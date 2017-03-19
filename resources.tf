data "aws_ami" "coreos" {
    most_recent = true

    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }

    filter {
        name = "owner-id"
        values = ["679593333241"]
    }

    filter {
        name = "name"
        values = ["CoreOS-stable-*"]
    }
}

//
// A default security group which should control general ingress/egress
// for all instances
//
data "aws_security_group" "default" {
    id = "sg-2f74324a"
}

resource "random_id" "mg_smtp_password" {
    keepers {
        domain_name = "${var.base_domain}"
    }

    byte_length = 16
}

//
// Ensure our primary zone exists, but also prevent changes
// so we do not have to keep resetting root NS records at the
// registrar.
//
resource "aws_route53_zone" "primary" {
    name = "${var.base_domain}."

    tags {
        Environment = "dev"
    }

    lifecycle {
        prevent_destroy = true
        ignore_changes = [
            "comment",
            "resource_record_set_count",
        ]
    }
}

//
// Mailgun domain for use w/ Koding for mail sending.
// Depending on the domain, destruction should be prevented, especially
// in the case of free (ie., .tk, .ml, etc) domains where spam is common.
resource "mailgun_domain" "primary" {
    name = "${random_id.mg_smtp_password.keepers.domain_name}"
    spam_action = "disabled"
    smtp_password = "${random_id.mg_smtp_password.hex}"

    lifecycle {
        prevent_destroy = true
    }
}

resource "aws_route53_record" "mailgun_sending_record_0" {
  zone_id = "${aws_route53_zone.primary.zone_id}"
  name    = "${mailgun_domain.primary.sending_records.0.name}."
  ttl     = "120"
  type    = "${mailgun_domain.primary.sending_records.0.record_type}"
  records = ["${mailgun_domain.primary.sending_records.0.value}"]
}

resource "aws_route53_record" "mailgun_sending_record_1" {
  zone_id = "${aws_route53_zone.primary.zone_id}"
  name    = "${mailgun_domain.primary.sending_records.1.name}."
  ttl     = "120"
  type    = "${mailgun_domain.primary.sending_records.1.record_type}"
  records = ["${mailgun_domain.primary.sending_records.1.value}"]
}

resource "aws_route53_record" "mailgun_sending_record_2" {
  zone_id = "${aws_route53_zone.primary.zone_id}"
  name    = "${mailgun_domain.primary.sending_records.2.name}."
  ttl     = "120"
  type    = "${mailgun_domain.primary.sending_records.2.record_type}"
  records = ["${mailgun_domain.primary.sending_records.2.value}"]
}

//
// Creates Mailgun MX records on the domain.
//
resource "aws_route53_record" "mailgun_recv_records" {
    zone_id = "${aws_route53_zone.primary.zone_id}"
    name = ""
    ttl = "120"
    type = "MX"
    records = [
        "${mailgun_domain.primary.receiving_records.0.priority} ${mailgun_domain.primary.receiving_records.0.value}",
        "${mailgun_domain.primary.receiving_records.1.priority} ${mailgun_domain.primary.receiving_records.1.value}"
    ]
}

//
// Ephemeral volume for configurations, compose stacks, etc.
//
resource "aws_ebs_volume" "koding_data" {
    availability_zone = "${var.aws_az}"
    size = "${var.ephemeral_size}"
    type = "standard"

    tags {
        Name = "koding_data"
    }

    lifecycle {
        prevent_destroy = true
    }
}

//
// LB access
//
resource "aws_security_group" "koding_fw" {
    name = "koding_fw"
    description = "FW Rules for Koding access"

    // This is only used by the internal LB
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    // This is only used by the internal LB
    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    // Provided by the Koding Kontrol Kite
    ingress {
        from_port = 8090
        to_port = 8090
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

//
// SSH management port - access CIDR should probably be narrow.
//
resource "aws_security_group" "coreos_mgmt" {
    name = "coreos_mgmt"
    description = "FW rules for coreos access"

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

//
// CoreOS SG for inter-cluster scaling / cluster communication,
// should it ever be necessary.
//
resource "aws_security_group" "coreos_etcd" {
    name = "coreos_etcd"
    description = "FW rules for coreos clustering"

    ingress {
        from_port = 2379
        to_port = 2379
        protocol = "tcp"
        self = true
    }

    ingress {
        from_port = 2380
        to_port = 2380
        protocol = "tcp"
        self = true
    }

    ingress {
        from_port = 4001
        to_port = 4001
        protocol = "tcp"
        self = true
    }

    ingress {
        from_port = 7001
        to_port = 7001
        protocol = "tcp"
        self = true
    }
}

//
// CoreOS instance on which to run Koding.
// Root FS should be big enough for a number of Docker containers..
//
resource "aws_instance" "koding" {
    ami = "${data.aws_ami.coreos.id}"
    availability_zone = "${var.aws_az}"
    instance_type = "t2.medium"

    root_block_device {
        delete_on_termination = true
        volume_size = "20"
    }

    security_groups = [
        "${data.aws_security_group.default.name}",
        "${aws_security_group.koding_fw.name}",
        "${aws_security_group.coreos_mgmt.name}",
        "${aws_security_group.coreos_etcd.name}"
    ]

    user_data = "${data.ignition_config.coreos.rendered}"

    tags {
        Name = "koding"
    }
}

//
// Main Koding access domain
//
resource "aws_route53_record" "koding_instance" {
    zone_id = "${aws_route53_zone.primary.zone_id}"
    name = "koding.${aws_route53_zone.primary.name}"
    type = "A"
    ttl = "120"
    records = [
        "${aws_instance.koding.public_ip}"
    ]
}

//
// Team access wildcard for koding instance (ie., engineering.koding...)
//
resource "aws_route53_record" "koding_instance_wc" {
    zone_id = "${aws_route53_zone.primary.zone_id}"
    name = "*.koding.${aws_route53_zone.primary.name}"
    type = "A"
    ttl = "120"
    records = [
        "${aws_instance.koding.public_ip}"
    ]
}

//
// dev.koding... stub, just for safety.
//
resource "aws_route53_record" "koding_devpg_stub" {
    zone_id = "${aws_route53_zone.primary.zone_id}"
    name = "dev.koding.${aws_route53_zone.primary.name}"
    type = "A"
    ttl = "120"
    records = [
        "${aws_instance.koding.public_ip}"
    ]
}

//
// Wildcard for Koding's dev pages service
//
resource "aws_route53_record" "koding_devpg_wc" {
    zone_id = "${aws_route53_zone.primary.zone_id}"
    name = "*.dev.koding.${aws_route53_zone.primary.name}"
    type = "A"
    ttl = "120"
    records = [
        "${aws_instance.koding.public_ip}"
    ]
}

//
// AWS volume attachment - ephemeral data volume to instance
//
resource "aws_volume_attachment" "data_volume" {
    device_name = "${var.ephemeral_node}"
    instance_id = "${aws_instance.koding.id}"
    volume_id = "${aws_ebs_volume.koding_data.id}"
}

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

data "aws_security_group" "default" {
    id = "sg-2f74324a"
}

data "aws_route53_zone" "primary" {
    name = "${var.base_domain}"

    tags {
        Environment = "dev"
    }
}

resource "aws_ebs_volume" "koding_data" {
    availability_zone = "${var.aws_az}"
    size = 32
    type = "standard"

    tags {
        Name = "koding_data"
    }
}

resource "aws_security_group" "koding_fw" {
    name = "koding_fw"
    description = "FW Rules for Koding access"

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

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

    key_name = "yubihsm"

    tags {
        Name = "koding"
    }
}

resource "aws_route53_record" "koding_instance" {
    zone_id = "${data.aws_route53_zone.primary.zone_id}"
    name = "koding.${data.aws_route53_zone.primary.name}"
    type = "A"
    ttl = "120"
    records = [
        "${aws_instance.koding.public_ip}"
    ]
}

resource "aws_route53_record" "koding_instance_wc" {
    zone_id = "${data.aws_route53_zone.primary.zone_id}"
    name = "*.koding.${data.aws_route53_zone.primary.name}"
    type = "A"
    ttl = "120"
    records = [
        "${aws_instance.koding.public_ip}"
    ]
}

resource "mailgun_domain" "primary" {
    name = "${var.base_domain}"
    spam_action = "disabled"
}

resource "aws_route53_record" "recv_records" {
}

resource "aws_volume_attachment" "data_volume" {
    device_name = "/dev/sdv"
    instance_id = "${aws_instance.koding.id}"
    volume_id = "${aws_ebs_volume.koding_data.id}"
}

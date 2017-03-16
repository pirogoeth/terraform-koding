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

resource "aws_ebs_volume" "koding_data" {
    availability_zone = "${var.aws_az}"
    size = 20
    type = "standard"

    tags {
        Name = "koding_data"
    }
}

resource "aws_security_group" "koding_fw" {
    name = "koding_fw"
    description = "FW Rules for Koding access"

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

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

resource "aws_instance" "koding" {
    ami = "${data.aws_ami.coreos.id}"
    availability_zone = "${var.aws_az}"
    instance_type = "t2.medium"

    root_block_device {
        delete_on_termination = true
    }

    security_groups = ["${aws_security_group.koding_fw.name}"]

    tags {
        Name = "koding"
    }
}

resource "aws_volume_attachment" "data_volume" {
    device_name = "/dev/sdv"
    instance_id = "${aws_instance.koding.id}"
    volume_id = "${aws_ebs_volume.koding_data.id}"
}

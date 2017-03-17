provider "aws" {
    access_key = "${var.aws_access}"
    secret_key = "${var.aws_secret}"
    region = "${var.aws_region}"
}

provider "mailgun" {
    api_key = "${var.mailgun_api_key}"
}

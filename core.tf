// Vars for setting up AWS provider
variable "aws_secret" {
    type = "string"
    description = "AWS Secret Key"
}

variable "aws_access" {
    type = "string"
    description = "AWS Access Key"
}

variable "aws_region" {
    type = "string"
    description = "AWS Region to use"
    default = "us-west-1"
}

variable "aws_az" {
    type = "string"
    description = "AWS Availability Zone"
    default = "us-west-1a"
}

// Domain things
variable "base_domain" {
    type = "string"
    description = "Base domain to use"
}

// Mailgun setup ;)
variable "mailgun_api_key" {
    type = "string"
    description = "Mailgun account API key"
}

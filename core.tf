terraform {
    required_version = ">= 0.9.0"
}

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

// Ephemeral block device setup
variable "ephemeral_size" {
    type = "string"
    description = "Size of ephemeral block device"
    default = "32"
}

variable "ephemeral_node" {
    type = "string"
    description = "device node inside EC2 instance"
    default = "/dev/xvdv"
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

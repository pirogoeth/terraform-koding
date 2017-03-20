Terraform plan for building a Koding instance
=============================================

Add the following to your `terraform.tfvars`:


    aws_access      = "AWS_ACCESS_KEY"
    aws_secret      = "AWS_SECRET_KEY"
    aws_region      = "us-west-1"
    aws_az          = "us-west-1a"

    ephemeral_node  = "/dev/xvdv"
    ephemeral_size  = "32"

    base_domain     = "DNS_DOMAIN"
    mailgun_api_key = "MAILGUN_SECRET_API_KEY"


*AND* configure the Terraform S3 backend according to [this](https://www.terraform.io/docs/backends/types/s3.html) doc or remove the `s3` backend block from `core.tf`.
Run `terraform init -backend-config "path/to/backend.hcl"` and then you should be free to `terraform plan`.

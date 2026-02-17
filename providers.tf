variable "region" {
  type    = string
  default = "eu-west-2"
}
provider "aws" { region = var.region }
data "aws_region" "current" {}

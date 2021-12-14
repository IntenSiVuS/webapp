provider "aws" {
  region = var.region
}

data "aws_vpc" "this" {
  filter {
    name   = "tag:Name"
    values = ["default"]
  }
}

locals {
  subnets = ["subnet-0ef5cd66", "subnet-f2a7e288"]
  ami     = "ami-0e8f6957a4eb67446"
  azs     = ["eu-central-1a", "eu-central-1b"]
}
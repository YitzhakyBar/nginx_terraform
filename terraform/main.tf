# The required version and provider for AWS
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.25.0"
    }
  }

  required_version = ">= 1.2.0"

}

provider "aws" {
  region     = "eu-north-1"
  access_key = var.access_key
  secret_key = var.secret_key
}

resource "aws_key_pair" "key_pair" {
  key_name   = "key-pair"
  public_key = file("~/.ssh/key-pair.pub")
}
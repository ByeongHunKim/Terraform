terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.4.0"
    }
  }

  required_version = ">= 1.4"
}

provider "aws" {
  region = var.vpc_region
}

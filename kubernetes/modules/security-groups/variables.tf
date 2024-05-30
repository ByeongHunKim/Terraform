variable "vpc_id" {
  description = "The VPC ID where the security groups will be created."
  type        = string
}

variable "bastion_cidr_block" {
  description = "CIDR block for SSH access to the Bastion host"
  type        = string
}

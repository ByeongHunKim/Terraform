variable "public_subnet_id" {
  description = "The public subnet ID where the Bastion host will be deployed."
  type        = string
}

variable "security_group_id" {
  description = "The ID of the security group to be attached to the Bastion host."
  type        = string
}

variable "public_subnet_id" {
  description = "The public subnet ID where the Bastion host will be deployed."
  type        = string
}

variable "security_group_id" {
  description = "The ID of the security group to be attached to the Bastion host."
  type        = string
}

variable "bastion_instance_type" {
  description = "Instance type for the Bastion host"
  type        = string
}

variable "bastion_key_name" {
  description = "Key name for SSH access"
  type        = string
}

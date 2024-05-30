variable "availability_zones" {
  type    = list(string)
  description = "List of availability zones in the region"
}

variable "bastion_instance_type" {
  type        = string
  description = "Instance type for the Bastion host"
}

variable "bastion_key_name" {
  type        = string
  description = "Key name for SSH access"
}

variable "bastion_cidr_block" {
  type        = string
  description = "CIDR block for SSH access to the Bastion host"
}

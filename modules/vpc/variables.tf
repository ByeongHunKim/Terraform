variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "A list of public subnet CIDR blocks"
  type        = list(string)
  default     = []
}

variable "private_subnets" {
  description = "A list of private subnet CIDR blocks"
  type        = list(string)
  default     = []
}

variable "enable_dns_hostnames" {
  description = "Whether to enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Whether to enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "enable_nat_gateway" {
  description = "Whether to create NAT gateway for private subnets"
  type        = bool
  default     = false
}

variable "name_prefix" {
  description = "Name prefix to be used on all the resources as identifier"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}

variable "database_subnets" {
  description = "A list of database subnet CIDR blocks"
  type        = list(string)
  default     = []
}

variable "create_database_subnet_group" {
  description = "Whether to create database subnet group"
  type        = bool
  default     = true
}

variable "database_subnet_group_name" {
  description = "Name of the database subnet group"
  type        = string
  default     = ""
}
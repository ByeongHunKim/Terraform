variable "vpc_tags" {
  type = string
  description = "vpc tag name"
}

variable "vpc_region" {
  type = string
  description = "vpc region"
  default = "ap-southeast-1"
}
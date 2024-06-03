variable "cluster_name" {
  description = "The name of the EKS cluster"
  type = string
}

variable "cluster_version" {
  description = "The version of the EKS cluster"
  type = string
}

variable "vpc_id" {
  description = "The VPC ID where the cluster will be deployed"
  type = string
}

variable "subnet_ids" {
  description = "The subnet IDs for the EKS cluster"
  type = list(string)
}

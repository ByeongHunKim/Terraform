output "bastion_sg_id" {
  value = aws_security_group.bastion.id
  description = "The ID of the security group for the Bastion host."
}

output "eks_node_sg_id" {
  value = aws_security_group.eks_node.id
  description = "The ID of the security group for the EKS nodes."
}

# modules/security-groups/outputs.tf
output "bastion_sg_id" {
  value = aws_security_group.bastion.id
  description = "The ID of the security group for the Bastion host."
}

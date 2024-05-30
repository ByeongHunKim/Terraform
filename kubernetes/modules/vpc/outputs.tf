output "vpc_id" {
  value = aws_vpc.main.id
  description = "The ID of the VPC created."
}

output "public_subnet_ids" {
  value = aws_subnet.public.*.id
  description = "The IDs of the public subnets created."
}

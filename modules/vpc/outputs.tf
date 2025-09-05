output "vpc_id" {
  description = "vpc id"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "VPC cidr block"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "pub sbn id lists"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "pri sbn id lists"
  value       = aws_subnet.private[*].id
}

output "internet_gateway_id" {
  description = "igw id"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_id" {
  description = "NAT GW id"
  value       = var.enable_nat_gateway && length(var.private_subnets) > 0 ? aws_nat_gateway.main[0].id : null
}

output "public_route_table_id" {
  description = "pub rt id"
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "priv rt id"
  value       = length(var.private_subnets) > 0 ? aws_route_table.private[0].id : null
}

output "database_subnet_ids" {
  description = "Database subnet IDs"
  value       = aws_subnet.database[*].id
}

output "database_route_table_id" {
  description = "Database route table ID"
  value       = length(var.database_subnets) > 0 ? aws_route_table.database[0].id : null
}

output "database_subnet_group_name" {
  description = "Database subnet group name"
  value       = var.create_database_subnet_group && length(var.database_subnets) > 0 ? aws_db_subnet_group.database[0].name : null
}
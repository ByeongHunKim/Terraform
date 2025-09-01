# ====================================================================
# VPC Outputs
# ====================================================================
output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = aws_vpc.main.arn
}

# ====================================================================
# Subnet Outputs
# ====================================================================
output "public_subnet_ids" {
  description = "List of IDs of the public subnets"
  value       = values(aws_subnet.public)[*].id
}

output "private_subnet_ids" {
  description = "List of IDs of the private subnets"
  value       = values(aws_subnet.private)[*].id
}

output "public_subnet_cidrs" {
  description = "List of CIDR blocks of the public subnets"
  value       = values(aws_subnet.public)[*].cidr_block
}

output "private_subnet_cidrs" {
  description = "List of CIDR blocks of the private subnets"
  value       = values(aws_subnet.private)[*].cidr_block
}

output "public_subnets_by_cidr" {
  description = "Map of public subnet CIDRs to subnet IDs"
  value = {
    for cidr, subnet in aws_subnet.public : cidr => subnet.id
  }
}

output "private_subnets_by_cidr" {
  description = "Map of private subnet CIDRs to subnet IDs"
  value = {
    for cidr, subnet in aws_subnet.private : cidr => subnet.id
  }
}

# ====================================================================
# Gateway Outputs
# ====================================================================
output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_id" {
  description = "The ID of the NAT Gateway"
  value       = local.create_nat_gateway ? aws_nat_gateway.main[0].id : null
}

output "nat_gateway_public_ip" {
  description = "The public IP of the NAT Gateway"
  value       = local.create_nat_gateway ? aws_eip.nat[0].public_ip : null
}

# ====================================================================
# Route Table Outputs
# ====================================================================
output "public_route_table_id" {
  description = "The ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "The ID of the private route table"
  value       = length(var.private_subnets) > 0 ? aws_route_table.private[0].id : null
}

# ====================================================================
# Availability Zone Information
# ====================================================================
output "availability_zones" {
  description = "List of availability zones used"
  value       = local.available_azs
}

output "subnet_az_mapping" {
  description = "Map showing subnet CIDR to AZ mapping"
  value = merge(
    {
      for cidr, config in local.public_subnets_map :
      "${cidr} (public)" => config.az
    },
    {
      for cidr, config in local.private_subnets_map :
      "${cidr} (private)" => config.az
    }
  )
}
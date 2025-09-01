# ====================================================================
# Data Sources - AWS Availability Zones
# - Fetch available AZs in the current region
# ====================================================================
data "aws_availability_zones" "available" {
  state = "available"
}

# ====================================================================
# Local Values - Complex Logic Separated to Local Variables
# - Improves readability and maintainability
# - Enables safe AZ distribution across subnets
# ====================================================================
locals {
  # Available AZ list and count for safe distribution
  available_azs = data.aws_availability_zones.available.names
  az_count      = length(local.available_azs)

  # Public subnets mapped with index and AZ assignment
  # - Uses CIDR as key for stable resource identification
  # - Distributes subnets across AZs using modulo operation
  public_subnets_map = {
    for idx, cidr in var.public_subnets : cidr => {
      cidr  = cidr
      az    = local.available_azs[idx % local.az_count]
      index = idx
    }
  }

  # Private subnets mapped with index and AZ assignment
  # - Same pattern as public subnets for consistency
  private_subnets_map = {
    for idx, cidr in var.private_subnets : cidr => {
      cidr  = cidr
      az    = local.available_azs[idx % local.az_count]
      index = idx
    }
  }

  # NAT Gateway creation logic - simplified conditional
  create_nat_gateway = var.enable_nat_gateway && length(var.private_subnets) > 0
  nat_gateway_count  = local.create_nat_gateway ? 1 : 0

  # Base tags applied to all resources
  base_tags = merge(var.tags, {
    Module = "vpc"
  })
}

# ====================================================================
# VPC - Main Virtual Private Cloud
# ====================================================================
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(local.base_tags, {
    Name = "${var.name_prefix}-vpc"
    Type = "VPC"
  })
}

# ====================================================================
# Public Subnets - Internet Accessible Subnets
# - Uses for_each for stable resource management
# - Distributed across multiple AZs for high availability
# - Auto-assign public IP enabled
# ====================================================================
resource "aws_subnet" "public" {
  for_each = local.public_subnets_map

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  map_public_ip_on_launch = true

  tags = merge(local.base_tags, {
    Name = "${var.name_prefix}-public-${each.value.index + 1}"
    Type = "Public"
    CIDR = each.value.cidr
    AZ   = each.value.az
  })
}

# ====================================================================
# Private Subnets - Internal Network Subnets
# - Uses for_each for stable resource management
# - No direct internet access
# - Distributed across multiple AZs for high availability
# ====================================================================
resource "aws_subnet" "private" {
  for_each = local.private_subnets_map

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(local.base_tags, {
    Name = "${var.name_prefix}-private-${each.value.index + 1}"
    Type = "Private"
    CIDR = each.value.cidr
    AZ   = each.value.az
  })
}

# ====================================================================
# Internet Gateway - VPC Internet Access Gateway
# - Enables internet connectivity for public subnets
# ====================================================================
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.base_tags, {
    Name = "${var.name_prefix}-igw"
    Type = "InternetGateway"
  })
}

# ====================================================================
# Public Route Table - Routing for Public Subnets
# - Default route to Internet Gateway (0.0.0.0/0 -> IGW)
# ====================================================================
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.base_tags, {
    Name = "${var.name_prefix}-public-rt"
    Type = "RouteTable"
  })
}

# ====================================================================
# Public Route Table Association - Connect Subnets to Route Table
# - Associate all public subnets with public route table
# - Uses for_each for stable resource management
# ====================================================================
resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# ====================================================================
# Elastic IP for NAT Gateway - Static IP for NAT
# - Required for NAT Gateway
# - Created only when NAT Gateway is enabled and private subnets exist
# - Uses simplified conditional logic
# ====================================================================
resource "aws_eip" "nat" {
  count = local.nat_gateway_count

  domain = "vpc"

  tags = merge(local.base_tags, {
    Name = "${var.name_prefix}-nat-eip"
    Type = "ElasticIP"
  })

  depends_on = [aws_internet_gateway.main]
}

# ====================================================================
# NAT Gateway - Internet Access for Private Subnets
# - Enables outbound internet access for private subnets
# - Deployed in first public subnet for internet connectivity
# - Uses simplified conditional logic
# ====================================================================
resource "aws_nat_gateway" "main" {
  count = local.nat_gateway_count

  allocation_id = aws_eip.nat[0].id
  subnet_id     = values(aws_subnet.public)[0].id

  tags = merge(local.base_tags, {
    Name = "${var.name_prefix}-nat-gateway"
    Type = "NATGateway"
  })

  depends_on = [aws_internet_gateway.main]
}

# ====================================================================
# Private Route Table - Routing for Private Subnets
# - Optional route to NAT Gateway for outbound internet access
# - Uses dynamic block for conditional route creation
# ====================================================================
resource "aws_route_table" "private" {
  count = length(var.private_subnets) > 0 ? 1 : 0

  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = local.create_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[0].id
    }
  }

  tags = merge(local.base_tags, {
    Name = "${var.name_prefix}-private-rt"
    Type = "RouteTable"
  })
}

# ====================================================================
# Private Route Table Association - Connect Private Subnets to Route Table
# - Associate all private subnets with private route table
# - Uses for_each for stable resource management
# ====================================================================
resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[0].id
}
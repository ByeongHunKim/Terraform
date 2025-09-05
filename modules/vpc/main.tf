# ====================================================================
# Data Sources - AWS Availability Zones
# - Fetch available AZs in the current region
# ====================================================================
data "aws_availability_zones" "available" {
  state = "available"
}

# ====================================================================
# VPC - Main Virtual Private Cloud
# - CIDR block defined by variable
# - DNS hostnames and support enabled
# ====================================================================
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-vpc"
  })
}

# ====================================================================
# Public Subnets - Internet Accessible Subnets
# - Distributed across multiple AZs for high availability
# - Auto-assign public IP enabled
# ====================================================================
resource "aws_subnet" "public" {
  count = length(var.public_subnets)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnets[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-${count.index + 1}"
    Type = "Public"
  })
}

# ====================================================================
# Private Subnets - Internal Network Subnets
# - No direct internet access
# - Distributed across multiple AZs for high availability
# ====================================================================
resource "aws_subnet" "private" {
  count = length(var.private_subnets)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-${count.index + 1}"
    Type = "Private"
  })
}

# ====================================================================
# Internet Gateway - VPC Internet Access Gateway
# - Enables internet connectivity for public subnets
# ====================================================================
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-igw"
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

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-rt"
  })
}

# ====================================================================
# Public Route Table Association - Connect Subnets to Route Table
# - Associate all public subnets with public route table
# ====================================================================
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ====================================================================
# Elastic IP for NAT Gateway - Static IP for NAT
# - Required for NAT Gateway
# - Created only when NAT Gateway is enabled and private subnets exist
# ====================================================================
resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? length(var.private_subnets) > 0 ? 1 : 0 : 0

  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-nat-eip"
  })

  depends_on = [aws_internet_gateway.main]
}

# ====================================================================
# NAT Gateway - Internet Access for Private Subnets
# - Enables outbound internet access for private subnets
# - Deployed in public subnet for internet connectivity
# ====================================================================
resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? length(var.private_subnets) > 0 ? 1 : 0 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-nat-gateway"
  })

  depends_on = [aws_internet_gateway.main]
}

# ====================================================================
# Private Route Table - Routing for Private Subnets
# - Optional route to NAT Gateway for outbound internet access
# ====================================================================
resource "aws_route_table" "private" {
  count = length(var.private_subnets) > 0 ? 1 : 0

  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[0].id
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-rt"
  })
}

# ====================================================================
# Private Route Table Association - Connect Private Subnets to Route Table
# - Associate all private subnets with private route table
# ====================================================================
resource "aws_route_table_association" "private" {
  count = length(var.private_subnets)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[0].id
}

# ====================================================================
# Database Subnets - Isolated Database Layer
# ====================================================================
resource "aws_subnet" "database" {
  count = length(var.database_subnets)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.database_subnets[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-database-${count.index + 1}"
    Type = "Database"
  })
}

# ====================================================================
# Database Route Table
# ====================================================================
resource "aws_route_table" "database" {
  count = length(var.database_subnets) > 0 ? 1 : 0

  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-database-rt"
  })
}

# ====================================================================
# Database Route Table Association
# ====================================================================
resource "aws_route_table_association" "database" {
  count = length(var.database_subnets)

  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database[0].id
}

# ====================================================================
# RDS Subnet Group
# ====================================================================
resource "aws_db_subnet_group" "database" {
  count = var.create_database_subnet_group && length(var.database_subnets) > 0 ? 1 : 0

  name       = var.database_subnet_group_name != "" ? var.database_subnet_group_name : "${var.name_prefix}-db-subnet-group"
  subnet_ids = aws_subnet.database[*].id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-db-subnet-group"
  })
}
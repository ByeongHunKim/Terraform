# VPC 생성
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "production-vpc"
  }
}

# 인터넷 게이트웨이 생성
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "production-internet-gateway"
  }
}

# 퍼블릭 서브넷 생성
resource "aws_subnet" "public" {
  count = 2
  vpc_id = aws_vpc.main.id
  cidr_block = ["10.0.64.0/20", "10.0.80.0/20"][count.index]
  availability_zone = element(var.availability_zones, count.index)
  map_public_ip_on_launch = true
  tags = {
    "kubernetes.io/role/elb" = 1
  }
}

# 프라이빗 서브넷 생성
resource "aws_subnet" "private" {
  count = 2
  vpc_id = aws_vpc.main.id
  cidr_block = ["10.0.0.0/20", "10.0.16.0/20"][count.index]
  availability_zone = element(var.availability_zones, count.index)
  tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}

# Elastic IP 생성
resource "aws_eip" "nat" {
  count = length(aws_subnet.public.*.id)
  domain = "vpc"
  tags = {
    Name = "NAT-Gateway-EIP-${count.index}"
  }
}

# NAT Gateway 생성
resource "aws_nat_gateway" "example" {
  count         = length(aws_subnet.public.*.id)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  tags = {
    Name = "NAT-Gateway-${count.index}"
  }
}

# 퍼블릭 서브넷을 위한 라우팅 테이블 생성
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "public-route-table"
  }
}

# 인터넷 접속을 위한 퍼블릭 라우트 생성
resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# 퍼블릭 서브넷과 퍼블릭 라우팅 테이블 연결
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public.*.id)
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

# 프라이빗 서브넷을 위한 라우팅 테이블 생성
resource "aws_route_table" "private" {
  count = length(aws_subnet.private.*.id)
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "Private-Route-Table-${count.index}"
  }
}

# 인터넷 접속을 위한 프라이빗 라우트 생성
resource "aws_route" "internet_access" {
  count                = length(aws_subnet.private.*.id)
  route_table_id       = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id       = aws_nat_gateway.example[count.index % length(aws_nat_gateway.example.*.id)].id
}

# 라우팅 테이블과 프라이빗 서브넷 연결
resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private.*.id)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

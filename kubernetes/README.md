# Terraform Infrastructure Deployment

## Summary [Apply complete! Resources: 30 added, 0 changed, 0 destroyed ]

This Terraform configuration creates a network infrastructure in the AWS `ap-southeast-1` (Singapore) region, including a VPC, subnets, NAT gateways, security groups, and a bastion host. Below are the details of the created resources:

### VPC
- **Name**: `production-vpc`
- **CIDR Block**: `10.0.0.0/16`
- **DNS Support**: Enabled

### Internet Gateway
- **Name**: `production-internet-gateway`

### Subnets
- **Public Subnets**:
  - `public-subnet-ap-southeast-1a` - `10.0.64.0/20`
  - `public-subnet-ap-southeast-1b` - `10.0.80.0/20`
  - `public-subnet-ap-southeast-1c` - `10.0.96.0/20`
- **Private Subnets**:
  - `private-subnet-ap-southeast-1a` - `10.0.0.0/20`
  - `private-subnet-ap-southeast-1b` - `10.0.16.0/20`
  - `private-subnet-ap-southeast-1c` - `10.0.32.0/20`

### NAT Gateways
- **NAT Gateway 0**: `NAT-Gateway-0` (Elastic IP: `NAT-Gateway-EIP-0`)
- **NAT Gateway 1**: `NAT-Gateway-1` (Elastic IP: `NAT-Gateway-EIP-1`)
- **NAT Gateway 2**: `NAT-Gateway-2` (Elastic IP: `NAT-Gateway-EIP-2`)

### Route Tables
- **Public Route Table**: Routes internet traffic via Internet Gateway
- **Private Route Tables**: Routes internet traffic via respective NAT Gateways

### Security Groups
- **bastion-sg**
  - **Description**: Security group for bastion host
  - **Ingress**: SSH (Port 22) from `{ip}/32`
  - **Egress**: All traffic allowed

### Bastion Host
- **AMI**: `{latest-ami}`
- **Instance Type**: `t2.micro`
- **Key Name**: `{common-pem}`
- **Public IP**: Assigned
- **Subnet**: `public-subnet-ap-southeast-1a`
- **Security Group**: `bastion-sg`
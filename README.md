# Terraform

## Project Structure

```bash
terraform-aws-infrastructure/
├── .github/                    # GitHub Actions workflows
│   └── workflows/
│       └── aws-test.yml        # AWS OIDC connection test
├── dev/                        # Development Environment
│   ├── .terraform.lock.hcl     # Provider version lock
│   ├── backend.tf              # Terraform Cloud workspace
│   ├── main.tf                 # Module calls & local config
│   ├── variables.tf            # Environment variables
│   ├── outputs.tf              # Environment outputs
│   └── terraform.tfvars        # Values (gitignored)
├── stg/                        # Staging Environment (planned)
├── prod/                       # Production Environment (planned)
├── modules/                    # Reusable Terraform modules
│   ├── vpc/                    # VPC with subnets, IGW, NAT
│   │   ├── main.tf             # VPC resources
│   │   ├── variables.tf        # VPC input variables
│   │   └── outputs.tf          # VPC outputs
│   ├── terraform-cloud-oidc/   # Terraform Cloud OIDC authentication
│   │   ├── main.tf             # OIDC provider & IAM role
│   │   ├── variables.tf        # TFC-specific variables
│   │   └── outputs.tf          # TFC OIDC outputs
│   ├── github-actions-oidc/    # GitHub Actions OIDC authentication
│   │   ├── main.tf             # GitHub OIDC provider & IAM role
│   │   ├── variables.tf        # GitHub-specific variables
│   │   └── outputs.tf          # GitHub OIDC outputs
│   ├── acm/                    # Certificate Manager
│   │   ├── main.tf              
│   │   ├── variables.tf        
│   │   └── outputs.tf
│   ├── ecs/                    # ECS Cluster
│   │   ├── main.tf              
│   │   ├── variables.tf        
│   │   └── outputs.tf              
│   └── ec2/                    # EC2 instances (planned)
├── .gitignore                  
└── README.md                   
```

## Authentication Flow

```mermaid
graph TB
    subgraph "Terraform Cloud"
        TFC[Workspace: Meiko<br/>Org: Meiko_Org]
    end
    
    subgraph "AWS Account"
        OIDC[OIDC Provider<br/>app.terraform.io]
        ROLE[IAM Role<br/>terraform-study-dev-tfc-role]
        
        subgraph "Infrastructure"
            VPC[VPC: 10.0.0.0/16]
            PUB[Public Subnets<br/>10.0.1.0/24, 10.0.2.0/24]
            PRIV[Private Subnets<br/>10.0.10.0/24, 10.0.20.0/24]
            IGW[Internet Gateway]
        end
    end
    
    TFC -->|OIDC Token| OIDC
    OIDC -->|Assume Role| ROLE
    ROLE -->|Deploy| VPC
    VPC --> PUB
    VPC --> PRIV
    VPC --> IGW
    
    style TFC fill:#326ce5,color:#fff
    style OIDC fill:#ff9900,color:#fff
    style ROLE fill:#ff9900,color:#fff
    style VPC fill:#90ee90,color:#000
```

## Usage

```bash
cd dev/
terraform init
terraform plan
terraform apply
```

**Environment**: Development (NAT Gateway disabled for cost optimization)  
**Region**: ap-northeast-2 (Seoul)
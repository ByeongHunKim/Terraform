# Terraform

## Project Structure

```bash
terraform-aws-infrastructure/
├── dev/                        # Development Environment
│   ├── .terraform.lock.hcl     # Provider version lock
│   ├── backend.tf              # Terraform Cloud workspace
│   ├── main.tf                 # Module calls & local config
│   ├── variables.tf            # Environment variables
│   ├── outputs.tf              # Outputs
│   └── terraform.tfvars        # Values (gitignored)
├── stg/                        # Staging (planned)
├── prod/                       # Production (planned)
├── modules/                    # Reusable modules
│   ├── vpc/                    # VPC with subnets, IGW, NAT
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── terraform-cloud-oidc/   # OIDC authentication
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
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
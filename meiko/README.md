# Structure

```bash
├── dev/
│   ├── .terraform.lock.hcl  # Development environment lock file
│   ├── main.tf             # Module calls only
│   ├── variables.tf        # Environment-specific variable definitions
│   ├── terraform.tfvars    # Environment-specific values
│   └── backend.tf          # Dev workspace connection
├── stg/                     # Staging environment
├── prod/                    # Production environment
├── modules/                 # Reusable modules
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── ec2/ # todo
```
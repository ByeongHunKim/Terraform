## terraform init
```bash
terrafor init                                                                                                                                1 ✘  system   dev/lazyants-airdrop-web ⭐  15:11:50  

Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/aws versions matching "5.4.0"...
- Installing hashicorp/aws v5.4.0...
- Installed hashicorp/aws v5.4.0 (signed by HashiCorp)

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.

```

### terraform init 설명
```text
terraform init 명렲은 Terraform 프로젝트를 초기화하는 데 사용됩니다. 이 명령은 주로 다음과 같은 작업을 수행합니다:

백엔드 초기화: Terraform 상태 파일을 저장하고 관리하는 백엔드를 초기화합니다. 이 백엔드는 로컬 파일 시스템이나 원격 데이터 저장소일 수 있습니다.
프로바이더 플러그인 초기화: Terraform이 리소스를 관리하는 데 사용하는 프로바이더(예: AWS, Google Cloud 등)의 적절한 버전을 찾아 설치합니다. 예에서는 AWS 프로바이더 버전 5.4.0이 설치되었습니다.
.terraform.lock.hcl 파일 생성: 이 파일은 사용된 프로바이더의 버전을 기록하여 프로젝트가 다른 환경에서 실행될 때 동일한 프로바이더 버전이 사용되도록 보장합니다. 이 파일은 버전 컨트롤에 포함되어야 합니다.
terraform init은 프로젝트를 시작할 때 처음 실행하거나, Terraform 구성의 모듈이나 백엔드 설정이 변경될 때 필요합니다. 초기화 과정이 성공적으로 완료되면, Terraform 구성 파일에 기술된 리소스를 관리하기 위해 terraform plan, terraform apply 등의 다른 Terraform 명령을 사용할 준비가 됩니다.

이 명령은 프로젝트 설정과 종속성 관리의 기초를 마련하며, 일관된 인프라 관리를 위한 중요한 첫 단계입니다.

Q1: Terraform에서 백엔드 설정을 변경할 때 주의해야 할 사항은 무엇인가요?

Q2: Terraform 프로젝트에서 프로바이더 버전을 명시적으로 지정하는 이점은 무엇인가요?

Q3: .terraform.lock.hcl 파일을 버전 관리에 포함시키는 것이 왜 중요한가요?
```

## terraform plan
```bash
terrafor plan                                                                                                                                 ✔  7s   system   dev/lazyants-airdrop-web ⭐  15:12:58  

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_vpc.main will be created
  + resource "aws_vpc" "main" {
      + arn                                  = (known after apply)
      + cidr_block                           = "10.0.0.0/16"
      + default_network_acl_id               = (known after apply)
      + default_route_table_id               = (known after apply)
      + default_security_group_id            = (known after apply)
      + dhcp_options_id                      = (known after apply)
      + enable_dns_hostnames                 = (known after apply)
      + enable_dns_support                   = true
      + enable_network_address_usage_metrics = (known after apply)
      + id                                   = (known after apply)
      + instance_tenancy                     = "default"
      + ipv6_association_id                  = (known after apply)
      + ipv6_cidr_block                      = (known after apply)
      + ipv6_cidr_block_network_border_group = (known after apply)
      + main_route_table_id                  = (known after apply)
      + owner_id                             = (known after apply)
      + tags                                 = {
          + "Name" = "terraform VPC"
        }
      + tags_all                             = {
          + "Name" = "terraform VPC"
        }
    }

Plan: 1 to add, 0 to change, 0 to destroy.

```

### terraform plan 설명
```text
terraform plan 명령은 변경 사항을 실제로 적용하기 전에 Terraform 구성이 어떤 작업을 수행할지 미리 보여줍니다. 이 명령은 지정된 Terraform 구성 파일에 기반하여 계획된 리소스의 생성, 변경, 파괴를 예측합니다. 예제에서 제공된 출력은 다음과 같은 내용을 포함하고 있습니다.

심볼 사용: 출력에 나타난 + 심볼은 리소스가 생성될 것임을 나타냅니다.
실행 계획: 이 구체적인 예에서는 aws_vpc.main이라는 VPC 리소스가 생성될 예정입니다. 리소스 생성시 설정할 여러 속성값들이 출력되며, known after apply는 해당 속성값이 실제 리소스 생성 후에만 알 수 있음을 의미합니다.
리소스 속성:
cidr_block은 VPC의 IP 주소 범위를 설정합니다.
enable_dns_support는 DNS 지원을 활성화하는 옵션입니다.
instance_tenancy는 VPC의 인스턴스가 배치될 테넌시 유형을 설정합니다.
tags와 tags_all은 리소스에 할당된 태그를 보여줍니다.
실행 요약: Plan: 1 to add, 0 to change, 0 to destroy.는 이 계획 실행시 한 개의 리소스가 추가될 것이고, 변경되거나 제거될 리소스는 없다는 것을 나타냅니다.
-out 옵션 주의: 출력 마지막 부분에서 -out 옵션을 사용하지 않았으므로, 이 계획은 저장되지 않았고 terraform apply를 실행할 때 정확히 같은 작업이 수행될 것이라는 보장은 없다는 주의 사항이 있습니다.
이 정보는 Terraform을 사용하여 AWS 리소스를 관리하는데 필수적인 이해를 제공합니다.

Q1: terraform plan 명령 후에 변경사항을 적용하지 않고 검토만 하기 위해 사용할 수 있는 옵션은 무엇인가요?

Q2: Terraform의 -out 옵션의 사용 예와 이 옵션이 왜 중요한지 설명해주세요.

Q3: Terraform을 사용할 때 VPC 리소르에 태그를 설정하는 이점은 무엇이며, 어떤 경우에 유용하게 사용할 수 있나요?
```

## terraform apply

```text
Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_vpc.main will be created
  + resource "aws_vpc" "main" {
      + arn                                  = (known after apply)
      + cidr_block                           = "10.0.0.0/16"
      + default_network_acl_id               = (known after apply)
      + default_route_table_id               = (known after apply)
      + default_security_group_id            = (known after apply)
      + dhcp_options_id                      = (known after apply)
      + enable_dns_hostnames                 = (known after apply)
      + enable_dns_support                   = true
      + enable_network_address_usage_metrics = (known after apply)
      + id                                   = (known after apply)
      + instance_tenancy                     = "default"
      + ipv6_association_id                  = (known after apply)
      + ipv6_cidr_block                      = (known after apply)
      + ipv6_cidr_block_network_border_group = (known after apply)
      + main_route_table_id                  = (known after apply)
      + owner_id                             = (known after apply)
      + tags                                 = {
          + "Name" = "terraform VPC"
        }
      + tags_all                             = {
          + "Name" = "terraform VPC"
        }
    }

Plan: 1 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

aws_vpc.main: Creating...
aws_vpc.main: Creation complete after 2s [id=vpc-0d760d47509ae3de5]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

```

## terraform destroy
```text
aws_vpc.main: Refreshing state... [id=vpc-0d760d47509ae3de5]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  - destroy

Terraform will perform the following actions:

  # aws_vpc.main will be destroyed
  - resource "aws_vpc" "main" {
      - arn                                  = "arn:aws:ec2:ap-southeast-1:00xxxxxxxxxx:vpc/vpc-0d760d47509ae3de5" -> null
      - assign_generated_ipv6_cidr_block     = false -> null
      - cidr_block                           = "10.0.0.0/16" -> null
      - default_network_acl_id               = "acl-08400eb6438db2e1f" -> null
      - default_route_table_id               = "rtb-02152ffefccde7057" -> null
      - default_security_group_id            = "sg-09a7fdbbf8429a1af" -> null
      - dhcp_options_id                      = "dopt-075b870daf978c542" -> null
      - enable_dns_hostnames                 = false -> null
      - enable_dns_support                   = true -> null
      - enable_network_address_usage_metrics = false -> null
      - id                                   = "vpc-0d760d47509ae3de5" -> null
      - instance_tenancy                     = "default" -> null
      - ipv6_netmask_length                  = 0 -> null
      - main_route_table_id                  = "rtb-02152ffefccde7057" -> null
      - owner_id                             = "00xxxxxxxxxx" -> null
      - tags                                 = {
          - "Name" = "terraform VPC"
        } -> null
      - tags_all                             = {
          - "Name" = "terraform VPC"
        } -> null
        # (4 unchanged attributes hidden)
    }

Plan: 0 to add, 0 to change, 1 to destroy.

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes

aws_vpc.main: Destroying... [id=vpc-0d760d47509ae3de5]
aws_vpc.main: Destruction complete after 1s

Destroy complete! Resources: 1 destroyed.

```
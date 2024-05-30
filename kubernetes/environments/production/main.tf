module "vpc" {
  source = "../../modules/vpc"
  availability_zones = var.availability_zones
}

module "security-groups" {
  source = "../../modules/security-groups"
  vpc_id = module.vpc.vpc_id
  bastion_cidr_block = var.bastion_cidr_block  # CIDR 블록 추가
}

module "bastion" {
  source = "../../modules/eks/bastion"
  public_subnet_id = module.vpc.public_subnet_ids[0]
  security_group_id = module.security-groups.bastion_sg_id
  bastion_instance_type = var.bastion_instance_type  # 인스턴스 타입 추가
  bastion_key_name = var.bastion_key_name  # 키 이름 추가
}

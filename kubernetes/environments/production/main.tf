module "vpc" {
  source = "../../modules/vpc"
  availability_zones = var.availability_zones
}

module "security-groups" {
  source = "../../modules/security-groups"
  vpc_id = module.vpc.vpc_id
}

module "bastion" {
  source          = "../../modules/eks/bastion"
  public_subnet_id = module.vpc.public_subnet_ids[0]
  security_group_id = module.security-groups.bastion_sg_id
}

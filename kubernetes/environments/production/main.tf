module "vpc" {
  source = "../../modules/vpc"
  availability_zones = var.availability_zones
}

module "security-groups" {
  source = "../../modules/security-groups"
  vpc_id = module.vpc.vpc_id
  bastion_cidr_block = var.bastion_cidr_block
}

module "bastion" {
  source = "../../modules/bastion"
  public_subnet_id = module.vpc.public_subnet_ids[0]
  bastion_security_group_id = module.security-groups.bastion_sg_id
  eks_node_security_group_id = module.security-groups.eks_node_sg_id
  bastion_instance_type = var.bastion_instance_type
  bastion_key_name = var.bastion_key_name
}

module "eks" {
  source = "../../modules/eks"
  cluster_name = var.cluster_name
  cluster_version = var.cluster_version
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
  bastion_key_name = var.bastion_key_name
}

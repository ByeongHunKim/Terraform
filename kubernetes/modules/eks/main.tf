module "eks" {
  source = "terraform-aws-modules/eks/aws"
  version = "19.20.0"

  cluster_name = var.cluster_name
  cluster_version = var.cluster_version
  vpc_id = var.vpc_id
  subnet_ids = var.subnet_ids

  self_managed_node_groups = {
    eks_nodes = {
      desired_capacity = 2
      max_capacity = 3
      min_capacity = 1
      instance_type = "t3.medium"
      key_name = var.bastion_key_name
    }
  }
}
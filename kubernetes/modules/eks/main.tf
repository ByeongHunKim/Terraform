# https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  vpc_id          = var.vpc_id
  subnet_ids      = var.subnet_ids

  cluster_endpoint_public_access  = true
  enable_cluster_creator_admin_permissions = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  eks_managed_node_groups = {
    terraform-node-group1 = {
      min_size     = 1
      max_size     = 3
      desired_size = 3

      instance_types = ["t3.medium"]
      capacity_type  = "SPOT"
    }
  }
}

output "eks_cluster_security_group_id" {
  value       = module.eks.cluster_security_group_id
  description = "The security group ID for the EKS cluster."
}
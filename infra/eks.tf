module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = ">= 20.0"

  name            = "${var.name}-eks"
  kubernetes_version = "1.35"

  endpoint_public_access  = true
  endpoint_private_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  ip_family = "ipv4"

  eks_managed_node_groups = {
    default = {
      name           = "${var.name}-node-group"
      use_name_prefix = true
      instance_types = ["t3.medium"]

      min_size     = 2
      max_size     = 3
      desired_size = 2

      tags = {
        Environment = "practical"
      }
    }
  }

  enable_cluster_creator_admin_permissions = true

  tags = {
    Environment = var.name
  }
}
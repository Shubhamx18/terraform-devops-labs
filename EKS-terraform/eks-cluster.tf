module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name                           = var.cluster_name
  kubernetes_version             = "1.29"
  endpoint_public_access         = true
  enable_cluster_creator_admin_permissions = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  control_plane_subnet_ids = module.vpc.intra_subnets

  cluster_addons = {
    vpc-cni    = { most_recent = true }
    kube-proxy = { most_recent = true }
    coredns    = { most_recent = true }
  }

  tags = {
    Environment = var.environment
  }
}

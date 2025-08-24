module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnets

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

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
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }

  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    instance_types = ["t3.medium"]
    
    attach_cluster_primary_security_group = true
    vpc_security_group_ids                = []
  }

  eks_managed_node_groups = {
    general = {
      name            = "general"
      use_name_prefix = true

      subnet_ids = var.private_subnets

      min_size     = var.min_size
      max_size     = var.max_size
      desired_size = var.desired_size

      instance_types = var.instance_types
      capacity_type  = var.capacity_type

      labels = {
        Environment = var.environment
        Type        = "general"
      }

      tags = var.tags
    }

    spot = {
      name            = "spot"
      use_name_prefix = true

      subnet_ids = var.private_subnets

      min_size     = 1
      max_size     = 3
      desired_size = 1

      instance_types = ["t3.small", "t3a.small"]
      capacity_type  = "SPOT"

      labels = {
        Environment = var.environment
        Type        = "spot"
      }

      taints = [
        {
          key    = "spot"
          value  = "true"
          effect = "NoSchedule"
        }
      ]

      tags = var.tags
    }
  }

  manage_aws_auth_configmap = true

  aws_auth_roles = var.aws_auth_roles
  aws_auth_users = var.aws_auth_users

  tags = var.tags
}

# Cluster Autoscaler IRSA
module "cluster_autoscaler_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name                        = "${var.cluster_name}-cluster-autoscaler"
  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_ids   = [module.eks.cluster_id]

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:cluster-autoscaler"]
    }
  }

  tags = var.tags
}

# Load Balancer Controller IRSA
module "load_balancer_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name                              = "${var.cluster_name}-aws-load-balancer-controller"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = var.tags
}
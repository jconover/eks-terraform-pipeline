# Production environment configuration
# Similar to dev but with:
# - Multi-AZ NAT gateways
# - Larger instance types
# - More replicas
# - Enhanced monitoring

provider "aws" {
  region = var.aws_region
}

locals {
  cluster_name = "${var.environment}-eks-cluster"
  
  tags = {
    Environment = var.environment
    Project     = "eks-terraform-pipeline"
    ManagedBy   = "Terraform"
    CostCenter  = "Production"
  }
}

module "vpc" {
  source = "../../modules/vpc"

  vpc_name             = "${var.environment}-vpc"
  vpc_cidr            = var.vpc_cidr
  availability_zones   = var.availability_zones
  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs  = var.public_subnet_cidrs
  single_nat_gateway   = false # High availability
  cluster_name        = local.cluster_name
  tags                = local.tags
}

module "eks" {
  source = "../../modules/eks"

  cluster_name    = local.cluster_name
  cluster_version = var.cluster_version
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
  environment     = var.environment
  
  instance_types = ["t3.large", "t3.xlarge"]
  min_size      = 3
  max_size      = 10
  desired_size  = 5
  capacity_type = "ON_DEMAND"
  
  aws_auth_roles = var.aws_auth_roles
  aws_auth_users = var.aws_auth_users
  
  tags = local.tags
}
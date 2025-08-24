provider "aws" {
  region = var.aws_region
}

locals {
  cluster_name = "${var.environment}-eks-cluster"
  
  tags = {
    Environment = var.environment
    Project     = "eks-terraform-pipeline"
    ManagedBy   = "Terraform"
  }
}

module "vpc" {
  source = "../../modules/vpc"

  vpc_name             = "${var.environment}-vpc"
  vpc_cidr            = var.vpc_cidr
  availability_zones   = var.availability_zones
  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs  = var.public_subnet_cidrs
  single_nat_gateway   = true # Cost optimization for dev
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
  
  instance_types = ["t3.small"]
  min_size      = 1
  max_size      = 3
  desired_size  = 2
  capacity_type = "ON_DEMAND"
  
  aws_auth_roles = var.aws_auth_roles
  aws_auth_users = var.aws_auth_users
  
  tags = local.tags
}

# Deploy Kubernetes resources
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = ["eks", "get-token", "--cluster-name", local.cluster_name]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = ["eks", "get-token", "--cluster-name", local.cluster_name]
    }
  }
}
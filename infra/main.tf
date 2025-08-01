# Configuring Terraform and required providers
terraform {
  required_version = ">= 1.5.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.0"
    }
  }
  backend "s3" {
    bucket         = "terraform-state-placeholder" # Placeholder, will be overridden by CLI
    key            = "terraform.tfstate"
    region         = "ap-south-1" # Default, will be overridden by CLI
    dynamodb_table = "terraform-locks-placeholder" # Placeholder, will be overridden by CLI
    encrypt        = true
  }
}

# AWS provider with parameterized region
provider "aws" {
  region = var.region
}

# Helm provider with EKS authentication
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", var.region]
    }
  }
}

# Kubernetes provider for EKS
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", var.region]
  }
}

# Random string for unique prefix
resource "random_string" "s3_prefix" {
  length  = 8
  special = false
  upper   = false
  numeric = true
}

# Data source for EKS-optimized AMI
data "aws_ami" "eks_optimized" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amazon-eks-node-1.28-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# Use an existing VPC (replace with your VPC ID)
data "aws_vpc" "existing" {
  id = "vpc-12345678" # Replace with an existing VPC ID in ap-south-1
}

# Security group rule for EKS cluster public access
resource "aws_security_group_rule" "eks_public_access" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]  # Restrict in production
  security_group_id = module.eks.cluster_security_group_id
  description       = "Allow public access to EKS cluster endpoint"
}

# EKS module for cluster creation
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.5"

  cluster_name    = var.cluster_name
  cluster_version = "1.28"

  vpc_id     = data.aws_vpc.existing.id
  subnet_ids = ["subnet-12345678", "subnet-87654321"]  # Replace with existing subnet IDs in ap-south-1

  # Ensure public endpoint only
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = false
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]  # Restrict in production

  # Disable automatic CloudWatch log group creation
  create_cloudwatch_log_group = false

  eks_managed_node_groups = {
    default = {
      min_size       = 1
      max_size       = var.node_count + 1
      desired_size   = var.node_count
      instance_types = ["t3.medium"]
      disk_size      = 20
      ami_id         = data.aws_ami.eks_optimized.id
    }
  }

  cluster_addons = {
    coredns = {
      addon_version               = "v1.10.1-eksbuild.6"
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }
    kube-proxy = {
      addon_version               = "v1.28.0-eksbuild.1"
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }
    vpc-cni = {
      addon_version               = "v1.16.0-eksbuild.1"
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }
  }

  depends_on = [data.aws_vpc.existing]

  tags = merge(
    {
      Environment   = "Production"
      Project       = "3tier-app"
      ManagedBy     = "Terraform"
      DeploymentID  = var.deployment_id  # Unique ID for tracking
    },
    var.tags
  )
}

# Kubernetes ConfigMap for aws-auth to map root user
resource "kubernetes_config_map_v1_data" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    "mapUsers" = yamlencode([
      {
        userarn  = "arn:aws:iam::${var.account_id}:root"
        username = "root-user"
        groups   = ["system:masters"]
      }
    ])
  }

  depends_on = [module.eks]
}

# IAM Role for AWS Load Balancer Controller
resource "aws_iam_role" "aws_load_balancer_controller" {
  name = "AWSLoadBalancerControllerRole-${var.cluster_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider}:sub" = "system:serviceaccount:kue-system:aws-load-balancer-controller"
          }
        }
      }
    ]
  })

  tags = merge(
    {
      Environment   = "Production"
      Project       = "3tier-app"
      ManagedBy     = "Terraform"
      DeploymentID  = var.deployment_id
    },
    var.tags
  )
}

# Attach the AWS managed policy for Load Balancer Controller
resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller_attach" {
  role       = aws_iam_role.aws_load_balancer_controller.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSLoadBalancerControllerRole"
}

# Add S3 bucket and DynamoDB for Terraform state with unique prefix
resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-state-${random_string.s3_prefix.result}-${var.region}-${var.account_id}"
  force_destroy = true  # Automatically delete bucket contents on destroy

  tags = merge(
    {
      Environment   = "Production"
      Project       = "3tier-app"
      ManagedBy     = "Terraform"
      DeploymentID  = var.deployment_id
    },
    var.tags
  )
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_locks" {
  name           = "terraform-locks-${random_string.s3_prefix.result}-${var.region}-${var.account_id}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
  tags = merge(
    {
      Environment   = "Production"
      Project       = "3tier-app"
      ManagedBy     = "Terraform"
      DeploymentID  = var.deployment_id
    },
    var.tags
  )
}

# Basic ALB resource (to be adjusted based on requirements)
resource "aws_lb" "alb" {
  name               = "${var.cluster_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.eks.cluster_security_group_id]
  subnets            = ["subnet-12345678", "subnet-87654321"]  # Replace with existing subnet IDs

  enable_deletion_protection = false

  tags = merge(
    {
      Environment   = "Production"
      Project       = "3tier-app"
      ManagedBy     = "Terraform"
      DeploymentID  = var.deployment_id
    },
    var.tags
  )
}
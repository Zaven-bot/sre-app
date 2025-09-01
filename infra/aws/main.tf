# Simple EKS Terraform - What you ACTUALLY need
terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

provider "aws" {
  region = "us-west-2"
}

# Variables
variable "environment" {
  default = "dev"
}

# Get existing VPC (or create simple one)
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ECR repositories
resource "aws_ecr_repository" "backend" {
  name = "sre-app/backend"
  force_delete = true
}

resource "aws_ecr_repository" "frontend" {
  name = "sre-app/frontend"
  force_delete = true
}

# EKS cluster
resource "aws_eks_cluster" "main" {
  name     = "sre-learning-cluster"
  role_arn = aws_iam_role.cluster_role.arn
  
  vpc_config {
    subnet_ids = data.aws_subnets.default.ids
  }
  
  # Ensure IAM role is ready before creating cluster
  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy
  ]
}

# IAM roles (minimal)
resource "aws_iam_role" "cluster_role" {
  name = "eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster_role.name
}

# Node group
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "main-nodes"
  node_role_arn   = aws_iam_role.node_role.arn
  subnet_ids      = data.aws_subnets.default.ids
  
  instance_types = ["t3.small"]
  capacity_type  = "SPOT"
  disk_size      = 20  # GB - minimum for EKS
  
  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 1
  }
  
  # Ensure IAM policies are attached before creating nodes
  depends_on = [
    aws_iam_role_policy_attachment.node_policies
  ]
}

# Node IAM role
resource "aws_iam_role" "node_role" {
  name = "eks-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# Required policies
resource "aws_iam_role_policy_attachment" "node_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ])
  
  policy_arn = each.value
  role       = aws_iam_role.node_role.name
}

# Outputs
output "backend_ecr_repository_url" {
  value = aws_ecr_repository.backend.repository_url
}

output "frontend_ecr_repository_url" {
  value = aws_ecr_repository.frontend.repository_url
}
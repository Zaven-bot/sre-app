# Environment Differentiation Strategies for AWS

## 1. Same Account, Different Resources (Current Approach)

### How it works:
- Single AWS account
- Environment variable controls resource sizing
- Different resource names/tags per environment

### Pros:
- Simple to manage
- Cost-effective for learning
- Easy to compare environments

### Cons:
- Shared account limits
- Risk of accidentally affecting production
- Harder to implement strict access controls

### Example Configuration:
```hcl
# Different cluster names
cluster_name = "${var.environment}-sre-cluster"

# Different instance types
instance_types = var.environment == "production" ? ["t3.small", "t3.medium"] : ["t3.micro"]

# Different scaling
desired_size = var.environment == "production" ? 2 : 1
```

## 2. Separate AWS Accounts (Enterprise Approach)

### How it works:
- Dedicated AWS account per environment
- Complete isolation between environments
- Cross-account roles for shared services

### Pros:
- Complete isolation
- Independent billing
- Strict access control
- Production safety

### Cons:
- More complex to manage
- Higher overhead
- Need AWS Organizations

### Example Structure:
```
AWS Organization
├── dev-account (123456789012)
├── staging-account (123456789013)
└── prod-account (123456789014)
```

## 3. Separate Regions (Geographic Approach)

### How it works:
- Same account, different AWS regions
- Environment-specific regions
- Regional isolation

### Pros:
- Natural isolation
- Disaster recovery benefits
- Region-specific compliance

### Cons:
- Data transfer costs
- Service availability differences
- More complex networking

### Example:
```hcl
# Development in us-west-2
# Production in us-east-1
region = var.environment == "production" ? "us-east-1" : "us-west-2"
```

## 4. Workspace-Based (Terraform Workspaces)

### How it works:
- Single Terraform configuration
- Multiple workspaces for different environments
- State isolation per workspace

### Pros:
- Clean state separation
- DRY configuration
- Easy switching

### Cons:
- Risk of workspace confusion
- Shared backend complexity

### Example Usage:
```bash
# Create workspaces
terraform workspace new dev
terraform workspace new production

# Switch and deploy
terraform workspace select dev
terraform apply

terraform workspace select production
terraform apply
```

## Current Implementation Analysis

Your current setup uses **Strategy #1 (Same Account, Different Resources)**:

```hcl
# From your main.tf
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# Conditional resource creation
count = var.environment == "production" ? 2 : 1

# Environment-based tagging
default_tags {
  tags = {
    Environment = var.environment
    # ...
  }
}
```

## Recommended Improvements for Your Setup

### 1. Better Environment Validation
```hcl
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
  
  validation {
    condition = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}
```

### 2. Environment-Specific Naming
```hcl
locals {
  cluster_name = "${var.environment}-${var.cluster_name}"
  
  common_tags = {
    Environment = var.environment
    Project     = "SRE-Learning-App"
    ManagedBy   = "Terraform"
  }
}
```

### 3. Configuration Maps
```hcl
locals {
  environment_config = {
    dev = {
      instance_types    = ["t3.micro", "t3.small"]
      desired_capacity  = 1
      max_capacity     = 2
      nat_gateways     = 1
      log_retention    = 7
      capacity_type    = "SPOT"
    }
    
    staging = {
      instance_types    = ["t3.small"]
      desired_capacity  = 2
      max_capacity     = 3
      nat_gateways     = 1
      log_retention    = 14
      capacity_type    = "ON_DEMAND"
    }
    
    prod = {
      instance_types    = ["t3.small", "t3.medium"]
      desired_capacity  = 3
      max_capacity     = 6
      nat_gateways     = 2
      log_retention    = 30
      capacity_type    = "ON_DEMAND"
    }
  }
  
  config = local.environment_config[var.environment]
}
```

## Deployment Workflow Examples

### Development Workflow
```bash
# Deploy development environment
export ENVIRONMENT=dev
./scripts/deploy-aws.sh

# Or with Terraform directly
terraform apply -var="environment=dev"
```

### Production Workflow
```bash
# Deploy production environment
export ENVIRONMENT=prod
./scripts/deploy-aws.sh

# With additional safety checks
terraform plan -var="environment=prod" -out=prod.plan
# Review the plan carefully
terraform apply prod.plan
```

## Security and Access Control

### Environment-Based IAM Policies
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["eks:*"],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "us-west-2",
          "eks:cluster-name": "dev-*"
        }
      }
    }
  ]
}
```

### Resource-Based Policies
```hcl
# Different security groups per environment
resource "aws_security_group" "app" {
  name_prefix = "${var.environment}-app-"
  
  # More restrictive rules for production
  dynamic "ingress" {
    for_each = var.environment == "prod" ? [80, 443] : [80, 443, 8080, 3000]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}
```

## Best Practices Summary

1. **Use environment variables** to control resource allocation
2. **Implement validation** to prevent typos in environment names
3. **Use consistent naming** with environment prefixes
4. **Tag everything** with environment information
5. **Different configurations** for different environments
6. **Security boundaries** based on environment sensitivity
7. **Cost controls** more aggressive in dev than prod
8. **Monitoring and alerting** environment-specific thresholds

The key insight is that **AWS doesn't know about your environments - you define them through your infrastructure code and deployment processes!**

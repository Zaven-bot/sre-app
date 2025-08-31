# AWS Deployment Guide

This guide covers deploying the SRE Learning App to AWS EKS with cost optimization.

## Quick Start

### Prerequisites
```bash
# Required tools
brew install terraform awscli kubectl

# Configure AWS credentials
aws configure
```

### One-Command Deployment
```bash
# Deploy to development environment (cost-optimized)
./scripts/deploy-aws.sh

# Or specify environment explicitly
ENVIRONMENT=development ./scripts/deploy-aws.sh deploy
```

### Environment Variables
```bash
export ENVIRONMENT=development     # or production
export AWS_REGION=us-west-2       # or your preferred region
export CLUSTER_NAME=sre-learning-cluster
```

## Cost-Conscious Deployment

### Development Environment (~$145/month)
- Single NAT Gateway (saves $45/month)
- Spot instances (saves ~$27/month)
- Smaller storage volumes
- Shorter log retention
- Single node minimum

```bash
ENVIRONMENT=development ./scripts/deploy-aws.sh deploy
```

### Production Environment (~$223/month)
- High availability with dual NAT Gateways
- On-demand instances for reliability
- Larger storage allocation
- Extended log retention
- Multi-node setup

```bash
ENVIRONMENT=production ./scripts/deploy-aws.sh deploy
```

## Manual Deployment Steps

### 1. Deploy Infrastructure
```bash
cd infra/aws
terraform init
terraform plan -var="environment=development"
terraform apply -var="environment=development"
```

### 2. Configure kubectl
```bash
aws eks update-kubeconfig --region us-west-2 --name sre-learning-cluster
kubectl get nodes
```

### 3. Build and Push Images
```bash
# Get ECR repository URLs
BACKEND_ECR=$(terraform output -raw backend_ecr_repository_url)
FRONTEND_ECR=$(terraform output -raw frontend_ecr_repository_url)

# Login to ECR
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin $BACKEND_ECR

# Build and push
docker build -f docker/Dockerfile.backend -t $BACKEND_ECR:latest .
docker push $BACKEND_ECR:latest

docker build -f docker/Dockerfile.frontend -t $FRONTEND_ECR:latest .
docker push $FRONTEND_ECR:latest
```

### 4. Deploy to Kubernetes
```bash
# Update manifests with ECR URLs (done automatically by script)
kubectl apply -f k8s/
kubectl wait --for=condition=available --timeout=300s deployment/backend
kubectl wait --for=condition=available --timeout=300s deployment/frontend
```

## Infrastructure Components

### Core AWS Resources
- **EKS Cluster**: Kubernetes control plane ($73/month)
- **EC2 Node Group**: Worker nodes (variable cost)
- **VPC**: Networking with public/private subnets
- **NAT Gateway**: Outbound internet for private subnets
- **ECR Repositories**: Container image storage
- **CloudWatch**: Logging and monitoring

### Kubernetes Resources
- **Deployments**: Backend, Frontend, Redis
- **Services**: LoadBalancer and ClusterIP types
- **ConfigMaps**: Application configuration
- **Secrets**: Sensitive data (Redis password)
- **HPA**: Horizontal Pod Autoscaler
- **Network Policies**: Security controls
- **Monitoring**: Prometheus and Grafana

## Cost Monitoring

### Check Current Costs
```bash
# AWS CLI cost reports
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost

# Or use AWS Console Cost Explorer
```

### Set Up Cost Alerts
```bash
# Create a budget alert
aws budgets create-budget \
  --account-id $(aws sts get-caller-identity --query Account --output text) \
  --budget file://budget.json
```

## Troubleshooting

### Common Issues

1. **ECR Permission Denied**
```bash
# Re-login to ECR
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-west-2.amazonaws.com
```

2. **kubectl Connection Issues**
```bash
# Reconfigure kubectl
aws eks update-kubeconfig --region us-west-2 --name sre-learning-cluster
```

3. **Node Not Ready**
```bash
# Check node status
kubectl describe nodes
kubectl get events --sort-by=.metadata.creationTimestamp
```

4. **Pod ImagePullBackOff**
```bash
# Check ECR repository and permissions
kubectl describe pod <pod-name>
aws ecr describe-repositories
```

### Debugging Commands
```bash
# Cluster status
kubectl get all
kubectl get nodes -o wide

# Pod logs
kubectl logs -l app=backend --tail=50
kubectl logs -l app=frontend --tail=50

# Service endpoints
kubectl get endpoints

# Resource usage
kubectl top nodes
kubectl top pods
```

## Security Considerations

### Production Hardening
1. **Network Security**
   - Restrict EKS API public access
   - Use private endpoints where possible
   - Configure Network ACLs

2. **IAM Security**
   - Use IAM roles for service accounts (IRSA)
   - Implement least privilege access
   - Regular credential rotation

3. **Container Security**
   - Scan images for vulnerabilities
   - Use non-root containers
   - Implement Pod Security Standards

4. **Data Security**
   - Encrypt EBS volumes
   - Use AWS Secrets Manager
   - Enable audit logging

## Scaling and Performance

### Horizontal Pod Autoscaler
```bash
# HPA is configured to scale based on CPU/memory
kubectl get hpa
kubectl describe hpa backend-hpa
```

### Cluster Autoscaler
```bash
# Install cluster autoscaler (optional)
kubectl apply -f https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml
```

### Performance Monitoring
```bash
# Access Grafana dashboard
kubectl port-forward svc/grafana 3000:3000

# Access Prometheus
kubectl port-forward svc/prometheus-service 9090:9090
```

## Cleanup

### Destroy Everything
```bash
# Use the script for safe cleanup
./scripts/deploy-aws.sh destroy

# Or manually
kubectl delete -f k8s/
cd infra/aws
terraform destroy -var="environment=development"
```

### Partial Cleanup
```bash
# Scale down applications but keep cluster
kubectl scale deployment backend --replicas=0
kubectl scale deployment frontend --replicas=0
kubectl scale deployment redis --replicas=0

# Scale down nodes
aws eks update-nodegroup-config \
  --cluster-name sre-learning-cluster \
  --nodegroup-name sre-learning-cluster-nodes \
  --scaling-config minSize=0,maxSize=1,desiredSize=0
```

## Cost Optimization Tips

1. **Development Workflow**
   - Destroy environments when not in use
   - Use spot instances for testing
   - Scale down during off-hours

2. **Resource Right-Sizing**
   - Monitor actual resource usage
   - Adjust requests/limits based on data
   - Use AWS Compute Optimizer

3. **Storage Optimization**
   - Clean up old ECR images regularly
   - Use GP3 volumes for better cost/performance
   - Optimize log retention periods

4. **Network Optimization**
   - Minimize cross-AZ data transfer
   - Use single NAT Gateway for dev
   - Consider VPC endpoints for AWS services

## Next Steps

1. **CI/CD Integration**: Update GitHub Actions to deploy to AWS
2. **Monitoring Enhancement**: Add custom metrics and alerts
3. **Security Hardening**: Implement security best practices
4. **Performance Optimization**: Load testing and optimization
5. **Cost Management**: Set up automated cost controls

For detailed cost information, see [Cost Optimization Guide](docs/cost-optimization.md).

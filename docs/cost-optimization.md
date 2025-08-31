# AWS Cost Optimization Guide for SRE App

This document outlines cost optimization strategies implemented in the Terraform configuration and additional measures you can take.

## Implemented Cost Optimizations

### 1. Environment-Based Resource Scaling
- **Development/Test**: Single NAT Gateway, smaller instances, spot instances
- **Production**: High availability with redundancy and on-demand instances

### 2. Compute Optimizations
- **Instance Types**: 
  - Development: t3.micro/t3.small (cost-effective)
  - Production: t3.small/t3.medium (balanced performance/cost)
- **Spot Instances**: Used in development for 60-90% cost savings
- **Right-sizing**: Smaller disk sizes for non-production (20GB vs 50GB)

### 3. Network Cost Optimizations
- **Single NAT Gateway**: For development environments saves ~$45/month
- **Production**: Dual NAT gateways for high availability

### 4. Storage Optimizations
- **ECR Lifecycle Policies**: Automatically clean up old images
- **CloudWatch Log Retention**: Shorter retention for dev (7 days vs 30 days)
- **EBS GP3**: Better cost/performance ratio

### 5. ECR Cost Management
- **Image Lifecycle**: Keep only 10 tagged images, clean untagged immediately
- **Security Scanning**: Included for vulnerability management

## Monthly Cost Estimates (CORRECTED)

### Standard Development Environment
| Service | Cost | Notes |
|---------|------|-------|
| EKS Cluster | $73 | Fixed cost (unavoidable) |
| EC2 (1x t3.micro spot) | $4 | ~90% savings with spot |
| NAT Gateway (1) | $45 | **Major cost driver!** |
| Application Load Balancer | $16 | For LoadBalancer services |
| EBS Storage (20GB) | $2 | gp3 storage |
| **Total** | **~$140** | |

### Ultra-Low-Cost Development (For Lightweight Apps)
| Service | Cost | Notes |
|---------|------|-------|
| EKS Cluster | $73 | Fixed cost (unavoidable) |
| EC2 (1x t3.micro spot) | $4 | Single small instance |
| NAT Gateway | $0 | **ELIMINATED** ✅ |
| Load Balancer | $0 | **Use NodePort instead** ✅ |
| EBS Storage (10GB) | $1 | Minimal storage |
| **Total** | **~$78** | **Save $62/month!** |

### Production Environment
| Service | Cost | Notes |
|---------|------|-------|
| EKS Cluster | $73 | Fixed cost |
| EC2 (2x t3.small) | $30 | On-demand for reliability |
| NAT Gateways (2) | $90 | High availability |
| Application Load Balancer | $16 | Production grade |
| EBS Storage (50GB) | $5 | Production size |
| **Total** | **~$214** | |

## Ultra-Low-Cost Deployment for Lightweight Apps

Since your app isn't intensive, you can eliminate the two biggest cost drivers:

### 💰 **Ultra-Low-Cost Mode (~$78/month)**

```bash
# Deploy without NAT Gateway and Load Balancer
ULTRA_LOW_COST=true ./scripts/deploy-aws-ultra-low-cost.sh ultra
```

**What changes:**
- ✅ **No NAT Gateway**: Deploy nodes in public subnets (saves $45/month)
- ✅ **No Load Balancer**: Use NodePort services (saves $16/month)  
- ✅ **Minimal storage**: 10GB instead of 20GB (saves $1/month)
- ✅ **Single t3.micro spot**: Perfect for lightweight apps

**Access your app:**
```bash
# Get node IP and port
kubectl get nodes -o wide
kubectl get svc

# Or use port-forwarding
kubectl port-forward svc/frontend-service 8080:80
kubectl port-forward svc/backend-service 5000:5000
```

### 🔄 **Easy Mode Switching**

```bash
# Ultra-low-cost (no NAT, no LB)
./scripts/deploy-aws-ultra-low-cost.sh ultra

# Standard dev (with NAT and LB)  
./scripts/deploy-aws.sh

# Production (full redundancy)
ENVIRONMENT=production ./scripts/deploy-aws.sh
```

### 1. Compute Optimizations
```bash
# Use cluster autoscaler to scale down during low usage
kubectl apply -f https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml

# Configure HPA for automatic scaling
kubectl apply -f k8s/hpa.yaml
```

### 2. Scheduled Scaling
```bash
# Create a cron job to scale down nodes during off-hours (weekends)
# Add to k8s manifests or use AWS Lambda
```

### 3. Resource Requests and Limits
```yaml
# Ensure all pods have resource requests/limits
resources:
  requests:
    memory: "64Mi"
    cpu: "50m"
  limits:
    memory: "128Mi"
    cpu: "100m"
```

### 4. Monitoring and Alerting
```bash
# Set up cost alerts
aws budgets create-budget --account-id $(aws sts get-caller-identity --query Account --output text) --budget '{
  "BudgetName": "SRE-App-Monthly",
  "BudgetLimit": {
    "Amount": "200",
    "Unit": "USD"
  },
  "TimeUnit": "MONTHLY",
  "BudgetType": "COST"
}'
```

### 5. Development Workflow Optimizations
```bash
# Use the deployment script to tear down dev environments when not in use
./scripts/deploy-aws.sh destroy

# Use port-forwarding for development instead of load balancers
kubectl port-forward svc/frontend-service 8080:80
kubectl port-forward svc/backend-service 5000:5000
```

## Cost Monitoring

### 1. AWS Cost Explorer
- Monitor daily costs
- Set up cost anomaly detection
- Track by service and tag

### 2. Terraform Cost Estimation
```bash
# Use terraform plan to estimate costs before deployment
terraform plan -var="environment=development"
```

### 3. Kubernetes Resource Monitoring
```bash
# Monitor resource usage
kubectl top nodes
kubectl top pods

# Use Prometheus metrics for detailed analysis
kubectl port-forward svc/prometheus-service 9090:9090
```

## Emergency Cost Controls

### 1. Immediate Shutdown
```bash
# Scale down all deployments
kubectl scale deployment backend --replicas=0
kubectl scale deployment frontend --replicas=0
kubectl scale deployment redis --replicas=0

# Or destroy the entire environment
./scripts/deploy-aws.sh destroy
```

### 2. Node Scaling
```bash
# Scale node group to minimum
aws eks update-nodegroup-config \
  --cluster-name sre-learning-cluster \
  --nodegroup-name sre-learning-cluster-nodes \
  --scaling-config minSize=0,maxSize=1,desiredSize=0
```

## Best Practices

1. **Tag Everything**: Use consistent tagging for cost allocation
2. **Regular Reviews**: Weekly cost reviews and optimization
3. **Right-Size Regularly**: Use AWS Compute Optimizer recommendations
4. **Use Savings Plans**: For predictable workloads in production
5. **Monitor Data Transfer**: Minimize inter-AZ data transfer costs
6. **Clean Up Regularly**: Remove unused resources and old ECR images

## Development vs Production Trade-offs

| Aspect | Development | Production |
|--------|-------------|------------|
| Availability | Single AZ OK | Multi-AZ required |
| Instance Types | Spot instances | On-demand |
| Monitoring | Basic | Comprehensive |
| Backup | Optional | Required |
| Security | Relaxed | Strict |
| Cost | Optimized | Balanced with reliability |

Remember: The goal is to minimize costs while maintaining the learning objectives for SRE practices!

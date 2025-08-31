#!/bin/bash

# AWS EKS Deployment Script for SRE App
# Simple, clean deployment to AWS EKS

set -e  # Exit on any error

# Default variables
ENVIRONMENT=${ENVIRONMENT:-dev}
AWS_REGION=${AWS_REGION:-us-east-1}
CLUSTER_NAME=${CLUSTER_NAME:-sre-learning-cluster}
PROJECT_NAME=${PROJECT_NAME:-sre-learning}

echo "🚀 Starting AWS EKS deployment for SRE App"
echo "Environment: ${ENVIRONMENT}"
echo "Region: ${AWS_REGION}"
echo "Cluster: ${CLUSTER_NAME}"

# Check prerequisites
echo "Checking prerequisites..."
for tool in terraform aws kubectl docker; do
    if ! command -v $tool &> /dev/null; then
        echo "❌ $tool is not installed"
        exit 1
    fi
done

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured"
    echo "Please run: aws configure"
    exit 1
fi

echo "✅ All prerequisites met"

# Show cost estimation
echo ""
echo "💰 Cost Estimates:"
if [ "$ENVIRONMENT" = "production" ]; then
    echo 'Production: ~$214/month (2 nodes, 2 NAT gateways, on-demand instances)'
else
    echo 'Dev: ~$78/month (1 node, no NAT gateway, spot instances, NodePort services)'
    echo "💡 Dev mode optimized for cost savings"
fi

# Confirm deployment
echo ""
echo "⚠️ This will create AWS resources that may incur costs."
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Deployment cancelled"
    exit 1
fi

# Deploy infrastructure with Terraform
echo ""
echo "🏗️ Deploying infrastructure with Terraform..."

cd infra/aws
terraform init

# Build terraform variables (simplified for your Terraform)
TERRAFORM_VARS="-var=environment=$ENVIRONMENT"

# Apply infrastructure
terraform apply $TERRAFORM_VARS -auto-approve

cd ../..

# Configure kubectl
echo ""
echo "⚙️ Configuring kubectl..."
aws eks update-kubeconfig --region ${AWS_REGION} --name ${CLUSTER_NAME}

# Test the connection
if kubectl get nodes &> /dev/null; then
    echo "✅ Successfully connected to EKS cluster"
    kubectl get nodes
else
    echo "❌ Failed to connect to EKS cluster"
    exit 1
fi

# Build and push Docker images
echo ""
echo "🐳 Building and pushing Docker images..."

# Get ECR repository URLs from Terraform output
BACKEND_ECR=$(terraform -chdir=infra/aws output -raw backend_ecr_repository_url)
FRONTEND_ECR=$(terraform -chdir=infra/aws output -raw frontend_ecr_repository_url)

# Login to ECR
echo "🔑 Logging into ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${BACKEND_ECR%/*}

# Build and push backend image
echo "🔨 Building backend image..."
docker build -f docker/Dockerfile.backend -t ${BACKEND_ECR}:latest .
docker push ${BACKEND_ECR}:latest
echo "✅ Backend image pushed"

# Build and push frontend image
echo "🔨 Building frontend image..."
docker build -f docker/Dockerfile.frontend -t ${FRONTEND_ECR}:latest .
docker push ${FRONTEND_ECR}:latest
echo "✅ Frontend image pushed"

# Update Kubernetes manifests
echo ""
echo "📝 Updating Kubernetes manifests..."

mkdir -p temp-k8s

# Process all YAML files
for file in k8s/*.yaml; do
    basename_file=$(basename "$file")
    
    # Replace image references and pull policy
    sed -e "s|sre-learning-app-backend:latest|${BACKEND_ECR}:latest|g" \
        -e "s|sre-learning-app-frontend:latest|${FRONTEND_ECR}:latest|g" \
        -e "s|imagePullPolicy: Never|imagePullPolicy: Always|g" \
        "$file" > "temp-k8s/$basename_file"
    
    # For dev environment, convert LoadBalancer to NodePort for cost savings
    if [ "$ENVIRONMENT" != "production" ]; then
        sed -i.bak "s|type: LoadBalancer|type: NodePort|g" "temp-k8s/$basename_file"
        rm -f "temp-k8s/$basename_file.bak"
    fi
done

if [ "$ENVIRONMENT" != "production" ]; then
    echo "💰 Converted LoadBalancer services to NodePort for cost savings"
fi

# Deploy to Kubernetes
echo ""
echo "☸️ Deploying to Kubernetes..."

# Apply all manifests
kubectl apply -f temp-k8s/

# Wait for deployments to be ready
echo "⏳ Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/backend-deployment
kubectl wait --for=condition=available --timeout=300s deployment/frontend-deployment

echo "✅ All deployments are ready"

# Show status
kubectl get pods -o wide
kubectl get services

# Show access information
echo ""
echo "🌐 Application Access:"

if [ "$ENVIRONMENT" != "production" ]; then
    echo "📡 NodePort mode - use port-forwarding to access:"
    echo "  kubectl port-forward svc/frontend-service 8080:80"
    echo "  kubectl port-forward svc/backend-service 5000:5000"
    echo ""
    echo "Or check node IP and NodePort:"
    echo "  kubectl get nodes -o wide"
    echo "  kubectl get svc"
else
    echo "⏳ Waiting for LoadBalancer to be ready..."
    echo "Check status with: kubectl get svc"
    echo "Once ready, access via the LoadBalancer hostname"
fi

# Cleanup function
cleanup() {
    echo "🧹 Cleaning up temporary files..."
    rm -rf temp-k8s
}

# Cleanup on exit
trap cleanup EXIT

echo ""
echo "🎉 Deployment completed successfully!"

if [ "$ENVIRONMENT" != "production" ]; then
    echo 'Monthly cost: ~$78 (optimized for development)'
    echo "📝 Note: Using NodePort instead of LoadBalancer for cost savings"
fi

echo ""
echo "📚 Useful commands:"
echo "  kubectl get pods"
echo "  kubectl logs -l app=backend"
echo "  kubectl logs -l app=frontend"
echo "  kubectl port-forward svc/frontend-service 8080:80"
echo "  kubectl port-forward svc/backend-service 5000:5000"

# Handle different command modes
case "${1:-}" in
    "destroy")
        echo ""
        echo "⚠️ This will destroy all AWS resources!"
        read -p "Are you sure? Type 'yes' to confirm: " confirmation
        if [ "$confirmation" = "yes" ]; then
            kubectl delete -f temp-k8s/ 2>/dev/null || true
            cd infra/aws
            
            # Build destroy vars (simplified)
            DESTROY_VARS="-var=environment=${ENVIRONMENT}"
            
            terraform destroy $DESTROY_VARS -auto-approve
            cd ../..
            echo "✅ Resources destroyed"
        else
            echo "❌ Destruction cancelled"
        fi
        ;;
    "status")
        kubectl get all
        ;;
    "logs")
        echo "--- Backend logs ---"
        kubectl logs -l app=backend --tail=50
        echo ""
        echo "--- Frontend logs ---"
        kubectl logs -l app=frontend --tail=50
        ;;
    "help"|"--help"|"-h")
        echo ""
        echo "Usage: $0 [destroy|status|logs|help]"
        echo "  (no args) - Deploy the application"
        echo "  destroy   - Destroy all AWS resources"
        echo "  status    - Show cluster status"
        echo "  logs      - Show application logs"
        echo "  help      - Show this help"
        echo ""
        echo "Environment variables:"
        echo "  ENVIRONMENT=dev|production (default: dev)"
        echo "  AWS_REGION=us-east-1 (default)"
        echo "  CLUSTER_NAME=sre-learning-cluster (default)"
        echo ""
        echo "Examples:"
        echo '  ./deploy-aws.sh                    # Cost-optimized dev deployment (~$78/month)'
        echo '  ENVIRONMENT=production ./deploy-aws.sh # Production deployment (~$214/month)'
        echo "  ./deploy-aws.sh destroy             # Destroy everything"
        ;;
esac

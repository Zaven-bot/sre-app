# Deployment helper script for AWS
#!/bin/bash

set -e

echo "🚀 AWS Deployment Helper"
echo "======================="

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS CLI not configured. Run 'aws configure' first."
    exit 1
fi

CLUSTER_NAME="sre-learning-cluster"
REGION="us-west-2"

# Function to deploy infrastructure
deploy_infrastructure() {
    echo "🏗️  Deploying AWS infrastructure..."
    cd infra/aws
    
    terraform init
    terraform plan -out=tfplan
    echo ""
    echo "⚠️  WARNING: This will create real AWS resources that cost money!"
    echo "Review the plan above. Continue? (y/N)"
    read -r confirm
    
    if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
        terraform apply tfplan
        echo "✅ Infrastructure deployed!"
    else
        echo "❌ Deployment cancelled"
        exit 1
    fi
    
    cd ../..
}

# Function to configure kubectl
configure_kubectl() {
    echo "⚙️  Configuring kubectl..."
    aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME
    echo "✅ kubectl configured"
}

# Function to build and push images to ECR
build_and_push_images() {
    echo "🐳 Building and pushing Docker images..."
    
    # Create ECR repositories if they don't exist
    aws ecr describe-repositories --repository-names sre-learning/frontend --region $REGION 2>/dev/null || \
        aws ecr create-repository --repository-name sre-learning/frontend --region $REGION
        
    aws ecr describe-repositories --repository-names sre-learning/backend --region $REGION 2>/dev/null || \
        aws ecr create-repository --repository-name sre-learning/backend --region $REGION
    
    # Get ECR login token
    aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.$REGION.amazonaws.com
    
    # Get account ID
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    ECR_REGISTRY="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"
    
    # Build and push images
    echo "Building frontend image..."
    docker build -t $ECR_REGISTRY/sre-learning/frontend:latest -f docker/Dockerfile.frontend .
    docker push $ECR_REGISTRY/sre-learning/frontend:latest
    
    echo "Building backend image..."
    docker build -t $ECR_REGISTRY/sre-learning/backend:latest -f docker/Dockerfile.backend .
    docker push $ECR_REGISTRY/sre-learning/backend:latest
    
    echo "✅ Images pushed to ECR"
    
    # Update Kubernetes manifests with ECR image URLs
    sed -i.bak "s|image: sre-learning-app/frontend:latest|image: $ECR_REGISTRY/sre-learning/frontend:latest|" k8s/deployment-frontend.yaml
    sed -i.bak "s|image: sre-learning-app/backend:latest|image: $ECR_REGISTRY/sre-learning/backend:latest|" k8s/deployment-backend.yaml
    
    echo "✅ Kubernetes manifests updated"
}

# Function to deploy application to EKS
deploy_application() {
    echo "☸️  Deploying application to EKS..."
    
    # Apply Kubernetes manifests
    kubectl apply -f k8s/
    
    # Wait for deployments to be ready
    echo "⏳ Waiting for deployments..."
    kubectl wait --for=condition=available --timeout=300s deployment/frontend-deployment
    kubectl wait --for=condition=available --timeout=300s deployment/backend-deployment
    
    echo "✅ Application deployed!"
}

# Function to setup monitoring
setup_monitoring() {
    echo "📊 Setting up monitoring..."
    ./scripts/monitoring-setup.sh all
    echo "✅ Monitoring setup complete!"
}

# Function to get application URL
get_application_url() {
    echo "🌐 Getting application URL..."
    
    # Check if LoadBalancer service exists and get external IP
    if kubectl get service frontend-loadbalancer &> /dev/null; then
        echo "Waiting for LoadBalancer to get external IP..."
        external_ip=""
        while [ -z $external_ip ]; do
            external_ip=$(kubectl get service frontend-loadbalancer --template="{{range .status.loadBalancer.ingress}}{{.hostname}}{{.ip}}{{end}}")
            [ -z "$external_ip" ] && sleep 10
        done
        echo "🎉 Application URL: http://$external_ip"
    elif kubectl get ingress app-ingress &> /dev/null; then
        ingress_host=$(kubectl get ingress app-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
        if [ ! -z "$ingress_host" ]; then
            echo "🎉 Application URL: http://$ingress_host"
        else
            echo "ℹ️  Ingress created but no external hostname yet. Check later with:"
            echo "   kubectl get ingress app-ingress"
        fi
    else
        echo "ℹ️  No LoadBalancer or Ingress found. Use port forwarding:"
        echo "   kubectl port-forward service/frontend-service 8080:80"
        echo "   Then visit: http://localhost:8080"
    fi
}

# Function to show status
show_status() {
    echo "📊 Current Status:"
    echo "=================="
    
    echo "🏗️  Infrastructure:"
    cd infra/aws
    if [ -f terraform.tfstate ]; then
        terraform output 2>/dev/null || echo "   No outputs available"
    else
        echo "   Not deployed"
    fi
    cd ../..
    
    echo ""
    echo "☸️  Kubernetes:"
    if kubectl cluster-info &> /dev/null; then
        echo "   ✅ Connected to cluster"
        kubectl get nodes --no-headers | wc -l | xargs echo "   📦 Nodes:"
        kubectl get pods --no-headers | wc -l | xargs echo "   🐳 Pods:"
        kubectl get services --no-headers | wc -l | xargs echo "   🌐 Services:"
    else
        echo "   ❌ Not connected to cluster"
    fi
    
    echo ""
    echo "📊 Application Pods:"
    kubectl get pods -l app=frontend,app=backend 2>/dev/null || echo "   No application pods found"
}

# Function to cleanup
cleanup() {
    echo "🧹 Cleanup AWS Resources"
    echo "======================"
    echo "⚠️  This will destroy ALL AWS resources created by this project!"
    echo "Continue? (y/N)"
    read -r confirm
    
    if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
        cd infra/aws
        terraform destroy
        cd ../..
        echo "✅ AWS resources cleaned up"
    else
        echo "❌ Cleanup cancelled"
    fi
}

# Main menu
case "${1:-menu}" in
    "infra")
        deploy_infrastructure
        ;;
    "kubectl")
        configure_kubectl
        ;;
    "images")
        build_and_push_images
        ;;
    "app")
        deploy_application
        ;;
    "monitoring")
        setup_monitoring
        ;;
    "url")
        get_application_url
        ;;
    "status")
        show_status
        ;;
    "cleanup")
        cleanup
        ;;
    "all")
        deploy_infrastructure
        configure_kubectl
        build_and_push_images
        deploy_application
        setup_monitoring
        get_application_url
        ;;
    "menu")
        echo "AWS Deployment Helper"
        echo "===================="
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  infra      - Deploy AWS infrastructure (EKS cluster)"
        echo "  kubectl    - Configure kubectl for EKS"
        echo "  images     - Build and push Docker images to ECR"
        echo "  app        - Deploy application to Kubernetes"
        echo "  monitoring - Setup monitoring stack"
        echo "  url        - Get application URL"
        echo "  status     - Show current deployment status"
        echo "  cleanup    - Destroy all AWS resources"
        echo "  all        - Deploy everything"
        echo ""
        echo "Prerequisites:"
        echo "  - AWS CLI configured (aws configure)"
        echo "  - Docker running"
        echo "  - kubectl installed"
        echo "  - Terraform installed"
        ;;
    *)
        echo "❌ Unknown command: $1"
        echo "Run '$0 menu' to see available commands"
        exit 1
        ;;
esac

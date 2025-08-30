#!/bin/bash

# SRE Learning App - Kubernetes Deployment Script
# This script deploys the complete application stack to Kubernetes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if kubectl is available
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed or not in PATH"
        exit 1
    fi
    
    # Check if kubectl can connect to cluster
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    
    print_success "Connected to Kubernetes cluster"
}

# Function to check if required images exist
check_images() {
    print_status "Checking if Docker images exist..."
    
    # Only check for images we're building (not pulling from registry)
    images=(
        "sre-learning-app-backend:latest"
        "sre-learning-app-frontend:latest"
    )
    
    missing_images=()
    
    for image in "${images[@]}"; do
        if ! docker image inspect "$image" > /dev/null 2>&1; then
            missing_images+=("$image")
        fi
    done
    
    if [ ${#missing_images[@]} -ne 0 ]; then
        echo "❌ Missing Docker images:"
        printf "   - %s\n" "${missing_images[@]}"
        echo ""
        echo "💡 Build images first with:"
        echo "   cd docker && docker compose build"
        return 1
    fi

    print_success "All required Docker images found"
    return 0
}

# Add this function to deploy.sh# Update import_dashboards function in deploy.sh:
import_dashboards() {
    print_status "Checking for Grafana dashboards..."
    
    # Check if dashboard file exists
    if [ ! -f "../monitoring/dashboards/backend-metrics.json" ]; then
        print_status "No dashboard file found - skipping dashboard import"
        print_status "Create ../monitoring/dashboards/backend-metrics.json to enable auto-import"
        return 0
    fi
    
    print_status "Dashboard file found - importing to Grafana..."
    
    # Check if Grafana is actually running
    if ! kubectl get pod -l app=grafana --no-headers | grep -q "Running"; then
        print_warning "Grafana pod is not running - skipping dashboard import"
        return 0
    fi
    
    # Port-forward in background for API access
    kubectl port-forward svc/grafana-service 3000:3000 &
    PF_PID=$!
    
    # Wait for port-forward to be ready
    sleep 5
    
    # Wait for Grafana to be fully ready
    print_status "Waiting for Grafana API to be ready..."
    for i in {1..15}; do  # Reduced timeout
        if curl -s -f -u admin:admin http://localhost:3000/api/health > /dev/null 2>&1; then
            print_success "Grafana API is ready"
            break
        fi
        if [ $i -eq 15 ]; then
            print_warning "Grafana API not ready - skipping dashboard import"
            kill $PF_PID 2>/dev/null || true
            return 0  # Don't fail, just skip
        fi
        sleep 2
    done
    
    # Import dashboard
    print_status "Importing backend metrics dashboard..."
    if curl -s -X POST \
        -H "Content-Type: application/json" \
        -u admin:admin \
        -d @../monitoring/dashboards/backend-metrics.json \
        http://localhost:3000/api/dashboards/db > /dev/null 2>&1; then
        print_success "Dashboard imported successfully"
    else
        print_warning "Dashboard import failed - continuing anyway"
    fi
    
    # Clean up port-forward
    kill $PF_PID 2>/dev/null || true
}

# Function to deploy components in order
deploy_components() {

    cd ../k8s

    print_status "Deploying Redis (database layer)..."
    kubectl apply -f deployment-redis.yaml
    
    print_status "Waiting for Redis to be ready..."
    kubectl wait --for=condition=ready pod -l app=redis --timeout=300s
    print_success "Redis is ready"

    print_status "Deploying Backend application..."
    kubectl apply -f deployment-backend.yaml
    kubectl apply -f service-backend.yaml
    
    print_status "Waiting for Backend to be ready..."
    kubectl wait --for=condition=ready pod -l app=backend --timeout=300s
    print_success "Backend is ready"

    print_status "Deploying Frontend application..."
    kubectl apply -f deployment-frontend.yaml
    kubectl apply -f service-frontend.yaml
    
    print_status "Waiting for Frontend to be ready..."
    kubectl wait --for=condition=ready pod -l app=frontend --timeout=300s
    print_success "Frontend is ready"
    
    print_status "Deploying Prometheus monitoring..."
    kubectl apply -f prometheus.yaml
    
    print_status "Waiting for Prometheus to be ready..."
    kubectl wait --for=condition=ready pod -l app=prometheus --timeout=300s
    print_success "Prometheus is ready"
    
    print_status "Deploying Grafana dashboards..."
    kubectl apply -f grafana.yaml
    
    print_status "Waiting for Grafana to be ready..."
    kubectl wait --for=condition=ready pod -l app=grafana --timeout=300s
    print_success "Grafana is ready"

    print_status "Importing Grafana dashboards..."
    # Add this line:
    import_dashboards
    print_success "Grafana dashboards imported"
    
    print_status "Deploying Horizontal Pod Autoscaler..."
    kubectl apply -f hpa.yaml
    print_success "HPA deployed"
    
    print_status "Deploying Network Policies..."
    kubectl apply -f network-policies.yaml
    print_success "Network Policies applied"
    
    # print_status "Deploying Ingress..."
    # kubectl apply -f ingress.yaml
    # print_success "Ingress deployed"

    # Return to scripts directory
    cd ../scripts
}

# Function to show deployment status
show_status() {
    print_status "Deployment Status:"
    echo
    
    print_status "Pods:"
    kubectl get pods -o wide
    echo
    
    print_status "Services:"
    kubectl get services
    echo
    
    print_status "Persistent Volume Claims:"
    kubectl get pvc
    echo
    
    print_status "Ingress:"
    kubectl get ingress
    echo
    
    print_status "HPA Status:"
    kubectl get hpa
    echo
}

# Function to show access information
show_access_info() {
    print_success "Deployment completed successfully!"
    echo
    print_status "Access Information:"
    
    # Get ingress IP/hostname
    INGRESS_IP=$(kubectl get ingress app-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    INGRESS_HOSTNAME=$(kubectl get ingress app-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    
    if [[ -n "$INGRESS_IP" ]]; then
        print_status "Application URL: http://$INGRESS_IP"
        print_status "Prometheus: http://$INGRESS_IP/prometheus"
        print_status "Grafana: http://$INGRESS_IP/grafana (admin/admin)"
    elif [[ -n "$INGRESS_HOSTNAME" ]]; then
        print_status "Application URL: http://$INGRESS_HOSTNAME"
        print_status "Prometheus: http://$INGRESS_HOSTNAME/prometheus"
        print_status "Grafana: http://$INGRESS_HOSTNAME/grafana (admin/admin)"
    else
        print_warning "Ingress not ready yet. You can also access services via port-forward:"
        print_status "Frontend: kubectl port-forward svc/frontend-service 8080:80"
        print_status "Backend: kubectl port-forward svc/backend-service 8000:5000"
        print_status "Prometheus: kubectl port-forward svc/prometheus-service 9090:9090"
        print_status "Grafana: kubectl port-forward svc/grafana-service 3000:3000"
    fi
    
    echo
    print_status "Useful commands:"
    print_status "  kubectl get pods                    # Check pod status"
    print_status "  kubectl logs -f deployment/backend-deployment  # View backend logs"
    print_status "  kubectl describe hpa backend-hpa    # Check autoscaling status"
    print_status "  kubectl get events --sort-by=.metadata.creationTimestamp  # Check recent events"
}

# Function to clean up deployment
cleanup() {
    print_status "Cleaning up deployment..."

    # Change to k8s directory
    cd ../k8s
    
    kubectl delete -f ingress.yaml --ignore-not-found=true
    kubectl delete -f network-policies.yaml --ignore-not-found=true
    kubectl delete -f hpa.yaml --ignore-not-found=true
    kubectl delete -f grafana.yaml --ignore-not-found=true
    kubectl delete -f prometheus.yaml --ignore-not-found=true
    kubectl delete -f service-frontend.yaml --ignore-not-found=true
    kubectl delete -f deployment-frontend.yaml --ignore-not-found=true
    kubectl delete -f service-backend.yaml --ignore-not-found=true
    kubectl delete -f deployment-backend.yaml --ignore-not-found=true
    kubectl delete -f deployment-redis.yaml --ignore-not-found=true
    

    # Return to scripts directory
    cd ../scripts

    print_success "Cleanup completed"
}

# Main execution
case "${1:-deploy}" in
    deploy)
        print_status "Starting SRE Learning App deployment..."
        check_kubectl
        check_images
        deploy_components
        show_status
        show_access_info
        ;;
    status)
        check_kubectl
        show_status
        ;;
    cleanup)
        check_kubectl
        cleanup
        ;;
    *)
        echo "Usage: $0 {deploy|status|cleanup}"
        echo "  deploy  - Deploy the complete application stack"
        echo "  status  - Show current deployment status"
        echo "  cleanup - Remove all deployed resources"
        exit 1
        ;;
esac

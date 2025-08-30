#!/bin/bash
# Local development setup script
# This script helps you get the SRE learning environment running locally

set -e  # Exit on any error

echo "🚀 Setting up SRE/DevOps Learning Environment"
echo "=============================================="

# Check for required tools
check_tool() {
    if ! command -v $1 &> /dev/null; then
        echo "❌ $1 is not installed. Please install it first."
        case $1 in
            docker)
                echo "   📦 Install Docker: https://docs.docker.com/get-docker/"
                ;;
            kubectl)
                echo "   ☸️  Install kubectl: https://kubernetes.io/docs/tasks/tools/"
                ;;
            minikube)
                echo "   🎯 Install minikube: https://minikube.sigs.k8s.io/docs/start/"
                ;;
            python3)
                echo "   🐍 Install Python: https://www.python.org/downloads/"
                ;;
        esac
        return 1
    else
        echo "✅ $1 is available"
        return 0
    fi
}

# Function to run backend locally
run_backend_local() {
    echo ""
    echo "🐍 Setting up Python backend..."
    cd app/backend
    
    # Create virtual environment if it doesn't exist
    if [ ! -d "venv" ]; then
        python3 -m venv venv
        echo "📦 Created Python virtual environment"
    fi
    
    # Activate virtual environment
    source venv/bin/activate
    
    # Install dependencies
    pip install -q -r requirements.txt
    echo "📦 Installed Python dependencies"
    
    # Run the backend
    echo "🚀 Starting Flask backend on http://localhost:5000"
    python app.py &
    BACKEND_PID=$!
    
    cd ../..
    return 0
}

# Function to run with Docker Compose
run_docker_compose() {
    echo ""
    echo "🐳 Running with Docker Compose..."
    cd docker
    
    # Build and run
    docker-compose up --build -d
    
    echo "🎉 Services started!"
    echo "   Frontend: http://localhost"
    echo "   Backend: http://localhost:5000"
    echo "   Prometheus: http://localhost:9090"
    echo "   Grafana: http://localhost:3000 (admin/admin)"
    
    cd ..
    return 0
}

# Function to setup Kubernetes locally
setup_kubernetes() {
    echo ""
    echo "☸️  Setting up local Kubernetes..."
    
    # Check if minikube is running
    if ! minikube status &> /dev/null; then
        echo "🎯 Starting minikube..."
        minikube start --driver=docker --memory=4g --cpus=2
    else
        echo "✅ minikube is already running"
    fi
    
    # Enable ingress addon
    minikube addons enable ingress
    echo "🌐 Enabled ingress addon"
    
    # Build Docker images in minikube environment
    echo "🏗️  Building Docker images for Kubernetes..."
    eval $(minikube docker-env)
    
    docker build -t sre-learning-app/frontend:latest -f docker/Dockerfile.frontend .
    docker build -t sre-learning-app/backend:latest -f docker/Dockerfile.backend .
    
    # Apply Kubernetes manifests
    echo "📋 Applying Kubernetes manifests..."
    kubectl apply -f k8s/
    
    # Wait for deployments
    echo "⏳ Waiting for deployments to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/frontend-deployment
    kubectl wait --for=condition=available --timeout=300s deployment/backend-deployment
    
    # Get minikube URL
    MINIKUBE_IP=$(minikube ip)
    echo ""
    echo "🎉 Kubernetes deployment complete!"
    echo "   Access your app at: http://$MINIKUBE_IP"
    echo "   Or use port forwarding:"
    echo "   kubectl port-forward service/frontend-service 8080:80"
    
    return 0
}

# Function to check application health
check_health() {
    echo ""
    echo "🏥 Checking application health..."
    
    # Check backend
    if curl -s http://localhost:5000/health > /dev/null; then
        echo "✅ Backend is healthy"
    else
        echo "❌ Backend is not responding"
    fi
    
    # Check frontend (if running on port 80)
    if curl -s http://localhost/health > /dev/null 2>&1; then
        echo "✅ Frontend is healthy"
    else
        echo "ℹ️  Frontend not accessible on port 80 (normal for local dev)"
    fi
    
    # Check Prometheus (if running)
    if curl -s http://localhost:9090/-/healthy > /dev/null 2>&1; then
        echo "✅ Prometheus is healthy"
    else
        echo "ℹ️  Prometheus not running"
    fi
}

# Function to cleanup
cleanup() {
    echo ""
    echo "🧹 Cleaning up..."
    
    # Stop Docker Compose
    if [ -f docker/docker-compose.yml ]; then
        cd docker
        docker-compose down -v 2>/dev/null || true
        cd ..
    fi
    
    # Stop local backend if running
    if [ ! -z "$BACKEND_PID" ]; then
        kill $BACKEND_PID 2>/dev/null || true
    fi
    
    echo "✅ Cleanup complete"
}

# Function to show logs
show_logs() {
    echo ""
    echo "📋 Showing application logs..."
    
    if docker-compose -f docker/docker-compose.yml ps | grep -q "Up"; then
        echo "🐳 Docker Compose logs:"
        cd docker
        docker-compose logs --tail=50
        cd ..
    elif kubectl get pods &> /dev/null; then
        echo "☸️  Kubernetes logs:"
        kubectl logs -l app=backend --tail=50
        echo "---"
        kubectl logs -l app=frontend --tail=50
    else
        echo "ℹ️  No containerized services found running"
    fi
}

# Main menu
show_menu() {
    echo ""
    echo "What would you like to do?"
    echo "1) 🐍 Run backend locally (Python)"
    echo "2) 🐳 Run with Docker Compose (recommended for beginners)"
    echo "3) ☸️  Deploy to local Kubernetes (minikube)"
    echo "4) 🏥 Check application health"
    echo "5) 📋 Show logs"
    echo "6) 🧹 Cleanup all services"
    echo "7) ❓ Show help"
    echo "8) 🚪 Exit"
    echo ""
}

show_help() {
    echo ""
    echo "🎓 SRE/DevOps Learning Guide"
    echo "============================"
    echo ""
    echo "This project demonstrates key SRE/DevOps concepts:"
    echo ""
    echo "🐍 Backend Development:"
    echo "   - Flask API with health checks"
    echo "   - Prometheus metrics"
    echo "   - Error handling and logging"
    echo ""
    echo "🐳 Containerization:"
    echo "   - Multi-stage Docker builds"
    echo "   - Docker Compose for local development"
    echo "   - Container security best practices"
    echo ""
    echo "☸️  Kubernetes:"
    echo "   - Deployments and Services"
    echo "   - Health checks and probes"
    echo "   - Ingress for routing"
    echo "   - Resource limits and requests"
    echo ""
    echo "📊 Monitoring:"
    echo "   - Prometheus for metrics collection"
    echo "   - Grafana for visualization"
    echo "   - Application health checks"
    echo ""
    echo "🔄 CI/CD:"
    echo "   - GitHub Actions workflow"
    echo "   - Automated testing and deployment"
    echo "   - Container image building"
    echo ""
    echo "☁️  Infrastructure:"
    echo "   - Terraform for AWS EKS"
    echo "   - Infrastructure as Code"
    echo "   - Cloud resource management"
    echo ""
}

# Check required tools
echo "🔍 Checking required tools..."
check_tool "docker" || exit 1
check_tool "python3" || exit 1

# Optional tools
check_tool "kubectl" || echo "ℹ️  kubectl not found (needed for Kubernetes)"
check_tool "minikube" || echo "ℹ️  minikube not found (needed for local Kubernetes)"

# Trap cleanup on exit
trap cleanup EXIT

# Main loop
while true; do
    show_menu
    read -p "Enter your choice [1-8]: " choice
    
    case $choice in
        1)
            run_backend_local
            ;;
        2)
            run_docker_compose
            ;;
        3)
            if check_tool "kubectl" && check_tool "minikube"; then
                setup_kubernetes
            else
                echo "❌ kubectl and minikube are required for Kubernetes setup"
            fi
            ;;
        4)
            check_health
            ;;
        5)
            show_logs
            ;;
        6)
            cleanup
            echo "✅ All services stopped"
            ;;
        7)
            show_help
            ;;
        8)
            echo "👋 Goodbye! Happy learning!"
            exit 0
            ;;
        *)
            echo "❌ Invalid option. Please choose 1-8."
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
done

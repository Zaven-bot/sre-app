#!/bin/bash
# filepath: /Users/ianunebasami/Documents/Lite/sre-app/scripts/sre-app.sh

# SRE Learning App - Simple Management Script

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Check we have the required scripts
check_scripts() {
    for script in build.sh deploy.sh port-forward.sh; do
        if [ ! -f "$script" ]; then
            print_error "$script not found"
            print_error "Run this script from the scripts/ directory"
            exit 1
        fi
    done
}

# Deploy everything
deploy_app() {
    print_status "🚀 Deploying SRE Learning App..."
    
    print_status "Building images..."
    ./build.sh clean
    ./build.sh build
    
    print_status "Deploying to Kubernetes..."
    ./deploy.sh deploy
    
    print_success "✅ Deployment completed!"
    print_status "Run 'sre-app.sh access' to connect to services"
}

# Quick update
update_app() {
    print_status "🔄 Updating app..."
    
    ./build.sh clean
    ./build.sh build
    
    kubectl rollout restart deployment/backend-deployment
    kubectl rollout restart deployment/frontend-deployment
    kubectl rollout restart deployment/grafana-deployment
    kubectl rollout restart deployment/prometheus-deployment
    
    print_success "✅ Update completed!"
}

# Start port-forwarding
start_access() {
    print_status "🔗 Starting port-forwarding..."
    print_warning "Press Ctrl+C to stop"
    ./port-forward.sh
}

# Destroy everything
destroy_app() {
    print_warning "💣 This will destroy everything!"
    read -p "Type 'YES' to confirm: " confirm
    
    if [ "$confirm" != "YES" ]; then
        print_status "Cancelled"
        exit 0
    fi
    
    ./deploy.sh cleanup
    ./build.sh clean
    print_success "✅ Everything destroyed"
}

# Show status
show_status() {
    print_status "📊 Current status:"
    echo
    kubectl get pods -l 'app in (backend,frontend,grafana,prometheus,redis)'
    echo
    kubectl get services -l 'app in (backend,frontend,grafana,prometheus,redis)'
}

# Show help
show_help() {
    echo "SRE Learning App Manager"
    echo
    echo "Commands:"
    echo "  up      - Deploy everything"
    echo "  update  - Rebuild and restart"
    echo "  access  - Start port-forwarding"
    echo "  status  - Show what's running"
    echo "  down    - Destroy everything"
    echo
    echo "Examples:"
    echo "  ./sre-app.sh up      # Deploy"
    echo "  ./sre-app.sh access  # Access services"
    echo "  ./sre-app.sh down    # Clean up"
}

# Main
check_scripts

case "${1:-help}" in
    up|deploy)
        deploy_app
        ;;
    update)
        update_app
        ;;
    access)
        start_access
        ;;
    status)
        show_status
        ;;
    down|destroy)
        destroy_app
        ;;
    help|--help|-h|*)
        show_help
        ;;
esac
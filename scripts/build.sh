#!/bin/bash
# filepath: /Users/ianunebasami/Documents/Lite/sre-app/scripts/build.sh

# SRE Learning App - Image Build Script
# This script builds Docker images for the application

set -e

# Colors for output (same as deploy.sh)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if Docker is available
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running"
        exit 1
    fi
    
    print_success "Docker is available and running"
}

# Function to build images
build_images() {
    print_status "Building application images..."
    
    print_status "Removing cached images..."
    # Remove existing images to force rebuild
    docker rmi sre-learning-app-frontend:latest || true
    docker rmi sre-learning-app-backend:latest || true
    print_success "Cached images removed"

    # Change to docker directory
    cd ../docker
    
    # Build images using docker compose
    print_status "Building backend and frontend images..."
    docker compose build
    
    # Return to scripts directory
    cd ../scripts
    
    print_success "Images built successfully"
    
    # Show built images
    print_status "Built images:"
    docker images | grep "sre-learning-app"
}

# Function to clean build cache
clean_build() {
    print_status "Cleaning Docker build cache..."
    docker builder prune -f
    print_success "Build cache cleaned"
    
    # Remove existing images to force rebuild
    print_status "Remove existing images..."
    docker rmi sre-learning-app-frontend:latest || true
    docker rmi sre-learning-app-backend:latest || true
    print_success "Existing images removed"
}

# Main execution
case "${1:-build}" in
    build)
        print_status "Starting image build process..."
        check_docker
        build_images
        ;;
    cleanup)
        check_docker
        clean_build
        ;;
    rebuild)
        print_status "Rebuilding images from scratch..."
        check_docker
        clean_build
        build_images
        ;;
    *)
        echo "Usage: $0 {build|clean|rebuild}"
        echo "  build   - Build application images"
        echo "  clean   - Clean Docker build cache"
        echo "  rebuild - Clean cache and rebuild images"
        exit 1
        ;;
esac
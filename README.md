# SRE DevOps Learning Project

A hands-on infrastructure project demonstrating production SRE and DevOps practices. Built to showcase end-to-end automation, monitoring, and deployment capabilities using modern containerization and orchestration technologies.

## Overview

This project implements a complete application stack with Flask backend, static frontend, and comprehensive monitoring. Everything runs in containers with Kubernetes orchestration and includes a fully automated CI/CD pipeline.

**Current Status:**
- Local development with Docker Compose
- Kubernetes deployment (local clusters)
- CI/CD pipeline with GitHub Actions
- Prometheus + Grafana monitoring stack
- Automated deployment scripts
- AWS EKS infrastructure (in progress)

## Quick Start

### Option 1: Docker Compose (Fastest)
```bash
# Start the complete stack locally
docker compose up -d

# Access services:
# Backend: http://localhost:6000
# Frontend: http://localhost:80
# Prometheus: http://localhost:9090
# Grafana: http://localhost:3000 (admin/admin)
```

### Option 2: Kubernetes (Production-like)
```bash
# Deploy to local Kubernetes cluster
./scripts/sre-app.sh up

# Access services (starts port-forwarding)
./scripts/sre-app.sh access

# Check deployment status
./scripts/sre-app.sh status

# Clean up when done
./scripts/sre-app.sh down
```

## Project Structure

```
sre-app/
├── app/
│   ├── backend/           # Flask API with health checks
│   └── frontend/          # Static HTML/JS interface
├── docker/
│   ├── Dockerfile.backend # Multi-stage Python build
│   ├── Dockerfile.frontend# Nginx-based frontend
│   └── docker-compose.yml # Complete local stack
├── k8s/                   # Kubernetes manifests
│   ├── deployment-*.yaml  # Application deployments
│   ├── service-*.yaml     # Service definitions
│   ├── prometheus.yaml    # Monitoring configuration
│   ├── grafana.yaml       # Dashboard setup
│   ├── hpa.yaml          # Horizontal Pod Autoscaler
│   └── network-policies.yaml # Security policies
├── scripts/
│   ├── sre-app.sh        # Main deployment controller
│   ├── build.sh          # Docker image builder
│   ├── deploy.sh         # Kubernetes orchestrator
│   └── port-forward.sh   # Service access helper
├── .github/workflows/
│   └── ci-cd-new.yaml    # Complete CI/CD pipeline
└── infra/aws/            # Terraform (WIP)
    └── main.tf
```

## Features

**Application Stack:**
- SRE playground featuring load-testing and metric fetching
- Flask backend with health endpoints and metrics
- Static frontend served by nginx
- Redis for caching and session storage
- Comprehensive health checks and monitoring

**Infrastructure:**
- Container-first architecture with multi-stage builds
- Kubernetes deployment with proper resource management
- Horizontal Pod Autoscaling (HPA) configured
- Network policies for security
- LoadBalancer services (ingress planned)

**Monitoring & Observability:**
- Prometheus metrics collection from all services
- Grafana dashboards with application and infrastructure metrics
- Custom health check endpoints
- Resource usage tracking

**CI/CD Pipeline:**
- Automated testing (unit tests with pytest)
- Code quality checks (flake8, black formatting)
- Container vulnerability scanning with Trivy
- Docker image builds pushed to GitHub Container Registry
- Full integration testing with docker-compose

## Deployment Scripts

The project includes automated deployment scripts that handle the complexity:

```bash
# Main commands
./scripts/sre-app.sh up      # Build and deploy everything
./scripts/sre-app.sh access  # Start port-forwarding for local access
./scripts/sre-app.sh status  # Check deployment health
./scripts/sre-app.sh down    # Clean shutdown

# Individual components
./scripts/build.sh build     # Build Docker images
./scripts/deploy.sh deploy   # Deploy to Kubernetes
./scripts/port-forward.sh    # Access services locally
```

## CI/CD Pipeline

GitHub Actions automatically:
1. **Lint & Test**: Code quality checks and unit tests
2. **Security Scan**: Container vulnerability analysis
3. **Build**: Create and push Docker images
4. **Integration Test**: Verify full stack functionality

Pipeline triggers on pushes to main/develop branches and pull requests.

## Monitoring

**Prometheus Metrics:**
- Application performance and health
- Kubernetes resource usage
- Custom business metrics
- Infrastructure monitoring

**Grafana Dashboards:**
- System overview and health status
- Application performance metrics
- Resource utilization tracking

Access monitoring after deployment:
- Prometheus: http://localhost:9090 (via port-forward)
- Grafana: http://localhost:3000 (admin/admin)

## Development Workflow

1. **Local Development**: Use `docker compose up -d` for rapid iteration
2. **Testing**: Run `pytest` in `app/backend/` or use the CI pipeline
3. **Kubernetes Testing**: Deploy with `./scripts/sre-app.sh up`
4. **Monitoring**: Check metrics and dashboards
5. **CI/CD**: Push to GitHub for automated pipeline execution

## Architecture Notes

**Service Communication:**
- Services communicate via Kubernetes DNS
- LoadBalancer services for external access
- Port-forwarding used for local development access
- Network policies restrict inter-pod communication

**Container Security:**
- Non-root execution in all containers
- Multi-stage builds minimize attack surface
- Vulnerability scanning in CI pipeline
- Resource limits and health checks configured

**Scalability:**
- Horizontal Pod Autoscaler configured
- Stateless application design
- Redis for shared state management
- Resource requests/limits defined

## Known Limitations

- **Ingress**: Currently using LoadBalancer + port-forwarding instead of ingress controller
- **AWS Deployment**: Terraform infrastructure exists but not yet tested
- **Documentation**: `/docs` folder needs updating

## Getting Started

### Prerequisites
- Docker and Docker Compose
- Kubernetes cluster (minikube, kind, or cloud)
- kubectl configured for your cluster

### Installation

1. Clone and start with Docker Compose:
```bash
git clone https://github.com/Zaven-bot/sre-app.git
cd sre-app
docker compose up -d
```

2. Verify services:
```bash
curl http://localhost:6000/health
curl http://localhost:6000/api/data
```

3. Deploy to Kubernetes:
```bash
./scripts/sre-app.sh up
./scripts/sre-app.sh access
```

## Testing

Run tests locally:
```bash
cd app/backend
python -m pytest test_app.py -v
```

Or use the automated CI/CD pipeline by pushing to GitHub.

## Future Enhancements

- Complete AWS EKS deployment with Terraform
- Implement proper ingress controller setup
- Extend monitoring with alerting rules
- Add performance testing automation

This project demonstrates production-ready DevOps practices suitable for real-world environments.

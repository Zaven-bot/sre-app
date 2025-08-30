# 🚀 SRE/DevOps Learning Application

A comprehensive, production-ready application designed to teach and demonstrate core SRE/DevOps concepts through hands-on experience.

## 🎯 Learning Objectives

This project covers all the essential skills mentioned in your SRE/DevOps roadmap:

- **Linux & Shell Scripting** - Automation scripts and container management
- **Git + CI/CD** - GitHub Actions pipeline with automated testing and deployment
- **Containers** - Docker containerization and orchestration
- **Kubernetes** - Production-grade container orchestration
- **Cloud (AWS)** - Infrastructure as Code with Terraform
- **Monitoring** - Prometheus metrics and Grafana dashboards

## 📁 Project Structure

```
production-ready-app/
├── app/                      # Application code
│   ├── frontend/            # HTML/CSS/JS frontend
│   │   └── index.html       # Interactive web interface
│   └── backend/             # Python Flask API
│       ├── app.py           # Main application with metrics
│       └── requirements.txt # Python dependencies
│
├── docker/                  # Container definitions
│   ├── Dockerfile.frontend  # Nginx frontend container
│   ├── Dockerfile.backend   # Python backend container
│   └── docker-compose.yml   # Local development setup
│
├── k8s/                     # Kubernetes manifests
│   ├── deployment-*.yaml    # Application deployments
│   ├── service-*.yaml       # Service definitions
│   └── ingress.yaml         # Load balancing and routing
│
├── infra/                   # Infrastructure as Code
│   └── aws/
│       └── main.tf          # Terraform EKS cluster
│
├── monitoring/              # Observability stack
│   ├── prometheus-config.yaml # Metrics collection config
│   └── grafana-dashboard.json # Visualization dashboard
│
├── .github/                 # CI/CD pipeline
│   └── workflows/
│       └── ci-cd.yaml       # Automated testing and deployment
│
├── scripts/                 # Automation utilities
│   ├── setup.sh            # Development environment setup
│   └── monitoring-setup.sh # Monitoring stack deployment
│
└── docs/                    # Documentation
    ├── README.md            # This file
    └── architecture.png     # System architecture diagram
```

## 🚀 Quick Start

### Option 1: Docker Compose (Recommended for Beginners)

```bash
# Clone and navigate to the project
cd production-ready-app

# Run the complete stack
cd docker
docker-compose up --build

# Access the application
open http://localhost        # Frontend
open http://localhost:5000   # Backend API
open http://localhost:9090   # Prometheus
open http://localhost:3000   # Grafana (admin/admin)
```

### Option 2: Local Development

```bash
# Use the interactive setup script
./scripts/setup.sh

# Or manually run the backend
cd app/backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python app.py
```

### Option 3: Kubernetes (Local)

```bash
# Start minikube
minikube start

# Deploy the application
kubectl apply -f k8s/

# Access via port forwarding
kubectl port-forward service/frontend-service 8080:80
```

## 🎓 Learning Path

### 1. **Start with Local Development** 🐍
- Run the Flask backend: `python app/backend/app.py`
- Understand the code structure
- Explore the health checks and metrics endpoints
- Learn: Python web frameworks, API design, monitoring

### 2. **Containerize Everything** 🐳
- Build Docker images: `docker build -f docker/Dockerfile.backend .`
- Run with Docker Compose: `docker-compose up`
- Understand multi-stage builds and container security
- Learn: Docker, container networking, service discovery

### 3. **Deploy to Kubernetes** ☸️
- Apply manifests: `kubectl apply -f k8s/`
- Understand deployments, services, and ingress
- Explore scaling and rolling updates
- Learn: Container orchestration, service mesh concepts

### 4. **Set Up Monitoring** 📊
- Run monitoring setup: `./scripts/monitoring-setup.sh`
- Configure Prometheus and Grafana
- Create custom dashboards and alerts
- Learn: Observability, SLIs/SLOs, incident response

### 5. **Implement CI/CD** 🔄
- Fork the repository and enable GitHub Actions
- Watch automated builds and deployments
- Modify code and see the pipeline in action
- Learn: GitOps, automated testing, deployment strategies

### 6. **Provision Cloud Infrastructure** ☁️
- Set up AWS credentials
- Deploy with Terraform: `terraform apply infra/aws/`
- Connect to real cloud resources
- Learn: Infrastructure as Code, cloud services, cost management

## 🛠️ Core Technologies Demonstrated

### Backend (Python/Flask)
- RESTful API design
- Health check endpoints
- Prometheus metrics integration
- Error handling and logging
- Security best practices

### Frontend (HTML/JS)
- Modern JavaScript (ES6+)
- Responsive design
- API integration
- Real-time monitoring dashboard
- Progressive enhancement

### Docker & Containers
- Multi-stage builds
- Container security
- Resource optimization
- Health checks
- Non-root user execution

### Redis
This app uses Redis to store custom application metrics (e.g. request counts, response times, error rates), which are exposed via the `/metrics` endpoint and scraped by Prometheus. It does *not* monitor Redis server internals (e.g. memory usage, cache hit rates); no Redis Exporter is required.

### Kubernetes
- Deployments and ReplicaSets
- Services and Ingress
- ConfigMaps and Secrets
- Resource quotas and limits
- Rolling updates and rollbacks

### Monitoring & Observability
- Prometheus metrics collection
- Grafana visualization
- Custom dashboards
- Alert rules and notifications
- Application Performance Monitoring (APM)

### CI/CD Pipeline
- Automated testing (unit, integration, security)
- Docker image building and scanning
- Multi-environment deployments
- Blue-green deployments
- Rollback strategies

### Infrastructure as Code
- Terraform for AWS EKS
- VPC and networking setup
- Security groups and IAM roles
- Scalable cluster configuration
- Cost optimization

## 📊 Monitoring & Metrics

The application exposes several key metrics:

- **Application Health**: `/health` endpoint with comprehensive checks
- **Business Metrics**: Request count, response times, error rates
- **Infrastructure Metrics**: CPU, memory, disk usage
- **Custom Metrics**: Application-specific business logic metrics

### Grafana Dashboards

Import the pre-built dashboard (`monitoring/grafana-dashboard.json`) to visualize:
- Service health and uptime
- Request rate and latency
- Error rate trends
- Resource utilization
- Application performance

## 🔧 Development Workflow

### Making Changes
1. Edit code locally
2. Test with the local setup: `./scripts/setup.sh`
3. Build and test containers: `docker-compose up --build`
4. Deploy to local Kubernetes for integration testing
5. Push to GitHub to trigger CI/CD pipeline

### Debugging
- Check application logs: `kubectl logs -l app=backend`
- Monitor metrics: Open Prometheus at `http://localhost:9090`
- Use Grafana dashboards for visualization
- Check health endpoints for service status

## 🌍 Production Deployment

### AWS EKS Deployment
```bash
# Set up AWS credentials
aws configure

# Deploy infrastructure
cd infra/aws
terraform init
terraform plan
terraform apply

# Configure kubectl
aws eks update-kubeconfig --region us-west-2 --name sre-learning-cluster

# Deploy application
kubectl apply -f ../../k8s/
```

### Security Considerations
- Non-root container execution
- Resource limits and quotas
- Network policies (add in production)
- RBAC configuration
- Secrets management
- Image vulnerability scanning

## 🎯 Interview Preparation

This project demonstrates your knowledge of:

### Technical Skills
- **Linux/Shell**: Automation scripts, container management
- **Git**: Version control, branching strategies, collaboration
- **CI/CD**: Automated pipelines, testing strategies, deployment automation
- **Containers**: Docker expertise, security, optimization
- **Kubernetes**: Orchestration, scaling, service discovery
- **Cloud**: AWS services, networking, security
- **Monitoring**: Observability, alerting, incident response

### SRE Concepts
- **Reliability**: Health checks, redundancy, failover
- **Scalability**: Horizontal scaling, load balancing
- **Observability**: Metrics, logs, traces, dashboards
- **Automation**: Infrastructure as Code, GitOps
- **Incident Response**: Monitoring, alerting, debugging

### Best Practices
- **Security**: Least privilege, container security, network isolation
- **Performance**: Resource optimization, caching, CDN
- **Cost Management**: Resource efficiency, autoscaling
- **Documentation**: Clear README, architecture diagrams, runbooks


## 🏗️ Design Patterns for Infrastructure Problems

This project uses design patterns to solve real SRE/DevOps challenges. Here's where and why:

### 1. **Singleton Pattern** - Metrics Collection 📊
**Problem**: Multiple metrics collectors create inconsistent data and memory leaks
**Solution**: Single metrics instance across the entire application

```python
# In app/backend/app.py - MetricsCollector should be a Singleton
# Ensures all metrics go to one place, preventing data inconsistency
```

**Real-world impact**: Prevents duplicate metrics, ensures accurate monitoring data

### 2. **Factory Pattern** - Multi-Cloud Resource Creation ☁️
**Problem**: Supporting AWS, GCP, Azure requires different resource creation logic
**Solution**: Factory creates appropriate cloud resources based on provider

```python
# Future enhancement: infra/cloud_factory.py
class CloudResourceFactory:
    @staticmethod
    def create_cluster(provider, config):
        if provider == 'aws':
            return EKSCluster(config)
        elif provider == 'gcp':
            return GKECluster(config)
        # Enables easy multi-cloud support
```

**Real-world impact**: Makes infrastructure portable across cloud providers

### 3. **Observer Pattern** - Configuration Management 🔧
**Problem**: Services need to restart when configuration changes
**Solution**: Config manager notifies all services of changes

```python
# Future enhancement: app/backend/config_observer.py
class ConfigManager:
    def update_config(self, key, value):
        self._config[key] = value
        self._notify_all_services()  # Auto-restart affected services
```

**Real-world impact**: Zero-downtime config updates, automatic service reloads

### 4. **Chain of Responsibility** - Health Checks 🏥
**Problem**: Complex health checks need to run in sequence, failing fast
**Solution**: Chain health checks together, stopping on first failure

```python
# Enhancement for app/backend/app.py health_check()
# Database → Redis → External API → File System
# If database fails, skip the rest and return degraded status
```

**Real-world impact**: Faster failure detection, better debugging information

### 5. **Strategy Pattern** - Deployment Methods 🚀
**Problem**: Different environments need different deployment strategies
**Solution**: Pluggable deployment strategies

```python
# Future enhancement: .github/workflows/deployment_strategy.py
class DeploymentContext:
    def set_strategy(self, strategy):
        self.strategy = strategy
    
    def deploy(self):
        return self.strategy.execute()

# BlueGreenDeployment() for production
# RollingDeployment() for staging  
# CanaryDeployment() for gradual rollouts
```

**Real-world impact**: Reduces deployment risk, enables safe production releases

### When NOT to Use Patterns

❌ **Don't over-engineer these areas:**
- Simple CRUD operations
- Basic HTTP handlers
- Configuration file parsing
- Log formatting
- Basic shell scripts

✅ **DO use patterns for:**
- Resource management (Singleton)
- Cross-cutting concerns (Decorator)
- Multi-provider support (Factory)
- Event handling (Observer)
- Algorithm selection (Strategy)

## 📚 Additional Learning Resources

### Books
- "Site Reliability Engineering" by Google
- "The Phoenix Project" by Gene Kim
- "Kubernetes in Action" by Marko Lukša

### Online Courses
- Kubernetes certification (CKA/CKAD)
- AWS Solutions Architect certification
- Prometheus and Grafana training

### Practice Platforms
- Kubernetes playground: https://labs.play-with-k8s.com/
- AWS Free Tier: https://aws.amazon.com/free/
- Docker playground: https://labs.play-with-docker.com/

## 📝 Next Steps

Once you're comfortable with this setup:

1. **Add more services** (database, cache, message queue)
2. **Implement advanced monitoring** (ELK stack, distributed tracing)
3. **Add security scanning** (Falco, OPA Gatekeeper)
4. **Experiment with service mesh** (Istio, Linkerd)
5. **Try different deployment strategies** (canary, blue-green)
6. **Implement GitOps** (ArgoCD, Flux)
7. **Add chaos engineering** (Chaos Monkey, Litmus)

## 🆘 Troubleshooting

### Common Issues

**Docker build fails**
```bash
# Clean up Docker
docker system prune -f
docker-compose down -v
```

**Kubernetes pods not starting**
```bash
# Check pod status
kubectl get pods
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

**Monitoring not working**
```bash
# Check services
kubectl get svc -n monitoring
kubectl port-forward service/prometheus-service 9090:9090 -n monitoring
```

**Cannot access application**
```bash
# Check ingress
kubectl get ingress
minikube ip  # For local development
```

---

## This project shows knowledge of:

- How to build and containerize applications
- How to deploy and scale in Kubernetes
- How to implement monitoring and observability
- How to automate with CI/CD pipelines
- How to manage infrastructure as code
- How to follow security and operational best practices

Keep experimenting, learning, and building! 🚀

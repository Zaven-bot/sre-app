# SRE/DevOps Learning App Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              Internet                                       │
└─────────────────────────┬───────────────────────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────────────────────┐
│                    AWS Application Load Balancer                           │
│                         (ALB/Ingress)                                      │
└─────────────────────────┬───────────────────────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────────────────────┐
│                     Kubernetes Cluster (EKS)                               │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐ │
│  │   Frontend      │  │    Backend      │  │      Monitoring             │ │
│  │   (Nginx)       │  │   (Flask API)   │  │   ┌─────────────────────┐   │ │
│  │  ┌───────────┐  │  │  ┌───────────┐  │  │   │    Prometheus      │   │ │
│  │  │ HTML/CSS/ │  │  │  │  Python   │  │  │   │   (Metrics)        │   │ │
│  │  │    JS     │  │  │  │   Flask   │  │  │   └─────────────────────┘   │ │
│  │  └───────────┘  │  │  │  Health   │  │  │   ┌─────────────────────┐   │ │
│  │   Port: 80      │  │  │  Metrics  │  │  │   │     Grafana         │   │ │
│  │   Replicas: 2   │  │  └───────────┘  │  │   │   (Dashboards)      │   │ │
│  └─────────────────┘  │   Port: 5000    │  │   └─────────────────────┘   │ │
│                       │   Replicas: 3   │  │                             │ │
│                       └─────────────────┘  └─────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                         Infrastructure Layer                                │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐ │
│  │      VPC        │  │   EKS Cluster   │  │      Security               │ │
│  │  ┌───────────┐  │  │  ┌───────────┐  │  │   ┌─────────────────────┐   │ │
│  │  │  Public   │  │  │  │   Node    │  │  │   │   Security Groups   │   │ │
│  │  │  Subnets  │  │  │  │  Groups   │  │  │   │       IAM Roles     │   │ │
│  │  └───────────┘  │  │  │ (t3.small)│  │  │   │    Network ACLs     │   │ │
│  │  ┌───────────┐  │  │  └───────────┘  │  │   └─────────────────────┘   │ │
│  │  │ Private   │  │  │  Min: 1 node    │  │                             │ │
│  │  │ Subnets   │  │  │  Max: 3 nodes   │  │                             │ │
│  │  └───────────┘  │  │                 │  │                             │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                           CI/CD Pipeline                                   │
│                                                                             │
│  GitHub → Actions → Build → Test → Scan → Deploy                           │
│     │         │       │      │      │        │                            │
│     │         │       │      │      │        └── Staging/Production       │
│     │         │       │      │      └─────────── Security Scanning        │
│     │         │       │      └──────────────── Unit/Integration Tests     │
│     │         │       └─────────────────────── Docker Build              │
│     │         └─────────────────────────────── Lint/Quality Checks       │
│     └───────────────────────────────────────── Source Code               │
└─────────────────────────────────────────────────────────────────────────────┘

Data Flow:
1. User visits website → ALB → Frontend Pod (Nginx)
2. Frontend makes API calls → Backend Pod (Flask)
3. Backend exposes metrics → Prometheus scrapes them
4. Grafana queries Prometheus → Displays dashboards
5. Health checks ensure service availability
6. Logs are collected for troubleshooting

Key Components:
- Frontend: Serves static files, proxies API requests
- Backend: REST API with health checks and metrics
- Monitoring: Real-time metrics and alerting
- Infrastructure: Scalable, secure cloud deployment
- CI/CD: Automated testing and deployment
```

## Technology Stack

### Application Layer
- **Frontend**: HTML5, CSS3, JavaScript (ES6+)
- **Backend**: Python 3.11, Flask, RESTful APIs
- **Metrics**: Prometheus client, custom metrics
- **Health**: Comprehensive health checks

### Container Layer
- **Runtime**: Docker with multi-stage builds
- **Orchestration**: Kubernetes with Helm charts
- **Registry**: Amazon ECR (Elastic Container Registry)
- **Security**: Non-root execution, vulnerability scanning

### Infrastructure Layer
- **Cloud**: Amazon Web Services (AWS)
- **Compute**: Elastic Kubernetes Service (EKS)
- **Networking**: VPC, ALB, Security Groups
- **IaC**: Terraform for infrastructure management

### Monitoring & Observability
- **Metrics**: Prometheus with custom exporters
- **Visualization**: Grafana dashboards
- **Logging**: Structured logging (ready for ELK)
- **Alerting**: Prometheus AlertManager rules

### CI/CD & Automation
- **Version Control**: Git with GitFlow strategy
- **CI/CD**: GitHub Actions workflows
- **Testing**: Unit tests, integration tests, security scans
- **Deployment**: Blue-green, rolling updates

## Scaling Considerations

### Horizontal Scaling
- Frontend: 2-10 replicas based on traffic
- Backend: 3-20 replicas with auto-scaling
- Database: Read replicas (when added)

### Vertical Scaling
- Adjust CPU/memory limits based on metrics
- Node group scaling for cluster growth

### Performance Optimization
- CDN for static assets (CloudFront)
- Caching layer (Redis - to be added)
- Database optimization (when added)

## Security Measures

### Container Security
- Non-root user execution
- Read-only root filesystem where possible
- Minimal base images (Alpine Linux)
- Regular vulnerability scanning

### Network Security
- Private subnets for worker nodes
- Security groups for traffic control
- Network policies for pod communication
- TLS encryption for all traffic

### Access Control
- IAM roles with least privilege
- RBAC in Kubernetes
- Service accounts for pods
- Secrets management

This architecture demonstrates production-ready practices while remaining simple enough for learning and experimentation.

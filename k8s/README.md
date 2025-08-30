# SRE Learning App - Kubernetes Deployment

This directory contains production-ready Kubernetes manifests for the complete SRE Learning Application stack.

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Backend       │    │   Redis         │
│   (Nginx)       │───▶│   (Gunicorn)    │───▶│   (Database)    │
│   Port: 80      │    │   Port: 5000    │    │   Port: 6379    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │
         │                       │
         ▼                       ▼
┌─────────────────┐    ┌─────────────────┐
│   Prometheus    │    │   Grafana       │
│   (Monitoring)  │───▶│   (Dashboards)  │
│   Port: 9090    │    │   Port: 3000    │
└─────────────────┘    └─────────────────┘
```

## 📋 Components

### Core Application
- **Frontend**: Nginx serving static files with API proxy
- **Backend**: Gunicorn WSGI server with Flask app (2+ workers)
- **Redis**: Shared metrics storage and caching

### Monitoring Stack
- **Prometheus**: Metrics collection and alerting
- **Grafana**: Visualization dashboards

### Production Features
- **HPA**: Horizontal Pod Autoscaler for backend scaling
- **PVCs**: Persistent storage for Redis, Prometheus, Grafana
- **Network Policies**: Security restrictions between components
- **Health Checks**: Liveness and readiness probes
- **Resource Limits**: CPU and memory constraints
- **Security Contexts**: Non-root containers

## 🚀 Quick Start

### Prerequisites

1. **Kubernetes Cluster** (local or cloud):
   ```bash
   # Local with minikube
   minikube start --memory=4g --cpus=4
   
   # Or kind
   kind create cluster --config=kind-config.yaml
   
   # Or AWS EKS, GKE, AKS
   ```

2. **kubectl** configured to access your cluster

3. **Application Images** built and available:
   ```bash
   # Build and tag images
   cd /path/to/production-ready-app
   docker build -t sre-learning-app/backend:latest -f docker/Dockerfile.backend .
   docker build -t sre-learning-app/frontend:latest -f docker/Dockerfile.frontend .
   
   # For cloud deployment, push to registry:
   # docker tag sre-learning-app/backend:latest your-registry/backend:latest
   # docker push your-registry/backend:latest
   ```

### Deploy

```bash
# Simple one-command deployment
./deploy.sh

# Or step by step
kubectl apply -f deployment-redis.yaml
kubectl apply -f deployment-backend.yaml
kubectl apply -f service-backend.yaml
kubectl apply -f deployment-frontend.yaml
kubectl apply -f service-frontend.yaml
kubectl apply -f prometheus.yaml
kubectl apply -f grafana.yaml
kubectl apply -f hpa.yaml
kubectl apply -f network-policies.yaml
kubectl apply -f ingress.yaml
```

### Access

After deployment, access your application:

```bash
# Check status
./deploy.sh status

# Port forwarding (if ingress not ready)
kubectl port-forward svc/frontend-service 8080:80
kubectl port-forward svc/prometheus-service 9090:9090
kubectl port-forward svc/grafana-service 3000:3000
```

## 📁 File Descriptions

| File | Purpose |
|------|---------|
| `deployment-redis.yaml` | Redis database with persistence |
| `deployment-backend.yaml` | Backend application with Redis connectivity |
| `service-backend.yaml` | Backend service and metrics discovery |
| `deployment-frontend.yaml` | Frontend Nginx proxy |
| `service-frontend.yaml` | Frontend service |
| `prometheus.yaml` | Prometheus monitoring with RBAC |
| `grafana.yaml` | Grafana dashboards with data sources |
| `hpa.yaml` | Horizontal Pod Autoscaler |
| `network-policies.yaml` | Network security policies |
| `ingress.yaml` | External access routing |
| `deploy.sh` | Deployment automation script |

## 🔧 Configuration

### Environment Variables

Backend deployment includes these key environment variables:
- `REDIS_HOST=redis-service`
- `REDIS_PORT=6379`
- `FLASK_ENV=production`
- `GUNICORN_WORKERS=2`

### Resource Requests/Limits

| Component | Memory Request | Memory Limit | CPU Request | CPU Limit |
|-----------|---------------|--------------|-------------|-----------|
| Backend | 256Mi | 512Mi | 200m | 500m |
| Frontend | 64Mi | 128Mi | 50m | 100m |
| Redis | 128Mi | 512Mi | 100m | 300m |
| Prometheus | 512Mi | 1Gi | 200m | 500m |
| Grafana | 256Mi | 512Mi | 100m | 300m |

### Persistent Storage

- **Redis**: 5Gi for data persistence
- **Prometheus**: 10Gi for metrics storage (30-day retention)
- **Grafana**: 5Gi for dashboards and configuration

## 📊 Monitoring

### Prometheus Targets

- Backend metrics: `backend-service:5000/metrics`
- Kubernetes API: Service discovery enabled
- Custom dashboards: Available in Grafana

### Grafana Access

- **URL**: `/grafana` (via ingress) or `localhost:3000` (port-forward)
- **Credentials**: `admin` / `admin` (change in production!)
- **Data Source**: Prometheus automatically configured

### Key Metrics

- `requests_total` - Total HTTP requests
- `errors_total` - Total errors
- `response_time_avg` - Average response time
- `memory_usage_mb` - Memory consumption
- `cpu_percent` - CPU utilization

## 🔐 Security

### Network Policies

- Backend: Only accessible from frontend and prometheus
- Redis: Only accessible from backend
- Prometheus: Can scrape backend, accessible from grafana
- Grafana: Only accessible via ingress

### Security Contexts

All containers run as non-root users:
- Backend: User 1000
- Frontend: User 101 (nginx)
- Redis: User 999
- Prometheus: User 65534 (nobody)
- Grafana: User 472

## 🎯 Scaling

### Horizontal Pod Autoscaler

Backend automatically scales based on:
- CPU utilization > 70%
- Memory utilization > 80%
- Min replicas: 2
- Max replicas: 10

### Manual Scaling

```bash
# Scale backend manually
kubectl scale deployment backend-deployment --replicas=5

# Scale frontend
kubectl scale deployment frontend-deployment --replicas=3
```

## 🐛 Troubleshooting

### Common Issues

1. **Images not found**:
   ```bash
   # Check if images exist
   docker images | grep sre-learning-app
   # Build if missing
   docker build -t sre-learning-app/backend:latest -f docker/Dockerfile.backend .
   ```

2. **Pods not starting**:
   ```bash
   kubectl describe pod <pod-name>
   kubectl logs <pod-name>
   ```

3. **Redis connection issues**:
   ```bash
   kubectl exec -it deployment/backend-deployment -- env | grep REDIS
   kubectl exec -it deployment/redis-deployment -- redis-cli ping
   ```

4. **Prometheus not scraping**:
   ```bash
   kubectl port-forward svc/prometheus-service 9090:9090
   # Check targets at http://localhost:9090/targets
   ```

### Useful Commands

```bash
# Check all resources
kubectl get all

# View events
kubectl get events --sort-by=.metadata.creationTimestamp

# Check HPA status
kubectl get hpa

# View logs
kubectl logs -f deployment/backend-deployment
kubectl logs -f deployment/prometheus-deployment

# Debug networking
kubectl exec -it deployment/backend-deployment -- nslookup redis-service
kubectl exec -it deployment/backend-deployment -- curl redis-service:6379

# Check metrics
kubectl exec -it deployment/backend-deployment -- curl localhost:5000/metrics
```

## 🌍 Cloud Deployment

### AWS EKS

1. Create EKS cluster:
   ```bash
   eksctl create cluster --name sre-learning --region us-west-2 --nodes 3
   ```

2. Configure ALB ingress controller:
   ```bash
   kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.4/docs/install/iam_policy.json
   ```

3. Update ingress annotations in `ingress.yaml`:
   ```yaml
   annotations:
     kubernetes.io/ingress.class: alb
     alb.ingress.kubernetes.io/scheme: internet-facing
   ```

### Storage Classes

Update PVCs for your cloud provider:

```yaml
# AWS EBS
storageClassName: gp2

# GCP Persistent Disk
storageClassName: standard

# Azure Disk
storageClassName: default
```

## 🧹 Cleanup

```bash
# Remove all resources
./deploy.sh cleanup

# Or manually
kubectl delete -f .
```

## 📚 Next Steps

After successful deployment:

1. **Set up CI/CD** with GitHub Actions
2. **Configure monitoring alerts** in Prometheus
3. **Add custom Grafana dashboards**
4. **Implement backup strategies** for persistent data
5. **Set up log aggregation** (ELK stack)
6. **Configure certificate management** (cert-manager)
7. **Add chaos engineering** tests

---

## 🤝 Contributing

This is a learning project. Feel free to:
- Add more monitoring dashboards
- Implement additional microservices
- Enhance security policies
- Add more sophisticated deployment strategies

## 📄 License

Educational use only. Part of SRE/DevOps learning curriculum.



deployment-backend.yaml:
3 Backend Pods (computers)
├── Each pod runs: Your Flask app container
├── Each container has: 2 Gunicorn workers  
├── Total capacity: 6 workers handling requests
├── Each connects to: redis-service:6379
├── Each exposes: /health, /metrics, /api/* endpoints
└── Prometheus monitors: All 3 pods automatically

grafana.yaml:
1. ConfigMap: grafana-config
   ├── grafana.ini (main config)
   └── datasources.yaml (auto-configure Prometheus)

2. Deployment: grafana-deployment  
   ├── 1 pod running Grafana
   ├── Mounts config files from ConfigMap
   ├── Mounts data storage from PVC
   └── Gets admin password from Secret

3. Service: grafana-service
   └── Provides network access at grafana-service:3000

4. PVC: grafana-pvc
   └── Requests 5GB storage for dashboards/data

5. Secret: grafana-secret
   └── Stores admin password securely


hpa.yaml:
1. HorizontalPodAutoscaler: backend-hpa
   ├── Watches: backend-deployment (the kitchen)
   ├── Staff limits: 2-10 cooks (min-max replicas)
   ├── Hiring triggers: CPU >70% OR Memory >80%
   ├── Hiring rules: Wait 1min, hire up to 100% more or 2 pods
   └── Firing rules: Wait 5min, fire up to 50% at once


ingress.yaml:
1. Ingress: app-ingress (Smart front desk)
   ├── Rules: Route visitors based on URL path
   │   ├── / → frontend-service:80 (main website)
   │   ├── /api → backend-service:5000 (API calls)
   │   ├── /health → backend-service:5000 (health checks)
   │   ├── /metrics → backend-service:5000 (monitoring)
   │   ├── /prometheus → prometheus-service:9090 (Prometheus UI)
   │   └── /grafana → grafana-service:3000 (Grafana UI)
   └── Settings: Rate limiting, no forced HTTPS

2. LoadBalancer: frontend-loadbalancer (Simple alternative)
   └── Directly exposes frontend with cloud provider IP

http://your-cluster-ip/           → Frontend (your main app)
http://your-cluster-ip/api/data   → Backend API
http://your-cluster-ip/health     → Health check
http://your-cluster-ip/prometheus → Prometheus dashboard  
http://your-cluster-ip/grafana    → Grafana dashboards

The tons of comments are just examples for different cloud providers - ignore them for now!


network-policies.yaml:
1. Backend Security Guard
   ├── Visitors allowed: Frontend, Prometheus, External
   └── Can visit: Redis, DNS, Kubernetes API

2. Redis Security Guard (Most Strict!)
   ├── Visitors allowed: Backend ONLY
   └── Can visit: DNS only

3. Prometheus Security Guard
   ├── Visitors allowed: Grafana, External
   └── Can visit: Backend, DNS, Kubernetes API

4. Grafana Security Guard
   ├── Visitors allowed: External ONLY
   └── Can visit: Prometheus, DNS

5. Frontend Security Guard
   ├── Visitors allowed: External ONLY
   └── Can visit: Backend, DNS

🌐 Internet → Ingress → Frontend → Backend → Redis
                         ↑         ↑
                    (public)   (internal only)
                         
🔍 Prometheus → Backend (pulls /metrics)
       ↓
📊 Grafana ← Prometheus
    ↑
(public dashboards)



prometheus.yaml:
1. ConfigMap: prometheus-config
   ├── Investigation manual with 4 jobs:
   │   ├── Self-check (localhost:9090)
   │   ├── Building management (Kubernetes API)
   │   ├── Backend offices (auto-discovery)
   │   └── Backend office (direct address)

2. Deployment: prometheus-deployment
   ├── 1 detective with instruction manual
   ├── Filing cabinet for evidence storage
   ├── Office at door 9090
   └── Health checks to ensure detective is working

3. Service: prometheus-service
   └── Phone number (prometheus-service:9090)

4. PVC: prometheus-pvc
   └── 10GB filing cabinet for evidence

5. ServiceAccount: prometheus-service-account
   └── Building access badge

6. ClusterRole: Investigation permissions
   └── Can observe pods, services, endpoints

7. ClusterRoleBinding: Badge + Permissions
   └── Programs the badge with investigation rights
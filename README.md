# SRE - DevOps Learning Project

> **Production-ready infrastructure to review SRE and DevOps skills**

I used this project to review SRE/DevOps technologies I've used in professional production settings that I wanted to get a deeper understanding of. I've ran these technologies locally, deployed to Kubernetes, and scale to the cloud.

## Highlighted Skills:
✅ **Linux & Shell Scripting** - Automated deployment
✅ **Git + CI/CD** - GitHub Actions, automated pipelines  
✅ **Containers** - Docker → Kubernetes orchestration  
✅ **Cloud Basics** - AWS infrastructure with Terraform  
✅ **Monitoring/Logging** - Prometheus, Grafana, observability  

## ⚡ Quick Start

```bash
# 1. Connect to AWS EKS cluster
aws configure
aws eks update-kubeconfig --region us-west-2 --name sre-learning-cluster

# 2. Deploy everything (build + deploy)
./sre-app.sh up
deploy_app() {
    ./build.sh clean     # Clean Docker images
    ./build.sh build     # Build new images  
    ./deploy.sh deploy   # Deploy to Kubernetes
}

# 3. Access services via port-forward
./sre-app.sh access
start_access() {
    ./port-forward.sh    # Start port-forwarding
}
```

### On AWS vs Local:
```bash
./sre-app.sh up      # Deploy everything
./sre-app.sh access  # Port-forward to Grafana/Prometheus only
# Frontend accessible via: http://abc123.us-west-2.elb.amazonaws.com
```

```bash
./sre-app.sh up      # Deploy everything  
./sre-app.sh access  # Port-forward to ALL services including frontend
# Frontend accessible via: http://localhost:8080
```

## 🏗️ What's Inside

- **App**: Simple SRE playground featuring load testing and displayed live /metrics
- **Full Container Stack**: Multi-stage Docker builds with security best practices
- **Kubernetes Manifests**: Complete K8s deployment with ingress, monitoring
- **AWS Infrastructure**: Terraform EKS cluster ready for production
- **CI/CD Pipeline**: GitHub Actions with testing, building, deploying
- **Monitoring Stack**: Prometheus + Grafana with custom dashboards
- **Automation Scripts**: One-click setup and deployment tools

## 📊 Live Demo Features

The application includes:
- 🏥 Health checks and monitoring endpoints
- 📈 Real-time metrics and dashboards  
- ⚡ Load testing capabilities
- 🔍 Error simulation for testing monitoring
- 📊 Resource usage tracking
- 🚨 Alert rules and notifications

## 🎓 Learning Path

1. **Start Local** → Run backend with Python/Flask
2. **Containerize** → Build and run with Docker
3. **Orchestrate** → Deploy to local Kubernetes (minikube)
4. **Monitor** → Set up Prometheus + Grafana
5. **Automate** → Enable GitHub Actions CI/CD
6. **Scale** → Deploy to AWS EKS with Terraform

## 🛠️ Technologies Used

| Category | Technologies |
|----------|-------------|
| **Application** | Python Flask, HTML/JS, REST APIs |
| **Containers** | Docker, Docker Compose, Multi-stage builds |
| **Orchestration** | Kubernetes, minikube, EKS |
| **Infrastructure** | Terraform, AWS VPC/EKS, IAM |
| **CI/CD** | GitHub Actions, automated testing |
| **Monitoring** | Prometheus, Grafana, custom metrics |
| **Security** | Container scanning, non-root execution |

## 💼 Perfect for Job Interviews

This project demonstrates that you can:

- Build and deploy applications end-to-end
- Containerize and orchestrate with Kubernetes
- Implement comprehensive monitoring and alerting
- Automate with CI/CD pipelines
- Manage cloud infrastructure as code
- Follow security and operational best practices

## 📂 Project Structure

```
production-ready-app/
├── 🐍 app/                  # Flask backend + frontend
├── 🐳 docker/              # Container definitions  
├── ☸️  k8s/                # Kubernetes manifests
├── ☁️  infra/aws/          # Terraform infrastructure
├── 📊 monitoring/          # Prometheus + Grafana
├── 🔄 .github/workflows/   # CI/CD pipeline
├── 🛠️  scripts/            # Automation tools
└── 📚 docs/               # Complete documentation
```

## 🚀 Get Started Now

```bash
# Clone this repository
git clone <this-repo>
cd production-ready-app

# Run the interactive setup
./scripts/setup.sh
```

The setup script will guide you through:
- Local development setup
- Docker containerization  
- Kubernetes deployment
- Monitoring configuration
- Health checks and verification

## 📚 Full Documentation

Check out [`docs/README.md`](docs/README.md) for:
- Detailed setup instructions
- Architecture explanations
- Troubleshooting guides
- Interview preparation tips
- Advanced deployment scenarios

## 🎯 Ready for Your SRE/DevOps Journey?

This project gives you everything you need to demonstrate real-world SRE/DevOps skills. Start with the basics and work your way up to a full production deployment!

**Happy learning!** 🚀

---

*💡 Pro tip: Fork this repository and customize it with your own improvements to show initiative and creativity to potential employers!*

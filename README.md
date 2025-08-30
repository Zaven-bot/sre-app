# 🚀 SRE/DevOps Learning Project

> **A hands-on, production-ready application to master SRE and DevOps skills**

This project provides a complete learning environment covering all essential SRE/DevOps technologies through a real-world application that you can run locally, deploy to Kubernetes, and scale to the cloud.

## 🎯 What You'll Learn

✅ **Linux & Shell Scripting** - Daily bread of SRE  
✅ **Git + CI/CD** - GitHub Actions, automated pipelines  
✅ **Containers** - Docker → Kubernetes orchestration  
✅ **Cloud Basics** - AWS infrastructure with Terraform  
✅ **Monitoring/Logging** - Prometheus, Grafana, observability  

## ⚡ Quick Start

```bash
# 1. Get the project running locally
./scripts/setup.sh

# 2. Or run everything with Docker
cd docker && docker-compose up --build

# 3. Access your running application
open http://localhost        # Frontend dashboard
open http://localhost:5000   # Backend API
open http://localhost:9090   # Prometheus metrics
open http://localhost:3000   # Grafana dashboards
```

## 🏗️ What's Inside

- **Production-Ready App**: Flask backend + frontend with real metrics
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

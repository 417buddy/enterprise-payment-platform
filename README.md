# 🏦 Enterprise Payment Platform

## Secure Microservices CI/CD Pipeline on AWS EKS

Enterprise-grade GitFlow-based CI/CD pipeline for a secure microservices payment platform with semantic versioning, automated security scanning, tag-driven production releases, and hotfix governance.

---

## 🚀 Quick Start

### Prerequisites

- AWS Account with EKS cluster
- GitHub repository with self-hosted runners
- kubectl, helm, AWS CLI configured
- Docker installed

### Deploy Pipeline

```bash
# Clone repository
git clone https://github.com/417buddy/enterprise-payment-platform.git
cd enterprise-payment-platform

# Setup self-hosted runner
./scripts/setup-runner.sh

# Create your first feature branch
git checkout -b feature/initial-setup develop

# Deploy to staging
git push -u origin feature/initial-setup
```

---

## 🌿 GitFlow Branching Strategy

```
main (production)
├── develop (staging)
│   ├── feature/*
│   ├── release/*
│   └── hotfix/*
```

| Branch | Pattern | Environment | Auto-Deploy |
|--------|---------|-------------|-------------|
| Main | `main` | Production | ❌ (Tag required) |
| Develop | `develop` | Staging | ✅ |
| Feature | `feature/*` | Dev | ✅ |
| Release | `release/*` | Staging | ✅ |
| Hotfix | `hotfix/*` | Production | ✅ |

---

## 🔄 CI/CD Pipeline Overview

### Pipeline Stages

1. **🔍 Code Quality & Security** (Self-hosted runner)
   - Semantic versioning
   - SonarQube analysis
   - SAST scanning (Semgrep)
   - Secret detection
   - Dependency scan (Trivy)

2. **🏗️ Build & Push** (Self-hosted runner)
   - Docker image build
   - Security scan
   - Push to GHCR & ECR

3. **🚀 Deploy Staging** (Self-hosted runner)
   - Kubernetes deployment
   - Smoke tests
   - Health checks

4. **🚀 Deploy Production** (Self-hosted runner)
   - Manual approval gate
   - Tag-triggered only
   - Health verification
   - Release documentation

5. **🔥 Hotfix Deploy** (Self-hosted runner)
   - Emergency production deploy
   - Expedited process
   - Post-deployment review

---

## 🏷️ Semantic Versioning

### Automated Version Generation

```bash
# View current version
./scripts/semantic-versioning.sh current

# Calculate next version
./scripts/semantic-versioning.sh next

# Create release tag
./scripts/semantic-versioning.sh tag 1.0.0

# Push tag (triggers production deploy)
./scripts/semantic-versioning.sh push-tag 1.0.0

# Complete release process
./scripts/semantic-versioning.sh release 1.0.0

# Create hotfix branch
./scripts/semantic-versioning.sh hotfix 1.0.1
```

### Version Format

```
MAJOR.MINOR.PATCH
   ↓     ↓      ↓
   |     |      └─ Bug fixes (auto)
   |     └──────── Features
   └────────────── Breaking changes
```

---

## 🔐 Security Features

### Automated Security Scanning

- **SAST**: Semgrep for static analysis
- **Secret Detection**: Pattern matching for credentials
- **Dependency Scan**: Trivy for vulnerabilities
- **Container Scan**: Image vulnerability assessment
- **SonarQube**: Code quality & security metrics

### Security Gates

```yaml
Critical Issues → Build Fails
High Vulnerabilities → Warning
Medium/Low → Logged
```

---

## 🏗️ Architecture

### Microservices

- **Payment Gateway Service** - Payment processing
- **User Authentication Service** - Auth & authorization
- **Transaction Service** - Transaction management
- **Notification Service** - Alerts & notifications
- **API Gateway** - Request routing

### Infrastructure

- **AWS EKS** - Kubernetes cluster
- **Amazon RDS PostgreSQL** - Primary database
- **Amazon ElastiCache Redis** - Caching layer
- **Amazon SQS** - Message queue
- **Amazon CloudWatch** - Monitoring & logging

---

## 📋 Pipeline Configuration

### Required GitHub Secrets

```bash
# AWS Credentials
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_ACCOUNT_ID=564268554451
AWS_REGION=us-east-1

# Kubernetes
KUBECONFIG  # Base64 encoded

# SonarQube (optional)
SONAR_HOST_URL
SONAR_TOKEN

# Notifications (optional)
SLACK_WEBHOOK
PAGERDUTY_KEY
```

### Environment Variables

```yaml
EKS_CLUSTER_NAME: payment-platform-prod
REGISTRY: ghcr.io
IMAGE_NAME: 417buddy/enterprise-payment-platform
AWS_ACCOUNT_ID: 564268554451
AWS_REGION: us-east-1
```

---

## 🚀 Deployment Workflows

### Workflow Files

- **`.github/workflows/cicd-pipeline.yaml`** - Main CI/CD pipeline
- **`.github/workflows/security-scan.yaml`** - Scheduled security scans
- **`.github/workflows/manual-deploy.yaml`** - Manual deployment trigger

### Trigger Conditions

| Event | Branch/Tag | Pipeline | Deploy |
|-------|------------|----------|--------|
| Push | `feature/*` | Full | Dev |
| Push | `develop` | Full | Staging |
| Push | `release/*` | Full | Staging |
| Tag | `v*` on main | Full | Production |
| Push | `hotfix/*` | Full | Production |
| PR | Any | Validation | None |

---

## 📊 Monitoring & Observability

### Dashboards

- **GitHub Actions**: Pipeline status & metrics
- **Grafana**: Application performance
- **CloudWatch**: AWS resources & logs
- **SonarQube**: Code quality

### Alerts

- Pipeline failures
- Deployment failures
- Security vulnerabilities
- Performance degradation
- Resource thresholds

---

## 🎯 Best Practices

### Development

1. Branch from `develop` for features
2. Small, frequent commits
3. Write tests for all changes
4. Run security scan locally
5. Update documentation

### Releases

1. Create `release/*` branch
2. Final testing on staging
3. Tag on `main` branch
4. Document in changelog
5. Monitor production post-deploy

### Hotfixes

1. Branch from `main`
2. Fix with minimal changes
3. Test thoroughly
4. Deploy via hotfix pipeline
5. Merge back to `develop`

---

## 🆘 Troubleshooting

### Common Issues

**Pipeline won't start:**
```bash
# Check runner status
kubectl get pods -n actions-runner-system

# Verify runner is online
# Settings → Actions → Runners
```

**Security scan fails:**
```bash
# Review issues
cat semgrep-results.json | jq

# Fix and recommit
```

**Deployment stuck:**
```bash
# Check pod status
kubectl get pods -n payment-platform

# View logs
kubectl logs -f deployment/payment-service
```

---

## 📚 Documentation

- **[GitFlow Guide](docs/GITFLOW-GUIDE.md)** - Branching strategy
- **[Security Scanning](docs/SECURITY-SCANNING.md)** - Security processes
- **[Deployment Guide](docs/DEPLOYMENT-GUIDE.md)** - Deployment procedures
- **[Runbook](docs/RUNBOOK.md)** - Operational procedures

---

## 🔗 Repository Links

- **Source**: https://github.com/417buddy/enterprise-payment-platform
- **Actions**: https://github.com/417buddy/enterprise-payment-platform/actions
- **Issues**: https://github.com/417buddy/enterprise-payment-platform/issues

---

**Version**: 1.0.0  
**License**: Proprietary  
**Team**: Platform Engineering  
**Contact**: devops@company.com

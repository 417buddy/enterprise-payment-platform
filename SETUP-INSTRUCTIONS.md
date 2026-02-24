# 🚀 Enterprise Payment Platform - Setup Instructions

## Complete GitFlow CI/CD Pipeline Implementation

---

## ✅ What's Been Created

A complete enterprise-grade GitFlow-based CI/CD pipeline for a secure microservices payment platform on AWS EKS with:

- ✅ Semantic versioning automation
- ✅ Automated security scanning (SAST, secrets, dependencies)
- ✅ Tag-driven production releases
- ✅ Hotfix governance
- ✅ Self-hosted runner configuration for all stages
- ✅ Multi-environment deployment (Dev, Staging, Production)

---

## 📁 Project Location

**Local Path**: `/Users/owolabiyusuff/enterprise-payment-platform/`

**Files Created**:
- `.github/workflows/cicd-pipeline.yaml` - Main CI/CD pipeline
- `README.md` - Project documentation
- `docs/IMPLEMENTATION-SUMMARY.md` - Complete implementation guide

---

## 🔧 Step 1: Create GitHub Repository

### Option A: Via GitHub Web Interface

1. Go to: https://github.com/new
2. Repository name: `enterprise-payment-platform`
3. Description: "Enterprise GitFlow CI/CD Pipeline for Secure Payment Platform on AWS EKS"
4. Visibility: **Private** (recommended for payment platforms) or Public
5. **DO NOT** initialize with README, .gitignore, or license
6. Click **Create repository**

### Option B: Via GitHub CLI

```bash
# Install GitHub CLI if not installed
brew install gh  # macOS
# or
sudo apt-get install gh  # Linux

# Authenticate
gh auth login

# Create repository
gh repo create enterprise-payment-platform --private --source=. --remote=origin --push
```

---

## 🔧 Step 2: Push to GitHub

### If Repository is Public:

```bash
cd /Users/owolabiyusuff/enterprise-payment-platform

# Configure git (if not already done)
git config user.email "owolabiyusuff@gmail.com"
git config user.name "Owolabi Yusuff"

# Push to GitHub
git push -u origin main
```

### If Repository is Private:

```bash
cd /Users/owolabiyusuff/enterprise-payment-platform

# Configure git
git config user.email "owolabiyusuff@gmail.com"
git config user.name "Owolabi Yusuff"

# Update remote URL (if needed)
git remote set-url origin git@github.com:417buddy/enterprise-payment-platform.git

# Push to GitHub
git push -u origin main
```

---

## 🔧 Step 3: Configure GitHub Secrets

After pushing, configure these secrets in GitHub:

### Navigate to Secrets
1. Go to your repository: https://github.com/417buddy/enterprise-payment-platform
2. Click **Settings** tab
3. Click **Secrets and variables** → **Actions**
4. Click **New repository secret**

### Required Secrets

```bash
# AWS Credentials
AWS_ACCESS_KEY_ID=YOUR_AWS_ACCESS_KEY
AWS_SECRET_ACCESS_KEY=YOUR_AWS_SECRET_KEY
AWS_ACCOUNT_ID=564268554451
AWS_REGION=us-east-1

# Kubernetes (base64 encode your kubeconfig)
# Run: cat ~/.kube/config | base64 -w 0
KUBECONFIG=<paste base64 output here>

# SonarQube (optional)
SONAR_HOST_URL=https://your-sonarqube-instance.com
SONAR_TOKEN=your-sonarqube-token

# Slack Notifications (optional)
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL

# PagerDuty (optional)
PAGERDUTY_ROUTING_KEY=your-pagerduty-key
```

---

## 🔧 Step 4: Setup Self-Hosted Runner

### On Your Runner Machine (EC2, Local Server, etc.)

```bash
# Install required tools
sudo apt-get update
sudo apt-get install -y docker.io curl wget jq apt-transport-https ca-certificates software-properties-common

# Install kubectl
sudo curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install Trivy
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt update && sudo apt install -y trivy

# Install Semgrep
pip3 install semgrep || sudo pip3 install semgrep

# Configure GitHub Actions Runner
# 1. Go to: Settings → Actions → Runners → New self-hosted runner
# 2. Download runner package and follow installation instructions
# 3. Start runner service
```

### Verify Runner Installation

```bash
# Verify all tools
kubectl version --client
helm version
docker --version
aws --version
trivy --version
semgrep --version

# All should return version numbers
```

---

## 🔧 Step 5: Configure GitHub Environments

### Create Environments

1. Go to: **Settings** → **Environments**
2. Click **New environment**
3. Create these environments:

#### Environment: `staging`
- Name: `staging`
- Deployment branches: `develop`, `release/*`
- (Optional) Required reviewers: Add QA team

#### Environment: `production`
- Name: `production`
- Deployment branches: `main` (tagged only)
- Required reviewers: Add DevOps/Lead engineers
- Wait timer: 5 minutes

#### Environment: `production-hotfix`
- Name: `production-hotfix`
- Deployment branches: `hotfix/*`
- (Optional) Required reviewers: Add on-call engineer

---

## 🎯 Step 6: Test the Pipeline

### Test Feature Branch Flow

```bash
# Create develop branch
git checkout -b develop
git push -u origin develop

# Create feature branch
git checkout -b feature/test-feature develop

# Create a test file
echo "test" > test.txt
git add .
git commit -m "test: Pipeline test commit"
git push -u origin feature/test-feature
```

This will trigger the pipeline and deploy to development environment.

### Test Staging Deployment

```bash
# Merge to develop
git checkout develop
git merge feature/test-feature
git push origin develop
```

This will trigger deployment to staging environment.

### Test Production Release

```bash
# Create release branch
git checkout -b release/v1.0.0 develop
git push origin release/v1.0.0

# After testing, merge to main and tag
git checkout main
git merge release/v1.0.0
git tag v1.0.0
git push origin v1.0.0
```

This will trigger production deployment with approval gate.

---

## 📊 Pipeline Workflow

### What Happens on Each Trigger

| Trigger | Branch/Tag | Pipeline Runs | Deploys To |
|---------|------------|---------------|------------|
| Push | `feature/*` | ✅ Full | Development |
| Push | `develop` | ✅ Full | Staging |
| Push | `release/*` | ✅ Full | Staging |
| Tag | `v*` on main | ✅ Full | Production |
| Push | `hotfix/*` | ✅ Full | Production |
| Pull Request | Any | ✅ Validation | None |

---

## 🔍 Monitoring Your Pipeline

### GitHub Actions

- View runs: https://github.com/417buddy/enterprise-payment-platform/actions
- Click on workflow run to see detailed logs
- Re-run failed jobs directly from UI

### Application Monitoring

```bash
# After deployment, check status
kubectl get pods -n payment-platform
kubectl get svc -n payment-platform
kubectl rollout status deployment/payment-service -n payment-platform

# View logs
kubectl logs -f deployment/payment-service -n payment-platform
```

---

## 📚 Documentation

Complete documentation available in:

- **README.md** - Project overview and quick start
- **docs/IMPLEMENTATION-SUMMARY.md** - Complete implementation guide
- **.github/workflows/cicd-pipeline.yaml** - Pipeline configuration (heavily commented)

---

## 🎯 Next Steps

1. ✅ Create GitHub repository
2. ✅ Push code to GitHub
3. ✅ Configure secrets
4. ✅ Setup self-hosted runner
5. ✅ Configure environments
6. ✅ Test pipeline with feature branch
7. ✅ Deploy to staging
8. ✅ Deploy to production

---

## 🆘 Troubleshooting

### Pipeline Won't Start

- Check runner is online: **Settings** → **Actions** → **Runners**
- Verify branch pattern matches workflow triggers
- Confirm secrets are configured correctly

### Runner Issues

```bash
# Check runner service status
sudo systemctl status actions-runner

# Restart runner
sudo systemctl restart actions-runner

# Check logs
journalctl -u actions-runner -f
```

### Deployment Fails

```bash
# Check cluster connection
kubectl cluster-info

# Verify namespace exists
kubectl get namespaces | grep payment-platform

# Check image exists in ECR
aws ecr describe-images --repository-name payment-platform --region us-east-1
```

---

## 🔗 Quick Links

- **GitHub Repository**: https://github.com/417buddy/enterprise-payment-platform
- **GitHub Actions**: https://github.com/417buddy/enterprise-payment-platform/actions
- **AWS Console**: https://us-east-1.console.aws.amazon.com/eks/home?region=us-east-1

---

**Created**: 2024-02-16  
**Version**: 1.0.0  
**AWS Account**: 564268554451  
**Region**: us-east-1

# 🏗️ EC2 Self-Hosted Runner Prerequisites Guide

## Complete Setup for Enterprise Payment Platform CI/CD

---

## 📋 EC2 Instance Requirements

### Minimum Specifications

| Resource | Minimum | Recommended | Production |
|----------|---------|-------------|------------|
| **Instance Type** | t3.large | m5.xlarge | m5.2xlarge |
| **vCPU** | 2 | 4 | 8 |
| **Memory** | 8 GB | 16 GB | 32 GB |
| **Storage** | 50 GB GP3 | 100 GB GP3 | 200 GB GP3 |
| **Network** | 1 Gbps | 10 Gbps | 10 Gbps |

### AMI Recommendation

```
Amazon Linux 2023 OR Ubuntu 22.04 LTS
```

### IAM Role Requirements

Create an IAM role with these policies:
- `AmazonEC2ContainerRegistryPowerUser` - ECR access
- `AmazonEKS_CNI_Policy` - EKS cluster access
- `CloudWatchAgentServerPolicy` - Logging
- `SecretsManagerReadWrite` - Secrets access (optional)

---

## 🔧 Complete Installation Script

### For Amazon Linux 2023 / Amazon Linux 2

```bash
#!/bin/bash
set -e

echo "=========================================="
echo "  EC2 Runner Prerequisites Installation"
echo "=========================================="
echo ""

# Update system
echo "📦 Updating system packages..."
sudo yum update -y

# Install essential tools
echo "📦 Installing essential tools..."
sudo yum install -y \
    git \
    curl \
    wget \
    jq \
    unzip \
    zip \
    vim \
    nano \
    htop \
    net-tools \
    bind-utils \
    amazon-cloudwatch-agent

# Install Docker
echo "🐳 Installing Docker..."
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install AWS CLI v2
echo "☁️  Installing AWS CLI v2..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip

# Install kubectl
echo "☸️  Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
sudo curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum -c
rm kubectl.sha256

# Install Helm
echo "⛵ Installing Helm..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install Trivy (Security Scanner)
echo "🔍 Installing Trivy..."
cat <<EOF | sudo tee /etc/yum.repos.d/trivy.repo
[trivy]
name=Trivy repository
baseurl=https://aquasecurity.github.io/trivy-repo/rpm/releases/\$basearch/
gpgcheck=1
enabled=1
gpgkey=https://aquasecurity.github.io/trivy-repo/rpm/public.key
EOF
sudo yum install -y trivy

# Install Semgrep (SAST Scanner)
echo "🔐 Installing Semgrep..."
pip3 install semgrep || {
    sudo yum install -y python3-pip
    pip3 install semgrep
}

# Install SonarQube Scanner
echo "📊 Installing SonarQube Scanner..."
SONAR_VERSION=5.0.1.3006
wget -q https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_VERSION}-linux.zip
unzip -q sonar-scanner-cli-${SONAR_VERSION}-linux.zip
sudo mv sonar-scanner-${SONAR_VERSION}-linux /opt/sonar-scanner
sudo ln -s /opt/sonar-scanner/bin/sonar-scanner /usr/local/bin/sonar-scanner
rm -rf sonar-scanner-cli-${SONAR_VERSION}-linux.zip sonar-scanner-${SONAR_VERSION}-linux

# Install GitHub Actions Runner Dependencies
echo "🏃 Installing GitHub Actions Runner dependencies..."
sudo yum install -y \
    libicu \
    libicu-devel \
    openssl \
    openssl-devel \
    libffi \
    libffi-devel \
    zlib \
    zlib-devel

# Install additional Kubernetes tools
echo "☸️  Installing additional K8s tools..."

# Install stern (log tailing)
go install github.com/stern/stern@latest
sudo mv ~/go/bin/stern /usr/local/bin/

# Install kubectx and kubens
wget -q https://github.com/ahmetb/kubectx/releases/download/v0.9.4/kubectx
wget -q https://github.com/ahmetb/kubectx/releases/download/v0.9.4/kubens
chmod +x kubectx kubens
sudo mv kubectx kubens /usr/local/bin/

# Install kubeval (manifest validation)
wget https://github.com/instrumenta/kubeval/releases/latest/download/kubeval-linux-amd64.tar.gz
tar xf kubeval-linux-amd64.tar.gz
sudo cp kubeval /usr/local/bin/
rm -rf kubeval-linux-amd64.tar.gz kubeval

# Configure system limits
echo "⚙️  Configuring system limits..."
cat <<EOF | sudo tee -a /etc/security/limits.conf
# GitHub Actions Runner limits
ec2-user soft nofile 65536
ec2-user hard nofile 65536
ec2-user soft nproc 65536
ec2-user hard nproc 65536
EOF

# Configure Docker daemon
echo "🐳 Configuring Docker daemon..."
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "live-restore": true
}
EOF

# Restart Docker
sudo systemctl restart docker

# Verify installations
echo ""
echo "=========================================="
echo "  Verification"
echo "=========================================="
echo ""

tools=(
    "docker --version"
    "docker-compose --version"
    "aws --version"
    "kubectl version --client"
    "helm version"
    "trivy --version"
    "semgrep --version"
    "sonar-scanner -version"
    "git --version"
    "jq --version"
    "kubeval --version"
)

for tool in "${tools[@]}"; do
    echo "Checking $tool..."
    if command -v $(echo $tool | awk '{print $1}') &> /dev/null; then
        echo "✅ $(echo $tool | awk '{print $1}'): $($tool 2>&1 | head -n 1)"
    else
        echo "❌ $(echo $tool | awk '{print $1}'): NOT INSTALLED"
    fi
done

echo ""
echo "=========================================="
echo "  Installation Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Configure AWS credentials (if not using IAM role)"
echo "   aws configure"
echo ""
echo "2. Configure kubectl for your EKS cluster"
echo "   aws eks update-kubeconfig --name payment-platform-prod --region us-east-1"
echo ""
echo "3. Install GitHub Actions Runner"
echo "   Follow instructions from: Settings → Actions → Runners → New self-hosted runner"
echo ""
echo "4. Start the runner service"
echo ""
echo "5. Test runner with test-runner workflow"
echo ""
```

---

### For Ubuntu 22.04 LTS

```bash
#!/bin/bash
set -e

echo "=========================================="
echo "  EC2 Runner Prerequisites Installation"
echo "=========================================="
echo ""

# Update system
echo "📦 Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y

# Install essential tools
echo "📦 Installing essential tools..."
sudo apt-get install -y \
    git \
    curl \
    wget \
    jq \
    unzip \
    zip \
    vim \
    nano \
    htop \
    net-tools \
    dnsutils \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common

# Install Docker
echo "🐳 Installing Docker..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ubuntu

# Install Docker Compose standalone
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install AWS CLI v2
echo "☁️  Installing AWS CLI v2..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip

# Install kubectl
echo "☸️  Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Install Helm
echo "⛵ Installing Helm..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install Trivy
echo "🔍 Installing Trivy..."
sudo apt-get install -y wget apt-transport-https gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo gpg --dearmor -o /usr/share/keyrings/trivy.gpg
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install -y trivy

# Install Semgrep
echo "🔐 Installing Semgrep..."
pip3 install semgrep || {
    sudo apt-get install -y python3-pip
    pip3 install semgrep
}

# Install SonarQube Scanner
echo "📊 Installing SonarQube Scanner..."
SONAR_VERSION=5.0.1.3006
wget -q https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_VERSION}-linux.zip
unzip -q sonar-scanner-cli-${SONAR_VERSION}-linux.zip
sudo mv sonar-scanner-${SONAR_VERSION}-linux /opt/sonar-scanner
sudo ln -s /opt/sonar-scanner/bin/sonar-scanner /usr/local/bin/sonar-scanner
rm -rf sonar-scanner-cli-${SONAR_VERSION}-linux.zip sonar-scanner-${SONAR_VERSION}-linux

# Install GitHub Actions Runner Dependencies
echo "🏃 Installing GitHub Actions Runner dependencies..."
sudo apt-get install -y \
    libicu70 \
    libicu-dev \
    openssl \
    libssl-dev \
    libffi8 \
    libffi-dev \
    zlib1g \
    zlib1g-dev

# Install additional Kubernetes tools
echo "☸️  Installing additional K8s tools..."

# Install Go for stern
wget -q https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
go install github.com/stern/stern@latest
sudo mv ~/go/bin/stern /usr/local/bin/
rm -rf go1.21.5.linux-amd64.tar.gz

# Install kubectx and kubens
wget -q https://github.com/ahmetb/kubectx/releases/download/v0.9.4/kubectx
wget -q https://github.com/ahmetb/kubectx/releases/download/v0.9.4/kubens
chmod +x kubectx kubens
sudo mv kubectx kubens /usr/local/bin/

# Install kubeval
wget https://github.com/instrumenta/kubeval/releases/latest/download/kubeval-linux-amd64.tar.gz
tar xf kubeval-linux-amd64.tar.gz
sudo cp kubeval /usr/local/bin/
rm -rf kubeval-linux-amd64.tar.gz kubeval

# Configure system limits
echo "⚙️  Configuring system limits..."
cat <<EOF | sudo tee -a /etc/security/limits.conf
# GitHub Actions Runner limits
ubuntu soft nofile 65536
ubuntu hard nofile 65536
ubuntu soft nproc 65536
ubuntu hard nproc 65536
EOF

# Configure Docker daemon
echo "🐳 Configuring Docker daemon..."
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "live-restore": true
}
EOF

# Restart Docker
sudo systemctl restart docker

# Verify installations
echo ""
echo "=========================================="
echo "  Verification"
echo "=========================================="
echo ""

tools=(
    "docker --version"
    "docker-compose --version"
    "aws --version"
    "kubectl version --client"
    "helm version"
    "trivy --version"
    "semgrep --version"
    "sonar-scanner -version"
    "git --version"
    "jq --version"
    "kubeval --version"
)

for tool in "${tools[@]}"; do
    echo "Checking $tool..."
    if command -v $(echo $tool | awk '{print $1}') &> /dev/null; then
        echo "✅ $(echo $tool | awk '{print $1}'): $($tool 2>&1 | head -n 1)"
    else
        echo "❌ $(echo $tool | awk '{print $1}'): NOT INSTALLED"
    fi
done

echo ""
echo "=========================================="
echo "  Installation Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Configure AWS credentials (if not using IAM role)"
echo "   aws configure"
echo ""
echo "2. Configure kubectl for your EKS cluster"
echo "   aws eks update-kubeconfig --name payment-platform-prod --region us-east-1"
echo ""
echo "3. Install GitHub Actions Runner"
echo "   Follow instructions from: Settings → Actions → Runners → New self-hosted runner"
echo ""
```

---

## 🔐 IAM Role Policy for EC2 Runner

Create this IAM role and attach to your EC2 instance:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:DescribeImages",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ],
      "Resource": "arn:aws:ecr:us-east-1:564268554451:repository/payment-platform"
    },
    {
      "Effect": "Allow",
      "Action": [
        "eks:DescribeCluster",
        "eks:ListClusters",
        "eks:AccessKubernetesApi"
      ],
      "Resource": "arn:aws:eks:us-east-1:564268554451:cluster/payment-platform-prod"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ],
      "Resource": "arn:aws:logs:us-east-1:564268554451:log-group:/aws/containerinsights/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": "arn:aws:secretsmanager:us-east-1:564268554451:secret:payment-platform/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParametersByPath"
      ],
      "Resource": "arn:aws:ssm:us-east-1:564268554451:parameter/payment-platform/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "cloudwatch:PutMetricData",
        "cloudwatch:GetMetricData",
        "cloudwatch:GetMetricStatistics"
      ],
      "Resource": "*"
    }
  ]
}
```

---

## 🔧 Post-Installation Configuration

### 1. Configure AWS Credentials (if not using IAM role)

```bash
aws configure
# AWS Access Key ID: [your-key]
# AWS Secret Access Key: [your-secret]
# Default region name: us-east-1
# Default output format: json
```

### 2. Configure EKS Cluster Access

```bash
aws eks update-kubeconfig --name payment-platform-prod --region us-east-1

# Test connection
kubectl cluster-info
kubectl get nodes
```

### 3. Test Kubernetes Access

```bash
# Test all required operations
kubectl get namespaces
kubectl get pods -A
kubectl get svc -A
kubectl auth can-i create deployments -n payment-platform
kubectl auth can-i get secrets -n payment-platform
```

### 4. Test Docker

```bash
docker run --rm hello-world
docker info
```

### 5. Test Security Tools

```bash
# Test Trivy
trivy --version

# Test Semgrep
semgrep --version

# Test SonarQube Scanner
sonar-scanner -version
```

---

## 🧪 Runner Test Checklist

Before registering the runner, verify:

- [ ] All tools installed and in PATH
- [ ] Docker daemon running
- [ ] EKS cluster accessible
- [ ] AWS credentials configured
- [ ] System limits configured
- [ ] Security groups allow outbound HTTPS
- [ ] Sufficient disk space (50GB+ free)
- [ ] Sufficient memory (8GB+ free)

---

## 🏃 Install GitHub Actions Runner

### Download and Install

```bash
# Create runner directory
mkdir -p /home/ec2-user/actions-runner && cd /home/ec2-user/actions-runner

# Download runner (get latest from GitHub)
curl -O -L https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-x64-2.311.0.tar.gz

# Extract
tar xzf actions-runner-linux-x64-2.311.0.tar.gz

# Configure (get URL and token from GitHub)
./config.sh --url https://github.com/417buddy/enterprise-payment-platform \
            --token YOUR_TOKEN_HERE \
            --name enterprise_runner-1 \
            --runnergroup default \
            --labels self-hosted,linux,x64,enterprise \
            --work /home/ec2-user/actions-runner/_work

# Install as service
sudo ./svc.sh install ec2-user
sudo ./svc.sh start
```

### Verify Runner

```bash
# Check runner status
sudo ./svc.sh status

# View runner logs
tail -f /home/ec2-user/actions-runner/_diag/Runner_*.log
```

---

## 📊 Monitoring & Maintenance

### CloudWatch Agent Configuration

```bash
# Install CloudWatch agent
sudo yum install -y amazon-cloudwatch-agent

# Configure
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-config-wizard

# Start
sudo systemctl start amazon-cloudwatch-agent
sudo systemctl enable amazon-cloudwatch-agent
```

### Log Rotation

```bash
# Configure log rotation
cat <<EOF | sudo tee /etc/logrotate.d/actions-runner
/home/ec2-user/actions-runner/_diag/*.log {
    daily
    rotate 14
    compress
    delaycompress
    notifempty
    missingok
    create 0644 ec2-user ec2-user
}
EOF
```

### Auto-Update Script

```bash
# Create update script
cat <<EOF | sudo tee /usr/local/bin/update-runner.sh
#!/bin/bash
cd /home/ec2-user/actions-runner
sudo ./svc.sh stop
./run.sh &
sleep 30
sudo ./svc.sh start
EOF

chmod +x /usr/local/bin/update-runner.sh
```

---

## 🆘 Troubleshooting

### Docker Permission Denied

```bash
# Add user to docker group
sudo usermod -aG docker ec2-user
newgrp docker

# Restart docker
sudo systemctl restart docker
```

### kubectl Connection Failed

```bash
# Update kubeconfig
aws eks update-kubeconfig --name payment-platform-prod --region us-east-1

# Verify
kubectl cluster-info
```

### Runner Offline

```bash
# Check service status
sudo ./svc.sh status

# Restart service
sudo ./svc.sh restart

# Check logs
tail -f /home/ec2-user/actions-runner/_diag/Runner_*.log
```

### Out of Disk Space

```bash
# Clean Docker
docker system prune -af

# Clean old logs
sudo find /home/ec2-user/actions-runner/_diag -name "*.log" -mtime +7 -delete

# Check disk usage
df -h
```

---

## ✅ Verification Commands

Run these to verify everything is working:

```bash
# System info
uname -a
free -h
df -h

# Tool versions
docker --version
docker-compose --version
aws --version
kubectl version --client
helm version
trivy --version
semgrep --version
sonar-scanner -version
git --version
jq --version
kubeval --version

# Docker test
docker run --rm alpine echo "Docker works"

# Kubectl test
kubectl cluster-info
kubectl get nodes

# AWS test
aws sts get-caller-identity
aws eks describe-cluster --name payment-platform-prod
```

---

**Your EC2 runner is now ready for enterprise CI/CD pipeline execution!** 🚀
#!/bin/bash
set -e

######################################################################
# Enterprise Payment Platform - EC2 Runner Setup Script
# Automated installation of all prerequisites for GitHub Actions runner
######################################################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo_colored() {
    color=$1
    shift
    echo -e "${color}$@${NC}"
}

section() {
    echo_colored $BLUE "========================================"
    echo_colored $BLUE "  $1"
    echo_colored $BLUE "========================================"
}

step() {
    echo_colored $GREEN ">>> $1"
}

warn() {
    echo_colored $YELLOW "⚠️  $1"
}

error_exit() {
    echo_colored $RED "❌ ERROR: $1"
    exit 1
}

success() {
    echo_colored $GREEN "✅ $1"
}

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    error_exit "Cannot detect operating system"
fi

echo ""
section "EC2 Runner Prerequisites Installation"
echo ""
echo "Detected OS: $OS"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    error_exit "Please run as root (use sudo)"
fi

# Step 1: System Update
section "Step 1: System Update"
step "Updating system packages..."

if [ "$OS" = "amzn" ]; then
    yum update -y
elif [ "$OS" = "ubuntu" ]; then
    apt-get update && apt-get upgrade -y
else
    error_exit "Unsupported OS: $OS"
fi

success "System updated"

# Step 2: Install Essential Tools
section "Step 2: Install Essential Tools"

if [ "$OS" = "amzn" ]; then
    yum install -y git curl wget jq unzip zip vim nano htop net-tools bind-utils
elif [ "$OS" = "ubuntu" ]; then
    apt-get install -y git curl wget jq unzip zip vim nano htop net-tools dnsutils
fi

success "Essential tools installed"

# Step 3: Install Docker
section "Step 3: Install Docker"
step "Installing Docker..."

if [ "$OS" = "amzn" ]; then
    yum install -y docker
    systemctl start docker
    systemctl enable docker
elif [ "$OS" = "ubuntu" ]; then
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    systemctl start docker
    systemctl enable docker
fi

# Get username based on OS
if [ "$OS" = "amzn" ]; then
    USER_NAME="ec2-user"
elif [ "$OS" = "ubuntu" ]; then
    USER_NAME="ubuntu"
fi

usermod -aG docker $USER_NAME

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

success "Docker installed and configured"

# Step 4: Install AWS CLI v2
section "Step 4: Install AWS CLI v2"
step "Installing AWS CLI v2..."

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

success "AWS CLI v2 installed"

# Step 5: Install kubectl
section "Step 5: Install kubectl"
step "Installing kubectl..."

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

success "kubectl installed"

# Step 6: Install Helm
section "Step 6: Install Helm"
step "Installing Helm..."

curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

success "Helm installed"

# Step 7: Install Trivy
section "Step 7: Install Trivy"
step "Installing Trivy..."

if [ "$OS" = "amzn" ]; then
    cat <<EOF | tee /etc/yum.repos.d/trivy.repo
[trivy]
name=Trivy repository
baseurl=https://aquasecurity.github.io/trivy-repo/rpm/releases/\$basearch/
gpgcheck=1
enabled=1
gpgkey=https://aquasecurity.github.io/trivy-repo/rpm/public.key
EOF
    yum install -y trivy
elif [ "$OS" = "ubuntu" ]; then
    wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor -o /usr/share/keyrings/trivy.gpg
    echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | tee -a /etc/apt/sources.list.d/trivy.list
    apt-get update
    apt-get install -y trivy
fi

success "Trivy installed"

# Step 8: Install Semgrep
section "Step 8: Install Semgrep"
step "Installing Semgrep..."

if ! command -v pip3 &> /dev/null; then
    if [ "$OS" = "amzn" ]; then
        yum install -y python3-pip
    elif [ "$OS" = "ubuntu" ]; then
        apt-get install -y python3-pip
    fi
fi

pip3 install semgrep

success "Semgrep installed"

# Step 9: Install SonarQube Scanner
section "Step 9: Install SonarQube Scanner"
step "Installing SonarQube Scanner..."

SONAR_VERSION=5.0.1.3006
wget -q https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_VERSION}-linux.zip
unzip -q sonar-scanner-cli-${SONAR_VERSION}-linux.zip
mv sonar-scanner-${SONAR_VERSION}-linux /opt/sonar-scanner
ln -s /opt/sonar-scanner/bin/sonar-scanner /usr/local/bin/sonar-scanner
rm -rf sonar-scanner-cli-${SONAR_VERSION}-linux.zip sonar-scanner-${SONAR_VERSION}-linux

success "SonarQube Scanner installed"

# Step 10: Install Additional K8s Tools
section "Step 10: Install Additional Kubernetes Tools"

# Install kubeval
step "Installing kubeval..."
wget https://github.com/instrumenta/kubeval/releases/latest/download/kubeval-linux-amd64.tar.gz
tar xf kubeval-linux-amd64.tar.gz
cp kubeval /usr/local/bin/
rm -rf kubeval-linux-amd64.tar.gz kubeval

# Install kubectx and kubens
step "Installing kubectx and kubens..."
wget -q https://github.com/ahmetb/kubectx/releases/download/v0.9.4/kubectx
wget -q https://github.com/ahmetb/kubectx/releases/download/v0.9.4/kubens
chmod +x kubectx kubens
mv kubectx kubens /usr/local/bin/

success "Additional K8s tools installed"

# Step 11: Configure System Limits
section "Step 11: Configure System Limits"
step "Configuring system limits..."

cat <<EOF | tee -a /etc/security/limits.conf
# GitHub Actions Runner limits
$USER_NAME soft nofile 65536
$USER_NAME hard nofile 65536
$USER_NAME soft nproc 65536
$USER_NAME hard nproc 65536
EOF

success "System limits configured"

# Step 12: Configure Docker Daemon
section "Step 12: Configure Docker Daemon"
step "Configuring Docker daemon..."

cat <<EOF | tee /etc/docker/daemon.json
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

systemctl restart docker

success "Docker daemon configured"

# Step 13: Verification
section "Step 13: Verification"
echo ""
echo "Installed tools:"
echo ""

tools=(
    "docker"
    "docker-compose"
    "aws"
    "kubectl"
    "helm"
    "trivy"
    "semgrep"
    "sonar-scanner"
    "git"
    "jq"
    "kubeval"
)

for tool in "${tools[@]}"; do
    if command -v $tool &> /dev/null; then
        version=$($tool --version 2>&1 | head -n 1 || $tool version 2>&1 | head -n 1 || $tool -version 2>&1 | head -n 1 || echo "installed")
        echo "✅ $tool: $version"
    else
        echo "❌ $tool: NOT INSTALLED"
    fi
done

echo ""

# Step 14: Final Instructions
section "Installation Complete!"
echo ""
success "All prerequisites installed successfully!"
echo ""
echo_colored $BLUE "📋 Next Steps:"
echo ""
echo "1. Configure AWS credentials (if not using IAM role):"
echo "   aws configure"
echo ""
echo "2. Configure EKS cluster access:"
echo "   aws eks update-kubeconfig --name payment-platform-prod --region us-east-1"
echo ""
echo "3. Test Kubernetes connection:"
echo "   kubectl cluster-info"
echo "   kubectl get nodes"
echo ""
echo "4. Install GitHub Actions Runner:"
echo "   - Go to: https://github.com/417buddy/enterprise-payment-platform/settings/actions/runners"
echo "   - Click 'New self-hosted runner'"
echo "   - Follow the instructions to download and configure the runner"
echo ""
echo "5. Start the runner service and test with a workflow"
echo ""
echo_colored $YELLOW "⚠️  Important:"
echo "- Reboot the instance to apply all updates: sudo reboot"
echo "- Ensure security group allows outbound HTTPS (443)"
echo "- Monitor disk space: df -h"
echo "- Monitor memory: free -h"
echo ""
echo_colored $GREEN "Your EC2 runner is ready for enterprise CI/CD! 🚀"
echo ""

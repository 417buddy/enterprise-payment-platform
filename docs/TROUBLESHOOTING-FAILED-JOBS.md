# 🔧 Troubleshooting Failed Jobs

## Code Quality & Security Scan Failure

---

## ❌ Common Failure Reasons

### 1. **Missing Required Tools** (Most Common)

The job fails because these tools are not installed on your self-hosted runner:

- `sonar-scanner`
- `semgrep`
- `trivy`
- `jq`
- `pip3` (for installing semgrep)

**Solution:** Install all prerequisites using the setup script:

```bash
# On your EC2 runner
cd /home/ec2-user
curl -O https://raw.githubusercontent.com/417buddy/enterprise-payment-platform/main/scripts/setup-ec2-runner.sh
chmod +x setup-ec2-runner.sh
sudo ./setup-ec2-runner.sh
```

Or manually install missing tools:

```bash
# Install Semgrep
pip3 install semgrep

# Install Trivy
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo gpg --dearmor -o /usr/share/keyrings/trivy.gpg
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update && sudo apt-get install -y trivy

# Install jq
sudo apt-get install -y jq

# Install sonar-scanner
wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip
unzip sonar-scanner-cli-5.0.1.3006-linux.zip
sudo mv sonar-scanner-5.0.1.3006-linux /opt/sonar-scanner
sudo ln -s /opt/sonar-scanner/bin/sonar-scanner /usr/local/bin/sonar-scanner
```

---

### 2. **Git Not Configured Properly**

**Error:** `fatal: not a git repository`

**Solution:**
```bash
# Verify git is installed
git --version

# If not installed
sudo apt-get install -y git  # Ubuntu
sudo yum install -y git      # Amazon Linux
```

---

### 3. **Permission Denied Errors**

**Error:** `Permission denied` when running tools

**Solution:**
```bash
# Check file permissions
ls -la /usr/local/bin/

# Fix permissions
sudo chmod +x /usr/local/bin/sonar-scanner
sudo chmod +x /usr/local/bin/trivy
sudo chmod +x /usr/local/bin/semgrep
```

---

### 4. **Python/pip3 Not Available**

**Error:** `pip3: command not found`

**Solution:**
```bash
# Install pip3
sudo apt-get install -y python3-pip  # Ubuntu
sudo yum install -y python3-pip      # Amazon Linux

# Verify
pip3 --version
```

---

### 5. **Semgrep Installation Fails**

**Error:** `ERROR: Could not find a version that satisfies the requirement semgrep`

**Solution:**
```bash
# Upgrade pip first
pip3 install --upgrade pip

# Then install semgrep
pip3 install semgrep

# Or use alternative installation
curl -L https://semgrep.dev/install | bash
```

---

### 6. **Insufficient Disk Space**

**Error:** `No space left on device`

**Solution:**
```bash
# Check disk space
df -h

# Clean up
docker system prune -af
sudo apt-get clean  # Ubuntu
sudo yum clean all  # Amazon Linux

# Remove old logs
sudo find /home/ec2-user/actions-runner/_diag -name "*.log" -mtime +7 -delete
```

---

### 7. **Out of Memory**

**Error:** `Killed` or `Out of memory`

**Solution:**
```bash
# Check memory
free -h

# Close unnecessary processes
ps aux --sort=-%mem | head

# Consider upgrading instance type
# Minimum: t3.large (8GB RAM)
# Recommended: m5.xlarge (16GB RAM)
```

---

## 🔍 How to Diagnose the Exact Error

### Step 1: View Job Logs

1. Go to: https://github.com/417buddy/enterprise-payment-platform/actions
2. Click on the failed workflow run
3. Click on **"🔍 Code Quality & Security Scan"** job
4. Expand each step to see the error message

### Step 2: Identify Failing Step

Look for the step that failed:
- 📋 Checkout code
- ℹ️ Get branch info
- 🏷️ Generate semantic version
- 📊 SonarQube Code Quality Scan ← **Common failure point**
- 🔐 SAST - Static Application Security Testing ← **Common failure point**
- 🔍 Secret Detection
- 📦 Dependency Vulnerability Scan ← **Common failure point**

### Step 3: Check Error Message

The error message will tell you what's wrong:
- `command not found` → Tool not installed
- `Permission denied` → Permission issue
- `Connection refused` → Network issue
- `No space left on device` → Disk space issue

---

## ✅ Quick Fix Checklist

Run these commands on your self-hosted runner:

```bash
# 1. Check if runner is running
cd /home/ec2-user/actions-runner
sudo ./svc.sh status

# 2. Verify all required tools
echo "Checking required tools..."
git --version || echo "❌ git missing"
jq --version || echo "❌ jq missing"
docker --version || echo "❌ docker missing"
kubectl version --client || echo "❌ kubectl missing"
helm version || echo "❌ helm missing"
trivy --version || echo "❌ trivy missing"
semgrep --version || echo "❌ semgrep missing"
sonar-scanner -version || echo "❌ sonar-scanner missing"

# 3. Check disk space
df -h

# 4. Check memory
free -h

# 5. Check Docker
docker info

# 6. Check AWS credentials
aws sts get-caller-identity

# 7. Check Kubernetes access
kubectl cluster-info
```

---

## 🚀 Complete Reinstallation (If All Else Fails)

```bash
# Stop runner
cd /home/ec2-user/actions-runner
sudo ./svc.sh stop

# Remove and reinstall all tools
sudo apt-get remove --purge -y trivy semgrep sonar-scanner 2>/dev/null || true

# Run the complete setup script
cd /tmp
curl -O https://raw.githubusercontent.com/417buddy/enterprise-payment-platform/main/scripts/setup-ec2-runner.sh
chmod +x setup-ec2-runner.sh
sudo ./setup-ec2-runner.sh

# Restart runner
cd /home/ec2-user/actions-runner
sudo ./svc.sh start

# Verify
sudo ./svc.sh status
```

---

## 📊 Expected Output After Fix

When everything is working, you should see:

```
✅ SonarQube scan completed
✅ SAST scan passed - No critical security issues found
✅ No hardcoded secrets detected
✅ Dependency vulnerability scan completed
```

---

## 🆘 Still Having Issues?

### Enable Debug Logging

Add this secret to your repository:
- Name: `ACTIONS_RUNNER_DEBUG`
- Value: `true`

Then re-run the job and check the detailed logs.

### Check Runner Logs

```bash
# View runner logs
tail -f /home/ec2-user/actions-runner/_diag/Runner_*.log

# Or
journalctl -u actions-runner -f
```

### Test Tools Manually

```bash
# Test each tool
cd /home/ec2-user/actions-runner

# Git
git clone https://github.com/417buddy/enterprise-payment-platform.git test-repo
cd test-repo

# Semgrep
semgrep --version

# Trivy
trivy --version

# kubectl
kubectl version --client

# Docker
docker run --rm hello-world
```

---

## 📝 Prevention for Future Runs

After fixing, ensure your runner stays healthy:

1. **Regular Updates:**
   ```bash
   sudo apt-get update && sudo apt-get upgrade -y  # Ubuntu
   sudo yum update -y                              # Amazon Linux
   ```

2. **Disk Cleanup:**
   ```bash
   # Add to crontab
   0 2 * * * docker system prune -af
   ```

3. **Monitor Resources:**
   ```bash
   # Install monitoring
   sudo yum install -y amazon-cloudwatch-agent  # Amazon Linux
   ```

4. **Auto-Update Runner:**
   The runner auto-updates, but monitor for issues.

---

## ✅ Verification After Fix

Run a test workflow to verify:

1. Go to: https://github.com/417buddy/enterprise-payment-platform/actions
2. Select **"🧪 Test Runner"** workflow
3. Click **"Run workflow"**
4. All steps should pass ✅

---

**After applying these fixes, re-run your workflow and the job should succeed!** 🚀

If you're still experiencing issues, please share:
1. The exact error message from the logs
2. Your EC2 instance type
3. Output of the verification commands above

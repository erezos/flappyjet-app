# 🔧 Firebase Test Lab - Troubleshooting Guide

## 🐛 gcloud Installation Issues

### Issue: Python 3.13 not found

**Error:**
```
ERROR: (gcloud.config.virtualenv.create) /opt/homebrew/opt/python@3.13/libexec/bin/python3: command not found
```

**Solution 1: Install Python 3.11 first**

```bash
# Install Python 3.11
brew install python@3.11

# Set Python path
export CLOUDSDK_PYTHON=$(brew --prefix python@3.11)/bin/python3

# Then install gcloud
brew install --cask gcloud-cli
```

**Solution 2: Use system Python**

```bash
# Check system Python
which python3
python3 --version

# Set to use system Python
export CLOUDSDK_PYTHON=$(which python3)

# Install gcloud
brew install --cask gcloud-cli
```

**Solution 3: Manual Installation (Recommended if brew fails)**

```bash
# Download and install manually
curl https://sdk.cloud.google.com | bash

# Restart terminal or source
exec -l $SHELL

# Initialize
gcloud init
```

---

### Issue: File conflict during installation

**Error:**
```
Error: gcloud-cli: same file: /opt/homebrew/Caskroom/gcloud-cli/...
```

**Solution:**

```bash
# Clean up old installation
brew uninstall --cask gcloud-cli
rm -rf /opt/homebrew/Caskroom/gcloud-cli
rm -rf /opt/homebrew/share/google-cloud-sdk

# Reinstall
brew install --cask gcloud-cli
```

---

## 🔧 Alternative: Use Manual Installation

If brew continues to fail, use manual installation:

```bash
# 1. Download installer
curl https://sdk.cloud.google.com | bash

# 2. Restart terminal or source
exec -l $SHELL

# 3. Initialize
gcloud init

# 4. Login
gcloud auth login

# 5. Set project
gcloud config set project YOUR_PROJECT_ID
```

---

## ✅ Verify Installation

After installation, verify:

```bash
# Check gcloud is installed
gcloud --version

# Check authentication
gcloud auth list

# Check project
gcloud config get-value project

# List available devices
gcloud firebase test android models list --limit=5
```

---

## 🚀 Once gcloud is Working

Then you can run:

```bash
./scripts/build_and_test_firebase.sh
```

---

## 🆘 Still Having Issues?

1. **Check Python version:**
   ```bash
   python3 --version
   # Should be 3.10 or higher
   ```

2. **Set Python explicitly:**
   ```bash
   export CLOUDSDK_PYTHON=$(which python3)
   ```

3. **Try manual installation:**
   ```bash
   curl https://sdk.cloud.google.com | bash
   ```

4. **Check PATH:**
   ```bash
   echo $PATH | grep google-cloud-sdk
   # If not found, add to ~/.zshrc:
   # export PATH="/opt/homebrew/share/google-cloud-sdk/bin:$PATH"
   ```

---

## 📚 Resources

- [gcloud Installation Guide](https://cloud.google.com/sdk/docs/install)
- [Firebase Test Lab Docs](https://firebase.google.com/docs/test-lab)


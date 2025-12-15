#!/bin/bash

# 🔧 Alternative gcloud Installation Script
# 
# If brew install fails, use this method instead

set -e

echo "🔧 Installing gcloud CLI (Alternative Method)"
echo ""

# Check if gcloud is already installed
if command -v gcloud &> /dev/null; then
    echo "✅ gcloud is already installed!"
    gcloud --version
    exit 0
fi

# Method 1: Install Python first, then gcloud
echo "📦 Step 1: Installing Python 3.10+..."
brew install python@3.11

echo ""
echo "📦 Step 2: Setting Python path..."
export CLOUDSDK_PYTHON=$(brew --prefix python@3.11)/bin/python3

echo ""
echo "📦 Step 3: Installing gcloud..."
brew install --cask gcloud-cli

echo ""
echo "📦 Step 4: Initializing gcloud..."
gcloud init

echo ""
echo "✅ Installation complete!"
echo ""
echo "Add to your ~/.zshrc:"
echo "  export PATH=\"/opt/homebrew/share/google-cloud-sdk/bin:\$PATH\""
echo "  export CLOUDSDK_PYTHON=$(brew --prefix python@3.11)/bin/python3"


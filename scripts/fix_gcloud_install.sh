#!/bin/bash

# 🔧 Fix gcloud Installation Script
# 
# This script fixes the Python path issue and installs gcloud properly

set -e

echo "🔧 Fixing gcloud Installation..."
echo ""

# Step 1: Set Python to use system Python
echo "📦 Step 1: Setting Python path..."
export CLOUDSDK_PYTHON=$(which python3)
echo "   Using Python: $CLOUDSDK_PYTHON"
echo "   Python version: $(python3 --version)"
echo ""

# Step 2: Clean up any broken installation
echo "📦 Step 2: Cleaning up old installation..."
brew uninstall --cask gcloud-cli 2>/dev/null || echo "   No old installation to remove"
rm -rf /opt/homebrew/Caskroom/gcloud-cli 2>/dev/null || echo "   No caskroom to clean"
echo ""

# Step 3: Install gcloud with correct Python
echo "📦 Step 3: Installing gcloud-cli..."
echo "   This may take a few minutes..."
brew install --cask gcloud-cli
echo ""

# Step 4: Verify installation
echo "📦 Step 4: Verifying installation..."
if command -v gcloud &> /dev/null; then
    echo "✅ gcloud installed successfully!"
    gcloud --version
    echo ""
    echo "📝 Next steps:"
    echo "   1. Run: gcloud auth login"
    echo "   2. Run: gcloud init"
    echo "   3. Then run: ./scripts/setup_firebase_test_lab.sh"
else
    echo "❌ Installation failed. Trying manual installation..."
    echo ""
    echo "Run this command:"
    echo "   curl https://sdk.cloud.google.com | bash"
    echo ""
    echo "Then restart your terminal and run:"
    echo "   gcloud init"
fi


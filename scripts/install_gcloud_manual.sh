#!/bin/bash

# 🔧 Manual gcloud Installation Script
# 
# This bypasses brew and installs gcloud directly
# This is more reliable when brew has Python path issues

set -e

echo "🔧 Installing gcloud CLI (Manual Method)"
echo ""

# Check if gcloud is already installed
if command -v gcloud &> /dev/null; then
    echo "✅ gcloud is already installed!"
    gcloud --version
    exit 0
fi

# Step 1: Set Python path
echo "📦 Step 1: Setting Python path..."
export CLOUDSDK_PYTHON=$(which python3)
echo "   Using Python: $CLOUDSDK_PYTHON"
echo ""

# Step 2: Download and install
echo "📦 Step 2: Downloading and installing gcloud..."
echo "   This will download ~50MB and may take a few minutes..."
echo ""

# Download installer
curl https://sdk.cloud.google.com | bash

# Step 3: Source the path
echo ""
echo "📦 Step 3: Adding gcloud to PATH..."
INSTALL_DIR="$HOME/google-cloud-sdk"
if [ -d "$INSTALL_DIR" ]; then
    export PATH="$INSTALL_DIR/bin:$PATH"
    echo "   Added to PATH: $INSTALL_DIR/bin"
else
    # Try common installation location
    if [ -d "/opt/homebrew/share/google-cloud-sdk" ]; then
        export PATH="/opt/homebrew/share/google-cloud-sdk/bin:$PATH"
        echo "   Added to PATH: /opt/homebrew/share/google-cloud-sdk/bin"
    fi
fi

# Step 4: Verify installation
echo ""
echo "📦 Step 4: Verifying installation..."
if command -v gcloud &> /dev/null; then
    echo "✅ gcloud installed successfully!"
    gcloud --version
    echo ""
    echo "📝 Add to your ~/.zshrc:"
    echo "   export PATH=\"\$HOME/google-cloud-sdk/bin:\$PATH\""
    echo "   export CLOUDSDK_PYTHON=$(which python3)"
    echo ""
    echo "📝 Next steps:"
    echo "   1. Restart terminal or run: source ~/.zshrc"
    echo "   2. Run: gcloud auth login"
    echo "   3. Run: gcloud init"
    echo "   4. Then run: ./scripts/setup_firebase_test_lab.sh"
else
    echo "❌ Installation may have completed, but gcloud not in PATH"
    echo ""
    echo "Try:"
    echo "   1. Restart terminal"
    echo "   2. Or run: source ~/.zshrc"
    echo "   3. Then verify: gcloud --version"
fi


#!/bin/bash

# 🔥 Firebase Test Lab Setup Script
# 
# This script helps you set up Firebase Test Lab for the first time

set -e

echo "🔥 Firebase Test Lab Setup"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Step 1: Check gcloud installation
echo -e "${BLUE}Step 1: Checking gcloud CLI...${NC}"
if ! command -v gcloud &> /dev/null; then
    echo -e "${YELLOW}⚠️  gcloud CLI not found.${NC}"
    echo ""
    echo "Install it with:"
    echo "  brew install google-cloud-sdk"
    echo ""
    echo "Or visit: https://cloud.google.com/sdk/docs/install"
    exit 1
fi
echo -e "${GREEN}✅ gcloud CLI found${NC}"
echo ""

# Step 2: Login
echo -e "${BLUE}Step 2: Authenticating with Google...${NC}"
gcloud auth login
echo ""

# Step 3: List Firebase projects
echo -e "${BLUE}Step 3: Available Firebase projects:${NC}"
gcloud projects list --format="table(projectId,name)"
echo ""

# Step 4: Set project
echo -e "${BLUE}Step 4: Set your Firebase project ID${NC}"
read -p "Enter your Firebase project ID: " PROJECT_ID

if [ -z "$PROJECT_ID" ]; then
    echo "❌ Project ID cannot be empty"
    exit 1
fi

gcloud config set project $PROJECT_ID
echo -e "${GREEN}✅ Project set to: $PROJECT_ID${NC}"
echo ""

# Step 5: Enable APIs
echo -e "${BLUE}Step 5: Enabling required APIs...${NC}"
echo "   Attempting to enable APIs via gcloud..."
if gcloud services enable cloudtesting.googleapis.com 2>/dev/null; then
    echo "   ✅ Cloud Testing API enabled"
else
    echo "   ⚠️  Could not enable via gcloud (may need Firebase Console)"
fi

if gcloud services enable toolresults.googleapis.com 2>/dev/null; then
    echo "   ✅ Tool Results API enabled"
else
    echo "   ⚠️  Could not enable via gcloud (may need Firebase Console)"
fi

if gcloud services enable storage-component.googleapis.com 2>/dev/null; then
    echo "   ✅ Storage API enabled"
else
    echo "   ⚠️  Could not enable via gcloud (may need Firebase Console)"
fi

echo ""
echo -e "${YELLOW}⚠️  If APIs failed to enable, they may need to be enabled via Firebase Console:${NC}"
echo "   1. Go to: https://console.firebase.google.com/project/$PROJECT_ID/settings/general"
echo "   2. Or enable via: https://console.cloud.google.com/apis/library?project=$PROJECT_ID"
echo "   3. Search for 'Cloud Testing API' and enable it"
echo ""
echo -e "${GREEN}✅ Setup complete (APIs may need manual enablement)${NC}"
echo ""

# Step 6: Create environment file
echo -e "${BLUE}Step 6: Creating environment configuration...${NC}"
cat > .firebase_test_lab.env << EOF
# Firebase Test Lab Configuration
# Source this file before running tests: source .firebase_test_lab.env

export FIREBASE_PROJECT_ID=$PROJECT_ID
export FIREBASE_RESULTS_BUCKET=$PROJECT_ID.appspot.com
EOF

echo -e "${GREEN}✅ Configuration saved to .firebase_test_lab.env${NC}"
echo ""
echo "To use this configuration, run:"
echo "  source .firebase_test_lab.env"
echo ""

# Step 7: Test connection
echo -e "${BLUE}Step 7: Testing connection...${NC}"
gcloud firebase test android models list --limit=5
echo ""
echo -e "${GREEN}✅ Setup complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Source the config: source .firebase_test_lab.env"
echo "  2. Run tests: ./scripts/build_and_test_firebase.sh"
echo ""


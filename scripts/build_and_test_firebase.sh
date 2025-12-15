#!/bin/bash

# 🔥 Firebase Test Lab - Build and Test Script
# 
# This script:
# 1. Builds the app APK
# 2. Builds the test APK
# 3. Uploads to Firebase Test Lab
# 4. Runs tests on multiple devices
# 5. Shows results URL

set -e  # Exit on error

echo "🚀 Starting Firebase Test Lab Build and Test..."
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
# Get project ID from gcloud config if not set
if [ -z "$FIREBASE_PROJECT_ID" ]; then
    PROJECT_ID=$(gcloud config get-value project 2>/dev/null || echo "your-firebase-project-id")
else
    PROJECT_ID="$FIREBASE_PROJECT_ID"
fi

# Use a custom bucket name instead of .appspot.com (which requires Firebase Console creation)
RESULTS_BUCKET="${FIREBASE_RESULTS_BUCKET:-${PROJECT_ID}-test-lab-results}"
TEST_TARGET="integration_test/all_popups_test.dart"

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}❌ gcloud CLI not found. Please install it:${NC}"
    echo "   brew install google-cloud-sdk"
    exit 1
fi

# Check if Firebase project is set
if [ "$PROJECT_ID" == "your-firebase-project-id" ]; then
    echo -e "${YELLOW}⚠️  FIREBASE_PROJECT_ID not set.${NC}"
    echo "   Set it with: export FIREBASE_PROJECT_ID=your-project-id"
    echo "   Or edit this script to set PROJECT_ID"
    exit 1
fi

# Step 1: Clean previous builds
echo -e "${GREEN}📦 Step 1: Cleaning previous builds...${NC}"
flutter clean
flutter pub get

# Step 2: Build app APK
echo ""
echo -e "${GREEN}📦 Step 2: Building app APK (release)...${NC}"
flutter build apk --release

if [ ! -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    echo -e "${RED}❌ Failed to build app APK${NC}"
    exit 1
fi

echo -e "${GREEN}✅ App APK built successfully${NC}"

# Step 3: Build test APK (instrumentation test)
echo ""
echo -e "${GREEN}📦 Step 3: Building test APK (instrumentation test)...${NC}"
echo "   Building Flutter integration test as instrumentation test APK for Firebase Test Lab"
echo ""

# For Firebase Test Lab, Flutter integration tests need to be built using Gradle.
# First build the instrumentation test APK, then build the debug APK with test target.
cd android

echo "   Step 3a: Building instrumentation test APK..."
./gradlew app:assembleAndroidTest

echo "   Step 3b: Building integration test with target..."
# This creates a debug APK with the integration test code embedded
./gradlew app:assembleDebug -Ptarget=$TEST_TARGET

cd ..

# Check for the instrumentation test APK
TEST_APK=""
if [ -f "build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk" ]; then
    TEST_APK="build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk"
    echo -e "${GREEN}✅ Found instrumentation test APK: $TEST_APK${NC}"
elif [ -f "build/app/outputs/flutter-apk/app-debug-androidTest.apk" ]; then
    TEST_APK="build/app/outputs/flutter-apk/app-debug-androidTest.apk"
    echo -e "${GREEN}✅ Found instrumentation test APK: $TEST_APK${NC}"
else
    echo -e "${RED}❌ Error: Instrumentation test APK not found${NC}"
    echo ""
    echo "   Searching for APK files..."
    find build -name "*.apk" -type f 2>/dev/null | head -10
    echo ""
    echo "   The Gradle build should create:"
    echo "   build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk"
    exit 1
fi

echo -e "${GREEN}✅ Test APK built successfully: $TEST_APK${NC}"

# Step 4: Set Firebase project
echo ""
echo -e "${GREEN}📦 Step 4: Setting Firebase project...${NC}"
gcloud config set project $PROJECT_ID

# Step 5: Check billing
echo ""
echo -e "${BLUE}📋 Step 5: Checking billing status...${NC}"
BILLING_ENABLED=$(gcloud billing projects describe $PROJECT_ID --format="value(billingEnabled)" 2>/dev/null || echo "false")
# Convert to lowercase for comparison (gcloud returns "True" with capital T)
BILLING_ENABLED=$(echo "$BILLING_ENABLED" | tr '[:upper:]' '[:lower:]')

if [ "$BILLING_ENABLED" != "true" ]; then
    echo -e "${RED}❌ Billing is not enabled for this project${NC}"
    echo ""
    echo "Firebase Test Lab requires billing to be enabled (even for free tier)."
    echo ""
    echo "Enable billing at:"
    echo "  https://console.firebase.google.com/project/$PROJECT_ID/settings/billing"
    echo ""
    echo "Or:"
    echo "  https://console.cloud.google.com/billing?project=$PROJECT_ID"
    echo ""
    echo "Free tier: 5 tests/day - no charge!"
    echo ""
    exit 1
fi

echo -e "${GREEN}✅ Billing is enabled${NC}"

# Step 6: Run Firebase Test Lab
echo ""
echo -e "${GREEN}🔥 Step 6: Running Firebase Test Lab tests...${NC}"
echo "   This may take 10-20 minutes..."
echo ""

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULTS_DIR="popup-tests/$TIMESTAMP"

# Try to create bucket if it doesn't exist (ignore errors if it already exists)
echo "   Ensuring results bucket exists..."
gsutil mb -p $PROJECT_ID -l us-central1 gs://$RESULTS_BUCKET 2>/dev/null || echo "   Bucket may already exist or will be created automatically"

echo "   Note: Firebase Test Lab will use its default bucket (gs://$PROJECT_ID.appspot.com)"
echo "   Results will be stored in: gs://$PROJECT_ID.appspot.com/$RESULTS_DIR"
echo ""

# Run Flutter integration tests as instrumentation tests on Firebase Test Lab
echo "   Running Flutter integration tests on Firebase Test Lab..."
echo "   This will execute your integration_test/all_popups_test.dart test"
echo "   which will trigger all popups and take screenshots on different screen sizes"
echo ""

# For Flutter integration tests with Firebase Test Lab:
# - App APK: debug APK with test code embedded (built with -Ptarget)
# - Test APK: instrumentation test APK with test runner (built with assembleAndroidTest)
APP_APK_WITH_TEST_CODE="build/app/outputs/flutter-apk/app-debug.apk"

if [ ! -f "$APP_APK_WITH_TEST_CODE" ]; then
    echo -e "${RED}❌ Error: App APK with test code not found: $APP_APK_WITH_TEST_CODE${NC}"
    echo "   Expected from: ./gradlew app:assembleDebug -Ptarget=$TEST_TARGET"
    exit 1
fi

if [ -z "$TEST_APK" ]; then
    echo -e "${RED}❌ Error: Instrumentation test APK not found${NC}"
    exit 1
fi

echo "   Using correct APKs for Flutter integration tests:"
echo "   App APK (with test code): $APP_APK_WITH_TEST_CODE"
echo "   Test APK (with test runner): $TEST_APK"

# Updated device list with correct Android versions based on device support
# o1q: supports 34, b0q: supports 33, dm3q: supports 33;34, a02q: supports 31, a14xm: supports 34
gcloud firebase test android run \
  --type instrumentation \
  --app $APP_APK_WITH_TEST_CODE \
  --test $TEST_APK \
  --device model=o1q,version=34,locale=en,orientation=portrait \
  --device model=b0q,version=33,locale=en,orientation=portrait \
  --device model=dm3q,version=33,locale=en,orientation=portrait \
  --device model=a02q,version=31,locale=en,orientation=portrait \
  --device model=a14xm,version=34,locale=en,orientation=portrait \
  --results-dir=$RESULTS_DIR \
  --timeout=45m

echo ""
echo -e "${GREEN}✅ Tests completed!${NC}"
echo ""
echo "📊 View results at:"
echo "   https://console.firebase.google.com/project/$PROJECT_ID/testlab/histories"
echo ""
echo "📸 Screenshots and videos are available in the Firebase Console"
echo ""
echo "🎯 Tested on 5 Samsung devices:"
echo "   - Galaxy A02s (1600x720) - Small"
echo "   - Galaxy A14 (2400x1080) - Medium"
echo "   - Galaxy S21 (2400x1080) - Medium"
echo "   - Galaxy S22 Ultra (3088x1440) - Large"
echo "   - Galaxy S23 Ultra (3088x1440) - Large"
echo ""


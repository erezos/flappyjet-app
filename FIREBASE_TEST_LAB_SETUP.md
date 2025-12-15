# 🔥 Firebase Test Lab - Complete Setup Guide

This guide will help you set up Firebase Test Lab to test all popups on multiple devices and see screenshots.

## 🎯 What You'll Get

- ✅ Screenshots of all popups on different screen sizes
- ✅ Videos of the entire test run
- ✅ Test results on 5+ devices automatically
- ✅ No manual device setup needed

---

## 📋 Prerequisites

1. **Firebase Project** - You need a Firebase project
2. **Google Cloud Account** - Free tier available
3. **gcloud CLI** - Command line tool (we'll install it)

---

## 🚀 Quick Setup (5 Minutes)

### Step 1: Install gcloud CLI

**macOS:**
```bash
brew install google-cloud-sdk
```

**Or download from:**
https://cloud.google.com/sdk/docs/install

### Step 2: Run Setup Script

```bash
chmod +x scripts/setup_firebase_test_lab.sh
./scripts/setup_firebase_test_lab.sh
```

This will:
- Check gcloud installation
- Authenticate with Google
- List your Firebase projects
- Enable required APIs
- Create configuration file

### Step 3: Get Your Firebase Project ID

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project (or create one)
3. Copy the Project ID (e.g., `flappy-jet-pro`)

### Step 4: Set Environment Variables

```bash
export FIREBASE_PROJECT_ID=your-project-id
export FIREBASE_RESULTS_BUCKET=your-project-id.appspot.com
```

Or use the generated config file:
```bash
source .firebase_test_lab.env
```

---

## 🎬 Running Tests

### Option 1: Use the Script (Recommended)

```bash
chmod +x scripts/build_and_test_firebase.sh
./scripts/build_and_test_firebase.sh
```

This will:
1. Build the app APK
2. Build the test APK
3. Upload to Firebase Test Lab
4. Run on 5 devices
5. Show results URL

### Option 2: Manual Commands

```bash
# 1. Build app
flutter build apk --release

# 2. Build test
flutter build apk --debug --target=integration_test/all_popups_test.dart

# 3. Run on Firebase Test Lab
gcloud firebase test android run \
  --app build/app/outputs/flutter-apk/app-release.apk \
  --test build/app/outputs/flutter-apk/app-debug-androidTest.apk \
  --device model=Pixel5,version=31 \
  --device model=Pixel6,version=32 \
  --device model=GalaxyS21,version=31 \
  --results-bucket=your-project-id.appspot.com
```

---

## 📱 Test Devices

The script tests on these devices (different screen sizes):

- **Pixel 5** (1080x2340) - Medium phone
- **Pixel 6** (1080x2400) - Large phone  
- **Galaxy S21** (1080x2400) - Large phone
- **Pixel 4** (1080x2280) - Medium phone
- **Nexus Low Res** (800x1280) - Small tablet

You can add more devices by editing the script.

---

## 📊 Viewing Results

### In Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Navigate to **Test Lab > Results**
4. Click on your test run

### What You'll See

- **📸 Screenshots** - One for each popup on each device
- **🎥 Videos** - Full test run video
- **📝 Logs** - Detailed test logs
- **📈 Performance** - App performance metrics

### Screenshot Locations

Screenshots are taken automatically when:
- Each popup appears
- Before closing each popup
- At key test moments

---

## 🔧 Configuration

### Change Test Devices

Edit `scripts/build_and_test_firebase.sh`:

```bash
--device model=Pixel7,version=33 \
--device model=GalaxyS23,version=33 \
```

### Change Test Timeout

```bash
--timeout=45m  # Increase timeout for longer tests
```

### Test Specific Popups Only

Edit `integration_test/all_popups_test.dart` and comment out popups you don't want to test.

---

## 🐛 Troubleshooting

### "gcloud not found"
```bash
brew install google-cloud-sdk
# Then restart terminal
```

### "Project not found"
```bash
gcloud projects list
gcloud config set project YOUR_PROJECT_ID
```

### "Permission denied"
```bash
gcloud auth login
gcloud auth application-default login
```

### "Test APK not found"
The test APK location might vary. Check:
```bash
find build -name "*.apk" -type f
```

Then update the script with the correct path.

### "API not enabled"
```bash
gcloud services enable cloudtesting.googleapis.com
gcloud services enable toolresults.googleapis.com
```

---

## 💰 Cost

**Free Tier:**
- 5 tests per day
- Perfect for development/testing

**Paid Tier:**
- ~$0.17 per device-hour
- Unlimited tests
- Recommended for CI/CD

---

## 🎯 What Gets Tested

The test file (`integration_test/all_popups_test.dart`) tests:

1. ✅ **Daily Streak Popup** - Opens, verifies, closes
2. ✅ **Rate Us Popup** - Opens, verifies, closes
3. ✅ **Tournament Info Popup** - Opens, verifies, closes
4. ✅ **Notification Permission Popup** - Opens, verifies, closes
5. ✅ **Exit Confirmation Popup** - Opens, verifies, closes

Each popup is tested on **4 different screen sizes**:
- Small phone (320x568)
- Reference (375x667)
- Large phone (428x926)
- Tablet (768x1024)

---

## 📝 Customizing Tests

### Add More Popups

Edit `integration_test/all_popups_test.dart` and add:

```dart
await _testYourNewPopup(tester, screenSize);
```

### Change Screen Sizes

Edit the `screenSizes` array in the test file.

### Add More Devices

Edit `scripts/build_and_test_firebase.sh` and add more `--device` entries.

---

## 🚀 CI/CD Integration

A GitHub Actions workflow is included at:
`.github/workflows/firebase-test-lab-popups.yml`

To use it:
1. Add secrets to GitHub:
   - `FIREBASE_SERVICE_ACCOUNT`
   - `FIREBASE_SERVICE_ACCOUNT_KEY`
   - `FIREBASE_PROJECT_ID`

2. Push to main branch - tests run automatically!

---

## 📚 Next Steps

1. ✅ Run setup script
2. ✅ Run test script
3. ✅ View results in Firebase Console
4. ✅ Check screenshots of all popups
5. ✅ Verify responsive design on all devices

---

## 🆘 Need Help?

- [Firebase Test Lab Docs](https://firebase.google.com/docs/test-lab)
- [Flutter Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- Check test logs in Firebase Console

---

**Happy Testing! 🎉**


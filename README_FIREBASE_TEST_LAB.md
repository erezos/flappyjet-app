# 🔥 Firebase Test Lab - Quick Start

## ✅ Everything is Ready!

All files have been created. Here's what you need to do:

---

## 🚀 3-Step Setup

### Step 1: Install gcloud CLI

```bash
brew install google-cloud-sdk
```

### Step 2: Run Setup

```bash
./scripts/setup_firebase_test_lab.sh
```

This will:
- Authenticate with Google
- Let you select your Firebase project
- Enable required APIs
- Create config file

### Step 3: Run Tests

```bash
./scripts/build_and_test_firebase.sh
```

That's it! 🎉

---

## 📊 What You'll Get

After running the test, go to Firebase Console:
1. **Screenshots** - One for each popup on each device
2. **Videos** - Full test run showing all popups
3. **Logs** - Detailed test execution logs
4. **Results** - Pass/fail status for each device

---

## 📱 Tested Popups

- ✅ Daily Streak Popup
- ✅ Rate Us Popup  
- ✅ Tournament Info Popup
- ✅ Notification Permission Popup
- ✅ Exit Confirmation Popup

Each tested on **4 screen sizes** × **5 devices** = **20 screenshots per popup!**

---

## 🎯 Test Devices

- Pixel 5 (1080x2340)
- Pixel 6 (1080x2400)
- Galaxy S21 (1080x2400)
- Pixel 4 (1080x2280)
- Nexus Low Res (800x1280)

---

## 📝 Files Created

- ✅ `integration_test/all_popups_test.dart` - Main test file
- ✅ `scripts/build_and_test_firebase.sh` - Build and test script
- ✅ `scripts/setup_firebase_test_lab.sh` - Setup script
- ✅ `.github/workflows/firebase-test-lab-popups.yml` - CI/CD workflow
- ✅ `FIREBASE_TEST_LAB_SETUP.md` - Detailed setup guide

---

## 🆘 Troubleshooting

**"gcloud not found"**
```bash
brew install google-cloud-sdk
```

**"Project not found"**
```bash
gcloud projects list
export FIREBASE_PROJECT_ID=your-project-id
```

**"Permission denied"**
```bash
gcloud auth login
```

---

## 💰 Cost

- **Free:** 5 tests/day (perfect for development)
- **Paid:** ~$0.17 per device-hour (for CI/CD)

---

**Ready to test! Run `./scripts/build_and_test_firebase.sh` 🚀**


# 🚀 Quick Start - Firebase Test Lab

## ✅ Everything is Ready!

All files have been created. Just follow these 3 steps:

---

## Step 1: Install gcloud CLI

```bash
brew install google-cloud-sdk
```

---

## Step 2: Run Setup

```bash
./scripts/setup_firebase_test_lab.sh
```

This will:
- ✅ Authenticate with Google
- ✅ Let you select your Firebase project
- ✅ Enable required APIs
- ✅ Create config file

---

## Step 3: Run Tests

```bash
./scripts/build_and_test_firebase.sh
```

**That's it!** 🎉

The script will:
1. Build your app
2. Build the test
3. Upload to Firebase Test Lab
4. Run on 5 devices
5. Show you the results URL

---

## 📊 View Results

After tests complete (10-20 minutes), go to:

**Firebase Console → Test Lab → Results**

You'll see:
- 📸 **Screenshots** of all popups on all devices
- 🎥 **Videos** of the entire test run
- 📝 **Logs** with detailed information

---

## 🎯 What Gets Tested

- ✅ Daily Streak Popup
- ✅ Rate Us Popup
- ✅ Tournament Info Popup
- ✅ Notification Permission Popup
- ✅ Exit Confirmation Popup

**Each popup tested on:**
- 4 screen sizes (small, medium, large, tablet)
- 5 devices (Pixel 5, Pixel 6, Galaxy S21, etc.)
- = **20 screenshots per popup!**

---

## 💰 Cost

- **Free:** 5 tests/day (perfect for development)
- **Paid:** ~$0.17 per device-hour

---

## 🆘 Need Help?

See `FIREBASE_TEST_LAB_SETUP.md` for detailed instructions.

---

**Ready? Run `./scripts/build_and_test_firebase.sh` 🚀**


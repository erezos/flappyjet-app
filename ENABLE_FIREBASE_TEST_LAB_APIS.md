# 🔧 Enable Firebase Test Lab APIs

## The Issue

The Cloud Testing API couldn't be enabled via command line due to permissions. This is common - some APIs need to be enabled through the Firebase/Google Cloud Console.

## ✅ Solution: Enable via Firebase Console

### Option 1: Firebase Console (Easiest)

1. **Go to Firebase Console:**
   ```
   https://console.firebase.google.com/project/flappyjet-b31f9
   ```

2. **Navigate to Test Lab:**
   - Click on "Test Lab" in the left menu
   - Or go directly to: https://console.firebase.google.com/project/flappyjet-b31f9/testlab

3. **APIs will be enabled automatically** when you first use Test Lab

### Option 2: Google Cloud Console

1. **Go to API Library:**
   ```
   https://console.cloud.google.com/apis/library?project=flappyjet-b31f9
   ```

2. **Enable these APIs:**
   - Search for "Cloud Testing API" → Enable
   - Search for "Cloud Tool Results API" → Enable
   - Search for "Cloud Storage" → Enable (usually already enabled)

### Option 3: Use Firebase Test Lab Directly

Firebase Test Lab APIs are **automatically enabled** when you:
- First run a test via Firebase Console
- Or use the Firebase Console to upload a test

You don't need to enable them manually if you're using Firebase Test Lab!

---

## ✅ After APIs are Enabled

Once APIs are enabled (or if you use Firebase Console), you can run:

```bash
./scripts/build_and_test_firebase.sh
```

---

## 🎯 Quick Test

Try running a test - Firebase will enable the APIs automatically:

```bash
# Set your project
export FIREBASE_PROJECT_ID=flappyjet-b31f9

# Try to list available devices (this will trigger API enablement)
gcloud firebase test android models list --limit=5
```

If this works, APIs are enabled! If not, use Option 1 or 2 above.

---

## 📝 Note

The permission error is normal - Firebase Test Lab APIs often need to be enabled through the console the first time. Once enabled, they stay enabled for future use.


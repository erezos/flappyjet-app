# 🔥 FIREBASE VERIFICATION & SETUP INSTRUCTIONS

## ✅ GOOD NEWS: Firebase Already Set Up!

### Found:
- ✅ `google-services.json` exists at: `android/app/google-services.json`
- ✅ Project ID: `flappyjet-b31f9`
- ✅ Project Number (Sender ID): `861286493216`
- ✅ Package: `com.flappyjet.pro.flappy_jet_pro`

---

## 📋 WHAT YOU NEED TO CHECK:

### 1. Verify Cloud Messaging is Enabled

Go to: https://console.firebase.google.com/project/flappyjet-b31f9/settings/cloudmessaging

**Check:**
- [ ] "Cloud Messaging API (Legacy)" is enabled
- [ ] **OR** "Firebase Cloud Messaging API (V1)" is enabled

**If not enabled:**
1. Click the link that says "Manage API in Google Cloud Console"
2. Enable "Firebase Cloud Messaging API"

---

### 2. Get Server Key for Railway Backend

**Option A: Cloud Messaging (Legacy) - Easiest**
1. Go to: https://console.firebase.google.com/project/flappyjet-b31f9/settings/cloudmessaging
2. Scroll to "Cloud Messaging API (Legacy)"
3. Find "Server key"
4. **Copy this key** (looks like: `AAAAxxxxxxx:APA91bH...`)

**Option B: Service Account (V1 API) - More Secure**
1. Go to: https://console.firebase.google.com/project/flappyjet-b31f9/settings/serviceaccounts
2. Click "Generate new private key"
3. Download the JSON file
4. We'll use this instead of server key

**Which do you see?** Let me know and I'll configure accordingly.

---

## 🔑 ADD SERVER KEY TO RAILWAY

Once you have the server key:

1. Go to Railway dashboard: https://railway.app
2. Select `flappyjet-backend` service
3. Go to "Variables" tab
4. Add new variable:
   ```
   Name: FIREBASE_SERVER_KEY
   Value: AAAAxxxxxxx:APA91bH... (your server key)
   ```
5. Click "Add" and redeploy

**OR if using Service Account JSON:**
   ```
   Name: FIREBASE_SERVICE_ACCOUNT
   Value: (paste entire JSON content)
   ```

---

## ✅ Quick Verification Checklist:

- [ ] Firebase Console → Project: `flappyjet-b31f9` ✅
- [ ] google-services.json exists ✅
- [ ] Cloud Messaging API enabled (check above)
- [ ] Server key copied (or service account JSON downloaded)
- [ ] Server key added to Railway variables

**Once done, proceed to database migration below!**


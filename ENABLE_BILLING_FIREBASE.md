# 💳 Enable Billing for Firebase Test Lab

## The Issue

Firebase Test Lab requires billing to be enabled, even for the free tier (5 tests/day).

## ✅ Quick Fix (2 Minutes)

### Step 1: Enable Billing

1. **Go to Firebase Console:**
   ```
   https://console.firebase.google.com/project/flappyjet-b31f9/settings/billing
   ```

2. **Or Google Cloud Console:**
   ```
   https://console.cloud.google.com/billing?project=flappyjet-b31f9
   ```

3. **Link a billing account:**
   - Click "Link billing account"
   - Select or create a billing account
   - Add a payment method (credit card)

### Step 2: Verify Billing

```bash
gcloud billing projects describe flappyjet-b31f9
```

Should show: `billingEnabled: true`

### Step 3: Run Tests Again

```bash
./scripts/build_and_test_firebase.sh
```

---

## 💰 Cost Information

**Free Tier:**
- ✅ **5 tests per day** - FREE
- ✅ Perfect for development/testing
- ✅ No charge for first 5 tests each day

**Paid Tier:**
- ~$0.17 per device-hour after free tier
- Only charged if you exceed 5 tests/day

---

## 🎯 Alternative: Use Firebase Console

If you prefer not to enable billing via CLI, you can:

1. **Go to Firebase Console:**
   ```
   https://console.firebase.google.com/project/flappyjet-b31f9/testlab
   ```

2. **Upload APKs manually:**
   - Upload `build/app/outputs/flutter-apk/app-release.apk`
   - Upload `build/app/outputs/flutter-apk/app-debug.apk`
   - Select devices
   - Run tests

This will also prompt you to enable billing if needed.

---

## ✅ After Billing is Enabled

Once billing is enabled, the script will work:

```bash
./scripts/build_and_test_firebase.sh
```

The bucket will be created automatically and tests will run!

---

## 🆘 Still Having Issues?

1. **Check billing status:**
   ```bash
   gcloud billing projects describe flappyjet-b31f9
   ```

2. **Verify project:**
   ```bash
   gcloud config get-value project
   ```

3. **Check permissions:**
   - Make sure you're the project owner
   - Or have "Billing Account Administrator" role

---

**Once billing is enabled, you're all set! 🚀**


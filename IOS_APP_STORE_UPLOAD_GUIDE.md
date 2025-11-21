# 📱 iOS App Store Upload Guide - FlappyJet v2.0.6

**Date**: November 16, 2025  
**Version**: 2.0.6 (Build 56)  
**IPA Location**: `build/ios/ipa/flappy_jet_pro.ipa` (131.9MB)

---

## ✅ **BUILD COMPLETED**

- ✅ IPA file created: `build/ios/ipa/flappy_jet_pro.ipa`
- ✅ Version: 2.0.6
- ✅ Build Number: 56
- ✅ Bundle ID: com.flappyjet.pro.flappyJetPro
- ✅ Team ID: 2NH9R2WLTT

---

## 📤 **PART 1: Upload IPA to App Store Connect**

### **Method 1: Transporter App (Recommended)**

1. **Open Transporter** (should already be open)
   - If not: Open from Applications or Mac App Store

2. **Sign in with your Apple ID**
   - Use your developer account credentials

3. **Drag and drop the IPA file**
   - File: `build/ios/ipa/flappy_jet_pro.ipa`
   - Or click "+" and browse to the file

4. **Click "Deliver"**
   - Upload will take 5-15 minutes (131.9MB file)
   - Don't close Transporter until complete

5. **Wait for "Delivered" status**
   - You'll see a green checkmark when done
   - Processing in App Store Connect takes 5-10 more minutes

### **Method 2: Command Line (Alternative)**

```bash
xcrun altool --upload-app --type ios \
  --file build/ios/ipa/flappy_jet_pro.ipa \
  --apiKey YOUR_API_KEY \
  --apiIssuer YOUR_ISSUER_ID
```

---

## 🎮 **PART 2: Create New Version in App Store Connect**

1. **Go to App Store Connect**
   - URL: https://appstoreconnect.apple.com
   - Sign in with your Apple Developer account

2. **Navigate to your app**
   - Click "My Apps"
   - Select "Flappy Jet Pro"

3. **Create new version**
   - Click "+ Version or Platform" (top left)
   - Select "iOS"
   - Enter version: **2.0.6**
   - Click "Create"

4. **Wait for build to appear**
   - After upload completes (from Part 1)
   - Wait 5-10 minutes for processing
   - Refresh the page
   - Build 56 should appear under "Build" section

5. **Select the build**
   - Click on the build number (56)
   - Click "Done"

---

## 📝 **PART 3: Configure App Listing**

### **What's New in This Version** (Copy this)
```
🚀 FLAPPYJET PRO v2.0.6

🌍 NEW: EPIC STORY MODE!
50 handcrafted levels across 5 stunning zones! Battle AI rivals!

🎯 DAILY MISSIONS & ACHIEVEMENTS!
Complete challenges, unlock legendary rewards!

✨ NEW FEATURES:
🏆 Weekly tournaments - global competition
🤖 Boss battles - defeat rival pilots
🗺️ 5 unique zones - Desert, Ocean, Space, City, Arctic
💖 Heart system - strategic gameplay
🔥 Daily streak bonuses
⚡ Smoother performance

Join millions of pilots! Download NOW! ✈️🔥
```

### **Required Info**

1. **App Privacy**
   - Click "Edit" next to App Privacy
   - Confirm privacy practices match Privacy Manifest
   - Data types collected:
     - User ID ✅
     - Device ID ✅
     - Purchase History ✅
     - Product Interaction ✅
     - Advertising Data ✅
     - Performance Data ✅

2. **Export Compliance**
   - Does your app use encryption? → **NO**
   - (We use HTTPS which is exempt)

3. **Content Rights**
   - Check "I certify that I have rights to use..."
   - (For music, graphics, etc.)

4. **Advertising Identifier (IDFA)**
   - Does this app use the Advertising Identifier (IDFA)? → **YES**
   - Check these purposes:
     - ✅ Serve advertisements within the app
     - ✅ Attribute an action taken within this app to a previously served advertisement
     - ✅ Limit Ad Tracking setting in iOS

---

## 📸 **PART 4: Screenshots (If Not Already Uploaded)**

### **Required Sizes**
- **6.7" Display** (iPhone 14 Pro Max): 1290 x 2796 pixels
- **6.5" Display** (iPhone 11 Pro Max): 1242 x 2688 pixels
- **12.9" iPad Pro**: 2048 x 2732 pixels

### **Recommended Screenshots**
1. Story Mode world map
2. Gameplay (level in action)
3. Boss battle
4. Achievement screen
5. Shop/customization

---

## 🚀 **PART 5: Submit for Review**

1. **Review all sections**
   - Make sure all required fields are filled
   - Look for any red warnings

2. **Add to Review**
   - Click "Add for Review" (top right)

3. **Submit**
   - Click "Submit for Review"
   - Confirm submission

4. **Wait for Review**
   - Typical: 24-48 hours
   - You'll get email updates
   - Status: "Waiting for Review" → "In Review" → "Ready for Sale"

---

## ⚠️ **IMPORTANT NOTES**

### **Review Rejections - Common Issues**
1. **IDFA Usage**: If they ask, explain:
   - "We use AdMob for monetization"
   - "User consents via ATT prompt"
   - "Privacy Manifest included"

2. **Local Notifications**: If they ask:
   - "We use LOCAL notifications only (flutter_local_notifications)"
   - "No remote push notifications"
   - "No APNs certificate needed"

3. **Third-party Content**: If they ask:
   - "All graphics and music are original or licensed"
   - "No copyright infringement"

### **Post-Approval**
- **Phased Release**: Recommended for first iOS release
- **Monitor Crashes**: Check Xcode Organizer for crash reports
- **Watch Ratings**: Respond to reviews quickly

### **TestFlight** (Optional but Recommended)
- Before public release, test with TestFlight
- Invite internal testers
- Catch issues before public launch

---

## 📊 **Current Status**

| Task | Status | Notes |
|------|--------|-------|
| Build IPA | ✅ Done | 131.9MB |
| Upload to App Store | 🟡 In Progress | Use Transporter |
| Create Version 2.0.6 | ⏳ Next | After upload completes |
| Configure Listing | ⏳ Next | Use template above |
| Submit for Review | ⏳ Final | 24-48hr review |

---

## 🆘 **Need Help?**

- **Apple Support**: https://developer.apple.com/support/
- **App Store Review Guidelines**: https://developer.apple.com/app-store/review/guidelines/
- **Common Rejection Reasons**: https://developer.apple.com/app-store/review/rejections/

---

## 🎉 **Next Steps After Approval**

1. **Release Strategy**
   - Manual release (recommended for first iOS)
   - Or automatic release after approval

2. **Marketing**
   - Announce on social media
   - Update website
   - Send to gaming press

3. **Monitor**
   - Check App Analytics daily
   - Respond to reviews
   - Watch crash reports

---

**Good luck with your iOS launch! 🚀**


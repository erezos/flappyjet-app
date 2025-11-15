# 📱 iOS Release Working Plan - FlappyJet v2.0.6

**Plan Created**: November 15, 2025  
**Target Version**: 2.0.6+56  
**Estimated Total Time**: 6-8 hours  
**Current Status**: 🔴 Not Started

---

## 📊 PROGRESS TRACKER

| Phase | Tasks | Status | Time Estimate | Time Actual |
|-------|-------|--------|---------------|-------------|
| **Phase 1: Critical Compliance** | 5/5 | 🔴 Not Started | 2h | - |
| **Phase 2: Infrastructure Setup** | 3/3 | 🔴 Not Started | 1.5h | - |
| **Phase 3: App Store Configuration** | 4/4 | 🔴 Not Started | 2h | - |
| **Phase 4: Testing & Validation** | 3/3 | 🔴 Not Started | 1-2h | - |
| **Phase 5: Submission** | 3/3 | 🔴 Not Started | 1h | - |
| **TOTAL** | **18 tasks** | **0% Complete** | **7.5-9h** | **-** |

---

## 🎯 PHASE 1: CRITICAL COMPLIANCE (2 hours)

### ✅ Task 1.1: Implement App Tracking Transparency (ATT)
**Status**: 🔴 Not Started  
**Priority**: 🔴 CRITICAL  
**Time Estimate**: 30 minutes  
**Risk**: App Store rejection without this

#### Subtasks:
- [ ] **1.1.1** Create `lib/integrations/att_manager.dart`
  - [ ] Import `app_tracking_transparency` package
  - [ ] Create singleton `ATTManager` class
  - [ ] Implement `requestPermission()` method
  - [ ] Add analytics tracking for ATT status
  - [ ] Handle all 4 ATT states: authorized, denied, restricted, notDetermined

- [ ] **1.1.2** Integrate ATT into app initialization
  - [ ] Add ATT manager to `lib/main.dart`
  - [ ] Call ATT request BEFORE AdMob initialization
  - [ ] Add delay for iOS 14+ requirement (1 second after app launch)
  - [ ] Handle permission result in `_initializeAllSystems()`

- [ ] **1.1.3** Update AdMob initialization flow
  - [ ] Check ATT status in `InterstitialAdManager`
  - [ ] Only initialize ads if ATT is authorized or device < iOS 14
  - [ ] Add fallback for denied/restricted status

- [ ] **1.1.4** Test ATT flow
  - [ ] Test on iOS Simulator (iOS 14+)
  - [ ] Verify prompt appears correctly
  - [ ] Test "Allow" and "Don't Allow" paths
  - [ ] Verify ads work after authorization

**Deliverables**:
- ✅ `lib/integrations/att_manager.dart` created
- ✅ ATT prompt shows on first launch
- ✅ Ads only initialize after authorization

**Notes**:
- ATT must be requested BEFORE any IDFA access
- Apple recommends showing context screen before system prompt
- Status persists across app launches

---

### ✅ Task 1.2: Add SKAdNetwork IDs
**Status**: 🔴 Not Started  
**Priority**: 🔴 CRITICAL  
**Time Estimate**: 15 minutes  
**Risk**: Revenue loss from incomplete ad attribution

#### Subtasks:
- [ ] **1.2.1** Get official SKAdNetwork ID list
  - [ ] Download AdMob's official list (100+ networks)
  - [ ] Get Unity Ads SKAdNetwork IDs
  - [ ] Verify list is up-to-date for 2025

- [ ] **1.2.2** Update `ios/Runner/Info.plist`
  - [ ] Add `<key>SKAdNetworkItems</key>` section
  - [ ] Insert all SKAdNetwork IDs
  - [ ] Format correctly as array of dictionaries
  - [ ] Verify XML syntax is valid

- [ ] **1.2.3** Verify configuration
  - [ ] Run `flutter build ios` to check for errors
  - [ ] Open Xcode project and verify Info.plist shows IDs
  - [ ] Check for duplicate IDs

**Deliverables**:
- ✅ `ios/Runner/Info.plist` updated with SKAdNetwork IDs
- ✅ Build succeeds without warnings

**Resources**:
- AdMob list: https://developers.google.com/admob/ios/ios14#skadnetwork
- Unity Ads list: https://docs.unity.com/ads/ImplementingSKAdNetwork.html

---

### ✅ Task 1.3: Verify Bundle ID Consistency
**Status**: 🔴 Not Started  
**Priority**: 🔴 CRITICAL  
**Time Estimate**: 15 minutes  
**Risk**: App Store rejection if mismatched

#### Subtasks:
- [ ] **1.3.1** Check Xcode project settings
  - [ ] Open `ios/Runner.xcworkspace` in Xcode
  - [ ] Navigate to "Signing & Capabilities"
  - [ ] Verify Bundle Identifier: `com.flappyjet.pro.flappyJetPro`
  - [ ] Screenshot current value for reference

- [ ] **1.3.2** Verify Firebase configuration
  - [ ] Check `ios/Runner/GoogleService-Info.plist`
  - [ ] Confirm `BUNDLE_ID` matches: `com.flappyjet.pro.flappyJetPro`
  - [ ] Check Firebase Console project settings

- [ ] **1.3.3** Verify AdMob configuration
  - [ ] Log into AdMob dashboard
  - [ ] Check iOS app is linked to correct Bundle ID
  - [ ] Verify Interstitial ad unit is for iOS app

- [ ] **1.3.4** Check Apple Developer Portal
  - [ ] Log into developer.apple.com
  - [ ] Verify App ID exists for bundle: `com.flappyjet.pro.flappyJetPro`
  - [ ] Check provisioning profiles are valid

**Deliverables**:
- ✅ All Bundle IDs match across platforms
- ✅ Apple Developer Portal has valid App ID
- ✅ Certificates and profiles are current

**Current Bundle ID**: `com.flappyjet.pro.flappyJetPro` (from GoogleService-Info.plist)

---

### ✅ Task 1.4: Add Push Notification Entitlements
**Status**: 🔴 Not Started  
**Priority**: 🔴 CRITICAL  
**Time Estimate**: 30 minutes  
**Risk**: Daily streak reminders won't work on iOS

#### Subtasks:
- [ ] **1.4.1** Create entitlements file
  - [ ] Create `ios/Runner/Runner.entitlements`
  - [ ] Add `aps-environment` key with value `production`
  - [ ] Save as XML plist format

- [ ] **1.4.2** Link entitlements in Xcode
  - [ ] Open `ios/Runner.xcworkspace`
  - [ ] Select "Runner" target
  - [ ] Go to "Signing & Capabilities"
  - [ ] Enable "Push Notifications" capability
  - [ ] Verify entitlements file is linked

- [ ] **1.4.3** Configure APNs in Firebase
  - [ ] Log into Firebase Console
  - [ ] Navigate to Project Settings > Cloud Messaging
  - [ ] Upload APNs Authentication Key (or certificate)
  - [ ] Verify iOS APNs is enabled

- [ ] **1.4.4** Test notification permissions
  - [ ] Build and run on iOS device/simulator
  - [ ] Verify notification permission prompt appears
  - [ ] Check `LocalNotificationManager` initializes correctly

**Deliverables**:
- ✅ `ios/Runner/Runner.entitlements` created
- ✅ Push Notifications capability enabled in Xcode
- ✅ APNs configured in Firebase Console
- ✅ Notification permission prompt works

**Notes**:
- APNs certificate/key must be from Apple Developer Portal
- Test on real device (push notifications don't work in Simulator)

---

### ✅ Task 1.5: Create Privacy Manifest
**Status**: 🔴 Not Started  
**Priority**: 🔴 CRITICAL  
**Time Estimate**: 30 minutes  
**Risk**: App Store rejection for iOS 17+

#### Subtasks:
- [ ] **1.5.1** Create privacy manifest file
  - [ ] Create `ios/Runner/PrivacyInfo.xcprivacy`
  - [ ] Add `NSPrivacyTracking` = true
  - [ ] Add tracking domains (AdMob, Unity Ads, Railway backend)

- [ ] **1.5.2** Declare data collection
  - [ ] Add `NSPrivacyCollectedDataTypes` array
  - [ ] Declare: Device ID, Gameplay Data, Purchase History
  - [ ] Add data usage purposes
  - [ ] Link to privacy policy URL

- [ ] **1.5.3** Declare Required Reason APIs
  - [ ] Check if app uses UserDefaults (yes - for game state)
  - [ ] Check if app uses FileManager (yes - for SQLite)
  - [ ] Add required reason codes
  - [ ] Document reasons in manifest

- [ ] **1.5.4** Link manifest in Xcode
  - [ ] Open Xcode project
  - [ ] Add PrivacyInfo.xcprivacy to Runner target
  - [ ] Verify it appears in "Copy Bundle Resources"
  - [ ] Build and check for warnings

**Deliverables**:
- ✅ `ios/Runner/PrivacyInfo.xcprivacy` created
- ✅ All data collection declared
- ✅ Required Reason APIs documented
- ✅ No privacy-related build warnings

**Template**: Will provide standard gaming app template

---

## 🏗️ PHASE 2: INFRASTRUCTURE SETUP (1.5 hours)

### ✅ Task 2.1: Verify IAP Configuration
**Status**: 🔴 Not Started  
**Priority**: ⚠️ HIGH  
**Time Estimate**: 45 minutes  
**Risk**: Revenue loss if IAP doesn't work

#### Subtasks:
- [ ] **2.1.1** Find and verify IAPConfig
  - [ ] Search for `IAPConfig.appleSharedSecret` in codebase
  - [ ] Verify shared secret is set (not placeholder)
  - [ ] Check if value is from App Store Connect

- [ ] **2.1.2** Check App Store Connect products
  - [ ] Log into App Store Connect
  - [ ] Navigate to "In-App Purchases"
  - [ ] Verify all 15 products exist:
    - [ ] `com.flappyjet.gems.small` ($0.99)
    - [ ] `com.flappyjet.gems.medium` ($4.99)
    - [ ] `com.flappyjet.gems.large` ($9.99)
    - [ ] `com.flappyjet.gems.huge` ($19.99)
    - [ ] `com.flappyjet.gems.massive` ($49.99)
    - [ ] `com.flappyjet.hearts.refill` ($0.99)
    - [ ] `com.flappyjet.hearts.booster_1d` ($1.99)
    - [ ] `com.flappyjet.hearts.booster_7d` ($4.99)
    - [ ] `com.flappyjet.hearts.booster_30d` ($9.99)
    - [ ] `com.flappyjet.jet.neon_racer` ($2.99)
    - [ ] `com.flappyjet.jet.thunder_bolt` ($3.99)
    - [ ] `com.flappyjet.jet.shadow_strike` ($4.99)
    - [ ] `com.flappyjet.jet.solar_flare` ($5.99)
    - [ ] `com.flappyjet.bundle.starter` ($4.99)
    - [ ] `com.flappyjet.bundle.deluxe` ($9.99)

- [ ] **2.1.3** Verify product metadata
  - [ ] Check all products have correct prices
  - [ ] Verify descriptions match game
  - [ ] Check screenshots are uploaded
  - [ ] Verify products are "Ready to Submit"

- [ ] **2.1.4** Create sandbox tester accounts
  - [ ] Create 2-3 sandbox accounts in App Store Connect
  - [ ] Document credentials securely
  - [ ] Plan to test each product type

**Deliverables**:
- ✅ All 15 IAP products configured in App Store Connect
- ✅ Shared secret verified in code
- ✅ Sandbox accounts created for testing

**Notes**:
- Products must be submitted WITH app (not before)
- Sandbox testing required before production

---

### ✅ Task 2.2: Configure Signing & Certificates
**Status**: 🔴 Not Started  
**Priority**: ⚠️ HIGH  
**Time Estimate**: 30 minutes  
**Risk**: Can't build or upload without valid certificates

#### Subtasks:
- [ ] **2.2.1** Check certificate status
  - [ ] Log into Apple Developer Portal
  - [ ] Navigate to "Certificates, Identifiers & Profiles"
  - [ ] Verify iOS Distribution certificate exists and is valid
  - [ ] Check expiration date (must be > 6 months)

- [ ] **2.2.2** Verify provisioning profiles
  - [ ] Check "iOS Distribution" profile exists for app
  - [ ] Verify it includes correct App ID
  - [ ] Verify it includes Push Notifications entitlement
  - [ ] Download and install latest profile

- [ ] **2.2.3** Configure Xcode signing
  - [ ] Open `ios/Runner.xcworkspace`
  - [ ] Select "Runner" target
  - [ ] Go to "Signing & Capabilities"
  - [ ] Set "Team" to your Apple Developer account
  - [ ] Enable "Automatically manage signing"
  - [ ] Select "Release" configuration
  - [ ] Verify signing certificate is valid

- [ ] **2.2.4** Test archive build
  - [ ] Product > Archive in Xcode
  - [ ] Verify build succeeds
  - [ ] Check archive in Organizer
  - [ ] Don't upload yet (just test)

**Deliverables**:
- ✅ Valid iOS Distribution certificate
- ✅ Valid provisioning profile with Push Notifications
- ✅ Xcode signing configured
- ✅ Test archive builds successfully

**Notes**:
- Certificate must be on development machine
- May need to download from different Mac

---

### ✅ Task 2.3: Update Build Configuration
**Status**: 🔴 Not Started  
**Priority**: ⚠️ HIGH  
**Time Estimate**: 15 minutes  
**Risk**: Build warnings or issues

#### Subtasks:
- [ ] **2.3.1** Check deployment target
  - [ ] Open `ios/Podfile`
  - [ ] Verify: `platform :ios, '15.0'` ✅ (already set)
  - [ ] Open Xcode > Runner target
  - [ ] Verify "iOS Deployment Target" = 15.0
  - [ ] Check all pods have compatible targets

- [ ] **2.3.2** Update build settings
  - [ ] Set "Enable Bitcode" = NO (deprecated)
  - [ ] Set "Validate Workspace" = YES
  - [ ] Check "Other Linker Flags" includes Firebase
  - [ ] Verify "Swift Language Version" is set

- [ ] **2.3.3** Run pod install
  - [ ] `cd ios && pod install`
  - [ ] Verify Unity Ads mediation pod installs
  - [ ] Check for deprecation warnings
  - [ ] Update any outdated pods if needed

- [ ] **2.3.4** Verify build modes
  - [ ] Test Debug build on simulator
  - [ ] Test Release build on device
  - [ ] Check app size (should be < 200 MB)
  - [ ] Verify no missing architectures

**Deliverables**:
- ✅ Build settings optimized
- ✅ Pods updated and installed
- ✅ Debug and Release builds work
- ✅ App size within limits

---

## 🎨 PHASE 3: APP STORE CONFIGURATION (2 hours)

### ✅ Task 3.1: Create App Store Screenshots
**Status**: 🔴 Not Started  
**Priority**: ⚠️ HIGH  
**Time Estimate**: 1 hour  
**Risk**: Poor conversion if screenshots are outdated

#### Subtasks:
- [ ] **3.1.1** Plan screenshot strategy
  - [ ] Decide on 6-10 key screens to showcase
  - [ ] Prioritize NEW features: Story Mode, Bosses, Zones
  - [ ] Create shot list with captions

- [ ] **3.1.2** Capture iPhone screenshots (6.7" - iPhone 15 Pro Max)
  - [ ] Screenshot 1: World Map with 5 zones
  - [ ] Screenshot 2: Boss Battle in action
  - [ ] Screenshot 3: Story Mode level playing
  - [ ] Screenshot 4: Daily Missions screen
  - [ ] Screenshot 5: Tournament leaderboard
  - [ ] Screenshot 6: Daily Streak bonus collection
  - [ ] Screenshot 7: Jet customization
  - [ ] Screenshot 8: Achievements screen

- [ ] **3.1.3** Capture iPhone screenshots (6.5" - iPhone 11 Pro Max)
  - [ ] Same 8 screenshots as 6.7"
  - [ ] Resize if needed

- [ ] **3.1.4** Capture iPhone screenshots (5.5" - iPhone 8 Plus)
  - [ ] Same 8 screenshots
  - [ ] Ensure UI is readable at smaller size

- [ ] **3.1.5** Capture iPad Pro screenshots (12.9")
  - [ ] At least 3 iPad-optimized screenshots
  - [ ] Show landscape mode if supported

- [ ] **3.1.6** Add promotional overlays (optional)
  - [ ] Use design tool to add text overlays
  - [ ] Highlight features: "50 LEVELS!", "BOSS BATTLES!", etc.
  - [ ] Keep branding consistent

**Deliverables**:
- ✅ 8 screenshots per iPhone size (24 total)
- ✅ 3 screenshots for iPad Pro
- ✅ Screenshots saved in correct resolution/format

**Tools**:
- Use Xcode Simulator + `xcrun simctl io booted screenshot`
- Or use physical devices + Xcode Devices window

---

### ✅ Task 3.2: Update App Store Metadata
**Status**: 🔴 Not Started  
**Priority**: ⚠️ HIGH  
**Time Estimate**: 30 minutes  
**Risk**: Users won't understand what's new

#### Subtasks:
- [ ] **3.2.1** Update app description
  - [ ] Use `RELEASE_NOTES_v1.4.2.md` as base
  - [ ] Expand to full App Store description (4000 char limit)
  - [ ] Emphasize Story Mode, Bosses, Zones
  - [ ] Include: 50 levels, 5 zones, boss battles, daily missions, tournaments
  - [ ] Add call-to-action: "Download FREE now!"

- [ ] **3.2.2** Update promotional text (170 chars)
  - [ ] "🚀 NEW: Epic Story Mode with 50 levels! Battle AI bosses, explore 5 zones, complete daily missions, and compete in global tournaments! Download now!"

- [ ] **3.2.3** Update "What's New" section
  - [ ] Copy from `RELEASE_NOTES_v1.4.2.md` (English version)
  - [ ] Keep under 4000 characters
  - [ ] Format with emojis for readability

- [ ] **3.2.4** Update keywords (100 chars)
  - [ ] Current keywords + new terms
  - [ ] Add: story mode, boss battle, tournament, missions
  - [ ] Optimize for ASO (App Store Optimization)

- [ ] **3.2.5** Update support URL and privacy policy
  - [ ] Verify support URL is active
  - [ ] Verify privacy policy URL is up-to-date
  - [ ] Check privacy policy covers new features

**Deliverables**:
- ✅ App description updated and compelling
- ✅ Promotional text highlights v2.0.6 features
- ✅ Keywords optimized for discovery
- ✅ All URLs verified and working

---

### ✅ Task 3.3: Configure App Information
**Status**: 🔴 Not Started  
**Priority**: ⚠️ HIGH  
**Time Estimate**: 15 minutes  
**Risk**: Metadata issues can delay review

#### Subtasks:
- [ ] **3.3.1** Set content rating
  - [ ] Complete Apple's content questionnaire
  - [ ] Expected rating: 9+ (Infrequent/Mild Cartoon Violence)
  - [ ] Verify rating is appropriate for gameplay

- [ ] **3.3.2** Configure Game Center
  - [ ] Verify Game Center is enabled in App Store Connect
  - [ ] Check leaderboard IDs match code
  - [ ] Verify achievements are configured

- [ ] **3.3.3** Set pricing and availability
  - [ ] Price: FREE (with IAPs)
  - [ ] Availability: All territories
  - [ ] Verify IAP pricing tiers for each region

- [ ] **3.3.4** Configure App Store badges
  - [ ] Check if eligible for "Editor's Choice" nomination
  - [ ] Verify game shows in "Games" category
  - [ ] Add relevant tags: Action, Arcade

**Deliverables**:
- ✅ Content rating: 9+
- ✅ Game Center configured
- ✅ Pricing set (FREE)
- ✅ Available in all territories

---

### ✅ Task 3.4: Prepare App Preview Video (Optional)
**Status**: 🔴 Not Started  
**Priority**: 📋 MEDIUM  
**Time Estimate**: 15 minutes (or skip)  
**Risk**: None (optional)

#### Subtasks:
- [ ] **3.4.1** Record gameplay video
  - [ ] Use Screen Recording on iOS device
  - [ ] Capture 15-30 seconds of exciting gameplay
  - [ ] Show Story Mode, Boss Battle, and Endless Mode

- [ ] **3.4.2** Edit video
  - [ ] Trim to 15-30 seconds
  - [ ] Add background music (use game music)
  - [ ] Ensure no copyrighted content

- [ ] **3.4.3** Export and upload
  - [ ] Export as .mp4 or .mov
  - [ ] Upload to App Store Connect
  - [ ] Preview on different devices

**Deliverables**:
- ✅ App Preview video (15-30 sec)
- ✅ Video uploaded to App Store Connect

**Note**: Can skip this and do later. Screenshots are more important.

---

## 🧪 PHASE 4: TESTING & VALIDATION (1-2 hours)

### ✅ Task 4.1: TestFlight Build Upload
**Status**: 🔴 Not Started  
**Priority**: 🔴 CRITICAL  
**Time Estimate**: 30 minutes  
**Risk**: Can't test without TestFlight build

#### Subtasks:
- [ ] **4.1.1** Prepare for upload
  - [ ] Increment build number to 57 in `pubspec.yaml`
  - [ ] Run `flutter build ios --release`
  - [ ] Verify build succeeds with no errors

- [ ] **4.1.2** Archive in Xcode
  - [ ] Open `ios/Runner.xcworkspace`
  - [ ] Product > Archive
  - [ ] Wait for archive to complete
  - [ ] Open Organizer when done

- [ ] **4.1.3** Upload to App Store Connect
  - [ ] Click "Distribute App"
  - [ ] Select "App Store Connect"
  - [ ] Choose "Upload" (not Submit for Review)
  - [ ] Wait for upload (can take 5-15 minutes)
  - [ ] Check for errors/warnings

- [ ] **4.1.4** Configure TestFlight
  - [ ] Log into App Store Connect
  - [ ] Navigate to TestFlight tab
  - [ ] Wait for build to process (can take 10-30 min)
  - [ ] Add build to "Internal Testing" group
  - [ ] Add external testers (optional)

**Deliverables**:
- ✅ Build uploaded to TestFlight
- ✅ Build processing complete
- ✅ Build available for testing

**Notes**:
- Apple scans builds for malware (can take 30 min)
- Export compliance: Select "No" for encryption (games exempt)

---

### ✅ Task 4.2: Device Testing
**Status**: 🔴 Not Started  
**Priority**: 🔴 CRITICAL  
**Time Estimate**: 45 minutes  
**Risk**: Critical bugs may exist on real devices

#### Subtasks:
- [ ] **4.2.1** Install TestFlight build
  - [ ] Install TestFlight app on iOS device
  - [ ] Accept TestFlight invitation
  - [ ] Download FlappyJet build
  - [ ] Launch app

- [ ] **4.2.2** Test critical features
  - [ ] ✅ App launches successfully
  - [ ] ✅ ATT prompt appears (first launch)
  - [ ] ✅ Tutorial/onboarding works
  - [ ] ✅ Endless Mode gameplay smooth
  - [ ] ✅ Story Mode gameplay smooth
  - [ ] ✅ World Map navigation works
  - [ ] ✅ Boss battles work correctly
  - [ ] ✅ Daily Missions track progress
  - [ ] ✅ Achievements unlock properly
  - [ ] ✅ Daily Streak can be claimed
  - [ ] ✅ Tournaments display correctly

- [ ] **4.2.3** Test monetization
  - [ ] ✅ Interstitial ads show after wins
  - [ ] ✅ Rewarded ads work for continues
  - [ ] ✅ IAP store opens correctly
  - [ ] ✅ Test sandbox purchase (gems)
  - [ ] ✅ Purchase completes and coins/gems added
  - [ ] ✅ Test "Restore Purchases"

- [ ] **4.2.4** Test push notifications
  - [ ] ✅ Notification permission prompt works
  - [ ] ✅ Grant notification permission
  - [ ] ✅ Send test notification from Firebase Console
  - [ ] ✅ Notification received on device
  - [ ] ✅ Tapping notification opens app

- [ ] **4.2.5** Test edge cases
  - [ ] ✅ Kill app mid-game and relaunch (state persists)
  - [ ] ✅ Turn on Airplane Mode (offline mode works)
  - [ ] ✅ Low battery warning doesn't crash app
  - [ ] ✅ Background app and resume
  - [ ] ✅ Rotate device (portrait lock works)

**Deliverables**:
- ✅ All critical features tested and working
- ✅ No P0/P1 bugs found
- ✅ IAP tested in sandbox mode
- ✅ Push notifications working

**Test Devices** (if possible):
- iPhone 15 Pro (iOS 18)
- iPhone 12 (iOS 16)
- iPad Pro (iOS 17)

---

### ✅ Task 4.3: Performance & Crash Testing
**Status**: 🔴 Not Started  
**Priority**: ⚠️ HIGH  
**Time Estimate**: 15 minutes  
**Risk**: Performance issues can lead to bad reviews

#### Subtasks:
- [ ] **4.3.1** Monitor performance
  - [ ] Play 10+ Story Mode levels
  - [ ] Check frame rate (should be 60 FPS)
  - [ ] Monitor battery drain
  - [ ] Check device temperature

- [ ] **4.3.2** Stress test
  - [ ] Play for 30+ minutes continuously
  - [ ] Switch between modes rapidly
  - [ ] Open/close menus repeatedly
  - [ ] Check for memory leaks

- [ ] **4.3.3** Check Firebase Crashlytics
  - [ ] Log into Firebase Console
  - [ ] Check "Crashlytics" tab
  - [ ] Verify test crashes are recorded
  - [ ] Check for any unexpected crashes

- [ ] **4.3.4** Check analytics
  - [ ] Verify events are being tracked
  - [ ] Check Railway backend logs
  - [ ] Verify tournament scores sync
  - [ ] Check Event Bus is sending events

**Deliverables**:
- ✅ No performance issues found
- ✅ No crashes during testing
- ✅ Crashlytics working
- ✅ Analytics tracking correctly

---

## 🚀 PHASE 5: SUBMISSION (1 hour)

### ✅ Task 5.1: Pre-Submission Checklist
**Status**: 🔴 Not Started  
**Priority**: 🔴 CRITICAL  
**Time Estimate**: 15 minutes  
**Risk**: Missing items can delay review

#### Subtasks:
- [ ] **5.1.1** Review App Store Connect readiness
  - [ ] ✅ Screenshots uploaded (all sizes)
  - [ ] ✅ App description complete
  - [ ] ✅ "What's New" text added
  - [ ] ✅ Keywords set
  - [ ] ✅ Support URL working
  - [ ] ✅ Privacy Policy URL working
  - [ ] ✅ Content rating set
  - [ ] ✅ Pricing configured
  - [ ] ✅ All territories selected

- [ ] **5.1.2** Review build readiness
  - [ ] ✅ TestFlight build tested thoroughly
  - [ ] ✅ No critical bugs
  - [ ] ✅ IAP tested in sandbox
  - [ ] ✅ Ads working correctly
  - [ ] ✅ Push notifications working
  - [ ] ✅ All features functional

- [ ] **5.1.3** Review compliance checklist
  - [ ] ✅ ATT implemented
  - [ ] ✅ SKAdNetwork IDs added
  - [ ] ✅ Privacy Manifest included
  - [ ] ✅ Bundle ID consistent
  - [ ] ✅ Push Notifications entitled
  - [ ] ✅ Signing certificates valid

- [ ] **5.1.4** Review export compliance
  - [ ] ✅ App doesn't use encryption (select "No")
  - [ ] ✅ OR select encryption exemption reason
  - [ ] ✅ Document reasoning if needed

**Deliverables**:
- ✅ All checklist items verified
- ✅ Ready to submit for review

---

### ✅ Task 5.2: Submit for App Review
**Status**: 🔴 Not Started  
**Priority**: 🔴 CRITICAL  
**Time Estimate**: 30 minutes  
**Risk**: Final step - can't go back easily

#### Subtasks:
- [ ] **5.2.1** Final build preparation
  - [ ] Verify correct build is selected in App Store Connect
  - [ ] Double-check version: 2.0.6 (56 or 57)
  - [ ] Review all metadata one last time

- [ ] **5.2.2** Submit for review
  - [ ] Click "Submit for Review" in App Store Connect
  - [ ] Answer export compliance questions
  - [ ] Answer advertising identifier questions (Yes - ATT implemented)
  - [ ] Review and accept Apple agreements
  - [ ] Click final "Submit" button

- [ ] **5.2.3** Monitor submission status
  - [ ] Screenshot confirmation screen
  - [ ] Note submission date/time
  - [ ] Check email for confirmation from Apple
  - [ ] Monitor status: "Waiting for Review"

- [ ] **5.2.4** Prepare for reviewer
  - [ ] Create test account for reviewer (if needed)
  - [ ] Document how to access new features
  - [ ] Prepare for potential questions

**Deliverables**:
- ✅ App submitted to App Store Review
- ✅ Status: "Waiting for Review"
- ✅ Confirmation email received

**Timeline**:
- Review typically takes 24-48 hours
- Can take up to 7 days
- Rejections typically come with actionable feedback

---

### ✅ Task 5.3: Post-Submission Monitoring
**Status**: 🔴 Not Started  
**Priority**: ⚠️ HIGH  
**Time Estimate**: 15 minutes (ongoing)  
**Risk**: Need to respond quickly to rejections

#### Subtasks:
- [ ] **5.3.1** Monitor review status
  - [ ] Check App Store Connect daily
  - [ ] Enable email notifications for status changes
  - [ ] Watch for: "In Review", "Approved", "Rejected"

- [ ] **5.3.2** Prepare for potential rejection
  - [ ] Have Xcode project ready for quick fixes
  - [ ] Keep TestFlight build for reference
  - [ ] Document any edge cases or design decisions

- [ ] **5.3.3** Plan release timing
  - [ ] If approved: Release immediately or schedule?
  - [ ] Coordinate with marketing/social media
  - [ ] Prepare announcement posts

- [ ] **5.3.4** Plan post-launch monitoring
  - [ ] Monitor Crashlytics for iOS-specific crashes
  - [ ] Watch analytics for iOS user behavior
  - [ ] Monitor App Store reviews
  - [ ] Prepare for hotfix if needed

**Deliverables**:
- ✅ Review status monitored
- ✅ Ready to respond to feedback
- ✅ Release plan documented

---

## 📋 QUICK REFERENCE CHECKLIST

Copy this section for quick status tracking:

### Pre-Flight Checklist (Before Starting)
- [ ] Have Apple Developer account credentials
- [ ] Have App Store Connect access
- [ ] Have valid signing certificate on Mac
- [ ] Have Firebase Console access
- [ ] Have AdMob dashboard access
- [ ] Have 2-3 hours of uninterrupted time

### Critical Files to Create/Modify
- [ ] `lib/integrations/att_manager.dart` (NEW)
- [ ] `ios/Runner/Info.plist` (MODIFY - add SKAdNetwork IDs)
- [ ] `ios/Runner/Runner.entitlements` (NEW)
- [ ] `ios/Runner/PrivacyInfo.xcprivacy` (NEW)
- [ ] `lib/main.dart` (MODIFY - add ATT initialization)
- [ ] `pubspec.yaml` (MODIFY - bump build number)

### External Configurations
- [ ] Apple Developer Portal: Bundle ID verified
- [ ] Apple Developer Portal: Certificates valid
- [ ] Apple Developer Portal: Provisioning profiles current
- [ ] Firebase Console: APNs configured
- [ ] AdMob: iOS app and ad units verified
- [ ] App Store Connect: All 15 IAP products created
- [ ] App Store Connect: Screenshots uploaded
- [ ] App Store Connect: Metadata complete

### Testing Devices Needed
- [ ] iPhone with iOS 15+ (physical device preferred)
- [ ] iPad (optional but recommended)
- [ ] Mac with Xcode 15+

---

## 🎯 RECOMMENDED WORKING ORDER

### Day 1 (3-4 hours):
1. **Phase 1**: Critical Compliance (2h)
   - Task 1.1: ATT
   - Task 1.2: SKAdNetwork
   - Task 1.3: Bundle ID
   - Task 1.4: Push Notifications
   - Task 1.5: Privacy Manifest

2. **Phase 2**: Infrastructure Setup (1.5h)
   - Task 2.1: IAP Verification
   - Task 2.2: Signing
   - Task 2.3: Build Config

**Break Point**: Good stopping point after Phase 2

### Day 2 (3-4 hours):
3. **Phase 3**: App Store Configuration (2h)
   - Task 3.1: Screenshots
   - Task 3.2: Metadata
   - Task 3.3: App Information

4. **Phase 4**: Testing (1-2h)
   - Task 4.1: TestFlight Upload
   - Task 4.2: Device Testing
   - Task 4.3: Performance Testing

5. **Phase 5**: Submission (1h)
   - Task 5.1: Pre-Submission Checklist
   - Task 5.2: Submit for Review
   - Task 5.3: Monitoring

---

## 🚨 BLOCKERS & DEPENDENCIES

### Potential Blockers:
1. **Apple Developer Account** - Must be active and paid
2. **Mac with Xcode** - Required for iOS builds
3. **Signing Certificate** - Must be valid and on machine
4. **IAP Products** - Must be created in App Store Connect
5. **APNs Certificate/Key** - Required for push notifications

### Dependencies:
- Phase 2 depends on Phase 1 (compliance first)
- Phase 4 depends on Phase 3 (need metadata for TestFlight)
- Phase 5 depends on Phase 4 (must test before submit)

---

## 📞 SUPPORT RESOURCES

### Apple Documentation:
- App Store Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- ATT Documentation: https://developer.apple.com/documentation/apptrackingtransparency
- SKAdNetwork: https://developer.apple.com/documentation/storekit/skadnetwork
- Privacy Manifest: https://developer.apple.com/documentation/bundleresources/privacy_manifest_files

### Firebase:
- APNs Setup: https://firebase.google.com/docs/cloud-messaging/ios/client
- Cloud Messaging: https://firebase.google.com/docs/cloud-messaging

### AdMob:
- iOS Setup: https://developers.google.com/admob/ios/quick-start
- Unity Ads Mediation: https://developers.google.com/admob/ios/mediation/unity

---

## 🎉 SUCCESS CRITERIA

### Definition of Done:
- [ ] ✅ App submitted to App Store Review
- [ ] ✅ All critical compliance items implemented
- [ ] ✅ TestFlight build tested on real device
- [ ] ✅ All features working (gameplay, IAP, ads, notifications)
- [ ] ✅ No P0/P1 bugs
- [ ] ✅ Screenshots showcase v2.0.6 features
- [ ] ✅ Status: "Waiting for Review"

### Expected Timeline:
- **Phase 1-3**: 4-6 hours (spread over 1-2 days)
- **Phase 4**: 1-2 hours (testing)
- **Phase 5**: 1 hour (submission)
- **Apple Review**: 1-3 days
- **Total**: 5-7 days from start to App Store

---

**Ready to start?** 🚀

Would you like me to begin with **Phase 1: Task 1.1 (Implement ATT)**?


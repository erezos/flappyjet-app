# 🤖 Automated Multi-Device Testing Guide

This guide covers automated testing services that can test your FlappyJet app on multiple devices automatically.

## 🎯 Overview

There are several services that can automatically test your app on multiple devices:

1. **Firebase Test Lab** (Google) - Free tier available, best for Android
2. **Google Play Console Pre-Launch Reports** - Automatic when uploading to Play Store
3. **BrowserStack** - Paid, supports both iOS and Android
4. **Sauce Labs** - Paid, supports both iOS and Android
5. **Xcode Cloud** (Apple) - For iOS testing
6. **CI/CD Integration** - GitHub Actions, GitLab CI, etc.

---

## 🔥 Firebase Test Lab (Recommended for Android)

**Best for:** Android automated testing on real devices  
**Cost:** Free tier (5 tests/day), then pay-as-you-go  
**Devices:** 100+ real Android devices

### Setup

1. **Create Firebase Project**
   ```bash
   # Install Firebase CLI
   npm install -g firebase-tools
   
   # Login
   firebase login
   
   # Initialize Firebase in your project
   firebase init
   ```

2. **Install Flutter Firebase Test Lab Plugin**
   ```bash
   flutter pub add firebase_test_lab
   ```

3. **Create Test Script**
   ```yaml
   # .github/workflows/firebase-test-lab.yml
   name: Firebase Test Lab
   
   on:
     push:
       branches: [ main ]
     pull_request:
       branches: [ main ]
   
   jobs:
     test:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v3
         - uses: subosito/flutter-action@v2
           with:
             flutter-version: '3.24.0'
         
         - name: Build APK
           run: flutter build apk --release
         
         - name: Run Firebase Test Lab
           uses: wzieba/Firebase-TestLab-Action@v1
           with:
             serviceAccountEmail: ${{ secrets.FIREBASE_SERVICE_ACCOUNT }}
             serviceAccountKey: ${{ secrets.FIREBASE_SERVICE_ACCOUNT_KEY }}
             appFile: build/app/outputs/flutter-apk/app-release.apk
             devices: |
               model=Pixel2,version=28
               model=Pixel3,version=29
               model=Pixel4,version=30
               model=Pixel5,version=31
               model=Pixel6,version=32
             resultsBucket: your-firebase-project.appspot.com
   ```

4. **Run Tests Locally**
   ```bash
   # Build APK
   flutter build apk --release
   
   # Run on Firebase Test Lab
   gcloud firebase test android run \
     --app build/app/outputs/flutter-apk/app-release.apk \
     --device model=Pixel5,version=31,locale=en,orientation=portrait \
     --device model=Pixel6,version=32,locale=en,orientation=portrait \
     --device model=NexusLowRes,version=28,locale=en,orientation=portrait
   ```

### Features
- ✅ Tests on real devices (not emulators)
- ✅ Automatic screenshots and videos
- ✅ Performance metrics
- ✅ Crash reports
- ✅ Free tier: 5 tests/day
- ✅ Supports Robo tests (automatic UI exploration)

### Pricing
- **Free Tier:** 5 tests/day
- **Paid:** ~$0.17 per device-hour

---

## 📱 Google Play Console Pre-Launch Reports

**Best for:** Automatic testing when uploading to Play Store  
**Cost:** Free  
**Devices:** Various Android devices automatically selected

### How It Works

1. **Upload to Internal/Alpha/Beta Track**
   - Go to Google Play Console
   - Navigate to **Testing > Internal testing**
   - Upload your AAB file
   - Google automatically runs tests

2. **View Pre-Launch Report**
   - Go to **Release > Pre-launch report**
   - See results across multiple devices
   - Get crash reports, screenshots, performance data

### What It Tests
- ✅ Crashes and ANRs
- ✅ Display issues
- ✅ Security vulnerabilities
- ✅ Performance issues
- ✅ Accessibility problems

### Setup
No setup required! Just upload your app to any testing track.

---

## 🌐 BrowserStack

**Best for:** Both iOS and Android, real devices  
**Cost:** Paid (starts at $29/month)  
**Devices:** 3000+ real devices

### Setup

1. **Sign Up**
   - Go to [browserstack.com](https://www.browserstack.com)
   - Create account

2. **Install BrowserStack CLI**
   ```bash
   npm install -g browserstack-cli
   ```

3. **Configure**
   ```bash
   browserstack config
   # Enter your username and access key
   ```

4. **Create Test Script**
   ```yaml
   # .github/workflows/browserstack.yml
   name: BrowserStack Tests
   
   on:
     push:
       branches: [ main ]
   
   jobs:
     test:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v3
         - uses: subosito/flutter-action@v2
         
         - name: Build APK
           run: flutter build apk --release
         
         - name: Upload to BrowserStack
           uses: browserstack/github-actions@master
           with:
             username: ${{ secrets.BROWSERSTACK_USERNAME }}
             access-key: ${{ secrets.BROWSERSTACK_ACCESS_KEY }}
             appPath: build/app/outputs/flutter-apk/app-release.apk
             deviceList: |
               [
                 {"device": "Samsung Galaxy S21", "osVersion": "11.0"},
                 {"device": "Google Pixel 5", "osVersion": "11.0"},
                 {"device": "OnePlus 9", "osVersion": "11.0"}
               ]
   ```

### Features
- ✅ Real devices (iOS and Android)
- ✅ Automated screenshots
- ✅ Video recordings
- ✅ Network throttling
- ✅ Geolocation testing
- ✅ Appium support

### Pricing
- **Automate:** $29/month (100 minutes)
- **App Automate:** $99/month (unlimited)

---

## 🧪 Sauce Labs

**Best for:** Both iOS and Android, CI/CD integration  
**Cost:** Paid (starts at $49/month)  
**Devices:** 1000+ real devices

### Setup

1. **Sign Up**
   - Go to [saucelabs.com](https://saucelabs.com)
   - Create account

2. **Install Sauce Labs CLI**
   ```bash
   npm install -g @saucelabs/cli
   ```

3. **Create Test Script**
   ```yaml
   # .github/workflows/saucelabs.yml
   name: Sauce Labs Tests
   
   on:
     push:
       branches: [ main ]
   
   jobs:
     test:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v3
         - uses: subosito/flutter-action@v2
         
         - name: Build APK
           run: flutter build apk --release
         
         - name: Run Sauce Labs Tests
           uses: saucelabs/sauce-actions-upload@v1
           with:
             username: ${{ secrets.SAUCE_USERNAME }}
             accessKey: ${{ secrets.SAUCE_ACCESS_KEY }}
             appPath: build/app/outputs/flutter-apk/app-release.apk
   ```

### Features
- ✅ Real devices (iOS and Android)
- ✅ Automated testing
- ✅ Screenshots and videos
- ✅ Performance testing
- ✅ CI/CD integration

### Pricing
- **Starter:** $49/month
- **Professional:** $149/month

---

## 🍎 Xcode Cloud (iOS Only)

**Best for:** iOS automated testing  
**Cost:** Free for open source, $14.99/month for individuals  
**Devices:** Various iOS devices

### Setup

1. **Enable Xcode Cloud**
   - Open your project in Xcode
   - Go to **Product > Cloud > Create Workflow**

2. **Configure Workflow**
   - Select devices to test on
   - Configure test schemes
   - Set up triggers

3. **Run Tests**
   - Tests run automatically on push/PR
   - View results in Xcode Cloud dashboard

### Features
- ✅ Native iOS testing
- ✅ Multiple iOS devices
- ✅ Automatic test runs
- ✅ Integration with TestFlight

---

## 🔄 CI/CD Integration

### GitHub Actions Example

```yaml
# .github/workflows/multi-device-test.yml
name: Multi-Device Testing

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test-android:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        device:
          - model: Pixel5,version=31
          - model: Pixel6,version=32
          - model: GalaxyS21,version=31
    
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      
      - name: Build APK
        run: flutter build apk --release
      
      - name: Run Firebase Test Lab
        uses: wzieba/Firebase-TestLab-Action@v1
        with:
          serviceAccountEmail: ${{ secrets.FIREBASE_SERVICE_ACCOUNT }}
          serviceAccountKey: ${{ secrets.FIREBASE_SERVICE_ACCOUNT_KEY }}
          appFile: build/app/outputs/flutter-apk/app-release.apk
          devices: ${{ matrix.device }}

  test-ios:
    runs-on: macos-latest
    strategy:
      matrix:
        device:
          - iPhone SE (3rd generation)
          - iPhone 14
          - iPhone 14 Pro Max
          - iPad Pro (12.9-inch)
    
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      
      - name: Build iOS
        run: flutter build ios --release --no-codesign
      
      - name: Run Tests on Simulator
        run: |
          xcrun simctl boot "${{ matrix.device }}"
          flutter test --device-id="${{ matrix.device }}"
```

---

## 📊 Comparison Table

| Service | Platform | Cost | Devices | Best For |
|---------|----------|------|---------|----------|
| **Firebase Test Lab** | Android | Free (5/day) | 100+ | Android testing |
| **Play Console Pre-Launch** | Android | Free | Auto-selected | Automatic testing |
| **BrowserStack** | iOS + Android | $29+/month | 3000+ | Both platforms |
| **Sauce Labs** | iOS + Android | $49+/month | 1000+ | CI/CD integration |
| **Xcode Cloud** | iOS | $14.99/month | Various | iOS native |
| **GitHub Actions** | Both | Free (public) | Simulators | CI/CD |

---

## 🚀 Recommended Setup for FlappyJet

### Option 1: Free Tier (Recommended to Start)

1. **Firebase Test Lab** for Android
   - Free 5 tests/day
   - Real devices
   - Automatic screenshots

2. **Google Play Console Pre-Launch Reports**
   - Automatic when uploading
   - No setup needed

3. **GitHub Actions** for iOS Simulators
   - Free for public repos
   - Multiple device sizes
   - Automated on push/PR

### Option 2: Paid Tier (Production)

1. **Firebase Test Lab** (Android)
   - Unlimited tests
   - Real devices
   - Performance metrics

2. **BrowserStack** or **Sauce Labs** (iOS)
   - Real iOS devices
   - Automated testing
   - Screenshots/videos

---

## 📝 Quick Start: Firebase Test Lab

1. **Install gcloud CLI**
   ```bash
   # macOS
   brew install google-cloud-sdk
   
   # Initialize
   gcloud init
   ```

2. **Authenticate**
   ```bash
   gcloud auth login
   gcloud config set project YOUR_PROJECT_ID
   ```

3. **Build APK**
   ```bash
   flutter build apk --release
   ```

4. **Run Test**
   ```bash
   gcloud firebase test android run \
     --app build/app/outputs/flutter-apk/app-release.apk \
     --type robo \
     --device model=Pixel5,version=31 \
     --device model=Pixel6,version=32 \
     --device model=GalaxyS21,version=31
   ```

5. **View Results**
   - Go to [Firebase Console](https://console.firebase.google.com)
   - Navigate to **Test Lab > Results**

---

## 🎯 Next Steps

1. **Start with Firebase Test Lab** (free tier)
2. **Set up GitHub Actions** for automated testing
3. **Upload to Play Console** to get Pre-Launch Reports
4. **Consider paid services** if you need iOS real device testing

---

## 📚 Resources

- [Firebase Test Lab Docs](https://firebase.google.com/docs/test-lab)
- [Google Play Console Pre-Launch Reports](https://support.google.com/googleplay/android-developer/answer/7002270)
- [BrowserStack Flutter Testing](https://www.browserstack.com/docs/app-automate/flutter)
- [Sauce Labs Flutter Testing](https://saucelabs.com/solutions/flutter)
- [Xcode Cloud Docs](https://developer.apple.com/xcode-cloud/)

---

**Happy Testing! 🚀**


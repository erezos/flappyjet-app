# 🔥 Firebase Test Lab with Flutter Integration Tests

## ✅ Solution: Build Flutter Integration Tests as Instrumentation Tests

Flutter integration tests **CAN** be built as instrumentation tests for Firebase Test Lab using Gradle commands.

## How It Works

When you run:
```bash
flutter build apk --debug --target=integration_test/all_popups_test.dart
```

It creates a regular debug APK (`app-debug.apk`), not an instrumentation test APK. 

**The correct approach** is to use Gradle commands:

```bash
cd android
./gradlew app:assembleAndroidTest
./gradlew app:assembleDebug -Ptarget=integration_test/all_popups_test.dart
cd ..
```

This creates `build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk` which Firebase Test Lab can use.

## Required Configuration

### 1. Android build.gradle.kts

Add to `defaultConfig`:
```kotlin
testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
```

Add to `dependencies`:
```kotlin
testImplementation("junit:junit:4.13.2")
androidTestImplementation("androidx.test:runner:1.5.2")
androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")
```

### 2. Build Commands

The script `build_and_test_firebase.sh` now:
1. Builds the app APK: `flutter build apk --release`
2. Builds instrumentation test APK: `./gradlew app:assembleAndroidTest`
3. Builds integration test: `./gradlew app:assembleDebug -Ptarget=integration_test/all_popups_test.dart`
4. Runs on Firebase Test Lab: `gcloud firebase test android run --type instrumentation`

## What This Achieves

✅ Your Flutter integration tests (`integration_test/all_popups_test.dart`) will run on Firebase Test Lab  
✅ All popups will be triggered and tested on different screen sizes  
✅ Screenshots will be captured automatically  
✅ Videos will be recorded  
✅ Tests run on multiple devices simultaneously  

## Resources

- [Flutter Integration Tests](https://docs.flutter.dev/testing/integration-tests)
- [Firebase Test Lab Documentation](https://firebase.google.com/docs/test-lab)
- [Flutter Firebase Test Lab Guide](https://firebase.google.com/docs/test-lab/flutter/integration-testing-with-flutter)


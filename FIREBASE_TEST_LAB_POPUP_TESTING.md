# 🎯 Firebase Test Lab: Testing Popups & All Components

This guide shows you how to ensure Firebase Test Lab tests see and interact with all popups and components in your FlappyJet app.

## 🎯 The Challenge

**Robo Tests** (automatic exploration) may not:
- Trigger all popups (they appear conditionally)
- Navigate to specific screens
- Wait for animations to complete
- Test conditional logic

**Solution:** Write **custom instrumentation tests** that explicitly test each popup and component.

---

## 📋 Strategy Overview

1. **Write Flutter Integration Tests** - Test popups explicitly
2. **Convert to Instrumentation Tests** - For Firebase Test Lab
3. **Create Test Scripts** - Navigate to specific screens
4. **Take Screenshots** - Verify popups appear
5. **Use Test Data** - Trigger popup conditions

---

## 🚀 Step 1: Set Up Flutter Integration Tests

### Install Dependencies

```yaml
# pubspec.yaml
dev_dependencies:
  integration_test:
    sdk: flutter
  flutter_test:
    sdk: flutter
```

### Create Integration Test Structure

```
integration_test/
  ├── popups/
  │   ├── daily_streak_popup_test.dart
  │   ├── rate_us_popup_test.dart
  │   ├── notification_permission_popup_test.dart
  │   └── tournament_popups_test.dart
  ├── screens/
  │   ├── home_screen_test.dart
  │   ├── tournament_screen_test.dart
  │   └── profile_screen_test.dart
  └── app_test.dart
```

---

## 📝 Step 2: Write Popup Tests

### Example: Daily Streak Popup Test

```dart
// integration_test/popups/daily_streak_popup_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flappy_jet_pro/main.dart' as app;
import 'package:flappy_jet_pro/game/systems/daily_streak_manager.dart';
import 'package:flappy_jet_pro/ui/widgets/daily_streak/daily_streak_integration.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Daily Streak Popup Tests', () {
    testWidgets('Daily streak popup appears and is visible', (tester) async {
      // Start app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to home screen (where streak button is)
      // Assuming you have a way to navigate to home
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find and tap the daily streak button
      final streakButton = find.byKey(const Key('daily_streak_button'));
      expect(streakButton, findsOneWidget);
      await tester.tap(streakButton);
      await tester.pumpAndSettle();

      // Wait for popup animation
      await tester.pump(const Duration(milliseconds: 500));

      // Verify popup is visible
      expect(find.byType(DailyStreakPopupStable), findsOneWidget);

      // Take screenshot for verification
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/screenshot',
        null,
        (data) {},
      );

      // Verify popup content
      expect(find.text('Daily Streak'), findsOneWidget);
      expect(find.text('Claim'), findsOneWidget);

      // Test claim button
      final claimButton = find.text('Claim');
      await tester.tap(claimButton);
      await tester.pumpAndSettle();

      // Verify popup closes
      expect(find.byType(DailyStreakPopupStable), findsNothing);
    });

    testWidgets('Daily streak popup scales correctly on different screen sizes', (tester) async {
      // Test on small screen
      tester.binding.window.physicalSizeTestValue = const Size(375, 667);
      tester.binding.window.devicePixelRatioTestValue = 2.0;
      addTearDown(() => tester.binding.window.clearPhysicalSizeTestValue());

      app.main();
      await tester.pumpAndSettle();

      // Trigger popup
      final streakButton = find.byKey(const Key('daily_streak_button'));
      await tester.tap(streakButton);
      await tester.pumpAndSettle();

      // Verify no overflow
      expect(tester.takeException(), isNull);

      // Verify popup is visible
      expect(find.byType(DailyStreakPopupStable), findsOneWidget);
    });
  });
}
```

### Example: Rate Us Popup Test

```dart
// integration_test/popups/rate_us_popup_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flappy_jet_pro/main.dart' as app;
import 'package:flappy_jet_pro/ui/widgets/rate_us_popup.dart';
import 'package:flappy_jet_pro/ui/widgets/rate_us_integration.dart';
import 'package:flappy_jet_pro/game/systems/rate_us_manager.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Rate Us Popup Tests', () {
    testWidgets('Rate us popup appears after daily streak claim', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Simulate conditions that trigger rate us popup
      // (e.g., after claiming daily streak reward)
      
      // Navigate to trigger point
      // This depends on your app's flow
      
      // Wait for popup to appear
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify popup is visible
      expect(find.byType(RateUsPopup), findsOneWidget);

      // Verify popup content
      expect(find.text('Loving FlappyJet?'), findsOneWidget);
      expect(find.text('RATE FLAPPYJET'), findsOneWidget);
      expect(find.text('MAYBE LATER'), findsOneWidget);
      expect(find.text('No Thanks'), findsOneWidget);

      // Test buttons
      final maybeLaterButton = find.text('MAYBE LATER');
      await tester.tap(maybeLaterButton);
      await tester.pumpAndSettle();

      // Verify popup closes
      expect(find.byType(RateUsPopup), findsNothing);
    });

    testWidgets('Rate us popup is responsive on different screen sizes', (tester) async {
      // Test on large screen
      tester.binding.window.physicalSizeTestValue = const Size(428, 926);
      tester.binding.window.devicePixelRatioTestValue = 3.0;
      addTearDown(() => tester.binding.window.clearPhysicalSizeTestValue());

      app.main();
      await tester.pumpAndSettle();

      // Trigger popup (your method)
      // ...

      // Verify popup appears and is properly sized
      expect(find.byType(RateUsPopup), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
```

### Example: Tournament Popup Test

```dart
// integration_test/popups/tournament_popups_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flappy_jet_pro/main.dart' as app;
import 'package:flappy_jet_pro/ui/widgets/tournament/tournament_info_popup.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Tournament Popup Tests', () {
    testWidgets('Tournament info popup appears when tournament is tapped', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to tournament hub
      // (Adjust based on your navigation)
      
      // Find tournament card
      final tournamentCard = find.byKey(const Key('tournament_card_chopper_adventures'));
      expect(tournamentCard, findsOneWidget);
      
      // Tap tournament card
      await tester.tap(tournamentCard);
      await tester.pumpAndSettle();

      // Verify popup appears
      expect(find.byType(TournamentInfoPopup), findsOneWidget);

      // Verify popup content
      expect(find.text('CHOPPER ADVENTURES'), findsOneWidget);
      
      // Test close button
      final closeButton = find.byIcon(Icons.close);
      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      // Verify popup closes
      expect(find.byType(TournamentInfoPopup), findsNothing);
    });
  });
}
```

---

## 🔧 Step 3: Create Helper Functions

```dart
// integration_test/helpers/popup_test_helpers.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

class PopupTestHelpers {
  /// Wait for popup to appear with timeout
  static Future<void> waitForPopup(
    WidgetTester tester,
    Finder popupFinder, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final endTime = DateTime.now().add(timeout);
    
    while (DateTime.now().isBefore(endTime)) {
      await tester.pump(const Duration(milliseconds: 100));
      if (popupFinder.evaluate().isNotEmpty) {
        await tester.pumpAndSettle();
        return;
      }
    }
    
    fail('Popup did not appear within ${timeout.inSeconds} seconds');
  }

  /// Take screenshot for verification
  static Future<void> takeScreenshot(
    WidgetTester tester,
    String name,
  ) async {
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/screenshot',
      null,
      (data) {
        // Screenshot data is available here
        // You can save it or send to Firebase Test Lab
      },
    );
  }

  /// Verify no overflow errors
  static void verifyNoOverflow(WidgetTester tester) {
    final exception = tester.takeException();
    if (exception != null) {
      final exceptionString = exception.toString();
      if (exceptionString.contains('overflowed') ||
          exceptionString.contains('RenderFlex')) {
        fail('Overflow error detected: $exception');
      }
    }
  }

  /// Navigate to specific screen
  static Future<void> navigateToScreen(
    WidgetTester tester,
    String screenKey,
  ) async {
    // Find navigation button/key
    final navButton = find.byKey(Key(screenKey));
    if (navButton.evaluate().isNotEmpty) {
      await tester.tap(navButton);
      await tester.pumpAndSettle();
    }
  }
}
```

---

## 🎬 Step 4: Create Comprehensive Test Suite

```dart
// integration_test/app_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flappy_jet_pro/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('FlappyJet Comprehensive Tests', () {
    testWidgets('All popups appear and function correctly', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Test 1: Daily Streak Popup
      await _testDailyStreakPopup(tester);

      // Test 2: Rate Us Popup
      await _testRateUsPopup(tester);

      // Test 3: Tournament Popups
      await _testTournamentPopups(tester);

      // Test 4: Notification Permission Popup
      await _testNotificationPermissionPopup(tester);

      // Test 5: Game Over Popups
      await _testGameOverPopups(tester);
    });

    testWidgets('All components are responsive', (tester) async {
      // Test on multiple screen sizes
      final screenSizes = [
        const Size(320, 568),  // Small phone
        const Size(375, 667),  // Reference
        const Size(428, 926),  // Large phone
        const Size(768, 1024), // Tablet
      ];

      for (final size in screenSizes) {
        tester.binding.window.physicalSizeTestValue = size;
        tester.binding.window.devicePixelRatioTestValue = 2.0;
        
        app.main();
        await tester.pumpAndSettle();

        // Verify no overflow
        expect(tester.takeException(), isNull);

        // Test key components
        // ...
      }
    });
  });
}

Future<void> _testDailyStreakPopup(WidgetTester tester) async {
  // Your test logic
}

Future<void> _testRateUsPopup(WidgetTester tester) async {
  // Your test logic
}

// ... other test functions
```

---

## 🔥 Step 5: Configure for Firebase Test Lab

### Build Instrumentation Test APK

```bash
# Build the app
flutter build apk --release

# Build the test APK
flutter build apk --debug --target=integration_test/app_test.dart
```

### Create Test Configuration

```yaml
# firebase_test_lab_config.yml
gcloud:
  project: your-firebase-project-id

test_spec:
  android:
    app: build/app/outputs/flutter-apk/app-release.apk
    test: build/app/outputs/flutter-apk/app-debug-androidTest.apk
    devices:
      - model: Pixel5
        version: 31
        locale: en
        orientation: portrait
      - model: Pixel6
        version: 32
        locale: en
        orientation: portrait
      - model: GalaxyS21
        version: 31
        locale: en
        orientation: portrait
```

### Run Tests on Firebase Test Lab

```bash
# Using gcloud CLI
gcloud firebase test android run \
  --app build/app/outputs/flutter-apk/app-release.apk \
  --test build/app/outputs/flutter-apk/app-debug-andboardTest.apk \
  --device model=Pixel5,version=31 \
  --device model=Pixel6,version=32 \
  --results-bucket=your-firebase-project.appspot.com \
  --results-dir=test-results/$(date +%Y%m%d-%H%M%S)
```

---

## 📸 Step 6: Add Screenshot Capture

### Install Screenshot Package

```yaml
# pubspec.yaml
dev_dependencies:
  screenshot: ^2.0.0
```

### Capture Screenshots in Tests

```dart
import 'package:screenshot/screenshot.dart';

testWidgets('Capture popup screenshot', (tester) async {
  final screenshotController = ScreenshotController();
  
  app.main();
  await tester.pumpAndSettle();

  // Trigger popup
  // ...

  // Capture screenshot
  await screenshotController.capture().then((image) {
    // Save or upload screenshot
    // Firebase Test Lab will also capture screenshots automatically
  });
});
```

---

## 🎯 Step 7: Use Test Data to Trigger Popups

### Create Test Data Helpers

```dart
// integration_test/helpers/test_data_helpers.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flappy_jet_pro/game/systems/rate_us_manager.dart';
import 'package:flappy_jet_pro/game/systems/daily_streak_manager.dart';

class TestDataHelpers {
  /// Set up conditions for rate us popup
  static Future<void> setupRateUsPopupConditions() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Set session count to trigger rate us
    await prefs.setInt('session_count', 5);
    await prefs.setInt('days_since_first_launch', 3);
    await prefs.setBool('has_rated', false);
    await prefs.setBool('has_declined', false);
  }

  /// Set up conditions for daily streak popup
  static Future<void> setupDailyStreakConditions() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Set streak data
    await prefs.setInt('current_streak', 3);
    await prefs.setString('last_claim_date', DateTime.now().toIso8601String());
  }

  /// Reset all test data
  static Future<void> resetTestData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
```

---

## 🚀 Step 8: GitHub Actions Workflow

```yaml
# .github/workflows/firebase-test-lab-popups.yml
name: Firebase Test Lab - Popup Tests

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test-popups:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Build app APK
        run: flutter build apk --release
      
      - name: Build test APK
        run: flutter build apk --debug --target=integration_test/app_test.dart
      
      - name: Run Firebase Test Lab
        uses: wzieba/Firebase-TestLab-Action@v1
        with:
          serviceAccountEmail: ${{ secrets.FIREBASE_SERVICE_ACCOUNT }}
          serviceAccountKey: ${{ secrets.FIREBASE_SERVICE_ACCOUNT_KEY }}
          appFile: build/app/outputs/flutter-apk/app-release.apk
          testFile: build/app/outputs/flutter-apk/app-debug-androidTest.apk
          devices: |
            model=Pixel5,version=31
            model=Pixel6,version=32
            model=GalaxyS21,version=31
          resultsBucket: your-firebase-project.appspot.com
          resultsDir: popup-tests/$(date +%Y%m%d-%H%M%S)
```

---

## 📊 Step 9: View Results

After tests run, view results in Firebase Console:

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Navigate to **Test Lab > Results**
3. Click on your test run
4. View:
   - ✅ Screenshots (verify popups appear)
   - ✅ Videos (see popup interactions)
   - ✅ Logs (debug any issues)
   - ✅ Performance metrics

---

## ✅ Checklist: Ensuring All Popups Are Tested

- [ ] Daily Streak Popup
- [ ] Rate Us Popup
- [ ] Notification Permission Popup
- [ ] Tournament Info Popup
- [ ] Tournament Game Over Popup
- [ ] Tournament Victory Popup
- [ ] Level Complete Popup
- [ ] Level Failed Popup
- [ ] Store Popups
- [ ] Settings Popups
- [ ] Error Popups
- [ ] Confirmation Dialogs

---

## 🎯 Best Practices

1. **Use Explicit Waits** - Don't rely on `pumpAndSettle()` alone
2. **Take Screenshots** - Verify popups visually
3. **Test Multiple Screen Sizes** - Ensure responsiveness
4. **Use Test Data** - Trigger popup conditions
5. **Test All Interactions** - Buttons, close, dismiss
6. **Verify No Overflow** - Check for layout errors
7. **Test Animations** - Wait for animations to complete

---

## 🐛 Troubleshooting

### Popups Don't Appear
- Check popup conditions (session count, streak, etc.)
- Use test data helpers to set conditions
- Add explicit waits

### Tests Timeout
- Increase timeout duration
- Add more `pumpAndSettle()` calls
- Check for infinite animations

### Screenshots Not Captured
- Use Firebase Test Lab's automatic screenshots
- Or use `screenshot` package
- Check Firebase Console for results

---

## 📚 Resources

- [Flutter Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- [Firebase Test Lab Instrumentation Tests](https://firebase.google.com/docs/test-lab/android/instrumentation-test)
- [Flutter Driver](https://docs.flutter.dev/testing/integration-tests#flutter-driver)

---

**Now your Firebase Test Lab tests will see and test all popups! 🎉**


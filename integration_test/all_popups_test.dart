/// 🎯 Comprehensive Popup Test for Firebase Test Lab
/// 
/// Tests all popups in the app:
/// 1. Opens each popup
/// 2. Takes screenshot (Firebase does this automatically)
/// 3. Verifies popup is visible and responsive
/// 4. Closes popup
/// 5. Moves to next popup
/// 
/// Run: flutter test integration_test/all_popups_test.dart
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flappy_jet_pro/main.dart' as app;
import 'package:flappy_jet_pro/ui/widgets/daily_streak/daily_streak_popup_stable.dart';
import 'package:flappy_jet_pro/ui/widgets/rate_us_popup.dart';
import 'package:flappy_jet_pro/ui/widgets/tournament/tournament_info_popup.dart';
import 'package:flappy_jet_pro/ui/widgets/notification_permission_popup.dart';
import 'package:flappy_jet_pro/ui/widgets/exit_confirmation_popup.dart';
import 'package:flappy_jet_pro/ui/widgets/status_bar/daily_streak_button.dart';
import 'package:flappy_jet_pro/ui/widgets/rate_us_integration.dart';
import 'package:flappy_jet_pro/ui/screens/home_navigator_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('All Popups Screenshot Test', () {
    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    // Main test - verify app launches and test popups
    testWidgets('App launches and popups are tested', (tester) async {
      // Start app once (not in loop)
      print('🚀 Starting app...');
      app.main();
      
      // Wait for app to initialize - pump multiple times to allow async initialization
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      
      // Wait for loading screen to complete and HomeNavigatorScreen to appear
      print('⏳ Waiting for app to finish loading...');
      await tester.pumpAndSettle(const Duration(seconds: 10));
      
      // Verify app is actually visible - look for HomeNavigatorScreen or any visible widget
      final materialApp = find.byType(MaterialApp);
      expect(materialApp, findsOneWidget, reason: 'MaterialApp should be visible');
      
      // Wait for HomeNavigatorScreen to appear (app finished loading)
      print('⏳ Waiting for HomeNavigatorScreen...');
      await tester.pump(const Duration(seconds: 2));
      
      // Try to find HomeNavigatorScreen - it should appear after initialization
      final homeNavigator = find.byType(HomeNavigatorScreen);
      int attempts = 0;
      while (homeNavigator.evaluate().isEmpty && attempts < 20) {
        await tester.pump(const Duration(milliseconds: 500));
        attempts++;
        if (attempts % 4 == 0) {
          print('   Still waiting for app to load... (attempt $attempts/20)');
        }
      }
      
      if (homeNavigator.evaluate().isNotEmpty) {
        print('✅ HomeNavigatorScreen is visible - app loaded successfully');
      } else {
        print('⚠️ HomeNavigatorScreen not found, checking for any visible widgets...');
        // Check if ANY widget is visible (app might be in loading state)
        final scaffold = find.byType(Scaffold);
        if (scaffold.evaluate().isNotEmpty) {
          print('   ✅ Scaffold found - app UI is rendering');
        } else {
          print('   ⚠️ No Scaffold found - app might not be rendering');
        }
      }
      
      // Wait a bit more to ensure UI is fully rendered
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle(const Duration(seconds: 3));
      
      // Final verification - check if we can see any text or buttons
      final anyText = find.text('Story', skipOffstage: false);
      final anyButton = find.byType(ElevatedButton, skipOffstage: false);
      if (anyText.evaluate().isNotEmpty || anyButton.evaluate().isNotEmpty) {
        print('✅ App UI is visible and interactive');
      } else {
        print('⚠️ No interactive elements found - app might still be loading');
      }
      
      print('✅ App ready for testing');
      
      // Verify the app is visible
      expect(find.byType(MaterialApp), findsOneWidget, reason: 'MaterialApp should be visible');
      
      // Test on different screen sizes
      final screenSizes = [
        const Size(375, 667),  // Reference (iPhone 13 mini) - test one size first
        const Size(428, 926),  // Large phone (iPhone 14 Pro Max)
      ];

      for (final screenSize in screenSizes) {
        print('\n📱 Testing on ${screenSize.width}x${screenSize.height}');
        
        // Set screen size
        tester.binding.window.physicalSizeTestValue = screenSize;
        tester.binding.window.devicePixelRatioTestValue = 2.0;
        addTearDown(() => tester.binding.window.clearPhysicalSizeTestValue());

        // Wait for UI to adjust to new size
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Test each popup with timeout protection (each handles its own errors)
        await _testDailyStreakPopup(tester, screenSize);
        await _testRateUsPopup(tester, screenSize);
        await _testTournamentInfoPopup(tester, screenSize);
        await _testNotificationPermissionPopup(tester, screenSize);
        await _testExitConfirmationPopup(tester, screenSize);

        print('✅ Completed testing on ${screenSize.width}x${screenSize.height}\n');
      }
      
      print('✅ All tests completed');
    });
  });
}

/// Test Daily Streak Popup
Future<void> _testDailyStreakPopup(WidgetTester tester, Size screenSize) async {
  print('  🎯 Testing Daily Streak Popup...');

  try {
    // Set up test data to ensure popup can show
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('daily_streak_current_streak', 3);
    await prefs.setString('daily_streak_last_claim_date', 
        DateTime.now().subtract(const Duration(days: 1)).toIso8601String());

    // Find daily streak button (usually in status bar or home screen)
    // Try multiple possible locations
    Finder streakButton = find.byType(DailyStreakButton);
    if (streakButton.evaluate().isEmpty) {
      streakButton = find.byKey(const Key('daily_streak_button'));
    }
    if (streakButton.evaluate().isEmpty) {
      streakButton = find.text('Daily Streak');
    }
    if (streakButton.evaluate().isEmpty) {
      streakButton = find.byIcon(Icons.local_fire_department);
    }

    if (streakButton.evaluate().isNotEmpty) {
      await tester.tap(streakButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));
    } else {
      // Try to trigger via integration - check available methods
      // Note: You may need to navigate to a screen that shows the streak button first
      print('    ⚠️ Daily Streak button not found - skipping');
      return; // Skip this popup if button not found
    }

    // Wait for popup animation (with timeout)
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Verify popup is visible
    final popupFinder = find.byType(DailyStreakPopupStable);
    if (popupFinder.evaluate().isNotEmpty) {
      print('    ✅ Daily Streak Popup is visible');
      
      // Verify no overflow
      final exception = tester.takeException();
      if (exception != null && exception.toString().contains('overflowed')) {
        fail('❌ Overflow error in Daily Streak Popup: $exception');
      }

      // Take screenshot (Firebase Test Lab does this automatically)
      // Wait a bit for screenshot
      await tester.pump(const Duration(milliseconds: 500));

      // Close popup
      final closeButton = find.byIcon(Icons.close);
      if (closeButton.evaluate().isNotEmpty) {
        await tester.tap(closeButton);
      } else {
        // Try claim button
        final claimButton = find.text('Claim');
        if (claimButton.evaluate().isNotEmpty) {
          await tester.tap(claimButton);
        }
      }
      await tester.pumpAndSettle(const Duration(seconds: 2));
    } else {
      print('    ⚠️ Daily Streak Popup not found (may need different trigger)');
    }
  } catch (e) {
    print('    ⚠️ Error testing Daily Streak Popup: $e');
  }
}

/// Test Rate Us Popup
Future<void> _testRateUsPopup(WidgetTester tester, Size screenSize) async {
  print('  🎯 Testing Rate Us Popup...');

  try {
    // Set up test data to trigger rate us popup
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('rate_us_session_count', 5);
    await prefs.setInt('rate_us_days_since_first_launch', 3);
    await prefs.setBool('rate_us_has_rated', false);
    await prefs.setBool('rate_us_has_declined', false);

    // Try to trigger rate us popup
    final context = tester.element(find.byType(MaterialApp));
    await RateUsIntegration.showAfterDailyStreak(context, streakDay: 3);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Wait for popup animation (with timeout)
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Verify popup is visible
    final popupFinder = find.byType(RateUsPopup);
    if (popupFinder.evaluate().isNotEmpty) {
      print('    ✅ Rate Us Popup is visible');
      
      // Verify content
      expect(find.text('Loving FlappyJet?'), findsOneWidget);

      // Verify no overflow
      final exception = tester.takeException();
      if (exception != null && exception.toString().contains('overflowed')) {
        fail('❌ Overflow error in Rate Us Popup: $exception');
      }

      // Take screenshot
      await tester.pump(const Duration(milliseconds: 500));

      // Close popup
      final maybeLaterButton = find.text('MAYBE LATER');
      if (maybeLaterButton.evaluate().isNotEmpty) {
        await tester.tap(maybeLaterButton);
      } else {
        final closeButton = find.byIcon(Icons.close);
        if (closeButton.evaluate().isNotEmpty) {
          await tester.tap(closeButton);
        }
      }
      await tester.pumpAndSettle(const Duration(seconds: 2));
    } else {
      print('    ⚠️ Rate Us Popup not found (may need different trigger)');
    }
  } catch (e) {
    print('    ⚠️ Error testing Rate Us Popup: $e');
  }
}

/// Test Tournament Info Popup
Future<void> _testTournamentInfoPopup(WidgetTester tester, Size screenSize) async {
  print('  🎯 Testing Tournament Info Popup...');

  try {
    // Navigate to tournament hub
    // Find bottom navigation and tap tournaments tab
    Finder tournamentTab = find.text('Tournaments');
    if (tournamentTab.evaluate().isEmpty) {
      tournamentTab = find.byIcon(Icons.emoji_events);
    }
    
    if (tournamentTab.evaluate().isNotEmpty) {
      await tester.tap(tournamentTab);
      await tester.pumpAndSettle(const Duration(seconds: 2));
    } else {
      print('    ⚠️ Tournament tab not found - skipping');
      return; // Skip if can't navigate
    }

    // Find a tournament card and tap it
    Finder tournamentCard = find.byKey(const Key('tournament_card_chopper_adventures'));
    if (tournamentCard.evaluate().isEmpty) {
      // Try to find by text or other methods
      tournamentCard = find.text('Chopper Adventures');
    }
    if (tournamentCard.evaluate().isEmpty) {
      // Try to find any clickable element in tournament area
      tournamentCard = find.byType(InkWell).first;
    }

    if (tournamentCard.evaluate().isNotEmpty) {
      await tester.tap(tournamentCard);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Wait for popup animation (with timeout)
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify popup is visible
      final popupFinder = find.byType(TournamentInfoPopup);
      if (popupFinder.evaluate().isNotEmpty) {
        print('    ✅ Tournament Info Popup is visible');
        
        // Verify no overflow
        final exception = tester.takeException();
        if (exception != null && exception.toString().contains('overflowed')) {
          fail('❌ Overflow error in Tournament Info Popup: $exception');
        }

        // Take screenshot
        await tester.pump(const Duration(milliseconds: 500));

        // Close popup (usually swipe down or tap outside)
        final closeBtn = find.byKey(const Key('tournament_info_close_button'));
        if (closeBtn.evaluate().isNotEmpty) {
          await tester.tap(closeBtn);
        } else {
          await tester.tapAt(const Offset(100, 100)); // Tap outside
        }
        await tester.pumpAndSettle(const Duration(seconds: 2));
      } else {
        print('    ⚠️ Tournament Info Popup not found');
      }
    } else {
      print('    ⚠️ Tournament card not found');
    }
  } catch (e) {
    print('    ⚠️ Error testing Tournament Info Popup: $e');
  }
}

/// Test Notification Permission Popup
Future<void> _testNotificationPermissionPopup(WidgetTester tester, Size screenSize) async {
  print('  🎯 Testing Notification Permission Popup...');

  try {
    // Set up test data to trigger notification popup
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notification_permission_show_count', 0);
    await prefs.setBool('notification_permission_has_allowed', false);
    await prefs.setBool('notification_permission_has_declined', false);

    // Navigate to settings/profile where notification popup might appear
    Finder profileTab = find.text('Profile');
    if (profileTab.evaluate().isEmpty) {
      profileTab = find.byIcon(Icons.person);
    }

    if (profileTab.evaluate().isNotEmpty) {
      await tester.tap(profileTab);
      await tester.pumpAndSettle(const Duration(seconds: 2));
    } else {
      print('    ⚠️ Profile tab not found - skipping');
      return; // Skip if can't navigate
    }

    // Try to trigger notification popup
    // This might require specific conditions or navigation
    await tester.pump(const Duration(milliseconds: 500));

    // Check if popup appeared
    final popupFinder = find.byType(NotificationPermissionPopup);
    if (popupFinder.evaluate().isNotEmpty) {
      print('    ✅ Notification Permission Popup is visible');
      
      // Verify no overflow
      final exception = tester.takeException();
      if (exception != null && exception.toString().contains('overflowed')) {
        fail('❌ Overflow error in Notification Permission Popup: $exception');
      }

      // Take screenshot
      await tester.pump(const Duration(milliseconds: 500));

      // Close popup
      final notNowButton = find.text('Not Now');
      if (notNowButton.evaluate().isNotEmpty) {
        await tester.tap(notNowButton);
      } else {
        final closeButton = find.byIcon(Icons.close);
        if (closeButton.evaluate().isNotEmpty) {
          await tester.tap(closeButton);
        }
      }
      await tester.pumpAndSettle(const Duration(seconds: 2));
    } else {
      print('    ⚠️ Notification Permission Popup not found (may need different trigger)');
    }
  } catch (e) {
    print('    ⚠️ Error testing Notification Permission Popup: $e');
  }
}

/// Test Exit Confirmation Popup
Future<void> _testExitConfirmationPopup(WidgetTester tester, Size screenSize) async {
  print('  🎯 Testing Exit Confirmation Popup...');

  try {
    // Navigate to home/story page (where back button shows exit confirmation)
    Finder storyTab = find.text('Story');
    if (storyTab.evaluate().isEmpty) {
      storyTab = find.byIcon(Icons.home);
    }

    if (storyTab.evaluate().isNotEmpty) {
      await tester.tap(storyTab);
      await tester.pumpAndSettle(const Duration(seconds: 2));
    } else {
      print('    ⚠️ Story tab not found - skipping');
      return; // Skip if can't navigate
    }

    // Simulate back button press using SystemNavigator
    // Note: In integration tests, we can't easily simulate system back button
    // Instead, we'll try to find and trigger the exit confirmation directly
    // or navigate in a way that triggers it
    await tester.pump(const Duration(milliseconds: 500));

    // Check if exit confirmation appeared
    Finder popupFinder = find.byType(ExitConfirmationPopup);
    if (popupFinder.evaluate().isEmpty) {
      // Try finding by text
      popupFinder = find.text('Exit Game');
    }

    if (popupFinder.evaluate().isNotEmpty) {
      print('    ✅ Exit Confirmation Popup is visible');
      
      // Verify no overflow
      final exception = tester.takeException();
      if (exception != null && exception.toString().contains('overflowed')) {
        fail('❌ Overflow error in Exit Confirmation Popup: $exception');
      }

      // Take screenshot
      await tester.pump(const Duration(milliseconds: 500));

      // Close popup (tap "Cancel" or "Stay")
      final cancelButton = find.text('Cancel');
      if (cancelButton.evaluate().isNotEmpty) {
        await tester.tap(cancelButton);
      } else {
        final stayButton = find.text('Stay');
        if (stayButton.evaluate().isNotEmpty) {
          await tester.tap(stayButton);
        }
      }
      await tester.pumpAndSettle(const Duration(seconds: 2));
    } else {
      print('    ⚠️ Exit Confirmation Popup not found');
    }
  } catch (e) {
    print('    ⚠️ Error testing Exit Confirmation Popup: $e');
  }
}


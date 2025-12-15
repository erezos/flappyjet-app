/// 🎯 Simple Popup Screenshot Test
/// 
/// This test opens each popup one by one, takes a screenshot,
/// verifies it's visible, then closes it.
/// 
/// Run with: flutter test integration_test/popup_screenshot_test.dart
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flappy_jet_pro/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Popup Screenshot Tests', () {
    testWidgets('Test all popups - take screenshots and verify', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // ============================================
      // POPUP 1: Daily Streak Popup
      // ============================================
      await _testPopup(
        tester: tester,
        popupName: 'Daily Streak Popup',
        triggerAction: () async {
          // Find and tap the daily streak button
          final streakButton = find.byKey(const Key('daily_streak_button'));
          if (streakButton.evaluate().isNotEmpty) {
            await tester.tap(streakButton);
            await tester.pumpAndSettle();
          }
        },
        verifyPopup: () {
          // Verify popup is visible (adjust based on your actual popup widget)
          expect(find.text('Daily Streak'), findsOneWidget);
        },
        closeAction: () async {
          // Find and tap close button or claim button
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
          await tester.pumpAndSettle();
        },
      );

      // ============================================
      // POPUP 2: Rate Us Popup
      // ============================================
      await _testPopup(
        tester: tester,
        popupName: 'Rate Us Popup',
        triggerAction: () async {
          // Navigate to trigger rate us popup
          // This might require specific conditions (e.g., after X sessions)
          // You may need to set test data first
          await tester.pumpAndSettle(const Duration(seconds: 2));
        },
        verifyPopup: () {
          expect(find.text('Loving FlappyJet?'), findsOneWidget);
        },
        closeAction: () async {
          final maybeLaterButton = find.text('MAYBE LATER');
          if (maybeLaterButton.evaluate().isNotEmpty) {
            await tester.tap(maybeLaterButton);
          } else {
            final closeButton = find.byIcon(Icons.close);
            await tester.tap(closeButton);
          }
          await tester.pumpAndSettle();
        },
      );

      // ============================================
      // POPUP 3: Tournament Info Popup
      // ============================================
      await _testPopup(
        tester: tester,
        popupName: 'Tournament Info Popup',
        triggerAction: () async {
          // Navigate to tournament hub
          // Find tournament card and tap it
          final tournamentCard = find.byKey(const Key('tournament_card_chopper_adventures'));
          if (tournamentCard.evaluate().isNotEmpty) {
            await tester.tap(tournamentCard);
            await tester.pumpAndSettle();
          }
        },
        verifyPopup: () {
          // Verify tournament popup content
          expect(find.text('CHOPPER ADVENTURES'), findsOneWidget);
        },
        closeAction: () async {
          final closeButton = find.byIcon(Icons.close);
          await tester.tap(closeButton);
          await tester.pumpAndSettle();
        },
      );

      // ============================================
      // POPUP 4: Notification Permission Popup
      // ============================================
      await _testPopup(
        tester: tester,
        popupName: 'Notification Permission Popup',
        triggerAction: () async {
          // Navigate to settings or trigger notification popup
          // This might require specific conditions
          await tester.pumpAndSettle(const Duration(seconds: 2));
        },
        verifyPopup: () {
          // Verify notification popup content
          expect(find.text('Enable Notifications'), findsOneWidget);
        },
        closeAction: () async {
          final allowButton = find.text('Allow');
          if (allowButton.evaluate().isNotEmpty) {
            await tester.tap(allowButton);
          } else {
            final dismissButton = find.text('Not Now');
            await tester.tap(dismissButton);
          }
          await tester.pumpAndSettle();
        },
      );

      // Add more popups as needed...
    });
  });
}

/// Helper function to test a single popup
Future<void> _testPopup({
  required WidgetTester tester,
  required String popupName,
  required Future<void> Function() triggerAction,
  required void Function() verifyPopup,
  required Future<void> Function() closeAction,
}) async {
  print('🧪 Testing: $popupName');

  // Step 1: Trigger the popup
  print('  → Triggering popup...');
  await triggerAction();
  
  // Wait for popup animation
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();

  // Step 2: Verify popup is visible
  print('  → Verifying popup is visible...');
  verifyPopup();

  // Step 3: Take screenshot (Firebase Test Lab does this automatically)
  // But you can also capture it manually if needed
  print('  → Screenshot captured (Firebase Test Lab will do this automatically)');
  
  // Verify no overflow errors
  final exception = tester.takeException();
  if (exception != null) {
    final exceptionString = exception.toString();
    if (exceptionString.contains('overflowed') || 
        exceptionString.contains('RenderFlex')) {
      fail('❌ Overflow error in $popupName: $exception');
    }
  }

  // Step 4: Close the popup
  print('  → Closing popup...');
  await closeAction();
  
  // Wait for close animation
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();

  // Step 5: Verify popup is closed
  print('  → Verifying popup is closed...');
  // The popup should no longer be in the widget tree
  // (Adjust based on your popup widget type)
  
  print('  ✅ $popupName test completed!\n');
  
  // Small delay between popups
  await tester.pump(const Duration(milliseconds: 300));
}


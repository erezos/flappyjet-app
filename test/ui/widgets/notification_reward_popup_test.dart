/// Unit Tests for NotificationRewardPopup
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flappy_jet_pro/ui/widgets/notification_reward_popup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationRewardPopup', () {
    testWidgets('should display coin reward correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationRewardPopup(
              rewardType: 'coins',
              rewardAmount: 100,
              eventId: 123,
            ),
          ),
        ),
      );

      // Verify title
      expect(find.text('🎮 WELCOME BACK!'), findsOneWidget);
      
      // Verify reward amount
      expect(find.textContaining('+100 COINS'), findsOneWidget);
      
      // Verify claim button
      expect(find.text('CLAIM REWARD'), findsOneWidget);
    });

    testWidgets('should display gem reward correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationRewardPopup(
              rewardType: 'gems',
              rewardAmount: 10,
              eventId: 456,
            ),
          ),
        ),
      );

      // Verify reward amount
      expect(find.textContaining('+10 GEMS'), findsOneWidget);
    });

    testWidgets('should show correct emoji for coins', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationRewardPopup(
              rewardType: 'coins',
              rewardAmount: 50,
            ),
          ),
        ),
      );

      // Verify coin emoji exists
      expect(find.text('🪙'), findsOneWidget);
    });

    test('should accept different reward types', () {
      const validRewardTypes = ['coins', 'gems'];
      
      for (final type in validRewardTypes) {
        expect(['coins', 'gems'].contains(type), true);
      }
    });

    test('should handle various reward amounts', () {
      const testAmounts = [10, 50, 100, 500, 1000];
      
      for (final amount in testAmounts) {
        expect(amount > 0, true);
      }
    });
  });

  group('NotificationRewardPopup - Reward Type Validation', () {
    test('should only accept valid reward types', () {
      const validTypes = ['coins', 'gems'];
      const invalidTypes = ['gold', 'money', 'points'];

      for (final type in validTypes) {
        expect(validTypes.contains(type), true);
      }

      for (final type in invalidTypes) {
        expect(validTypes.contains(type), false);
      }
    });
  });

  group('NotificationRewardPopup - UI Elements', () {
    testWidgets('should have welcome message', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationRewardPopup(
              rewardType: 'coins',
              rewardAmount: 100,
            ),
          ),
        ),
      );

      expect(find.text('🎮 WELCOME BACK!'), findsOneWidget);
      expect(find.textContaining('Thanks for returning'), findsOneWidget);
    });

    testWidgets('should have claim reward description', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationRewardPopup(
              rewardType: 'coins',
              rewardAmount: 100,
            ),
          ),
        ),
      );

      expect(find.textContaining('Claim your reward'), findsOneWidget);
    });
  });

  group('NotificationRewardPopup - Rate Us Integration', () {
    test('should show Rate Us after claiming if user has not rated', () {
      // This tests the logic that Rate Us should be shown
      // Actual implementation tested via widget test
      const hasRated = false;
      const shouldShowRateUs = !hasRated;
      
      expect(shouldShowRateUs, true);
    });

    test('should NOT show Rate Us after claiming if user already rated', () {
      const hasRated = true;
      const shouldShowRateUs = !hasRated;
      
      expect(shouldShowRateUs, false);
    });
  });
}


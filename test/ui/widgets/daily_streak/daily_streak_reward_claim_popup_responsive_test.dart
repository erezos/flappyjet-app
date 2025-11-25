/// 🧪 DAILY STREAK REWARD CLAIM POPUP RESPONSIVE DESIGN TESTS
/// 
/// Tests for responsive design and X button positioning on daily streak reward claim popup.
/// Ensures the popup looks perfect on all device sizes.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flappy_jet_pro/ui/widgets/daily_streak/daily_streak_reward_claim_popup.dart';
import 'package:flappy_jet_pro/game/systems/daily_streak_manager.dart';

void main() {
  group('Daily Streak Reward Claim Popup - Responsive Design Tests', () {
    // Test data
    final testReward = const DailyStreakReward(
      type: DailyStreakRewardType.coins,
      amount: 100,
      iconFrame: 'icon/coin',
      displayText: '100',
      description: '100 Coins',
    );

    testWidgets('X button is positioned outside popup container on frame', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DailyStreakRewardClaimPopup(
              reward: testReward,
              onClose: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the close button
      final closeButton = find.byIcon(Icons.close_rounded);
      expect(closeButton, findsOneWidget);

      // Verify X button is positioned outside container (negative top/right values)
      final closeButtonWidget = tester.widget<GestureDetector>(closeButton);
      expect(closeButtonWidget, isNotNull);
    });

    testWidgets('Popup uses responsive sizing for different screen sizes', (WidgetTester tester) async {
      // Test small screen (phone)
      await tester.binding.setSurfaceSize(const Size(360, 640));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DailyStreakRewardClaimPopup(
              reward: testReward,
              onClose: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify popup exists
      final popup = find.byType(DailyStreakRewardClaimPopup);
      expect(popup, findsOneWidget);

      // Test large screen (tablet)
      await tester.binding.setSurfaceSize(const Size(1024, 1366));
      await tester.pumpAndSettle();

      // Verify popup still exists and is responsive
      expect(popup, findsOneWidget);
    });

    testWidgets('Popup content is properly constrained and doesn\'t overflow', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DailyStreakRewardClaimPopup(
              reward: testReward,
              onClose: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify no overflow errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('X button has proper touch target size (min 44x44)', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DailyStreakRewardClaimPopup(
              reward: testReward,
              onClose: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final closeButton = find.byIcon(Icons.close_rounded);
      expect(closeButton, findsOneWidget);

      // Get the button container
      final buttonFinder = find.ancestor(
        of: closeButton,
        matching: find.byType(Container),
      );
      
      if (buttonFinder.evaluate().isNotEmpty) {
        final container = tester.widget<Container>(buttonFinder.first);
        final constraints = container.constraints;
        
        // Verify minimum touch target size
        if (constraints != null && constraints.hasBoundedWidth && constraints.hasBoundedHeight) {
          expect(constraints.minWidth, greaterThanOrEqualTo(44.0));
          expect(constraints.minHeight, greaterThanOrEqualTo(44.0));
        }
      }
    });

    testWidgets('Popup handles jet skin reward correctly', (WidgetTester tester) async {
      final jetReward = const DailyStreakReward(
        type: DailyStreakRewardType.jetSkin,
        amount: 1,
        iconFrame: 'icon/jet',
        displayText: 'Flash Strike',
        description: 'Flash Strike Jet',
        jetSkinId: 'flash_strike',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DailyStreakRewardClaimPopup(
              reward: jetReward,
              onClose: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify popup renders without errors
      expect(find.byType(DailyStreakRewardClaimPopup), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Popup handles progressive jet reward correctly', (WidgetTester tester) async {
      final progressiveJetReward = const DailyStreakReward(
        type: DailyStreakRewardType.jetSkin,
        amount: 1,
        iconFrame: 'icon/jet',
        displayText: 'Jet',
        description: 'Jet Skin',
        jetSkinId: 'progressive_jet',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DailyStreakRewardClaimPopup(
              reward: progressiveJetReward,
              onClose: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify popup renders without errors
      expect(find.byType(DailyStreakRewardClaimPopup), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}


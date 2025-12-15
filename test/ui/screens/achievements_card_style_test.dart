import 'package:flappy_jet_pro/game/systems/achievements_manager.dart';
import 'package:flappy_jet_pro/ui/widgets/rewards/unified_reward_card.dart';
import 'package:flappy_jet_pro/ui/widgets/mission_achievement_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 🎯 Achievement Card Style Tests (Updated for UnifiedRewardCard)
/// 
/// These tests verify that achievement cards use the unified card component
/// with proper styling and floating icons (no circular backgrounds).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UnifiedRewardCard - Achievement Styling', () {
    final screenSize = const Size(360, 800);

    testWidgets('uses mission-like height and has no rarity stripe', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: UnifiedRewardCard(
                title: 'Test Achievement',
                description: 'Earn a test achievement',
                coinReward: 100,
                gemReward: 5,
                progress: 5,
                target: 10,
                status: RewardCardStatus.completed,
                icon: Achievement3DIcon(
                  iconType: AchievementIconType.scoreGold,
                  size: 30,
                ),
                iconStyle: RewardCardIconStyle.circular,
                cardGradient: const LinearGradient(
                  colors: [Color(0xFFffc107), Color(0xFFff8f00)],
                ),
                shadowColor: const Color(0xFFffc107),
                onClaimReward: () {},
                screenSize: screenSize,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final card = find.byType(UnifiedRewardCard);
      final size = tester.getSize(card);
      expect(size.height, inInclusiveRange(120, 170));

      // No explicit 6px width stripe (legacy rarity stripe) should exist
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Positioned && widget.width == 6,
        ),
        findsNothing,
      );
    });

    testWidgets('renders floating icon (no circular background, no stripe)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnifiedRewardCard(
              title: 'Test Achievement',
              description: 'Earn a test achievement',
              coinReward: 100,
              gemReward: 5,
              progress: 5,
              target: 10,
              status: RewardCardStatus.completed,
              icon: Achievement3DIcon(
                iconType: AchievementIconType.scoreGold,
                size: 30,
              ),
              iconStyle: RewardCardIconStyle.circular, // Style enum kept for compatibility, but renders as floating
              cardGradient: const LinearGradient(
                colors: [Color(0xFFffc107), Color(0xFFff8f00)],
              ),
              shadowColor: const Color(0xFFffc107),
              onClaimReward: () {},
              screenSize: screenSize,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should NOT have circular decoration (icons now float without background)
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).shape == BoxShape.circle,
        ),
        findsNothing,
      );
    });
  });
}


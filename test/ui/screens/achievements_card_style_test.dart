import 'package:flappy_jet_pro/game/systems/achievements_manager.dart';
import 'package:flappy_jet_pro/ui/screens/daily_missions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PremiumAchievementCard styling', () {
    final screenSize = const Size(360, 800);
    final sampleAchievement = Achievement(
      id: 'achv_test',
      title: 'Test Achievement',
      description: 'Earn a test achievement',
      category: AchievementCategory.score,
      rarity: AchievementRarity.gold,
      target: 10,
      coinReward: 100,
      gemReward: 5,
      iconPath: 'icons/test.png',
      progress: 5,
      unlocked: true,
      claimed: false,
    );

    testWidgets('uses mission-like height and has no rarity stripe', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PremiumAchievementCard(
                achievement: sampleAchievement,
                onClaimReward: () {},
                screenSize: screenSize,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final card = find.byType(PremiumAchievementCard);
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

    testWidgets('renders circular icon background (no stripe)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PremiumAchievementCard(
              achievement: sampleAchievement,
              onClaimReward: () {},
              screenSize: screenSize,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // There should be at least one container with circular decoration (icon background)
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).shape == BoxShape.circle,
        ),
        findsWidgets,
      );
    });
  });
}


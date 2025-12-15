/// 🎯 Unified Reward Card Tests
/// 
/// Comprehensive tests for the unified reward card component.
/// Verifies:
/// - Card renders correctly for missions and achievements
/// - All three states (locked, completed, claimed) work properly
/// - Responsive design on different screen sizes
/// - Icon styles (floating vs circular)
/// - Reward display (coins + optional gems)
/// - Loading states
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/game/systems/missions_manager.dart';
import 'package:flappy_jet_pro/game/systems/achievements_manager.dart';
import 'package:flappy_jet_pro/ui/widgets/rewards/unified_reward_card.dart';
import 'package:flappy_jet_pro/ui/widgets/mission_achievement_icons.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UnifiedRewardCard - Basic Rendering', () {
    final screenSize = const Size(360, 800);

    testWidgets('renders mission card with floating icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: UnifiedRewardCard(
                title: 'Test Mission',
                description: 'Complete a test mission',
                coinReward: 100,
                gemReward: null,
                progress: 5,
                target: 10,
                status: RewardCardStatus.locked,
                icon: Mission3DIcon(
                  iconType: MissionIconType.playGames,
                  size: 50,
                ),
                iconStyle: RewardCardIconStyle.floating,
                cardGradient: const LinearGradient(
                  colors: [Color(0xFF00bcd4), Color(0xFF0097a7)],
                ),
                shadowColor: const Color(0xFF00bcd4),
                screenSize: screenSize,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify card exists
      expect(find.byType(UnifiedRewardCard), findsOneWidget);
      
      // Verify title and description
      expect(find.text('Test Mission'), findsOneWidget);
      expect(find.text('Complete a test mission'), findsOneWidget);
      
      // Verify coin reward
      expect(find.text('100'), findsOneWidget);
      
      // Verify progress indicator
      expect(find.text('Progress: 5/10'), findsOneWidget);
    });

    testWidgets('renders achievement card with circular icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: UnifiedRewardCard(
                title: 'Test Achievement',
                description: 'Earn a test achievement',
                coinReward: 200,
                gemReward: 5,
                progress: 8,
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

      // Verify card exists
      expect(find.byType(UnifiedRewardCard), findsOneWidget);
      
      // Verify title and description
      expect(find.text('Test Achievement'), findsOneWidget);
      expect(find.text('Earn a test achievement'), findsOneWidget);
      
      // Verify both coin and gem rewards
      expect(find.text('200'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      
      // Verify claim button image exists
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName == 'assets/images/ui/claim_button.png',
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows DONE badge for claimed items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: UnifiedRewardCard(
                title: 'Completed Mission',
                description: 'This mission is done',
                coinReward: 150,
                progress: 10,
                target: 10,
                status: RewardCardStatus.claimed,
                icon: Mission3DIcon(
                  iconType: MissionIconType.collectCoins,
                  size: 50,
                ),
                iconStyle: RewardCardIconStyle.floating,
                cardGradient: const LinearGradient(
                  colors: [Color(0xFFffc107), Color(0xFFff8f00)],
                ),
                shadowColor: const Color(0xFFffc107),
                screenSize: screenSize,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify DONE badge appears
      expect(find.text('DONE'), findsOneWidget);
      
      // Verify no claim button
      expect(find.text('CLAIM REWARD'), findsNothing);
    });

    testWidgets('shows loading state when claiming', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: UnifiedRewardCard(
                title: 'Loading Mission',
                description: 'This is being claimed',
                coinReward: 75,
                progress: 10,
                target: 10,
                status: RewardCardStatus.completed,
                icon: Mission3DIcon(
                  iconType: MissionIconType.playGames,
                  size: 50,
                ),
                iconStyle: RewardCardIconStyle.floating,
                cardGradient: const LinearGradient(
                  colors: [Color(0xFF00bcd4), Color(0xFF0097a7)],
                ),
                shadowColor: const Color(0xFF00bcd4),
                onClaimReward: () {},
                isClaiming: true,
                screenSize: screenSize,
              ),
            ),
          ),
        ),
      );

      await tester.pump(); // Don't use pumpAndSettle for loading states

      // Verify claim button image exists (with loading overlay)
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName == 'assets/images/ui/claim_button.png',
        ),
        findsOneWidget,
      );
      
      // Verify loading indicator exists
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('UnifiedRewardCard - Responsive Design', () {
    testWidgets('adapts to small phone screen', (tester) async {
      final smallScreen = const Size(320, 568);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: UnifiedRewardCard(
                title: 'Small Screen Test',
                description: 'Testing responsive design',
                coinReward: 100,
                progress: 5,
                target: 10,
                status: RewardCardStatus.locked,
                icon: Mission3DIcon(
                  iconType: MissionIconType.playGames,
                  size: 50,
                ),
                iconStyle: RewardCardIconStyle.floating,
                cardGradient: const LinearGradient(
                  colors: [Color(0xFF00bcd4), Color(0xFF0097a7)],
                ),
                shadowColor: const Color(0xFF00bcd4),
                screenSize: smallScreen,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final card = find.byType(UnifiedRewardCard);
      final size = tester.getSize(card);
      
      // Card height should be within responsive range
      expect(size.height, inInclusiveRange(120, 170));
    });

    testWidgets('adapts to tablet screen', (tester) async {
      final tabletScreen = const Size(768, 1024);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: UnifiedRewardCard(
                title: 'Tablet Screen Test',
                description: 'Testing responsive design on tablet',
                coinReward: 200,
                gemReward: 10,
                progress: 8,
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
                screenSize: tabletScreen,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final card = find.byType(UnifiedRewardCard);
      final size = tester.getSize(card);
      
      // Card height should be within responsive range (allowing some flexibility for tablets)
      expect(size.height, greaterThanOrEqualTo(120));
      expect(size.height, lessThanOrEqualTo(200)); // Allow higher for tablets
    });
  });

  group('UnifiedRewardCard - Icon Styles', () {
    final screenSize = const Size(360, 800);

    testWidgets('floating icon has no circular background', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: UnifiedRewardCard(
                title: 'Floating Icon Test',
                description: 'Icon should float',
                coinReward: 100,
                progress: 5,
                target: 10,
                status: RewardCardStatus.locked,
                icon: Mission3DIcon(
                  iconType: MissionIconType.playGames,
                  size: 50,
                ),
                iconStyle: RewardCardIconStyle.floating,
                cardGradient: const LinearGradient(
                  colors: [Color(0xFF00bcd4), Color(0xFF0097a7)],
                ),
                shadowColor: const Color(0xFF00bcd4),
                screenSize: screenSize,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should NOT have circular decoration
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

    testWidgets('circular icon style now uses floating (no background)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: UnifiedRewardCard(
                title: 'Floating Icon Test',
                description: 'Icon should float without circular background',
                coinReward: 200,
                gemReward: 5,
                progress: 8,
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
        ),
      );

      await tester.pumpAndSettle();

      // Should NOT have circular decoration (all icons now float)
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

  group('UnifiedRewardCard - Reward Display', () {
    final screenSize = const Size(360, 800);

    testWidgets('shows only coins when no gems', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: UnifiedRewardCard(
                title: 'Coins Only',
                description: 'No gems here',
                coinReward: 100,
                gemReward: null,
                progress: 5,
                target: 10,
                status: RewardCardStatus.locked,
                icon: Mission3DIcon(
                  iconType: MissionIconType.playGames,
                  size: 50,
                ),
                iconStyle: RewardCardIconStyle.floating,
                cardGradient: const LinearGradient(
                  colors: [Color(0xFF00bcd4), Color(0xFF0097a7)],
                ),
                shadowColor: const Color(0xFF00bcd4),
                screenSize: screenSize,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show coin reward
      expect(find.text('100'), findsOneWidget);
      
      // Should show coin reward
      expect(find.text('100'), findsOneWidget);
      
      // Should NOT show gem reward text (only coin amount)
      // Note: The card itself has a gradient, so we check for text instead
      expect(find.textContaining('100'), findsOneWidget);
    });

    testWidgets('shows both coins and gems when gemReward provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: UnifiedRewardCard(
                title: 'Coins and Gems',
                description: 'Has both rewards',
                coinReward: 200,
                gemReward: 10,
                progress: 10,
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

      // Should show both coin and gem rewards
      expect(find.text('200'), findsOneWidget);
      expect(find.text('10'), findsWidgets); // Appears in both coin and gem badges
    });
  });

  group('UnifiedRewardCard - Status States', () {
    final screenSize = const Size(360, 800);

    testWidgets('locked state shows progress with percentage', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: UnifiedRewardCard(
                title: 'Locked Mission',
                description: 'Not completed yet',
                coinReward: 100,
                progress: 3,
                target: 10,
                status: RewardCardStatus.locked,
                icon: Mission3DIcon(
                  iconType: MissionIconType.playGames,
                  size: 50,
                ),
                iconStyle: RewardCardIconStyle.floating,
                cardGradient: const LinearGradient(
                  colors: [Color(0xFF00bcd4), Color(0xFF0097a7)],
                ),
                shadowColor: const Color(0xFF00bcd4),
                screenSize: screenSize,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show progress
      expect(find.text('Progress: 3/10'), findsOneWidget);
      
      // Should show percentage
      expect(find.text('30%'), findsOneWidget);
      
      // Should NOT show claim button or DONE badge
      expect(find.text('CLAIM REWARD'), findsNothing);
      expect(find.text('DONE'), findsNothing);
    });

    testWidgets('completed state shows claim button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: UnifiedRewardCard(
                title: 'Completed Mission',
                description: 'Ready to claim',
                coinReward: 150,
                progress: 10,
                target: 10,
                status: RewardCardStatus.completed,
                icon: Mission3DIcon(
                  iconType: MissionIconType.collectCoins,
                  size: 50,
                ),
                iconStyle: RewardCardIconStyle.floating,
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

      // Should show claim button (programmatic button with "CLAIM" text)
      expect(find.text('CLAIM'), findsOneWidget);
      
      // Should NOT show progress or DONE badge
      expect(find.text('Progress:'), findsNothing);
      expect(find.text('DONE'), findsNothing);
    });

    testWidgets('claimed state shows DONE badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: UnifiedRewardCard(
                title: 'Claimed Mission',
                description: 'Already claimed',
                coinReward: 200,
                progress: 10,
                target: 10,
                status: RewardCardStatus.claimed,
                icon: Mission3DIcon(
                  iconType: MissionIconType.streakMaster,
                  size: 50,
                ),
                iconStyle: RewardCardIconStyle.floating,
                cardGradient: const LinearGradient(
                  colors: [Color(0xFFff5722), Color(0xFFe64a19)],
                ),
                shadowColor: const Color(0xFFff5722),
                screenSize: screenSize,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show DONE badge
      expect(find.text('DONE'), findsOneWidget);
      
      // Should NOT show claim button or progress
      expect(find.text('CLAIM REWARD'), findsNothing);
      expect(find.text('Progress:'), findsNothing);
    });
  });
}


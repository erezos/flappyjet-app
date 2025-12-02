/// 🎯 BADGE OVERLAP VERIFICATION TESTS
///
/// These tests verify that the notification badge is correctly positioned
/// at the banner's top-right corner, following mobile game UI best practices.
///
/// The banner is rectangular (222x80 aspect ratio) and the badge is positioned
/// at the top-right corner using Positioned with right/top values.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flappy_jet_pro/ui/widgets/floating_missions_banner.dart';
import 'package:flappy_jet_pro/game/systems/missions_manager.dart';
import 'package:flappy_jet_pro/game/systems/achievements_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Badge Position Verification', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      MissionsManager().resetForTesting();
      await MissionsManager().initialize();
      await AchievementsManager().initialize();
    });

    testWidgets('Badge uses Positioned widget for placement', (tester) async {
      await MissionsManager().updateMissionProgress(MissionType.playGames, 10);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingMissionsBanner(
              onTap: () {},
              size: 85,
              useResponsiveScaling: false,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Find Positioned widgets
      final positionedFinder = find.descendant(
        of: find.byType(FloatingMissionsBanner),
        matching: find.byType(Positioned),
      );
      
      expect(positionedFinder, findsWidgets, reason: 'Badge should use Positioned widget');
    });

    testWidgets('Badge uses positioning to overlap corner', (tester) async {
      await MissionsManager().updateMissionProgress(MissionType.playGames, 10);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FloatingMissionsBanner(
                onTap: () {},
                size: 85,
                useResponsiveScaling: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Find Positioned widgets
      final positionedFinder = find.descendant(
        of: find.byType(FloatingMissionsBanner),
        matching: find.byType(Positioned),
      );
      
      expect(positionedFinder, findsWidgets);

      // Find the badge Positioned (one with right and top values set)
      bool foundBadgePositioned = false;
      for (final element in positionedFinder.evaluate()) {
        final positioned = element.widget as Positioned;
        final right = positioned.right;
        final top = positioned.top;
        
        // Badge should have right AND top values defined (positioned at corner)
        if (right != null && top != null) {
          foundBadgePositioned = true;
          // Verify it's positioned near the corner (small values)
          expect(right, lessThan(50), reason: 'Badge should be near right edge');
          expect(top, lessThan(50), reason: 'Badge should be near top edge');
          break;
        }
      }
      
      expect(foundBadgePositioned, isTrue, 
        reason: 'Badge Positioned must have right AND top values to be at corner');
    });

    testWidgets('Badge visually overlaps banner corner area', (tester) async {
      await MissionsManager().updateMissionProgress(MissionType.playGames, 10);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FloatingMissionsBanner(
                onTap: () {},
                size: 85,
                useResponsiveScaling: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Find the SizedBox wrapper (defines banner bounds)
      final sizedBoxFinder = find.descendant(
        of: find.byType(FloatingMissionsBanner),
        matching: find.byType(SizedBox),
      );
      
      // Find the RED badge (not the blue fallback banner)
      final badgeFinder = find.descendant(
        of: find.byType(FloatingMissionsBanner),
        matching: find.byWidgetPredicate((widget) {
          if (widget is Container && widget.decoration is BoxDecoration) {
            final decoration = widget.decoration as BoxDecoration;
            if (decoration.gradient is LinearGradient) {
              final gradient = decoration.gradient as LinearGradient;
              return gradient.colors.any((color) => color.red > 200 && color.green < 100);
            }
          }
          return false;
        }),
      );

      expect(sizedBoxFinder, findsWidgets, reason: 'Should find the banner SizedBox');
      expect(badgeFinder, findsOneWidget, reason: 'Should find the red badge Container');

      // Get the actual rendered positions
      final bannerRect = tester.getRect(sizedBoxFinder.first);
      final badgeRect = tester.getRect(badgeFinder);

      // Badge should OVERLAP the banner (positioned inside the banner bounds)
      expect(badgeRect.left, lessThan(bannerRect.right),
        reason: 'Badge left edge (${badgeRect.left}) should overlap banner right area (${bannerRect.right})');
      expect(badgeRect.bottom, greaterThan(bannerRect.top),
        reason: 'Badge bottom edge (${badgeRect.bottom}) should overlap banner top area (${bannerRect.top})');
    });

    testWidgets('Badge is positioned at TOP-RIGHT corner (not any other corner)', (tester) async {
      await MissionsManager().updateMissionProgress(MissionType.playGames, 10);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FloatingMissionsBanner(
                onTap: () {},
                size: 85,
                useResponsiveScaling: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Find the SizedBox wrapper (defines banner bounds)
      final sizedBoxFinder = find.descendant(
        of: find.byType(FloatingMissionsBanner),
        matching: find.byType(SizedBox),
      );
      
      // Find RED badge (not the blue fallback banner)
      final badgeFinder = find.descendant(
        of: find.byType(FloatingMissionsBanner),
        matching: find.byWidgetPredicate((widget) {
          if (widget is Container && widget.decoration is BoxDecoration) {
            final decoration = widget.decoration as BoxDecoration;
            if (decoration.gradient is LinearGradient) {
              final gradient = decoration.gradient as LinearGradient;
              return gradient.colors.any((color) => color.red > 200 && color.green < 100);
            }
          }
          return false;
        }),
      );

      expect(sizedBoxFinder, findsWidgets);
      expect(badgeFinder, findsOneWidget);

      final bannerRect = tester.getRect(sizedBoxFinder.first);
      final badgeRect = tester.getRect(badgeFinder);

      // Badge center should be near the TOP-RIGHT corner of the banner
      final badgeCenterX = badgeRect.center.dx;
      final badgeCenterY = badgeRect.center.dy;
      final bannerCenterX = bannerRect.center.dx;
      final bannerCenterY = bannerRect.center.dy;

      // Badge should be to the RIGHT of banner center (right side)
      expect(badgeCenterX, greaterThan(bannerCenterX),
        reason: 'Badge center X (${badgeCenterX}) should be to the RIGHT of banner center X (${bannerCenterX})');

      // Badge should be ABOVE banner center (top side)
      expect(badgeCenterY, lessThan(bannerCenterY),
        reason: 'Badge center Y (${badgeCenterY}) should be ABOVE banner center Y (${bannerCenterY})');
    });

    testWidgets('No badge shown when claimable count is 0', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FloatingMissionsBanner(
                onTap: () {},
                size: 85,
                useResponsiveScaling: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Find RED badge container (badge has red gradient, fallback banner has blue)
      final badgeFinder = find.descendant(
        of: find.byType(FloatingMissionsBanner),
        matching: find.byWidgetPredicate((widget) {
          if (widget is Container && widget.decoration is BoxDecoration) {
            final decoration = widget.decoration as BoxDecoration;
            if (decoration.gradient is LinearGradient) {
              final gradient = decoration.gradient as LinearGradient;
              // Badge has RED gradient (0xFFFF5555, 0xFFDD0000)
              return gradient.colors.any((color) => color.red > 200 && color.green < 100);
            }
          }
          return false;
        }),
      );

      expect(badgeFinder, findsNothing, reason: 'Red badge should not appear when no rewards are claimable');
    });

    testWidgets('Badge appears when rewards become claimable', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FloatingMissionsBanner(
                onTap: () {},
                size: 85,
                useResponsiveScaling: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Helper to find the RED badge (not the blue fallback banner)
      Finder findRedBadge() => find.descendant(
        of: find.byType(FloatingMissionsBanner),
        matching: find.byWidgetPredicate((widget) {
          if (widget is Container && widget.decoration is BoxDecoration) {
            final decoration = widget.decoration as BoxDecoration;
            if (decoration.gradient is LinearGradient) {
              final gradient = decoration.gradient as LinearGradient;
              // Badge has RED gradient (0xFFFF5555, 0xFFDD0000)
              // Fallback has BLUE gradient (0xFF1E3A8A, 0xFF0F172A)
              return gradient.colors.any((color) => color.red > 200 && color.green < 100);
            }
          }
          return false;
        }),
      );
      
      // Initially no RED badge (may have fallback banner but that's blue)
      expect(findRedBadge(), findsNothing);

      // Complete a mission
      await MissionsManager().updateMissionProgress(MissionType.playGames, 10);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Now RED badge should appear
      expect(findRedBadge(), findsOneWidget, reason: 'Badge should appear after mission is completed');
    });
  });
}

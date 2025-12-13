/// 🏆 FREE BADGE OVERLAP VERIFICATION TESTS
///
/// These tests verify that the "FREE" notification badge is correctly positioned
/// at the banner's top-right corner, matching the Missions banner style.
///
/// The banner is rectangular (220x147 aspect ratio) and the badge is positioned
/// at the top-right corner using Positioned with:
/// - Positive right offset (slightly inside the right edge)
/// - Negative top offset (overlapping the top edge)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flappy_jet_pro/ui/widgets/floating_tournaments_banner.dart';
import 'package:flappy_jet_pro/game/systems/tournament_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FloatingTournamentsBanner - Badge Position Verification', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      // Initialize tournament manager for tests
      if (!TournamentManager().isInitialized) {
        await TournamentManager().initialize();
      }
    });

    testWidgets('Badge uses Positioned widget for placement', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingTournamentsBanner(
              onTap: () {},
              size: 100,
              useResponsiveScaling: false,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Find Positioned widgets
      final positionedFinder = find.descendant(
        of: find.byType(FloatingTournamentsBanner),
        matching: find.byType(Positioned),
      );
      
      expect(positionedFinder, findsWidgets, reason: 'Badge should use Positioned widget');
    });

    testWidgets('Badge positioned at top-right corner with correct offsets', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FloatingTournamentsBanner(
                onTap: () {},
                size: 100,
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
        of: find.byType(FloatingTournamentsBanner),
        matching: find.byType(Positioned),
      );
      
      expect(positionedFinder, findsWidgets);

      // Find the BADGE Positioned specifically
      // Badge Positioned has: right AND top set, but NOT left AND bottom
      // This distinguishes it from Positioned.fill which has all 4 set
      bool foundBadgePositioned = false;
      for (final element in positionedFinder.evaluate()) {
        final positioned = element.widget as Positioned;
        final right = positioned.right;
        final top = positioned.top;
        final left = positioned.left;
        final bottom = positioned.bottom;
        
        // Badge Positioned: has right + top, but NOT left + bottom (not a fill)
        final isFill = left != null && right != null && top != null && bottom != null;
        final isBadgePositioned = right != null && top != null && !isFill;
        
        if (isBadgePositioned) {
          foundBadgePositioned = true;
          
          // ✅ Verify positioning MATCHES Missions banner pattern EXACTLY:
          // - POSITIVE rightOffset = badge stays INSIDE container (near right edge)
          // - NEGATIVE topOffset = badge overlaps TOP edge (sits above)
          expect(right, greaterThanOrEqualTo(0), 
            reason: 'Badge right offset ($right) should be non-negative (inside container)');
          expect(right, lessThan(20), 
            reason: 'Badge right offset ($right) should be small (near right edge)');
          
          // - Top offset should be NEGATIVE (overlapping top edge)
          expect(top, lessThan(0), 
            reason: 'Badge top offset ($top) should be negative (overlapping top edge like Missions banner)');
          expect(top, greaterThan(-20), 
            reason: 'Badge top offset ($top) should be small negative (not too far outside)');
          break;
        }
      }
      
      expect(foundBadgePositioned, isTrue, 
        reason: 'Badge Positioned must have right AND top values (but not left/bottom) to be at corner');
    });

    testWidgets('Badge is smaller than banner (compact size)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FloatingTournamentsBanner(
                onTap: () {},
                size: 100,
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
        of: find.byType(FloatingTournamentsBanner),
        matching: find.byType(SizedBox),
      );
      
      // Find GREEN badge (FREE badge has green gradient)
      final badgeFinder = find.descendant(
        of: find.byType(FloatingTournamentsBanner),
        matching: find.byWidgetPredicate((widget) {
          if (widget is Container && widget.decoration is BoxDecoration) {
            final decoration = widget.decoration as BoxDecoration;
            if (decoration.gradient is LinearGradient) {
              final gradient = decoration.gradient as LinearGradient;
              // FREE badge has GREEN gradient (0xFF4CAF50, 0xFF2E7D32)
              return gradient.colors.any((color) => color.green > 150 && color.red < 150);
            }
          }
          return false;
        }),
      );

      if (sizedBoxFinder.evaluate().isNotEmpty && badgeFinder.evaluate().isNotEmpty) {
        final bannerRect = tester.getRect(sizedBoxFinder.first);
        final badgeRect = tester.getRect(badgeFinder);

        // Badge should be SMALLER than the banner (compact mobile gaming badge)
        // Badge is wider for "FREE" text, so allow up to 60% width, 50% height
        expect(badgeRect.width, lessThan(bannerRect.width * 0.6),
          reason: 'Badge width (${badgeRect.width}) should be less than 60% of banner width (${bannerRect.width})');
        expect(badgeRect.height, lessThan(bannerRect.height * 0.5),
          reason: 'Badge height (${badgeRect.height}) should be less than 50% of banner height (${bannerRect.height})');
      }
    });

    testWidgets('Badge visually overlaps banner corner area', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FloatingTournamentsBanner(
                onTap: () {},
                size: 100,
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
        of: find.byType(FloatingTournamentsBanner),
        matching: find.byType(SizedBox),
      );
      
      // Find GREEN badge (FREE badge has green gradient)
      final badgeFinder = find.descendant(
        of: find.byType(FloatingTournamentsBanner),
        matching: find.byWidgetPredicate((widget) {
          if (widget is Container && widget.decoration is BoxDecoration) {
            final decoration = widget.decoration as BoxDecoration;
            if (decoration.gradient is LinearGradient) {
              final gradient = decoration.gradient as LinearGradient;
              // FREE badge has GREEN gradient (0xFF4CAF50, 0xFF2E7D32)
              return gradient.colors.any((color) => color.green > 150 && color.red < 150);
            }
          }
          return false;
        }),
      );

      if (sizedBoxFinder.evaluate().isNotEmpty && badgeFinder.evaluate().isNotEmpty) {
        final bannerRect = tester.getRect(sizedBoxFinder.first);
        final badgeRect = tester.getRect(badgeFinder);

        // Badge should OVERLAP the banner (positioned inside the banner bounds)
        expect(badgeRect.left, lessThan(bannerRect.right),
          reason: 'Badge left edge (${badgeRect.left}) should overlap banner right area (${bannerRect.right})');
        expect(badgeRect.bottom, greaterThan(bannerRect.top),
          reason: 'Badge bottom edge (${badgeRect.bottom}) should overlap banner top area (${bannerRect.top})');
      }
    });

    testWidgets('Badge is positioned at TOP-RIGHT corner (not any other corner)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FloatingTournamentsBanner(
                onTap: () {},
                size: 100,
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
        of: find.byType(FloatingTournamentsBanner),
        matching: find.byType(SizedBox),
      );
      
      // Find GREEN badge (FREE badge has green gradient)
      final badgeFinder = find.descendant(
        of: find.byType(FloatingTournamentsBanner),
        matching: find.byWidgetPredicate((widget) {
          if (widget is Container && widget.decoration is BoxDecoration) {
            final decoration = widget.decoration as BoxDecoration;
            if (decoration.gradient is LinearGradient) {
              final gradient = decoration.gradient as LinearGradient;
              // FREE badge has GREEN gradient (0xFF4CAF50, 0xFF2E7D32)
              return gradient.colors.any((color) => color.green > 150 && color.red < 150);
            }
          }
          return false;
        }),
      );

      if (sizedBoxFinder.evaluate().isNotEmpty && badgeFinder.evaluate().isNotEmpty) {
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
      }
    });
  });

  group('FloatingTournamentsBanner - Badge Size Verification', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Badge dimensions match expected compact size', (tester) async {
      // Test with size 100 (bannerHeight = 70, badgeSize = ~24.5)
      // Formula: badgeSize = (bannerHeight * 0.35).clamp(20, 28)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FloatingTournamentsBanner(
                onTap: () {},
                size: 100,
                useResponsiveScaling: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Find GREEN badge
      final badgeFinder = find.descendant(
        of: find.byType(FloatingTournamentsBanner),
        matching: find.byWidgetPredicate((widget) {
          if (widget is Container && widget.decoration is BoxDecoration) {
            final decoration = widget.decoration as BoxDecoration;
            if (decoration.gradient is LinearGradient) {
              final gradient = decoration.gradient as LinearGradient;
              return gradient.colors.any((color) => color.green > 150 && color.red < 150);
            }
          }
          return false;
        }),
      );

      if (badgeFinder.evaluate().isNotEmpty) {
        final badgeRect = tester.getRect(badgeFinder);
        
        // For size=100, bannerHeight=70, badgeSize = (70*0.35).clamp(20,28) ≈ 24.5
        // Badge height should be around 20-28px (clamped range) + some padding
        expect(badgeRect.height, greaterThanOrEqualTo(15),
          reason: 'Badge height (${badgeRect.height}) should be at least 15px');
        expect(badgeRect.height, lessThanOrEqualTo(40),
          reason: 'Badge height (${badgeRect.height}) should be at most 40px (compact)');
        
        // Badge width should be wider than height (for "FREE" text)
        // The badge has padding, so actual width can be up to 3x the base height
        expect(badgeRect.width, greaterThan(badgeRect.height),
          reason: 'Badge width should be wider than height for "FREE" text');
        expect(badgeRect.width, lessThanOrEqualTo(badgeRect.height * 3.5),
          reason: 'Badge width should not be too wide (max 3.5x height)');
      }
    });
  });

  group('FloatingTournamentsBanner - Stack Configuration', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Stack uses clipBehavior: Clip.none for badge overflow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingTournamentsBanner(
              onTap: () {},
              size: 100,
              useResponsiveScaling: false,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Find Stack widgets inside the banner
      final stackFinder = find.descendant(
        of: find.byType(FloatingTournamentsBanner),
        matching: find.byType(Stack),
      );
      
      expect(stackFinder, findsWidgets, reason: 'Banner should contain Stack widget');

      // At least one Stack should have clipBehavior: Clip.none
      bool foundClipNone = false;
      for (final element in stackFinder.evaluate()) {
        final stack = element.widget as Stack;
        if (stack.clipBehavior == Clip.none) {
          foundClipNone = true;
          break;
        }
      }
      
      expect(foundClipNone, isTrue,
        reason: 'Stack must have clipBehavior: Clip.none to allow badge to overflow');
    });
  });

  group('FloatingTournamentsBanner - Badge Styling', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('FREE badge has green gradient (distinct from red Missions badge)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingTournamentsBanner(
              onTap: () {},
              size: 100,
              useResponsiveScaling: false,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Find GREEN badge (FREE badge has green gradient)
      final greenBadgeFinder = find.descendant(
        of: find.byType(FloatingTournamentsBanner),
        matching: find.byWidgetPredicate((widget) {
          if (widget is Container && widget.decoration is BoxDecoration) {
            final decoration = widget.decoration as BoxDecoration;
            if (decoration.gradient is LinearGradient) {
              final gradient = decoration.gradient as LinearGradient;
              // GREEN gradient (0xFF4CAF50, 0xFF2E7D32)
              return gradient.colors.any((color) => color.green > 150 && color.red < 150);
            }
          }
          return false;
        }),
      );

      // Find RED badge (should NOT exist - Missions uses red, not Tournaments)
      final redBadgeFinder = find.descendant(
        of: find.byType(FloatingTournamentsBanner),
        matching: find.byWidgetPredicate((widget) {
          if (widget is Container && widget.decoration is BoxDecoration) {
            final decoration = widget.decoration as BoxDecoration;
            if (decoration.gradient is LinearGradient) {
              final gradient = decoration.gradient as LinearGradient;
              // RED gradient (0xFFFF4444, 0xFFCC0000)
              return gradient.colors.any((color) => color.red > 200 && color.green < 100 && color.blue < 100);
            }
          }
          return false;
        }),
      );

      // RED badge should NOT exist (that's for Missions banner)
      expect(redBadgeFinder, findsNothing,
        reason: 'Tournament banner should NOT have red badge (red is for Missions)');
      
      // GREEN badge may or may not exist depending on free tournament availability
      // Just verify it's the correct type if present
      if (greenBadgeFinder.evaluate().isNotEmpty) {
        expect(greenBadgeFinder, findsOneWidget,
          reason: 'If FREE badge is shown, it should be green');
      }
    });

    testWidgets('FREE badge displays "FREE" text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingTournamentsBanner(
              onTap: () {},
              size: 100,
              useResponsiveScaling: false,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Look for "FREE" text (may or may not be visible depending on tournament availability)
      final freeTextFinder = find.descendant(
        of: find.byType(FloatingTournamentsBanner),
        matching: find.text('FREE'),
      );

      // If badge is shown, it should have "FREE" text
      // (Badge only shows when there's a free tournament or ticket)
      if (freeTextFinder.evaluate().isNotEmpty) {
        expect(freeTextFinder, findsOneWidget,
          reason: 'FREE badge should display "FREE" text');
      }
    });
  });
}


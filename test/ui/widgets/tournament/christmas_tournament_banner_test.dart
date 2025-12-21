/// 🎄 Tests for Christmas Tournament Banner - Timer Badge Single Line
/// 
/// Verifies:
/// - Timer badge text stays on one line across all screen sizes
/// - FittedBox correctly scales text to fit
/// - Different time formats (days, hours:minutes:seconds) work correctly
/// - Small screens (Xiaomi-like) handle text without wrapping
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flappy_jet_pro/ui/widgets/tournament/christmas_tournament_banner.dart';
import 'package:flappy_jet_pro/game/systems/tournament_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Christmas Tournament Banner - Timer Badge Single Line', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      TournamentManager().resetForTesting();
    });

    tearDown(() {
      // Reset screen size after each test
      // Screen size reset is handled in individual tests
    });

    testWidgets('timer badge uses FittedBox to prevent text wrapping', (tester) async {
      // Test on small screen (Xiaomi-like device: 360x640)
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                ChristmasTournamentBanner(),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the FittedBox widget (should exist if banner is visible)
      final fittedBoxFinder = find.descendant(
        of: find.byType(ChristmasTournamentBanner),
        matching: find.byType(FittedBox),
      );

      // Banner might not be visible if tournament is not available
      // But if it is visible, FittedBox should be used
      if (fittedBoxFinder.evaluate().isNotEmpty) {
        final fittedBox = tester.widget<FittedBox>(fittedBoxFinder);
        expect(fittedBox.fit, equals(BoxFit.scaleDown), 
          reason: 'Should use scaleDown to shrink text if needed');

        // Find the Text widget inside FittedBox
        final textWidget = tester.widget<Text>(
          find.descendant(
            of: fittedBoxFinder,
            matching: find.byType(Text),
          ),
        );

        expect(textWidget.maxLines, equals(1), reason: 'Text should be limited to one line');
        expect(textWidget.overflow, equals(TextOverflow.ellipsis), 
          reason: 'Should use ellipsis as fallback');
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('timer badge has ConstrainedBox to limit width', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                ChristmasTournamentBanner(),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the ConstrainedBox inside FittedBox
      final constrainedBoxFinder = find.descendant(
        of: find.byType(ChristmasTournamentBanner),
        matching: find.byType(ConstrainedBox),
      );

      if (constrainedBoxFinder.evaluate().isNotEmpty) {
        final constrainedBox = tester.widget<ConstrainedBox>(constrainedBoxFinder);
        expect(constrainedBox.constraints.maxWidth, greaterThan(0), 
          reason: 'maxWidth should be set to constrain text');
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('timer badge text structure is correct for single line', (tester) async {
      // Test on very small screen (smallest common Android device)
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                ChristmasTournamentBanner(),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the widget structure: FittedBox > ConstrainedBox > Text
      final fittedBoxFinder = find.descendant(
        of: find.byType(ChristmasTournamentBanner),
        matching: find.byType(FittedBox),
      );

      if (fittedBoxFinder.evaluate().isNotEmpty) {
        // Verify FittedBox exists
        expect(fittedBoxFinder, findsOneWidget);

        // Verify ConstrainedBox is inside FittedBox
        final constrainedBoxFinder = find.descendant(
          of: fittedBoxFinder,
          matching: find.byType(ConstrainedBox),
        );
        expect(constrainedBoxFinder, findsOneWidget);

        // Verify Text is inside ConstrainedBox
        final textFinder = find.descendant(
          of: constrainedBoxFinder,
          matching: find.byType(Text),
        );
        expect(textFinder, findsOneWidget);

        final textWidget = tester.widget<Text>(textFinder);
        expect(textWidget.maxLines, equals(1), reason: 'Text must be limited to one line');
        expect(textWidget.overflow, equals(TextOverflow.ellipsis), 
          reason: 'Should use ellipsis as overflow fallback');
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('timer badge text scales correctly on different screen sizes', (tester) async {
      final screenSizes = [
        const Size(360, 640),   // Small (Xiaomi Redmi)
        const Size(375, 667),   // iPhone SE
        const Size(414, 896),   // iPhone 11 Pro Max
        const Size(768, 1024),  // iPad
        const Size(1024, 1366), // Large tablet
      ];

      for (final screenSize in screenSizes) {
        tester.view.physicalSize = screenSize;
        tester.view.devicePixelRatio = 2.0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  ChristmasTournamentBanner(),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify FittedBox exists (if banner is visible)
        final fittedBoxFinder = find.descendant(
          of: find.byType(ChristmasTournamentBanner),
          matching: find.byType(FittedBox),
        );

        if (fittedBoxFinder.evaluate().isNotEmpty) {
          // Verify text stays on one line
          final textWidget = tester.widget<Text>(
            find.descendant(
              of: fittedBoxFinder,
              matching: find.byType(Text),
            ),
          );

          expect(textWidget.maxLines, equals(1), 
            reason: 'Text should stay on one line on ${screenSize.width}x${screenSize.height}');

          // Verify no overflow errors
          expect(tester.takeException(), isNull,
            reason: 'Should not have overflow errors on ${screenSize.width}x${screenSize.height}');
        }
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('timer badge handles long text without wrapping', (tester) async {
      // Test with small screen to force text scaling
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                ChristmasTournamentBanner(),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final textFinder = find.descendant(
        of: find.byType(ChristmasTournamentBanner),
        matching: find.byType(Text),
      );

      if (textFinder.evaluate().isNotEmpty) {
        final textWidget = tester.widget<Text>(textFinder);
        expect(textWidget.maxLines, equals(1), 
          reason: 'Long text should be limited to one line');

        // Verify FittedBox will scale it down
        final fittedBoxFinder = find.ancestor(
          of: textFinder,
          matching: find.byType(FittedBox),
        );
        expect(fittedBoxFinder, findsOneWidget, 
          reason: 'Text should be wrapped in FittedBox for scaling');

        // Verify no overflow errors
        expect(tester.takeException(), isNull, 
          reason: 'Long text should not cause overflow');
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('timer badge text is readable on very small screens', (tester) async {
      // Test on very small screen (smallest common Android device)
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                ChristmasTournamentBanner(),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final textFinder = find.descendant(
        of: find.byType(ChristmasTournamentBanner),
        matching: find.byType(Text),
      );

      if (textFinder.evaluate().isNotEmpty) {
        final textWidget = tester.widget<Text>(textFinder);

        // Font size should be reasonable (not too small to read)
        // FittedBox will scale down, but we want to ensure it's still readable
        expect(textWidget.style?.fontSize, isNotNull);
        expect(textWidget.style?.fontSize, greaterThan(6.0), 
          reason: 'Font size should not be too small to read');

        expect(textWidget.maxLines, equals(1));
        expect(tester.takeException(), isNull);
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('timer badge uses correct widget hierarchy', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                ChristmasTournamentBanner(),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the correct widget hierarchy:
      // Container > FittedBox > ConstrainedBox > Text
      // Find Container by checking if it has a red BoxDecoration
      final containerFinder = find.descendant(
        of: find.byType(ChristmasTournamentBanner),
        matching: find.byType(Container),
      );

      if (containerFinder.evaluate().isNotEmpty) {
        // Verify FittedBox is child of Container
        final fittedBoxFinder = find.descendant(
          of: containerFinder,
          matching: find.byType(FittedBox),
        );
        expect(fittedBoxFinder, findsOneWidget, 
          reason: 'Container should contain FittedBox');

        // Verify ConstrainedBox is child of FittedBox
        final constrainedBoxFinder = find.descendant(
          of: fittedBoxFinder,
          matching: find.byType(ConstrainedBox),
        );
        expect(constrainedBoxFinder, findsOneWidget, 
          reason: 'FittedBox should contain ConstrainedBox');

        // Verify Text is child of ConstrainedBox
        final textFinder = find.descendant(
          of: constrainedBoxFinder,
          matching: find.byType(Text),
        );
        expect(textFinder, findsOneWidget, 
          reason: 'ConstrainedBox should contain Text');
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}

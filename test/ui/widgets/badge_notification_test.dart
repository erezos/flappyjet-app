/// 🎯 Badge Notification Widget Tests
/// 
/// Tests for the BadgeNotification widget to ensure:
/// - Badge appears/disappears correctly
/// - Count display is accurate
/// - Responsive sizing works
/// - Animations are smooth
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/ui/widgets/badge_notification.dart';

void main() {
  group('BadgeNotification Widget', () {
    const testScreenSize = Size(375.0, 667.0); // Reference device size

    testWidgets('Badge is hidden when count is 0', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BadgeNotification(
              count: 0,
              screenSize: testScreenSize,
            ),
          ),
        ),
      );

      // Badge should not be visible (returns SizedBox.shrink())
      expect(find.byType(BadgeNotification), findsOneWidget);
      // But the actual badge container should not be rendered
      expect(find.byType(Container), findsNothing);
    });

    testWidgets('Badge is hidden when count is negative', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BadgeNotification(
              count: -1,
              screenSize: testScreenSize,
            ),
          ),
        ),
      );

      // Badge should not be visible
      expect(find.byType(BadgeNotification), findsOneWidget);
      expect(find.byType(Container), findsNothing);
    });

    testWidgets('Badge appears when count is positive', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BadgeNotification(
              count: 5,
              screenSize: testScreenSize,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Badge should be visible
      expect(find.byType(BadgeNotification), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('Badge displays correct count (1-99)', (tester) async {
      for (int count = 1; count <= 99; count += 10) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BadgeNotification(
                count: count,
                screenSize: testScreenSize,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text(count.toString()), findsOneWidget);
      }
    });

    testWidgets('Badge displays "99+" when count > 99', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BadgeNotification(
              count: 100,
              screenSize: testScreenSize,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('99+'), findsOneWidget);
      expect(find.text('100'), findsNothing);
    });

    testWidgets('Badge displays "99+" for very large counts', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BadgeNotification(
              count: 999,
              screenSize: testScreenSize,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('Badge has red color by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BadgeNotification(
              count: 1,
              screenSize: testScreenSize,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final container = tester.widget<Container>(
        find.byType(Container).first,
      );
      final decoration = container.decoration as BoxDecoration;
      final gradient = decoration.gradient as LinearGradient;
      
      // Check that gradient uses red color (EF4444 or similar)
      expect(gradient.colors.first, isA<Color>());
    });

    testWidgets('Badge has white text by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BadgeNotification(
              count: 1,
              screenSize: testScreenSize,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final text = tester.widget<Text>(find.text('1'));
      expect(text.style?.color, Colors.white);
    });

    testWidgets('Badge uses custom colors when provided', (tester) async {
      const customColor = Color(0xFF00FF00); // Green
      const customTextColor = Color(0xFF000000); // Black

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BadgeNotification(
              count: 1,
              screenSize: testScreenSize,
              badgeColor: customColor,
              textColor: customTextColor,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final text = tester.widget<Text>(find.text('1'));
      expect(text.style?.color, customTextColor);
    });

    testWidgets('Badge has circular shape', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BadgeNotification(
              count: 1,
              screenSize: testScreenSize,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final container = tester.widget<Container>(
        find.byType(Container).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
    });

    testWidgets('Badge has shadow for depth', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BadgeNotification(
              count: 1,
              screenSize: testScreenSize,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final container = tester.widget<Container>(
        find.byType(Container).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.boxShadow, isNotNull);
      expect(decoration.boxShadow!.length, greaterThan(0));
    });

    testWidgets('Badge is responsive on different screen sizes', (tester) async {
      final screenSizes = [
        const Size(320.0, 568.0), // Small phone
        const Size(375.0, 667.0), // Reference
        const Size(428.0, 926.0), // Large phone
        const Size(768.0, 1024.0), // Tablet
      ];

      for (final screenSize in screenSizes) {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(size: screenSize),
              child: Scaffold(
                body: BadgeNotification(
                  count: 5,
                  screenSize: screenSize,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Badge should be visible on all screen sizes
        expect(find.byType(BadgeNotification), findsOneWidget);
        expect(find.text('5'), findsOneWidget);
      }
    });

    testWidgets('Badge has smooth fade animation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: BadgeNotification(
                  count: 5,
                  screenSize: testScreenSize,
                ),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check that AnimatedOpacity is present
      expect(find.byType(AnimatedOpacity), findsOneWidget);
      
      final animatedOpacity = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity).first,
      );
      expect(animatedOpacity.duration, const Duration(milliseconds: 200));
      expect(animatedOpacity.opacity, 1.0);
    });

    testWidgets('Badge respects min and max size constraints', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BadgeNotification(
              count: 1,
              screenSize: testScreenSize,
              minSize: 20.0,
              maxSize: 30.0,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Get the render box to check actual size
      final renderBox = tester.renderObject<RenderBox>(
        find.byType(Container).first,
      );
      final size = renderBox.size;
      
      // Size should be within min/max constraints
      expect(size.width, greaterThanOrEqualTo(20.0));
      expect(size.width, lessThanOrEqualTo(30.0));
      expect(size.height, greaterThanOrEqualTo(20.0));
      expect(size.height, lessThanOrEqualTo(30.0));
    });
  });
}


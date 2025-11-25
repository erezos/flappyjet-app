/// 🧪 Tests for LevelFailedScreen responsive design
/// 
/// Verifies:
/// - X button is positioned on popup frame (not inside)
/// - Responsive sizing works across different screen sizes
/// - Touch targets meet accessibility standards (44x44 minimum)
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/ui/screens/level_failed_screen.dart';
import 'package:flappy_jet_pro/models/level_data_schema.dart';
import 'package:flappy_jet_pro/ui/utils/responsive_config.dart';

/// Helper to create a test level
LevelData _createTestLevel({
  String name = 'Test Level',
  int target = 10,
}) {
  return LevelData(
    id: 1,
    zone: 1,
    name: name,
    objective: LevelObjective(
      type: ObjectiveType.passObstacles,
      target: target,
      description: 'Pass $target obstacles',
    ),
    difficulty: const DifficultyConfig(
      speedMultiplier: 1.0,
      obstacleGap: 200.0,
      obstacleFrequency: 2.0,
    ),
    reward: const LevelReward(
      coins: 50,
      gems: 0,
    ),
    theme: const LevelTheme(
      background: 'peaceful_sky.png',
      obstacles: 'wooden_pipes.png',
      music: 'sky_rookie.mp3',
    ),
  );
}

void main() {
  group('LevelFailedScreen Responsive Design', () {
    testWidgets('X button is positioned on popup frame (outside container)', (WidgetTester tester) async {
      final testLevel = _createTestLevel();

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelFailedScreen(
              level: testLevel,
              objectiveAchieved: 5,
              objectiveTarget: 10,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the X button (close icon)
      final closeButton = find.byIcon(Icons.close_rounded);
      expect(closeButton, findsOneWidget);

      // Get the button's render object
      final RenderBox? buttonBox = tester.renderObject(closeButton) as RenderBox?;
      expect(buttonBox, isNotNull);
      final buttonPosition = buttonBox!.localToGlobal(Offset.zero);
      final buttonSize = buttonBox.size;

      // Find the popup container (the one with gradient decoration)
      final containerFinder = find.descendant(
        of: find.byType(LevelFailedScreen),
        matching: find.byType(Container),
      ).first;
      final RenderBox? containerBox = tester.renderObject(containerFinder) as RenderBox?;
      expect(containerBox, isNotNull);
      final containerPosition = containerBox!.localToGlobal(Offset.zero);
      final containerSize = containerBox.size;

      // ✅ Verify X button is positioned on the frame (half outside)
      // Top-right corner of container
      final containerTopRight = Offset(
        containerPosition.dx + containerSize.width,
        containerPosition.dy,
      );

      // Button center should be at or near the container's top-right corner
      final buttonCenter = Offset(
        buttonPosition.dx + buttonSize.width / 2,
        buttonPosition.dy + buttonSize.height / 2,
      );

      // Allow small tolerance for positioning
      expect(
        (buttonCenter.dx - containerTopRight.dx).abs(),
        lessThan(buttonSize.width / 2 + 5), // Half button width + tolerance
      );
      expect(
        (buttonCenter.dy - containerTopRight.dy).abs(),
        lessThan(buttonSize.height / 2 + 5), // Half button height + tolerance
      );
    });

    testWidgets('X button has minimum touch target size (44x44)', (WidgetTester tester) async {
      final testLevel = _createTestLevel();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelFailedScreen(
              level: testLevel,
              objectiveAchieved: 5,
              objectiveTarget: 10,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final closeButton = find.byIcon(Icons.close_rounded);
      expect(closeButton, findsOneWidget);

      final RenderBox? buttonBox = tester.renderObject(closeButton) as RenderBox?;
      expect(buttonBox, isNotNull);
      final buttonSize = buttonBox!.size;

      // ✅ Verify minimum touch target size (accessibility standard)
      expect(buttonSize.width, greaterThanOrEqualTo(44.0));
      expect(buttonSize.height, greaterThanOrEqualTo(44.0));
    });

    testWidgets('Popup scales responsively on different screen sizes', (WidgetTester tester) async {
      final testLevel = _createTestLevel();

      // Test on small screen (iPhone SE)
      await tester.binding.setSurfaceSize(const Size(375, 667));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelFailedScreen(
              level: testLevel,
              objectiveAchieved: 5,
              objectiveTarget: 10,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final smallScreenButton = find.byIcon(Icons.close_rounded);
      expect(smallScreenButton, findsOneWidget);
      final smallScreenButtonBox = tester.renderObject(smallScreenButton) as RenderBox;
      final smallScreenButtonSize = smallScreenButtonBox.size;

      // Test on large screen (iPad)
      await tester.binding.setSurfaceSize(const Size(1024, 1366));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelFailedScreen(
              level: testLevel,
              objectiveAchieved: 5,
              objectiveTarget: 10,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final largeScreenButton = find.byIcon(Icons.close_rounded);
      expect(largeScreenButton, findsOneWidget);
      final largeScreenButtonBox = tester.renderObject(largeScreenButton) as RenderBox;
      final largeScreenButtonSize = largeScreenButtonBox.size;

      // ✅ Verify button scales responsively (but within bounds)
      // Should be larger on larger screens, but clamped to max
      expect(largeScreenButtonSize.width, greaterThanOrEqualTo(smallScreenButtonSize.width));
      expect(largeScreenButtonSize.width, lessThanOrEqualTo(56.0)); // Max size
      expect(largeScreenButtonSize.height, lessThanOrEqualTo(56.0)); // Max size
    });

    testWidgets('X button is tappable', (WidgetTester tester) async {
      final testLevel = _createTestLevel();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return LevelFailedScreen(
                  level: testLevel,
                  objectiveAchieved: 5,
                  objectiveTarget: 10,
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final closeButton = find.byIcon(Icons.close_rounded);
      expect(closeButton, findsOneWidget);

      // ✅ Verify button is tappable (no exception thrown)
      await tester.tap(closeButton);
      await tester.pumpAndSettle();
      
      // Button should still exist (navigation might not complete in test)
      // But we verify no exceptions were thrown
      expect(tester.takeException(), isNull);
    });

    testWidgets('Popup content does not overflow on small screens', (WidgetTester tester) async {
      final testLevel = _createTestLevel(
        name: 'Very Long Level Name That Might Cause Overflow',
        target: 100,
      );

      // Test on small screen
      await tester.binding.setSurfaceSize(const Size(320, 568)); // iPhone SE
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelFailedScreen(
              level: testLevel,
              objectiveAchieved: 50,
              objectiveTarget: 100,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // ✅ Verify no overflow errors
      expect(tester.takeException(), isNull);
    });
  });
}


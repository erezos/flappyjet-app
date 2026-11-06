/// Tests for LevelCompleteScreen disposal fixes
/// 
/// Tests the fixes for:
/// 1. Ticker disposal - ensuring all AnimationControllers are properly stopped and disposed
/// 2. Overlay removal - ensuring overlays are safely removed even after widget disposal
/// Follows Flutter best practices and mobile gaming standards.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flappy_jet_pro/ui/screens/level_complete_screen.dart';
import 'package:flappy_jet_pro/models/level_data_schema.dart';
import '../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LevelCompleteScreen - Disposal Fixes', () {
    testWidgets('dispose() stops all animation controllers before disposal', (tester) async {
      // Arrange: Create a level complete screen
      final level = TestHelpers.createTestLevel(
        id: 1,
        zone: 1,
        type: ObjectiveType.passObstacles,
        target: 10,
      );

      final screen = LevelCompleteScreen(
        level: level,
        objectiveAchieved: 10,
        timeTaken: 30,
        continuesUsed: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: screen,
          ),
        ),
      );

      await tester.pump();

      // Act: Dispose the widget
      // This should stop all animation controllers before disposing them
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(),
          ),
        ),
      );

      await tester.pump();

      // Assert: No ticker disposal errors should occur
      // (Test passes if no exception is thrown)
    });

    testWidgets('overlay removal checks mounted state before removing', (tester) async {
      // Arrange: Create a level complete screen
      final level = TestHelpers.createTestLevel(
        id: 1,
        zone: 1,
        type: ObjectiveType.passObstacles,
        target: 10,
      );

      final screen = LevelCompleteScreen(
        level: level,
        objectiveAchieved: 10,
        timeTaken: 30,
        continuesUsed: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: screen,
          ),
        ),
      );

      await tester.pump();

      // Act: Dispose the widget immediately (before overlays are removed)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(),
          ),
        ),
      );

      // Wait for any delayed overlay removal callbacks
      await tester.pump(const Duration(milliseconds: 2000));

      // Assert: No overlay removal errors should occur
      // (Test passes if no exception is thrown)
    });

    testWidgets('dispose() handles overlay removal errors gracefully', (tester) async {
      // Arrange: Create a level complete screen
      final level = TestHelpers.createTestLevel(
        id: 1,
        zone: 1,
        type: ObjectiveType.passObstacles,
        target: 10,
      );

      final screen = LevelCompleteScreen(
        level: level,
        objectiveAchieved: 10,
        timeTaken: 30,
        continuesUsed: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: screen,
          ),
        ),
      );

      await tester.pump();

      // Act: Dispose the widget
      // Even if overlay removal fails, it should be caught and handled
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(),
          ),
        ),
      );

      await tester.pump();

      // Assert: Should not throw exception
      // (Test passes if no exception is thrown)
    });
  });
}


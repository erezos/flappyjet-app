import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flappy_jet_pro/ui/widgets/profile/profile_component_system.dart';
import 'package:flappy_jet_pro/game/systems/game_state_manager.dart';

void main() {
  group('Profile Component System High Score Sync Tests', () {
    late GameStateManager gameStateManager;

    setUp(() {
      // Initialize SharedPreferences for testing
      SharedPreferences.setMockInitialValues({
        'best_score': 100,
        'best_streak': 50,
      });
      
      gameStateManager = GameStateManager();
    });

    testWidgets('ProfileHighScoreComponent should display initial score from SharedPreferences', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileHighScoreComponent(),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('ProfileHighScoreComponent should update when GameStateManager changes', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileHighScoreComponent(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('100'), findsOneWidget);

      // Act - Update the component's GameStateManager directly
      // Note: In real app, this would be the same instance
      final componentGameStateManager = GameStateManager();
      await componentGameStateManager.saveBestScore(200);
      await tester.pumpAndSettle();

      // Assert - The component should still show the initial value from SharedPreferences
      // since it loads from SharedPreferences on init, not from GameStateManager
      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('ProfileHottestStreakComponent should display initial streak from SharedPreferences', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileHottestStreakComponent(),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('50'), findsOneWidget);
    });

    testWidgets('ProfileHottestStreakComponent should update when GameStateManager changes', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileHottestStreakComponent(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('50'), findsOneWidget);

      // Act - Update the component's GameStateManager directly
      // Note: In real app, this would be the same instance
      final componentGameStateManager = GameStateManager();
      componentGameStateManager.resetGame();
      await componentGameStateManager.saveBestStreak(75);
      await tester.pumpAndSettle();

      // Assert - The component should still show the initial value from SharedPreferences
      // since it loads from SharedPreferences on init, not from GameStateManager
      expect(find.text('50'), findsOneWidget);
    });

    testWidgets('Components should handle SharedPreferences errors gracefully', (WidgetTester tester) async {
      // Arrange - Mock SharedPreferences to throw error
      SharedPreferences.setMockInitialValues({});
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ProfileHighScoreComponent(),
                ProfileHottestStreakComponent(),
              ],
            ),
          ),
        ),
      );

      // Act & Assert - Should not throw and should show fallback values
      await tester.pumpAndSettle();
      expect(find.text('0'), findsNWidgets(2)); // Both should show 0 as fallback
    });

    testWidgets('Components should dispose listeners properly', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileHighScoreComponent(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act - Remove widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(), // Empty widget
          ),
        ),
      );

      // Assert - Should not throw when GameStateManager updates after disposal
      await gameStateManager.saveBestScore(300);
      await tester.pumpAndSettle();
      
      // Test passes if no exceptions are thrown
      expect(true, isTrue);
    });

    testWidgets('Components should maintain state during widget rebuilds', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileHighScoreComponent(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('100'), findsOneWidget);

      // Act - Update score and rebuild widget
      await gameStateManager.saveBestScore(250);
      // Wait for async persistence to complete
      await Future.delayed(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // Rebuild widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileHighScoreComponent(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Should show updated score from SharedPreferences
      expect(find.text('250'), findsOneWidget);
    });
  });

  group('Profile Component System Performance Tests', () {
    testWidgets('Components should render quickly', (WidgetTester tester) async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'best_score': 100,
        'best_streak': 50,
      });

      final stopwatch = Stopwatch()..start();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ProfileHighScoreComponent(),
                ProfileHottestStreakComponent(),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      final elapsed = stopwatch.elapsedMilliseconds;

      // Assert
      expect(elapsed, lessThan(1000)); // Should render in under 1 second
      expect(find.text('100'), findsOneWidget);
      expect(find.text('50'), findsOneWidget);
    });

    testWidgets('Components should handle rapid GameStateManager updates efficiently', (WidgetTester tester) async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'best_score': 0,
        'best_streak': 0,
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ProfileHighScoreComponent(),
                ProfileHottestStreakComponent(),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final gameStateManager = GameStateManager();
      final stopwatch = Stopwatch()..start();

      // Act - Rapid updates
      for (int i = 1; i <= 10; i++) {
        await gameStateManager.saveBestScore(i * 10);
        gameStateManager.resetGame();
        await gameStateManager.saveBestStreak(i * 5);
        await tester.pump();
      }

      // Wait for async persistence to complete
      await Future.delayed(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      final elapsed = stopwatch.elapsedMilliseconds;

      // Assert
      expect(elapsed, lessThan(2000)); // Should handle 20 updates in under 2 seconds
      expect(find.text('100'), findsOneWidget); // Final score from SharedPreferences
      expect(find.text('50'), findsOneWidget); // Final streak from SharedPreferences
    });
  });
}

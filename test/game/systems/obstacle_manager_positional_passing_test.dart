/// 🎯 Zone 1 Positional Passing Tests
/// 
/// Tests for the Zone 1 positional passing feature:
/// - Obstacles are correctly identified when positionally passed
/// - Unscored obstacles are correctly identified
/// - No double scoring occurs
/// 
/// ✅ PERFORMANCE: Uses event-driven approach (check on crash, not every frame)
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:flappy_jet_pro/game/systems/obstacle_manager.dart';
import 'package:flappy_jet_pro/game/components/dynamic_obstacle.dart';
import 'package:flappy_jet_pro/game/core/game_config.dart';
import 'package:flappy_jet_pro/game/core/game_themes.dart';

void main() {
  group('ObstacleManager Positional Passing (Event-Driven)', () {
    late ObstacleManager manager;
    late Size gameSize;
    late GameTheme theme;

    setUp(() {
      manager = ObstacleManager();
      gameSize = Size(400, 600); // Match existing test setup
      theme = GameThemes.skyRookie;
    });

    test('getPositionallyPassedButUnscored detects obstacles when jet passes right edge', () {
      // Spawn an obstacle using update (same as real game)
      manager.update(2.0, 0, gameSize, theme);
      
      // If obstacles didn't spawn, try with longer time or check spawn interval
      if (manager.obstacles.isEmpty) {
        // Try with longer time to ensure spawn interval is met
        manager.update(5.0, 0, gameSize, theme);
      }
      
      expect(manager.obstacles, isNotEmpty, reason: 'Obstacle should be spawned after update');
      final spawnedObstacle = manager.obstacles.first;
      
      // Obstacles spawn at screen width (375), so right edge is at 375 + obstacleWidth (~510)
      final obstacleRightEdge = spawnedObstacle.position.x + GameConfig.obstacleWidth;
      expect(spawnedObstacle.position.x, equals(gameSize.width), reason: 'Obstacle should spawn at screen width');
      expect(spawnedObstacle.scored, isFalse, reason: 'Obstacle should not be scored initially');

      // Jet is before obstacle right edge (at x=100, which is before ~510)
      final beforeObstacle = Vector2(100, 300);
      final passed1 = manager.getPositionallyPassedButUnscored(beforeObstacle);
      expect(passed1, isEmpty, reason: 'Jet before obstacle should not pass');

      // Jet is exactly at obstacle right edge (should not count)
      final atRightEdge = Vector2(obstacleRightEdge, 300);
      final passed2 = manager.getPositionallyPassedButUnscored(atRightEdge);
      expect(passed2, isEmpty, reason: 'Jet exactly at edge should not pass');

      // Jet is past obstacle right edge (x > obstacleRightEdge)
      // Use a position well past the obstacle (e.g., 600 which is > 375 + ~135)
      final pastObstacle = Vector2(obstacleRightEdge + 10, 300);
      final passed3 = manager.getPositionallyPassedButUnscored(pastObstacle);
      expect(passed3, isNotEmpty, reason: 'Should find at least one passed obstacle');
      expect(passed3, contains(spawnedObstacle), reason: 'Jet past obstacle should pass');
    });

    test('getPositionallyPassedButUnscored excludes already scored obstacles', () {
      // Spawn an obstacle
      manager.update(2.0, 0, gameSize, theme);
      expect(manager.obstacles, isNotEmpty);
      final obstacle = manager.obstacles.first;
      final obstacleRightEdge = obstacle.position.x + GameConfig.obstacleWidth;

      // Mark obstacle as scored (via gap)
      obstacle.scored = true;

      // Jet is past obstacle right edge (well past, e.g., 600)
      final pastObstacle = Vector2(obstacleRightEdge + 10, 300);
      final passed = manager.getPositionallyPassedButUnscored(pastObstacle);
      
      // Should not be in list (already scored)
      expect(passed, isNot(contains(obstacle)), reason: 'Already scored obstacle should not be returned');
    });

    test('getPositionallyPassedButUnscored excludes obstacles scored via ScoreZone', () {
      // Spawn an obstacle
      manager.update(2.0, 0, gameSize, theme);
      expect(manager.obstacles, isNotEmpty);
      final obstacle = manager.obstacles.first;
      final obstacleRightEdge = obstacle.position.x + GameConfig.obstacleWidth;

      // Simulate ScoreZone scoring (mark obstacle as scored)
      obstacle.scored = true;

      // Jet is past obstacle right edge (well past)
      final pastObstacle = Vector2(obstacleRightEdge + 10, 300);
      final passed = manager.getPositionallyPassedButUnscored(pastObstacle);
      
      // Should not be in list (scored via ScoreZone)
      expect(passed, isNot(contains(obstacle)), reason: 'Scored via ScoreZone should not be returned');
    });

    test('getPositionallyPassedButUnscored returns multiple unscored obstacles', () {
      // Spawn multiple obstacles
      manager.update(2.0, 0, gameSize, theme);
      expect(manager.obstacles, isNotEmpty);
      final obstacle1 = manager.obstacles.first;
      final obstacle1RightEdge = obstacle1.position.x + GameConfig.obstacleWidth;

      manager.update(2.0, 0, gameSize, theme);
      expect(manager.obstacles.length, greaterThanOrEqualTo(2));
      final obstacle2 = manager.obstacles[1];
      final obstacle2RightEdge = obstacle2.position.x + GameConfig.obstacleWidth;

      manager.update(2.0, 0, gameSize, theme);
      expect(manager.obstacles.length, greaterThanOrEqualTo(3));
      final obstacle3 = manager.obstacles[2];
      final obstacle3RightEdge = obstacle3.position.x + GameConfig.obstacleWidth;

      // Jet is past all three obstacles (use a position well past all of them)
      final maxRightEdge = [obstacle1RightEdge, obstacle2RightEdge, obstacle3RightEdge]
          .reduce((a, b) => a > b ? a : b);
      final pastAll = Vector2(maxRightEdge + 10, 300);
      final passed = manager.getPositionallyPassedButUnscored(pastAll);
      
      // Should contain all three (if they're all unscored)
      expect(passed.length, greaterThanOrEqualTo(3));
      expect(passed, contains(obstacle1));
      expect(passed, contains(obstacle2));
      expect(passed, contains(obstacle3));
    });

    test('getPositionallyPassedButUnscored only returns obstacles that are actually passed', () {
      // Spawn two obstacles
      manager.update(2.0, 0, gameSize, theme);
      expect(manager.obstacles, isNotEmpty);
      final obstacle1 = manager.obstacles.first;
      final obstacle1RightEdge = obstacle1.position.x + GameConfig.obstacleWidth;

      manager.update(2.0, 0, gameSize, theme);
      expect(manager.obstacles.length, greaterThanOrEqualTo(2));
      final obstacle2 = manager.obstacles[1];
      final obstacle2RightEdge = obstacle2.position.x + GameConfig.obstacleWidth;

      // Jet is past first obstacle but not second
      // Position between the two obstacles
      final betweenObstacles = Vector2(obstacle1RightEdge + 10, 300);
      final passed = manager.getPositionallyPassedButUnscored(betweenObstacles);
      
      // Should only contain first obstacle (if jet is past it but not past second)
      // Note: If obstacles spawn close together, both might be passed
      // So we check that at least obstacle1 is passed
      expect(passed, contains(obstacle1));
      
      // If jet is not past obstacle2, it shouldn't be in the list
      if (betweenObstacles.x <= obstacle2RightEdge) {
        expect(passed, isNot(contains(obstacle2)));
      }
    });

    test('getPositionallyPassedButUnscored works correctly with moving obstacles', () {
      // Spawn an obstacle
      manager.update(2.0, 0, gameSize, theme);
      expect(manager.obstacles, isNotEmpty);
      final obstacle = manager.obstacles.first;
      final initialRightEdge = obstacle.position.x + GameConfig.obstacleWidth;

      // Jet is before obstacle (at x=100, which is before obstacle at x=375)
      final beforeObstacle = Vector2(100, 300);
      expect(manager.getPositionallyPassedButUnscored(beforeObstacle), isEmpty);

      // Move obstacle left (simulate movement) - move it to x=200
      obstacle.position.x = 200;
      final newRightEdge = obstacle.position.x + GameConfig.obstacleWidth;

      // Jet is now past obstacle (obstacle moved left, jet at x=400 is past it)
      final pastObstacle = Vector2(newRightEdge + 10, 300);
      final passed = manager.getPositionallyPassedButUnscored(pastObstacle);
      
      // Should detect obstacle as passed
      expect(passed, contains(obstacle));
    });

    test('getPositionallyPassedButUnscored returns empty list when no obstacles exist', () {
      // No obstacles spawned
      expect(manager.obstacles, isEmpty);

      // Check with any jet position
      final jetPosition = Vector2(100, 300);
      final passed = manager.getPositionallyPassedButUnscored(jetPosition);
      
      expect(passed, isEmpty);
    });

    test('getPositionallyPassedButUnscored handles edge case at exact right edge', () {
      // Spawn an obstacle
      manager.update(2.0, 0, gameSize, theme);
      expect(manager.obstacles, isNotEmpty);
      final obstacle = manager.obstacles.first;
      final obstacleRightEdge = obstacle.position.x + GameConfig.obstacleWidth;

      // Jet is exactly at right edge (should not count)
      final exactlyAtEdge = Vector2(obstacleRightEdge, 300);
      final passed = manager.getPositionallyPassedButUnscored(exactlyAtEdge);
      
      expect(passed, isEmpty, reason: 'Exactly at edge should not count as passed');
      
      // Jet is just past right edge (should count)
      final justPastEdge = Vector2(obstacleRightEdge + 0.1, 300);
      final passed2 = manager.getPositionallyPassedButUnscored(justPastEdge);
      
      expect(passed2, contains(obstacle), reason: 'Just past edge should count as passed');
    });
  });
}

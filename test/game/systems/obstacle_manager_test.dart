import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:flappy_jet_pro/game/systems/obstacle_manager.dart';
import 'package:flappy_jet_pro/game/components/dynamic_obstacle.dart';
import 'package:flappy_jet_pro/game/core/game_themes.dart';

void main() {
  group('ObstacleManager', () {
    late ObstacleManager obstacleManager;
    late Size gameSize;
    late GameTheme currentTheme;

    setUp(() {
      obstacleManager = ObstacleManager();
      gameSize = Size(400, 600);
      currentTheme = GameThemes.skyRookie;
    });

    test('should initialize with empty obstacles list', () {
      expect(obstacleManager.obstacles, isEmpty);
      expect(obstacleManager.timeSinceLastObstacle, 0.0);
    });

    test('should spawn obstacles based on score and time', () {
      // Update with enough time to trigger spawn
      obstacleManager.update(2.0, 0, gameSize, currentTheme);
      
      expect(obstacleManager.obstacles, isNotEmpty);
      expect(obstacleManager.timeSinceLastObstacle, 0.0); // Should reset after spawn
    });

    test('should not spawn obstacles too quickly', () {
      // Update with insufficient time
      obstacleManager.update(0.1, 0, gameSize, currentTheme);
      
      expect(obstacleManager.obstacles, isEmpty);
      expect(obstacleManager.timeSinceLastObstacle, 0.1);
    });

    test('should spawn obstacles with correct properties', () {
      obstacleManager.update(2.0, 0, gameSize, currentTheme);
      
      expect(obstacleManager.obstacles.length, 1);
      
      final obstacle = obstacleManager.obstacles.first;
      expect(obstacle.position.x, gameSize.width); // Should start at right edge
      expect(obstacle.position.y, greaterThan(0));
      expect(obstacle.position.y, lessThan(gameSize.height));
      expect(obstacle.gapSize, greaterThan(0));
      expect(obstacle.speed, greaterThan(0));
      expect(obstacle.scored, false);
    });

    test('should update existing obstacles', () {
      obstacleManager.update(2.0, 0, gameSize, currentTheme);
      final initialX = obstacleManager.obstacles.first.position.x;
      
      // Update obstacles
      obstacleManager.update(0.1, 0, gameSize, currentTheme);
      
      expect(obstacleManager.obstacles.first.position.x, lessThan(initialX));
    });

    test('should remove off-screen obstacles', () {
      obstacleManager.update(2.0, 0, gameSize, currentTheme);
      expect(obstacleManager.obstacles, isNotEmpty);
      
      // Move obstacle off-screen and update
      obstacleManager.obstacles.first.position.x = -200;
      obstacleManager.update(0.1, 0, gameSize, currentTheme);
      
      expect(obstacleManager.obstacles, isEmpty);
    });

    test('should detect scoring correctly', () {
      obstacleManager.update(2.0, 0, gameSize, currentTheme);
      final obstacle = obstacleManager.obstacles.first;
      
      // Position jet past the obstacle
      final jetPosition = Vector2(obstacle.position.x + 100, 200);
      
      final scoredObstacles = obstacleManager.checkScoring(jetPosition);
      
      expect(scoredObstacles.length, 1);
      expect(scoredObstacles.first.scored, true);
    });

    test('should not score same obstacle twice', () {
      obstacleManager.update(2.0, 0, gameSize, currentTheme);
      final obstacle = obstacleManager.obstacles.first;
      
      // Score the obstacle
      final jetPosition = Vector2(obstacle.position.x + 100, 200);
      obstacleManager.checkScoring(jetPosition);
      
      // Try to score again
      final scoredObstacles = obstacleManager.checkScoring(jetPosition);
      
      expect(scoredObstacles, isEmpty);
    });

    test('should clear all obstacles', () {
      obstacleManager.update(2.0, 0, gameSize, currentTheme);
      expect(obstacleManager.obstacles, isNotEmpty);
      
      obstacleManager.clearObstacles();
      
      expect(obstacleManager.obstacles, isEmpty);
      expect(obstacleManager.timeSinceLastObstacle, 0.0);
    });

    test('should provide obstacle statistics', () {
      obstacleManager.update(2.0, 0, gameSize, currentTheme);
      
      final stats = obstacleManager.getObstacleStats();
      
      expect(stats['total_obstacles'], 1);
      expect(stats['time_since_last_spawn'], 0.0);
      expect(stats['obstacles_on_screen'], 1);
      expect(stats['obstacles_scored'], 0);
    });

    test('should handle different scores correctly', () {
      // Test with different scores to verify difficulty scaling
      obstacleManager.update(2.0, 0, gameSize, currentTheme);
      final lowScoreObstacle = obstacleManager.obstacles.first;
      
      obstacleManager.clearObstacles();
      
      obstacleManager.update(2.0, 50, gameSize, currentTheme);
      final highScoreObstacle = obstacleManager.obstacles.first;
      
      // Higher score should result in different obstacle properties
      expect(highScoreObstacle.gapSize, isNot(equals(lowScoreObstacle.gapSize)));
      expect(highScoreObstacle.speed, isNot(equals(lowScoreObstacle.speed)));
    });

    test('should handle multiple obstacles correctly', () {
      // Spawn multiple obstacles
      obstacleManager.update(2.0, 0, gameSize, currentTheme);
      obstacleManager.update(2.0, 0, gameSize, currentTheme);
      
      expect(obstacleManager.obstacles.length, 2);
      
      // Check that both obstacles are tracked correctly
      final stats = obstacleManager.getObstacleStats();
      expect(stats['total_obstacles'], 2);
    });

    test('should handle edge cases gracefully', () {
      // Test with very small game size
      final smallGameSize = Size(100, 100);
      
      obstacleManager.update(2.0, 0, smallGameSize, currentTheme);
      
      expect(obstacleManager.obstacles, isNotEmpty);
      final obstacle = obstacleManager.obstacles.first;
      expect(obstacle.position.y, greaterThan(0));
      expect(obstacle.position.y, lessThan(smallGameSize.height));
    });
  });
}

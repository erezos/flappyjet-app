import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../core/debug_logger.dart';
import '../core/game_config.dart';
import '../core/game_themes.dart';
import '../components/dynamic_obstacle.dart';
import 'difficulty_system.dart';

/// Manages obstacle spawning, updating, and cleanup
/// Separated from FlappyGame for better testability and maintainability
class ObstacleManager {
  final List<DynamicObstacle> _obstacles = [];
  double _timeSinceLastObstacle = 0.0;

  /// Get current obstacles list
  List<DynamicObstacle> get obstacles => List.unmodifiable(_obstacles);

  /// Get time since last obstacle spawn
  double get timeSinceLastObstacle => _timeSinceLastObstacle;

  /// Update obstacle manager
  void update(double dt, int score, Size gameSize, GameTheme currentTheme) {
    // Spawn obstacles based on difficulty
    _timeSinceLastObstacle += dt;
    final spawnInterval = GameConfig.getSpawnInterval(score);
    
    if (_timeSinceLastObstacle >= spawnInterval) {
      _spawnObstacle(gameSize, currentTheme, score);
      _timeSinceLastObstacle = 0.0;
    }

    // Update obstacles
    for (final obstacle in _obstacles) {
      obstacle.update(dt);
    }

    // Remove off-screen obstacles
    _obstacles.removeWhere((obstacle) {
      if (obstacle.position.x < -100) {
        obstacle.removeFromParent();
        return true;
      }
      return false;
    });
  }

  /// Spawn a new obstacle
  void _spawnObstacle(Size gameSize, GameTheme currentTheme, int score) {
    // 🎯 Continuous difficulty curves + micro-variance + breathers/assist
    final screenH = gameSize.height;
    double gap = DifficultySystem.getGapRatioContinuous(score) * screenH;
    double speed = DifficultySystem.getBaseSpeedContinuous(score);

    // FTUE beginner preset for first 3 spawns (forgiving)
    if (score < 3) {
      gap *= 1.20;
      speed *= 0.90;
    }

    // Assist: if two deaths before score 3 (tracked via best score and current? simple heuristic)
    // Heuristic: if bestScore < 3 and _score < 3, apply assist for first 3 spawns
    if (score < 3) { // Simplified - apply assist for first 3 spawns
      gap *= 1.15;
      speed *= 0.90;
    }

    // Breathers every 6th obstacle
    if ((score + 1) % 6 == 0) {
      gap *= 1.10;
    } else {
      // Rare spice 1 in 10
      if ((DateTime.now().millisecondsSinceEpoch ~/ 1000) % 10 == 0) {
        gap *= 0.95;
      }
    }

    // Micro-variance ±2–3%
    final rnd = (math.Random().nextDouble() * 0.06) - 0.03;
    gap *= (1.0 + rnd).clamp(0.97, 1.03);
    speed *= (1.0 - rnd).clamp(0.97, 1.03);

    // Clamp readability
    gap = gap.clamp(screenH * 0.28, screenH * 0.5);
    speed = speed.clamp(200.0, 400.0);
    final phase = DifficultySystem.getPhaseForScore(score);

    // Gap center distribution:
    // - Until score 25: fair band (35%–65% of screen height)
    // - After 25: full-range placement constrained only by gap size (no fairness band)
    double gapY;
    // Define fairness bands by score
    final bandMinRatio = score < 25 ? 0.35 : 0.25;
    final bandMaxRatio = score < 25 ? 0.65 : 0.75;
    // Convert to pixels
    double bandMin = gameSize.height * bandMinRatio;
    double bandMax = gameSize.height * bandMaxRatio;
    // Ensure band stays within legal centers given gap size
    final minCenterAllowed = gap / 2;
    final maxCenterAllowed = gameSize.height - gap / 2;
    bandMin = math.max(bandMin, minCenterAllowed);
    bandMax = math.min(bandMax, maxCenterAllowed);
    if (bandMax <= bandMin) {
      // Fallback to safe center if band collapses (extreme gap sizes)
      gapY = (minCenterAllowed + maxCenterAllowed) * 0.5;
    } else {
      gapY = bandMin + math.Random().nextDouble() * (bandMax - bandMin);
    }

    final obstacle = DynamicObstacle(
      position: Vector2(gameSize.width, gapY),
      theme: currentTheme,
      gapSize: gap,
      speed: speed,
      currentScore: score,
    );
    obstacle.priority = 0; // FLAME PRIORITY: Obstacles render at base level (above background, below jet)
    
    _obstacles.add(obstacle);

    // 🎯 DEBUG: Show difficulty progression
    safePrint(
      '🎯 OBSTACLE: Score $score → ${phase.name} (gap: ${gap.toStringAsFixed(1)}, speed: ${speed.toStringAsFixed(1)})',
    );
  }

  /// Add obstacle to game (called from FlappyGame)
  void addObstacleToGame(DynamicObstacle obstacle, Component game) {
    game.add(obstacle);
  }

  /// Check scoring for obstacles
  /// Returns list of obstacles that were just scored
  List<DynamicObstacle> checkScoring(Vector2 jetPosition) {
    final scoredObstacles = <DynamicObstacle>[];
    
    for (final obstacle in _obstacles) {
      // Check scoring (🔥 FIXED: Use obstacle width to match collision detection exactly)
      final scoringThreshold = obstacle.position.x + GameConfig.obstacleWidth;
      if (!obstacle.scored && scoringThreshold < jetPosition.x) {
        obstacle.scored = true;
        scoredObstacles.add(obstacle);
        
        // 🎯 SCORING DEBUG: Log exact positions when scoring happens
        safePrint(
          '🎯 SCORING DEBUG: Jet at X=${jetPosition.x.toStringAsFixed(2)}, Obstacle right edge at X=${scoringThreshold.toStringAsFixed(2)}',
        );
        safePrint('🎯 SCORING DEBUG: Score triggered! Jet passed obstacle safely');
      }
    }
    
    return scoredObstacles;
  }

  /// Clear all obstacles
  void clearObstacles() {
    for (final obstacle in _obstacles) {
      obstacle.removeFromParent();
    }
    _obstacles.clear();
    _timeSinceLastObstacle = 0.0;
    safePrint('🗑️ All obstacles cleared');
  }

  /// Get obstacle statistics for debugging
  Map<String, dynamic> getObstacleStats() {
    return {
      'total_obstacles': _obstacles.length,
      'time_since_last_spawn': _timeSinceLastObstacle,
      'obstacles_on_screen': _obstacles.where((o) => o.position.x > -100).length,
      'obstacles_scored': _obstacles.where((o) => o.scored).length,
    };
  }
}

import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../core/debug_logger.dart';
import '../../models/tournament_config.dart'; // 🎪 TOURNAMENT: ObstaclePattern
import '../core/game_config.dart';
import '../core/game_themes.dart';
import '../components/dynamic_obstacle.dart';
import '../components/obstacle_movement_config.dart'; // 🎪 TOURNAMENT: Moving obstacles
import 'difficulty_system.dart';

/// Manages obstacle spawning, updating, and cleanup
/// Separated from FlappyGame for better testability and maintainability
/// 
/// 🎪 TOURNAMENT v2.3.0: Supports moving obstacle patterns
class ObstacleManager {
  final List<DynamicObstacle> _obstacles = [];
  double _timeSinceLastObstacle = 0.0;
  
  // 🎯 STORY MODE: Override obstacle asset path for story mode levels
  String? storyModeObstacleAsset;
  
  // 🎯 STORY MODE: Override difficulty settings for story mode levels
  double? storyModeObstacleFrequency;  // Seconds between obstacles
  double? storyModeObstacleGap;        // Gap size in pixels
  double? storyModeSpeedMultiplier;    // Speed multiplier
  double? storyModeMaxGapShift;        // Max vertical shift between gaps (pixels)
  
  // 🎪 TOURNAMENT: Pattern selector for moving obstacles
  ObstaclePatternSelector? patternSelector;
  
  // 🎯 STORY MODE: Track previous gap center for smooth path generation
  double? _previousGapCenterY;
  
  // 🎁 BONUS SYSTEM: Callback when obstacle spawns (for bonus spawning)
  void Function(double gapCenterY, double obstacleX, double gapSize, double speed)? onObstacleSpawned;

  // 🛑 PERFORMANCE FIX: Pause flag to stop spawning during victory animation
  bool _isPaused = false;
  
  // 🎯 ZONE 1: Positional passing tracking removed - using event-driven approach instead
  // We check obstacles on crash only, not every frame (better performance)
  
  /// Pause obstacle spawning (e.g., during victory animation)
  void pause() {
    _isPaused = true;
    safePrint('🛑 ObstacleManager: Spawning PAUSED');
  }
  
  /// Resume obstacle spawning
  void resume() {
    _isPaused = false;
    safePrint('▶️ ObstacleManager: Spawning RESUMED');
  }
  
  /// Check if spawning is paused
  bool get isPaused => _isPaused;

  /// Get current obstacles list
  List<DynamicObstacle> get obstacles => List.unmodifiable(_obstacles);

  /// Get time since last obstacle spawn
  double get timeSinceLastObstacle => _timeSinceLastObstacle;

  /// Update obstacle manager
  void update(double dt, int score, Size gameSize, GameTheme currentTheme) {
    // 🛑 PERFORMANCE FIX: Skip spawning if paused (but still update existing obstacles)
    if (_isPaused) {
      // Update existing obstacles (they still need to move)
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
      return;
    }
    
    // Spawn obstacles based on difficulty
    _timeSinceLastObstacle += dt;
    
    // 🎯 STORY MODE: Use story mode frequency if set, otherwise use score-based interval
    final spawnInterval = storyModeObstacleFrequency ?? GameConfig.getSpawnInterval(score);
    
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
    // 🎯 STORY MODE: Use story mode settings if available, otherwise use score-based difficulty
    final screenH = gameSize.height;
    double gap;
    double speed;
    
    if (storyModeObstacleGap != null && storyModeSpeedMultiplier != null) {
      // Story mode: Use fixed level settings
      gap = storyModeObstacleGap!;
      speed = DifficultySystem.getBaseObstacleSpeed() * storyModeSpeedMultiplier!;
      
    } else {
      // Endless mode: Use continuous difficulty curves + micro-variance + breathers/assist
      gap = DifficultySystem.getGapRatioContinuous(score) * screenH;
      speed = DifficultySystem.getBaseSpeedContinuous(score);

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
    }
    
    // Phase used for debugging - keep commented for reference
    // final phase = DifficultySystem.getPhaseForScore(score);

    // 🎯 STORY MODE: Constrained path generation with maxGapShift
    double gapY; // Gap center Y position
    final minCenterAllowed = gap / 2;
    final maxCenterAllowed = gameSize.height - gap / 2;
    
    if (storyModeMaxGapShift != null && _previousGapCenterY != null) {
      // Constrained path: limit shift from previous gap
      final maxShift = storyModeMaxGapShift!;
      final prevCenter = _previousGapCenterY!;
      
      // Calculate allowed range based on previous position and max shift
      double minCenter = (prevCenter - maxShift).clamp(minCenterAllowed, maxCenterAllowed);
      double maxCenter = (prevCenter + maxShift).clamp(minCenterAllowed, maxCenterAllowed);
      
      // Ensure valid range
      if (maxCenter <= minCenter) {
        gapY = prevCenter.clamp(minCenterAllowed, maxCenterAllowed);
      } else {
        gapY = minCenter + math.Random().nextDouble() * (maxCenter - minCenter);
      }
      
      // Path logs removed - too verbose even for debug mode
    } else if (storyModeMaxGapShift != null && _previousGapCenterY == null) {
      // First obstacle in constrained path: start in middle 60% of screen
      final safeMin = math.max(minCenterAllowed, gameSize.height * 0.2);
      final safeMax = math.min(maxCenterAllowed, gameSize.height * 0.8);
      gapY = safeMin + math.Random().nextDouble() * (safeMax - safeMin);
      
      // Path logs removed - too verbose even for debug mode
    } else {
      // Endless mode or no constraint: use fairness bands
      final bandMinRatio = score < 25 ? 0.35 : 0.25;
      final bandMaxRatio = score < 25 ? 0.65 : 0.75;
      double bandMin = gameSize.height * bandMinRatio;
      double bandMax = gameSize.height * bandMaxRatio;
      
      bandMin = math.max(bandMin, minCenterAllowed);
      bandMax = math.min(bandMax, maxCenterAllowed);
      
      if (bandMax <= bandMin) {
        gapY = (minCenterAllowed + maxCenterAllowed) * 0.5;
      } else {
        gapY = bandMin + math.Random().nextDouble() * (bandMax - bandMin);
      }
    }
    
    // 🎯 STORY MODE: Track gap center for next obstacle
    if (storyModeMaxGapShift != null) {
      _previousGapCenterY = gapY;
    }

    // ✅ FIX v17: Spawn obstacle fully off-screen
    // Since anchor is Anchor.topLeft, position is at gap TOP, not center
    // So we need to subtract half the obstacle width to spawn fully off-screen
    final spawnX = gameSize.width;
    
    // ✅ FIX v17: gapY is gap CENTER, but anchor is topLeft at gap TOP
    // So position should be gapY - (gap / 2) to place anchor at gap top
    final gapTopY = gapY - (gap / 2);
    
    // 🎪 TOURNAMENT: Get movement config from pattern selector if available
    final movementConfig = patternSelector?.selectMovementConfig() 
        ?? const ObstacleMovementConfig();
    
    final obstacle = DynamicObstacle(
      position: Vector2(spawnX, gapTopY),
      theme: currentTheme,
      gapSize: gap,
      speed: speed,
      currentScore: score,
      storyModeObstacleAsset: storyModeObstacleAsset, // 🎯 STORY MODE: Pass story mode asset if set
      movementConfig: movementConfig, // 🎪 TOURNAMENT: Pass movement config
    );
    obstacle.priority = 0; // FLAME PRIORITY: Obstacles render at base level (above background, below jet)
    
    _obstacles.add(obstacle);

    // Obstacle spawn log removed - too verbose during gameplay
    // Enable for debugging: safePrint('🎯 OBSTACLE: Score $score → ${phase.name}');
    
    // 🎁 BONUS SYSTEM: Notify callback for bonus spawning opportunity
    onObstacleSpawned?.call(gapY, spawnX, gap, speed);
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
        // Scoring debug logs removed - too verbose during gameplay
      }
    }
    
    return scoredObstacles;
  }

  /// 🎯 ZONE 1: Get obstacles that were positionally passed but not scored
  /// 
  /// ✅ PERFORMANCE: Event-driven approach - only called on crash, not every frame
  /// Checks all current obstacles to see which ones were positionally passed
  /// (jet X >= obstacle center) but not scored via gap
  /// 
  /// This is O(n) only on crash (rare event), making it much more efficient
  /// than checking every frame (which would be O(n) * 60fps = 60n per second)
  /// 
  /// 🎯 FIX: Changed from "jet X > obstacle right edge" to "jet X >= obstacle left edge"
  /// This ensures that if the player crashes into an obstacle, they still get credit
  /// for positionally passing it (as long as they've reached the obstacle's position)
  List<DynamicObstacle> getPositionallyPassedButUnscored(Vector2 jetPosition) {
    final unscoredObstacles = <DynamicObstacle>[];
    
    for (final obstacle in _obstacles) {
      // Skip if already scored (via gap or previous positional passing)
      if (obstacle.scored) {
        safePrint('🎯 ZONE 1: Skipping obstacle at x=${obstacle.position.x} - already marked as scored');
        continue;
      }
      if (obstacle.scoreZone?.hasScored == true) {
        safePrint('🎯 ZONE 1: Skipping obstacle at x=${obstacle.position.x} - already scored via ScoreZone');
        continue;
      }
      
      // 🎯 FIX: Check if obstacle was positionally passed (jet X >= obstacle center)
      // This is more lenient than requiring right edge - if the jet has reached the obstacle's center,
      // it counts even if the player crashes into it before fully passing the right edge
      final obstacleLeftEdge = obstacle.position.x;
      final obstacleCenter = obstacle.position.x + (GameConfig.obstacleWidth / 2);
      final obstacleRightEdge = obstacle.position.x + GameConfig.obstacleWidth;
      
      safePrint('🎯 ZONE 1: Checking obstacle at x=${obstacle.position.x} (left=${obstacleLeftEdge.toStringAsFixed(1)}, center=${obstacleCenter.toStringAsFixed(1)}, right=${obstacleRightEdge.toStringAsFixed(1)}), jet at x=${jetPosition.x.toStringAsFixed(1)}');
      
      // Count as passed if jet has reached or passed the obstacle's center
      // This ensures credit even if player crashes into the obstacle
      // Using center instead of left edge prevents counting obstacles that haven't been reached yet
      if (jetPosition.x >= obstacleCenter) {
        safePrint('🎯 ZONE 1: ✅ Obstacle at x=${obstacle.position.x} was positionally passed! (jet ${jetPosition.x.toStringAsFixed(1)} >= center ${obstacleCenter.toStringAsFixed(1)})');
        unscoredObstacles.add(obstacle);
      } else {
        safePrint('🎯 ZONE 1: ❌ Obstacle at x=${obstacle.position.x} not yet passed (jet x=${jetPosition.x.toStringAsFixed(1)} < center=${obstacleCenter.toStringAsFixed(1)})');
      }
    }
    
    safePrint('🎯 ZONE 1: Found ${unscoredObstacles.length} unscored positionally passed obstacles');
    return unscoredObstacles;
  }
  
  /// Clear all obstacles
  void clearObstacles() {
    for (final obstacle in _obstacles) {
      obstacle.removeFromParent();
    }
    _obstacles.clear();
    _timeSinceLastObstacle = 0.0;
    _previousGapCenterY = null; // 🎯 Reset path tracking
    _isPaused = false; // 🛑 Reset pause state
    patternSelector?.reset(); // 🎪 Reset pattern selector
    safePrint('🗑️ All obstacles cleared');
  }
  
  /// 🎪 TOURNAMENT: Configure pattern selector from obstacle patterns
  void configurePatterns(List<dynamic>? patterns) {
    if (patterns == null || patterns.isEmpty) {
      patternSelector = null;
      safePrint('🎪 No obstacle patterns configured (static obstacles)');
      return;
    }
    
    // Convert to ObstaclePattern if coming from tournament config
    final obstaclePatterns = patterns.map((p) {
      if (p is ObstaclePattern) return p;
      // Shouldn't happen but handle gracefully
      return const ObstaclePattern(
        type: ObstaclePatternType.static,
        weight: 100,
      );
    }).toList();
    
    patternSelector = ObstaclePatternSelector(patterns: obstaclePatterns);
    safePrint('🎪 Configured ${obstaclePatterns.length} obstacle patterns');
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

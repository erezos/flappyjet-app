import 'package:flutter/material.dart';
import '../../core/debug_logger.dart';
import '../core/game_config.dart';
import '../components/jet_player.dart';
import '../components/dynamic_obstacle.dart';

/// Handles collision detection between jet and obstacles
/// Separated from FlappyGame for better testability and maintainability
class CollisionSystem {
  /// Check collision between jet and obstacle
  /// Returns true if collision detected
  bool checkCollision(JetPlayer jet, DynamicObstacle obstacle, Size gameSize) {
    // Jet collision box tuned to align with sprite visually: slightly forward towards nose
    final skin = jet.currentSkin;
    final jetCenter = Offset(jet.position.x, jet.position.y).translate(
      skin.collisionCenterOffset.dx,
      skin.collisionCenterOffset.dy,
    );
    final jetRect = Rect.fromCenter(
      center: jetCenter,
      width: GameConfig.jetSize * skin.collisionWidthFactor,
      height: GameConfig.jetSize * skin.collisionHeightFactor,
    );

    final gapSize = obstacle.gapSize;
    final topRect = Rect.fromLTWH(
      obstacle.position.x,
      0,
      GameConfig.obstacleWidth,
      obstacle.position.y - gapSize / 2,
    );

    final bottomRect = Rect.fromLTWH(
      obstacle.position.x,
      obstacle.position.y + gapSize / 2,
      GameConfig.obstacleWidth,
      gameSize.height - (obstacle.position.y + gapSize / 2),
    );

    final collision = jetRect.overlaps(topRect) || jetRect.overlaps(bottomRect);

    if (collision) {
      safePrint(
        '🎯 COLLISION DETECTED: Jet X=${jet.position.x.toStringAsFixed(2)} vs Obstacle ${obstacle.position.x.toStringAsFixed(2)}',
      );
    }

    return collision;
  }

  /// Check if jet is near obstacle (for performance optimization)
  /// Only check collision with obstacles that are actually near the jet
  bool isJetNearObstacle(JetPlayer jet, DynamicObstacle obstacle) {
    final obstacleLeft = obstacle.position.x;
    final obstacleRight = obstacle.position.x + GameConfig.obstacleWidth;
    final jetX = jet.position.x;

    // Only check collision if jet is within reasonable range of obstacle (20px buffer for safety)
    final isNearObstacle =
        jetX >= (obstacleLeft - 20) && jetX <= (obstacleRight + 20);

    return isNearObstacle;
  }

  /// Check ceiling collision
  bool checkCeilingCollision(JetPlayer jet) {
    return jet.position.y < 0;
  }

  /// Handle ceiling collision by stopping upward movement
  void handleCeilingCollision(JetPlayer jet) {
    jet.position.y = 0;
    jet.velocity.y = 0;
    safePrint('🚫 Ceiling collision - stopping upward movement');
  }

  /// Get collision debug info for testing
  Map<String, dynamic> getCollisionDebugInfo(JetPlayer jet, DynamicObstacle obstacle) {
    final skin = jet.currentSkin;
    final jetCenter = Offset(jet.position.x, jet.position.y).translate(
      skin.collisionCenterOffset.dx,
      skin.collisionCenterOffset.dy,
    );
    
    return {
      'jet': {
        'position': jet.position.toString(),
        'center': jetCenter.toString(),
        'size': GameConfig.jetSize,
        'collision_width_factor': skin.collisionWidthFactor,
        'collision_height_factor': skin.collisionHeightFactor,
      },
      'obstacle': {
        'position': obstacle.position.toString(),
        'gap_size': obstacle.gapSize,
        'width': GameConfig.obstacleWidth,
      },
      'is_near': isJetNearObstacle(jet, obstacle),
    };
  }
}

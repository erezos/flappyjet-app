import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:flappy_jet_pro/game/systems/collision_system.dart';
import 'package:flappy_jet_pro/game/components/jet_player.dart';
import 'package:flappy_jet_pro/game/components/dynamic_obstacle.dart';
import 'package:flappy_jet_pro/game/core/game_config.dart';
import 'package:flappy_jet_pro/game/core/game_themes.dart';
import 'package:flappy_jet_pro/game/core/jet_skins.dart';

void main() {
  group('CollisionSystem', () {
    late CollisionSystem collisionSystem;
    late JetPlayer jet;
    late DynamicObstacle obstacle;

    setUp(() {
      collisionSystem = CollisionSystem();
      
      // Create a test jet
      jet = JetPlayer(
        Vector2(100, 200),
        GameThemes.skyRookie,
        jetSkin: JetSkinCatalog.starterJet,
      );
      
      // Create a test obstacle
      obstacle = DynamicObstacle(
        position: Vector2(100, 200),
        theme: GameThemes.skyRookie,
        gapSize: 200,
        speed: 300,
        currentScore: 0,
      );
    });

    test('should detect collision when jet overlaps with obstacle', () {
      // Position jet in collision with obstacle
      jet.position = Vector2(100, 150); // Jet at same X as obstacle, in gap area
      obstacle.position = Vector2(100, 200); // Obstacle with gap at Y=200
      
      final gameSize = Size(400, 600);
      final hasCollision = collisionSystem.checkCollision(jet, obstacle, gameSize);
      
      expect(hasCollision, true);
    });

    test('should not detect collision when jet is in gap', () {
      // Position jet in the gap (safe area)
      jet.position = Vector2(100, 200); // Jet in center of gap
      obstacle.position = Vector2(100, 200); // Obstacle with gap at Y=200
      
      final gameSize = Size(400, 600);
      final hasCollision = collisionSystem.checkCollision(jet, obstacle, gameSize);
      
      expect(hasCollision, false);
    });

    test('should detect collision with top obstacle', () {
      // Position jet above the gap (collision with top obstacle)
      jet.position = Vector2(100, 50); // Jet above gap
      obstacle.position = Vector2(100, 200); // Obstacle with gap at Y=200
      
      final gameSize = Size(400, 600);
      final hasCollision = collisionSystem.checkCollision(jet, obstacle, gameSize);
      
      expect(hasCollision, true);
    });

    test('should detect collision with bottom obstacle', () {
      // Position jet below the gap (collision with bottom obstacle)
      jet.position = Vector2(100, 350); // Jet below gap
      obstacle.position = Vector2(100, 200); // Obstacle with gap at Y=200
      
      final gameSize = Size(400, 600);
      final hasCollision = collisionSystem.checkCollision(jet, obstacle, gameSize);
      
      expect(hasCollision, true);
    });

    test('should correctly identify when jet is near obstacle', () {
      jet.position = Vector2(100, 200);
      obstacle.position = Vector2(100, 200);
      
      final isNear = collisionSystem.isJetNearObstacle(jet, obstacle);
      
      expect(isNear, true);
    });

    test('should correctly identify when jet is far from obstacle', () {
      jet.position = Vector2(50, 200);
      obstacle.position = Vector2(200, 200); // Far away
      
      final isNear = collisionSystem.isJetNearObstacle(jet, obstacle);
      
      expect(isNear, false);
    });

    test('should detect ceiling collision', () {
      jet.position = Vector2(100, -10); // Above ceiling
      
      final hasCeilingCollision = collisionSystem.checkCeilingCollision(jet);
      
      expect(hasCeilingCollision, true);
    });

    test('should not detect ceiling collision when jet is below ceiling', () {
      jet.position = Vector2(100, 50); // Below ceiling
      
      final hasCeilingCollision = collisionSystem.checkCeilingCollision(jet);
      
      expect(hasCeilingCollision, false);
    });

    test('should handle ceiling collision by stopping upward movement', () {
      jet.position = Vector2(100, -10);
      jet.velocity = Vector2(0, -100); // Moving upward
      
      collisionSystem.handleCeilingCollision(jet);
      
      expect(jet.position.y, 0);
      expect(jet.velocity.y, 0);
    });

    test('should provide collision debug info', () {
      jet.position = Vector2(100, 200);
      obstacle.position = Vector2(100, 200);
      
      final debugInfo = collisionSystem.getCollisionDebugInfo(jet, obstacle);
      
      expect(debugInfo['jet'], isA<Map<String, dynamic>>());
      expect(debugInfo['obstacle'], isA<Map<String, dynamic>>());
      expect(debugInfo['is_near'], isA<bool>());
      expect(debugInfo['jet']['position'], isA<String>());
      expect(debugInfo['obstacle']['position'], isA<String>());
    });

    test('should handle edge cases correctly', () {
      // Test with jet at exact obstacle edge
      jet.position = Vector2(100, 100); // At top edge of gap
      obstacle.position = Vector2(100, 200);
      
      final gameSize = Size(400, 600);
      final hasCollision = collisionSystem.checkCollision(jet, obstacle, gameSize);
      
      // Should detect collision as jet is at the edge
      expect(hasCollision, true);
    });

    test('should work with different obstacle sizes', () {
      // Create obstacle with smaller gap
      final smallGapObstacle = DynamicObstacle(
        position: Vector2(100, 200),
        theme: GameThemes.skyRookie,
        gapSize: 100, // Smaller gap
        speed: 300,
        currentScore: 0,
      );
      
      jet.position = Vector2(100, 150); // Should be in collision with smaller gap
      
      final gameSize = Size(400, 600);
      final hasCollision = collisionSystem.checkCollision(jet, smallGapObstacle, gameSize);
      
      expect(hasCollision, true);
    });
  });
}

/// Flame Collision System Tests (TDD)
/// 
/// These tests are written BEFORE implementing Flame collision.
/// Expected: Tests will FAIL initially (Red phase)
/// Then we implement the features to make them pass (Green phase)
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flame/collisions.dart';
import '../../../lib/game/flappy_game.dart';
import '../../../lib/game/components/jet_player.dart';
import '../../../lib/game/components/dynamic_obstacle.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('Flame Collision: HasCollisionDetection', () {
    testWidgets('FlappyGame has HasCollisionDetection mixin', (tester) async {
      final game = TestHelpers.createTestGame();
      await tester.pumpWidget(GameWidget(game: game));
      await tester.pump();
      
      // Test: FlappyGame should have collision detection
      expect(
        game is HasCollisionDetection,
        true,
        reason: 'FlappyGame should implement HasCollisionDetection mixin',
      );
    });
    
    testWidgets('Collision detection system is initialized', (tester) async {
      final game = TestHelpers.createTestGame();
      await tester.pumpWidget(GameWidget(game: game));
      await tester.pump();
      
      await TestHelpers.waitForGameReady(game);
      
      // Test: Collision detection should be set up
      expect(
        (game as HasCollisionDetection).collisionDetection,
        isNotNull,
        reason: 'Collision detection system should be initialized',
      );
    });
  });
  
  group('Flame Collision: JetPlayer Hitbox', () {
    testWidgets('JetPlayer has CircleHitbox', (tester) async {
      final game = TestHelpers.createTestGame();
      await tester.pumpWidget(GameWidget(game: game));
      await tester.pump();
      
      await TestHelpers.waitForGameReady(game);
      
      final jet = game.jet;
      
      // Test: Jet should have exactly one CircleHitbox
      final hitboxes = jet.children.query<CircleHitbox>();
      expect(
        hitboxes.length,
        1,
        reason: 'JetPlayer should have exactly one CircleHitbox',
      );
    });
    
    testWidgets('JetPlayer hitbox is correct size', (tester) async {
      final game = TestHelpers.createTestGame();
      await tester.pumpWidget(GameWidget(game: game));
      await tester.pump();
      
      await TestHelpers.waitForGameReady(game);
      
      final jet = game.jet;
      final hitbox = jet.children.query<CircleHitbox>().first;
      
      // Test: Hitbox should be 70% of jet width (35% radius)
      final expectedRadius = jet.size.x * 0.35;
      expect(
        hitbox.radius,
        closeTo(expectedRadius, 0.1),
        reason: 'Hitbox radius should be 35% of jet width',
      );
    });
    
    testWidgets('JetPlayer hitbox is active collision type', (tester) async {
      final game = TestHelpers.createTestGame();
      await tester.pumpWidget(GameWidget(game: game));
      await tester.pump();
      
      await TestHelpers.waitForGameReady(game);
      
      final jet = game.jet;
      final hitbox = jet.children.query<CircleHitbox>().first;
      
      // Test: Jet hitbox should be active (checks for collisions)
      expect(
        hitbox.collisionType,
        CollisionType.active,
        reason: 'Jet hitbox should be active collision type',
      );
    });
    
    testWidgets('JetPlayer implements CollisionCallbacks', (tester) async {
      final game = TestHelpers.createTestGame();
      await tester.pumpWidget(GameWidget(game: game));
      await tester.pump();
      
      await TestHelpers.waitForGameReady(game);
      
      final jet = game.jet;
      
      // Test: Jet should implement collision callbacks
      expect(
        jet is CollisionCallbacks,
        true,
        reason: 'JetPlayer should implement CollisionCallbacks mixin',
      );
    });
  });
  
  group('Flame Collision: DynamicObstacle Hitbox', () {
    testWidgets('DynamicObstacle has two RectangleHitboxes', (tester) async {
      final game = TestHelpers.createTestGame();
      await tester.pumpWidget(GameWidget(game: game));
      await tester.pump();
      
      await TestHelpers.waitForGameReady(game);
      await TestHelpers.simulateTap(game);
      await tester.pump();
      
      // Create and add obstacle
      final obstacle = DynamicObstacle(
        Vector2(300, game.size.y / 2),
        gapSize: 200,
      );
      await game.add(obstacle);
      await tester.pump();
      
      // Test: Obstacle should have exactly two hitboxes (top + bottom)
      final hitboxes = obstacle.children.query<RectangleHitbox>();
      expect(
        hitboxes.length,
        2,
        reason: 'DynamicObstacle should have two RectangleHitboxes (top + bottom)',
      );
    });
    
    testWidgets('DynamicObstacle hitboxes are passive', (tester) async {
      final game = TestHelpers.createTestGame();
      await tester.pumpWidget(GameWidget(game: game));
      await tester.pump();
      
      await TestHelpers.waitForGameReady(game);
      
      final obstacle = DynamicObstacle(
        Vector2(300, game.size.y / 2),
        gapSize: 200,
      );
      await game.add(obstacle);
      await tester.pump();
      
      final hitboxes = obstacle.children.query<RectangleHitbox>();
      
      // Test: Obstacle hitboxes should be passive (performance optimization)
      for (final hitbox in hitboxes) {
        expect(
          hitbox.collisionType,
          CollisionType.passive,
          reason: 'Obstacle hitboxes should be passive (only be checked, not check others)',
        );
      }
    });
  });
  
  group('Flame Collision: Collision Detection', () {
    testWidgets('Collision detected between jet and obstacle', (tester) async {
      final game = TestHelpers.createTestGame();
      await tester.pumpWidget(GameWidget(game: game));
      await tester.pump();
      
      await TestHelpers.waitForGameReady(game);
      await TestHelpers.simulateTap(game);
      await tester.pump();
      
      // Create obstacle
      final obstacle = DynamicObstacle(
        Vector2(game.jet.position.x + 100, game.size.y / 2),
        gapSize: 200,
      );
      await game.add(obstacle);
      await tester.pump();
      
      // Move jet into obstacle (top pillar)
      game.jet.position.y = obstacle.position.y - 150;
      game.jet.position.x = obstacle.position.x;
      
      // Update game to trigger collision detection
      game.update(0.016);
      await tester.pump();
      await tester.pump(); // Extra pump for collision callbacks
      
      // Test: Game should be over due to collision
      expect(
        game.gameStateManager.isGameOver,
        true,
        reason: 'Flame collision should detect collision and trigger game over',
      );
    });
    
    testWidgets('No collision when jet is in gap', (tester) async {
      final game = TestHelpers.createTestGame();
      await tester.pumpWidget(GameWidget(game: game));
      await tester.pump();
      
      await TestHelpers.waitForGameReady(game);
      await TestHelpers.simulateTap(game);
      await tester.pump();
      
      final obstacle = DynamicObstacle(
        Vector2(game.jet.position.x + 100, game.size.y / 2),
        gapSize: 200,
      );
      await game.add(obstacle);
      await tester.pump();
      
      // Position jet perfectly in gap
      game.jet.position.y = obstacle.position.y;
      game.jet.position.x = obstacle.position.x + 10;
      
      game.update(0.016);
      await tester.pump();
      await tester.pump();
      
      // Test: Should NOT trigger collision
      expect(
        game.gameStateManager.isGameOver,
        false,
        reason: 'Jet in gap should not trigger collision',
      );
    });
    
    testWidgets('Invulnerability prevents collision', (tester) async {
      final game = TestHelpers.createTestGame();
      await tester.pumpWidget(GameWidget(game: game));
      await tester.pump();
      
      await TestHelpers.waitForGameReady(game);
      await TestHelpers.simulateTap(game);
      await tester.pump();
      
      // Enable invulnerability
      game.jet.setInvulnerable(true);
      
      final obstacle = DynamicObstacle(
        Vector2(game.jet.position.x + 50, game.size.y / 2),
        gapSize: 200,
      );
      await game.add(obstacle);
      await tester.pump();
      
      // Collide while invulnerable
      game.jet.position.y = obstacle.position.y - 150;
      game.jet.position.x = obstacle.position.x;
      
      game.update(0.016);
      await tester.pump();
      await tester.pump();
      
      // Test: Should NOT trigger game over when invulnerable
      expect(
        game.gameStateManager.isGameOver,
        false,
        reason: 'Invulnerability should prevent collision from causing game over',
      );
    });
  });
  
  group('Flame Collision: Performance', () {
    testWidgets('Quadtree collision detection is used', (tester) async {
      final game = TestHelpers.createTestGame();
      await tester.pumpWidget(GameWidget(game: game));
      await tester.pump();
      
      await TestHelpers.waitForGameReady(game);
      
      final collisionDetection = (game as HasCollisionDetection).collisionDetection;
      
      // Test: Should use quadtree for performance
      expect(
        collisionDetection is StandardCollisionDetection ||
        collisionDetection is QuadTreeCollisionDetection,
        true,
        reason: 'Should use Standard or QuadTree collision detection',
      );
    });
    
    testWidgets('Collision checks scale efficiently with obstacles', (tester) async {
      final game = TestHelpers.createTestGame();
      await tester.pumpWidget(GameWidget(game: game));
      await tester.pump();
      
      await TestHelpers.waitForGameReady(game);
      await TestHelpers.simulateTap(game);
      await tester.pump();
      
      // Add many obstacles
      for (int i = 0; i < 20; i++) {
        final obstacle = DynamicObstacle(
          Vector2(game.jet.position.x + (i * 200.0), game.size.y / 2),
          gapSize: 200,
        );
        await game.add(obstacle);
      }
      await tester.pump();
      
      // Measure performance
      final stopwatch = Stopwatch()..start();
      
      // Run 60 frames (1 second at 60 FPS)
      for (int i = 0; i < 60; i++) {
        game.update(0.016);
      }
      
      stopwatch.stop();
      
      // Test: Should handle 20 obstacles without significant performance drop
      // (This is more of a sanity check than a strict performance test)
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(5000), // Should complete in less than 5 seconds
        reason: 'Collision detection should be efficient with many obstacles',
      );
    });
  });
}


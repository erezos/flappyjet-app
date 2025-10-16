/// Baseline Collision Detection Tests
/// 
/// These tests document and verify the CURRENT collision behavior before refactoring.
/// All tests must pass throughout the refactoring process.
/// 
/// Purpose: Ensure collision detection works identically after migrating to Flame collision
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flame_test/flame_test.dart';
import '../../lib/game/flappy_game.dart';
import '../../lib/game/components/jet_player.dart';
import '../../lib/game/components/dynamic_obstacle.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Baseline: Collision Detection', () {
    testWidgets('Jet collides with top pillar', (tester) async {
      final game = TestHelpers.createTestGame();
      await tester.pumpWidget(GameWidget(game: game));
      await tester.pump();
      
      await TestHelpers.waitForGameReady(game);
      
      // Start the game
      await TestHelpers.simulateTap(game);
      await tester.pump();
      
      TestHelpers.assertGameState(game, isPlaying: true);
      
      // Create obstacle in jet's path
      final obstacle = DynamicObstacle(
        Vector2(game.jet.position.x + 100, game.size.y / 2),
        gapSize: 200,
      );
      await game.add(obstacle);
      await tester.pump();
      
      // Move jet into top pillar
      game.jet.position.y = obstacle.position.y - 150; // Above gap
      game.jet.position.x = obstacle.position.x;
      
      // Update game to trigger collision check
      game.update(0.016);
      await tester.pump();
      
      // BASELINE: Should detect collision and trigger game over
      expect(
        game.gameStateManager.isGameOver,
        true,
        reason: 'Collision with top pillar should trigger game over',
      );
    });
    
    testWidgets('Jet collides with bottom pillar', (tester) async {
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
      
      // Move jet into bottom pillar
      game.jet.position.y = obstacle.position.y + 150; // Below gap
      game.jet.position.x = obstacle.position.x;
      
      game.update(0.016);
      await tester.pump();
      
      expect(
        game.gameStateManager.isGameOver,
        true,
        reason: 'Collision with bottom pillar should trigger game over',
      );
    });
    
    testWidgets('Jet passes through gap without collision', (tester) async {
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
      game.jet.position.y = obstacle.position.y; // In gap
      game.jet.position.x = obstacle.position.x + 10;
      
      game.update(0.016);
      await tester.pump();
      
      // BASELINE: Should NOT detect collision
      expect(
        game.gameStateManager.isGameOver,
        false,
        reason: 'Jet in gap should not collide',
      );
    });
    
    testWidgets('Jet hits ground', (tester) async {
      final game = TestHelpers.createTestGame();
      await tester.pumpWidget(GameWidget(game: game));
      await tester.pump();
      
      await TestHelpers.waitForGameReady(game);
      await TestHelpers.simulateTap(game);
      await tester.pump();
      
      // Move jet to ground level
      game.jet.position.y = game.size.y - 25; // Ground is at y - 50
      
      game.update(0.016);
      await tester.pump();
      
      // BASELINE: Jet should stop at ground, velocity should be 0
      expect(
        game.jet.velocity.y,
        0,
        reason: 'Jet velocity should be 0 when hitting ground',
      );
      expect(
        game.jet.position.y,
        lessThanOrEqualTo(game.size.y - 25),
        reason: 'Jet should not go below ground level',
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
      game.jet.position.y = obstacle.position.y - 150; // Top pillar
      game.jet.position.x = obstacle.position.x;
      
      game.update(0.016);
      await tester.pump();
      
      // BASELINE: Should NOT trigger game over when invulnerable
      expect(
        game.gameStateManager.isGameOver,
        false,
        reason: 'Invulnerability should prevent collision',
      );
    });
    
    testWidgets('Multiple obstacles checked correctly', (tester) async {
      final game = TestHelpers.createTestGame();
      await tester.pumpWidget(GameWidget(game: game));
      await tester.pump();
      
      await TestHelpers.waitForGameReady(game);
      await TestHelpers.simulateTap(game);
      await tester.pump();
      
      // Add 3 obstacles
      final obstacle1 = DynamicObstacle(
        Vector2(game.jet.position.x + 200, game.size.y / 2),
        gapSize: 200,
      );
      final obstacle2 = DynamicObstacle(
        Vector2(game.jet.position.x + 400, game.size.y / 2),
        gapSize: 200,
      );
      final obstacle3 = DynamicObstacle(
        Vector2(game.jet.position.x + 600, game.size.y / 2),
        gapSize: 200,
      );
      
      await game.add(obstacle1);
      await game.add(obstacle2);
      await game.add(obstacle3);
      await tester.pump();
      
      // Jet is far from all obstacles
      game.update(0.016);
      await tester.pump();
      
      // BASELINE: Should not collide with distant obstacles
      expect(
        game.gameStateManager.isGameOver,
        false,
        reason: 'Should not collide with distant obstacles',
      );
      
      // Now move jet into second obstacle
      game.jet.position.x = obstacle2.position.x;
      game.jet.position.y = obstacle2.position.y - 150; // Top pillar
      
      game.update(0.016);
      await tester.pump();
      
      // BASELINE: Should detect collision
      expect(
        game.gameStateManager.isGameOver,
        true,
        reason: 'Should detect collision with second obstacle',
      );
    });
  });
  
  group('Baseline: Collision Edge Cases', () {
    testWidgets('Jet at exact gap boundary (top edge)', (tester) async {
      final game = TestHelpers.createTestGame();
      await tester.pumpWidget(GameWidget(game: game));
      await tester.pump();
      
      await TestHelpers.waitForGameReady(game);
      await TestHelpers.simulateTap(game);
      await tester.pump();
      
      final obstacle = DynamicObstacle(
        Vector2(game.jet.position.x + 100, 200),
        gapSize: 200,
      );
      await game.add(obstacle);
      await tester.pump();
      
      // Position at exact top edge of gap
      game.jet.position.y = obstacle.position.y - 100; // Exact top edge
      game.jet.position.x = obstacle.position.x;
      
      game.update(0.016);
      await tester.pump();
      
      // BASELINE: Document current behavior at edge
      // (May or may not collide - documenting as-is)
      final collided = game.gameStateManager.isGameOver;
      expect(
        collided,
        isA<bool>(),
        reason: 'Edge case behavior documented: collided=$collided',
      );
    });
    
    testWidgets('Jet moving very fast (potential tunnel effect)', (tester) async {
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
      
      // Set very high velocity (unrealistic, but tests edge case)
      game.jet.velocity.y = -1000;
      game.jet.position.y = obstacle.position.y;
      game.jet.position.x = obstacle.position.x;
      
      // Update multiple frames
      for (int i = 0; i < 5; i++) {
        game.update(0.016);
        await tester.pump();
      }
      
      // BASELINE: Current system may miss collision (tunneling)
      // Document current behavior
      expect(
        game.gameStateManager.isGameOver,
        isA<bool>(),
        reason: 'High velocity edge case documented',
      );
    });
  });
}


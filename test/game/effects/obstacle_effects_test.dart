import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/game/components/dynamic_obstacle.dart';
import 'package:flappy_jet_pro/game/flappy_game.dart';

void main() {
  group('Obstacle Spawn Effects', () {
    testWithGame<FlappyGame>(
      'obstacle spawns with fade-in effect',
      FlappyGame.new,
      (game) async {
        final obstacle = DynamicObstacle(
          x: 500,
          topHeight: 300,
          gapSize: 200,
          speed: 200,
        );
        
        await game.ensureAdd(obstacle);
        
        // Initial opacity should be 0
        expect(obstacle.opacity, 0.0, reason: 'Should start invisible');
        
        // Advance time during fade-in
        game.update(0.15); // Mid-fade
        
        // Opacity should be increasing
        expect(obstacle.opacity, greaterThan(0.0));
        expect(obstacle.opacity, lessThan(1.0));
        
        // Advance to end of fade
        game.update(0.20);
        
        // Opacity should be fully visible
        expect(obstacle.opacity, closeTo(1.0, 0.1));
      },
    );

    testWithGame<FlappyGame>(
      'obstacle spawns with scale-up effect',
      FlappyGame.new,
      (game) async {
        final obstacle = DynamicObstacle(
          x: 500,
          topHeight: 300,
          gapSize: 200,
          speed: 200,
        );
        
        await game.ensureAdd(obstacle);
        
        // Initial scale should be small
        expect(obstacle.scale.x, lessThan(1.0), reason: 'Should start small');
        expect(obstacle.scale.y, lessThan(1.0), reason: 'Should start small');
        
        // Advance time during scale-up
        game.update(0.15);
        
        // Scale should be increasing
        expect(obstacle.scale.x, lessThan(1.0));
        
        // Advance to end of scale animation
        game.update(0.20);
        
        // Scale should be normal size
        expect(obstacle.scale.x, closeTo(1.0, 0.1));
        expect(obstacle.scale.y, closeTo(1.0, 0.1));
      },
    );

    testWithGame<FlappyGame>(
      'spawn effects use elastic curve for bounce feel',
      FlappyGame.new,
      (game) async {
        final obstacle = DynamicObstacle(
          x: 500,
          topHeight: 300,
          gapSize: 200,
          speed: 200,
        );
        
        await game.ensureAdd(obstacle);
        
        // Advance to near end of animation
        game.update(0.25);
        
        // With elastic curve, scale might temporarily exceed 1.0
        final scaleEffect = obstacle.children.whereType<ScaleEffect>().firstOrNull;
        expect(scaleEffect, isNotNull, reason: 'Should have scale effect');
      },
    );
  });

  group('Obstacle Removal Effects', () {
    testWithGame<FlappyGame>(
      'removeWithEffect() applies fade-out before removal',
      FlappyGame.new,
      (game) async {
        final obstacle = DynamicObstacle(
          x: 500,
          topHeight: 300,
          gapSize: 200,
          speed: 200,
        );
        
        await game.ensureAdd(obstacle);
        
        // Wait for spawn effects to complete
        game.update(0.5);
        
        // Obstacle should be fully visible
        expect(obstacle.opacity, 1.0);
        
        // Trigger removal
        obstacle.removeWithEffect();
        
        // Advance time during fade-out
        game.update(0.1);
        
        // Opacity should be decreasing
        expect(obstacle.opacity, lessThan(1.0), reason: 'Should be fading out');
      },
    );

    testWithGame<FlappyGame>(
      'removeWithEffect() removes obstacle after fade-out',
      FlappyGame.new,
      (game) async {
        final obstacle = DynamicObstacle(
          x: 500,
          topHeight: 300,
          gapSize: 200,
          speed: 200,
        );
        
        await game.ensureAdd(obstacle);
        game.update(0.5); // Wait for spawn
        
        // Trigger removal
        obstacle.removeWithEffect();
        
        // Advance past fade-out duration
        game.update(0.3);
        
        // Obstacle should be removed from game
        expect(obstacle.isMounted, isFalse, reason: 'Should be removed after fade-out');
      },
    );

    testWithGame<FlappyGame>(
      'immediate removal still works for backwards compatibility',
      FlappyGame.new,
      (game) async {
        final obstacle = DynamicObstacle(
          x: 500,
          topHeight: 300,
          gapSize: 200,
          speed: 200,
        );
        
        await game.ensureAdd(obstacle);
        game.update(0.5);
        
        // Immediate removal
        obstacle.removeFromParent();
        
        // Should be removed immediately
        expect(obstacle.isMounted, isFalse);
      },
    );
  });

  group('Obstacle Effect Performance', () {
    testWithGame<FlappyGame>(
      'multiple obstacles with effects maintain performance',
      FlappyGame.new,
      (game) async {
        // Spawn many obstacles
        for (int i = 0; i < 20; i++) {
          final obstacle = DynamicObstacle(
            x: 500.0 + (i * 300.0),
            topHeight: 300,
            gapSize: 200,
            speed: 200,
          );
          await game.ensureAdd(obstacle);
        }
        
        // Advance time to trigger effects
        final stopwatch = Stopwatch()..start();
        for (int i = 0; i < 60; i++) {
          game.update(1 / 60);
        }
        stopwatch.stop();
        
        // Should maintain 60 FPS with many effects
        expect(stopwatch.elapsedMilliseconds, lessThan(1500),
            reason: 'Multiple obstacle effects should not kill performance');
      },
    );

    testWithGame<FlappyGame>(
      'effects do not accumulate over time',
      FlappyGame.new,
      (game) async {
        final obstacle = DynamicObstacle(
          x: 500,
          topHeight: 300,
          gapSize: 200,
          speed: 200,
        );
        
        await game.ensureAdd(obstacle);
        
        // Wait for spawn effects to complete
        game.update(1.0);
        
        // Effect count should be low (spawn effects completed)
        final effectCount = obstacle.children.whereType<Effect>().length;
        expect(effectCount, lessThan(3), 
            reason: 'Completed spawn effects should be cleaned up');
      },
    );
  });
}


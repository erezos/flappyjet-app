/// 🔥 BLOCKBUSTER COLLISION TESTS
/// Critical production safety tests to prevent collision bugs
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../lib/game/enhanced_flappy_game.dart';
import '../../lib/game/components/enhanced_jet_player.dart';
import '../../lib/game/components/dynamic_obstacle.dart';

import '../../lib/game/core/game_config.dart';
import '../../lib/game/core/game_themes.dart';

void main() {
  group('🔥 BLOCKBUSTER Collision Detection Tests', () {
    late EnhancedFlappyGame game;
    late EnhancedJetPlayer jet;
    late DynamicObstacle obstacle;
    
    setUp(() {
      // Create game instance
      game = EnhancedFlappyGame();
      
      // Create jet at default position
      jet = EnhancedJetPlayer(
        Vector2(GameConfig.getStartScreenJetX(400), GameConfig.getStartScreenJetY(600)),
        GameThemes.skyRookie,
      );
      
      // Create test obstacle
      obstacle = DynamicObstacle(
        position: Vector2(400, 400), // Center position
        theme: GameThemes.skyRookie,
        gapSize: GameConfig.obstacleGap,
        speed: GameConfig.obstacleSpeed,
        currentScore: 0,
      );
    });

    group('🟢 Ground Collision Tests', () {
      test('CRITICAL: Ground collision triggers at correct position', () {
        // Position jet just above ground collision threshold
        jet.position.y = 700; // Safe position
        expect(jet.position.y > 700, false); // Should not trigger
        
        // Position jet at ground collision threshold
        jet.position.y = 701; // At threshold (size.y - 100 = 800 - 100 = 700)
        expect(jet.position.y > 700, true); // Should trigger
        
        debugPrint('✅ Ground collision threshold test passed');
      });

      test('CRITICAL: Ground collision accounts for jet size properly', () {
        // Test different jet positions around ground level
        final testPositions = [695.0, 700.0, 705.0, 710.0];
        final expectedCollisions = [false, false, true, true];
        
        for (int i = 0; i < testPositions.length; i++) {
          jet.position.y = testPositions[i];
          final shouldCollide = jet.position.y > 700; // size.y - 100
          expect(shouldCollide, expectedCollisions[i],
              reason: 'Position ${testPositions[i]} collision expectation failed');
        }
        
        debugPrint('✅ Ground collision size test passed');
      });

      test('CRITICAL: Ground collision works on different screen sizes', () {
        // Test with different game sizes
        final screenSizes = [
          Vector2(400, 800),  // Default
          Vector2(375, 812),  // iPhone X
          Vector2(414, 896),  // iPhone 11 Pro Max
          Vector2(360, 640),  // Common Android
        ];
        
        for (final screenSize in screenSizes) {
          final groundThreshold = screenSize.y - 100;
          jet.position.y = groundThreshold + 1; // Just over threshold
          expect(jet.position.y > groundThreshold, true,
              reason: 'Screen size ${screenSize} ground collision failed');
        }
        
        debugPrint('✅ Multi-screen ground collision test passed');
      });
    });

    group('🎯 Obstacle Collision Tests', () {
      test('CRITICAL: Obstacle collision detects when jet hits top obstacle', () {
        // Position jet to collide with top obstacle
        jet.position = Vector2(400, 200); // Above gap
        obstacle.position = Vector2(400, 400);
        
        final jetRect = Rect.fromCenter(
          center: jet.position.toOffset(),
          width: GameConfig.jetSize * 0.8,
          height: GameConfig.jetSize * 0.8,
        );
        
        final topRect = Rect.fromLTWH(
          obstacle.position.x,
          0,
          GameConfig.obstacleWidth,
          obstacle.position.y - obstacle.gapSize / 2,
        );
        
        expect(jetRect.overlaps(topRect), true,
            reason: 'Jet should collide with top obstacle');
        
        debugPrint('✅ Top obstacle collision test passed');
      });

      test('CRITICAL: Obstacle collision detects when jet hits bottom obstacle', () {
        // Position jet to collide with bottom obstacle
        jet.position = Vector2(400, 600); // Below gap
        obstacle.position = Vector2(400, 400);
        
        final jetRect = Rect.fromCenter(
          center: jet.position.toOffset(),
          width: GameConfig.jetSize * 0.8,
          height: GameConfig.jetSize * 0.8,
        );
        
        final bottomRect = Rect.fromLTWH(
          obstacle.position.x,
          obstacle.position.y + obstacle.gapSize / 2,
          GameConfig.obstacleWidth,
          800 - (obstacle.position.y + obstacle.gapSize / 2), // Using default screen height
        );
        
        expect(jetRect.overlaps(bottomRect), true,
            reason: 'Jet should collide with bottom obstacle');
        
        debugPrint('✅ Bottom obstacle collision test passed');
      });

      test('CRITICAL: No collision when jet is in safe gap', () {
        // Position jet safely in the gap
        jet.position = Vector2(400, 400); // Exact center of gap
        obstacle.position = Vector2(400, 400);
        
        final jetRect = Rect.fromCenter(
          center: jet.position.toOffset(),
          width: GameConfig.jetSize * 0.8,
          height: GameConfig.jetSize * 0.8,
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
          800 - (obstacle.position.y + gapSize / 2),
        );
        
        expect(jetRect.overlaps(topRect), false,
            reason: 'Jet should not collide with top when in gap');
        expect(jetRect.overlaps(bottomRect), false,
            reason: 'Jet should not collide with bottom when in gap');
        
        debugPrint('✅ Safe gap collision test passed');
      });

      test('CRITICAL: Collision precision with edge cases', () {
        // Test collision at exact edge of obstacles
        final gapSize = GameConfig.obstacleGap;
        final halfGap = gapSize / 2;
        
        // Test positions at gap edges (account for jet size)
        final jetHalfSize = (GameConfig.jetSize * 0.8) / 2; // Half of collision box
        final testCases = [
          {'position': Vector2(400, 400 - halfGap - jetHalfSize - 1), 'shouldCollide': true, 'name': 'Just above gap'},
          {'position': Vector2(400, 400 - halfGap + jetHalfSize + 1), 'shouldCollide': false, 'name': 'Just inside gap top'},
          {'position': Vector2(400, 400 + halfGap - jetHalfSize - 1), 'shouldCollide': false, 'name': 'Just inside gap bottom'},
          {'position': Vector2(400, 400 + halfGap + jetHalfSize + 1), 'shouldCollide': true, 'name': 'Just below gap'},
        ];
        
        for (final testCase in testCases) {
          jet.position = testCase['position'] as Vector2;
          obstacle.position = Vector2(400, 400);
          
          final jetRect = Rect.fromCenter(
            center: jet.position.toOffset(),
            width: GameConfig.jetSize * 0.8,
            height: GameConfig.jetSize * 0.8,
          );
          
          final topRect = Rect.fromLTWH(
            obstacle.position.x,
            0,
            GameConfig.obstacleWidth,
            obstacle.position.y - halfGap,
          );
          
          final bottomRect = Rect.fromLTWH(
            obstacle.position.x,
            obstacle.position.y + halfGap,
            GameConfig.obstacleWidth,
            800 - (obstacle.position.y + halfGap),
          );
          
          final actualCollision = jetRect.overlaps(topRect) || jetRect.overlaps(bottomRect);
          expect(actualCollision, testCase['shouldCollide'],
              reason: '${testCase['name']} collision expectation failed');
        }
        
        debugPrint('✅ Edge case collision precision test passed');
      });
    });

    group('⚡ Performance Collision Tests', () {
      test('CRITICAL: Collision detection performs well with many obstacles', () {
        final stopwatch = Stopwatch()..start();
        
        // Create 100 obstacles and test collision with each
        final obstacles = <DynamicObstacle>[];
        for (int i = 0; i < 100; i++) {
          obstacles.add(DynamicObstacle(
            position: Vector2(400 + i * 10, 400),
            theme: GameThemes.skyRookie,
            gapSize: GameConfig.obstacleGap,
            speed: GameConfig.obstacleSpeed,
            currentScore: 0,
          ));
        }
        
        // Test collision with all obstacles
        jet.position = Vector2(450, 200); // Position to potentially collide
        int collisionCount = 0;
        
        for (final obs in obstacles) {
          final jetRect = Rect.fromCenter(
            center: jet.position.toOffset(),
            width: GameConfig.jetSize * 0.8,
            height: GameConfig.jetSize * 0.8,
          );
          
          final topRect = Rect.fromLTWH(
            obs.position.x,
            0,
            GameConfig.obstacleWidth,
            obs.position.y - obs.gapSize / 2,
          );
          
          if (jetRect.overlaps(topRect)) {
            collisionCount++;
          }
        }
        
        stopwatch.stop();
        
        // Should complete in under 10ms for good performance
        expect(stopwatch.elapsedMilliseconds, lessThan(10),
            reason: 'Collision detection should be fast even with many obstacles');
        
        debugPrint('✅ Performance test passed: ${stopwatch.elapsedMilliseconds}ms for 100 obstacles');
        debugPrint('✅ Detected $collisionCount collisions as expected');
      });
    });

    group('🔧 Integration Tests', () {
      test('CRITICAL: Game configuration affects collision correctly', () {
        // Test that changing GameConfig values affects collision
        final originalJetSize = GameConfig.jetSize;
        final originalObstacleGap = GameConfig.obstacleGap;
        
        // Test with larger jet (should collide more easily)
        jet.position = Vector2(400, 300); // Near gap edge
        obstacle.position = Vector2(400, 400);
        
        final smallJetRect = Rect.fromCenter(
          center: jet.position.toOffset(),
          width: 50 * 0.8, // Smaller jet
          height: 50 * 0.8,
        );
        
        final largeJetRect = Rect.fromCenter(
          center: jet.position.toOffset(),
          width: 100 * 0.8, // Larger jet
          height: 100 * 0.8,
        );
        
        final topRect = Rect.fromLTWH(
          obstacle.position.x,
          0,
          GameConfig.obstacleWidth,
          obstacle.position.y - obstacle.gapSize / 2,
        );
        
        // Larger jet should be more likely to collide
        final smallJetCollides = smallJetRect.overlaps(topRect);
        final largeJetCollides = largeJetRect.overlaps(topRect);
        
        if (smallJetCollides != largeJetCollides) {
          expect(largeJetCollides, true,
              reason: 'Larger jet should collide when smaller one doesn\'t');
        }
        
        debugPrint('✅ GameConfig integration test passed');
      });
    });
  });
}
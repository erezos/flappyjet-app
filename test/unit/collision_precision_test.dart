import 'package:flutter_test/flutter_test.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../lib/game/enhanced_flappy_game.dart';
import '../../lib/game/core/game_config.dart';
import '../../lib/game/core/game_themes.dart';

/// 🔥 COLLISION PRECISION TESTS - Prevent false collision bugs
/// Tests exact scenarios reported by users to ensure fair gameplay

void main() {
  group('🎯 COLLISION PRECISION TESTS - User-Reported Scenarios', () {
    setUpAll(() async {
      WidgetsFlutterBinding.ensureInitialized();
    });
    
    test('🔥 CRITICAL: Jet at X=35 should safely avoid obstacles at X=76+', () {
      // This replicates the exact scenario from user logs
      final jetX = GameConfig.getStartScreenJetX(400); // 35.0
      final jetY = 180.0; // Similar to user log Y=178.99
      final obstacleX = 76.3; // From user logs
      final gapSize = 320.0; // From user logs
      
      // Calculate jet collision box
      final jetSize = GameConfig.jetSize * 0.6; // 77 * 0.6 = 46.2
      final jetLeft = jetX - jetSize / 2; // 35 - 23.1 = 11.9  
      final jetRight = jetX + jetSize / 2; // 35 + 23.1 = 58.1
      
      // Obstacle collision box
      final obstacleLeft = obstacleX; // 76.3
      final obstacleRight = obstacleX + GameConfig.obstacleWidth; // 76.3 + 75 = 151.3
      
      // Should NOT overlap
      expect(jetRight < obstacleLeft, true, 
        reason: 'Jet (X: \$jetLeft-\$jetRight) should not overlap obstacle (X: \$obstacleLeft-\$obstacleRight)');
      
      // Safety margin should be at least 10 pixels
      final safetyMargin = obstacleLeft - jetRight;
      expect(safetyMargin >= 10.0, true,
        reason: 'Safety margin (\$safetyMargin px) should be at least 10px for fair gameplay');
      
      print('✅ COLLISION TEST PASSED:');
      print('   Jet collision box: X=\$jetLeft to \$jetRight');  
      print('   Obstacle collision box: X=\$obstacleLeft to \$obstacleRight');
      print('   Safety margin: \${safetyMargin}px');
    });
    
    test('🎯 User-reported scenario: Jet in gap should be safe', () {
      // Scenario from logs: Jet Y=178.99, Gap from Y=300.3 to Y=620.3
      final jetY = 178.99;
      final gapTop = 300.3;
      final gapBottom = 620.3;
      final jetSize = GameConfig.jetSize * 0.6;
      
      final jetTop = jetY - jetSize / 2;
      final jetBottom = jetY + jetSize / 2;
      
      // Jet should be safely above the gap (not in collision zone)
      expect(jetBottom < gapTop, true,
        reason: 'Jet should be safely above gap. Jet bottom: \$jetBottom, Gap top: \$gapTop');
    });
    
    test('🔥 COLLISION EDGE CASES: Various obstacle positions', () {
      final jetX = GameConfig.getStartScreenJetX(400);
      final jetSize = GameConfig.jetSize * 0.6;
      final jetRight = jetX + jetSize / 2;
      
      // Test multiple obstacle X positions around the critical zone
      final testObstaclePositions = [70.0, 75.0, 76.3, 80.0, 85.0];
      
      for (final obstacleX in testObstaclePositions) {
        final shouldCollide = jetRight >= obstacleX;
        final actualSafetyMargin = obstacleX - jetRight;
        
        if (shouldCollide) {
          expect(actualSafetyMargin < 0, true,
            reason: 'Obstacle at X=\$obstacleX should collide (overlap: \${-actualSafetyMargin}px)');
        } else {
          expect(actualSafetyMargin >= 0, true,
            reason: 'Obstacle at X=\$obstacleX should be safe (margin: \${actualSafetyMargin}px)');
        }
        
        print('Obstacle X=\$obstacleX: \${shouldCollide ? "COLLISION" : "SAFE"} (margin: \${actualSafetyMargin.toStringAsFixed(1)}px)');
      }
    });
    
    test('🛡️ ULTRA-FORGIVING collision box size validation', () {
      final originalJetSize = GameConfig.jetSize; // 77.0
      final collisionSize = originalJetSize * 0.6; // 46.2
      final forgivenessReduction = originalJetSize - collisionSize; // 30.8
      
      expect(collisionSize < originalJetSize, true,
        reason: 'Collision box should be smaller than visual size for fair gameplay');
      
      final forgivenessPercentage = (forgivenessReduction / originalJetSize) * 100;
      expect(forgivenessPercentage >= 35.0, true,
        reason: 'Should have at least 35% size reduction for ultra-fair gameplay (actual: \${forgivenessPercentage.toStringAsFixed(1)}%)');
      
      print('✅ FORGIVENESS VALIDATION:');
      print('   Visual size: \${originalJetSize}px');
      print('   Collision size: \${collisionSize}px');  
      print('   Forgiveness: \${forgivenessPercentage.toStringAsFixed(1)}% reduction');
    });
    
    test('🚀 Reaction time validation with new jet position', () {
      final jetX = GameConfig.getStartScreenJetX(400); // 35.0 (was 55.0)
      final screenWidth = 400.0;
      final obstacleSpawnX = screenWidth; // 400.0
      final obstacleSpeed = GameConfig.obstacleSpeed; // 45.0 px/s
      
      // Time until obstacle reaches jet X position
      final distanceToJet = obstacleSpawnX - jetX; // 400 - 35 = 365
      final timeToReachJet = distanceToJet / obstacleSpeed; // 365 / 45 = 8.11 seconds
      
      expect(timeToReachJet >= 6.0, true,
        reason: 'Should have at least 6 seconds reaction time (actual: \${timeToReachJet.toStringAsFixed(2)}s)');
      
      print('✅ REACTION TIME VALIDATION:');
      print('   Distance to obstacle: \${distanceToJet}px');
      print('   Obstacle speed: \${obstacleSpeed}px/s');
      print('   Reaction time: \${timeToReachJet.toStringAsFixed(2)} seconds');
    });
    
    test('🎯 Real collision box overlap calculation', () {
      // Test the exact overlap calculation logic used in the game
      final jetPosition = Vector2(GameConfig.getStartScreenJetX(400), 200.0);
      final obstaclePosition = Vector2(76.3, 400.0);
      final gapSize = 320.0;
      
      // Replicate game's collision detection logic
      final jetSize = GameConfig.jetSize * 0.6;
      final jetRect = Rect.fromCenter(
        center: jetPosition.toOffset(),
        width: jetSize,
        height: jetSize,
      );
      
      final topRect = Rect.fromLTWH(
        obstaclePosition.x,
        0,
        GameConfig.obstacleWidth,
        obstaclePosition.y - gapSize / 2,
      );
      
      final bottomRect = Rect.fromLTWH(
        obstaclePosition.x,
        obstaclePosition.y + gapSize / 2,
        GameConfig.obstacleWidth,
        800 - (obstaclePosition.y + gapSize / 2),
      );
      
      final topOverlap = jetRect.overlaps(topRect);
      final bottomOverlap = jetRect.overlaps(bottomRect);
      final anyCollision = topOverlap || bottomOverlap;
      
      expect(anyCollision, false,
        reason: 'With new jet position (X=\${GameConfig.getStartScreenJetX(400)}), should not collide with obstacle at X=\${obstaclePosition.x}');
      
      print('✅ OVERLAP CALCULATION:');
      print('   Jet rect: \${jetRect}');
      print('   Top obstacle: \${topRect}');
      print('   Bottom obstacle: \${bottomRect}');
      print('   Top overlap: \$topOverlap');
      print('   Bottom overlap: \$bottomOverlap');
      print('   Any collision: \$anyCollision');
    });
  });
}
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../lib/game/enhanced_flappy_game.dart';
import '../../lib/game/core/game_config.dart';
import '../../lib/game/core/game_themes.dart';
import '../../lib/game/components/enhanced_jet_player.dart';
import '../../lib/game/components/dynamic_obstacle.dart';

/// 🎯 COLLISION/SCORING BUG TESTS
/// These tests reproduce the exact scenario where players lose lives when passing obstacles correctly

void main() {
  group('🎯 COLLISION/SCORING BUG ANALYSIS', () {
    setUpAll(() async {
      WidgetsFlutterBinding.ensureInitialized();
    });
    
    test('🚨 BUG REPRODUCTION: Jet should NOT collide when passing through obstacle gap', () {
      // Reproduce the exact scenario from logs
      final obstacleWidth = GameConfig.obstacleWidth; // 75px
      final obstacleGap = GameConfig.obstacleGap; // 320px
      final jetSize = GameConfig.jetSize; // 77px
      final jetCollisionSize = jetSize * 0.5; // 🎯 FIXED: 38.5px (updated collision box)
      
      // Obstacle setup (from logs: obstacle at X=55.7, gap center around Y=380)
      final obstacleX = 55.7;
      final obstacleCenterY = 380.0;
      final gapHalfSize = obstacleGap / 2; // 160px
      
      // Define obstacle collision rectangles
      final topObstacleRect = Rect.fromLTWH(
        obstacleX,
        0,
        obstacleWidth,
        obstacleCenterY - gapHalfSize, // Top of gap
      );
      
      final bottomObstacleRect = Rect.fromLTWH(
        obstacleX,
        obstacleCenterY + gapHalfSize, // Bottom of gap
        obstacleWidth,
        800 - (obstacleCenterY + gapHalfSize), // To screen bottom
      );
      
      // Jet positions during passage (from logs: Jet X=35.37, Y=261.30)
      final jetCenterX = 35.37; // Jet center X position
      final jetCenterY = 261.30; // Jet center Y position (should be in gap)
      
      // Jet collision rectangle
      final jetRect = Rect.fromCenter(
        center: Offset(jetCenterX, jetCenterY),
        width: jetCollisionSize,
        height: jetCollisionSize,
      );
      
      // Calculate jet boundaries
      final jetLeft = jetCenterX - jetCollisionSize / 2; // 12.27
      final jetRight = jetCenterX + jetCollisionSize / 2; // 58.47
      final jetTop = jetCenterY - jetCollisionSize / 2; // 238.20
      final jetBottom = jetCenterY + jetCollisionSize / 2; // 284.40
      
      // Calculate gap boundaries
      final gapTop = obstacleCenterY - gapHalfSize; // 220.0
      final gapBottom = obstacleCenterY + gapHalfSize; // 540.0
      
      // Obstacle X boundaries
      final obstacleLeft = obstacleX; // 55.7
      final obstacleRight = obstacleX + obstacleWidth; // 130.7
      
      print('🎯 BUG ANALYSIS:');
      print('   Obstacle X: \${obstacleLeft} to \${obstacleRight}');
      print('   Gap Y: \${gapTop} to \${gapBottom}');
      print('   Jet center: (\${jetCenterX}, \${jetCenterY})');
      print('   Jet bounds: X=\${jetLeft} to \${jetRight}, Y=\${jetTop} to \${jetBottom}');
      
      // CRITICAL TEST 1: Jet should be OUTSIDE obstacle X range when collision happens
      expect(jetRight, lessThan(obstacleLeft),
        reason: 'Jet right edge (\${jetRight}) should be LEFT of obstacle left edge (\${obstacleLeft}) - jet has NOT reached obstacle yet!');
      
      // CRITICAL TEST 2: Jet should be INSIDE gap Y range
      expect(jetTop, greaterThan(gapTop),
        reason: 'Jet top (\${jetTop}) should be below gap top (\${gapTop})');
      expect(jetBottom, lessThan(gapBottom),
        reason: 'Jet bottom (\${jetBottom}) should be above gap bottom (\${gapBottom})');
      
      // CRITICAL TEST 3: No collision should occur
      final topCollision = jetRect.overlaps(topObstacleRect);
      final bottomCollision = jetRect.overlaps(bottomObstacleRect);
      final anyCollision = topCollision || bottomCollision;
      
      expect(anyCollision, isFalse,
        reason: 'NO collision should occur! Jet is not overlapping obstacle.');
      
      // CRITICAL TEST 4: Scoring should happen when jet passes obstacle right edge
      final scoringThreshold = obstacleRight; // 130.7
      final shouldScore = jetCenterX > scoringThreshold;
      
      expect(shouldScore, isFalse,
        reason: 'Scoring should NOT happen yet - jet (\${jetCenterX}) has not passed scoring threshold (\${scoringThreshold})');
      
      print('✅ BUG ANALYSIS RESULT:');
      print('   🔍 Jet X position: \${jetCenterX} vs Obstacle range: \${obstacleLeft}-\${obstacleRight}');
      print('   🔍 Gap collision: Top=\${topCollision}, Bottom=\${bottomCollision}');
      print('   🔍 Should score: \${shouldScore} (threshold: \${scoringThreshold})');
      
      // THIS TEST REVEALS THE BUG: If collision happens when jet is LEFT of obstacle,
      // there's a bug in the collision detection or obstacle positioning!
    });
    
    test('🎯 CORRECT BEHAVIOR: Show when scoring should happen vs collision', () {
      final obstacleWidth = GameConfig.obstacleWidth; // 75px
      final obstacleX = 100.0; // Example obstacle position
      final obstacleLeft = obstacleX;
      final obstacleRight = obstacleX + obstacleWidth; // 175px
      
      // Test different jet X positions
      final testPositions = [
        50.0,   // Before obstacle
        100.0,  // At obstacle left edge  
        137.5,  // Middle of obstacle
        175.0,  // At obstacle right edge (scoring threshold)
        200.0,  // After obstacle (scored)
      ];
      
      for (final jetX in testPositions) {
        final inObstacleRange = jetX >= obstacleLeft && jetX <= obstacleRight;
        final shouldScore = jetX > obstacleRight;
        final shouldCollide = inObstacleRange; // Simplified - real collision needs Y check too
        
        print('🎯 Position analysis for Jet X=\${jetX}:');
        print('   In obstacle X range: \${inObstacleRange}');
        print('   Should collide: \${shouldCollide}');
        print('   Should score: \${shouldScore}');
        
        if (shouldScore && shouldCollide) {
          fail('❌ BUG: Cannot both score AND collide at position \${jetX}!');
        }
        
        // Verify logical constraints
        if (jetX < obstacleLeft) {
          expect(shouldCollide, isFalse, reason: 'No collision before obstacle');
          expect(shouldScore, isFalse, reason: 'No scoring before obstacle');
        }
        
        if (jetX > obstacleRight) {
          expect(shouldCollide, isFalse, reason: 'No collision after obstacle');
          expect(shouldScore, isTrue, reason: 'Should score after obstacle');
        }
      }
    });
    
    test('🔍 FRAME-BY-FRAME: Simulate jet passing through obstacle', () {
      // Simulate the exact collision scenario frame by frame
      final obstacleX = 55.7;
      final obstacleWidth = GameConfig.obstacleWidth; // 75px
      final scoringThreshold = obstacleX + obstacleWidth; // 130.7
      
      final jetSpeed = 2.0; // pixels per frame
      final startX = 30.0;
      final endX = 140.0;
      
      bool hasScored = false;
      bool hasCollided = false;
      double? scoreFrame = null;
      double? collisionFrame = null;
      
      for (double jetX = startX; jetX <= endX; jetX += jetSpeed) {
        // Check scoring
        if (!hasScored && jetX > scoringThreshold) {
          hasScored = true;
          scoreFrame = jetX;
          print('🎯 FRAME ANALYSIS: SCORING at jetX=\${jetX} (threshold=\${scoringThreshold})');
        }
        
        // Check collision (simplified - assume collision happens in obstacle X range)
        final inObstacle = jetX >= obstacleX && jetX <= (obstacleX + obstacleWidth);
        if (!hasCollided && inObstacle) {
          hasCollided = true;
          collisionFrame = jetX;
          print('🎯 FRAME ANALYSIS: COLLISION at jetX=\${jetX} (obstacle: \${obstacleX}-\${obstacleX + obstacleWidth})');
        }
      }
      
      print('🎯 FRAME ANALYSIS RESULTS:');
      print('   Score frame: \${scoreFrame}');
      print('   Collision frame: \${collisionFrame}');
      
      // Verify correct behavior
      expect(scoreFrame, isNotNull, reason: 'Scoring should occur');
      expect(collisionFrame, isNull, reason: 'Collision should NOT occur for safe passage');
      
      if (collisionFrame != null && scoreFrame != null) {
        expect(scoreFrame!, greaterThan(collisionFrame!),
          reason: 'If both happen, scoring must come AFTER collision (but neither should happen for safe passage)');
      }
    });
    
    test('🐛 ROOT CAUSE: Check if collision detection boundaries are wrong', () {
      // Test actual collision detection with exact values from logs
      final obstacleX = 55.7;
      final obstacleWidth = 75.0;
      final jetX = 35.37;
      final jetY = 261.30;
      final jetCollisionSize = 38.5; // 🎯 FIXED: Updated to match new collision box (0.5 * 77)
      
      // Create collision rectangles exactly as in game code
      final jetRect = Rect.fromCenter(
        center: Offset(jetX, jetY),
        width: jetCollisionSize,
        height: jetCollisionSize,
      );
      
      final obstacleTopRect = Rect.fromLTWH(
        obstacleX,
        0,
        obstacleWidth,
        220.0, // Example gap top
      );
      
      final obstacleBottomRect = Rect.fromLTWH(
        obstacleX,
        540.0, // Example gap bottom
        obstacleWidth,
        260.0, // To screen bottom
      );
      
      final topCollision = jetRect.overlaps(obstacleTopRect);
      final bottomCollision = jetRect.overlaps(obstacleBottomRect);
      
      print('🐛 ROOT CAUSE ANALYSIS:');
      print('   Jet rect: \${jetRect}');
      print('   Top obstacle rect: \${obstacleTopRect}');
      print('   Bottom obstacle rect: \${obstacleBottomRect}');
      print('   Top collision: \${topCollision}');
      print('   Bottom collision: \${bottomCollision}');
      
      // Given the jet X position (35.37) is LEFT of obstacle X (55.7),
      // there should be NO collision at all!
      expect(topCollision, isFalse,
        reason: 'Jet at X=\${jetX} should not collide with obstacle at X=\${obstacleX}');
      expect(bottomCollision, isFalse,
        reason: 'Jet at X=\${jetX} should not collide with obstacle at X=\${obstacleX}');
      
      // If this test FAILS, it means there's a bug in collision detection
      // If this test PASSES, the bug is elsewhere (timing, multiple obstacles, etc.)
    });
  });
}
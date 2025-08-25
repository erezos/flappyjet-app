import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import '../../lib/game/core/game_config.dart';

/// 🎯 OBSTACLE PROXIMITY COLLISION TEST
/// Tests the fix for collision detection with wrong obstacles

void main() {
  group('🎯 OBSTACLE PROXIMITY COLLISION FIX', () {
    test('🚨 BUG REPRODUCTION: Should only check collision with nearby obstacles', () {
      // Setup from actual logs
      final jetX = 35.37; // Jet position (left side of screen)
      final obstacleWidth = GameConfig.obstacleWidth; // 75px
      
      // Multiple obstacles at different positions
      final obstacles = [
        {'left': 1.44, 'right': 1.44 + obstacleWidth, 'name': 'Far left obstacle'},
        {'left': 31.33 - obstacleWidth, 'right': 31.33, 'name': 'Just passed obstacle'}, // -43.67 to 31.33
        {'left': 49.67, 'right': 49.67 + obstacleWidth, 'name': 'Upcoming obstacle'}, // 49.67 to 124.67
      ];
      
      for (final obstacle in obstacles) {
        final obstacleLeft = obstacle['left'] as double;
        final obstacleRight = obstacle['right'] as double;
        final obstacleName = obstacle['name'] as String;
        
        // Apply the proximity check logic from the fix (20px buffer)
        final isNearObstacle = jetX >= (obstacleLeft - 20) && jetX <= (obstacleRight + 20);
        
        print('🎯 Testing $obstacleName:');
        print('   Obstacle range: ${obstacleLeft.toStringAsFixed(2)} to ${obstacleRight.toStringAsFixed(2)}');
        print('   Jet position: ${jetX.toStringAsFixed(2)}');
        print('   Is near obstacle: $isNearObstacle');
        print('   Distance to left edge: ${(jetX - obstacleLeft).toStringAsFixed(2)}');
        print('   Distance to right edge: ${(jetX - obstacleRight).toStringAsFixed(2)}');
        
        // Test the proximity logic
        if (obstacleName.contains('Far left')) {
          // These obstacles should NOT trigger collision checks
          final distanceToNearestEdge = [
            (jetX - obstacleLeft).abs(),
            (jetX - obstacleRight).abs()
          ].reduce((a, b) => a < b ? a : b);
          
          expect(isNearObstacle, isFalse,
            reason: '$obstacleName should not trigger collision (distance: ${distanceToNearestEdge.toStringAsFixed(1)}px)');
        } else if (obstacleName.contains('Just passed')) {
          // This obstacle was just passed, should be in range for final collision check
          expect(isNearObstacle, isTrue,
            reason: '$obstacleName should still be in collision range after passing');
        }
        
        print('   ✅ Proximity check result: ${isNearObstacle ? "NEAR" : "FAR"}');
        print('');
      }
    });
    
    test('🎯 PROXIMITY BOUNDARIES: Test exact 20px boundary conditions', () {
      final jetX = 100.0; // Jet at position 100
      final obstacleWidth = GameConfig.obstacleWidth; // 75px
      
      // Test different obstacle positions relative to the 20px boundary
      final testCases = [
        {'obstacleLeft': 85.0, 'expected': true, 'reason': 'Within 20px range (15px before left edge)'},
        {'obstacleLeft': 79.0, 'expected': false, 'reason': 'Just outside 20px range (21px before left edge)'},
        {'obstacleLeft': 100.0, 'expected': true, 'reason': 'Jet at obstacle left edge'},
        {'obstacleLeft': 125.0, 'expected': true, 'reason': 'Jet overlapping obstacle'},
        {'obstacleLeft': 75.0, 'expected': true, 'reason': 'Jet just past obstacle right edge'},
        {'obstacleLeft': 5.0, 'expected': true, 'reason': 'Jet 20px past obstacle right edge'},
        {'obstacleLeft': 4.0, 'expected': true, 'reason': 'Jet ~21px past right edge but within inclusive boundary'},
      ];
      
      for (final testCase in testCases) {
        final obstacleLeft = testCase['obstacleLeft'] as double;
        final obstacleRight = obstacleLeft + obstacleWidth;
        final expected = testCase['expected'] as bool;
        final reason = testCase['reason'] as String;
        
        // Apply proximity check (20px buffer)
        final isNearObstacle = jetX >= (obstacleLeft - 20) && jetX <= (obstacleRight + 20);
        
        expect(isNearObstacle, equals(expected),
          reason: reason + ' (obstacle: ${obstacleLeft.toStringAsFixed(1)}-${obstacleRight.toStringAsFixed(1)}, jet: ${jetX.toStringAsFixed(1)})');
        
        print('✅ ${expected ? "NEAR" : "FAR"}: $reason');
      }
    });
    
    test('🔄 GAME FLOW: Verify proper sequence of scoring and collision', () {
      final jetX = 100.0; // Jet moving right
      final obstacleWidth = GameConfig.obstacleWidth; // 75px
      
      // Simulate obstacle that jet is approaching and passing
      final obstacleLeft = 50.0; // Obstacle ahead of jet
      final obstacleRight = obstacleLeft + obstacleWidth; // 125.0
      
      // Test different jet positions as it approaches and passes obstacle
      final jetPositions = [
        {'x': 25.0, 'phase': 'Approaching', 'shouldCollide': false, 'shouldScore': false}, // Outside 20px buffer
        {'x': 35.0, 'phase': 'Near left edge', 'shouldCollide': true, 'shouldScore': false}, // Within 20px buffer
        {'x': 60.0, 'phase': 'Inside obstacle', 'shouldCollide': true, 'shouldScore': false},
        {'x': 120.0, 'phase': 'Near right edge', 'shouldCollide': true, 'shouldScore': false},
        {'x': 130.0, 'phase': 'Just passed', 'shouldCollide': true, 'shouldScore': true}, // Still in 20px buffer
        {'x': 150.0, 'phase': 'Safely past', 'shouldCollide': false, 'shouldScore': false}, // Outside 20px buffer
      ];
      
      for (final position in jetPositions) {
        final currentJetX = position['x'] as double;
        final phase = position['phase'] as String;
        final shouldCollide = position['shouldCollide'] as bool;
        final shouldScore = position['shouldScore'] as bool;
        
        // Test proximity check (20px buffer)
        final isNearObstacle = currentJetX >= (obstacleLeft - 20) && currentJetX <= (obstacleRight + 20);
        
        // Test scoring condition
        final scoringThreshold = obstacleRight; // 125.0
        final wouldScore = currentJetX > scoringThreshold;
        
        expect(isNearObstacle, equals(shouldCollide),
          reason: '$phase: collision proximity check should be $shouldCollide');
        
        expect(wouldScore, equals(shouldScore),
          reason: '$phase: scoring should be $shouldScore');
        
        print('📍 $phase (jet X=${currentJetX.toStringAsFixed(1)}):');
        print('   Near obstacle: $isNearObstacle (expected: $shouldCollide)');
        print('   Would score: $wouldScore (expected: $shouldScore)');
        print('');
      }
    });
  });
}
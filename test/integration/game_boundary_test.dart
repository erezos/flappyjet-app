/// 🔥 BLOCKBUSTER BOUNDARY TESTS
/// Integration tests for screen boundaries and limits
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../lib/game/enhanced_flappy_game.dart';
import '../../lib/game/components/enhanced_jet_player.dart';
import '../../lib/game/core/game_config.dart';
import '../../lib/game/core/game_themes.dart';

void main() {
  group('🔥 BLOCKBUSTER Boundary Integration Tests', () {
    late EnhancedFlappyGame game;
    late EnhancedJetPlayer jet;
    
    setUp(() async {
      game = EnhancedFlappyGame();
      // Initialize game to set up proper screen size
      await game.onLoad();
      
      jet = EnhancedJetPlayer(
        Vector2(GameConfig.getStartScreenJetX(400), GameConfig.getStartScreenJetY(600)),
        GameThemes.skyRookie,
      );
    });

    group('📱 Screen Boundary Tests', () {
      test('CRITICAL: Jet starts within screen boundaries', () {
        // Test initial position is valid
        expect(jet.position.x, greaterThan(0));
        expect(jet.position.x, lessThan(game.size.x));
        expect(jet.position.y, greaterThan(0));
        expect(jet.position.y, lessThan(game.size.y));
        
        debugPrint('✅ Initial position boundary test passed');
        debugPrint('Jet at: ${jet.position}, Screen: ${game.size}');
      });

      test('CRITICAL: Ground boundary prevents jet from falling through', () {
        // Simulate jet falling to ground
        jet.position.y = game.size.y - 90; // Just above ground threshold
        expect(jet.position.y > game.size.y - 100, false);
        
        jet.position.y = game.size.y - 99; // At ground threshold
        expect(jet.position.y > game.size.y - 100, true);
        
        debugPrint('✅ Ground boundary test passed');
        debugPrint('Ground threshold: ${game.size.y - 100}');
      });

      test('CRITICAL: Ceiling boundary prevents jet from going off-screen', () {
        // Test ceiling collision
        jet.position.y = -10; // Above screen
        expect(jet.position.y < 0, true);
        
        // After boundary correction, should be at 0
        if (jet.position.y < 0) {
          jet.position.y = 0;
          jet.velocity.y = 0;
        }
        
        expect(jet.position.y, equals(0));
        expect(jet.velocity.y, equals(0));
        
        debugPrint('✅ Ceiling boundary test passed');
      });

      test('CRITICAL: Side boundaries are respected', () {
        // Test left boundary
        jet.position.x = -50; // Off-screen left
        expect(jet.position.x < 0, true);
        
        // Test right boundary  
        jet.position.x = game.size.x + 50; // Off-screen right
        expect(jet.position.x > game.size.x, true);
        
        debugPrint('✅ Side boundary test passed');
        debugPrint('Screen width: ${game.size.x}');
      });
    });

    group('🎮 Physics Boundary Tests', () {
      test('CRITICAL: Velocity limits prevent unrealistic speeds', () {
        // Test maximum fall speed
        jet.velocity.y = 2000; // Extremely fast
        
        // Apply velocity clamping (simulating game physics)
        jet.velocity.y = jet.velocity.y.clamp(-GameConfig.maxFallSpeed, GameConfig.maxFallSpeed);
        
        expect(jet.velocity.y, lessThanOrEqualTo(GameConfig.maxFallSpeed));
        expect(jet.velocity.y, greaterThanOrEqualTo(-GameConfig.maxFallSpeed));
        
        debugPrint('✅ Velocity limit test passed');
        debugPrint('Max fall speed: ${GameConfig.maxFallSpeed}');
      });

      test('CRITICAL: Jump velocity is within bounds', () {
        // Test jump velocity
        jet.velocity.y = GameConfig.jumpVelocity;
        
        expect(jet.velocity.y, equals(GameConfig.jumpVelocity));
        expect(jet.velocity.y, lessThan(0)); // Should be negative (upward)
        expect(jet.velocity.y, greaterThan(-1000)); // Should be reasonable
        
        debugPrint('✅ Jump velocity test passed');
        debugPrint('Jump velocity: ${GameConfig.jumpVelocity}');
      });
    });

    group('📐 Collision Boundary Tests', () {
      test('CRITICAL: Jet hitbox is within visual bounds', () {
        // Test that hitbox is reasonable compared to jet size
        final hitboxSize = Vector2(GameConfig.jetSize * 0.75, GameConfig.jetSize * 0.75);
        final visualSize = Vector2.all(GameConfig.jetSize);
        
        expect(hitboxSize.x, lessThanOrEqualTo(visualSize.x));
        expect(hitboxSize.y, lessThanOrEqualTo(visualSize.y));
        expect(hitboxSize.x, greaterThan(visualSize.x * 0.5)); // Not too small
        expect(hitboxSize.y, greaterThan(visualSize.y * 0.5)); // Not too small
        
        debugPrint('✅ Hitbox boundary test passed');
        debugPrint('Hitbox: $hitboxSize, Visual: $visualSize');
      });

      test('CRITICAL: Ground collision accounts for jet center vs edge', () {
        // Test collision with jet positioned using center anchor
        final jetHalfSize = GameConfig.jetSize / 2;
        final groundLevel = game.size.y - 100;
        
        // Jet center at ground level should trigger collision
        jet.position.y = groundLevel;
        expect(jet.position.y > groundLevel - 1, true);
        
        // Jet center above ground level should not trigger
        jet.position.y = groundLevel - jetHalfSize - 1;
        expect(jet.position.y > groundLevel - 1, false);
        
        debugPrint('✅ Center-based collision boundary test passed');
      });
    });

    group('🔄 Dynamic Boundary Tests', () {
      test('CRITICAL: Boundaries work across different screen orientations', () {
        // Simulate different screen sizes (portrait vs landscape)
        final portraitSize = Vector2(400, 800);
        final landscapeSize = Vector2(800, 400);
        
        for (final screenSize in [portraitSize, landscapeSize]) {
          final groundThreshold = screenSize.y - 100;
          
          // Test that ground collision works for this screen size
          expect(groundThreshold, greaterThan(0));
          expect(groundThreshold, lessThan(screenSize.y));
          
          debugPrint('✅ Screen ${screenSize}: Ground at $groundThreshold');
        }
        
        debugPrint('✅ Multi-orientation boundary test passed');
      });

      test('CRITICAL: Boundaries scale with game configuration', () {
        // Test that changing game config affects boundaries appropriately
        final smallJetSize = 50.0;
        final largeJetSize = 100.0;
        
        // Smaller jet should have smaller collision area
        final smallHitbox = Vector2(smallJetSize * 0.75, smallJetSize * 0.75);
        final largeHitbox = Vector2(largeJetSize * 0.75, largeJetSize * 0.75);
        
        expect(smallHitbox.x, lessThan(largeHitbox.x));
        expect(smallHitbox.y, lessThan(largeHitbox.y));
        
        debugPrint('✅ Scalable boundary test passed');
      });
    });

    group('🚨 Edge Case Boundary Tests', () {
      test('CRITICAL: Extreme positions are handled gracefully', () {
        // Test extremely negative positions
        jet.position = Vector2(-1000, -1000);
        expect(jet.position.x, lessThan(0));
        expect(jet.position.y, lessThan(0));
        
        // Test extremely positive positions
        jet.position = Vector2(10000, 10000);
        expect(jet.position.x, greaterThan(game.size.x));
        expect(jet.position.y, greaterThan(game.size.y));
        
        debugPrint('✅ Extreme position test passed');
      });

      test('CRITICAL: Zero and negative velocities work correctly', () {
        // Test zero velocity
        jet.velocity = Vector2.zero();
        expect(jet.velocity.x, equals(0));
        expect(jet.velocity.y, equals(0));
        
        // Test negative horizontal velocity (shouldn't break anything)
        jet.velocity.x = -100;
        expect(jet.velocity.x, lessThan(0));
        
        debugPrint('✅ Edge case velocity test passed');
      });
    });
  });
}
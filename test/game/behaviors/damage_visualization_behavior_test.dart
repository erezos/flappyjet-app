/// DamageVisualizationBehavior Tests (TDD Red Phase)
/// 
/// Tests written BEFORE implementation
/// Expected: Tests will FAIL initially
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import '../../../lib/game/behaviors/damage_visualization_behavior.dart';
import '../../../lib/game/components/jet_player.dart';

void main() {
  group('DamageVisualizationBehavior', () {
    
    test('updates damage state based on lives count', () {
      final behavior = DamageVisualizationBehavior();
      
      // 3 hearts = healthy
      behavior.updateFromLives(3);
      expect(behavior.currentState, JetDamageState.healthy);
      
      // 2 hearts = damaged
      behavior.updateFromLives(2);
      expect(behavior.currentState, JetDamageState.damaged);
      
      // 1 heart = critical
      behavior.updateFromLives(1);
      expect(behavior.currentState, JetDamageState.critical);
    });
    
    test('triggers flash animation on damage', () {
      final behavior = DamageVisualizationBehavior();
      
      // Initially not flashing
      expect(behavior.isFlashing, false);
      
      // Take damage
      behavior.updateFromLives(2);
      
      // Should trigger flash
      expect(behavior.isFlashing, true);
    });
    
    test('flash animation completes after duration', () {
      final behavior = DamageVisualizationBehavior(
        flashDuration: 0.2, // 200ms
      );
      
      // Trigger flash
      behavior.updateFromLives(2);
      expect(behavior.isFlashing, true);
      
      // Update for half duration
      behavior.update(0.1);
      expect(behavior.isFlashing, true, reason: 'Should still be flashing');
      
      // Update past duration
      behavior.update(0.15); // Total 0.25s > 0.2s
      expect(behavior.isFlashing, false, reason: 'Flash should complete');
    });
    
    test('pending damage state applies after invulnerability ends', () {
      final behavior = DamageVisualizationBehavior();
      
      // Take damage while invulnerable
      behavior.setInvulnerable(true);
      behavior.updateFromLives(2);
      
      // Damage state should be pending
      expect(behavior.hasPendingState, true);
      
      // End invulnerability
      behavior.setInvulnerable(false);
      
      // Pending state should now apply
      expect(behavior.currentState, JetDamageState.damaged);
      expect(behavior.hasPendingState, false);
    });
    
    test('provides opacity for flash effect', () {
      final behavior = DamageVisualizationBehavior(
        flashDuration: 0.2,
      );
      
      behavior.updateFromLives(2); // Trigger flash
      
      // At start of flash
      final initialOpacity = behavior.flashOpacity;
      expect(initialOpacity, lessThan(1.0), reason: 'Should start fading');
      
      // Early in flash (avoid exact midpoint where sine peaks)
      behavior.update(0.05);
      final earlyOpacity = behavior.flashOpacity;
      expect(earlyOpacity, greaterThan(initialOpacity), reason: 'Opacity should increase');
      expect(earlyOpacity, lessThan(1.0), reason: 'Should still be flashing');
      
      // After flash completes
      behavior.update(0.2);
      expect(behavior.flashOpacity, 1.0, reason: 'Should return to full opacity');
    });
  });
}


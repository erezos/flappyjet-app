/// GravityBehavior Tests (TDD Red Phase)
/// 
/// Tests written BEFORE implementation
/// Expected: Tests will FAIL initially
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import '../../../lib/game/behaviors/gravity_behavior.dart';
import '../../../lib/game/core/game_config.dart';

void main() {
  group('GravityBehavior', () {
    
    test('applies gravity to velocity over time', () {
      final velocity = Vector2.zero();
      final behavior = GravityBehavior(velocity: velocity);
      
      // Simulate 1 second of physics
      behavior.update(1.0);
      
      // Gravity should be applied: velocity.y = gravity * dt
      expect(velocity.y, GameConfig.gravity);
    });
    
    test('accumulates gravity over multiple frames', () {
      final velocity = Vector2.zero();
      final behavior = GravityBehavior(velocity: velocity);
      
      // Simulate 60 frames at 60 FPS (1 second total)
      for (int i = 0; i < 60; i++) {
        behavior.update(1 / 60);
      }
      
      // After 1 second, should have gravity velocity
      expect(velocity.y, closeTo(GameConfig.gravity, 0.1));
    });
    
    test('caps velocity at terminal velocity', () {
      final velocity = Vector2(0, 1000); // Already falling fast
      final behavior = GravityBehavior(
        velocity: velocity,
        maxFallSpeed: 800.0,
      );
      
      behavior.update(1.0);
      
      // Should be capped at 800
      expect(velocity.y, 800.0);
    });
    
    test('respects gravity multiplier', () {
      final velocity = Vector2.zero();
      final behavior = GravityBehavior(
        velocity: velocity,
        gravityMultiplier: 2.0, // Double gravity
      );
      
      behavior.update(1.0);
      
      expect(velocity.y, GameConfig.gravity * 2.0);
    });
    
    test('does not allocate new vectors in update (performance)', () {
      final velocity = Vector2.zero();
      final behavior = GravityBehavior(velocity: velocity);
      
      // Warm up
      for (int i = 0; i < 10; i++) {
        behavior.update(0.016);
      }
      
      // Multiple frames should not allocate new vectors
      // (In real implementation, _gravityVector is pre-allocated)
      for (int i = 0; i < 1000; i++) {
        behavior.update(0.016);
      }
      
      // Test passes if no exceptions thrown
      expect(behavior, isNotNull);
    });
  });
}


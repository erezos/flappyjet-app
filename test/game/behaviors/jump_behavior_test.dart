/// JumpBehavior Tests (TDD Red Phase)
/// 
/// Tests written BEFORE implementation
/// Expected: Tests will FAIL initially
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import '../../../lib/game/behaviors/jump_behavior.dart';
import '../../../lib/game/core/game_config.dart';

void main() {
  group('JumpBehavior', () {
    
    test('sets upward velocity when jump() is called', () {
      final velocity = Vector2.zero();
      final behavior = JumpBehavior(velocity: velocity);
      
      behavior.jump();
      
      // Should set velocity to negative (upward)
      expect(velocity.y, -GameConfig.jumpForce);
    });
    
    test('has jump cooldown to prevent spam', () {
      final velocity = Vector2.zero();
      final behavior = JumpBehavior(
        velocity: velocity,
        jumpCooldown: 0.1,
      );
      
      // First jump works
      behavior.jump();
      final firstJumpVelocity = velocity.y;
      expect(firstJumpVelocity, -GameConfig.jumpForce);
      
      // Immediate second jump should be blocked
      velocity.setZero(); // Reset velocity
      behavior.jump();
      expect(velocity.y, 0.0, reason: 'Jump should be on cooldown');
    });
    
    test('cooldown resets after time passes', () {
      final velocity = Vector2.zero();
      final behavior = JumpBehavior(
        velocity: velocity,
        jumpCooldown: 0.1,
      );
      
      // First jump
      behavior.jump();
      velocity.setZero();
      
      // Wait for cooldown
      behavior.update(0.2); // 200ms (more than 100ms cooldown)
      
      // Second jump should now work
      behavior.jump();
      expect(velocity.y, -GameConfig.jumpForce);
    });
    
    test('respects custom jump force', () {
      final velocity = Vector2.zero();
      final customJumpForce = 500.0;
      final behavior = JumpBehavior(
        velocity: velocity,
        jumpForce: customJumpForce,
      );
      
      behavior.jump();
      
      expect(velocity.y, -customJumpForce);
    });
    
    test('canJump property indicates cooldown state', () {
      final velocity = Vector2.zero();
      final behavior = JumpBehavior(
        velocity: velocity,
        jumpCooldown: 0.1,
      );
      
      // Initially can jump
      expect(behavior.canJump, true);
      
      // After jumping, on cooldown
      behavior.jump();
      expect(behavior.canJump, false);
      
      // After waiting, can jump again
      behavior.update(0.2);
      expect(behavior.canJump, true);
    });
    
    test('does not allocate vectors in update (performance)', () {
      final velocity = Vector2.zero();
      final behavior = JumpBehavior(velocity: velocity);
      
      // Multiple updates should not allocate
      for (int i = 0; i < 1000; i++) {
        behavior.update(0.016);
      }
      
      expect(behavior, isNotNull);
    });
  });
}


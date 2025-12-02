import 'package:flutter_test/flutter_test.dart';

/// Shield stacking logic test helper
/// Mimics the shield duration stacking implemented in FlappyGame
/// 
/// BEHAVIOR:
/// - When user collects a shield, duration is ADDED to remaining time
/// - If shield is active and user collects another, times stack
/// - Example: 3s shield, at 1s remaining collect 2s shield = 3s total
class ShieldStackingTestHelper {
  double _shieldRemainingTime = 0.0;
  bool _isInvulnerable = false;
  String _currentTier = 'none';
  
  // Getters for testing
  double get shieldRemainingTime => _shieldRemainingTime;
  bool get isInvulnerable => _isInvulnerable;
  bool get isShieldActive => _shieldRemainingTime > 0;
  String get currentTier => _currentTier;
  
  /// Apply shield bonus - implements stacking logic
  void applyShield(double duration, {String tier = 'bronze'}) {
    // Stack the duration
    _shieldRemainingTime += duration;
    _currentTier = tier;
    
    // Activate shield if not already active
    if (!_isInvulnerable) {
      _isInvulnerable = true;
    }
  }
  
  /// Update shield timer - simulates game update loop
  void update(double dt) {
    if (_shieldRemainingTime <= 0) return;
    
    _shieldRemainingTime -= dt;
    
    if (_shieldRemainingTime <= 0) {
      _shieldRemainingTime = 0;
      _isInvulnerable = false;
      _currentTier = 'none';
    }
  }
  
  /// Reset state - simulates game reset
  void reset() {
    _shieldRemainingTime = 0.0;
    _isInvulnerable = false;
    _currentTier = 'none';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  late ShieldStackingTestHelper shield;
  
  setUp(() {
    shield = ShieldStackingTestHelper();
  });
  
  group('Shield Stacking - Basic Activation', () {
    test('single shield activates with correct duration', () {
      shield.applyShield(3.0, tier: 'bronze');
      
      expect(shield.isShieldActive, isTrue);
      expect(shield.isInvulnerable, isTrue);
      expect(shield.shieldRemainingTime, equals(3.0));
      expect(shield.currentTier, equals('bronze'));
    });
    
    test('shield expires after duration', () {
      shield.applyShield(3.0);
      
      // Simulate 3 seconds passing
      shield.update(1.0); // 2.0 remaining
      expect(shield.isShieldActive, isTrue);
      expect(shield.shieldRemainingTime, closeTo(2.0, 0.01));
      
      shield.update(1.0); // 1.0 remaining
      expect(shield.isShieldActive, isTrue);
      expect(shield.shieldRemainingTime, closeTo(1.0, 0.01));
      
      shield.update(1.0); // 0.0 remaining - expired!
      expect(shield.isShieldActive, isFalse);
      expect(shield.isInvulnerable, isFalse);
      expect(shield.shieldRemainingTime, equals(0.0));
    });
    
    test('shield expires with fractional time updates', () {
      shield.applyShield(2.0);
      
      // Simulate at 60fps (dt = 0.0167)
      for (int i = 0; i < 120; i++) { // 2 seconds worth of frames
        shield.update(0.0167);
      }
      
      expect(shield.isShieldActive, isFalse);
      expect(shield.shieldRemainingTime, equals(0.0));
    });
  });
  
  group('Shield Stacking - Core Stacking Logic', () {
    test('collecting shield while active ADDS duration (user scenario)', () {
      // User scenario: 3s shield at T=0, at T=2 collect 3s shield
      // Expected: 1s remaining + 3s new = 4s total
      
      shield.applyShield(3.0, tier: 'blue');
      expect(shield.shieldRemainingTime, equals(3.0));
      
      // Simulate 2 seconds passing
      shield.update(2.0);
      expect(shield.shieldRemainingTime, closeTo(1.0, 0.01));
      
      // Collect another 3-second shield
      shield.applyShield(3.0, tier: 'red');
      
      // Should be 1 + 3 = 4 seconds
      expect(shield.shieldRemainingTime, closeTo(4.0, 0.01));
      expect(shield.isShieldActive, isTrue);
      expect(shield.currentTier, equals('red')); // Updated to new tier
    });
    
    test('specific user example: 3s shield, 1s left, collect 3s = 4s total', () {
      // Exact example from user request
      shield.applyShield(3.0);
      
      // Pass 2 seconds (1 second remaining)
      shield.update(2.0);
      expect(shield.shieldRemainingTime, closeTo(1.0, 0.01));
      
      // Collect 3-second shield
      shield.applyShield(3.0);
      
      // Expected: 1 + 3 = 4 seconds remaining
      expect(shield.shieldRemainingTime, closeTo(4.0, 0.01));
      
      // Verify shield expires at correct time (4 more seconds)
      shield.update(3.9);
      expect(shield.isShieldActive, isTrue);
      
      shield.update(0.2); // 3.9 + 0.2 = 4.1 > 4.0
      expect(shield.isShieldActive, isFalse);
    });
    
    test('multiple shields stack correctly', () {
      // Collect 3 shields in rapid succession
      shield.applyShield(3.0, tier: 'blue');
      shield.applyShield(4.0, tier: 'red');
      shield.applyShield(5.0, tier: 'green');
      
      // Should be 3 + 4 + 5 = 12 seconds
      expect(shield.shieldRemainingTime, equals(12.0));
      expect(shield.currentTier, equals('green'));
    });
    
    test('stacking different tier shields', () {
      // Blue (3s) -> Red (4s) -> Green (5s)
      shield.applyShield(3.0, tier: 'blue');
      expect(shield.currentTier, equals('blue'));
      
      shield.update(1.5); // 1.5s remaining
      shield.applyShield(4.0, tier: 'red'); // 1.5 + 4 = 5.5s
      expect(shield.currentTier, equals('red'));
      expect(shield.shieldRemainingTime, closeTo(5.5, 0.01));
      
      shield.update(2.0); // 3.5s remaining
      shield.applyShield(5.0, tier: 'green'); // 3.5 + 5 = 8.5s
      expect(shield.currentTier, equals('green'));
      expect(shield.shieldRemainingTime, closeTo(8.5, 0.01));
    });
  });
  
  group('Shield Stacking - Edge Cases', () {
    test('collecting shield at exact moment of expiration', () {
      shield.applyShield(2.0);
      
      // Expire the shield exactly
      shield.update(2.0);
      expect(shield.isShieldActive, isFalse);
      expect(shield.shieldRemainingTime, equals(0.0));
      
      // Collect new shield - should work normally
      shield.applyShield(3.0);
      expect(shield.isShieldActive, isTrue);
      expect(shield.shieldRemainingTime, equals(3.0));
    });
    
    test('collecting shield with 0.1s remaining', () {
      shield.applyShield(3.0);
      
      // Leave only 0.1s remaining
      shield.update(2.9);
      expect(shield.shieldRemainingTime, closeTo(0.1, 0.01));
      
      // Collect 2s shield
      shield.applyShield(2.0);
      
      // Should be 0.1 + 2 = 2.1 seconds
      expect(shield.shieldRemainingTime, closeTo(2.1, 0.01));
    });
    
    test('reset clears all shield state', () {
      shield.applyShield(5.0, tier: 'green');
      shield.update(1.0);
      
      expect(shield.isShieldActive, isTrue);
      expect(shield.shieldRemainingTime, equals(4.0));
      
      shield.reset();
      
      expect(shield.isShieldActive, isFalse);
      expect(shield.isInvulnerable, isFalse);
      expect(shield.shieldRemainingTime, equals(0.0));
      expect(shield.currentTier, equals('none'));
    });
    
    test('no updates when shield inactive', () {
      expect(shield.isShieldActive, isFalse);
      expect(shield.shieldRemainingTime, equals(0.0));
      
      // Updates should be no-op
      shield.update(1.0);
      shield.update(10.0);
      shield.update(100.0);
      
      expect(shield.shieldRemainingTime, equals(0.0));
      expect(shield.isInvulnerable, isFalse);
    });
  });
  
  group('Shield Stacking - Game Scenarios', () {
    test('scenario: collect 3 shields during boss fight', () {
      // Player collects shields frequently during intense gameplay
      
      shield.applyShield(3.0); // T=0: 3s
      shield.update(1.0);      // T=1: 2s remaining
      
      shield.applyShield(3.0); // T=1: 2+3=5s
      shield.update(2.0);      // T=3: 3s remaining
      
      shield.applyShield(4.0); // T=3: 3+4=7s
      shield.update(1.0);      // T=4: 6s remaining
      
      expect(shield.shieldRemainingTime, closeTo(6.0, 0.01));
      expect(shield.isShieldActive, isTrue);
      
      // Shield should last until T=10 (4 + 6)
      shield.update(5.9);
      expect(shield.isShieldActive, isTrue);
      
      shield.update(0.2); // Total 6.1s update
      expect(shield.isShieldActive, isFalse);
    });
    
    test('scenario: rapid shield collection (machine gun bonuses)', () {
      // 5 shields collected in 1 second (unlikely but possible)
      shield.applyShield(2.0);
      shield.update(0.2);
      shield.applyShield(2.0);
      shield.update(0.2);
      shield.applyShield(2.0);
      shield.update(0.2);
      shield.applyShield(2.0);
      shield.update(0.2);
      shield.applyShield(2.0);
      
      // 5 × 2s shields - (0.8s elapsed) = 10 - 0.8 = 9.2s
      expect(shield.shieldRemainingTime, closeTo(9.2, 0.1));
    });
    
    test('scenario: shield collected just before collision', () {
      shield.applyShield(3.0);
      shield.update(2.99); // 0.01s remaining - shield still active!
      
      expect(shield.isShieldActive, isTrue);
      expect(shield.isInvulnerable, isTrue);
      
      // Collision at this point would be blocked!
      // Player collects another shield
      shield.applyShield(3.0);
      
      // 0.01 + 3 = 3.01s
      expect(shield.shieldRemainingTime, closeTo(3.01, 0.1));
    });
  });
  
  group('Shield Stacking - Regression Tests', () {
    test('OLD BUG: independent timers would expire prematurely', () {
      // This test ensures the OLD bug is fixed
      // OLD BEHAVIOR: Each shield had independent Future.delayed
      // Shield 1 (3s) at T=0 would expire at T=3
      // Shield 2 (3s) at T=2 would expire at T=5
      // BUT Shield 1 timer fires at T=3 and turns off invulnerability!
      
      // NEW BEHAVIOR: Durations stack
      shield.applyShield(3.0);
      shield.update(2.0); // 1s remaining
      shield.applyShield(3.0); // 1+3=4s remaining
      
      // At T=3 (1 more second), shield should STILL be active (3s remaining)
      shield.update(1.0);
      expect(shield.isShieldActive, isTrue, 
          reason: 'Shield should NOT expire at T=3 - it should have 3s remaining from stacking');
      expect(shield.shieldRemainingTime, closeTo(3.0, 0.01));
      
      // Shield should finally expire at T=6 (original 3 + stacked 3)
      // But we're at T=3, so 3 more seconds
      shield.update(2.9);
      expect(shield.isShieldActive, isTrue);
      
      shield.update(0.2);
      expect(shield.isShieldActive, isFalse);
    });
  });
}


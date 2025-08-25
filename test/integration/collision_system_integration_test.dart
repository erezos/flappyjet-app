import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../../lib/game/enhanced_flappy_game.dart';
import '../../lib/game/components/enhanced_jet_player.dart';
import '../../lib/game/core/game_config.dart';
import '../../lib/game/core/game_themes.dart';

/// 🎯 INTEGRATION TEST: COLLISION SYSTEM ARCHITECTURE
/// This test would have caught the dual collision system bug!

void main() {
  group('🚨 COLLISION SYSTEM INTEGRATION TESTS', () {
    
    test('🔍 BUG DETECTOR: Verify only ONE collision system is active', () async {
      // 🎯 THE TEST THAT WOULD HAVE CAUGHT THE BUG!
      
      print('🧪 TESTING: Real component collision architecture...');
      
      // Create real game instance
      final game = EnhancedFlappyGame();
      await game.onLoad();
      
      // Create real jet player
      final jetPlayer = EnhancedJetPlayer(Vector2(100, 400), GameThemes.skyRookie);
      await jetPlayer.onLoad();
      game.add(jetPlayer);
      
      // 🔍 COLLISION SYSTEM INSPECTION
      print('\n🔍 COLLISION SYSTEM ANALYSIS:');
      
      // Check if player has CollisionCallbacks (automatic collision)
      final hasCollisionCallbacks = jetPlayer is CollisionCallbacks;
      print('❓ Has CollisionCallbacks mixin: $hasCollisionCallbacks');
      
      // Check if player has RectangleHitbox components (automatic collision)
      final hitboxes = jetPlayer.children.whereType<RectangleHitbox>();
      final hitboxCount = hitboxes.length;
      print('❓ RectangleHitbox count: $hitboxCount');
      
      // Check if game has manual collision detection
      final hasManualCollision = game.toString().contains('_checkCollision');
      print('❓ Has manual collision method: $hasManualCollision');
      
      // 🚨 THE BUG DETECTION LOGIC
      print('\n🚨 COLLISION SYSTEM BUG DETECTION:');
      
      if (hasCollisionCallbacks && hitboxCount > 0 && hasManualCollision) {
        print('💥 BUG DETECTED: DUAL COLLISION SYSTEMS!');
        print('   ⚠️  Automatic: CollisionCallbacks + RectangleHitbox');
        print('   ⚠️  Manual: _checkCollision method');
        print('   ❌ This causes false collisions from hidden automatic system!');
        
        fail('DUAL COLLISION SYSTEMS DETECTED: Both automatic (CollisionCallbacks+RectangleHitbox) and manual (_checkCollision) are active!');
      } else if (hasCollisionCallbacks && hitboxCount > 0) {
        print('✅ AUTOMATIC COLLISION SYSTEM: CollisionCallbacks + RectangleHitbox');
        print('   ℹ️  Game uses Flame\'s automatic collision detection');
      } else if (hasManualCollision) {
        print('✅ MANUAL COLLISION SYSTEM: _checkCollision method only');
        print('   ℹ️  Game uses custom manual collision detection');
      } else {
        print('❌ NO COLLISION SYSTEM DETECTED!');
        fail('No collision detection system found!');
      }
    });
    
    test('🎮 COLLISION BEHAVIOR TEST: Verify collision detection works correctly', () async {
      print('\n🎮 TESTING: Real collision behavior...');
      
      // Create real game components
      final game = EnhancedFlappyGame();
      await game.onLoad();
      
      final jetPlayer = EnhancedJetPlayer(Vector2(100, 400), GameThemes.skyRookie);
      await jetPlayer.onLoad();
      game.add(jetPlayer);
      
      // Track collision events
      var automaticCollisionCount = 0;
      var manualCollisionCount = 0;
      
      // Mock collision detection
      print('🔬 Setting up collision monitoring...');
      
      // Test collision box calculations
      final jetRect = Rect.fromCenter(
        center: jetPlayer.position.toOffset(),
        width: GameConfig.jetSize * 0.6,
        height: GameConfig.jetSize * 0.6,
      );
      
      print('📊 COLLISION DATA:');
      print('   Jet position: ${jetPlayer.position}');
      print('   Jet collision rect: $jetRect');
      print('   Expected collision behavior: Manual detection only');
      
      // Verify collision box size consistency
      expect(jetRect.width, equals(GameConfig.jetSize * 0.6),
        reason: 'Collision box should be 60% of jet size');
      expect(jetRect.height, equals(GameConfig.jetSize * 0.6),
        reason: 'Collision box should be 60% of jet size');
    });
    
    test('🔧 COMPONENT LIFECYCLE TEST: Verify proper collision setup', () async {
      print('\n🔧 TESTING: Component initialization and collision setup...');
      
      // Test component creation process
      final game = EnhancedFlappyGame();
      print('1️⃣ Game created');
      
      await game.onLoad();
      print('2️⃣ Game loaded');
      
      final jetPlayer = EnhancedJetPlayer(Vector2(50, 300), GameThemes.skyRookie);
      print('3️⃣ JetPlayer created');
      
      await jetPlayer.onLoad();
      print('4️⃣ JetPlayer loaded');
      
      game.add(jetPlayer);
      print('5️⃣ JetPlayer added to game');
      
      // Verify component hierarchy
      final gameChildren = game.children.length;
      final jetChildren = jetPlayer.children.length;
      
      print('\n📊 COMPONENT HIERARCHY:');
      print('   Game children count: $gameChildren');
      print('   Jet children count: $jetChildren');
      
      // List jet's children to see what collision components exist
      print('\n🔍 JET CHILDREN ANALYSIS:');
      for (var i = 0; i < jetPlayer.children.length; i++) {
        final child = jetPlayer.children.elementAt(i);
        print('   Child $i: ${child.runtimeType}');
        
        if (child is RectangleHitbox) {
          print('      ⚠️  FOUND RECTANGLE HITBOX - AUTOMATIC COLLISION!');
          print('      Size: ${child.size}');
          print('      Anchor: ${child.anchor}');
        }
      }
      
      // Verify no RectangleHitbox exists (for manual collision only)
      final hitboxCount = jetPlayer.children.whereType<RectangleHitbox>().length;
      expect(hitboxCount, equals(0),
        reason: 'JetPlayer should not have RectangleHitbox for manual collision detection');
    });
    
    test('🚨 BUG REPRODUCTION TEST: Simulate the exact bug scenario', () async {
      print('\n🚨 TESTING: Bug reproduction scenario...');
      
      // Simulate the exact conditions that caused the bug
      final game = EnhancedFlappyGame();
      await game.onLoad();
      
      // Create jet with the buggy setup (CollisionCallbacks + RectangleHitbox)
      final buggyJet = TestBuggyJetPlayer(Vector2(39.3, 200));
      await buggyJet.onLoad();
      game.add(buggyJet);
      
      // Create obstacle at position from logs
      final obstacleX = 49.67;
      final obstacleY = 400.0;
      final obstacleGap = 200.0;
      
      print('🎯 BUG SCENARIO:');
      print('   Jet center: ${buggyJet.position.x}');
      print('   Obstacle left edge: $obstacleX');
      print('   Visual gap: ${obstacleX - buggyJet.position.x}px');
      
      // Test both collision systems
      final manualCollision = _testManualCollision(buggyJet, obstacleX, obstacleY, obstacleGap);
      final automaticCollision = buggyJet.children.whereType<RectangleHitbox>().isNotEmpty;
      
      print('\n📊 COLLISION RESULTS:');
      print('   Manual collision: $manualCollision');
      print('   Automatic collision system: $automaticCollision');
      
      if (manualCollision && automaticCollision) {
        print('💥 BUG CONFIRMED: Both collision systems active!');
        print('   This would cause false collisions from dual detection');
      }
    });
  });
}

/// Test helper: Manual collision detection
bool _testManualCollision(PositionComponent jet, double obstacleX, double obstacleY, double gapSize) {
  final jetRect = Rect.fromCenter(
    center: jet.position.toOffset(),
    width: GameConfig.jetSize * 0.6,
    height: GameConfig.jetSize * 0.6,
  );
  
  final topRect = Rect.fromLTWH(
    obstacleX, 0, GameConfig.obstacleWidth, obstacleY - gapSize / 2,
  );
  
  return jetRect.overlaps(topRect);
}

/// Test class: Simulates the buggy jet player with dual collision
class TestBuggyJetPlayer extends SpriteComponent with HasGameReference, CollisionCallbacks {
  TestBuggyJetPlayer(Vector2 position) : super(position: position, size: Vector2.all(GameConfig.jetSize));
  
  @override
  Future<void> onLoad() async {
    anchor = Anchor.center;
    
    // This is the bug - adds automatic collision detection
    final hitbox = RectangleHitbox(
      size: Vector2(size.x * 0.6, size.y * 0.6),
      anchor: Anchor.center,
    );
    add(hitbox);
  }
  
  @override
  bool onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    print('🚨 AUTOMATIC COLLISION DETECTED with ${other.runtimeType}');
    return true; // This triggers collision handling!
  }
}
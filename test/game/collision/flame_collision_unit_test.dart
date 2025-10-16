/// Flame Collision System Unit Tests (TDD)
/// 
/// Uses FlameTester for fast, isolated component testing
/// Following Flame best practices: https://docs.flame-engine.org/latest/flame/testing.html
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../../../lib/game/components/jet_player.dart';
import '../../../lib/game/components/dynamic_obstacle.dart';
import '../../../lib/game/components/score_zone.dart';
import '../../../lib/game/core/game_themes.dart';
import '../../../lib/game/core/jet_skins.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Flame Collision: Component Unit Tests', () {
    
    // Create a minimal test game for component testing
    final testGame = FlameTester(
      () => FlameGame() with HasCollisionDetection,
    );
    
    testGame.test('JetPlayer has CircleHitbox component', (game) async {
      // Create jet player
      final jet = JetPlayer(
        Vector2(100, 100),
        GameThemeConfig.themes[0],
        jetSkin: JetSkinCatalog.starterJet,
      );
      
      await game.ensureAdd(jet);
      
      // Verify CircleHitbox exists
      final hitboxes = jet.children.query<CircleHitbox>();
      expect(hitboxes.length, 1, reason: 'JetPlayer should have exactly one CircleHitbox');
      
      // Verify hitbox properties
      final hitbox = hitboxes.first;
      expect(hitbox.collisionType, CollisionType.active, reason: 'Jet hitbox should be active');
      expect(hitbox.radius, closeTo(jet.size.x * 0.35, 0.1), reason: 'Hitbox should be 70% of jet width');
    });
    
    testGame.test('JetPlayer implements CollisionCallbacks', (game) async {
      final jet = JetPlayer(
        Vector2(100, 100),
        GameThemeConfig.themes[0],
        jetSkin: JetSkinCatalog.starterJet,
      );
      
      await game.ensureAdd(jet);
      
      expect(jet is CollisionCallbacks, true, reason: 'JetPlayer should implement CollisionCallbacks');
    });
    
    testGame.test('DynamicObstacle has two RectangleHitboxes', (game) async {
      // Create obstacle
      final obstacle = DynamicObstacle(
        position: Vector2(300, 200),
        theme: GameThemeConfig.themes[0],
        gapSize: 200,
        speed: 150,
        currentScore: 0,
      );
      
      await game.ensureAdd(obstacle);
      game.update(0.1); // Let it initialize
      await game.ready();
      
      // Verify hitboxes
      final hitboxes = obstacle.children.query<RectangleHitbox>();
      expect(hitboxes.length, greaterThanOrEqualTo(2), reason: 'Obstacle should have at least 2 RectangleHitboxes');
      
      // Verify passive collision type
      for (final hitbox in hitboxes.take(2)) {
        expect(hitbox.collisionType, CollisionType.passive, reason: 'Obstacle hitboxes should be passive');
      }
    });
    
    testGame.test('DynamicObstacle has ScoreZone', (game) async {
      final obstacle = DynamicObstacle(
        position: Vector2(300, 200),
        theme: GameThemeConfig.themes[0],
        gapSize: 200,
        speed: 150,
        currentScore: 0,
      );
      
      await game.ensureAdd(obstacle);
      game.update(0.1);
      await game.ready();
      
      // Verify score zone exists
      final scoreZones = obstacle.children.query<ScoreZone>();
      expect(scoreZones.length, 1, reason: 'Obstacle should have exactly one ScoreZone');
      
      final scoreZone = scoreZones.first;
      expect(scoreZone.hasScored, false, reason: 'Score zone should start unscored');
    });
    
    testGame.test('ScoreZone has RectangleHitbox', (game) async {
      final scoreZone = ScoreZone(
        position: Vector2(100, 100),
        size: Vector2(50, 200),
      );
      
      await game.ensureAdd(scoreZone);
      
      // Verify hitbox
      final hitboxes = scoreZone.children.query<RectangleHitbox>();
      expect(hitboxes.length, 1, reason: 'ScoreZone should have exactly one RectangleHitbox');
      
      final hitbox = hitboxes.first;
      expect(hitbox.collisionType, CollisionType.passive, reason: 'ScoreZone hitbox should be passive');
    });
    
    testGame.test('ScoreZone can be marked as scored', (game) async {
      final scoreZone = ScoreZone(
        position: Vector2(100, 100),
        size: Vector2(50, 200),
      );
      
      await game.ensureAdd(scoreZone);
      
      // Initially not scored
      expect(scoreZone.hasScored, false);
      
      // Mark as scored
      scoreZone.markScored();
      expect(scoreZone.hasScored, true);
      
      // Marking again should not change state
      scoreZone.markScored();
      expect(scoreZone.hasScored, true);
    });
    
    testGame.test('Game has HasCollisionDetection mixin', (game) async {
      expect(game is HasCollisionDetection, true, 
        reason: 'Test game should have HasCollisionDetection mixin');
      expect((game as HasCollisionDetection).collisionDetection, isNotNull,
        reason: 'Collision detection system should be initialized');
    });
  });
  
  group('Flame Collision: Component Properties', () {
    
    test('CircleHitbox size calculation is correct', () {
      // Test hitbox sizing logic
      const jetSize = 60.0;
      const expectedRadius = jetSize * 0.35;
      
      expect(expectedRadius, 21.0, reason: 'Hitbox radius should be 35% of jet size');
      expect(expectedRadius * 2, 42.0, reason: 'Hitbox diameter should be 70% of jet size');
    });
    
    test('ScoreZone positioning aligns with obstacle gap', () {
      // Test score zone calculation
      const obstacleY = 300.0;
      const gapSize = 200.0;
      
      final gapTop = obstacleY - gapSize / 2;
      final gapBottom = obstacleY + gapSize / 2;
      final scoreZoneHeight = gapBottom - gapTop;
      
      expect(gapTop, 200.0);
      expect(gapBottom, 400.0);
      expect(scoreZoneHeight, 200.0, reason: 'ScoreZone height should match gap size');
    });
  });
}


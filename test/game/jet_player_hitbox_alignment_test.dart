import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/collisions.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/game/components/jet_player.dart';
import 'package:flappy_jet_pro/game/core/game_themes.dart';

void main() {
  // Initialize Flutter binding for asset loading in tests
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('JetPlayer Hitbox Alignment Tests', () {
    testWithFlameGame(
      'Hitbox should be centered on jet sprite',
      (game) async {
        // Create jet player at a test position
        final testPosition = Vector2(100, 200);
        final jetPlayer = JetPlayer(
          testPosition,
          GameThemes.skyRookie,
        );

        // Add to game and wait for onLoad to complete
        await game.ensureAdd(jetPlayer);

        // Wait an additional frame for all async operations
        game.update(0.01);

        // Find the CircleHitbox child
        final hitbox = jetPlayer.children.query<CircleHitbox>().first;

        // CRITICAL TEST: Child position should be at size/2 for centering
        // When parent has anchor=Anchor.center, child must be at size/2 to center
        final expectedCenter = jetPlayer.size / 2;

        expect(
          hitbox.position.x,
          closeTo(expectedCenter.x, 0.1),
          reason: 'Hitbox X position should be at center of component bounds',
        );
        expect(
          hitbox.position.y,
          closeTo(expectedCenter.y, 0.1),
          reason: 'Hitbox Y position should be at center of component bounds',
        );

        // Verify hitbox has correct anchor
        expect(
          hitbox.anchor,
          equals(Anchor.center),
          reason: 'Hitbox should have Anchor.center',
        );

        // Verify parent has correct anchor
        expect(
          jetPlayer.anchor,
          equals(Anchor.center),
          reason: 'JetPlayer should have Anchor.center',
        );

        // Calculate world positions for verification
        final jetWorldCenter = jetPlayer.absolutePosition;
        final hitboxWorldPosition = hitbox.absolutePosition;

        // Hitbox world position should match jet's world center
        expect(
          hitboxWorldPosition.x,
          closeTo(jetWorldCenter.x, 1.0),
          reason: 'Hitbox world X should match jet center in world coordinates',
        );
        expect(
          hitboxWorldPosition.y,
          closeTo(jetWorldCenter.y, 1.0),
          reason: 'Hitbox world Y should match jet center in world coordinates',
        );
      },
    );

    testWithFlameGame(
      'Debug circle should align with hitbox',
      (game) async {
        final testPosition = Vector2(150, 250);
        final jetPlayer = JetPlayer(
          testPosition,
          GameThemes.skyRookie,
        );

        await game.ensureAdd(jetPlayer);
        game.update(0.01);

        // Find both the hitbox and debug circle
        final hitbox = jetPlayer.children.query<CircleHitbox>().first;
        final debugCircle = jetPlayer.children.query<CircleComponent>().first;

        // Debug circle should be at same local position as hitbox
        expect(
          debugCircle.position.x,
          closeTo(hitbox.position.x, 0.1),
          reason: 'Debug circle X should match hitbox X',
        );
        expect(
          debugCircle.position.y,
          closeTo(hitbox.position.y, 0.1),
          reason: 'Debug circle Y should match hitbox Y',
        );

        // Both should have same radius
        expect(
          debugCircle.radius,
          closeTo(hitbox.radius, 0.1),
          reason: 'Debug circle radius should match hitbox radius',
        );

        // Both should have same anchor
        expect(
          debugCircle.anchor,
          equals(hitbox.anchor),
          reason: 'Debug circle and hitbox should have same anchor',
        );
      },
    );

    testWithFlameGame(
      'Hitbox radius should be 42% of smaller dimension',
      (game) async {
        final testPosition = Vector2(200, 300);
        final jetPlayer = JetPlayer(
          testPosition,
          GameThemes.skyRookie,
        );

        await game.ensureAdd(jetPlayer);
        game.update(0.01);

        final hitbox = jetPlayer.children.query<CircleHitbox>().first;

        // Calculate expected radius
        final smallerDimension =
            jetPlayer.size.x < jetPlayer.size.y ? jetPlayer.size.x : jetPlayer.size.y;
        final expectedRadius = smallerDimension * 0.42;

        expect(
          hitbox.radius,
          closeTo(expectedRadius, 0.1),
          reason: 'Hitbox radius should be 42% of smaller dimension (84% diameter)',
        );
      },
    );

    test('Local coordinates explanation test', () {
      // This test documents the coordinate system understanding
      
      // When a PositionComponent has anchor=Anchor.center:
      // - Its POSITION in world is at its center
      // - But its LOCAL coordinate system still has (0,0) at TOP-LEFT of bounds
      // - To center a child, position must be size/2, not (0,0)
      
      final componentSize = Vector2(100, 100);
      final expectedChildCenterPosition = componentSize / 2; // (50, 50)
      
      expect(expectedChildCenterPosition.x, equals(50.0));
      expect(expectedChildCenterPosition.y, equals(50.0));
      
      // This is why Vector2.zero() was wrong - it placed child at top-left!
      final wrongPosition = Vector2.zero();
      expect(wrongPosition.x, equals(0.0));
      expect(wrongPosition.y, equals(0.0));
    });
  });
}


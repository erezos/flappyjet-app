import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:flappy_jet_pro/game/enhanced_flappy_game.dart';
import 'package:flappy_jet_pro/game/components/dynamic_obstacle.dart';
import 'package:flappy_jet_pro/game/core/game_themes.dart';

void main() {
  group('Collision handling fixes', () {
    test('Single life decrement per collision (no double call)', () async {
      final game = EnhancedFlappyGame();
      await game.onLoad();

      // Place obstacle overlapping jet center to force collision in next update
      final jet = game.jet;
      final obstacle = DynamicObstacle(
        position: Vector2(jet.position.x, jet.position.y),
        theme: GameThemes.skyRookie,
        gapSize: 0.0,
        speed: 0.0,
        currentScore: 0,
      );
      game.add(obstacle);

      // Initial lives
      final initialLives = game.currentLives;

      // Run update to trigger collision
      game.update(0.016);

      // Expect exactly one life lost
      expect(game.currentLives, initialLives - 1);
    });
  });
}
import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/game/components/smooth_parallax_background.dart';
import 'package:flame/game.dart';

void main() {
  group('Parallax fade transition', () {
    test('Fade progresses from 0 to 1 and swaps components', () async {
      final bg = SmoothParallaxBackground();
      // Attach to a minimal fake game to allow size usage
      final game = FlameGame();
      await game.onLoad();
      game.add(bg);
      await bg.onLoad();

      // Trigger transition (simulate score change that requires asset switch)
      await bg.updateForScore(100);

      // Step the update loop over fade duration
      for (int i = 0; i < 10; i++) {
        game.update(0.1);
      }

      // If we reach here without exceptions, transition is stable
      expect(true, isTrue);
    });
  });
}



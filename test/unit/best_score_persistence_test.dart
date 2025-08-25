import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flappy_jet_pro/game/enhanced_flappy_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Best score persistence', () {
    test('Best score updated and exposed after game over', () async {
      // Ensure clean prefs
      SharedPreferences.setMockInitialValues({});

      final game = EnhancedFlappyGame();
      await game.onLoad();

      // Set a score and trigger game over path deterministically
      game.debugSetScoreForTesting(7);
      while (game.currentLives > 0) {
        game.handleCollision();
      }

      // Best score should be saved and at least the last score
      expect(game.bestScore, greaterThanOrEqualTo(7));

      // Recreate game to verify load from storage
      final game2 = EnhancedFlappyGame();
      await game2.onLoad();
      expect(game2.bestScore, equals(game.bestScore));
    });
  });
}



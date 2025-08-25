import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flappy_jet_pro/game/enhanced_flappy_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('remembers last equipped jet across sessions (starter)', () async {
    // Simulate a previous session where the user equipped the starter jet
    SharedPreferences.setMockInitialValues({
      'inv_equipped_skin': 'starter_blue',
    });

    final game = EnhancedFlappyGame();
    // Provide a logical game size before onLoad()
    game.onGameResize(Vector2(400, 800));
    await game.onLoad();

    expect(game.jet.currentSkin.id, equals('starter_blue'));
  });
}



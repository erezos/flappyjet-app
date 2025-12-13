import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flappy_jet_pro/game/flappy_game.dart';
import 'package:flappy_jet_pro/game/systems/lives_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LivesManager().forceResetToNewPlayer();
  });

  test('story mode crash syncs LivesManager with in-game lives', () async {
    final game = FlappyGame(isStoryMode: true);

    // Persist an initial value (simulates last saved hearts)
    await LivesManager().setLives(3);

    game.gameStateManager.setLives(2);
    await game.syncStoryModeLivesWithManager();

    // In-memory value updated
    expect(LivesManager().currentLives, 2);

    // Persistence not touched during in-memory sync
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('lm_lives'), 3);
  });

  test('non-story modes do not alter LivesManager', () async {
    final game = FlappyGame(isStoryMode: false);

    await LivesManager().setLives(3);
    game.gameStateManager.setLives(1);
    await game.syncStoryModeLivesWithManager();

    expect(LivesManager().currentLives, 3);
  });
}


import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flappy_jet_pro/game/systems/lives_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LivesManager().forceResetToNewPlayer();
  });

  test('setLivesInMemory updates notifier without persisting', () async {
    final manager = LivesManager();

    // Persisted value before in-memory change
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('lm_lives'), isNotNull);
    final persistedBefore = prefs.getInt('lm_lives');

    manager.setLivesInMemory(1);

    // Notifier updated
    expect(manager.currentLives, 1);

    // Persistence unchanged
    final persistedAfter = prefs.getInt('lm_lives');
    expect(persistedAfter, persistedBefore);
  });
}


import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flappy_jet_pro/game/systems/inventory_manager.dart';
import 'package:flappy_jet_pro/models/tournament_config.dart';
import 'package:flappy_jet_pro/ui/widgets/tournament/linear_tournament_game_wrapper.dart';

class _MockInventoryManager extends Mock implements InventoryManager {}

void main() {
  setUpAll(() {
    registerFallbackValue(TournamentReward(coins: 0, gems: 0, skinId: 'fallback'));
  });

  test('grantCompletionSkinReward unlocks and equips completion skin', () async {
    final inventory = _MockInventoryManager();
    when(() => inventory.unlockSkin('stunt_master')).thenAnswer((_) async {});
    when(() => inventory.equipSkin('stunt_master')).thenAnswer((_) async => true);

    const reward = TournamentReward(coins: 0, gems: 0, skinId: 'stunt_master');

    await grantCompletionSkinReward(
      inventoryManager: inventory,
      reward: reward,
    );

    verify(() => inventory.unlockSkin('stunt_master')).called(1);
    verify(() => inventory.equipSkin('stunt_master')).called(1);
    verifyNoMoreInteractions(inventory);
  });

  test('grantCompletionSkinReward no-ops when no skin reward', () async {
    final inventory = _MockInventoryManager();

    const reward = TournamentReward(coins: 100, gems: 5);

    await grantCompletionSkinReward(
      inventoryManager: inventory,
      reward: reward,
    );

    verifyZeroInteractions(inventory);
  });
}


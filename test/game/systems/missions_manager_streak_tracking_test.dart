import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flappy_jet_pro/game/systems/missions_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MissionsManager streak tracking', () {
    late MissionsManager manager;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      manager = MissionsManager();
      manager.resetForTesting();
      await manager.initialize();
    });

    test('streak missions progress and reset correctly', () async {
      final streakMission = manager.dailyMissions
          .firstWhere((m) => m.type == MissionType.maintainStreak);

      final description = streakMission.description;
      final thresholdMatch = RegExp(r'above (\d+)').firstMatch(description);
      expect(thresholdMatch, isNotNull);
      final threshold = int.parse(thresholdMatch!.group(1)!);

      // Build up streak to one less than target
      for (int i = 0; i < streakMission.target - 1; i++) {
        await manager.updatePlayerStats(newScore: threshold);
      }

      final inProgressMission = manager.dailyMissions
          .firstWhere((m) => m.type == MissionType.maintainStreak);
      expect(inProgressMission.progress, equals(streakMission.target - 1));
      expect(inProgressMission.completed, isFalse);

      // Break the streak with a low score
      await manager.updatePlayerStats(newScore: threshold - 1);
      final resetMission = manager.dailyMissions
          .firstWhere((m) => m.type == MissionType.maintainStreak);
      expect(resetMission.progress, equals(0));
      expect(resetMission.completed, isFalse);

      // Complete the streak
      for (int i = 0; i < streakMission.target; i++) {
        await manager.updatePlayerStats(newScore: threshold);
      }
      final completedMission = manager.dailyMissions
          .firstWhere((m) => m.type == MissionType.maintainStreak);
      expect(completedMission.completed, isTrue);
    });
  });
}


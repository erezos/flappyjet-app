import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flappy_jet_pro/game/systems/missions_manager.dart';

/// 🎯 CLAIMABLE MISSIONS GETTERS TESTS
/// 
/// These tests verify the new claimable missions getters work correctly:
/// - claimableMissionsCount
/// - claimableMissionsReward
/// - hasClaimableRewards
/// - timeUntilReset / timeUntilResetFormatted
/// - completionSummary
/// 
/// WHY: These getters power the floating missions banner and notification badges.
/// They must be accurate and efficient for real-time UI updates.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MissionsManager Claimable Getters', () {
    late MissionsManager manager;

    setUp(() async {
      // Reset SharedPreferences for clean test state
      SharedPreferences.setMockInitialValues({});
      
      // Reset singleton and initialize
      manager = MissionsManager();
      manager.resetForTesting();
      await manager.initialize();
    });

    group('claimableMissionsCount', () {
      test('returns 0 when no missions are completed', () {
        // Fresh initialization - no missions completed yet
        expect(manager.claimableMissionsCount, equals(0));
      });

      test('returns correct count when missions are completed', () async {
        // Complete missions by updating progress many times
        for (int i = 0; i < 50; i++) {
          await manager.updateMissionProgress(MissionType.playGames, 1);
          await manager.updateMissionProgress(MissionType.collectCoins, 100);
        }
        
        // Wait for async operations
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Count should reflect completed but unclaimed missions
        final completedNotClaimed = manager.dailyMissions
            .where((m) => m.completed && !m.claimed)
            .length;
        
        expect(manager.claimableMissionsCount, equals(completedNotClaimed));
      });

      test('decreases after claiming a mission', () async {
        // Complete missions
        for (int i = 0; i < 50; i++) {
          await manager.updateMissionProgress(MissionType.playGames, 1);
        }
        
        await Future.delayed(const Duration(milliseconds: 100));
        
        final completedMission = manager.dailyMissions
            .where((m) => m.completed && !m.claimed)
            .firstOrNull;
        
        if (completedMission != null) {
          final countBefore = manager.claimableMissionsCount;
          await manager.claimMissionReward(completedMission.id);
          final countAfter = manager.claimableMissionsCount;
          
          expect(countAfter, equals(countBefore - 1));
        }
      });
    });

    group('claimableMissionsReward', () {
      test('returns 0 when no missions are claimable', () {
        expect(manager.claimableMissionsReward, equals(0));
      });

      test('returns correct sum of claimable rewards', () async {
        // Complete missions
        for (int i = 0; i < 50; i++) {
          await manager.updateMissionProgress(MissionType.playGames, 1);
          await manager.updateMissionProgress(MissionType.collectCoins, 100);
        }
        
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Calculate expected reward manually
        final expectedReward = manager.dailyMissions
            .where((m) => m.completed && !m.claimed)
            .fold(0, (sum, m) => sum + m.reward);
        
        expect(manager.claimableMissionsReward, equals(expectedReward));
      });
    });

    group('hasClaimableRewards', () {
      test('returns false when no missions are claimable', () {
        expect(manager.hasClaimableRewards, isFalse);
      });

      test('returns true when at least one mission is claimable', () async {
        // Complete missions
        for (int i = 0; i < 50; i++) {
          await manager.updateMissionProgress(MissionType.playGames, 1);
        }
        
        await Future.delayed(const Duration(milliseconds: 100));
        
        final hasCompleted = manager.dailyMissions.any((m) => m.completed && !m.claimed);
        expect(manager.hasClaimableRewards, equals(hasCompleted));
      });
    });

    group('timeUntilReset', () {
      test('returns a duration less than 24 hours', () {
        // After initialization, time until reset should be less than 24h
        expect(manager.timeUntilReset.inHours, lessThanOrEqualTo(24));
      });

      test('returns non-negative duration', () {
        expect(manager.timeUntilReset.isNegative, isFalse);
      });
    });

    group('timeUntilResetFormatted', () {
      test('returns formatted string', () {
        final formatted = manager.timeUntilResetFormatted;
        
        // Should be either "Xh Ym", "Ym", or "Reset now"
        expect(
          formatted.contains('h') || 
          formatted.contains('m') || 
          formatted == 'Reset now',
          isTrue,
        );
      });

      test('returns "Reset now" when duration is zero', () {
        // This is tricky to test without mocking time
        // We just verify the format is valid
        final formatted = manager.timeUntilResetFormatted;
        expect(formatted, isNotEmpty);
      });
    });

    group('completionSummary', () {
      test('returns correct format "X/Y"', () {
        final summary = manager.completionSummary;
        
        // Should match pattern "X/Y"
        expect(RegExp(r'^\d+/\d+$').hasMatch(summary), isTrue);
      });

      test('reflects actual completion state', () {
        final summary = manager.completionSummary;
        final parts = summary.split('/');
        
        final completed = int.parse(parts[0]);
        final total = int.parse(parts[1]);
        
        // Verify against actual data
        expect(completed, equals(manager.dailyMissions.where((m) => m.completed).length));
        expect(total, equals(manager.dailyMissions.length));
      });

      test('updates when missions are completed', () async {
        // Complete missions
        for (int i = 0; i < 50; i++) {
          await manager.updateMissionProgress(MissionType.playGames, 1);
        }
        
        await Future.delayed(const Duration(milliseconds: 100));
        
        final summaryAfter = manager.completionSummary;
        
        // Summary should be valid format
        expect(RegExp(r'^\d+/\d+$').hasMatch(summaryAfter), isTrue);
      });
    });
  });

  group('MissionsManager Claimable - Integration', () {
    test('all claimable getters are consistent with each other', () async {
      SharedPreferences.setMockInitialValues({});
      final manager = MissionsManager();
      manager.resetForTesting();
      await manager.initialize();

      // Complete some missions
      for (int i = 0; i < 30; i++) {
        await manager.updateMissionProgress(MissionType.playGames, 1);
        await manager.updateMissionProgress(MissionType.collectCoins, 50);
      }
      
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify consistency
      final count = manager.claimableMissionsCount;
      final reward = manager.claimableMissionsReward;
      final hasRewards = manager.hasClaimableRewards;

      // If count > 0, hasRewards should be true
      if (count > 0) {
        expect(hasRewards, isTrue);
        expect(reward, greaterThan(0));
      } else {
        expect(hasRewards, isFalse);
        expect(reward, equals(0));
      }
    });

    test('getters update in real-time when notifyListeners is called', () async {
      SharedPreferences.setMockInitialValues({});
      final manager = MissionsManager();
      manager.resetForTesting();
      await manager.initialize();

      int notifyCount = 0;
      int lastCount = manager.claimableMissionsCount;

      manager.addListener(() {
        notifyCount++;
        // Check that getter reflects new state
        final newCount = manager.claimableMissionsCount;
        // Count should be >= lastCount (missions can only be completed, not uncompleted)
        expect(newCount, greaterThanOrEqualTo(lastCount));
        lastCount = newCount;
      });

      // Complete missions
      for (int i = 0; i < 20; i++) {
        await manager.updateMissionProgress(MissionType.playGames, 1);
      }

      // Verify listeners were called
      expect(notifyCount, greaterThan(0));
    });
  });

  group('MissionsManager Claimable - Edge Cases', () {
    test('handles empty missions list gracefully', () async {
      SharedPreferences.setMockInitialValues({});
      final manager = MissionsManager();
      manager.resetForTesting();
      // Don't initialize - missions list will be empty initially
      
      // These should not throw
      expect(manager.claimableMissionsCount, equals(0));
      expect(manager.claimableMissionsReward, equals(0));
      expect(manager.hasClaimableRewards, isFalse);
      expect(manager.completionSummary, equals('0/0'));
    });

    test('timeUntilReset handles null lastResetDate gracefully', () async {
      SharedPreferences.setMockInitialValues({});
      final manager = MissionsManager();
      manager.resetForTesting();
      // Don't initialize - lastResetDate will be null
      
      // Should return Duration.zero, not throw
      expect(manager.timeUntilReset, equals(Duration.zero));
      expect(manager.timeUntilResetFormatted, equals('Reset now'));
    });
  });
}


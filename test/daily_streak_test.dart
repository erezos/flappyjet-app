import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flappy_jet_pro/game/systems/daily_streak_manager.dart';
import 'package:flappy_jet_pro/game/systems/inventory_manager.dart';
import 'package:flappy_jet_pro/game/systems/lives_manager.dart';

void main() {
  // Initialize Flutter binding for tests
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Daily Streak Manager - 8 Day Consecutive Login Tests', () {
    late DailyStreakManager streakManager;
    
    setUp(() async {
      // Initialize SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      
      // Reset the singleton instance for clean testing
      streakManager = DailyStreakManager();
      await streakManager.resetAllData();
      await streakManager.initialize();
    });
    
    tearDown(() async {
      await streakManager.resetAllData();
    });

    test('Day 1-7 rewards are correct and cycle completes properly', () async {
      // Expected rewards for new player (7-day cycle)
      final expectedRewards = [
        '100 Coins',           // Day 1 (index 0)
        'Flash Strike Jet',    // Day 2 (index 1) 
        '1 Hour Heart Booster', // Day 3 (index 2)
        '250 Coins',           // Day 4 (index 3)
        '1 Heart',             // Day 5 (index 4)
        'Mystery Box',         // Day 6 (index 5)
        '15 Gems',             // Day 7 (index 6)
      ];
      
      // Simulate 7 consecutive days
      for (int day = 1; day <= 7; day++) {
        // Simulate new day
        await _simulateNewDay(streakManager);
        
        // Verify streak state
        expect(streakManager.currentState, DailyStreakState.available, 
               reason: 'Day $day should be available for claiming');
        
        // Verify current streak
        expect(streakManager.currentStreak, day - 1, 
               reason: 'Before claiming Day $day, streak should be ${day - 1}');
        
        // Verify reward index calculation
        final expectedIndex = (day - 1) % 7;
        expect(streakManager.todayRewardIndex, expectedIndex,
               reason: 'Day $day should have reward index $expectedIndex');
        
        // Verify correct reward
        final todayReward = streakManager.todayReward;
        expect(todayReward.description, expectedRewards[expectedIndex],
               reason: 'Day $day should give reward: ${expectedRewards[expectedIndex]}');
        
        // Claim the reward
        final success = await streakManager.claimTodayReward();
        expect(success, true, reason: 'Day $day claim should succeed');
        
        // Verify streak after claiming
        expect(streakManager.currentStreak, day,
               reason: 'After claiming Day $day, streak should be $day');
        
        // Verify claimed state
        expect(streakManager.currentState, DailyStreakState.claimed,
               reason: 'Day $day should be claimed after claiming');
        
        // Check cycle completion on Day 7
        if (day == 7) {
          expect(streakManager.currentCycle, 1,
                 reason: 'After Day 7, should be in cycle 1');
          expect(streakManager.totalStreaksCompleted, 1,
                 reason: 'Should have 1 completed streak after Day 7');
          expect(streakManager.currentStreak, 0,
                 reason: 'Streak should reset to 0 after cycle completion');
        }
      }
    });

    test('Day 8 starts new cycle with correct Day 1 reward', () async {
      // Complete first 7-day cycle
      for (int day = 1; day <= 7; day++) {
        await _simulateNewDay(streakManager);
        await streakManager.claimTodayReward();
      }
      
      // Verify cycle completion
      expect(streakManager.currentStreak, 0, reason: 'Streak should be 0 after cycle completion');
      expect(streakManager.currentCycle, 1, reason: 'Should be in cycle 1');
      expect(streakManager.totalStreaksCompleted, 1, reason: 'Should have 1 completed cycle');
      
      // Simulate Day 8 (new cycle)
      await _simulateNewDay(streakManager);
      
      // Verify Day 8 state
      expect(streakManager.currentState, DailyStreakState.available,
             reason: 'Day 8 should be available for claiming');
      
      expect(streakManager.currentStreak, 0,
             reason: 'Before claiming Day 8, streak should be 0');
      
      // Verify Day 8 reward is Day 1 reward (100 coins)
      expect(streakManager.todayRewardIndex, 0,
             reason: 'Day 8 should have reward index 0 (Day 1 of new cycle)');
      
      final day8Reward = streakManager.todayReward;
      expect(day8Reward.description, '100 Coins',
             reason: 'Day 8 should give Day 1 reward: 100 Coins');
      
      // Claim Day 8 reward
      final success = await streakManager.claimTodayReward();
      expect(success, true, reason: 'Day 8 claim should succeed');
      
      // Verify state after claiming Day 8
      expect(streakManager.currentStreak, 1,
             reason: 'After claiming Day 8, streak should be 1');
      
      expect(streakManager.currentCycle, 1,
             reason: 'Should still be in cycle 1');
      
      expect(streakManager.currentState, DailyStreakState.claimed,
             reason: 'Day 8 should be claimed after claiming');
    });

    test('Reward index calculation is correct for all days', () async {
      final testCases = [
        // [currentStreak, expectedIndex, expectedDay]
        [0, 0, 'Before first claim'],
        [1, 0, 'Day 1'],
        [2, 1, 'Day 2'], 
        [3, 2, 'Day 3'],
        [4, 3, 'Day 4'],
        [5, 4, 'Day 5'],
        [6, 5, 'Day 6'],
        [7, 6, 'Day 7'],
        [8, 0, 'Day 8 (new cycle Day 1)'], // This should be 0 after cycle reset
      ];
      
      for (final testCase in testCases) {
        final streak = testCase[0] as int;
        final expectedIndex = testCase[1] as int;
        final description = testCase[2] as String;
        
        // Manually set streak for testing
        await streakManager.resetAllData();
        
        // Simulate the streak without going through full claim process
        if (streak > 0) {
          for (int i = 1; i <= streak; i++) {
            await _simulateNewDay(streakManager);
            if (i <= 7) {
              await streakManager.claimTodayReward();
            } else {
              // For Day 8+, the streak should be reset by cycle completion
              // So we need to simulate this properly
              break;
            }
          }
        }
        
        final actualIndex = streakManager.todayRewardIndex;
        expect(actualIndex, expectedIndex,
               reason: '$description: streak=$streak should give index $expectedIndex, got $actualIndex');
      }
    });

    test('Cycle completion happens exactly on Day 7', () async {
      // Track cycle completion
      int initialCycle = streakManager.currentCycle;
      int initialCompleted = streakManager.totalStreaksCompleted;
      
      // Days 1-6 should not trigger cycle completion
      for (int day = 1; day <= 6; day++) {
        await _simulateNewDay(streakManager);
        await streakManager.claimTodayReward();
        
        expect(streakManager.currentCycle, initialCycle,
               reason: 'Day $day should not complete cycle');
        expect(streakManager.totalStreaksCompleted, initialCompleted,
               reason: 'Day $day should not increment completed cycles');
        expect(streakManager.currentStreak, day,
               reason: 'Day $day streak should be $day');
      }
      
      // Day 7 should trigger cycle completion
      await _simulateNewDay(streakManager);
      await streakManager.claimTodayReward();
      
      expect(streakManager.currentCycle, initialCycle + 1,
             reason: 'Day 7 should complete cycle and increment currentCycle');
      expect(streakManager.totalStreaksCompleted, initialCompleted + 1,
             reason: 'Day 7 should increment totalStreaksCompleted');
      expect(streakManager.currentStreak, 0,
             reason: 'Day 7 should reset streak to 0 for new cycle');
    });

    test('Multiple cycles work correctly', () async {
      // Complete 2 full cycles (14 days)
      for (int cycle = 0; cycle < 2; cycle++) {
        for (int day = 1; day <= 7; day++) {
          await _simulateNewDay(streakManager);
          
          final globalDay = (cycle * 7) + day;
          final expectedRewardIndex = (day - 1) % 7;
          
          expect(streakManager.todayRewardIndex, expectedRewardIndex,
                 reason: 'Global Day $globalDay (Cycle $cycle Day $day) should have index $expectedRewardIndex');
          
          await streakManager.claimTodayReward();
          
          if (day == 7) {
            // Cycle completion
            expect(streakManager.currentCycle, cycle + 1,
                   reason: 'After cycle $cycle completion, should be in cycle ${cycle + 1}');
            expect(streakManager.currentStreak, 0,
                   reason: 'Streak should reset after cycle completion');
          } else {
            expect(streakManager.currentStreak, day,
                   reason: 'Streak should be $day on day $day of cycle');
          }
        }
      }
      
      expect(streakManager.totalStreaksCompleted, 2,
             reason: 'Should have 2 completed cycles');
      expect(streakManager.currentCycle, 2,
             reason: 'Should be in cycle 2');
    });
  });
}

/// Helper function to simulate a new day
Future<void> _simulateNewDay(DailyStreakManager manager) async {
  // Simulate the passage of time to the next day
  // In real app, this happens when user opens app on a new calendar day
  
  // Force reset the claimed status to simulate new day
  await manager.resetDailyClaimStatus();
  
  // Re-initialize to check daily reset logic
  await manager.initialize();
}

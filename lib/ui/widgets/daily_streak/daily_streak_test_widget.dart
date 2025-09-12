import 'package:flutter/material.dart';
import 'daily_streak_integration.dart';

/// Test widget for daily streak system - for development/testing only
class DailyStreakTestWidget extends StatelessWidget {
  const DailyStreakTestWidget({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🎯 Daily Streak System Test',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Current status
            ListenableBuilder(
              listenable: DailyStreakIntegration.streakManager,
              builder: (context, child) {
                final manager = DailyStreakIntegration.streakManager;
                final stats = DailyStreakIntegration.streakStats;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current Streak: ${manager.currentStreak} days'),
                    Text('State: ${manager.currentState.name}'),
                    Text('Claimed Today: ${manager.claimedToday}'),
                    Text('Should Show Popup: ${DailyStreakIntegration.shouldShowPopup()}'),
                    Text('Has Notification: ${DailyStreakIntegration.hasNotification}'),
                    const SizedBox(height: 8),
                    Text('Today\'s Reward: ${manager.todayReward.description}'),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // Test buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () {
                    DailyStreakIntegration.showDailyStreakPopup(context);
                  },
                  child: const Text('Show Popup'),
                ),
                ElevatedButton(
                  onPressed: () {
                    DailyStreakIntegration.streakManager.resetAllData();
                  },
                  child: const Text('Reset Data'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final success = await DailyStreakIntegration.streakManager.claimTodayReward();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? 'Reward claimed!' : 'Failed to claim'),
                          backgroundColor: success ? Colors.green : Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Claim Reward'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

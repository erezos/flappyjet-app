import 'package:flutter/material.dart';
import 'daily_streak_integration.dart';

/// Example integration for showing daily streak in homepage
/// Add this to your homepage to show the daily streak notification
class DailyStreakHomepageIntegration extends StatefulWidget {
  const DailyStreakHomepageIntegration({super.key});
  
  @override
  State<DailyStreakHomepageIntegration> createState() => _DailyStreakHomepageIntegrationState();
}

class _DailyStreakHomepageIntegrationState extends State<DailyStreakHomepageIntegration> {
  
  @override
  void initState() {
    super.initState();
    _initializeDailyStreak();
  }
  
  Future<void> _initializeDailyStreak() async {
    await DailyStreakIntegration.initialize();
    
    // Show popup after a short delay if needed
    if (mounted && DailyStreakIntegration.shouldShowPopup()) {
      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted) {
        await DailyStreakIntegration.showDailyStreakPopup(context);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: DailyStreakIntegration.streakManager,
      builder: (context, child) {
        final hasNotification = DailyStreakIntegration.hasNotification;
        final currentStreak = DailyStreakIntegration.streakManager.currentStreak;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Streak icon with notification badge
              Stack(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: hasNotification 
                            ? [Colors.amber, Colors.orange]
                            : [Colors.grey.shade400, Colors.grey.shade600],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: hasNotification ? [
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ] : null,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: hasNotification ? () {
                          DailyStreakIntegration.showDailyStreakPopup(context);
                        } : null,
                        child: const Icon(
                          Icons.calendar_today,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  
                  // Notification badge
                  if (hasNotification)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.star,
                          color: Colors.white,
                          size: 8,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(width: 12),
              
              // Streak info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasNotification ? 'Daily Bonus Ready!' : 'Daily Streak',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: hasNotification ? Colors.amber : Colors.white,
                      ),
                    ),
                    Text(
                      currentStreak > 0 
                          ? '$currentStreak day${currentStreak == 1 ? '' : 's'} streak'
                          : 'Start your streak today!',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Arrow indicator
              if (hasNotification)
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.amber,
                  size: 16,
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Simple floating action button for daily streak
class DailyStreakFAB extends StatelessWidget {
  const DailyStreakFAB({super.key});
  
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: DailyStreakIntegration.streakManager,
      builder: (context, child) {
        final hasNotification = DailyStreakIntegration.hasNotification;
        
        if (!hasNotification) {
          return const SizedBox.shrink();
        }
        
        return FloatingActionButton(
          onPressed: () {
            DailyStreakIntegration.showDailyStreakPopup(context);
          },
          backgroundColor: Colors.amber,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.calendar_today,
                color: Colors.white,
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Integration instructions widget (for development/testing)
class DailyStreakInstructions extends StatelessWidget {
  const DailyStreakInstructions({super.key});
  
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
              'Daily Streak Integration',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'To integrate the daily streak system:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Add DailyStreakHomepageIntegration to your homepage\n'
              '2. Or use DailyStreakFAB as a floating action button\n'
              '3. Initialize in main.dart with DailyStreakIntegration.initialize()\n'
              '4. The system will automatically show popups when appropriate',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    DailyStreakIntegration.showDailyStreakPopup(context);
                  },
                  child: const Text('Test Popup'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    DailyStreakIntegration.streakManager.resetAllData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Daily streak data reset'),
                      ),
                    );
                  },
                  child: const Text('Reset Data'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

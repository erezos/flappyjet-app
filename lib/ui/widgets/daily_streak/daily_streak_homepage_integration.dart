import 'package:flutter/material.dart';
import 'daily_streak_integration.dart';

/// Auto-popup integration for daily streak - checks once per session at app open
/// Add this to your main screen to auto-show the daily streak popup when reward is available
/// 
/// Features:
/// - Checks only once per session (at app open)
/// - Shows popup automatically if reward is available
/// - No UI rendering (invisible widget)
class DailyStreakHomepageIntegration extends StatefulWidget {
  const DailyStreakHomepageIntegration({super.key});
  
  @override
  State<DailyStreakHomepageIntegration> createState() => _DailyStreakHomepageIntegrationState();
}

class _DailyStreakHomepageIntegrationState extends State<DailyStreakHomepageIntegration> {
  static bool _hasCheckedThisSession = false; // ✅ Session-level flag
  
  @override
  void initState() {
    super.initState();
    _checkAndShowPopup();
  }
  
  /// Check and show popup once per session
  Future<void> _checkAndShowPopup() async {
    // ✅ Only check once per session
    if (_hasCheckedThisSession) {
      return;
    }
    
    _hasCheckedThisSession = true;
    
    await DailyStreakIntegration.initialize();
    
    // Show popup after a short delay if reward is available
    if (mounted && DailyStreakIntegration.shouldShowPopup()) {
      await Future.delayed(const Duration(milliseconds: 1500)); // Slightly longer delay for better UX
      if (mounted) {
        await DailyStreakIntegration.showDailyStreakPopup(context);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // ✅ Invisible widget - only handles auto-popup logic
    // No UI rendering needed
    return const SizedBox.shrink();
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
              '1. Add DailyStreakHomepageIntegration to your main screen\n'
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

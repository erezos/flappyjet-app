import 'package:flutter/material.dart';
import '../../../game/systems/daily_streak_manager.dart';
import '../../../game/systems/firebase_analytics_manager.dart';
import '../rate_us_integration.dart';
import 'daily_streak_popup_stable.dart';

/// Integration helper for showing daily streak popups
class DailyStreakIntegration {
  static final DailyStreakManager _streakManager = DailyStreakManager();
  
  /// Initialize the daily streak system
  static Future<void> initialize() async {
    await _streakManager.initialize();
  }
  
  /// Check if daily streak popup should be shown
  static bool shouldShowPopup() {
    return _streakManager.shouldShowPopup;
  }
  
  /// Show daily streak popup
  static Future<void> showDailyStreakPopup(BuildContext context, {
    VoidCallback? onComplete,
  }) async {
    if (!shouldShowPopup()) {
      onComplete?.call();
      return;
    }
    
    // Track popup view
    FirebaseAnalyticsManager().trackEvent('daily_streak_popup_shown', {
      'streak_day': _streakManager.currentStreak,
      'state': _streakManager.currentState.name,
      'reward_type': _streakManager.todayReward.type.name,
    });
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => DailyStreakPopupStable(
        streakManager: _streakManager,
        onClaim: () async {
          await _handleClaimReward(dialogContext);
          // Close the dialog after handling claim
          if (dialogContext.mounted && Navigator.canPop(dialogContext)) {
            Navigator.of(dialogContext).pop();
          }
        },
        onClose: () {
          // Close the dialog
          if (dialogContext.mounted && Navigator.canPop(dialogContext)) {
            Navigator.of(dialogContext).pop();
          }
          _trackDismissal();
        },
        onRestore: () async {
          await _handleRestoreStreak(dialogContext);
          // Close the dialog after handling restore
          if (dialogContext.mounted && Navigator.canPop(dialogContext)) {
            Navigator.of(dialogContext).pop();
          }
        },
      ),
    );
    
    onComplete?.call();
  }
  
  /// Handle claiming today's reward
  static Future<void> _handleClaimReward(BuildContext context) async {
    final reward = _streakManager.todayReward;
    
    // Track claim attempt
    FirebaseAnalyticsManager().trackEvent('daily_streak_claim_attempt', {
      'streak_day': _streakManager.currentStreak,
      'reward_type': reward.type.name,
      'reward_amount': reward.amount,
    });
    
    final success = await _streakManager.claimTodayReward();
    
    if (success) {
      // Track successful claim
      FirebaseAnalyticsManager().trackEvent('daily_streak_claim_success', {
        'streak_day': _streakManager.currentStreak,
        'reward_type': reward.type.name,
        'reward_amount': reward.amount,
        'new_streak': _streakManager.currentStreak,
      });
      
      // Show success feedback
      if (context.mounted) {
        _showRewardFeedback(context, reward);
        
        // Wait a moment for user to see the feedback
        await Future.delayed(const Duration(milliseconds: 1000));
        
        // Check for rate us after successful daily streak claim
        if (context.mounted) {
          await RateUsIntegration.showAfterDailyStreak(
            context,
            streakDay: _streakManager.currentStreak,
          );
        }
      }
    } else {
      // Track failed claim
      FirebaseAnalyticsManager().trackEvent('daily_streak_claim_failed', {
        'streak_day': _streakManager.currentStreak,
        'reward_type': reward.type.name,
        'reason': 'claim_failed',
      });
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to claim reward. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Handle restoring broken streak
  static Future<void> _handleRestoreStreak(BuildContext context) async {
    FirebaseAnalyticsManager().trackEvent('daily_streak_restore_attempt', {
      'streak_day': _streakManager.currentStreak,
      'gems_cost': 10,
    });
    
    final success = await _streakManager.restoreStreakWithGems();
    
    if (success) {
      FirebaseAnalyticsManager().trackEvent('daily_streak_restore_success', {
        'streak_day': _streakManager.currentStreak,
        'gems_spent': 10,
      });
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Streak restored! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      FirebaseAnalyticsManager().trackEvent('daily_streak_restore_failed', {
        'streak_day': _streakManager.currentStreak,
        'reason': 'insufficient_gems',
      });
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not enough gems to restore streak'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Show reward feedback to user
  static void _showRewardFeedback(BuildContext context, DailyStreakReward reward) {
    String message;
    Color backgroundColor;
    
    switch (reward.type) {
      case DailyStreakRewardType.coins:
        message = 'Earned ${reward.amount} coins! 💰';
        backgroundColor = Colors.amber;
        break;
      case DailyStreakRewardType.gems:
        message = 'Earned ${reward.amount} gems! 💎';
        backgroundColor = Colors.cyan;
        break;
      case DailyStreakRewardType.heart:
        message = 'Earned ${reward.amount} heart! ❤️';
        backgroundColor = Colors.red;
        break;
      case DailyStreakRewardType.heartBooster:
        message = 'Heart Booster activated! ⚡';
        backgroundColor = Colors.orange;
        break;
      case DailyStreakRewardType.jetSkin:
        message = 'New jet unlocked: ${reward.displayText}! 🚁';
        backgroundColor = Colors.blue;
        break;
      case DailyStreakRewardType.mysteryBox:
        message = 'Mystery box opened! 🎁';
        backgroundColor = Colors.purple;
        break;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  /// Track popup dismissal
  static void _trackDismissal() {
    FirebaseAnalyticsManager().trackEvent('daily_streak_popup_dismissed', {
      'streak_day': _streakManager.currentStreak,
      'state': _streakManager.currentState.name,
    });
  }
  
  /// Get streak manager instance
  static DailyStreakManager get streakManager => _streakManager;
  
  /// Check if user has notification badge (for UI indicators)
  static bool get hasNotification => shouldShowPopup();
  
  /// Get streak stats for display
  static Map<String, dynamic> get streakStats => _streakManager.getStreakStats();
}

/// Widget to show daily streak notification badge
class DailyStreakNotificationBadge extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  
  const DailyStreakNotificationBadge({
    super.key,
    required this.child,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: onTap,
          child: child,
        ),
        
        if (DailyStreakIntegration.hasNotification)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
            ),
          ),
      ],
    );
  }
}

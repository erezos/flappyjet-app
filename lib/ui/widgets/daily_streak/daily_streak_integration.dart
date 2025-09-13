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
          // The popup already handled the claim - just close and track
          _trackClaimSuccess();
          
          // Close the dialog
          if (dialogContext.mounted && Navigator.canPop(dialogContext)) {
            Navigator.of(dialogContext).pop();
          }
          
          // Check for rate us after successful daily streak claim
          if (dialogContext.mounted) {
            await RateUsIntegration.showAfterDailyStreak(
              dialogContext,
              streakDay: _streakManager.currentStreak,
            );
          }
        },
        onClose: () {
          // Close the dialog
          if (dialogContext.mounted && Navigator.canPop(dialogContext)) {
            Navigator.of(dialogContext).pop();
          }
          _trackDismissal();
        },
      ),
    );
    
    onComplete?.call();
  }
  
  /// Track successful claim (called after popup handles the claim)
  static void _trackClaimSuccess() {
    final reward = _streakManager.todayReward;
    
    // Track successful claim
    FirebaseAnalyticsManager().trackEvent('daily_streak_claim_success', {
      'streak_day': _streakManager.currentStreak,
      'reward_type': reward.type.name,
      'reward_amount': reward.amount,
      'new_streak': _streakManager.currentStreak,
    });
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

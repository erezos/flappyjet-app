/// ⭐ Rate Us Integration Helper
/// 
/// Manages when and how to show the rate us popup.
/// Best practices for casual mobile games:
/// - Check eligibility ONCE before showing popup
/// - Never re-check when user taps "Rate"
/// - Show after positive experiences only
/// - Respect user's choice to decline
library;

import 'package:flutter/material.dart';
import '../../game/systems/rate_us_manager.dart';
import '../../core/debug_logger.dart';
import 'rate_us_popup.dart';

class RateUsIntegration {
  static final RateUsManager _rateUsManager = RateUsManager();

  /// Check if we should show rate us popup after positive game experience
  static bool get shouldShowAfterPositiveExperience {
    return _rateUsManager.shouldPromptAfterPositiveExperience();
  }

  /// Check if we should show rate us popup (general check)
  static bool get shouldShow {
    return _rateUsManager.shouldShowRateUsPrompt;
  }

  /// Show rate us popup after a positive game experience
  /// 
  /// Call this after:
  /// - User claims an achievement
  /// - User completes a difficult level
  /// - User reaches a new high score
  /// 
  /// ⚠️ IMPORTANT: Pass the PARENT context, not dialog context!
  static Future<void> showAfterPositiveExperience(BuildContext context) async {
    if (!shouldShowAfterPositiveExperience) {
      safePrint('⭐ Rate us: Not eligible for positive experience trigger');
      return;
    }

    await _showRateUsPopup(context, triggerType: 'positive_experience');
  }

  /// Show rate us popup after user claims daily streak
  /// 
  /// ⚠️ IMPORTANT: Pass the PARENT context, not dialog context!
  /// The daily streak dialog should pass down the parent context.
  static Future<void> showAfterDailyStreak(
    BuildContext context, {
    required int streakDay,
  }) async {
    if (!_rateUsManager.shouldPromptAfterDailyStreak(streakDay)) {
      safePrint('⭐ Rate us: Not eligible for daily streak trigger (day $streakDay)');
      return;
    }

    await _showRateUsPopup(context, triggerType: 'daily_streak', streakDay: streakDay);
  }

  /// Internal method to show the popup
  static Future<void> _showRateUsPopup(
    BuildContext context, {
    required String triggerType,
    int? streakDay,
  }) async {
    // Verify context is still valid
    if (!context.mounted) {
      safePrint('⭐ Rate us: Context not mounted, skipping');
      return;
    }

    safePrint('⭐ Rate us: Showing popup (trigger: $triggerType)');

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => RateUsPopup(
        onRated: () {
          safePrint('⭐ Rate us: User tapped rate');
        },
        onDismissed: () {
          safePrint('⭐ Rate us: User dismissed');
        },
      ),
    );
  }

  /// Open store listing directly (for settings menu)
  static Future<void> openStoreListing() async {
    await _rateUsManager.openStoreListing();
  }

  /// Check if user has already rated
  static bool get hasUserRated => _rateUsManager.hasRated;

  /// Check if user has declined
  static bool get hasUserDeclined => _rateUsManager.hasDeclined;

  /// Get current session count
  static int get sessionCount => _rateUsManager.sessionCount;

  /// Get days since first launch
  static int get daysSinceFirstLaunch => _rateUsManager.daysSinceFirstLaunch;

  /// Get debug state for troubleshooting
  static Map<String, dynamic> get debugState => _rateUsManager.getDebugState();
}

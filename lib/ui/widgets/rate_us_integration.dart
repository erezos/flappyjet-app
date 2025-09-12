/// ⭐ Rate Us Integration Helper
/// Manages when and how to show the rate us popup
library;

import 'package:flutter/material.dart';
import '../../game/systems/rate_us_manager.dart';
import '../../game/systems/firebase_analytics_manager.dart';
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
  /// Call this after user achieves high score, completes achievements, etc.
  static Future<void> showAfterPositiveExperience(BuildContext context) async {
    if (!shouldShowAfterPositiveExperience) return;

    FirebaseAnalyticsManager().trackEvent('rate_us_trigger_positive_experience', {
      'session_count': _rateUsManager.sessionCount,
    });

    await _showRateUsPopup(context);
  }

  /// Show rate us popup on app launch (if conditions are met)
  /// Call this from homepage or main screen
  static Future<void> showOnAppLaunch(BuildContext context) async {
    if (!shouldShow) return;

    // Add a small delay to let the app settle
    await Future.delayed(const Duration(seconds: 2));
    
    if (!context.mounted) return;

    FirebaseAnalyticsManager().trackEvent('rate_us_trigger_app_launch', {
      'session_count': _rateUsManager.sessionCount,
    });

    await _showRateUsPopup(context);
  }

  /// Show rate us popup after completing a level/game
  /// Call this from game over screen
  static Future<void> showAfterGameCompletion(BuildContext context, {
    required int score,
    required bool isHighScore,
  }) async {
    if (!shouldShowAfterPositiveExperience) return;

    // Only show after high scores or good performance
    if (!isHighScore && score < 10) return;

    FirebaseAnalyticsManager().trackEvent('rate_us_trigger_game_completion', {
      'session_count': _rateUsManager.sessionCount,
      'score': score,
      'is_high_score': isHighScore,
    });

    await _showRateUsPopup(context);
  }

  /// Show rate us popup after user claims daily streak
  /// Call this after successful daily streak claim
  static Future<void> showAfterDailyStreak(BuildContext context, {
    required int streakDay,
  }) async {
    if (!shouldShowAfterPositiveExperience) return;

    // Only show after longer streaks (user is engaged)
    if (streakDay < 3) return;

    FirebaseAnalyticsManager().trackEvent('rate_us_trigger_daily_streak', {
      'session_count': _rateUsManager.sessionCount,
      'streak_day': streakDay,
    });

    await _showRateUsPopup(context);
  }

  /// Show rate us popup manually (for settings or menu)
  static Future<void> showManually(BuildContext context) async {
    FirebaseAnalyticsManager().trackEvent('rate_us_trigger_manual', {
      'session_count': _rateUsManager.sessionCount,
    });

    await _showRateUsPopup(context);
  }

  /// Internal method to show the popup
  static Future<void> _showRateUsPopup(BuildContext context) async {
    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RateUsPopup(
        onRated: () {
          FirebaseAnalyticsManager().trackEvent('rate_us_completed_from_popup', {
            'session_count': _rateUsManager.sessionCount,
          });
        },
        onDismissed: () {
          FirebaseAnalyticsManager().trackEvent('rate_us_dismissed', {
            'session_count': _rateUsManager.sessionCount,
          });
        },
      ),
    );
  }

  /// Open store listing directly (for manual rating)
  static Future<void> openStoreListing() async {
    await _rateUsManager.openStoreListing();
  }

  /// Check if user has already rated
  static bool get hasUserRated {
    return _rateUsManager.hasRated;
  }

  /// Get current session count
  static int get sessionCount {
    return _rateUsManager.sessionCount;
  }

  /// Get days since first launch
  static int get daysSinceFirstLaunch {
    return _rateUsManager.daysSinceFirstLaunch;
  }
}

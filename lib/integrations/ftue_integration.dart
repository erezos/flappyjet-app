/// 🎮 Tutorial Integration - Level 1 Tutorial
/// Shows interactive Flame-based tutorial before Level 1
library;

import 'package:flutter/material.dart';
import '../ui/widgets/ftue/flame_tutorial_popup.dart';
import '../core/debug_logger.dart';
import '../core/analytics/unified_analytics_manager.dart';

class FTUEIntegration {
  static final UnifiedAnalyticsManager _analytics = UnifiedAnalyticsManager();
  
  /// Show tutorial animation popup before Level 1 (Flame-based)
  /// 
  /// Flame Best Practices:
  /// - Shows tutorial in non-dismissible dialog
  /// - Displays "Tutorial Complete" screen with stats
  /// - User must tap "Continue" button to proceed
  /// - Prevents race conditions from rapid taps
  /// 
  /// Analytics:
  /// - Fires `tutorial_started` when tutorial begins
  /// - Fires `tutorial_completed` when user finishes 20s or completes objective
  /// - Fires `tutorial_skipped` when user clicks skip button
  static Future<void> showTutorialAnimation(BuildContext context) async {
    safePrint('🎮 Tutorial: Showing Flame-based tutorial for Level 1');
    
    // Fire analytics: tutorial started
    try {
      _analytics.trackEvent('tutorial_started', {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      safePrint('📊 Analytics: tutorial_started event fired');
    } catch (e) {
      safePrint('❌ Error tracking tutorial_started: $e');
    }
    
    try {
      // ✅ FLAME BEST PRACTICE: Show tutorial in separate await to prevent race conditions
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return FlameTutorialPopup(
            onComplete: ({required bool completed, required int taps, required Duration duration}) async {
              safePrint('🎮 Tutorial finished: completed=$completed, taps=$taps, time=${duration.inSeconds}s');
              
              // Fire analytics: tutorial completed or skipped
              try {
                final eventName = completed ? 'tutorial_completed' : 'tutorial_skipped';
                _analytics.trackEvent(eventName, {
                  'taps': taps,
                  'duration_seconds': duration.inSeconds,
                  'timestamp': DateTime.now().millisecondsSinceEpoch,
                });
                safePrint('📊 Analytics: $eventName event fired');
              } catch (e) {
                safePrint('❌ Error tracking tutorial completion: $e');
              }
            },
          );
        },
      );
    } catch (e, stackTrace) {
      safePrint('❌ Error showing Flame tutorial: $e');
      safePrint('Stack trace: $stackTrace');
    }
  }
}

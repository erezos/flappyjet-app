/// ⭐ Rate Us Manager - Smart App Rating System
/// 
/// Handles intelligent timing and display of rate us prompts.
/// Optimized for casual mobile game best practices:
/// - Shows after positive experiences (level wins, achievements)
/// - Respects user's time and doesn't spam
/// - Tracks conversion funnel for analytics
/// 
/// Features:
/// - Session tracking for engagement measurement
/// - Railway + Firebase event tracking
/// - Configurable timing and probability
/// - Best practice: Never double-check eligibility (causes silent failures)
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_review/in_app_review.dart';
import 'firebase_analytics_manager.dart';
import '../../core/events/event_bus.dart';
import '../../core/debug_logger.dart';

/// Rate us manager for FlappyJet Pro
/// 
/// Usage:
/// ```dart
/// // Initialize on app start
/// await RateUsManager().initialize();
/// 
/// // Check eligibility (call this ONCE before showing popup)
/// if (RateUsManager().shouldShowRateUsPrompt) {
///   showRateUsPopup(); // Your custom popup
/// }
/// 
/// // When user taps "Rate" in popup, call this DIRECTLY (no re-check!)
/// await RateUsManager().requestReview();
/// ```
class RateUsManager {
  static final RateUsManager _instance = RateUsManager._internal();
  factory RateUsManager() => _instance;
  RateUsManager._internal();

  // Allow injection for testing
  InAppReview? _testInAppReview;
  InAppReview get _inAppReview => _testInAppReview ?? InAppReview.instance;
  
  /// For testing: inject mock InAppReview
  @visibleForTesting
  void setTestInAppReview(InAppReview? mock) => _testInAppReview = mock;

  // SharedPreferences keys
  static const String _keySessionCount = 'rate_us_session_count';
  static const String _keyHasRated = 'rate_us_has_rated';
  static const String _keyHasDeclined = 'rate_us_has_declined';
  static const String _keyLastPromptDate = 'rate_us_last_prompt_date';
  static const String _keyPromptCount = 'rate_us_prompt_count';
  static const String _keyFirstLaunchDate = 'rate_us_first_launch_date';

  // ============================================================================
  // CONFIGURATION - Optimized for casual game conversion
  // ============================================================================
  
  /// Minimum sessions before first prompt (engaged user)
  /// Best practice: 2-3 sessions shows commitment
  static const int minSessionsBeforePrompt = 2;
  
  /// Maximum prompts per user (respect user's choice)
  /// Best practice: 3-4 max, after that respect "no"
  static const int maxPromptsPerUser = 3;
  
  /// Days between prompts (don't spam)
  /// Best practice: 3-7 days for casual games
  static const int daysBetweenPrompts = 3;
  
  /// Minimum days since install for positive experience trigger
  /// Best practice: 1-2 days shows they're enjoying the game
  static const int minDaysForPositiveExperience = 1;
  
  /// Minimum streak day to trigger after daily streak
  /// Best practice: Day 3+ shows commitment
  static const int minStreakDayForTrigger = 3;

  // State
  bool _isInitialized = false;
  int _currentSessionCount = 0;
  bool _hasRated = false;
  bool _hasDeclined = false;
  int _promptCount = 0;
  DateTime? _lastPromptDate;
  DateTime? _firstLaunchDate;

  /// Initialize the rate us manager
  /// Call this once on app startup (in main.dart)
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load existing data
      _currentSessionCount = prefs.getInt(_keySessionCount) ?? 0;
      _hasRated = prefs.getBool(_keyHasRated) ?? false;
      _hasDeclined = prefs.getBool(_keyHasDeclined) ?? false;
      _promptCount = prefs.getInt(_keyPromptCount) ?? 0;
      
      final lastPromptMs = prefs.getInt(_keyLastPromptDate);
      _lastPromptDate = lastPromptMs != null 
          ? DateTime.fromMillisecondsSinceEpoch(lastPromptMs) 
          : null;
      
      final firstLaunchMs = prefs.getInt(_keyFirstLaunchDate);
      if (firstLaunchMs == null) {
        // First time user
        _firstLaunchDate = DateTime.now();
        await prefs.setInt(_keyFirstLaunchDate, _firstLaunchDate!.millisecondsSinceEpoch);
      } else {
        _firstLaunchDate = DateTime.fromMillisecondsSinceEpoch(firstLaunchMs);
      }

      // Increment session count
      _currentSessionCount++;
      await prefs.setInt(_keySessionCount, _currentSessionCount);

      _isInitialized = true;

      safePrint('⭐ RateUsManager initialized - Session: $_currentSessionCount, HasRated: $_hasRated, Declined: $_hasDeclined');
      
      // Track to Firebase
      FirebaseAnalyticsManager().trackEvent('rate_us_manager_initialized', {
        'session_count': _currentSessionCount,
        'has_rated': _hasRated,
        'has_declined': _hasDeclined,
        'prompt_count': _promptCount,
        'days_since_install': daysSinceFirstLaunch,
      });
      
      // Track to Railway backend for dashboard visibility
      EventBus().fire('rate_us_initialized', {
        'session_count': _currentSessionCount,
        'has_rated': _hasRated,
        'has_declined': _hasDeclined,
        'prompt_count': _promptCount,
        'days_since_install': daysSinceFirstLaunch,
      });

    } catch (e) {
      safePrint('⭐ Error initializing RateUsManager: $e');
    }
  }

  /// Check if we should show the rate us prompt
  /// 
  /// ⚠️ IMPORTANT: Call this ONCE to decide if showing popup.
  /// Do NOT call again when user taps "Rate" - use requestReview() directly!
  /// 
  /// Returns true if all conditions are met:
  /// - Manager is initialized
  /// - User hasn't rated or declined
  /// - Enough sessions have passed
  /// - Haven't exceeded max prompts
  /// - Enough days since last prompt
  bool get shouldShowRateUsPrompt {
    if (!_isInitialized) {
      safePrint('⭐ Rate us check: Not initialized');
      return false;
    }
    
    if (_hasRated) {
      safePrint('⭐ Rate us check: User already rated');
      return false;
    }
    
    if (_hasDeclined) {
      safePrint('⭐ Rate us check: User declined (respecting choice)');
      return false;
    }
    
    // Minimum sessions required
    if (_currentSessionCount < minSessionsBeforePrompt) {
      safePrint('⭐ Rate us check: Not enough sessions ($_currentSessionCount < $minSessionsBeforePrompt)');
      return false;
    }
    
    // Don't exceed max prompts
    if (_promptCount >= maxPromptsPerUser) {
      safePrint('⭐ Rate us check: Max prompts reached ($_promptCount >= $maxPromptsPerUser)');
      return false;
    }
    
    // Check time since last prompt
    if (_lastPromptDate != null) {
      final daysSinceLastPrompt = DateTime.now().difference(_lastPromptDate!).inDays;
      if (daysSinceLastPrompt < daysBetweenPrompts) {
        safePrint('⭐ Rate us check: Too soon since last prompt ($daysSinceLastPrompt < $daysBetweenPrompts days)');
        return false;
      }
    }
    
    safePrint('⭐ Rate us check: ELIGIBLE (session: $_currentSessionCount, prompts: $_promptCount)');
    return true;
  }

  /// Record that the custom popup was shown to user
  /// Call this when YOUR popup is displayed (not the native review)
  Future<void> recordPopupShown() async {
    await _recordPromptShown();
    
    // Track to Firebase
    FirebaseAnalyticsManager().trackEvent('rate_us_popup_shown', {
      'session_count': _currentSessionCount,
      'prompt_count': _promptCount,
      'days_since_install': daysSinceFirstLaunch,
    });
    
    // Track to Railway backend
    EventBus().fire('rate_us_popup_shown', {
      'session_count': _currentSessionCount,
      'prompt_count': _promptCount,
      'days_since_install': daysSinceFirstLaunch,
    });
    
    safePrint('⭐ Rate us popup shown (prompt #$_promptCount)');
  }

  /// Request the native in-app review
  /// 
  /// ⚠️ CRITICAL: Call this DIRECTLY when user taps "Rate" button!
  /// Do NOT check shouldShowRateUsPrompt again - that causes the 30% failure bug!
  /// 
  /// Returns true if review was requested successfully
  Future<bool> requestReview() async {
    try {
      // Track user tapped rate
      FirebaseAnalyticsManager().trackEvent('rate_us_rate_tapped', {
        'session_count': _currentSessionCount,
        'prompt_count': _promptCount,
      });
      
      EventBus().fire('rate_us_rate_tapped', {
        'session_count': _currentSessionCount,
        'prompt_count': _promptCount,
      });

      // Check if in-app review is available
      if (await _inAppReview.isAvailable()) {
        // Use native in-app review (iOS/Android system)
        await _inAppReview.requestReview();
        
        // Track that native prompt was shown
        FirebaseAnalyticsManager().trackEvent('rate_us_native_shown', {
          'session_count': _currentSessionCount,
        });
        
        EventBus().fire('rate_us_prompt_shown', {
          'session_count': _currentSessionCount,
          'prompt_count': _promptCount,
          'days_since_install': daysSinceFirstLaunch,
        });
        
        // Note: We can't know if user actually rated with native review
        // Mark as rated to avoid spamming, but don't track as "completed"
        await _markAsRated();
        
        safePrint('⭐ Native in-app review requested');
        return true;
      } else {
        // Fallback to store listing
        await _inAppReview.openStoreListing();
        
        EventBus().fire('rate_us_store_opened', {
          'session_count': _currentSessionCount,
          'trigger': 'fallback',
        });
        
        safePrint('⭐ Opened store listing as fallback');
        return true;
      }
    } catch (e) {
      safePrint('⭐ Error requesting review: $e');
      return false;
    }
  }

  /// @deprecated Use requestReview() instead
  /// Kept for backward compatibility
  Future<bool> showRateUsPrompt() async {
    if (!shouldShowRateUsPrompt) return false;
    await recordPopupShown();
    return requestReview();
  }

  /// Open store listing directly (for manual rating from settings)
  Future<void> openStoreListing() async {
    try {
      await _inAppReview.openStoreListing();
      
      FirebaseAnalyticsManager().trackEvent('rate_us_store_opened_manual', {
        'session_count': _currentSessionCount,
      });
      
      EventBus().fire('rate_us_store_opened', {
        'session_count': _currentSessionCount,
        'trigger': 'manual',
      });
      
      safePrint('⭐ Store listing opened manually');
    } catch (e) {
      safePrint('⭐ Error opening store listing: $e');
    }
  }

  /// User tapped "Maybe Later" - will show again after cooldown
  Future<void> handleMaybeLater() async {
    FirebaseAnalyticsManager().trackEvent('rate_us_maybe_later', {
      'session_count': _currentSessionCount,
      'prompt_count': _promptCount,
    });
    
    EventBus().fire('rate_us_maybe_later', {
      'session_count': _currentSessionCount,
      'prompt_count': _promptCount,
    });
    
    safePrint('⭐ User chose "Maybe Later" (will show again in $daysBetweenPrompts days)');
  }

  /// User tapped "No Thanks" - respect their choice, don't show again
  Future<void> handleDeclined() async {
    _hasDeclined = true;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasDeclined, true);
    
    FirebaseAnalyticsManager().trackEvent('rate_us_declined', {
      'session_count': _currentSessionCount,
      'prompt_count': _promptCount,
    });
    
    EventBus().fire('rate_us_declined', {
      'session_count': _currentSessionCount,
      'prompt_count': _promptCount,
    });
    
    safePrint('⭐ User declined rating (respecting choice, won\'t show again)');
  }

  /// Mark user as having rated (call this when user confirms they rated)
  Future<void> markAsRated() async {
    await _markAsRated();
  }

  /// Record that a prompt was shown
  Future<void> _recordPromptShown() async {
    _promptCount++;
    _lastPromptDate = DateTime.now();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyPromptCount, _promptCount);
    await prefs.setInt(_keyLastPromptDate, _lastPromptDate!.millisecondsSinceEpoch);
  }

  /// Mark user as having rated
  Future<void> _markAsRated() async {
    _hasRated = true;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasRated, true);
    
    FirebaseAnalyticsManager().trackEvent('rate_us_completed', {
      'session_count': _currentSessionCount,
      'prompt_count': _promptCount,
      'days_since_install': daysSinceFirstLaunch,
    });
    
    // This is the conversion event!
    EventBus().fire('rate_us_completed', {
      'session_count': _currentSessionCount,
      'prompt_count': _promptCount,
      'days_since_install': daysSinceFirstLaunch,
    });
    
    safePrint('⭐ User marked as having rated the app');
  }

  /// Get days since first launch
  int get daysSinceFirstLaunch {
    if (_firstLaunchDate == null) return 0;
    return DateTime.now().difference(_firstLaunchDate!).inDays;
  }

  /// Check if user should be prompted after a positive game experience
  /// Call this after achievements, level completions, etc.
  bool shouldPromptAfterPositiveExperience() {
    if (!shouldShowRateUsPrompt) return false;
    
    // Only prompt after user has been playing for at least N days
    if (daysSinceFirstLaunch < minDaysForPositiveExperience) {
      safePrint('⭐ Positive experience check: Too early ($daysSinceFirstLaunch < $minDaysForPositiveExperience days)');
      return false;
    }
    
    safePrint('⭐ Positive experience check: ELIGIBLE');
    return true;
  }

  /// Check if user should be prompted after claiming daily streak
  bool shouldPromptAfterDailyStreak(int streakDay) {
    if (!shouldShowRateUsPrompt) return false;
    
    // Only show after meaningful streak
    if (streakDay < minStreakDayForTrigger) {
      safePrint('⭐ Daily streak check: Streak too short ($streakDay < $minStreakDayForTrigger)');
      return false;
    }
    
    safePrint('⭐ Daily streak check: ELIGIBLE (day $streakDay)');
    return true;
  }

  /// Reset rate us data (for testing)
  @visibleForTesting
  Future<void> resetForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySessionCount);
    await prefs.remove(_keyHasRated);
    await prefs.remove(_keyHasDeclined);
    await prefs.remove(_keyLastPromptDate);
    await prefs.remove(_keyPromptCount);
    await prefs.remove(_keyFirstLaunchDate);
    
    _currentSessionCount = 0;
    _hasRated = false;
    _hasDeclined = false;
    _promptCount = 0;
    _lastPromptDate = null;
    _firstLaunchDate = null;
    _isInitialized = false;
    
    safePrint('⭐ Rate us data reset for testing');
  }

  /// Get debug state for testing/logging
  Map<String, dynamic> getDebugState() {
    return {
      'is_initialized': _isInitialized,
      'session_count': _currentSessionCount,
      'has_rated': _hasRated,
      'has_declined': _hasDeclined,
      'prompt_count': _promptCount,
      'days_since_install': daysSinceFirstLaunch,
      'last_prompt_date': _lastPromptDate?.toIso8601String(),
      'should_show': shouldShowRateUsPrompt,
      'config': {
        'min_sessions': minSessionsBeforePrompt,
        'max_prompts': maxPromptsPerUser,
        'days_between_prompts': daysBetweenPrompts,
        'min_days_positive_exp': minDaysForPositiveExperience,
        'min_streak_day': minStreakDayForTrigger,
      },
    };
  }

  // Public getters for UI and testing
  bool get isInitialized => _isInitialized;
  int get sessionCount => _currentSessionCount;
  bool get hasRated => _hasRated;
  bool get hasDeclined => _hasDeclined;
  int get promptCount => _promptCount;
  DateTime? get lastPromptDate => _lastPromptDate;
  DateTime? get firstLaunchDate => _firstLaunchDate;
}

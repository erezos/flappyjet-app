/// ⭐ Rate Us Manager - Smart App Rating System
/// Handles intelligent timing and display of rate us prompts
/// Features: Session tracking, 50% probability, user-friendly timing
library;

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_review/in_app_review.dart';
import 'firebase_analytics_manager.dart';

/// Rate us manager for FlappyJet Pro
class RateUsManager {
  static final RateUsManager _instance = RateUsManager._internal();
  factory RateUsManager() => _instance;
  RateUsManager._internal();

  final InAppReview _inAppReview = InAppReview.instance;
  final Random _random = Random();

  // SharedPreferences keys
  static const String _keySessionCount = 'rate_us_session_count';
  static const String _keyHasRated = 'rate_us_has_rated';
  static const String _keyLastPromptDate = 'rate_us_last_prompt_date';
  static const String _keyPromptCount = 'rate_us_prompt_count';
  static const String _keyFirstLaunchDate = 'rate_us_first_launch_date';

  // Configuration - Optimized for higher rating conversion
  static const int _minSessionsBeforePrompt = 10; // Faster engagement threshold
  static const int _maxPromptsPerUser = 4; // More opportunities to rate
  static const int _daysBetweenPrompts = 5; // More frequent prompts
  static const double _showProbability = 0.4; // 40% chance for better conversion

  bool _isInitialized = false;
  int _currentSessionCount = 0;
  bool _hasRated = false;
  int _promptCount = 0;
  DateTime? _lastPromptDate;
  DateTime? _firstLaunchDate;

  /// Initialize the rate us manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load existing data
      _currentSessionCount = prefs.getInt(_keySessionCount) ?? 0;
      _hasRated = prefs.getBool(_keyHasRated) ?? false;
      _promptCount = prefs.getInt(_keyPromptCount) ?? 0;
      
      final lastPromptMs = prefs.getInt(_keyLastPromptDate);
      _lastPromptDate = lastPromptMs != null ? DateTime.fromMillisecondsSinceEpoch(lastPromptMs) : null;
      
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

      debugPrint('⭐ RateUsManager initialized - Session: $_currentSessionCount, HasRated: $_hasRated');
      
      FirebaseAnalyticsManager().trackEvent('rate_us_manager_initialized', {
        'session_count': _currentSessionCount,
        'has_rated': _hasRated,
        'prompt_count': _promptCount,
        'days_since_install': _daysSinceFirstLaunch,
      });

    } catch (e) {
      debugPrint('⭐ Error initializing RateUsManager: $e');
    }
  }

  /// Check if we should show the rate us prompt
  bool get shouldShowRateUsPrompt {
    if (!_isInitialized || _hasRated) return false;
    
    // Not in first session
    if (_currentSessionCount < _minSessionsBeforePrompt) return false;
    
    // Don't exceed max prompts
    if (_promptCount >= _maxPromptsPerUser) return false;
    
    // Check time since last prompt
    if (_lastPromptDate != null) {
      final daysSinceLastPrompt = DateTime.now().difference(_lastPromptDate!).inDays;
      if (daysSinceLastPrompt < _daysBetweenPrompts) return false;
    }
    
    // 40% probability - optimized for conversion
    final shouldShow = _random.nextDouble() < _showProbability;
    
    debugPrint('⭐ Rate us check - Session: $_currentSessionCount, Probability: $shouldShow');
    
    return shouldShow;
  }

  /// Show the rate us prompt (native system)
  Future<bool> showRateUsPrompt() async {
    if (!shouldShowRateUsPrompt) return false;

    try {
      // Track prompt attempt
      await _recordPromptShown();
      
      FirebaseAnalyticsManager().trackEvent('rate_us_prompt_shown', {
        'session_count': _currentSessionCount,
        'prompt_count': _promptCount,
        'days_since_install': _daysSinceFirstLaunch,
      });

      // Check if in-app review is available
      if (await _inAppReview.isAvailable()) {
        // Use native in-app review (iOS/Android system)
        await _inAppReview.requestReview();
        
        // Assume user rated (we can't detect this with native review)
        await _markAsRated();
        
        debugPrint('⭐ Native in-app review requested');
        return true;
      } else {
        // Fallback to store listing
        await _inAppReview.openStoreListing();
        
        debugPrint('⭐ Opened store listing as fallback');
        return true;
      }
    } catch (e) {
      debugPrint('⭐ Error showing rate us prompt: $e');
      return false;
    }
  }

  /// Open store listing directly (for manual rating)
  Future<void> openStoreListing() async {
    try {
      await _inAppReview.openStoreListing();
      
      FirebaseAnalyticsManager().trackEvent('rate_us_store_opened_manual', {
        'session_count': _currentSessionCount,
      });
      
      debugPrint('⭐ Store listing opened manually');
    } catch (e) {
      debugPrint('⭐ Error opening store listing: $e');
    }
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
      'days_since_install': _daysSinceFirstLaunch,
    });
    
    debugPrint('⭐ User marked as having rated the app');
  }

  /// Get days since first launch
  int get _daysSinceFirstLaunch {
    if (_firstLaunchDate == null) return 0;
    return DateTime.now().difference(_firstLaunchDate!).inDays;
  }

  /// Check if user should be prompted after a positive game experience
  bool shouldPromptAfterPositiveExperience() {
    if (!shouldShowRateUsPrompt) return false;
    
    // Additional conditions for positive experience timing
    // Only prompt after user has been playing for at least 3 days
    if (_daysSinceFirstLaunch < 3) return false;
    
    return true;
  }

  /// Reset rate us data (for testing or user request)
  Future<void> resetRateUsData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySessionCount);
    await prefs.remove(_keyHasRated);
    await prefs.remove(_keyLastPromptDate);
    await prefs.remove(_keyPromptCount);
    // Don't reset first launch date
    
    _currentSessionCount = 0;
    _hasRated = false;
    _promptCount = 0;
    _lastPromptDate = null;
    
    debugPrint('⭐ Rate us data reset');
  }

  // Getters for debugging and UI
  bool get isInitialized => _isInitialized;
  int get sessionCount => _currentSessionCount;
  bool get hasRated => _hasRated;
  int get promptCount => _promptCount;
  DateTime? get lastPromptDate => _lastPromptDate;
  DateTime? get firstLaunchDate => _firstLaunchDate;
  int get daysSinceFirstLaunch => _daysSinceFirstLaunch;
}

/// 🔔 Notification Permission Manager - Smart Re-engagement System
/// Handles intelligent timing and display of notification permission requests
library;

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_notification_manager.dart';
import 'firebase_analytics_manager.dart';
import '../../ui/widgets/notification_permission_popup.dart';
import '../../core/debug_logger.dart';

/// Smart notification permission re-engagement manager
class NotificationPermissionManager {
  static final NotificationPermissionManager _instance = 
      NotificationPermissionManager._internal();
  factory NotificationPermissionManager() => _instance;
  NotificationPermissionManager._internal();

  final Random _random = Random();

  // SharedPreferences keys
  static const String _keyLastShownDate = 'notification_permission_last_shown_date';
  static const String _keyShowCount = 'notification_permission_show_count';
  static const String _keyUserDeclinedCount = 'notification_permission_declined_count';
  static const String _keyNeverShowAgain = 'notification_permission_never_show_again';

  // Configuration
  static const int _maxShowsPerUser = 3; // Don't annoy users
  static const int _daysBetweenShows = 3; // Wait 3 days between shows
  static const double _showProbability = 0.5; // 50% chance
  static const int _maxDeclines = 2; // Stop after 2 declines

  bool _isInitialized = false;
  int _showCount = 0;
  int _declinedCount = 0;
  bool _neverShowAgain = false;
  DateTime? _lastShownDate;

  /// Initialize the manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      
      _showCount = prefs.getInt(_keyShowCount) ?? 0;
      _declinedCount = prefs.getInt(_keyUserDeclinedCount) ?? 0;
      _neverShowAgain = prefs.getBool(_keyNeverShowAgain) ?? false;
      
      final lastShownTimestamp = prefs.getInt(_keyLastShownDate);
      if (lastShownTimestamp != null) {
        _lastShownDate = DateTime.fromMillisecondsSinceEpoch(lastShownTimestamp);
      }

      _isInitialized = true;
      
      Logger.d('🔔 NotificationPermissionManager initialized - Shows: $_showCount, Declined: $_declinedCount, NeverShow: $_neverShowAgain');
      
    } catch (e) {
      Logger.e('🔔 Error initializing NotificationPermissionManager: $e');
    }
  }

  /// Check if we should show the notification permission popup
  Future<bool> shouldShowPopup() async {
    if (!_isInitialized) await initialize();

    // Check if user already has permissions
    final notificationManager = LocalNotificationManager();
    if (notificationManager.hasPermissions) {
      Logger.d('🔔 User already has notification permissions');
      return false;
    }

    // Check if user said never show again
    if (_neverShowAgain) {
      Logger.d('🔔 User chose never show again');
      return false;
    }

    // Check if we've shown too many times
    if (_showCount >= _maxShowsPerUser) {
      Logger.d('🔔 Reached maximum shows per user: $_showCount');
      return false;
    }

    // Check if user declined too many times
    if (_declinedCount >= _maxDeclines) {
      Logger.d('🔔 User declined too many times: $_declinedCount');
      await _setNeverShowAgain();
      return false;
    }

    // Check time since last shown
    if (_lastShownDate != null) {
      final daysSinceLastShown = DateTime.now().difference(_lastShownDate!).inDays;
      if (daysSinceLastShown < _daysBetweenShows) {
        Logger.d('🔔 Too soon since last shown: $daysSinceLastShown days');
        return false;
      }
    }

    // Random probability check
    final shouldShow = _random.nextDouble() < _showProbability;
    Logger.d('🔔 Probability check: $shouldShow (${(_showProbability * 100).toInt()}% chance)');
    
    return shouldShow;
  }

  /// Show the notification permission popup
  Future<void> showPermissionPopup(BuildContext context) async {
    if (!await shouldShowPopup()) return;

    try {
      // Track that we're showing the popup
      await _recordPopupShown();

      // Show the popup
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => NotificationPermissionPopup(
          onAllow: () async {
            await _recordUserAllowed();
          },
          onDismiss: () async {
            await _recordUserDeclined();
          },
          onClose: () {
            // Just close, no additional tracking needed
          },
        ),
      );

    } catch (e) {
      Logger.e('🔔 Error showing notification permission popup: $e');
    }
  }

  /// Record that the popup was shown
  Future<void> _recordPopupShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _showCount++;
      _lastShownDate = DateTime.now();
      
      await prefs.setInt(_keyShowCount, _showCount);
      await prefs.setInt(_keyLastShownDate, _lastShownDate!.millisecondsSinceEpoch);

      // Track analytics
      FirebaseAnalyticsManager().trackEvent('notification_permission_manager_shown', {
        'show_count': _showCount,
        'declined_count': _declinedCount,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      Logger.d('🔔 Recorded popup shown - Count: $_showCount');
      
    } catch (e) {
      Logger.e('🔔 Error recording popup shown: $e');
    }
  }

  /// Record that user allowed notifications
  Future<void> _recordUserAllowed() async {
    try {
      // User allowed, so we don't need to show again
      await _setNeverShowAgain();

      // Track analytics
      FirebaseAnalyticsManager().trackEvent('notification_permission_manager_allowed', {
        'show_count': _showCount,
        'declined_count': _declinedCount,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      Logger.i('🔔 User allowed notifications via smart popup');
      
    } catch (e) {
      Logger.e('🔔 Error recording user allowed: $e');
    }
  }

  /// Record that user declined notifications
  Future<void> _recordUserDeclined() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _declinedCount++;
      await prefs.setInt(_keyUserDeclinedCount, _declinedCount);

      // Track analytics
      FirebaseAnalyticsManager().trackEvent('notification_permission_manager_declined', {
        'show_count': _showCount,
        'declined_count': _declinedCount,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      Logger.d('🔔 User declined notifications - Count: $_declinedCount');
      
    } catch (e) {
      Logger.e('🔔 Error recording user declined: $e');
    }
  }

  /// Set never show again flag
  Future<void> _setNeverShowAgain() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _neverShowAgain = true;
      await prefs.setBool(_keyNeverShowAgain, true);

      Logger.d('🔔 Set never show again flag');
      
    } catch (e) {
      Logger.e('🔔 Error setting never show again: $e');
    }
  }

  /// Reset all data (for testing/debugging)
  Future<void> reset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.remove(_keyLastShownDate);
      await prefs.remove(_keyShowCount);
      await prefs.remove(_keyUserDeclinedCount);
      await prefs.remove(_keyNeverShowAgain);
      
      _showCount = 0;
      _declinedCount = 0;
      _neverShowAgain = false;
      _lastShownDate = null;

      Logger.d('🔔 NotificationPermissionManager reset');
      
    } catch (e) {
      Logger.e('🔔 Error resetting NotificationPermissionManager: $e');
    }
  }

  // Getters for debugging
  bool get isInitialized => _isInitialized;
  int get showCount => _showCount;
  int get declinedCount => _declinedCount;
  bool get neverShowAgain => _neverShowAgain;
  DateTime? get lastShownDate => _lastShownDate;
}

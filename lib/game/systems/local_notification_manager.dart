/// 🔔 Local Notification Manager - iOS Only Smart Game Notifications
/// Handles local push notifications for iOS (Android uses FCM via Railway backend)
/// Features: Hearts refill, engagement reminders, daily streak alerts
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'lives_manager.dart';
import 'daily_streak_manager.dart';
import 'firebase_analytics_manager.dart';
import '../../core/debug_logger.dart';

/// Notification types for analytics and management
enum NotificationType {
  heartsRefilled,
  engagementReminder,
  dailyStreakReminder,
}

/// Smart local notification manager for iOS (Android uses FCM)
class LocalNotificationManager {
  static final LocalNotificationManager _instance = LocalNotificationManager._internal();
  factory LocalNotificationManager() => _instance;
  LocalNotificationManager._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool _permissionsGranted = false;

  // Notification IDs
  static const int _heartsRefilledId = 1;
  static const int _engagementReminderId = 2;
  static const int _dailyStreakReminderId = 3;

  // Removed Android notification channels - iOS doesn't use them

  // Preferences keys
  static const String _lastEngagementNotificationKey = 'last_engagement_notification';
  static const String _lastStreakReminderKey = 'last_streak_reminder';
  static const String _notificationsEnabledKey = 'notifications_enabled';

  /// Initialize the notification system (iOS only - Android uses FCM)
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Skip initialization for Android - FCM handles notifications via Railway backend
    if (Platform.isAndroid) {
      safePrint('🔔 Android uses FCM notifications via Railway backend, skipping local notifications');
      _isInitialized = true;
      return;
    }

    try {
      safePrint('🔔 Initializing iOS local notifications...');
      
      // Initialize timezone data
      tz.initializeTimeZones();
      
      // Set local timezone
      final String timeZoneName = await _getLocalTimeZone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));

      // Initialize notification plugin
      await _initializePlugin();
      
      // Request permissions
      await _requestPermissions();
      
      _isInitialized = true;
      
      // Schedule initial notifications if permissions granted
      if (_permissionsGranted) {
        await _scheduleInitialNotifications();
      }

      safePrint('🔔 iOS LocalNotificationManager initialized successfully');
      FirebaseAnalyticsManager().trackEvent('notification_system_initialized', {
        'permissions_granted': _permissionsGranted,
        'platform': 'ios',
      });

    } catch (e) {
      safePrint('🔔 Error initializing iOS LocalNotificationManager: $e');
    }
  }

  /// Initialize the notification plugin (iOS only)
  Future<void> _initializePlugin() async {
    // iOS-only initialization
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }
  
  /// Request notification permissions (iOS only)
  Future<void> _requestPermissions() async {
    try {
      final IOSFlutterLocalNotificationsPlugin? iosImplementation = 
          _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
              
      if (iosImplementation != null) {
        final bool? result = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        _permissionsGranted = result ?? false;
        
        if (_permissionsGranted) {
          safePrint('🔔 iOS notification permission granted by user');
        } else {
          safePrint('🔔 iOS notification permission denied by user');
        }
      } else {
        safePrint('🔔 iOS notification plugin not available');
        _permissionsGranted = false;
      }

      // Save permission status
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notificationsEnabledKey, _permissionsGranted);
      
    } catch (e) {
      safePrint('🔔 Error requesting iOS notification permissions: $e');
      _permissionsGranted = false;
    }
  }

  /// Get local timezone name with improved detection
  Future<String> _getLocalTimeZone() async {
    try {
      // Get system timezone
      final now = DateTime.now();
      final timeZoneName = now.timeZoneName;
      
      // Map common timezone abbreviations to full names
      final timezoneMap = {
        'PST': 'America/Los_Angeles',
        'PDT': 'America/Los_Angeles',
        'MST': 'America/Denver', 
        'MDT': 'America/Denver',
        'CST': 'America/Chicago',
        'CDT': 'America/Chicago',
        'EST': 'America/New_York',
        'EDT': 'America/New_York',
        'GMT': 'Europe/London',
        'BST': 'Europe/London',
        'CET': 'Europe/Paris',
        'CEST': 'Europe/Paris',
        'JST': 'Asia/Tokyo',
        'IST': 'Asia/Kolkata',
        'IDT': 'Asia/Jerusalem',
      };
      
      final mappedTimezone = timezoneMap[timeZoneName] ?? 'UTC';
      
      safePrint('ℹ️ INFO 🔔 Mapped timezone $timeZoneName → $mappedTimezone');
      
      return mappedTimezone;
    } catch (e) {
      safePrint('🔔 Error getting timezone, defaulting to UTC: $e');
      return 'UTC';
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse notificationResponse) {
    final payload = notificationResponse.payload;
    safePrint('🔔 Notification tapped with payload: $payload');
    
    // Track notification interaction
    FirebaseAnalyticsManager().trackEvent('notification_tapped', {
      'payload': payload ?? 'unknown',
      'platform': 'ios',
    });

    // Handle different notification types
    switch (payload) {
      case 'hearts_refilled':
        // Navigate to game or show hearts status
        break;
      case 'engagement_reminder':
        // Navigate to main game screen
        break;
      case 'daily_streak_reminder':
        // Navigate to daily streak screen
        break;
    }
  }

  /// Schedule initial notifications on app start
  Future<void> _scheduleInitialNotifications() async {
    if (Platform.isAndroid) return; // Skip for Android
    
    // Cancel any outdated heart notifications first
    await _cancelOutdatedHeartNotifications();
    
    await scheduleEngagementReminders();
    await scheduleDailyStreakReminder();
  }

  /// Cancel outdated heart notifications when app starts
  Future<void> _cancelOutdatedHeartNotifications() async {
    if (Platform.isAndroid) return; // Skip for Android
    
    try {
      final livesManager = LivesManager();
      final currentLives = livesManager.currentLives;
      final maxLives = livesManager.maxLives;
      
      // If hearts are already full, cancel any pending heart notifications
      if (currentLives >= maxLives) {
        await _flutterLocalNotificationsPlugin.cancel(_heartsRefilledId);
        safePrint('🔔 Cancelled outdated hearts notification - hearts already full');
      }
    } catch (e) {
      safePrint('🔔 Error cancelling outdated heart notifications: $e');
    }
  }

  /// Schedule hearts refilled notification (iOS only - Android uses FCM)
  Future<void> scheduleHeartsRefilledNotification() async {
    // Skip for Android - FCM handles this via Railway backend
    if (Platform.isAndroid) {
      safePrint('🔔 Android hearts notification handled by FCM backend');
      return;
    }
    
    if (!_permissionsGranted || !_isInitialized) return;

    try {
      // Cancel any existing hearts notifications
      await _flutterLocalNotificationsPlugin.cancel(_heartsRefilledId);

      final livesManager = LivesManager();
      final currentLives = livesManager.currentLives;
      final maxLives = livesManager.maxLives;
      
      // Don't schedule if hearts are already full
      if (currentLives >= maxLives) {
        safePrint('🔔 Cancelled outdated hearts notification - hearts already full');
        return;
      }

      // Calculate when hearts will be full (estimate 30 minutes per heart)
      final timeToFullHearts = Duration(minutes: 30) * (maxLives - currentLives);
      final scheduledTime = tz.TZDateTime.now(tz.local).add(timeToFullHearts);

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        iOS: iOSPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        _heartsRefilledId,
        '💙 Hearts Refilled!',
        'Your hearts are full! Ready for another epic flight? 🚀✈️',
        scheduledTime,
        platformChannelSpecifics,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'hearts_refilled',
        matchDateTimeComponents: DateTimeComponents.time,
      );

      safePrint('🔔 iOS hearts refilled notification scheduled for: $scheduledTime');
      
      FirebaseAnalyticsManager().trackEvent('notification_scheduled', {
        'type': 'hearts_refilled',
        'scheduled_time': scheduledTime.millisecondsSinceEpoch,
        'current_lives': currentLives,
        'platform': 'ios',
      });

    } catch (e) {
      safePrint('🔔 Error scheduling iOS hearts notification: $e');
    }
  }

  /// Schedule smart engagement reminders (iOS only - Android uses FCM)
  Future<void> scheduleEngagementReminders() async {
    // Skip for Android - FCM handles this via Railway backend
    if (Platform.isAndroid) {
      safePrint('🔔 Android engagement reminders handled by FCM backend');
      return;
    }
    
    if (!_permissionsGranted || !_isInitialized) return;

    try {
      // Check if there's already a scheduled engagement reminder
      final prefs = await SharedPreferences.getInstance();
      final lastScheduledTime = prefs.getInt(_lastEngagementNotificationKey) ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      
      // If there's a recent reminder scheduled (within last hour), don't schedule another
      if (lastScheduledTime > 0 && (currentTime - lastScheduledTime) < 3600000) { // 1 hour in ms
        safePrint('🔔 Engagement reminder already scheduled recently, skipping');
        return;
      }

      // Cancel existing engagement reminders
      await _flutterLocalNotificationsPlugin.cancel(_engagementReminderId);

      final now = tz.TZDateTime.now(tz.local);
      final nextReminderTime = _getNextEngagementReminderTime(now);

      if (nextReminderTime == null) return; // No suitable time found

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        iOS: iOSPlatformChannelSpecifics,
      );

      // Get engaging message
      final message = _getEngagingMessage();

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        _engagementReminderId,
        '🚀 Ready for Flight?',
        message,
        nextReminderTime,
        platformChannelSpecifics,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'engagement_reminder',
        matchDateTimeComponents: DateTimeComponents.time,
      );

      // Save last notification time
      await prefs.setInt(_lastEngagementNotificationKey, nextReminderTime.millisecondsSinceEpoch);

      safePrint('🔔 iOS engagement reminder scheduled for: $nextReminderTime');

      FirebaseAnalyticsManager().trackEvent('notification_scheduled', {
        'type': 'engagement_reminder',
        'scheduled_time': nextReminderTime.millisecondsSinceEpoch,
        'platform': 'ios',
      });

    } catch (e) {
      safePrint('🔔 Error scheduling iOS engagement reminder: $e');
    }
  }

  /// Get next suitable time for engagement reminder (avoiding bedtime)
  tz.TZDateTime? _getNextEngagementReminderTime(tz.TZDateTime from) {
    // Try to find a good time in the next 24 hours
    for (int hours = 4; hours <= 24; hours += 4) {
      final candidateTime = from.add(Duration(hours: hours));
      
      // Avoid bedtime hours (10 PM to 8 AM)
      if (candidateTime.hour >= 8 && candidateTime.hour < 22) {
        return candidateTime;
      }
    }
    
    // If no good time found, schedule for 10 AM tomorrow
    final tomorrow = from.add(const Duration(days: 1));
    return tz.TZDateTime(tz.local, tomorrow.year, tomorrow.month, tomorrow.day, 10);
  }

  /// Get engaging notification message
  String _getEngagingMessage() {
    final messages = [
      'The skies are calling! Your jet is ready for another adventure! ✈️',
      'Time to soar through the clouds! Your best score awaits! 🌤️',
      'Ready to break your high score? The runway is clear! 🛫',
      'Your jet misses you! Time for an epic flight! 🚀',
      'The clouds are perfect for flying today! Take off now! ☁️',
    ];
    
    return messages[DateTime.now().millisecond % messages.length];
  }

  /// Schedule daily streak reminder (iOS only - Android uses FCM)
  Future<void> scheduleDailyStreakReminder() async {
    // Skip for Android - FCM handles this via Railway backend
    if (Platform.isAndroid) {
      safePrint('🔔 Android daily streak reminders handled by FCM backend');
      return;
    }
    
    if (!_permissionsGranted || !_isInitialized) return;

    try {
      final streakManager = DailyStreakManager();
      
      // Don't schedule if streak is already claimed today
      if (streakManager.claimedToday) {
        safePrint('🔔 Daily streak already claimed, no reminder needed');
        return;
      }

      // Cancel existing streak reminders
      await _flutterLocalNotificationsPlugin.cancel(_dailyStreakReminderId);

      // Schedule reminder for 10 hours from now (or next day if too late)
      final now = tz.TZDateTime.now(tz.local);
      final reminderTime = now.add(const Duration(hours: 10));
      final adjustedTime = _adjustForBedtime(reminderTime);

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        iOS: iOSPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        _dailyStreakReminderId,
        '🎁 Daily Bonus Ready!',
        'Your streak bonus is waiting! Claim it before it\'s gone! 🔥',
        adjustedTime,
        platformChannelSpecifics,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'daily_streak_reminder',
        matchDateTimeComponents: DateTimeComponents.time,
      );

      // Save reminder time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastStreakReminderKey, adjustedTime.millisecondsSinceEpoch);

      safePrint('🔔 iOS daily streak reminder scheduled for: $adjustedTime');

      FirebaseAnalyticsManager().trackEvent('notification_scheduled', {
        'type': 'daily_streak_reminder',
        'scheduled_time': adjustedTime.millisecondsSinceEpoch,
        'current_streak': streakManager.currentStreak,
        'platform': 'ios',
      });

    } catch (e) {
      safePrint('🔔 Error scheduling iOS daily streak reminder: $e');
    }
  }

  /// Adjust time to avoid bedtime hours
  tz.TZDateTime _adjustForBedtime(tz.TZDateTime time) {
    // If scheduled during bedtime (10 PM to 8 AM), move to 9 AM
    if (time.hour >= 22 || time.hour < 8) {
      return tz.TZDateTime(
        tz.local,
        time.year,
        time.month,
        time.day + (time.hour >= 22 ? 1 : 0),
        9, // 9 AM
      );
    }
    return time;
  }

  /// Cancel all notifications (iOS only - Android uses FCM)
  Future<void> cancelAllNotifications() async {
    if (Platform.isAndroid) {
      safePrint('🔔 Android notifications managed by FCM backend');
      return;
    }
    
    await _flutterLocalNotificationsPlugin.cancelAll();
    safePrint('🔔 All iOS notifications cancelled');
  }

  /// Cancel specific notification type (iOS only - Android uses FCM)
  Future<void> cancelNotification(NotificationType type) async {
    if (Platform.isAndroid) {
      safePrint('🔔 Android notifications managed by FCM backend');
      return;
    }
    
    int notificationId;
    
    switch (type) {
      case NotificationType.heartsRefilled:
        notificationId = _heartsRefilledId;
        break;
      case NotificationType.engagementReminder:
        notificationId = _engagementReminderId;
        break;
      case NotificationType.dailyStreakReminder:
        notificationId = _dailyStreakReminderId;
        break;
    }
    
    await _flutterLocalNotificationsPlugin.cancel(notificationId);
    safePrint('🔔 Cancelled iOS notification: $type');
  }

  /// Get notification delivery status and debugging info (iOS only)
  Future<Map<String, dynamic>> getNotificationStatus() async {
    if (Platform.isAndroid) {
      return {
        'platform': 'android',
        'notification_system': 'fcm',
        'local_notifications': 'disabled',
        'message': 'Android uses FCM notifications via Railway backend'
      };
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final permissionsEnabled = prefs.getBool(_notificationsEnabledKey) ?? false;
      
      // Get pending notifications
      final pendingNotifications = await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
      
      // Get active notifications (iOS 10+)
      final activeNotifications = await _flutterLocalNotificationsPlugin.getActiveNotifications();
      
      return {
        'platform': 'ios',
        'notification_system': 'local',
        'is_initialized': _isInitialized,
        'permissions_granted': _permissionsGranted,
        'permissions_saved': permissionsEnabled,
        'pending_notifications': pendingNotifications.length,
        'active_notifications': activeNotifications.length,
        'pending_details': pendingNotifications.map((n) => {
          'id': n.id,
          'title': n.title,
          'body': n.body,
          'payload': n.payload,
        }).toList(),
        'timezone': tz.local.name,
        'current_time': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'platform': 'ios',
        'notification_system': 'local',
        'error': 'Failed to get notification status: $e',
        'is_initialized': _isInitialized,
        'permissions_granted': _permissionsGranted,
      };
    }
  }
  
  /// Validate notification scheduling (debug helper - DEBUG MODE ONLY)
  Future<bool> validateNotificationScheduling() async {
    // Only run in debug mode
    if (!kDebugMode) {
      safePrint('🔔 Notification validation skipped - not in debug mode');
      return false;
    }
    
    if (Platform.isAndroid) {
      safePrint('🔔 Android notification validation skipped - uses FCM backend');
      return true; // Consider FCM as valid
    }
    
    try {
      safePrint('🔔 Starting iOS notification validation...');
      
      // Check permissions
      if (!_permissionsGranted) {
        safePrint('🔔 Validation failed: No permissions granted');
        return false;
      }
      
      // Check initialization
      if (!_isInitialized) {
        safePrint('🔔 Validation failed: Not initialized');
        return false;
      }
      
      // Check timezone
      final timezone = tz.local.name;
      safePrint('🔔 Current timezone: $timezone');
      
      // Test scheduling a notification 10 seconds from now
      final testTime = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10));
      
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
      
      const NotificationDetails platformDetails = NotificationDetails(
        iOS: iosDetails,
      );
      
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        999, // Test ID
        '🔔 Test Notification',
        'This is a test notification to validate iOS scheduling',
        testTime,
        platformDetails,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'test_notification',
      );
      
      safePrint('🔔 Test iOS notification scheduled for: $testTime');
      
      // Cancel the test notification after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        _flutterLocalNotificationsPlugin.cancel(999);
        safePrint('🔔 Test notification cancelled');
      });
      
      return true;
      
    } catch (e) {
      safePrint('🔔 iOS notification validation failed: $e');
      return false;
    }
  }

  /// Get notification permissions status
  bool get hasPermissions => _permissionsGranted;
  
  /// Get initialization status
  bool get isInitialized => _isInitialized;
  
  /// Get platform-specific status
  String get platformStatus {
    if (Platform.isAndroid) {
      return 'Android - FCM Backend';
    } else {
      return 'iOS - Local Notifications';
    }
  }

  /// Public method to request permissions (for UI components)
  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      safePrint('🔔 Android permissions handled by FCM backend');
      return;
    }
    
    await _requestPermissions();
  }
}
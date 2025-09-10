/// 🔔 Local Notification Manager - Smart Game Notifications
/// Handles all local push notifications for FlappyJet Pro
/// Features: Hearts refill, engagement reminders, daily streak alerts
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'lives_manager.dart';
import 'daily_streak_manager.dart';
import 'firebase_analytics_manager.dart';

/// Notification types for analytics and management
enum NotificationType {
  heartsRefilled,
  engagementReminder,
  dailyStreakReminder,
}

/// Smart local notification manager for FlappyJet Pro
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

  // Notification channels
  static const String _heartsChannelId = 'hearts_refilled_channel';
  static const String _engagementChannelId = 'engagement_reminder_channel';
  static const String _streakChannelId = 'daily_streak_channel';

  // Preferences keys
  static const String _lastEngagementNotificationKey = 'last_engagement_notification';
  static const String _lastStreakReminderKey = 'last_streak_reminder';
  static const String _notificationsEnabledKey = 'notifications_enabled';

  /// Initialize the notification system
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
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

      debugPrint('🔔 LocalNotificationManager initialized successfully');
      FirebaseAnalyticsManager().trackEvent('notification_system_initialized', {
        'permissions_granted': _permissionsGranted,
        'platform': Platform.isAndroid ? 'android' : 'ios',
      });

    } catch (e) {
      debugPrint('🔔 Error initializing LocalNotificationManager: $e');
    }
  }

  /// Initialize the notification plugin with platform-specific settings
  Future<void> _initializePlugin() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Handle notification tap events
  void _onNotificationTapped(NotificationResponse notificationResponse) {
    final payload = notificationResponse.payload;
    
    FirebaseAnalyticsManager().trackEvent('notification_tapped', {
      'notification_type': payload ?? 'unknown',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    // Handle different notification types
    switch (payload) {
      case 'hearts_refilled':
        // User tapped hearts notification - they're likely ready to play
        break;
      case 'engagement_reminder':
        // User tapped engagement reminder
        break;
      case 'daily_streak_reminder':
        // User tapped daily streak reminder
        break;
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      final bool? granted = await androidImplementation?.requestNotificationsPermission();
      _permissionsGranted = granted ?? false;
    } else if (Platform.isIOS) {
      final bool? result = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      _permissionsGranted = result ?? false;
    }

    // Save permission status
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, _permissionsGranted);
  }

  /// Get local timezone name
  Future<String> _getLocalTimeZone() async {
    // Default to UTC if we can't determine local timezone
    try {
      return DateTime.now().timeZoneName;
    } catch (e) {
      return 'UTC';
    }
  }

  /// Schedule initial notifications
  Future<void> _scheduleInitialNotifications() async {
    await scheduleEngagementReminders();
    await scheduleDailyStreakReminder();
  }

  /// Schedule hearts refilled notification
  Future<void> scheduleHeartsRefilledNotification() async {
    if (!_permissionsGranted || !_isInitialized) return;

    try {
      // Calculate when hearts will be fully refilled
      final livesManager = LivesManager();
      final currentLives = livesManager.currentLives;
      
      if (currentLives >= 3) return; // Already full

      final minutesToFull = (3 - currentLives) * 30; // 30 min per heart
      final timeToFullHearts = Duration(minutes: minutesToFull);
      final scheduledTime = tz.TZDateTime.now(tz.local).add(timeToFullHearts);

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        _heartsChannelId,
        'Hearts Refilled',
        channelDescription: 'Notifications when your hearts are refilled',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigTextStyleInformation(
          '💙 Your hearts are fully refilled! Time to soar through the skies again! 🚀',
        ),
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        _heartsRefilledId,
        '💙 Hearts Refilled!',
        'Your hearts are full! Ready for another epic flight? 🚀✈️',
        scheduledTime,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'hearts_refilled',
      );

      debugPrint('🔔 Hearts refilled notification scheduled for: $scheduledTime');
      
      FirebaseAnalyticsManager().trackEvent('notification_scheduled', {
        'type': 'hearts_refilled',
        'scheduled_time': scheduledTime.millisecondsSinceEpoch,
        'current_lives': currentLives,
      });

    } catch (e) {
      debugPrint('🔔 Error scheduling hearts notification: $e');
    }
  }

  /// Schedule smart engagement reminders (every 4 hours, avoiding bedtime)
  Future<void> scheduleEngagementReminders() async {
    if (!_permissionsGranted || !_isInitialized) return;

    try {
      // Cancel existing engagement reminders
      await _flutterLocalNotificationsPlugin.cancel(_engagementReminderId);

      final now = tz.TZDateTime.now(tz.local);
      final nextReminderTime = _getNextEngagementReminderTime(now);

      if (nextReminderTime == null) return; // No suitable time found

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        _engagementChannelId,
        'Game Reminders',
        channelDescription: 'Friendly reminders to play FlappyJet',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigTextStyleInformation(
          '🚀 The skies are calling! Your jet is ready for another adventure through the clouds! ✈️',
        ),
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
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
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'engagement_reminder',
      );

      // Save last notification time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastEngagementNotificationKey, nextReminderTime.millisecondsSinceEpoch);

      debugPrint('🔔 Engagement reminder scheduled for: $nextReminderTime');

      FirebaseAnalyticsManager().trackEvent('notification_scheduled', {
        'type': 'engagement_reminder',
        'scheduled_time': nextReminderTime.millisecondsSinceEpoch,
      });

      // Schedule the next one after this
      _scheduleNextEngagementReminder(nextReminderTime);

    } catch (e) {
      debugPrint('🔔 Error scheduling engagement reminder: $e');
    }
  }

  /// Schedule next engagement reminder recursively
  Future<void> _scheduleNextEngagementReminder(tz.TZDateTime currentTime) async {
    final nextTime = _getNextEngagementReminderTime(currentTime.add(const Duration(hours: 4)));
    if (nextTime != null) {
      // Schedule the next reminder
      await Future.delayed(const Duration(seconds: 1));
      await scheduleEngagementReminders();
    }
  }

  /// Get next suitable time for engagement reminder (avoiding bedtime)
  tz.TZDateTime? _getNextEngagementReminderTime(tz.TZDateTime from) {
    tz.TZDateTime candidate = from.add(const Duration(hours: 4));
    
    // Check next 7 days for a suitable time
    for (int day = 0; day < 7; day++) {
      final checkTime = candidate.add(Duration(days: day));
      
      // Avoid bedtime hours (10 PM to 8 AM)
      if (checkTime.hour >= 8 && checkTime.hour < 22) {
        return checkTime;
      }
      
      // If it's bedtime, schedule for 9 AM next day
      if (checkTime.hour >= 22 || checkTime.hour < 8) {
        candidate = tz.TZDateTime(
          tz.local,
          checkTime.year,
          checkTime.month,
          checkTime.day + (checkTime.hour >= 22 ? 1 : 0),
          9, // 9 AM
        );
        return candidate;
      }
    }
    
    return null; // No suitable time found
  }

  /// Get engaging message for reminders
  String _getEngagingMessage() {
    final messages = [
      'The clouds are perfect for flying today! ☁️✈️',
      'Your jet misses the sky! Time for an adventure? 🚀',
      'New high scores await in the clouds! 🏆',
      'The sky is calling your name, pilot! 🌤️',
      'Ready to break your flight record? 🎯',
      'Your wings are itching for flight! 🪶',
      'Adventure awaits above the clouds! ⭐',
      'Time to show the sky who\'s boss! 💪',
    ];
    
    final now = DateTime.now();
    final index = now.millisecond % messages.length;
    return messages[index];
  }

  /// Schedule daily streak reminder (after 10 hours if not claimed)
  Future<void> scheduleDailyStreakReminder() async {
    if (!_permissionsGranted || !_isInitialized) return;

    try {
      final streakManager = DailyStreakManager();
      
      // Only schedule if user has an available streak to claim
      if (streakManager.currentState != DailyStreakState.available) return;

      // Schedule reminder 10 hours from now
      final reminderTime = tz.TZDateTime.now(tz.local).add(const Duration(hours: 10));
      
      // Adjust if it falls during bedtime
      final adjustedTime = _adjustForBedtime(reminderTime);

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        _streakChannelId,
        'Daily Streak Bonus',
        channelDescription: 'Reminders to claim your daily streak bonus',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigTextStyleInformation(
          '🎁 Your daily bonus is waiting! Don\'t let your streak slip away! 🔥',
        ),
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        _dailyStreakReminderId,
        '🎁 Daily Bonus Ready!',
        'Your streak bonus is waiting! Claim it before it\'s gone! 🔥',
        adjustedTime,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'daily_streak_reminder',
      );

      // Save reminder time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastStreakReminderKey, adjustedTime.millisecondsSinceEpoch);

      debugPrint('🔔 Daily streak reminder scheduled for: $adjustedTime');

      FirebaseAnalyticsManager().trackEvent('notification_scheduled', {
        'type': 'daily_streak_reminder',
        'scheduled_time': adjustedTime.millisecondsSinceEpoch,
        'current_streak': streakManager.currentStreak,
      });

    } catch (e) {
      debugPrint('🔔 Error scheduling daily streak reminder: $e');
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

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    debugPrint('🔔 All notifications cancelled');
  }

  /// Cancel specific notification type
  Future<void> cancelNotification(NotificationType type) async {
    int id;
    switch (type) {
      case NotificationType.heartsRefilled:
        id = _heartsRefilledId;
        break;
      case NotificationType.engagementReminder:
        id = _engagementReminderId;
        break;
      case NotificationType.dailyStreakReminder:
        id = _dailyStreakReminderId;
        break;
    }
    
    await _flutterLocalNotificationsPlugin.cancel(id);
    debugPrint('🔔 Cancelled notification: $type');
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? false;
  }

  /// Enable/disable notifications
  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);
    
    if (!enabled) {
      await cancelAllNotifications();
    } else if (_permissionsGranted) {
      await _scheduleInitialNotifications();
    }
    
    FirebaseAnalyticsManager().trackEvent('notifications_toggled', {
      'enabled': enabled,
    });
  }

  /// Get pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }

  // Getters
  bool get isInitialized => _isInitialized;
  bool get permissionsGranted => _permissionsGranted;
}

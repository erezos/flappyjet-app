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
import '../../core/debug_logger.dart';

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

      safePrint('🔔 LocalNotificationManager initialized successfully');
      FirebaseAnalyticsManager().trackEvent('notification_system_initialized', {
        'permissions_granted': _permissionsGranted,
        'platform': Platform.isAndroid ? 'android' : 'ios',
      });

    } catch (e) {
      safePrint('🔔 Error initializing LocalNotificationManager: $e');
    }
  }

  /// Initialize the notification plugin with platform-specific settings
  Future<void> _initializePlugin() async {
    // Android-specific initialization with proper channels
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
    
    // Create Android notification channels (Android 8.0+)
    if (Platform.isAndroid) {
      await _createAndroidNotificationChannels();
    }
  }
  
  /// Create Android notification channels (required for Android 8.0+)
  Future<void> _createAndroidNotificationChannels() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      // Hearts refilled channel
      const AndroidNotificationChannel heartsChannel = AndroidNotificationChannel(
        'hearts_refilled',
        'Hearts Refilled',
        description: 'Notifications when your hearts are refilled and ready to play',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: Color(0xFF2196F3), // Blue color
      );

      // Engagement reminder channel
      const AndroidNotificationChannel engagementChannel = AndroidNotificationChannel(
        'engagement_reminder',
        'Game Reminders',
        description: 'Friendly reminders to come back and play FlappyJet',
        importance: Importance.defaultImportance,
        playSound: true,
        enableVibration: false,
        enableLights: true,
        ledColor: Color(0xFF4CAF50), // Green color
      );

      // Daily streak reminder channel
      const AndroidNotificationChannel streakChannel = AndroidNotificationChannel(
        'daily_streak_reminder',
        'Daily Streak',
        description: 'Daily streak bonus reminders',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: Color(0xFFFF9800), // Orange color
      );

      // Create the channels
      await androidImplementation.createNotificationChannel(heartsChannel);
      await androidImplementation.createNotificationChannel(engagementChannel);
      await androidImplementation.createNotificationChannel(streakChannel);
      
      safePrint('🔔 Android notification channels created successfully');
    }
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

  /// Request notification permissions with enhanced Android support
  Future<void> _requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        if (androidImplementation != null) {
          // First check if we already have permission
          final bool? alreadyGranted = await androidImplementation.areNotificationsEnabled();
          
          if (alreadyGranted == true) {
            _permissionsGranted = true;
            Logger.i('🔔 Android notifications already enabled');
          } else {
            // For Android 13+ (API 33+), request POST_NOTIFICATIONS permission
            final bool? granted = await androidImplementation.requestNotificationsPermission();
            _permissionsGranted = granted ?? false;
            
            if (_permissionsGranted) {
              Logger.i('🔔 Android notification permission granted by user');
              
              // Additional setup for Android - check if battery optimization needs to be disabled
              await _checkBatteryOptimization();
            } else {
              Logger.w('🔔 Android notification permission denied by user');
              
              // Track permission denial for analytics
              FirebaseAnalyticsManager().trackEvent('notification_permission_denied', {
                'platform': 'android',
                'timestamp': DateTime.now().millisecondsSinceEpoch,
              });
            }
          }
        } else {
          Logger.w('🔔 Android notification plugin not available');
          _permissionsGranted = false;
        }
      } else if (Platform.isIOS) {
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
            Logger.i('🔔 iOS notification permission granted by user');
          } else {
            Logger.w('🔔 iOS notification permission denied by user');
          }
        } else {
          Logger.w('🔔 iOS notification plugin not available');
          _permissionsGranted = false;
        }
      }

      // Save permission status
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notificationsEnabledKey, _permissionsGranted);
      
    } catch (e) {
      Logger.e('🔔 Error requesting notification permissions: $e');
      _permissionsGranted = false;
    }
  }
  
  /// Check battery optimization for Android (helps with notification delivery)
  Future<void> _checkBatteryOptimization() async {
    if (!Platform.isAndroid) return;
    
    try {
      // Log battery optimization status for debugging
      Logger.i('🔔 Checking Android battery optimization settings...');
      
      // Note: We don't request to disable battery optimization as it requires 
      // REQUEST_IGNORE_BATTERY_OPTIMIZATIONS permission which Google restricts
      // Instead, we use inexactAllowWhileIdle scheduling mode which works better
      
      Logger.i('🔔 Using battery-friendly notification scheduling');
      
    } catch (e) {
      Logger.w('🔔 Could not check battery optimization: $e');
    }
  }

  /// Get local timezone name with improved detection
  Future<String> _getLocalTimeZone() async {
    try {
      // Try multiple methods to get the most accurate timezone
      final now = DateTime.now();
      String timeZoneName = now.timeZoneName;
      
      // Enhanced timezone mapping for problematic zones
      final timezoneMap = {
        'IDT': 'Asia/Jerusalem',    // Israel Daylight Time
        'IST': 'Asia/Jerusalem',    // Israel Standard Time  
        'PST': 'America/Los_Angeles',
        'PDT': 'America/Los_Angeles',
        'EST': 'America/New_York',
        'EDT': 'America/New_York',
        'CST': 'America/Chicago',
        'CDT': 'America/Chicago',
        'MST': 'America/Denver',
        'MDT': 'America/Denver',
        'GMT': 'Europe/London',
        'BST': 'Europe/London',
        'CET': 'Europe/Paris',
        'CEST': 'Europe/Paris',
      };
      
      // Check if we have a mapping for this timezone
      if (timezoneMap.containsKey(timeZoneName)) {
        final mappedZone = timezoneMap[timeZoneName]!;
        Logger.i('🔔 Mapped timezone $timeZoneName → $mappedZone');
        return mappedZone;
      }
      
      // Validate timezone name exists in tz database
      try {
        tz.getLocation(timeZoneName);
        Logger.i('🔔 Using detected timezone: $timeZoneName');
        return timeZoneName;
      } catch (e) {
        Logger.w('🔔 Timezone $timeZoneName not found in database: $e');
        
        // Fallback: Try to determine timezone from offset
        final offset = now.timeZoneOffset;
        final offsetHours = offset.inHours;
        
        // Common timezone mappings by UTC offset
        final offsetMap = {
          -8: 'America/Los_Angeles',  // PST/PDT
          -7: 'America/Denver',       // MST/MDT
          -6: 'America/Chicago',      // CST/CDT
          -5: 'America/New_York',     // EST/EDT
          0: 'Europe/London',         // GMT/BST
          1: 'Europe/Paris',          // CET/CEST
          2: 'Asia/Jerusalem',        // IST/IDT
          3: 'Europe/Moscow',         // MSK
          8: 'Asia/Shanghai',         // CST
          9: 'Asia/Tokyo',            // JST
        };
        
        if (offsetMap.containsKey(offsetHours)) {
          final fallbackZone = offsetMap[offsetHours]!;
          Logger.i('🔔 Using offset-based timezone: $fallbackZone (UTC${offset.isNegative ? '' : '+'}${offsetHours})');
          return fallbackZone;
        }
      }
      
      // Final fallback to UTC
      Logger.w('🔔 Could not determine timezone, using UTC');
      return 'UTC';
      
    } catch (e) {
      Logger.e('🔔 Critical timezone detection error: $e, using UTC');
      return 'UTC';
    }
  }

  /// Schedule initial notifications
  Future<void> _scheduleInitialNotifications() async {
    // Cancel any outdated heart notifications first
    await _cancelOutdatedHeartNotifications();
    
    await scheduleEngagementReminders();
    await scheduleDailyStreakReminder();
  }

  /// Cancel outdated heart notifications when app starts
  Future<void> _cancelOutdatedHeartNotifications() async {
    try {
      final livesManager = LivesManager();
      final currentLives = livesManager.currentLives;
      
      // If hearts are already full, cancel any pending heart notifications
      if (currentLives >= 3) {
        await cancelNotification(NotificationType.heartsRefilled);
        safePrint('🔔 Cancelled outdated hearts notification - hearts already full');
      }
    } catch (e) {
      safePrint('🔔 Error cancelling outdated heart notifications: $e');
    }
  }

  /// Schedule hearts refilled notification
  Future<void> scheduleHeartsRefilledNotification() async {
    if (!_permissionsGranted || !_isInitialized) return;

    try {
      // Calculate when hearts will be fully refilled
      final livesManager = LivesManager();
      final currentLives = livesManager.currentLives;
      
      if (currentLives >= 3) {
        // Cancel any existing hearts notification if hearts are already full
        await cancelNotification(NotificationType.heartsRefilled);
        return;
      }

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
        matchDateTimeComponents: DateTimeComponents.time, // Better for recurring-style notifications
      );

      safePrint('🔔 Hearts refilled notification scheduled for: $scheduledTime');
      
      FirebaseAnalyticsManager().trackEvent('notification_scheduled', {
        'type': 'hearts_refilled',
        'scheduled_time': scheduledTime.millisecondsSinceEpoch,
        'current_lives': currentLives,
      });

    } catch (e) {
      safePrint('🔔 Error scheduling hearts notification: $e');
    }
  }

  /// Schedule smart engagement reminders (every 4 hours, avoiding bedtime)
  Future<void> scheduleEngagementReminders() async {
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
        matchDateTimeComponents: DateTimeComponents.time,
      );

      // Save last notification time
      await prefs.setInt(_lastEngagementNotificationKey, nextReminderTime.millisecondsSinceEpoch);

      safePrint('🔔 Engagement reminder scheduled for: $nextReminderTime');

      FirebaseAnalyticsManager().trackEvent('notification_scheduled', {
        'type': 'engagement_reminder',
        'scheduled_time': nextReminderTime.millisecondsSinceEpoch,
      });

      // Next reminder will be scheduled when this one fires

    } catch (e) {
      safePrint('🔔 Error scheduling engagement reminder: $e');
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
        matchDateTimeComponents: DateTimeComponents.time,
      );

      // Save reminder time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastStreakReminderKey, adjustedTime.millisecondsSinceEpoch);

      safePrint('🔔 Daily streak reminder scheduled for: $adjustedTime');

      FirebaseAnalyticsManager().trackEvent('notification_scheduled', {
        'type': 'daily_streak_reminder',
        'scheduled_time': adjustedTime.millisecondsSinceEpoch,
        'current_streak': streakManager.currentStreak,
      });

    } catch (e) {
      safePrint('🔔 Error scheduling daily streak reminder: $e');
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
    safePrint('🔔 All notifications cancelled');
  }

  /// Get notification delivery status and debugging info
  Future<Map<String, dynamic>> getNotificationStatus() async {
    try {
      final pendingNotifications = await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
      final prefs = await SharedPreferences.getInstance();
      
      // Get scheduled times
      final heartsScheduledTime = prefs.getInt('hearts_refilled_scheduled_time') ?? 0;
      final engagementScheduledTime = prefs.getInt(_lastEngagementNotificationKey) ?? 0;
      final streakScheduledTime = prefs.getInt(_lastStreakReminderKey) ?? 0;
      
      final status = {
        'permissions_granted': _permissionsGranted,
        'is_initialized': _isInitialized,
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'timezone': tz.local.name,
        'current_time': DateTime.now().toIso8601String(),
        'pending_notifications': {
          'total_count': pendingNotifications.length,
          'notifications': pendingNotifications.map((n) => {
            'id': n.id,
            'title': n.title,
            'body': n.body,
            'payload': n.payload,
          }).toList(),
        },
        'scheduled_times': {
          'hearts_refilled': heartsScheduledTime > 0 
              ? DateTime.fromMillisecondsSinceEpoch(heartsScheduledTime).toIso8601String()
              : 'not_scheduled',
          'engagement_reminder': engagementScheduledTime > 0
              ? DateTime.fromMillisecondsSinceEpoch(engagementScheduledTime).toIso8601String()
              : 'not_scheduled',
          'daily_streak_reminder': streakScheduledTime > 0
              ? DateTime.fromMillisecondsSinceEpoch(streakScheduledTime).toIso8601String()
              : 'not_scheduled',
        },
        'notification_channels': await _getNotificationChannelStatus(),
      };
      
      final pendingData = status['pending_notifications'] as Map<String, dynamic>?;
      final pendingCount = pendingData?['total_count'] ?? 0;
      Logger.i('🔔 Notification status retrieved: $pendingCount pending');
      return status;
      
    } catch (e) {
      Logger.e('🔔 Error getting notification status: $e');
      return {
        'error': e.toString(),
        'permissions_granted': _permissionsGranted,
        'is_initialized': _isInitialized,
      };
    }
  }
  
  /// Get Android notification channel status
  Future<Map<String, dynamic>> _getNotificationChannelStatus() async {
    if (!Platform.isAndroid) return {'platform': 'ios'};
    
    try {
      final androidImplementation = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        final notificationsEnabled = await androidImplementation.areNotificationsEnabled();
        
        return {
          'platform': 'android',
          'notifications_enabled': notificationsEnabled,
          'channels': {
            'hearts_channel': _heartsChannelId,
            'engagement_channel': _engagementChannelId,
            'streak_channel': _streakChannelId,
          }
        };
      }
    } catch (e) {
      Logger.w('🔔 Error checking Android notification channels: $e');
    }
    
    return {'platform': 'android', 'error': 'could_not_check_channels'};
  }
  
  /// Validate notification scheduling (debug helper - DEBUG MODE ONLY)
  Future<bool> validateNotificationScheduling() async {
    // Only run in debug mode
    if (!kDebugMode) {
      safePrint('🔔 Notification validation skipped - not in debug mode');
      return false;
    }
    
    try {
      Logger.i('🔔 Starting notification validation...');
      
      // Check permissions
      if (!_permissionsGranted) {
        Logger.w('🔔 Validation failed: No permissions granted');
        return false;
      }
      
      // Check initialization
      if (!_isInitialized) {
        Logger.w('🔔 Validation failed: Not initialized');
        return false;
      }
      
      // Check timezone
      final timezone = tz.local.name;
      Logger.i('🔔 Current timezone: $timezone');
      
      // Test scheduling a notification 10 seconds from now
      final testTime = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10));
      
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'test_channel',
        'Test Notifications',
        channelDescription: 'Test notification validation',
        importance: Importance.low,
        priority: Priority.low,
      );
      
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
      
      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        999, // Test ID
        '🔔 Test Notification',
        'This is a test notification to validate scheduling',
        testTime,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle, // Game-appropriate flexible timing
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'test_notification',
      );
      
      Logger.i('🔔 Test notification scheduled for: $testTime');
      
      // Cancel the test notification after 5 seconds
      Future.delayed(const Duration(seconds: 5), () async {
        await _flutterLocalNotificationsPlugin.cancel(999);
        Logger.i('🔔 Test notification cancelled');
      });
      
      return true;
      
    } catch (e) {
      Logger.e('🔔 Notification validation failed: $e');
      return false;
    }
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
    safePrint('🔔 Cancelled notification: $type');
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
  
  /// Comprehensive Android notification diagnostics
  Future<Map<String, dynamic>> getAndroidNotificationDiagnostics() async {
    if (!Platform.isAndroid) {
      return {'platform': 'not_android'};
    }
    
    final diagnostics = <String, dynamic>{};
    
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
              
      if (androidImplementation != null) {
        // Check basic notification permission
        final bool? notificationsEnabled = await androidImplementation.areNotificationsEnabled();
        diagnostics['notifications_enabled'] = notificationsEnabled ?? false;
        
        // Get pending notifications
        final pendingNotifications = await getPendingNotifications();
        diagnostics['pending_notifications_count'] = pendingNotifications.length;
        diagnostics['pending_notifications'] = pendingNotifications.map((n) => {
          'id': n.id,
          'title': n.title,
          'body': n.body,
          'payload': n.payload,
        }).toList();
        
        // Check if channels exist
        diagnostics['channels_created'] = true; // We create them in _createAndroidNotificationChannels
        
        // System info
        diagnostics['android_version'] = 'unknown'; // Would need platform channel to get exact version
        diagnostics['manufacturer'] = 'unknown'; // Would need platform channel
        
        // Notification settings recommendations
        diagnostics['recommendations'] = [];
        
        if (notificationsEnabled != true) {
          diagnostics['recommendations'].add('Enable notifications in app settings');
        }
        
        if (pendingNotifications.isEmpty) {
          diagnostics['recommendations'].add('No notifications scheduled - check scheduling logic');
        }
        
        diagnostics['status'] = 'diagnostic_complete';
        
      } else {
        diagnostics['error'] = 'android_plugin_not_available';
      }
      
    } catch (e) {
      diagnostics['error'] = e.toString();
    }
    
    return diagnostics;
  }

  // Getters
  bool get isInitialized => _isInitialized;
  bool get permissionsGranted => _permissionsGranted;
  bool get hasPermissions => _permissionsGranted && _isInitialized;

  /// Request permissions (can be called externally)
  Future<void> requestPermissions() async {
    await _requestPermissions();
  }
  
  /// Test Android notification immediately (for debugging)
  Future<bool> testAndroidNotificationNow() async {
    if (!Platform.isAndroid || !_permissionsGranted) {
      safePrint('🔔 Cannot test Android notification - no permissions or not Android');
      return false;
    }
    
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'hearts_refilled',
        'Hearts Refilled',
        channelDescription: 'Test notification',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
      
      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _flutterLocalNotificationsPlugin.show(
        9999, // Test ID
        '🔔 Android Test Notification',
        'If you see this, Android notifications are working! 🎉',
        platformDetails,
        payload: 'test_android_notification',
      );
      
      safePrint('🔔 Android test notification sent successfully');
      return true;
      
    } catch (e) {
      safePrint('🔔 Android test notification failed: $e');
      return false;
    }
  }
}

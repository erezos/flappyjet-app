import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../config/app_config.dart';
import '../core/debug_logger.dart';

/// Top-level background message handler
/// This MUST be a top-level function and registered before runApp()
/// It runs in a separate isolate when the app is in the background or terminated
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // This runs in a separate isolate, so we can't access the PushNotificationManager instance
  // We can only do lightweight operations here
  
  safePrint('🔥 FCM BACKGROUND: Message received in background/terminated state');
  safePrint('🔥 FCM BACKGROUND: Message ID: ${message.messageId}');
  safePrint('🔥 FCM BACKGROUND: Title: ${message.notification?.title}');
  safePrint('🔥 FCM BACKGROUND: Body: ${message.notification?.body}');
  safePrint('🔥 FCM BACKGROUND: Data: ${message.data}');
  
  // Store notification data in SharedPreferences so we can handle it when app opens
  // This is especially important for terminated state
  try {
    final prefs = await SharedPreferences.getInstance();
    final notificationData = {
      'messageId': message.messageId,
      'title': message.notification?.title,
      'body': message.notification?.body,
      'data': message.data,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await prefs.setString('pending_notification', jsonEncode(notificationData));
    safePrint('🔥 FCM BACKGROUND: Stored pending notification data');
  } catch (e) {
    safePrint('🔥 FCM BACKGROUND ERROR: Failed to store notification: $e');
  }
  
  // Note: We can't show UI or access the app's context here
  // The actual handling will happen when the app opens via:
  // - getInitialMessage() for terminated state
  // - onMessageOpenedApp for background state
}

/// Push Notification Manager
/// 
/// Handles:
/// - FCM token registration
/// - Push notification receiving (foreground & background)
/// - Local notification scheduling
/// - Reward claiming
/// - Click tracking
/// 
/// Integration:
/// - Firebase Cloud Messaging (FCM V1 API)
/// - Local notifications for iOS fallback
/// - Railway backend APIs
class PushNotificationManager {
  static final PushNotificationManager _instance = PushNotificationManager._internal();
  factory PushNotificationManager() => _instance;
  PushNotificationManager._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  
  bool _initialized = false;
  String? _fcmToken;
  String? _userId;
  Function(Map<String, dynamic>)? _onRewardCallback;
  
  // Notification channel for Android
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'retention_notifications', // id
    'Retention Notifications', // name
    description: 'Push notifications to bring you back to FlappyJet',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  /// Initialize push notification system
  Future<void> initialize(String userId, {Function(Map<String, dynamic>)? onReward}) async {
    if (_initialized) {
      Logger.i('PushNotificationManager already initialized');
      return;
    }

    _userId = userId;
    _onRewardCallback = onReward;
    Logger.i('Initializing PushNotificationManager for user: $userId');
    Logger.i('🔥 FCM: Using user ID for notifications: $userId');
    safePrint('🔥 FCM: Using user ID for notifications: $userId');

    try {
      // 1. Request notification permissions
      await _requestPermissions();

      // 2. Initialize local notifications
      await _initializeLocalNotifications();

      // 3. Create Android notification channel
      if (Platform.isAndroid) {
        await _localNotifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(_channel);
      }

      // 4. Get FCM token and register with backend (NON-BLOCKING)
      // This runs in the background and doesn't block initialization
      _registerFCMToken(userId); // Fire and forget!

      // 5. Set up FCM message handlers
      _setupMessageHandlers();

      // 6. Check for pending notifications (from background handler)
      _checkPendingNotifications();

      _initialized = true;
      Logger.i('✅ PushNotificationManager initialized successfully');
    } catch (e, stack) {
      Logger.i('❌ Failed to initialize PushNotificationManager: $e');
      Logger.i('Stack: $stack');
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        Logger.i('✅ Notification permissions granted');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        Logger.i('⚠️  Notification permissions granted (provisional)');
      } else {
        Logger.i('❌ Notification permissions denied');
      }
    } catch (e) {
      Logger.i('Failed to request notification permissions: $e');
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    Logger.i('✅ Local notifications initialized');
  }

  /// Get FCM token and register with backend (NON-BLOCKING)
  /// This runs in the background and doesn't block initialization
  Future<void> _registerFCMToken(String userId) async {
    try {
      // Get FCM token
      final token = await _firebaseMessaging.getToken();
      
      if (token == null) {
        Logger.w('⚠️  FCM token is null');
        return;
      }

      _fcmToken = token;
      Logger.i('📱 FCM Token obtained: $token');

      // Listen for token refresh (setup once)
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        Logger.i('🔄 FCM token refreshed');
        _registerTokenWithBackend(newToken, userId); // Re-register with new token
      });

      // Register with backend (fire-and-forget)
      _registerTokenWithBackend(token, userId);
    } catch (e, stack) {
      Logger.e('Failed to get FCM token', error: e, stackTrace: stack);
    }
  }

  /// Register token with backend (fire-and-forget, non-blocking)
  void _registerTokenWithBackend(String token, String userId) {
    // Run async without awaiting - this is intentionally fire-and-forget
    _performRegistration(token, userId).then((_) {
      // Success handled inside
    }).catchError((e) {
      // Errors handled inside
    });
  }

  /// Actual registration logic with retries
  Future<void> _performRegistration(String token, String userId, {int attempt = 1}) async {
    const maxAttempts = 5;
    const retryDelay = Duration(seconds: 3);

    try {
      // First, ensure user is registered with backend
      await _registerUserWithBackend(userId);

      // Get device info
      final deviceInfo = await _getDeviceInfo();

      // Register FCM token
      final response = await http.post(
        Uri.parse('${AppConfig.backendUrl}/api/notifications/register-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'fcmToken': token,
          'platform': Platform.isAndroid ? 'android' : 'ios',
          'country': deviceInfo['country'],
          'timezone': deviceInfo['timezone'],
          'deviceModel': deviceInfo['deviceModel'],
          'osVersion': deviceInfo['osVersion'],
          'appVersion': deviceInfo['appVersion'],
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('FCM registration timeout'),
      );

      if (response.statusCode == 200) {
        Logger.i('✅ FCM token registered with backend (attempt $attempt)');
      } else {
        Logger.w('⚠️  FCM registration returned ${response.statusCode} (attempt $attempt)');
        
        // Retry on 5xx errors or 404 (user not found)
        if (attempt < maxAttempts && (response.statusCode >= 500 || response.statusCode == 404)) {
          Logger.i('🔄 Retrying FCM registration in ${retryDelay.inSeconds}s...');
          await Future.delayed(retryDelay);
          await _performRegistration(token, userId, attempt: attempt + 1);
        }
      }
    } catch (e) {
      Logger.w('⚠️  FCM registration failed (attempt $attempt): $e');
      
      // Retry on network errors
      if (attempt < maxAttempts) {
        Logger.i('🔄 Retrying FCM registration in ${retryDelay.inSeconds}s...');
        await Future.delayed(retryDelay);
        await _performRegistration(token, userId, attempt: attempt + 1);
      } else {
        Logger.e('❌ FCM registration failed after $maxAttempts attempts');
      }
    }
  }

  /// Register user with backend (lightweight auth)
  Future<void> _registerUserWithBackend(String userId) async {
    try {
      final deviceInfo = await _getDeviceInfo();
      
      final response = await http.post(
        Uri.parse('${AppConfig.backendUrl}/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'nickname': 'Player', // Default nickname
          'country': deviceInfo['country'],
          'deviceModel': deviceInfo['deviceModel'],
          'osVersion': deviceInfo['osVersion'],
          'appVersion': deviceInfo['appVersion'],
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        Logger.i('✅ User registered: ${data['isNew'] ? 'NEW' : 'EXISTING'}');
      } else {
        Logger.w('⚠️  User registration returned ${response.statusCode}');
      }
    } catch (e) {
      Logger.w('⚠️  User registration failed: $e');
      // Don't throw - we'll retry FCM registration which will trigger user registration again
    }
  }

  /// Get device information
  Future<Map<String, String?>> _getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final packageInfo = await _getPackageInfo();
      final countryCode = await _getCountryCode();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return {
          'deviceModel': androidInfo.model,
          'osVersion': 'Android ${androidInfo.version.release}',
          'appVersion': packageInfo['version'],
          'country': countryCode,
          'timezone': DateTime.now().timeZoneName,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return {
          'deviceModel': iosInfo.model,
          'osVersion': 'iOS ${iosInfo.systemVersion}',
          'appVersion': packageInfo['version'],
          'country': countryCode,
          'timezone': DateTime.now().timeZoneName,
        };
      }
    } catch (e) {
      Logger.e('Failed to get device info', error: e);
    }

    return {
      'deviceModel': 'Unknown',
      'osVersion': 'Unknown',
      'appVersion': 'unknown', // Fallback - actual version comes from PackageInfo
      'country': null, // No fallback - null is better than wrong data
      'timezone': 'UTC',
    };
  }

  /// Get country code from device locale
  /// Returns null if country cannot be detected (to avoid polluting analytics)
  Future<String?> _getCountryCode() async {
    try {
      // Try to get country from device locale
      final locale = Platform.localeName; // e.g., "en_US", "fr_FR", "ja_JP"
      final parts = locale.split('_');
      
      if (parts.length >= 2) {
        final countryCode = parts[1].toUpperCase();
        // Validate it's a 2-letter country code
        if (countryCode.length == 2 && RegExp(r'^[A-Z]{2}$').hasMatch(countryCode)) {
          Logger.i('🌍 Detected country code from locale: $countryCode');
          return countryCode;
        }
      }
      
      // Return null if we can't detect (don't use fallback to avoid polluting analytics)
      Logger.w('🌍 ⚠️ Could not detect country code from locale: $locale');
      return null;
    } catch (e) {
      Logger.w('🌍 ❌ Error detecting country code: $e');
      return null;
    }
  }

  /// Get package info
  Future<Map<String, String>> _getPackageInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return {
        'version': packageInfo.version,
        'buildNumber': packageInfo.buildNumber,
      };
    } catch (e) {
      return {'version': 'unknown', 'buildNumber': '0'};
    }
  }

  /// Set up FCM message handlers
  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages (user taps notification)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // Check if app was opened from a terminated state via notification
    _checkInitialMessage();
  }

  /// Handle foreground message (app is open)
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    Logger.i('📲 Foreground message received: ${message.messageId}');

    // Show local notification when app is in foreground
    await _showLocalNotification(message);
  }

  /// Handle background message (user tapped notification)
  Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    Logger.i('📲 Background message tapped: ${message.messageId}');
    await _onNotificationClick(message.data);
  }

  /// Check if app was opened from terminated state via notification
  Future<void> _checkInitialMessage() async {
    final message = await _firebaseMessaging.getInitialMessage();
    if (message != null) {
      Logger.i('📲 App opened from terminated state via notification');
      safePrint('🔥 FCM: Initial message data: ${message.data}');
      await _onNotificationClick(message.data);
    }
  }

  /// Check for pending notifications stored by background handler
  /// This handles cases where notifications were received while app was terminated
  Future<void> _checkPendingNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingData = prefs.getString('pending_notification');
      
      if (pendingData != null) {
        safePrint('🔥 FCM: Found pending notification from background handler');
        final notificationData = jsonDecode(pendingData) as Map<String, dynamic>;
        final data = notificationData['data'] as Map<String, dynamic>?;
        
        if (data != null) {
          safePrint('🔥 FCM: Processing pending notification data: $data');
          
          // Wait a bit for the app to fully initialize before showing popup
          await Future.delayed(const Duration(seconds: 2));
          
          // Process the notification
          await _onNotificationClick(data);
        }
        
        // Clear the pending notification
        await prefs.remove('pending_notification');
        safePrint('🔥 FCM: Cleared pending notification');
      }
    } catch (e) {
      Logger.w('⚠️  Failed to check pending notifications: $e');
      safePrint('🔥 FCM ERROR: Failed to check pending notifications: $e');
    }
  }

  /// Show local notification (for foreground messages)
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    safePrint('🔥 DEBUG: Showing local notification with data: ${message.data}');

    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF4FC3F7), // Flappy Jet brand color
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final payload = jsonEncode(message.data);
    safePrint('🔥 DEBUG: Notification payload JSON: $payload');

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      details,
      payload: payload,
    );
  }

  /// Handle notification tap
  Future<void> _onNotificationTapped(NotificationResponse response) async {
    safePrint('🔥 DEBUG: Local notification tapped, payload: ${response.payload}');
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        safePrint('🔥 DEBUG: Parsed notification payload: $data');
        await _onNotificationClick(data);
      } catch (e) {
        Logger.e('Failed to parse notification payload', error: e);
        safePrint('🔥 ERROR: Failed to parse payload: $e');
      }
    } else {
      safePrint('🔥 WARNING: Notification tapped but payload is null');
    }
  }

  /// Handle notification click (track + show reward)
  Future<void> _onNotificationClick(Map<String, dynamic> data) async {
    try {
      safePrint('🔥 DEBUG: Notification clicked with data: $data');

      final notificationType = data['notification_type'] ?? data['type'];
      final rewardType = data['reward_type'];
      final rewardAmount = int.tryParse(data['reward_amount']?.toString() ?? '0') ?? 0;

      Logger.i('🎯 Notification clicked: $notificationType, reward: $rewardType $rewardAmount');
      safePrint('🎯 Notification clicked: $notificationType, reward: $rewardType $rewardAmount');

      // Track click event on backend (fire and forget - non-blocking)
      if (_userId != null && notificationType != null) {
        http.post(
          Uri.parse('${AppConfig.backendUrl}/api/notifications/clicked'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'userId': _userId,
            'notificationType': notificationType,
          }),
        ).timeout(const Duration(seconds: 5)).then((_) {
          // Success - silently ignore
        }).catchError((e) {
          Logger.w('⚠️  Failed to track notification click: $e');
          // Ignore errors - this is fire-and-forget analytics
        });
      }

      // Show reward popup if there's a reward
      if (rewardType != null && rewardAmount > 0) {
        final rewardData = {
          'type': rewardType,
          'amount': rewardAmount,
          'eventId': data['event_id'],
        };
        
        // Call the callback if registered
        if (_onRewardCallback != null) {
          _onRewardCallback!(rewardData);
        }
      }
    } catch (e, stack) {
      Logger.e('Failed to handle notification click', error: e, stackTrace: stack);
    }
  }

  /// Mark reward as claimed (NON-BLOCKING)
  Future<void> claimReward(int eventId) async {
    // Fire and forget - don't block the UI
    http.post(
      Uri.parse('${AppConfig.backendUrl}/api/notifications/claimed'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'eventId': eventId}),
    ).timeout(const Duration(seconds: 5)).then((response) {
      if (response.statusCode == 200) {
        Logger.i('✅ Reward claimed for event $eventId');
      } else {
        Logger.w('⚠️  Reward claim returned ${response.statusCode}');
      }
    }).catchError((e) {
      Logger.w('⚠️  Failed to claim reward: $e');
      // Ignore errors - reward was already granted locally
    });
  }

  /// Get FCM token
  String? get fcmToken => _fcmToken;

  /// Check if initialized
  bool get isInitialized => _initialized;
}


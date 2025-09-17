/// 🔥 Firebase Cloud Messaging Service - Android Only
/// Handles push notifications for Android users with smart timezone awareness

import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../core/debug_logger.dart';
import '../game/systems/firebase_analytics_manager.dart';
import '../game/systems/railway_server_manager.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  FirebaseMessaging? _messaging;
  bool _isInitialized = false;
  String? _currentToken;

  /// Initialize FCM service (Android only)
  Future<void> initialize() async {
    // Only initialize for Android
    if (!Platform.isAndroid) {
      safePrint('🔥 FCM: iOS uses local notifications, skipping FCM initialization');
      return;
    }

    if (_isInitialized) {
      safePrint('🔥 FCM: Already initialized');
      return;
    }

    try {
      safePrint('🔥 FCM: Initializing Firebase Cloud Messaging for Android...');

      _messaging = FirebaseMessaging.instance;

      // Request notification permissions
      await _requestPermissions();

      // Get and register FCM token
      await _registerToken();

      // Set up message handlers
      _setupMessageHandlers();

      // Handle token refresh
      _messaging!.onTokenRefresh.listen(_onTokenRefresh);

      _isInitialized = true;
      safePrint('🔥 FCM: Initialization completed successfully');

      // Track FCM initialization
      FirebaseAnalyticsManager().trackEvent('fcm_initialized', {
        'platform': 'android',
        'has_token': _currentToken != null,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

    } catch (e) {
      safePrint('🔥 FCM: Initialization failed: $e');
      _isInitialized = false;
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    try {
      final settings = await _messaging!.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      safePrint('🔥 FCM: Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        safePrint('🔥 FCM: Notification permissions granted');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        safePrint('🔥 FCM: Provisional notification permissions granted');
      } else {
        safePrint('🔥 FCM: Notification permissions denied');
      }

      // Track permission result
      FirebaseAnalyticsManager().trackEvent('fcm_permission_result', {
        'status': settings.authorizationStatus.toString(),
        'platform': 'android',
      });

    } catch (e) {
      safePrint('🔥 FCM: Permission request failed: $e');
    }
  }

  /// Get and register FCM token with backend
  Future<void> _registerToken() async {
    try {
      final token = await _messaging!.getToken();
      
      if (token != null) {
        _currentToken = token;
        safePrint('🔥 FCM: Token obtained: ${token.substring(0, 20)}...');

        // Get user timezone
        final timezone = DateTime.now().timeZoneName;
        
        // Register token with Railway backend
        await _sendTokenToBackend(token, timezone);
      } else {
        safePrint('🔥 FCM: Failed to obtain token');
      }

    } catch (e) {
      safePrint('🔥 FCM: Token registration failed: $e');
    }
  }

  /// Send FCM token to Railway backend
  Future<void> _sendTokenToBackend(String token, String timezone) async {
    try {
      final railwayManager = RailwayServerManager();
      
      // Wait for authentication if not already authenticated
      int retryCount = 0;
      const maxRetries = 5;
      const retryDelay = Duration(seconds: 2);
      
      while (!railwayManager.isAuthenticated && retryCount < maxRetries) {
        safePrint('🔥 FCM: Waiting for Railway authentication... (attempt ${retryCount + 1}/$maxRetries)');
        await Future.delayed(retryDelay);
        retryCount++;
      }
      
      if (!railwayManager.isAuthenticated) {
        safePrint('🔥 FCM: Railway not authenticated after $maxRetries attempts, skipping token registration');
        return;
      }
      
      final response = await railwayManager.makeAuthenticatedRequest(
        'POST',
        '/api/fcm/register-token',
        {
          'fcmToken': token,
          'platform': 'android',
          'timezone': timezone,
        },
      );

      if (response['success'] == true) {
        safePrint('🔥 FCM: Token registered with backend successfully');
        
        FirebaseAnalyticsManager().trackEvent('fcm_token_registered', {
          'platform': 'android',
          'timezone': timezone,
        });
      } else {
        safePrint('🔥 FCM: Backend token registration failed: ${response['error']}');
      }

    } catch (e) {
      safePrint('🔥 FCM: Failed to send token to backend: $e');
    }
  }

  /// Handle token refresh
  void _onTokenRefresh(String token) {
    safePrint('🔥 FCM: Token refreshed: ${token.substring(0, 20)}...');
    _currentToken = token;
    
    // Re-register new token with backend
    final timezone = DateTime.now().timeZoneName;
    _sendTokenToBackend(token, timezone);
  }

  /// Set up message handlers for different app states
  void _setupMessageHandlers() {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle messages when app is in background but not terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // Handle messages when app is terminated and opened via notification
    _handleTerminatedMessage();
  }

  /// Handle foreground messages (app is active)
  void _handleForegroundMessage(RemoteMessage message) {
    safePrint('🔥 FCM: Foreground message received');
    safePrint('🔥 FCM: Title: ${message.notification?.title}');
    safePrint('🔥 FCM: Body: ${message.notification?.body}');
    safePrint('🔥 FCM: Data: ${message.data}');

    // Track message received
    FirebaseAnalyticsManager().trackEvent('fcm_message_received', {
      'type': message.data['type'] ?? 'unknown',
      'app_state': 'foreground',
      'has_notification': message.notification != null,
    });

    // Handle different notification types
    _handleNotificationAction(message);
  }

  /// Handle background messages (app is backgrounded)
  void _handleBackgroundMessage(RemoteMessage message) {
    safePrint('🔥 FCM: Background message opened app');
    safePrint('🔥 FCM: Title: ${message.notification?.title}');
    safePrint('🔥 FCM: Data: ${message.data}');

    // Track message interaction
    FirebaseAnalyticsManager().trackEvent('fcm_message_opened', {
      'type': message.data['type'] ?? 'unknown',
      'app_state': 'background',
    });

    // Handle notification action
    _handleNotificationAction(message);
  }

  /// Handle messages when app was terminated
  void _handleTerminatedMessage() async {
    // Check if app was opened via notification
    final initialMessage = await _messaging!.getInitialMessage();
    
    if (initialMessage != null) {
      safePrint('🔥 FCM: App opened from terminated state via notification');
      safePrint('🔥 FCM: Title: ${initialMessage.notification?.title}');
      safePrint('🔥 FCM: Data: ${initialMessage.data}');

      // Track app launch via notification
      FirebaseAnalyticsManager().trackEvent('fcm_app_launched', {
        'type': initialMessage.data['type'] ?? 'unknown',
        'app_state': 'terminated',
      });

      // Handle notification action
      _handleNotificationAction(initialMessage);
    }
  }

  /// Handle notification actions based on type
  void _handleNotificationAction(RemoteMessage message) {
    final type = message.data['type'];
    
    switch (type) {
      case 'hearts_refilled':
        _handleHeartsNotification(message);
        break;
      case 'daily_streak':
        _handleStreakNotification(message);
        break;
      case 'engagement':
        _handleEngagementNotification(message);
        break;
      case 'tournament':
        _handleTournamentNotification(message);
        break;
      case 'achievement':
        _handleAchievementNotification(message);
        break;
      default:
        safePrint('🔥 FCM: Unknown notification type: $type');
    }
  }

  /// Handle hearts refilled notification
  void _handleHeartsNotification(RemoteMessage message) {
    safePrint('🔥 FCM: Handling hearts refilled notification');
    
    // Navigate to game screen or show hearts UI
    // Implementation depends on your navigation system
    
    FirebaseAnalyticsManager().trackEvent('fcm_hearts_notification_handled', {
      'hearts': message.data['hearts'] ?? '0',
    });
  }

  /// Handle daily streak notification
  void _handleStreakNotification(RemoteMessage message) {
    safePrint('🔥 FCM: Handling daily streak notification');
    
    // Navigate to daily streak screen
    // Implementation depends on your navigation system
    
    FirebaseAnalyticsManager().trackEvent('fcm_streak_notification_handled', {
      'streak': message.data['streak'] ?? '0',
    });
  }

  /// Handle engagement notification
  void _handleEngagementNotification(RemoteMessage message) {
    safePrint('🔥 FCM: Handling engagement notification');
    
    // Navigate to main game screen
    // Implementation depends on your navigation system
    
    FirebaseAnalyticsManager().trackEvent('fcm_engagement_notification_handled', {
      'best_score': message.data['best_score'] ?? '0',
    });
  }

  /// Handle tournament notification
  void _handleTournamentNotification(RemoteMessage message) {
    safePrint('🔥 FCM: Handling tournament notification');
    
    // Navigate to tournament screen
    // Implementation depends on your navigation system
    
    FirebaseAnalyticsManager().trackEvent('fcm_tournament_notification_handled', {
      'tournament_id': message.data['tournament_id'] ?? '',
    });
  }

  /// Handle achievement notification
  void _handleAchievementNotification(RemoteMessage message) {
    safePrint('🔥 FCM: Handling achievement notification');
    
    // Show achievement popup or navigate to achievements
    // Implementation depends on your navigation system
    
    FirebaseAnalyticsManager().trackEvent('fcm_achievement_notification_handled', {});
  }

  /// Update notification preferences
  Future<bool> updateNotificationPreferences({
    bool? hearts,
    bool? streak,
    bool? engagement,
    bool? tournaments,
    bool? achievements,
  }) async {
    try {
      final railwayManager = RailwayServerManager();
      final preferences = <String, bool>{};
      
      if (hearts != null) preferences['hearts'] = hearts;
      if (streak != null) preferences['streak'] = streak;
      if (engagement != null) preferences['engagement'] = engagement;
      if (tournaments != null) preferences['tournaments'] = tournaments;
      if (achievements != null) preferences['achievements'] = achievements;

      if (preferences.isEmpty) return false;

      final response = await railwayManager.makeAuthenticatedRequest(
        'PUT',
        '/api/fcm/preferences',
        preferences,
      );

      if (response['success'] == true) {
        safePrint('🔥 FCM: Notification preferences updated');
        
        FirebaseAnalyticsManager().trackEvent('fcm_preferences_updated', preferences);
        return true;
      } else {
        safePrint('🔥 FCM: Failed to update preferences: ${response['error']}');
        return false;
      }

    } catch (e) {
      safePrint('🔥 FCM: Error updating preferences: $e');
      return false;
    }
  }

  /// Get current notification preferences
  Future<Map<String, dynamic>?> getNotificationPreferences() async {
    try {
      final railwayManager = RailwayServerManager();
      
      final response = await railwayManager.makeAuthenticatedRequest(
        'GET',
        '/api/fcm/preferences',
        null,
      );

      if (response['success'] == true) {
        return response['preferences'];
      } else {
        safePrint('🔥 FCM: Failed to get preferences: ${response['error']}');
        return null;
      }

    } catch (e) {
      safePrint('🔥 FCM: Error getting preferences: $e');
      return null;
    }
  }

  /// Unregister FCM token (call on logout)
  Future<void> unregisterToken() async {
    if (!Platform.isAndroid || !_isInitialized) return;

    try {
      final railwayManager = RailwayServerManager();
      
      final response = await railwayManager.makeAuthenticatedRequest(
        'DELETE',
        '/api/fcm/token',
        null,
      );

      if (response['success'] == true) {
        safePrint('🔥 FCM: Token unregistered successfully');
        _currentToken = null;
      } else {
        safePrint('🔥 FCM: Failed to unregister token: ${response['error']}');
      }

    } catch (e) {
      safePrint('🔥 FCM: Error unregistering token: $e');
    }
  }

  /// Send test notification (development only)
  Future<bool> sendTestNotification(String title, String body) async {
    if (kReleaseMode) {
      safePrint('🔥 FCM: Test notifications not available in release mode');
      return false;
    }

    try {
      final railwayManager = RailwayServerManager();
      
      final response = await railwayManager.makeAuthenticatedRequest(
        'POST',
        '/api/fcm/test-notification',
        {
          'title': title,
          'body': body,
        },
      );

      return response['success'] == true;

    } catch (e) {
      safePrint('🔥 FCM: Error sending test notification: $e');
      return false;
    }
  }

  /// Get FCM service status
  Map<String, dynamic> getStatus() {
    return {
      'isInitialized': _isInitialized,
      'hasToken': _currentToken != null,
      'platform': Platform.isAndroid ? 'android' : 'ios',
      'supportsFirebaseMessaging': Platform.isAndroid,
    };
  }

  /// Dispose FCM service
  void dispose() {
    // Clean up resources if needed
    _isInitialized = false;
    _currentToken = null;
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if needed
  // await Firebase.initializeApp();
  
  safePrint('🔥 FCM: Background message received: ${message.messageId}');
  safePrint('🔥 FCM: Title: ${message.notification?.title}');
  safePrint('🔥 FCM: Body: ${message.notification?.body}');
  safePrint('🔥 FCM: Data: ${message.data}');

  // Handle background message processing here if needed
  // Note: Keep this function lightweight as it runs in isolate
}

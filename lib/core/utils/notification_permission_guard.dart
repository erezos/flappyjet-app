/// 🔒 Notification Permission Guard - Prevents DuplicateTaskCompletionException
/// 
/// This crash occurs when multiple services (FCMService, PushNotificationManager,
/// LocalNotificationManager) call FirebaseMessaging.requestPermission() simultaneously
/// during app startup.
/// 
/// The Firebase plugin creates a single Task for permission requests. When multiple
/// callers try to complete the same Task, Android throws DuplicateTaskCompletionException.
/// 
/// Solution: Centralized guard that ensures only ONE permission request is active at a time.
library;

import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../core/debug_logger.dart';

/// Centralized guard for Firebase Messaging permission requests
/// 
/// Usage:
/// ```dart
/// final settings = await NotificationPermissionGuard.requestPermission(messaging);
/// ```
class NotificationPermissionGuard {
  // Private constructor - use static methods only
  NotificationPermissionGuard._();
  
  // 🔒 Shared state across all notification services
  static bool _isRequesting = false;
  static NotificationSettings? _cachedSettings;
  static Completer<NotificationSettings>? _activeRequest;
  
  /// Request notification permissions with guard against duplicate requests
  /// 
  /// If a request is already in progress, waits for it to complete and returns the result.
  /// If permissions were already requested this session, returns cached result.
  static Future<NotificationSettings> requestPermission(
    FirebaseMessaging messaging, {
    bool alert = true,
    bool badge = true,
    bool sound = true,
    bool provisional = false,
  }) async {
    // 🔒 Guard 1: Return cached result if available
    if (_cachedSettings != null) {
      safePrint('🔒 NotificationPermissionGuard: Using cached result');
      return _cachedSettings!;
    }
    
    // 🔒 Guard 2: If request in progress, wait for it
    if (_isRequesting && _activeRequest != null) {
      safePrint('🔒 NotificationPermissionGuard: Request in progress, waiting...');
      return _activeRequest!.future;
    }
    
    // Start new request
    _isRequesting = true;
    _activeRequest = Completer<NotificationSettings>();
    
    try {
      safePrint('🔒 NotificationPermissionGuard: Requesting permissions...');
      
      final settings = await messaging.requestPermission(
        alert: alert,
        badge: badge,
        sound: sound,
        provisional: provisional,
      );
      
      // Cache result
      _cachedSettings = settings;
      
      // Complete the active request for any waiters
      _activeRequest!.complete(settings);
      
      safePrint('🔒 NotificationPermissionGuard: Permission status: ${settings.authorizationStatus}');
      
      return settings;
      
    } catch (e) {
      safePrint('🔒 NotificationPermissionGuard: Request failed: $e');
      
      // Complete with error for any waiters
      if (!_activeRequest!.isCompleted) {
        _activeRequest!.completeError(e);
      }
      
      rethrow;
      
    } finally {
      _isRequesting = false;
      _activeRequest = null;
    }
  }
  
  /// Check if permissions have been requested this session
  static bool get hasRequestedThisSession => _cachedSettings != null;
  
  /// Get cached permission settings (null if not yet requested)
  static NotificationSettings? get cachedSettings => _cachedSettings;
  
  /// Reset the guard (for testing or after sign out)
  static void reset() {
    _isRequesting = false;
    _cachedSettings = null;
    _activeRequest = null;
    safePrint('🔒 NotificationPermissionGuard: Reset');
  }
}


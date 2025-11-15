import 'dart:io';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import '../core/analytics/unified_analytics_manager.dart';
import '../core/debug_logger.dart';

/// 📱 App Tracking Transparency (ATT) Manager for iOS
/// 
/// Manages iOS 14.5+ App Tracking Transparency (ATT) requirements.
/// Required by Apple before accessing IDFA for personalized ads.
/// 
/// **Apple Requirements:**
/// - Must request permission before any IDFA access
/// - Must show system prompt (automatic via requestTrackingAuthorization)
/// - Status persists across app launches
/// 
/// **Flow:**
/// 1. Check current status on app launch
/// 2. If notDetermined, show permission request (after delay)
/// 3. Track result in analytics
/// 4. Only initialize ads if authorized or on Android
/// 
/// **ATT States:**
/// - `authorized`: User granted permission ✅
/// - `denied`: User explicitly denied ❌
/// - `restricted`: Device restricted (parental controls) 🔒
/// - `notDetermined`: User hasn't been asked yet ❓
class ATTManager {
  static final ATTManager _instance = ATTManager._internal();
  factory ATTManager() => _instance;
  ATTManager._internal();

  /// Current ATT status
  TrackingStatus? _currentStatus;
  
  /// Has ATT been requested this session?
  bool _hasRequestedThisSession = false;

  /// Get current ATT status
  TrackingStatus? get currentStatus => _currentStatus;

  /// Check if tracking is authorized
  /// Returns true on Android (no ATT requirement) or if iOS user authorized
  bool get isTrackingAuthorized {
    if (Platform.isAndroid) return true; // ATT is iOS-only
    return _currentStatus == TrackingStatus.authorized;
  }

  /// Check if we should show ads
  /// True if authorized OR if device doesn't require ATT (iOS < 14.5)
  bool get canShowPersonalizedAds {
    if (Platform.isAndroid) return true;
    
    // On iOS, check ATT status
    return _currentStatus == TrackingStatus.authorized || 
           _currentStatus == TrackingStatus.notDetermined; // Allow until denied
  }

  /// Initialize ATT Manager
  /// 
  /// **Call this during app initialization (before ads)**
  /// 
  /// Steps:
  /// 1. Check current status
  /// 2. Track status in analytics
  /// 3. Return status for caller to decide when to show prompt
  Future<TrackingStatus> initialize() async {
    if (!Platform.isIOS) {
      safePrint('📱 ATT: Android - ATT not required');
      _currentStatus = TrackingStatus.authorized; // Simulate authorized for Android
      return TrackingStatus.authorized;
    }

    try {
      // Get current ATT status without requesting
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      _currentStatus = status;
      
      safePrint('📱 ATT: Current status = ${status.name}');
      
      // Track in analytics
      await _trackATTEvent('att_status_checked', {
        'status': status.name,
        'is_authorized': status == TrackingStatus.authorized,
      });

      return status;

    } catch (e) {
      safePrint('📱 ATT: Error checking status: $e');
      _currentStatus = TrackingStatus.notDetermined;
      return TrackingStatus.notDetermined;
    }
  }

  /// Request ATT permission from user
  /// 
  /// **Important:**
  /// - Apple requires 1+ second delay after app launch
  /// - Only call if status is `notDetermined`
  /// - System prompt is automatic (uses Info.plist NSUserTrackingUsageDescription)
  /// - User's choice persists forever (can only change in Settings)
  /// 
  /// Returns the user's choice
  Future<TrackingStatus> requestPermission() async {
    if (!Platform.isIOS) {
      safePrint('📱 ATT: Android - No permission needed');
      return TrackingStatus.authorized;
    }

    if (_hasRequestedThisSession) {
      safePrint('📱 ATT: Already requested this session');
      return _currentStatus ?? TrackingStatus.notDetermined;
    }

    try {
      safePrint('📱 ATT: Requesting tracking permission...');
      
      // Request tracking authorization (shows system prompt)
      final status = await AppTrackingTransparency.requestTrackingAuthorization();
      _currentStatus = status;
      _hasRequestedThisSession = true;
      
      safePrint('📱 ATT: User decision = ${status.name}');
      
      // Track user decision
      await _trackATTEvent('att_permission_requested', {
        'status': status.name,
        'is_authorized': status == TrackingStatus.authorized,
        'user_action': status == TrackingStatus.authorized ? 'allow' : 'deny',
      });

      return status;

    } catch (e) {
      safePrint('📱 ATT: Error requesting permission: $e');
      await _trackATTEvent('att_request_failed', {
        'error': e.toString(),
      });
      return TrackingStatus.notDetermined;
    }
  }

  /// Get IDFA (Identifier for Advertisers)
  /// 
  /// **Only call AFTER ATT authorization**
  /// Returns null if not authorized or on Android
  Future<String?> getIDFA() async {
    if (!Platform.isIOS) return null;
    
    if (_currentStatus != TrackingStatus.authorized) {
      safePrint('📱 ATT: Cannot get IDFA - not authorized (status: ${_currentStatus?.name})');
      return null;
    }

    try {
      final idfa = await AppTrackingTransparency.getAdvertisingIdentifier();
      safePrint('📱 ATT: IDFA retrieved: ${idfa.substring(0, 8)}...');
      return idfa;
    } catch (e) {
      safePrint('📱 ATT: Error getting IDFA: $e');
      return null;
    }
  }

  /// Open device settings to ATT
  /// 
  /// Use this if user denied but wants to enable tracking later
  Future<void> openSettings() async {
    if (!Platform.isIOS) return;
    
    try {
      safePrint('📱 ATT: Opening Settings...');
      // Note: This would require additional plugin or URL scheme
      // For now, we just log (can be enhanced with url_launcher)
      safePrint('📱 ATT: User should go to Settings > Privacy & Security > Tracking');
      
      await _trackATTEvent('att_settings_opened', {});
    } catch (e) {
      safePrint('📱 ATT: Error opening settings: $e');
    }
  }

  /// Get user-friendly status message
  String getStatusMessage() {
    if (!Platform.isIOS) {
      return 'Tracking enabled (Android)';
    }

    switch (_currentStatus) {
      case TrackingStatus.authorized:
        return 'Tracking authorized ✅';
      case TrackingStatus.denied:
        return 'Tracking denied by user ❌';
      case TrackingStatus.restricted:
        return 'Tracking restricted (parental controls) 🔒';
      case TrackingStatus.notDetermined:
        return 'Tracking not yet requested ❓';
      default:
        return 'Tracking status unknown';
    }
  }

  /// Track ATT-related analytics event
  Future<void> _trackATTEvent(String eventName, Map<String, dynamic> parameters) async {
    try {
      UnifiedAnalyticsManager().trackEvent(eventName, {
        'platform': Platform.isIOS ? 'ios' : 'android',
        'timestamp': DateTime.now().toIso8601String(),
        ...parameters,
      });
    } catch (e) {
      safePrint('📱 ATT: Failed to track event $eventName: $e');
    }
  }

  /// Reset state (for testing only)
  @visibleForTesting
  void reset() {
    _currentStatus = null;
    _hasRequestedThisSession = false;
  }
}


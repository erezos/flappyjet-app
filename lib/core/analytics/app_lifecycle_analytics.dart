/// 📊 App Lifecycle Analytics - Track app state changes and session metrics
/// 
/// Tracks critical app lifecycle events for comprehensive user behavior analysis
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../debug_logger.dart';
import 'unified_analytics_manager.dart';
import 'conversion_events_manager.dart';

/// App Lifecycle Analytics Manager
class AppLifecycleAnalytics with WidgetsBindingObserver {
  static final AppLifecycleAnalytics _instance = AppLifecycleAnalytics._internal();
  factory AppLifecycleAnalytics() => _instance;
  AppLifecycleAnalytics._internal();

  final UnifiedAnalyticsManager _analytics = UnifiedAnalyticsManager();
  final ConversionEventsManager _conversionEvents = ConversionEventsManager();
  
  DateTime? _sessionStartTime;
  DateTime? _lastActiveTime;
  int _sessionCount = 0;
  bool _isInitialized = false;

  /// Initialize app lifecycle tracking
  Future<void> initialize() async {
    if (_isInitialized) return;

    WidgetsBinding.instance.addObserver(this);
    _sessionStartTime = DateTime.now();
    _lastActiveTime = DateTime.now();
    _sessionCount++;

    // Track app launch
    _analytics.trackEvent('app_launch', {
      'session_count': _sessionCount,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'platform': defaultTargetPlatform.name,
    });

    // Track session start
    _analytics.trackEngagement(
      action: 'session_start',
      dailyPlayCount: _sessionCount,
    );

    // 🎯 Initialize conversion events and track session milestone
    await _conversionEvents.initialize();
    await _conversionEvents.onAppOpen();

    _isInitialized = true;
    safePrint('📊 App Lifecycle Analytics initialized');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        _onAppResumed();
        break;
      case AppLifecycleState.paused:
        _onAppPaused();
        break;
      case AppLifecycleState.inactive:
        _onAppInactive();
        break;
      case AppLifecycleState.detached:
        _onAppDetached();
        break;
      case AppLifecycleState.hidden:
        _onAppHidden();
        break;
    }
  }

  void _onAppResumed() {
    final now = DateTime.now();
    
    // Calculate time away if we have a last active time
    int? timeAwaySeconds;
    if (_lastActiveTime != null) {
      timeAwaySeconds = now.difference(_lastActiveTime!).inSeconds;
    }

    _analytics.trackEngagement(
      action: 'app_resumed',
      sessionDurationSeconds: timeAwaySeconds,
    );

    _lastActiveTime = now;
    safePrint('📊 App resumed - time away: ${timeAwaySeconds ?? 0}s');
  }

  void _onAppPaused() {
    final now = DateTime.now();
    
    // Calculate session duration
    int sessionDuration = 0;
    if (_sessionStartTime != null) {
      sessionDuration = now.difference(_sessionStartTime!).inSeconds;
    }

    _analytics.trackEngagement(
      action: 'app_paused',
      sessionDurationSeconds: sessionDuration,
    );

    _lastActiveTime = now;
    safePrint('📊 App paused - session duration: ${sessionDuration}s');
  }

  void _onAppInactive() {
    _analytics.trackEvent('app_inactive', {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    safePrint('📊 App inactive');
  }

  void _onAppDetached() {
    _onSessionEnd();
    safePrint('📊 App detached');
  }

  void _onAppHidden() {
    _analytics.trackEvent('app_hidden', {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    safePrint('📊 App hidden');
  }

  void _onSessionEnd() {
    final now = DateTime.now();
    
    // Calculate total session duration
    int sessionDuration = 0;
    if (_sessionStartTime != null) {
      sessionDuration = now.difference(_sessionStartTime!).inSeconds;
    }

    _analytics.trackEngagement(
      action: 'session_end',
      sessionDurationSeconds: sessionDuration,
    );

    safePrint('📊 Session ended - duration: ${sessionDuration}s');
  }

  /// Track feature usage
  void trackFeatureUsage(String featureName, {Map<String, dynamic>? metadata}) {
    _analytics.trackFeatureUsage(
      featureName: featureName,
      metadata: metadata,
    );
  }

  /// Track performance metrics
  void trackPerformance(String metricName, double value, {String? unit}) {
    _analytics.trackPerformance(
      metricName: metricName,
      value: value,
      unit: unit,
    );
  }

  /// Track error/crash
  void trackError(String errorType, String errorMessage, {String? stackTrace}) {
    _analytics.trackError(
      errorType: errorType,
      errorMessage: errorMessage,
      stackTrace: stackTrace,
    );
  }

  /// Get session statistics
  Map<String, dynamic> getSessionStats() {
    final now = DateTime.now();
    int currentSessionDuration = 0;
    
    if (_sessionStartTime != null) {
      currentSessionDuration = now.difference(_sessionStartTime!).inSeconds;
    }

    return {
      'session_count': _sessionCount,
      'current_session_duration': currentSessionDuration,
      'session_start_time': _sessionStartTime?.toIso8601String(),
      'last_active_time': _lastActiveTime?.toIso8601String(),
    };
  }

  /// Dispose resources
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _onSessionEnd();
  }
}


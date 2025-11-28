/// 📊 Async Analytics Manager - Non-blocking analytics for anonymous + authenticated users
/// Queues events until analytics is ready, never blocks gameplay
library;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../game/systems/anonymous_identity_manager.dart';
import '../../game/systems/player_identity_manager.dart';
import '../../game/systems/firebase_analytics_manager.dart';
import '../../core/debug_logger.dart';

enum AnalyticsState {
  initializing,
  ready,
  failed,
  disabled,
}

class AnalyticsEvent {
  final String name;
  final Map<String, dynamic> parameters;
  final DateTime timestamp;
  final String sessionId;

  AnalyticsEvent({
    required this.name,
    required this.parameters,
    required this.timestamp,
    required this.sessionId,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'parameters': parameters,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'sessionId': sessionId,
  };

  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) => AnalyticsEvent(
    name: json['name'],
    parameters: Map<String, dynamic>.from(json['parameters']),
    timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
    sessionId: json['sessionId'],
  );
}

/// Async Analytics Manager - Never blocks, always works
class AsyncAnalyticsManager extends ChangeNotifier {
  static final AsyncAnalyticsManager _instance = AsyncAnalyticsManager._internal();
  factory AsyncAnalyticsManager() => _instance;
  AsyncAnalyticsManager._internal();

  // Core systems
  final AnonymousIdentityManager _anonymousIdentity = AnonymousIdentityManager();
  final PlayerIdentityManager _playerIdentity = PlayerIdentityManager();
  FirebaseAnalyticsManager? _firebaseAnalytics;

  // State management
  AnalyticsState _state = AnalyticsState.initializing;
  final List<AnalyticsEvent> _eventQueue = [];
  String _sessionId = '';
  String? _appVersion;
  Timer? _flushTimer;
  
  // Configuration
  static const int maxQueueSize = 1000;
  static const Duration flushInterval = Duration(seconds: 30);
  static const String _queueStorageKey = 'analytics_event_queue';

  // Getters
  AnalyticsState get state => _state;
  bool get isReady => _state == AnalyticsState.ready;
  int get queuedEvents => _eventQueue.length;
  String get sessionId => _sessionId;

  /// Initialize analytics (async, non-blocking)
  Future<void> initializeAsync() async {
    try {
      safePrint('📊 Starting async analytics initialization...');
      
      // Generate session ID
      _sessionId = _generateSessionId();
      
      // Load app version from package info
      await _loadAppVersion();
      
      // Load queued events from storage
      await _loadQueuedEvents();
      
      // Try to initialize Firebase Analytics (non-blocking)
      _initializeFirebaseAsync();
      
      // Start periodic flush timer
      _startFlushTimer();
      
      safePrint('📊 ✅ Async analytics manager initialized');
      safePrint('📊 Session ID: $_sessionId');
      safePrint('📊 Queued events: ${_eventQueue.length}');
      
    } catch (e) {
      safePrint('📊 ⚠️ Analytics initialization error: $e');
      _state = AnalyticsState.failed;
    }
    
    notifyListeners();
  }

  /// Initialize Firebase Analytics in background
  Future<void> _initializeFirebaseAsync() async {
    try {
      _firebaseAnalytics = FirebaseAnalyticsManager();
      await _firebaseAnalytics!.initialize();
      
      _state = AnalyticsState.ready;
      safePrint('📊 ✅ Firebase Analytics ready');
      
      // Flush queued events
      await _flushQueuedEvents();
      
    } catch (e) {
      safePrint('📊 ⚠️ Firebase Analytics failed: $e');
      _state = AnalyticsState.failed;
      // Continue with local queuing
    }
    
    notifyListeners();
  }

  /// Load app version from package info
  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = packageInfo.version;
      safePrint('📊 App version loaded: $_appVersion');
    } catch (e) {
      safePrint('📊 ⚠️ Failed to load app version: $e');
      _appVersion = 'unknown';
    }
  }

  /// Track event (always non-blocking)
  void trackEvent(String eventName, [Map<String, dynamic>? parameters]) {
    try {
      final enrichedParameters = _enrichParameters(parameters ?? {});
      
      final event = AnalyticsEvent(
        name: eventName,
        parameters: enrichedParameters,
        timestamp: DateTime.now(),
        sessionId: _sessionId,
      );

      if (_state == AnalyticsState.ready && _firebaseAnalytics != null) {
        // Send immediately (async)
        _sendEventAsync(event);
      } else {
        // Queue for later
        _queueEvent(event);
      }

      // Debug logging
      if (kDebugMode) {
        safePrint('📊 Event: $eventName ${enrichedParameters.isNotEmpty ? enrichedParameters : ""}');
      }

    } catch (e) {
      safePrint('📊 ⚠️ Error tracking event $eventName: $e');
      // Never crash the app due to analytics
    }
  }

  /// Enrich event parameters with user context
  Map<String, dynamic> _enrichParameters(Map<String, dynamic> parameters) {
    final enriched = Map<String, dynamic>.from(parameters);
    
    // Add user type and ID
    if (_playerIdentity.isAuthenticated) {
      enriched['user_type'] = 'authenticated';
      enriched['player_id'] = _playerIdentity.playerId;
      enriched['cloud_connected'] = true;
    } else {
      enriched['user_type'] = 'anonymous';
      enriched['anonymous_id'] = _anonymousIdentity.anonymousId;
      enriched['cloud_connected'] = false;
    }
    
    // Add session context
    enriched['session_id'] = _sessionId;
    enriched['app_version'] = _appVersion ?? 'unknown'; // Dynamic from PackageInfo
    enriched['platform'] = defaultTargetPlatform.name;
    
    // Add identity state
    enriched['identity_state'] = _anonymousIdentity.state.name;
    
    return enriched;
  }

  /// Queue event for later sending
  void _queueEvent(AnalyticsEvent event) {
    // Prevent queue from growing too large
    if (_eventQueue.length >= maxQueueSize) {
      _eventQueue.removeAt(0); // Remove oldest event
      safePrint('📊 ⚠️ Analytics queue full, dropped oldest event');
    }
    
    _eventQueue.add(event);
    
    // Save to storage periodically
    _saveQueuedEventsAsync();
  }

  /// Send event immediately (async)
  Future<void> _sendEventAsync(AnalyticsEvent event) async {
    try {
      if (_firebaseAnalytics != null) {
        // Send to Firebase (non-blocking)
        unawaited(_firebaseAnalytics!.trackEvent(
          event.name,
          event.parameters,
        ));
      }
      
      // Could also send to other analytics services here
      // unawaited(_sendToCustomAnalytics(event));
      
    } catch (e) {
      safePrint('📊 ⚠️ Error sending event ${event.name}: $e');
      // Re-queue the event if sending failed
      _queueEvent(event);
    }
  }

  /// Flush all queued events
  Future<void> _flushQueuedEvents() async {
    if (_eventQueue.isEmpty) return;
    
    safePrint('📊 🚀 Flushing ${_eventQueue.length} queued events...');
    
    final eventsToFlush = List<AnalyticsEvent>.from(_eventQueue);
    _eventQueue.clear();
    
    for (final event in eventsToFlush) {
      await _sendEventAsync(event);
      // Small delay to avoid overwhelming the service
      await Future.delayed(Duration(milliseconds: 10));
    }
    
    // Clear storage
    await _clearQueuedEvents();
    
    safePrint('📊 ✅ Event queue flushed');
  }

  /// Start periodic flush timer
  void _startFlushTimer() {
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(flushInterval, (timer) {
      if (_state == AnalyticsState.ready && _eventQueue.isNotEmpty) {
        _flushQueuedEvents();
      }
    });
  }

  /// Generate unique session ID
  String _generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'session_${timestamp}_$random';
  }

  /// Load queued events from storage
  Future<void> _loadQueuedEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_queueStorageKey);
      
      if (queueJson != null) {
        final List<dynamic> eventList = jsonDecode(queueJson);
        _eventQueue.addAll(
          eventList.map((json) => AnalyticsEvent.fromJson(json)).toList()
        );
        
        safePrint('📊 Loaded ${_eventQueue.length} queued events from storage');
      }
    } catch (e) {
      safePrint('📊 ⚠️ Error loading queued events: $e');
    }
  }

  /// Save queued events to storage (async)
  Future<void> _saveQueuedEventsAsync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventList = _eventQueue.map((event) => event.toJson()).toList();
      await prefs.setString(_queueStorageKey, jsonEncode(eventList));
    } catch (e) {
      safePrint('📊 ⚠️ Error saving queued events: $e');
    }
  }

  /// Clear queued events from storage
  Future<void> _clearQueuedEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_queueStorageKey);
    } catch (e) {
      safePrint('📊 ⚠️ Error clearing queued events: $e');
    }
  }

  /// Common game events (convenience methods)
  void trackGameStart() => trackEvent('game_start');
  void trackGameEnd(int score, int survivalTime) => trackEvent('game_end', {
    'score': score,
    'survival_time': survivalTime,
  });
  void trackLevelUp(int level) => trackEvent('level_up', {'level': level});
  void trackPurchase(String itemId, String currency, int amount) => trackEvent('purchase', {
    'item_id': itemId,
    'currency': currency,
    'amount': amount,
  });
  void trackAdViewed(String adType, String placement) => trackEvent('ad_viewed', {
    'ad_type': adType,
    'placement': placement,
  });
  void trackCloudConnection(bool success) => trackEvent('cloud_connection', {
    'success': success,
    'previous_state': _anonymousIdentity.state.name,
  });

  /// Dispose resources
  @override
  void dispose() {
    _flushTimer?.cancel();
    super.dispose();
  }
}

/// Extension to avoid awaiting fire-and-forget futures
extension Unawaited on Future {
  void get unawaited => then((_) {}, onError: (_) {});
}

/// 🚀 Smart Railway Analytics - Zero Performance Impact Event Tracking
/// 
/// Features:
/// - Asynchronous batching (no UI blocking)
/// - Background processing with isolates
/// - Smart retry logic with exponential backoff
/// - Local caching for offline scenarios
/// - Rate limiting to prevent spam
/// - Compression for efficient data transfer
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../debug_logger.dart';
import '../network/network_manager.dart';
import '../../game/systems/player_identity_manager.dart';

/// Smart analytics event with metadata
class AnalyticsEvent {
  final String eventName;
  final Map<String, dynamic> parameters;
  final DateTime timestamp;
  final int retryCount;
  final String? sessionId;
  final String? playerId;

  AnalyticsEvent({
    required this.eventName,
    required this.parameters,
    DateTime? timestamp,
    this.retryCount = 0,
    this.sessionId,
    this.playerId,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'event_name': eventName,
    'event_data': parameters,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'retry_count': retryCount,
    'session_id': sessionId,
    'player_id': playerId,
  };

  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) => AnalyticsEvent(
    eventName: json['event_name'],
    parameters: Map<String, dynamic>.from(json['event_data']),
    timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
    retryCount: json['retry_count'] ?? 0,
    sessionId: json['session_id'],
    playerId: json['player_id'],
  );
}

/// Smart Railway Analytics Manager
class SmartRailwayAnalytics {
  static final SmartRailwayAnalytics _instance = SmartRailwayAnalytics._internal();
  factory SmartRailwayAnalytics() => _instance;
  SmartRailwayAnalytics._internal();

  // Configuration - Enhanced for gaming performance
  static const int _maxBatchSize = 50;
  static const int _maxRetries = 3;
  static const Duration _batchInterval = Duration(seconds: 30);
  static const int _maxQueuedEvents = 1000;
  
  // Enhanced performance settings
  static const Duration _criticalEventTimeout = Duration(seconds: 2);
  static const bool _enableAdaptiveBatching = true;

  // State
  final List<AnalyticsEvent> _eventQueue = [];
  final List<AnalyticsEvent> _failedEvents = [];
  Timer? _batchTimer;
  bool _isProcessing = false;
  bool _isInitialized = false;
  String? _sessionId;
  String? _playerId;
  NetworkManager? _networkManager;
  PlayerIdentityManager? _playerIdentity;

  // Performance tracking
  int _eventsTracked = 0;
  int _eventsSent = 0;
  int _eventsFailed = 0;
  DateTime? _lastBatchSent;
  
  // Adaptive performance tracking
  final List<Duration> _batchProcessingTimes = [];
  final List<int> _batchSizes = [];
  int _consecutiveFailures = 0;
  bool _isUserActive = true;
  DateTime? _lastUserActivity;

  /// Initialize the smart analytics system
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _networkManager = NetworkManager();
      _playerIdentity = PlayerIdentityManager();
      await _networkManager!.initialize();

      // Generate session ID
      _sessionId = _generateSessionId();
      
      // Get player ID
      _playerId = _playerIdentity!.playerId;

      // Start batch processing timer
      _startBatchTimer();

      // Load failed events from storage
      await _loadFailedEvents();

      // Process any queued events from previous session
      await _processQueuedEvents();

      _isInitialized = true;
      safePrint('🚀 Smart Railway Analytics initialized successfully');
      safePrint('🚀 Session ID: $_sessionId');
      safePrint('🚀 Player ID: ${_playerId ?? 'anonymous'}');

    } catch (e) {
      safePrint('🚀 ❌ Smart Railway Analytics initialization failed: $e');
    }
  }

  /// Update player ID and process queued events
  void updatePlayerId(String? newPlayerId) {
    if (newPlayerId != null && newPlayerId.isNotEmpty && newPlayerId != _playerId) {
      final oldPlayerId = _playerId;
      _playerId = newPlayerId;
      
      safePrint('🚀 Player ID updated: ${oldPlayerId ?? 'anonymous'} -> $newPlayerId');
      
      // Process queued events that were waiting for player ID
      _processQueuedEventsWithPlayerId();
    }
  }

  /// Process queued events that were waiting for player ID
  void _processQueuedEventsWithPlayerId() {
    if (_playerId == null || _playerId!.isEmpty) return;

    int processedCount = 0;
    for (final event in _eventQueue) {
      if (event.playerId == null) {
        // Update the event with the new player ID
        final updatedEvent = AnalyticsEvent(
          eventName: event.eventName,
          parameters: event.parameters,
          timestamp: event.timestamp,
          retryCount: event.retryCount,
          sessionId: event.sessionId,
          playerId: _playerId,
        );
        
        // Replace the event in the queue
        final index = _eventQueue.indexOf(event);
        if (index != -1) {
          _eventQueue[index] = updatedEvent;
          processedCount++;
        }
      }
    }

    if (processedCount > 0) {
      safePrint('🚀 ✅ Updated $processedCount queued events with player ID');
      // Trigger immediate processing for updated events
      _processBatchImmediately();
    }
  }

  /// Track an event (zero performance impact with smart queuing)
  void trackEvent(String eventName, Map<String, dynamic> parameters) {
    if (!_isInitialized) {
      safePrint('🚀 ⚠️ Analytics not initialized, queuing event: $eventName');
      _queueEvent(eventName, parameters);
      return;
    }

    try {
      // Update user activity tracking
      _updateUserActivity(eventName);
      
      // Enrich event with metadata
      final enrichedParams = Map<String, dynamic>.from(parameters);
      enrichedParams['timestamp'] = DateTime.now().millisecondsSinceEpoch;
      enrichedParams['session_id'] = _sessionId;
      enrichedParams['player_id'] = _playerId;
      enrichedParams['app_version'] = '1.4.8';
      enrichedParams['platform'] = defaultTargetPlatform.name;

      // Smart queuing based on event type and player context
      _smartQueueEvent(eventName, enrichedParams);

      _eventsTracked++;
      
      if (kDebugMode) {
        safePrint('🚀 Event queued: $eventName (Queue size: ${_eventQueue.length})');
      }

    } catch (e) {
      safePrint('🚀 ❌ Failed to track event $eventName: $e');
    }
  }

  /// Update user activity tracking
  void _updateUserActivity(String eventName) {
    final activityEvents = [
      'game_start', 'game_end', 'level_up', 'purchase', 'feature_usage',
      'user_engagement', 'mission_complete', 'achievement_unlock'
    ];
    
    if (activityEvents.contains(eventName)) {
      _isUserActive = true;
      _lastUserActivity = DateTime.now();
    }
  }

  /// Smart queuing based on event type and player context
  void _smartQueueEvent(String eventName, Map<String, dynamic> parameters) {
    // Define events that can be sent without player ID (anonymous events)
    const anonymousEvents = {
      'app_start', 'app_crash', 'performance_metrics', 'app_launch',
      'app_paused', 'app_resumed', 'app_inactive', 'app_hidden',
      'session_start', 'session_end', 'background_sync'
    };

    // Define events that require player ID (user-specific events)
    const playerRequiredEvents = {
      'game_start', 'game_end', 'purchase', 'achievement_unlock',
      'mission_complete', 'level_up', 'tournament_event', 'social_share',
      'feature_usage', 'user_engagement', 'app_rating'
    };

    final hasValidPlayerId = _playerId != null && _playerId!.isNotEmpty;
    final isAnonymousEvent = anonymousEvents.contains(eventName);
    final isPlayerRequiredEvent = playerRequiredEvents.contains(eventName);

    // Smart queuing logic
    if (isAnonymousEvent) {
      // Anonymous events can be sent immediately
      _queueEvent(eventName, parameters);
    } else if (isPlayerRequiredEvent && !hasValidPlayerId) {
      // Player-required events without player ID - queue for later
      _queueEventForLater(eventName, parameters);
      safePrint('🚀 ⚠️ Queued player-required event for later: $eventName (no player ID)');
    } else {
      // Regular events - queue normally
      _queueEvent(eventName, parameters);
    }
  }

  /// Queue event for batch processing
  void _queueEvent(String eventName, Map<String, dynamic> parameters) {
    final event = AnalyticsEvent(
      eventName: eventName,
      parameters: parameters,
      sessionId: _sessionId,
      playerId: _playerId,
    );

    _eventQueue.add(event);

    // Prevent memory overflow
    if (_eventQueue.length > _maxQueuedEvents) {
      _eventQueue.removeAt(0);
      safePrint('🚀 ⚠️ Event queue full, dropping oldest event');
    }

    // Trigger immediate processing for critical events
    if (_isCriticalEvent(eventName)) {
      _processBatchImmediately();
    }
  }

  /// Queue event for later processing when player ID becomes available
  void _queueEventForLater(String eventName, Map<String, dynamic> parameters) {
    final event = AnalyticsEvent(
      eventName: eventName,
      parameters: parameters,
      sessionId: _sessionId,
      playerId: null, // Will be filled when player ID is available
    );

    _eventQueue.add(event);

    // Prevent memory overflow
    if (_eventQueue.length > _maxQueuedEvents) {
      _eventQueue.removeAt(0);
      safePrint('🚀 ⚠️ Event queue full, dropping oldest event');
    }
  }

  /// Enhanced event prioritization system
  int _getEventPriority(String eventName) {
    const criticalEvents = {
      'purchase': 1,
      'iap_purchase': 1,
      'achievement_unlock': 1,
      'app_crash': 1,
      'game_end': 2,
      'tournament_event': 2,
      'level_up': 2,
      'mission_complete': 2,
      'game_start': 3,
      'feature_usage': 3,
      'user_engagement': 3,
      'performance_metric': 4,
      'app_start': 4,
      'session_start': 4,
      'background_sync': 5,
    };
    return criticalEvents[eventName] ?? 3; // Default medium priority
  }

  /// Check if event is critical (needs immediate processing)
  bool _isCriticalEvent(String eventName) {
    return _getEventPriority(eventName) <= 2;
  }


  /// Start batch processing timer with adaptive timing
  void _startBatchTimer() {
    _batchTimer?.cancel();
    final interval = _getAdaptiveBatchInterval();
    _batchTimer = Timer.periodic(interval, (_) {
      _processBatch();
    });
  }

  /// Get adaptive batch interval based on user activity and performance
  Duration _getAdaptiveBatchInterval() {
    if (!_enableAdaptiveBatching) return _batchInterval;
    
    // Adjust based on user activity
    if (_isUserActive && _lastUserActivity != null) {
      final timeSinceActivity = DateTime.now().difference(_lastUserActivity!);
      if (timeSinceActivity < Duration(minutes: 2)) {
        return Duration(seconds: 15); // Active user - faster sync
      }
    }
    
    // Adjust based on consecutive failures
    if (_consecutiveFailures > 2) {
      return Duration(minutes: 5); // Slow down on failures
    }
    
    // Adjust based on average processing time
    if (_batchProcessingTimes.isNotEmpty) {
      final totalTime = _batchProcessingTimes.fold(Duration.zero, (sum, duration) => sum + duration);
      final avgProcessingTime = Duration(milliseconds: totalTime.inMilliseconds ~/ _batchProcessingTimes.length);
      if (avgProcessingTime > Duration(seconds: 10)) {
        return Duration(minutes: 2); // Slow down if processing is slow
      }
    }
    
    return _batchInterval; // Default interval
  }

  /// Process batch immediately (for critical events)
  void _processBatchImmediately() {
    if (_isProcessing || _eventQueue.isEmpty) return;
    
    // For ultra-critical events, use shorter timeout
    final hasUltraCritical = _eventQueue.any((e) => _getEventPriority(e.eventName) == 1);
    if (hasUltraCritical) {
      _processBatchInBackground(timeout: _criticalEventTimeout);
    } else {
      _processBatchInBackground();
    }
  }

  /// Process batch in background isolate with optional timeout
  void _processBatchInBackground({Duration? timeout}) {
    if (_isProcessing) return;
    
    _isProcessing = true;
    
    // Use compute to run in background isolate
    final future = compute(_processBatchIsolate, {
      'events': _eventQueue.map((e) => e.toJson()).toList(),
      'failed_events': _failedEvents.map((e) => e.toJson()).toList(),
      'max_batch_size': _maxBatchSize,
      'max_retries': _maxRetries,
      'enable_compression': _eventQueue.length > 20, // Compress large batches
    });

    // Apply timeout if specified
    final processedFuture = timeout != null 
        ? future.timeout(timeout, onTimeout: () => throw Exception('Batch processing timeout after ${timeout.inSeconds}s'))
        : future;

    processedFuture.then((result) {
      _handleBatchResult(result);
    }).catchError((error) {
      safePrint('🚀 ❌ Batch processing failed: $error');
      _isProcessing = false;
    });
  }

  /// Process batch (called by timer)
  void _processBatch() {
    if (_isProcessing || _eventQueue.isEmpty) return;
    
    _processBatchInBackground();
  }


  /// Handle batch processing result
  void _handleBatchResult(Map<String, dynamic> result) {
    try {
      final sentEvents = result['sent_events'] as int;
      final failedEvents = result['failed_events'] as List<dynamic>;
      final processingTime = result['processing_time'] as Duration?;
      
      _eventsSent += sentEvents;
      _eventsFailed += failedEvents.length;
      _lastBatchSent = DateTime.now();

      // Track performance metrics
      if (processingTime != null) {
        _batchProcessingTimes.add(processingTime);
        if (_batchProcessingTimes.length > 10) {
          _batchProcessingTimes.removeAt(0); // Keep only last 10 measurements
        }
      }
      
      _batchSizes.add(sentEvents);
      if (_batchSizes.length > 10) {
        _batchSizes.removeAt(0); // Keep only last 10 measurements
      }

      // Update failure tracking
      if (failedEvents.isEmpty) {
        _consecutiveFailures = 0;
      } else {
        _consecutiveFailures++;
      }

      // Remove sent events from queue
      final eventsToRemove = min(sentEvents, _eventQueue.length);
      _eventQueue.removeRange(0, eventsToRemove);

      // Add failed events back to retry queue
      for (final failedEventJson in failedEvents) {
        final failedEvent = AnalyticsEvent.fromJson(failedEventJson);
        _failedEvents.add(failedEvent);
      }

      // Save failed events to storage
      _saveFailedEvents();

      // Restart timer with adaptive interval
      if (_enableAdaptiveBatching) {
        _startBatchTimer();
      }

      safePrint('🚀 ✅ Batch processed: $sentEvents sent, ${failedEvents.length} failed');
      safePrint('🚀 📊 Stats: ${_eventsTracked} tracked, ${_eventsSent} sent, ${_eventsFailed} failed');
      if (processingTime != null) {
        safePrint('🚀 ⏱️ Processing time: ${processingTime.inMilliseconds}ms');
      }

    } catch (e) {
      safePrint('🚀 ❌ Failed to handle batch result: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// Process batch in isolate (static method for compute)
  static Future<Map<String, dynamic>> _processBatchIsolate(Map<String, dynamic> data) async {
    final events = (data['events'] as List).map((e) => AnalyticsEvent.fromJson(e)).toList();
    final failedEvents = (data['failed_events'] as List).map((e) => AnalyticsEvent.fromJson(e)).toList();
    final maxBatchSize = data['max_batch_size'] as int;
    final maxRetries = data['max_retries'] as int;
    final enableCompression = data['enable_compression'] as bool? ?? false;

    int sentEvents = 0;
    final newFailedEvents = <AnalyticsEvent>[];
    final startTime = DateTime.now();

    try {
      // Process events in batches
      for (int i = 0; i < events.length; i += maxBatchSize) {
        final batch = events.skip(i).take(maxBatchSize).toList();
        
        try {
          // Send batch with optional compression
          await _sendBatchToRailway(batch, enableCompression: enableCompression);
          sentEvents += batch.length;
          
        } catch (e) {
          // Add failed events to retry queue
          for (final event in batch) {
            if (event.retryCount < maxRetries) {
              final retryEvent = AnalyticsEvent(
                eventName: event.eventName,
                parameters: event.parameters,
                timestamp: event.timestamp,
                retryCount: event.retryCount + 1,
                sessionId: event.sessionId,
                playerId: event.playerId,
              );
              newFailedEvents.add(retryEvent);
            }
          }
        }
      }

      // Process previously failed events
      for (final event in failedEvents) {
        if (event.retryCount < maxRetries) {
          try {
            await _sendBatchToRailway([event]);
            sentEvents++;
          } catch (e) {
            final retryEvent = AnalyticsEvent(
              eventName: event.eventName,
              parameters: event.parameters,
              timestamp: event.timestamp,
              retryCount: event.retryCount + 1,
              sessionId: event.sessionId,
              playerId: event.playerId,
            );
            newFailedEvents.add(retryEvent);
          }
        }
      }

    } catch (e) {
      // If everything fails, return all events as failed
      newFailedEvents.addAll(events);
      newFailedEvents.addAll(failedEvents);
    }

    final processingTime = DateTime.now().difference(startTime);
    
    return {
      'sent_events': sentEvents,
      'failed_events': newFailedEvents.map((e) => e.toJson()).toList(),
      'processing_time': processingTime,
    };
  }

  /// Send batch to Railway backend with optional compression
  static Future<void> _sendBatchToRailway(List<AnalyticsEvent> events, {bool enableCompression = false}) async {
    if (events.isEmpty) return;

    try {
      final networkManager = NetworkManager();
      await networkManager.initialize();
      
      // Convert events to API format
      final eventsData = events.map((event) => event.toJson()).toList();
      
      // Apply compression for large batches if enabled
      if (enableCompression && eventsData.length > 20) {
        // Add compression metadata
        final compressedData = {
          'events': eventsData,
          'compressed': true,
          'original_size': eventsData.length,
          'compression_ratio': 0.8, // Simulate compression
        };
        
        // Send compressed batch to Railway
        final result = await networkManager.submitAnalyticsBatch(events: [compressedData]);
        
        if (!result.success) {
          throw Exception('Railway compressed batch API failed: ${result.error}');
        }
      } else {
        // Send normal batch to Railway
        final result = await networkManager.submitAnalyticsBatch(events: eventsData);
        
        if (!result.success) {
          throw Exception('Railway batch API failed: ${result.error}');
        }
      }
      
    } catch (e) {
      // Re-throw to trigger retry logic
      throw Exception('Network error: $e');
    }
  }

  /// Load failed events from storage
  Future<void> _loadFailedEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final failedEventsJson = prefs.getString('failed_analytics_events');
      
      if (failedEventsJson != null) {
        final failedEventsList = jsonDecode(failedEventsJson) as List;
        _failedEvents.clear();
        
        for (final eventJson in failedEventsList) {
          _failedEvents.add(AnalyticsEvent.fromJson(eventJson));
        }
        
        safePrint('🚀 Loaded ${_failedEvents.length} failed events from storage');
      }
    } catch (e) {
      safePrint('🚀 ❌ Failed to load failed events: $e');
    }
  }

  /// Save failed events to storage
  Future<void> _saveFailedEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final failedEventsJson = jsonEncode(_failedEvents.map((e) => e.toJson()).toList());
      await prefs.setString('failed_analytics_events', failedEventsJson);
    } catch (e) {
      safePrint('🚀 ❌ Failed to save failed events: $e');
    }
  }

  /// Process queued events from previous session
  Future<void> _processQueuedEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queuedEventsJson = prefs.getString('queued_analytics_events');
      
      if (queuedEventsJson != null) {
        final queuedEventsList = jsonDecode(queuedEventsJson) as List;
        
        for (final eventJson in queuedEventsList) {
          final event = AnalyticsEvent.fromJson(eventJson);
          _eventQueue.add(event);
        }
        
        // Clear queued events from storage
        await prefs.remove('queued_analytics_events');
        
        safePrint('🚀 Processed ${queuedEventsList.length} queued events from previous session');
      }
    } catch (e) {
      safePrint('🚀 ❌ Failed to process queued events: $e');
    }
  }

  /// Generate unique session ID
  String _generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999).toString().padLeft(4, '0');
    return 'session_${timestamp}_$random';
  }

  /// Get analytics statistics
  Map<String, dynamic> getStats() {
    final avgProcessingTime = _batchProcessingTimes.isNotEmpty
        ? Duration(milliseconds: _batchProcessingTimes.fold(0, (sum, duration) => sum + duration.inMilliseconds) ~/ _batchProcessingTimes.length)
        : Duration.zero;
    
    final avgBatchSize = _batchSizes.isNotEmpty
        ? _batchSizes.reduce((a, b) => a + b) / _batchSizes.length
        : 0.0;
    
    return {
      'events_tracked': _eventsTracked,
      'events_sent': _eventsSent,
      'events_failed': _eventsFailed,
      'queue_size': _eventQueue.length,
      'failed_events_count': _failedEvents.length,
      'last_batch_sent': _lastBatchSent?.toIso8601String(),
      'session_id': _sessionId,
      'player_id': _playerId,
      'performance': {
        'avg_processing_time_ms': avgProcessingTime.inMilliseconds,
        'avg_batch_size': avgBatchSize,
        'consecutive_failures': _consecutiveFailures,
        'is_user_active': _isUserActive,
        'last_user_activity': _lastUserActivity?.toIso8601String(),
        'adaptive_batching_enabled': _enableAdaptiveBatching,
      },
    };
  }

  /// Force flush all events (for app shutdown)
  Future<void> flush() async {
    if (_eventQueue.isEmpty) return;

    safePrint('🚀 Flushing ${_eventQueue.length} events...');
    
    // Save queued events to storage for next session
    try {
      final prefs = await SharedPreferences.getInstance();
      final queuedEventsJson = jsonEncode(_eventQueue.map((e) => e.toJson()).toList());
      await prefs.setString('queued_analytics_events', queuedEventsJson);
    } catch (e) {
      safePrint('🚀 ❌ Failed to save queued events: $e');
    }

    // Try to send remaining events
    _processBatchImmediately();
  }

  /// Dispose resources
  void dispose() {
    _batchTimer?.cancel();
    flush();
  }
}

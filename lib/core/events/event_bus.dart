/// 📤 EventBus - Central event management for hybrid architecture
/// 
/// Fire-and-forget event system that queues events locally
/// and sends them to backend asynchronously.
/// 
/// Features:
/// - Non-blocking event firing
/// - Automatic batching
/// - Persistent queue (survives app restart)
/// - Automatic retry on failure
/// - Network-aware (waits for connectivity)
library;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart'; // For AppLifecycleState
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import '../debug_logger.dart';
import 'event.dart';
import '../identity/device_identity_manager.dart';

/// EventBus - Central event management system
class EventBus {
  static final EventBus _instance = EventBus._internal();
  factory EventBus() => _instance;
  EventBus._internal();

  // Configuration
  static const String _backendUrl = 'https://flappyjet-backend-production.up.railway.app';
  static const int _maxQueueSize = 100; // Auto-flush at 100 events
  static const int _maxBatchSize = 50; // Send max 50 events per request
  static const Duration _autoFlushInterval = Duration(seconds: 15); // ✅ Reduced from 30s for better data capture
  static const Duration _requestTimeout = Duration(seconds: 5);

  // State
  final List<Event> _memoryQueue = [];
  Database? _db;
  Timer? _autoFlushTimer;
  bool _isInitialized = false;
  bool _isFlushing = false;
  bool _isEnabled = true;
  
  // Identity
  DeviceIdentityManager? _identityManager;

  /// Initialize the event bus
  /// 
  /// Must be called during app startup
  Future<void> initialize(DeviceIdentityManager identityManager) async {
    if (_isInitialized) return;

    try {
      safePrint('📤 Initializing EventBus...');
      
      _identityManager = identityManager;
      
      // Initialize persistent storage
      await _initializeDatabase();
      
      // Load unsent events from previous sessions
      await _loadUnsentEvents();
      
      // Start auto-flush timer
      _startAutoFlush();
      
      _isInitialized = true;
      
      safePrint('📤 ✅ EventBus initialized');
      safePrint('📤 Queue size: ${_memoryQueue.length} events');
      
    } catch (e, stackTrace) {
      safePrint('📤 ❌ Failed to initialize EventBus: $e');
      safePrint('Stack trace: $stackTrace');
      _isInitialized = true; // Continue anyway, events will queue in memory
    }
  }

  /// Fire an event (non-blocking, always succeeds)
  /// 
  /// Automatically injects required base fields:
  /// - app_version (from DeviceIdentityManager)
  /// - platform ('ios' or 'android')
  /// - country (from DeviceIdentityManager, only if detected)
  /// 
  /// Usage:
  /// ```dart
  /// EventBus().fire('game_ended', {
  ///   'score': 150,
  ///   'survival_time_seconds': 180,
  /// });
  /// ```
  void fire(String eventName, Map<String, dynamic> data) {
    if (!_isInitialized) {
      safePrint('📤 ⚠️ EventBus not initialized, skipping event: $eventName');
      return;
    }

    if (!_isEnabled) {
      safePrint('📤 ⚠️ EventBus disabled, skipping event: $eventName');
      return;
    }

    if (_identityManager == null) {
      safePrint('📤 ⚠️ Identity manager not set, skipping event: $eventName');
      return;
    }

    try {
      // Inject required base fields from DeviceIdentityManager
      final enrichedData = {
        ...data,
        'app_version': _identityManager!.appVersion,
        'platform': _identityManager!.platform,
      };

      // Include device locale if available (for language preference analytics)
      // Note: Geographic country is determined server-side via IP geolocation
      final deviceLocale = _identityManager!.locale;
      if (deviceLocale != null) {
        enrichedData['locale'] = deviceLocale;
      }

      final event = Event(
        name: eventName,
        data: enrichedData,
        userId: _identityManager!.userId,
        sessionId: _identityManager!.sessionId,
        timestamp: DateTime.now(),
      );

      _memoryQueue.add(event);

      if (kDebugMode) {
        safePrint('📤 Event fired: $eventName (queue: ${_memoryQueue.length})');
      }

      // Persist to database (non-blocking)
      unawaited(_persistEvent(event));

      // Auto-flush if queue is full
      if (_memoryQueue.length >= _maxQueueSize) {
        safePrint('📤 Queue full, triggering auto-flush');
        unawaited(flush());
      }

    } catch (e) {
      safePrint('📤 ❌ Failed to fire event $eventName: $e');
      // Silently fail - events should never break the app
    }
  }

  /// Flush events to backend (fire-and-forget)
  /// 
  /// Sends queued events to backend in batches
  /// Returns immediately, processes asynchronously
  Future<void> flush() async {
    if (_isFlushing) {
      safePrint('📤 Already flushing, skipping');
      return;
    }

    if (_memoryQueue.isEmpty) {
      return;
    }

    _isFlushing = true;

    try {
      safePrint('📤 Flushing ${_memoryQueue.length} events...');

      // Take events from queue (max batch size)
      final eventsToSend = _memoryQueue.take(_maxBatchSize).toList();
      
      // Send to backend
      final success = await _sendEvents(eventsToSend);

      if (success) {
        // Remove sent events from queue
        _memoryQueue.removeRange(0, eventsToSend.length);
        
        // Mark as sent in database
        await _markEventsSent(eventsToSend);
        
        safePrint('📤 ✅ Flushed ${eventsToSend.length} events');
        
        // If more events remain, flush again
        if (_memoryQueue.isNotEmpty) {
          safePrint('📤 More events in queue, flushing again...');
          unawaited(flush());
        }
      } else {
        safePrint('📤 ⚠️ Failed to send events, will retry later');
      }

    } catch (e) {
      safePrint('📤 ❌ Flush error: $e');
    } finally {
      _isFlushing = false;
    }
  }

  /// Send events to backend
  Future<bool> _sendEvents(List<Event> events) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/api/events'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(events.map((e) => e.toJson()).toList()),
      ).timeout(_requestTimeout);

      if (response.statusCode == 200) {
        safePrint('📤 ✅ Backend acknowledged ${events.length} events');
        return true;
      } else {
        safePrint('📤 ⚠️ Backend returned ${response.statusCode}');
        return false;
      }

    } catch (e) {
      safePrint('📤 ⚠️ Network error: $e');
      return false;
    }
  }

  /// Initialize SQLite database for persistent event storage
  Future<void> _initializeDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final dbFilePath = path.join(dbPath, 'events.db');

      _db = await openDatabase(
        dbFilePath,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE events (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              data TEXT NOT NULL,
              user_id TEXT NOT NULL,
              session_id TEXT NOT NULL,
              timestamp INTEGER NOT NULL,
              sent INTEGER DEFAULT 0,
              retry_count INTEGER DEFAULT 0,
              created_at INTEGER NOT NULL
            )
          ''');
          
          await db.execute('''
            CREATE INDEX idx_events_sent ON events(sent, created_at)
          ''');
        },
      );

      safePrint('📤 Database initialized');

    } catch (e) {
      safePrint('📤 ⚠️ Database initialization failed: $e');
    }
  }

  /// Load unsent events from previous sessions
  Future<void> _loadUnsentEvents() async {
    if (_db == null) return;

    try {
      final results = await _db!.query(
        'events',
        where: 'sent = ?',
        whereArgs: [0],
        orderBy: 'created_at ASC',
        limit: _maxQueueSize,
      );

      for (final row in results) {
        final event = Event(
          name: row['name'] as String,
          data: json.decode(row['data'] as String) as Map<String, dynamic>,
          userId: row['user_id'] as String,
          sessionId: row['session_id'] as String,
          timestamp: DateTime.fromMillisecondsSinceEpoch(row['timestamp'] as int),
        );
        
        _memoryQueue.add(event);
      }

      if (results.isNotEmpty) {
        safePrint('📤 Loaded ${results.length} unsent events from previous sessions');
      }

    } catch (e) {
      safePrint('📤 ⚠️ Failed to load unsent events: $e');
    }
  }

  /// Persist event to database
  Future<void> _persistEvent(Event event) async {
    if (_db == null) return;

    try {
      await _db!.insert('events', {
        'name': event.name,
        'data': json.encode(event.data),
        'user_id': event.userId,
        'session_id': event.sessionId,
        'timestamp': event.timestamp.millisecondsSinceEpoch,
        'sent': 0,
        'retry_count': 0,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });

    } catch (e) {
      safePrint('📤 ⚠️ Failed to persist event: $e');
    }
  }

  /// Mark events as sent in database
  Future<void> _markEventsSent(List<Event> events) async {
    if (_db == null) return;

    try {
      final batch = _db!.batch();
      
      for (final event in events) {
        batch.update(
          'events',
          {'sent': 1},
          where: 'user_id = ? AND name = ? AND timestamp = ?',
          whereArgs: [
            event.userId,
            event.name,
            event.timestamp.millisecondsSinceEpoch,
          ],
        );
      }

      await batch.commit(noResult: true);

      // Clean up old sent events (older than 7 days)
      await _cleanupOldEvents();

    } catch (e) {
      safePrint('📤 ⚠️ Failed to mark events as sent: $e');
    }
  }

  /// Clean up old sent events
  Future<void> _cleanupOldEvents() async {
    if (_db == null) return;

    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      
      await _db!.delete(
        'events',
        where: 'sent = ? AND created_at < ?',
        whereArgs: [1, sevenDaysAgo.millisecondsSinceEpoch],
      );

    } catch (e) {
      safePrint('📤 ⚠️ Failed to cleanup old events: $e');
    }
  }

  /// Start auto-flush timer
  void _startAutoFlush() {
    _autoFlushTimer?.cancel();
    
    _autoFlushTimer = Timer.periodic(_autoFlushInterval, (timer) {
      if (_memoryQueue.isNotEmpty) {
        safePrint('📤 Auto-flush triggered (${_memoryQueue.length} events)');
        unawaited(flush());
      }
    });

    safePrint('📤 Auto-flush timer started (every ${_autoFlushInterval.inSeconds}s)');
  }

  /// Enable/disable event firing
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    safePrint('📤 EventBus ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Get current queue size
  int get queueSize => _memoryQueue.length;

  /// Check if initialized
  bool get isInitialized => _isInitialized;

  /// 🔥 NEW: Handle app lifecycle changes
  /// 
  /// Call this from your app's lifecycle observer when app goes to background.
  /// Ensures events are flushed before app is suspended/terminated.
  /// 
  /// This is CRITICAL for capturing events from users who:
  /// - Open app briefly then close
  /// - Switch to another app
  /// - Lock their phone
  /// 
  /// Without this, events would be lost if app closes before auto-flush timer.
  void onAppLifecycleChanged(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || 
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      // App going to background - flush events immediately!
      if (_memoryQueue.isNotEmpty) {
        safePrint('📤 🔥 App going to background - flushing ${_memoryQueue.length} events immediately!');
        unawaited(flush());
      }
    }
  }

  /// Dispose resources
  void dispose() {
    _autoFlushTimer?.cancel();
    _db?.close();
    _memoryQueue.clear();
    safePrint('📤 EventBus disposed');
  }
}


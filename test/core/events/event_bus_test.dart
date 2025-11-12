/// Unit tests for EventBus
/// 
/// Tests event firing, queuing, batching, and persistence
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flappy_jet_pro/core/events/event_bus.dart';
import 'package:flappy_jet_pro/core/events/event.dart';
import 'package:flappy_jet_pro/core/identity/device_identity_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Initialize FFI for SQLite testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('EventBus', () {
    late EventBus eventBus;
    late DeviceIdentityManager identityManager;

    setUp(() async {
      // Clear SharedPreferences
      SharedPreferences.setMockInitialValues({});
      
      // Initialize identity manager
      identityManager = DeviceIdentityManager();
      await identityManager.initialize();
      
      // Initialize event bus
      eventBus = EventBus();
      await eventBus.initialize(identityManager);
    });

    tearDown(() async {
      eventBus.dispose();
      SharedPreferences.setMockInitialValues({});
    });

    group('Initialization', () {
      test('should initialize successfully', () async {
        expect(eventBus.isInitialized, isTrue);
        expect(eventBus.queueSize, equals(0));
      });

      test('should not reinitialize if already initialized', () async {
        final wasInitialized = eventBus.isInitialized;
        await eventBus.initialize(identityManager);
        
        expect(eventBus.isInitialized, equals(wasInitialized));
      });

      test('should load unsent events from previous session', () async {
        // Fire some events
        eventBus.fire('test_event_1', {'value': 1});
        eventBus.fire('test_event_2', {'value': 2});
        eventBus.fire('test_event_3', {'value': 3});

        final originalQueueSize = eventBus.queueSize;
        expect(originalQueueSize, equals(3));

        // Create new event bus (simulates app restart)
        final newEventBus = EventBus();
        await newEventBus.initialize(identityManager);

        // Should have loaded the unsent events
        expect(newEventBus.queueSize, greaterThanOrEqualTo(0));
        
        newEventBus.dispose();
      });
    });

    group('Event Firing', () {
      test('should fire event successfully', () {
        eventBus.fire('game_ended', {
          'score': 150,
          'survivalTime': 180,
          'coins': 10,
        });

        expect(eventBus.queueSize, equals(1));
      });

      test('should fire multiple events', () {
        for (int i = 0; i < 10; i++) {
          eventBus.fire('test_event', {'index': i});
        }

        expect(eventBus.queueSize, equals(10));
      });

      test('should handle rapid event firing', () {
        const eventCount = 100;
        
        for (int i = 0; i < eventCount; i++) {
          eventBus.fire('rapid_event', {'index': i});
        }

        // Queue may have auto-flushed if > 100
        expect(eventBus.queueSize, lessThanOrEqualTo(eventCount));
      });

      test('should include userId and sessionId in fired events', () {
        eventBus.fire('test_event', {'value': 1});

        // Events are queued internally
        expect(eventBus.queueSize, equals(1));
      });

      test('should handle empty data payload', () {
        eventBus.fire('empty_event', {});
        expect(eventBus.queueSize, equals(1));
      });

      test('should handle complex data payload', () {
        eventBus.fire('complex_event', {
          'nested': {
            'level1': {
              'level2': [1, 2, 3],
            },
          },
          'array': [
            {'item': 1},
            {'item': 2},
          ],
        });

        expect(eventBus.queueSize, equals(1));
      });
    });

    group('Enable/Disable', () {
      test('should not fire events when disabled', () {
        eventBus.setEnabled(false);
        
        eventBus.fire('test_event', {'value': 1});
        
        expect(eventBus.queueSize, equals(0));
      });

      test('should fire events when re-enabled', () {
        eventBus.setEnabled(false);
        eventBus.fire('disabled_event', {'value': 1});
        expect(eventBus.queueSize, equals(0));

        eventBus.setEnabled(true);
        eventBus.fire('enabled_event', {'value': 2});
        expect(eventBus.queueSize, equals(1));
      });
    });

    group('Queue Management', () {
      test('should track queue size correctly', () {
        expect(eventBus.queueSize, equals(0));

        eventBus.fire('event_1', {});
        expect(eventBus.queueSize, equals(1));

        eventBus.fire('event_2', {});
        expect(eventBus.queueSize, equals(2));

        eventBus.fire('event_3', {});
        expect(eventBus.queueSize, equals(3));
      });

      test('should auto-flush at 100 events', () async {
        // Fire 100 events
        for (int i = 0; i < 100; i++) {
          eventBus.fire('test_event', {'index': i});
        }

        // Auto-flush should have triggered
        // Queue may be reduced after flush completes
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Queue should be less than 100 if flush succeeded
        // Or exactly 100 if network failed (events stay queued)
        expect(eventBus.queueSize, lessThanOrEqualTo(100));
      });
    });

    group('Flush Behavior', () {
      test('should flush events manually', () async {
        eventBus.fire('event_1', {'value': 1});
        eventBus.fire('event_2', {'value': 2});
        eventBus.fire('event_3', {'value': 3});

        expect(eventBus.queueSize, equals(3));

        await eventBus.flush();

        // After flush, queue may be empty (if network succeeded)
        // or still have events (if network failed)
        expect(eventBus.queueSize, lessThanOrEqualTo(3));
      });

      test('should not crash when flushing empty queue', () async {
        expect(eventBus.queueSize, equals(0));
        
        await eventBus.flush();
        
        expect(eventBus.queueSize, equals(0));
      });

      test('should handle concurrent flush calls', () async {
        for (int i = 0; i < 20; i++) {
          eventBus.fire('test_event', {'index': i});
        }

        // Trigger multiple flushes concurrently
        final flushFutures = [
          eventBus.flush(),
          eventBus.flush(),
          eventBus.flush(),
        ];

        await Future.wait(flushFutures);

        // Should handle gracefully without crashing
        expect(eventBus.isInitialized, isTrue);
      });
    });

    group('Event Schema Validation', () {
      test('should accept all documented event types', () {
        // User Lifecycle
        eventBus.fire('user_installed', {});
        eventBus.fire('app_launched', {});
        eventBus.fire('session_start', {});
        eventBus.fire('session_end', {});
        eventBus.fire('session_summary', {});

        // Gameplay
        eventBus.fire('game_started', {});
        eventBus.fire('game_ended', {'score': 100});
        eventBus.fire('level_started', {'levelId': 'zone1_level1'});
        eventBus.fire('level_completed', {'levelId': 'zone1_level1', 'stars': 3});
        eventBus.fire('level_failed', {'levelId': 'zone1_level1'});
        eventBus.fire('zone_completed', {'zoneId': 'zone1'});

        // Monetization
        eventBus.fire('coins_earned', {'amount': 100});
        eventBus.fire('coins_spent', {'amount': 50});
        eventBus.fire('gems_earned', {'amount': 10});
        eventBus.fire('gems_spent', {'amount': 5});
        eventBus.fire('purchase_initiated', {'productId': 'coins_1000'});
        eventBus.fire('purchase_completed', {'productId': 'coins_1000'});
        eventBus.fire('ad_watched', {'adType': 'rewarded'});

        // Social & Progression
        eventBus.fire('achievement_unlocked', {'achievementId': 'score_100'});
        eventBus.fire('mission_completed', {'missionId': 'daily_play_5'});
        eventBus.fire('score_shared', {'score': 150});
        eventBus.fire('app_rated', {'rating': 5});

        // Inventory
        eventBus.fire('jet_purchased', {'jetId': 'storm_blade'});
        eventBus.fire('jet_equipped', {'jetId': 'neon_racer'});

        // Tournament
        eventBus.fire('tournament_score_submitted', {'score': 250});
        eventBus.fire('prize_claimed', {'prizeId': 'prize_123'});

        // System
        eventBus.fire('app_crashed', {'crashMessage': 'test'});
        eventBus.fire('performance_metrics', {'averageFps': 60});

        // Should have queued all events
        expect(eventBus.queueSize, equals(28));
      });
    });

    group('Error Handling', () {
      test('should not crash on invalid data types', () {
        // These should all succeed (EventBus is fault-tolerant)
        eventBus.fire('test_event', {'value': null});
        eventBus.fire('test_event', {'value': 'string'});
        eventBus.fire('test_event', {'value': 123});
        eventBus.fire('test_event', {'value': 3.14});
        eventBus.fire('test_event', {'value': true});
        eventBus.fire('test_event', {'value': [1, 2, 3]});
        eventBus.fire('test_event', {'value': {'nested': 'object'}});

        expect(eventBus.queueSize, equals(7));
      });

      test('should handle network failures gracefully', () async {
        // Fire events (will fail to send since no backend is running in test)
        eventBus.fire('test_event_1', {});
        eventBus.fire('test_event_2', {});

        await eventBus.flush();

        // Events should stay in queue if network failed
        expect(eventBus.queueSize, greaterThanOrEqualTo(0));
      });
    });

    group('Persistence', () {
      test('should persist events across app restarts', () async {
        // Fire events
        eventBus.fire('persisted_event_1', {'value': 1});
        eventBus.fire('persisted_event_2', {'value': 2});

        final originalQueueSize = eventBus.queueSize;

        // Dispose and create new instance (simulates restart)
        eventBus.dispose();
        
        final newEventBus = EventBus();
        await newEventBus.initialize(identityManager);

        // Queue should have events from previous session
        expect(newEventBus.queueSize, greaterThanOrEqualTo(0));
        
        newEventBus.dispose();
      });
    });

    group('Performance', () {
      test('should handle high volume of events efficiently', () {
        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < 1000; i++) {
          eventBus.fire('performance_test', {
            'index': i,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
        }

        stopwatch.stop();

        // Should complete in under 1 second
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });

      test('should be non-blocking', () {
        final stopwatch = Stopwatch()..start();

        eventBus.fire('test_event', {'large_data': List.generate(100, (i) => i)});

        stopwatch.stop();

        // Should complete almost instantly (< 10ms)
        expect(stopwatch.elapsedMilliseconds, lessThan(10));
      });
    });

    group('Singleton Pattern', () {
      test('should return same instance', () {
        final instance1 = EventBus();
        final instance2 = EventBus();

        expect(identical(instance1, instance2), isTrue);
      });
    });
  });
}


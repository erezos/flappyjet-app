/// Unit tests for Event class
/// 
/// Tests event creation, serialization, and equality
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/core/events/event.dart';

void main() {
  group('Event', () {
    final testTimestamp = DateTime.parse('2025-11-08T12:34:56.789Z');
    
    group('Creation', () {
      test('should create event with all required fields', () {
        final event = Event(
          name: 'game_ended',
          data: {'score': 150, 'coins': 10},
          userId: 'user_test123_1699459200',
          sessionId: 'session_uuid-123',
          timestamp: testTimestamp,
        );

        expect(event.name, equals('game_ended'));
        expect(event.data, equals({'score': 150, 'coins': 10}));
        expect(event.userId, equals('user_test123_1699459200'));
        expect(event.sessionId, equals('session_uuid-123'));
        expect(event.timestamp, equals(testTimestamp));
      });

      test('should be immutable', () {
        final event = Event(
          name: 'test_event',
          data: {'value': 1},
          userId: 'user_123',
          sessionId: 'session_456',
          timestamp: testTimestamp,
        );

        // Event should be const-able (immutable)
        expect(event, isA<Event>());
        expect(event.name, equals('test_event'));
      });
    });

    group('JSON Serialization', () {
      test('should serialize to JSON correctly', () {
        final event = Event(
          name: 'game_ended',
          data: {'score': 150, 'survivalTime': 180},
          userId: 'user_test123_1699459200',
          sessionId: 'session_uuid-123',
          timestamp: testTimestamp,
        );

        final json = event.toJson();

        expect(json, isA<Map<String, dynamic>>());
        expect(json['name'], equals('game_ended'));
        expect(json['data'], equals({'score': 150, 'survivalTime': 180}));
        expect(json['userId'], equals('user_test123_1699459200'));
        expect(json['sessionId'], equals('session_uuid-123'));
        expect(json['timestamp'], equals('2025-11-08T12:34:56.789Z'));
      });

      test('should deserialize from JSON correctly', () {
        final json = {
          'name': 'game_ended',
          'data': {'score': 150, 'coins': 10},
          'userId': 'user_test123_1699459200',
          'sessionId': 'session_uuid-123',
          'timestamp': '2025-11-08T12:34:56.789Z',
        };

        final event = Event.fromJson(json);

        expect(event.name, equals('game_ended'));
        expect(event.data, equals({'score': 150, 'coins': 10}));
        expect(event.userId, equals('user_test123_1699459200'));
        expect(event.sessionId, equals('session_uuid-123'));
        expect(event.timestamp, equals(testTimestamp));
      });

      test('should handle round-trip serialization', () {
        final originalEvent = Event(
          name: 'level_completed',
          data: {'levelId': 'zone1_level5', 'stars': 3, 'score': 200},
          userId: 'user_device123_1699459200',
          sessionId: 'session_abc-def',
          timestamp: testTimestamp,
        );

        final json = originalEvent.toJson();
        final deserializedEvent = Event.fromJson(json);

        expect(deserializedEvent.name, equals(originalEvent.name));
        expect(deserializedEvent.data, equals(originalEvent.data));
        expect(deserializedEvent.userId, equals(originalEvent.userId));
        expect(deserializedEvent.sessionId, equals(originalEvent.sessionId));
        expect(deserializedEvent.timestamp, equals(originalEvent.timestamp));
      });

      test('should handle complex nested data', () {
        final event = Event(
          name: 'session_summary',
          data: {
            'sessionDuration': 300,
            'currentStats': {
              'highScore': 180,
              'coins': 5150,
              'storyProgress': {
                'zone1': {'completed': 10, 'stars': 28},
                'zone2': {'completed': 8, 'stars': 22},
              },
            },
          },
          userId: 'user_123',
          sessionId: 'session_456',
          timestamp: testTimestamp,
        );

        final json = event.toJson();
        final deserializedEvent = Event.fromJson(json);

        expect(deserializedEvent.data, equals(event.data));
        expect(
          deserializedEvent.data['currentStats']['storyProgress']['zone1']['stars'],
          equals(28),
        );
      });

      test('should handle empty data', () {
        final event = Event(
          name: 'app_launched',
          data: {},
          userId: 'user_123',
          sessionId: 'session_456',
          timestamp: testTimestamp,
        );

        final json = event.toJson();
        final deserializedEvent = Event.fromJson(json);

        expect(deserializedEvent.data, isEmpty);
      });
    });

    group('Equality', () {
      test('should be equal if all fields match', () {
        final event1 = Event(
          name: 'test_event',
          data: {'value': 1},
          userId: 'user_123',
          sessionId: 'session_456',
          timestamp: testTimestamp,
        );

        final event2 = Event(
          name: 'test_event',
          data: {'value': 1},
          userId: 'user_123',
          sessionId: 'session_456',
          timestamp: testTimestamp,
        );

        expect(event1, equals(event2));
        expect(event1.hashCode, equals(event2.hashCode));
      });

      test('should not be equal if name differs', () {
        final event1 = Event(
          name: 'event_a',
          data: {},
          userId: 'user_123',
          sessionId: 'session_456',
          timestamp: testTimestamp,
        );

        final event2 = Event(
          name: 'event_b',
          data: {},
          userId: 'user_123',
          sessionId: 'session_456',
          timestamp: testTimestamp,
        );

        expect(event1, isNot(equals(event2)));
      });

      test('should not be equal if userId differs', () {
        final event1 = Event(
          name: 'test_event',
          data: {},
          userId: 'user_123',
          sessionId: 'session_456',
          timestamp: testTimestamp,
        );

        final event2 = Event(
          name: 'test_event',
          data: {},
          userId: 'user_789',
          sessionId: 'session_456',
          timestamp: testTimestamp,
        );

        expect(event1, isNot(equals(event2)));
      });

      test('should not be equal if timestamp differs', () {
        final event1 = Event(
          name: 'test_event',
          data: {},
          userId: 'user_123',
          sessionId: 'session_456',
          timestamp: testTimestamp,
        );

        final event2 = Event(
          name: 'test_event',
          data: {},
          userId: 'user_123',
          sessionId: 'session_456',
          timestamp: testTimestamp.add(const Duration(seconds: 1)),
        );

        expect(event1, isNot(equals(event2)));
      });
    });

    group('CopyWith', () {
      test('should create copy with updated fields', () {
        final originalEvent = Event(
          name: 'original',
          data: {'value': 1},
          userId: 'user_123',
          sessionId: 'session_456',
          timestamp: testTimestamp,
        );

        final copiedEvent = originalEvent.copyWith(
          name: 'modified',
          data: {'value': 2},
        );

        expect(copiedEvent.name, equals('modified'));
        expect(copiedEvent.data, equals({'value': 2}));
        expect(copiedEvent.userId, equals('user_123')); // Unchanged
        expect(copiedEvent.sessionId, equals('session_456')); // Unchanged
        expect(copiedEvent.timestamp, equals(testTimestamp)); // Unchanged
      });

      test('should preserve original when no changes', () {
        final originalEvent = Event(
          name: 'test',
          data: {'value': 1},
          userId: 'user_123',
          sessionId: 'session_456',
          timestamp: testTimestamp,
        );

        final copiedEvent = originalEvent.copyWith();

        expect(copiedEvent.name, equals(originalEvent.name));
        expect(copiedEvent.data, equals(originalEvent.data));
        expect(copiedEvent.userId, equals(originalEvent.userId));
        expect(copiedEvent.sessionId, equals(originalEvent.sessionId));
        expect(copiedEvent.timestamp, equals(originalEvent.timestamp));
      });
    });

    group('String Representation', () {
      test('should provide meaningful string representation', () {
        final event = Event(
          name: 'game_ended',
          data: {'score': 150},
          userId: 'user_test123_1699459200',
          sessionId: 'session_uuid-123',
          timestamp: testTimestamp,
        );

        final str = event.toString();

        expect(str, contains('game_ended'));
        expect(str, contains('user_test1')); // Truncated userId (10 chars)
        expect(str, contains('session_uu')); // Truncated sessionId (10 chars)
        expect(str, contains('2025-11-08'));
      });
    });

    group('Data Validation', () {
      test('should handle various data types in payload', () {
        final event = Event(
          name: 'mixed_data',
          data: {
            'string': 'hello',
            'int': 42,
            'double': 3.14,
            'bool': true,
            'null': null,
            'list': [1, 2, 3],
            'map': {'nested': 'value'},
          },
          userId: 'user_123',
          sessionId: 'session_456',
          timestamp: testTimestamp,
        );

        final json = event.toJson();
        final deserializedEvent = Event.fromJson(json);

        expect(deserializedEvent.data['string'], equals('hello'));
        expect(deserializedEvent.data['int'], equals(42));
        expect(deserializedEvent.data['double'], equals(3.14));
        expect(deserializedEvent.data['bool'], equals(true));
        expect(deserializedEvent.data['null'], isNull);
        expect(deserializedEvent.data['list'], equals([1, 2, 3]));
        expect(deserializedEvent.data['map'], equals({'nested': 'value'}));
      });
    });
  });
}


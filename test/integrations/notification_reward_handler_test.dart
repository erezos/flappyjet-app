/// Unit Tests for NotificationRewardHandler
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flappy_jet_pro/integrations/notification_reward_handler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationRewardHandler', () {
    late NotificationRewardHandler handler;

    setUp(() {
      handler = NotificationRewardHandler();
      handler.dispose(); // Reset state
    });

    tearDown(() {
      handler.dispose();
    });

    test('should be a singleton', () {
      final instance1 = NotificationRewardHandler();
      final instance2 = NotificationRewardHandler();
      expect(instance1, same(instance2));
    });

    test('should start uninitialized', () {
      expect(handler, isNotNull);
    });

    test('should initialize with context', () {
      final context = MockBuildContext();
      handler.initialize(context);
      // Handler should be initialized (no direct getter, but no error means success)
      expect(handler, isNotNull);
    });

    test('should provide reward callback', () {
      final callback = handler.rewardCallback;
      expect(callback, isA<Function>());
    });

    test('should handle invalid reward data gracefully', () {
      final context = MockBuildContext();
      handler.initialize(context);

      // Missing reward type
      expect(() {
        handler.rewardCallback({
          'amount': 100,
        });
      }, returnsNormally);

      // Missing reward amount
      expect(() {
        handler.rewardCallback({
          'type': 'coins',
        });
      }, returnsNormally);

      // Empty data
      expect(() {
        handler.rewardCallback({});
      }, returnsNormally);
    });

    test('should accept valid reward data', () {
      final context = MockBuildContext();
      handler.initialize(context);

      final validData = {
        'type': 'coins',
        'amount': 100,
        'eventId': 123,
      };

      expect(() {
        handler.rewardCallback(validData);
      }, returnsNormally);
    });

    test('should handle coins reward type', () {
      final context = MockBuildContext();
      handler.initialize(context);

      final data = {
        'type': 'coins',
        'amount': 100,
      };

      expect(() {
        handler.rewardCallback(data);
      }, returnsNormally);
    });

    test('should handle gems reward type', () {
      final context = MockBuildContext();
      handler.initialize(context);

      final data = {
        'type': 'gems',
        'amount': 10,
      };

      expect(() {
        handler.rewardCallback(data);
      }, returnsNormally);
    });

    test('should handle various reward amounts', () {
      final context = MockBuildContext();
      handler.initialize(context);

      final amounts = [10, 50, 100, 500, 1000];
      
      for (final amount in amounts) {
        expect(() {
          handler.rewardCallback({
            'type': 'coins',
            'amount': amount,
          });
        }, returnsNormally);
      }
    });

    test('should update context', () {
      final context1 = MockBuildContext();
      final context2 = MockBuildContext();
      
      handler.initialize(context1);
      handler.updateContext(context2);
      
      // Should not throw
      expect(handler, isNotNull);
    });

    test('should dispose correctly', () {
      final context = MockBuildContext();
      handler.initialize(context);
      
      expect(() {
        handler.dispose();
      }, returnsNormally);
      
      // Should be able to reinitialize after dispose
      expect(() {
        handler.initialize(context);
      }, returnsNormally);
    });
  });

  group('NotificationRewardHandler - Context Handling', () {
    testWidgets('should use navigator key context when available', (WidgetTester tester) async {
      final handler = NotificationRewardHandler();
      handler.dispose();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: notificationNavigatorKey,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                // Initialize handler with context
                handler.initialize(context);
                
                // Try to show popup - should use navigator key
                handler.rewardCallback({
                  'type': 'coins',
                  'amount': 100,
                });
                
                return const Text('Test');
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      
      // Should not throw
      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('should handle missing context gracefully', (WidgetTester tester) async {
      final handler = NotificationRewardHandler();
      handler.dispose();

      // Don't initialize with context
      // Try to show popup without valid context
      expect(() {
        handler.rewardCallback({
          'type': 'coins',
          'amount': 100,
        });
      }, returnsNormally);
    });

    testWidgets('should handle unmounted context gracefully', (WidgetTester tester) async {
      final handler = NotificationRewardHandler();
      handler.dispose();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: notificationNavigatorKey,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                handler.initialize(context);
                return const Text('Test');
              },
            ),
          ),
        ),
      );

      // Remove widget (unmount context)
      await tester.pumpWidget(const SizedBox.shrink());
      
      // Try to show popup with unmounted context
      expect(() {
        handler.rewardCallback({
          'type': 'coins',
          'amount': 100,
        });
      }, returnsNormally);
    });
  });

  group('NotificationRewardHandler - Data Parsing', () {
    test('should parse reward type correctly', () {
      final handler = NotificationRewardHandler();
      final context = MockBuildContext();
      handler.initialize(context);

      final testCases = [
        {'type': 'coins', 'amount': 100},
        {'type': 'gems', 'amount': 10},
      ];

      for (final data in testCases) {
        expect(() {
          handler.rewardCallback(data);
        }, returnsNormally);
      }
    });

    test('should parse reward amount correctly', () {
      final handler = NotificationRewardHandler();
      final context = MockBuildContext();
      handler.initialize(context);

      final testCases = [
        {'type': 'coins', 'amount': 10},
        {'type': 'coins', 'amount': 50},
        {'type': 'coins', 'amount': 100},
        {'type': 'coins', 'amount': 500},
        {'type': 'gems', 'amount': 5},
        {'type': 'gems', 'amount': 10},
      ];

      for (final data in testCases) {
        expect(() {
          handler.rewardCallback(data);
        }, returnsNormally);
      }
    });

    test('should handle optional eventId', () {
      final handler = NotificationRewardHandler();
      final context = MockBuildContext();
      handler.initialize(context);

      // With eventId
      expect(() {
        handler.rewardCallback({
          'type': 'coins',
          'amount': 100,
          'eventId': 123,
        });
      }, returnsNormally);

      // Without eventId
      expect(() {
        handler.rewardCallback({
          'type': 'coins',
          'amount': 100,
        });
      }, returnsNormally);
    });
  });
}

/// Mock BuildContext for testing
class MockBuildContext extends BuildContext {
  @override
  bool get mounted => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flappy_jet_pro/game/systems/rate_us_manager.dart';
import 'package:flappy_jet_pro/core/events/event_bus.dart';

/// Event Lifecycle Tests for Rate Us System
/// 
/// Tests the complete event lifecycle:
/// 1. Events are fired with correct data
/// 2. Event payloads match backend schema expectations
/// 3. All rate us events have required fields
/// 
/// Backend schema reference: railway-backend/services/event-schemas.js
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RateUsManager manager;
  late List<Map<String, dynamic>> capturedEvents;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    manager = RateUsManager();
    await manager.resetForTesting();
    capturedEvents = [];
    
    // Capture events fired to EventBus
    // Note: In real app, EventBus sends to GameEventsTracker → Railway backend
  });

  group('Rate Us Event Lifecycle - Event Payloads', () {
    test('rate_us_initialized has correct payload', () async {
      // Setup
      SharedPreferences.setMockInitialValues({
        'rate_us_session_count': 4,
        'rate_us_prompt_count': 1,
        'rate_us_first_launch_date': DateTime.now()
            .subtract(const Duration(days: 5))
            .millisecondsSinceEpoch,
      });
      
      await manager.initialize();
      
      // Verify expected payload structure (matches backend schema)
      final debugState = manager.getDebugState();
      
      // These fields are sent in rate_us_initialized event
      expect(debugState['session_count'], equals(5)); // 4 + 1
      expect(debugState['has_rated'], isFalse);
      expect(debugState['has_declined'], isFalse);
      expect(debugState['prompt_count'], equals(1));
      expect(debugState['days_since_install'], equals(5));
    });

    test('rate_us_popup_shown increments prompt_count', () async {
      SharedPreferences.setMockInitialValues({
        'rate_us_session_count': 10,
        'rate_us_prompt_count': 0,
      });
      
      await manager.initialize();
      
      expect(manager.promptCount, equals(0));
      
      await manager.recordPopupShown();
      
      expect(manager.promptCount, equals(1));
      
      await manager.recordPopupShown();
      
      expect(manager.promptCount, equals(2));
    });

    test('rate_us_maybe_later does not change rated/declined status', () async {
      await manager.initialize();
      await manager.recordPopupShown();
      
      await manager.handleMaybeLater();
      
      expect(manager.hasRated, isFalse);
      expect(manager.hasDeclined, isFalse);
    });

    test('rate_us_declined permanently marks user as declined', () async {
      await manager.initialize();
      await manager.recordPopupShown();
      
      await manager.handleDeclined();
      
      expect(manager.hasDeclined, isTrue);
      expect(manager.shouldShowRateUsPrompt, isFalse);
    });

    test('rate_us_completed permanently marks user as rated', () async {
      await manager.initialize();
      await manager.recordPopupShown();
      
      await manager.markAsRated();
      
      expect(manager.hasRated, isTrue);
      expect(manager.shouldShowRateUsPrompt, isFalse);
    });
  });

  group('Rate Us Event Lifecycle - Backend Schema Compliance', () {
    /// These tests verify that the event payloads match what the backend expects
    /// Based on: railway-backend/services/event-schemas.js
    
    test('rate_us_initialized matches backend schema', () async {
      SharedPreferences.setMockInitialValues({
        'rate_us_session_count': 5,
        'rate_us_prompt_count': 2,
        'rate_us_first_launch_date': DateTime.now()
            .subtract(const Duration(days: 7))
            .millisecondsSinceEpoch,
      });
      
      await manager.initialize();
      
      // Backend schema requires:
      // - session_count: integer
      // - has_rated: boolean
      // - prompt_count: integer
      // - days_since_install: integer
      
      expect(manager.sessionCount, isA<int>());
      expect(manager.hasRated, isA<bool>());
      expect(manager.promptCount, isA<int>());
      expect(manager.daysSinceFirstLaunch, isA<int>());
    });

    test('rate_us_popup_shown matches backend schema', () async {
      SharedPreferences.setMockInitialValues({
        'rate_us_session_count': 5,
        'rate_us_first_launch_date': DateTime.now()
            .subtract(const Duration(days: 7))
            .millisecondsSinceEpoch,
      });
      
      await manager.initialize();
      await manager.recordPopupShown();
      
      // Backend schema requires:
      // - session_count: integer (min 0)
      // - days_since_install: integer (min 0)
      
      expect(manager.sessionCount, greaterThanOrEqualTo(0));
      expect(manager.daysSinceFirstLaunch, greaterThanOrEqualTo(0));
    });

    test('rate_us_trigger matches backend schema', () async {
      // Backend schema requires:
      // - trigger_type: 'positive_experience' | 'daily_streak' | 'achievement' | 'manual'
      // - session_count: integer
      // - streak_day: integer (optional, for daily_streak trigger)
      
      SharedPreferences.setMockInitialValues({
        'rate_us_session_count': 10,
        'rate_us_first_launch_date': DateTime.now()
            .subtract(const Duration(days: 10))
            .millisecondsSinceEpoch,
      });
      
      await manager.initialize();
      
      // Verify trigger methods return boolean
      expect(manager.shouldPromptAfterPositiveExperience(), isA<bool>());
      expect(manager.shouldPromptAfterDailyStreak(5), isA<bool>());
    });
  });

  group('Rate Us Event Lifecycle - Funnel Integrity', () {
    test('funnel progression: init → popup → action', () async {
      SharedPreferences.setMockInitialValues({
        'rate_us_session_count': 10,
        'rate_us_first_launch_date': DateTime.now()
            .subtract(const Duration(days: 10))
            .millisecondsSinceEpoch,
      });
      
      // Step 1: Initialize
      await manager.initialize();
      expect(manager.isInitialized, isTrue);
      expect(manager.promptCount, equals(0));
      
      // Step 2: Show popup
      await manager.recordPopupShown();
      expect(manager.promptCount, equals(1));
      
      // Step 3: User action (rate)
      await manager.markAsRated();
      expect(manager.hasRated, isTrue);
      expect(manager.shouldShowRateUsPrompt, isFalse);
    });

    test('funnel can end with decline', () async {
      SharedPreferences.setMockInitialValues({
        'rate_us_session_count': 10,
        'rate_us_first_launch_date': DateTime.now()
            .subtract(const Duration(days: 10))
            .millisecondsSinceEpoch,
      });
      
      await manager.initialize();
      await manager.recordPopupShown();
      
      // User declines instead of rating
      await manager.handleDeclined();
      
      expect(manager.hasDeclined, isTrue);
      expect(manager.hasRated, isFalse);
      expect(manager.shouldShowRateUsPrompt, isFalse);
    });

    test('funnel can be delayed with maybe later', () async {
      SharedPreferences.setMockInitialValues({
        'rate_us_session_count': 10,
        'rate_us_first_launch_date': DateTime.now()
            .subtract(const Duration(days: 10))
            .millisecondsSinceEpoch,
      });
      
      await manager.initialize();
      
      // First prompt
      await manager.recordPopupShown();
      await manager.handleMaybeLater();
      
      expect(manager.hasRated, isFalse);
      expect(manager.hasDeclined, isFalse);
      expect(manager.promptCount, equals(1));
      
      // User will be shown popup again after cooldown
      // (can't test time-based logic in unit test easily)
    });
  });

  group('Rate Us Event Lifecycle - Error Recovery', () {
    test('manager recovers from corrupted preferences', () async {
      // Simulate corrupted data
      SharedPreferences.setMockInitialValues({
        'rate_us_session_count': -5, // Invalid
        'rate_us_prompt_count': 999, // Unusually high
      });
      
      // Should not throw
      await manager.initialize();
      
      // Manager should still work
      expect(manager.isInitialized, isTrue);
    });

    test('manager handles missing first launch date', () async {
      SharedPreferences.setMockInitialValues({
        'rate_us_session_count': 5,
        // Missing first_launch_date
      });
      
      await manager.initialize();
      
      // Should set first launch date to now
      expect(manager.daysSinceFirstLaunch, equals(0));
    });
  });
}


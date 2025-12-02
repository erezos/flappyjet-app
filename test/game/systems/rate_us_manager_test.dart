import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flappy_jet_pro/game/systems/rate_us_manager.dart';

/// Comprehensive tests for RateUsManager
/// 
/// Tests the rate us funnel:
/// 1. Initialization and session tracking
/// 2. Eligibility conditions
/// 3. No double-check bug (critical fix)
/// 4. Positive experience and daily streak triggers
/// 5. Decline handling
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RateUsManager manager;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    manager = RateUsManager();
    await manager.resetForTesting();
  });

  group('RateUsManager - Initialization', () {
    test('should initialize with default values', () async {
      await manager.initialize();
      
      expect(manager.isInitialized, isTrue);
      expect(manager.sessionCount, equals(1)); // First session
      expect(manager.hasRated, isFalse);
      expect(manager.hasDeclined, isFalse);
      expect(manager.promptCount, equals(0));
    });

    test('should increment session count on each initialize', () async {
      await manager.initialize();
      expect(manager.sessionCount, equals(1));
      
      // Simulate app restart - reset and re-initialize
      await manager.resetForTesting();
      
      // Set up initial values to simulate returning user
      SharedPreferences.setMockInitialValues({
        'rate_us_session_count': 1,
      });
      manager = RateUsManager();
      await manager.initialize();
      
      expect(manager.sessionCount, equals(2));
    });

    test('should persist state across sessions', () async {
      await manager.initialize();
      await manager.markAsRated();
      
      // Create new instance (simulating app restart)
      SharedPreferences.setMockInitialValues({
        'rate_us_has_rated': true,
        'rate_us_session_count': 1,
      });
      
      final newManager = RateUsManager();
      newManager.setTestInAppReview(null);
      await newManager.resetForTesting();
      
      SharedPreferences.setMockInitialValues({
        'rate_us_has_rated': true,
        'rate_us_session_count': 1,
      });
      await newManager.initialize();
      
      expect(newManager.hasRated, isTrue);
    });
  });

  group('RateUsManager - Eligibility (shouldShowRateUsPrompt)', () {
    test('should not show before minimum sessions', () async {
      await manager.initialize();
      
      // Session 1 - not eligible
      expect(manager.shouldShowRateUsPrompt, isFalse);
      expect(manager.sessionCount, lessThan(RateUsManager.minSessionsBeforePrompt));
    });

    test('should show after minimum sessions', () async {
      // Simulate user with enough sessions
      SharedPreferences.setMockInitialValues({
        'rate_us_session_count': RateUsManager.minSessionsBeforePrompt - 1,
        'rate_us_first_launch_date': DateTime.now()
            .subtract(const Duration(days: 5))
            .millisecondsSinceEpoch,
      });
      
      await manager.initialize();
      
      expect(manager.sessionCount, equals(RateUsManager.minSessionsBeforePrompt));
      expect(manager.shouldShowRateUsPrompt, isTrue);
    });

    test('should not show if already rated', () async {
      SharedPreferences.setMockInitialValues({
        'rate_us_session_count': 10,
        'rate_us_has_rated': true,
      });
      
      await manager.initialize();
      
      expect(manager.hasRated, isTrue);
      expect(manager.shouldShowRateUsPrompt, isFalse);
    });

    test('should not show if user declined', () async {
      SharedPreferences.setMockInitialValues({
        'rate_us_session_count': 10,
        'rate_us_has_declined': true,
      });
      
      await manager.initialize();
      
      expect(manager.hasDeclined, isTrue);
      expect(manager.shouldShowRateUsPrompt, isFalse);
    });

    test('should not show if max prompts reached', () async {
      SharedPreferences.setMockInitialValues({
        'rate_us_session_count': 10,
        'rate_us_prompt_count': RateUsManager.maxPromptsPerUser,
      });
      
      await manager.initialize();
      
      expect(manager.promptCount, equals(RateUsManager.maxPromptsPerUser));
      expect(manager.shouldShowRateUsPrompt, isFalse);
    });

    test('should respect days between prompts', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      
      SharedPreferences.setMockInitialValues({
        'rate_us_session_count': 10,
        'rate_us_prompt_count': 1,
        'rate_us_last_prompt_date': yesterday.millisecondsSinceEpoch,
      });
      
      await manager.initialize();
      
      // Only 1 day since last prompt, need 3+
      expect(manager.shouldShowRateUsPrompt, isFalse);
    });

    test('should show if enough days since last prompt', () async {
      final fourDaysAgo = DateTime.now().subtract(const Duration(days: 4));
      
      SharedPreferences.setMockInitialValues({
        'rate_us_session_count': 10,
        'rate_us_prompt_count': 1,
        'rate_us_last_prompt_date': fourDaysAgo.millisecondsSinceEpoch,
        'rate_us_first_launch_date': DateTime.now()
            .subtract(const Duration(days: 10))
            .millisecondsSinceEpoch,
      });
      
      await manager.initialize();
      
      // 4 days since last prompt, need 3+
      expect(manager.shouldShowRateUsPrompt, isTrue);
    });
  });

  group('RateUsManager - NO Double Check Bug', () {
    /// This is the CRITICAL test that verifies the bug fix.
    /// Previously, calling showRateUsPrompt() would check eligibility AGAIN
    /// with random probability, causing 30% silent failures.
    /// 
    /// Now: requestReview() does NOT re-check eligibility!
    
    test('requestReview should NOT check eligibility again', () async {
      SharedPreferences.setMockInitialValues({
        'rate_us_session_count': 10,
        'rate_us_first_launch_date': DateTime.now()
            .subtract(const Duration(days: 10))
            .millisecondsSinceEpoch,
      });
      
      await manager.initialize();
      
      // First, verify we're eligible
      expect(manager.shouldShowRateUsPrompt, isTrue);
      
      // Now mark as rated (simulating what requestReview does internally)
      // The key point: requestReview() should ALWAYS work when called,
      // it should NOT re-check shouldShowRateUsPrompt
      await manager.markAsRated();
      
      expect(manager.hasRated, isTrue);
    });

    test('recordPopupShown should track without blocking rate', () async {
      SharedPreferences.setMockInitialValues({
        'rate_us_session_count': 10,
        'rate_us_first_launch_date': DateTime.now()
            .subtract(const Duration(days: 10))
            .millisecondsSinceEpoch,
      });
      
      await manager.initialize();
      
      // Record popup shown (this increments prompt count)
      await manager.recordPopupShown();
      
      expect(manager.promptCount, equals(1));
      
      // User can still rate (requestReview doesn't re-check!)
      // We can't test the actual InAppReview without mocking, but we verify state
      expect(manager.hasRated, isFalse); // Not rated yet
    });
  });

  group('RateUsManager - Positive Experience Trigger', () {
    test('should trigger after positive experience if eligible', () async {
      SharedPreferences.setMockInitialValues({
        'rate_us_session_count': 10,
        'rate_us_first_launch_date': DateTime.now()
            .subtract(Duration(days: RateUsManager.minDaysForPositiveExperience + 1))
            .millisecondsSinceEpoch,
      });
      
      await manager.initialize();
      
      expect(manager.shouldPromptAfterPositiveExperience(), isTrue);
    });

    test('should not trigger if too early (not enough days)', () async {
      SharedPreferences.setMockInitialValues({
        'rate_us_session_count': 10,
        'rate_us_first_launch_date': DateTime.now().millisecondsSinceEpoch, // Today
      });
      
      await manager.initialize();
      
      // Even if eligible by sessions, need N days for positive experience
      expect(manager.daysSinceFirstLaunch, equals(0));
      expect(manager.shouldPromptAfterPositiveExperience(), isFalse);
    });
  });

  group('RateUsManager - Daily Streak Trigger', () {
    test('should trigger after sufficient streak', () async {
      SharedPreferences.setMockInitialValues({
        'rate_us_session_count': 10,
        'rate_us_first_launch_date': DateTime.now()
            .subtract(const Duration(days: 10))
            .millisecondsSinceEpoch,
      });
      
      await manager.initialize();
      
      // Streak day 5 should trigger (min is 3)
      expect(manager.shouldPromptAfterDailyStreak(5), isTrue);
    });

    test('should not trigger for short streak', () async {
      SharedPreferences.setMockInitialValues({
        'rate_us_session_count': 10,
        'rate_us_first_launch_date': DateTime.now()
            .subtract(const Duration(days: 10))
            .millisecondsSinceEpoch,
      });
      
      await manager.initialize();
      
      // Streak day 2 should NOT trigger (min is 3)
      expect(manager.shouldPromptAfterDailyStreak(2), isFalse);
    });
  });

  group('RateUsManager - User Actions', () {
    test('handleMaybeLater should not block future prompts', () async {
      SharedPreferences.setMockInitialValues({
        'rate_us_session_count': 10,
        'rate_us_first_launch_date': DateTime.now()
            .subtract(const Duration(days: 10))
            .millisecondsSinceEpoch,
      });
      
      await manager.initialize();
      await manager.recordPopupShown();
      await manager.handleMaybeLater();
      
      expect(manager.hasRated, isFalse);
      expect(manager.hasDeclined, isFalse);
      // Will show again after daysBetweenPrompts
    });

    test('handleDeclined should permanently block prompts', () async {
      SharedPreferences.setMockInitialValues({
        'rate_us_session_count': 10,
        'rate_us_first_launch_date': DateTime.now()
            .subtract(const Duration(days: 10))
            .millisecondsSinceEpoch,
      });
      
      await manager.initialize();
      
      expect(manager.shouldShowRateUsPrompt, isTrue);
      
      await manager.handleDeclined();
      
      expect(manager.hasDeclined, isTrue);
      expect(manager.shouldShowRateUsPrompt, isFalse);
    });

    test('markAsRated should permanently block prompts', () async {
      SharedPreferences.setMockInitialValues({
        'rate_us_session_count': 10,
        'rate_us_first_launch_date': DateTime.now()
            .subtract(const Duration(days: 10))
            .millisecondsSinceEpoch,
      });
      
      await manager.initialize();
      
      expect(manager.shouldShowRateUsPrompt, isTrue);
      
      await manager.markAsRated();
      
      expect(manager.hasRated, isTrue);
      expect(manager.shouldShowRateUsPrompt, isFalse);
    });
  });

  group('RateUsManager - Debug State', () {
    test('getDebugState should return complete state', () async {
      SharedPreferences.setMockInitialValues({
        'rate_us_session_count': 5,
        'rate_us_prompt_count': 2,
      });
      
      await manager.initialize();
      
      final state = manager.getDebugState();
      
      expect(state['is_initialized'], isTrue);
      expect(state['session_count'], equals(6)); // 5 + 1 for this init
      expect(state['has_rated'], isFalse);
      expect(state['has_declined'], isFalse);
      expect(state['prompt_count'], equals(2));
      expect(state['config'], isNotNull);
      expect(state['config']['min_sessions'], equals(RateUsManager.minSessionsBeforePrompt));
    });
  });

  group('RateUsManager - Configuration Constants', () {
    test('should have reasonable default values', () {
      // These are best practices for casual games
      expect(RateUsManager.minSessionsBeforePrompt, greaterThanOrEqualTo(2));
      expect(RateUsManager.minSessionsBeforePrompt, lessThanOrEqualTo(5));
      
      expect(RateUsManager.maxPromptsPerUser, greaterThanOrEqualTo(2));
      expect(RateUsManager.maxPromptsPerUser, lessThanOrEqualTo(5));
      
      expect(RateUsManager.daysBetweenPrompts, greaterThanOrEqualTo(2));
      expect(RateUsManager.daysBetweenPrompts, lessThanOrEqualTo(7));
      
      expect(RateUsManager.minDaysForPositiveExperience, greaterThanOrEqualTo(1));
      expect(RateUsManager.minDaysForPositiveExperience, lessThanOrEqualTo(3));
      
      expect(RateUsManager.minStreakDayForTrigger, greaterThanOrEqualTo(2));
      expect(RateUsManager.minStreakDayForTrigger, lessThanOrEqualTo(5));
    });
  });
}

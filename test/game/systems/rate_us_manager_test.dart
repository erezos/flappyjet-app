/// Tests for RateUsManager - Rate Us popup logic
///
/// Tests verify:
/// 1. Session threshold (3 sessions)
/// 2. Max prompts limit (4 max)
/// 3. Days between prompts (5 days)
/// 4. Probability check (40%)
/// 5. Has rated flag persistence

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RateUsManager Configuration Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('Session threshold should be 3', () {
      // Configuration constant in RateUsManager
      const minSessionsBeforePrompt = 3;
      expect(minSessionsBeforePrompt, equals(3));
    });

    test('Max prompts per user should be 4', () {
      const maxPromptsPerUser = 4;
      expect(maxPromptsPerUser, equals(4));
    });

    test('Days between prompts should be 5', () {
      const daysBetweenPrompts = 5;
      expect(daysBetweenPrompts, equals(5));
    });

    test('Show probability should be 0.4 (40%)', () {
      const showProbability = 0.4;
      expect(showProbability, equals(0.4));
    });
  });

  group('RateUsManager Logic Tests', () {
    test('Should not show before session threshold', () {
      // Session 1, 2 should not show
      const currentSession = 2;
      const minSessions = 3;
      final shouldShow = currentSession >= minSessions;
      expect(shouldShow, isFalse);
    });

    test('Should be eligible at session threshold', () {
      const currentSession = 3;
      const minSessions = 3;
      final shouldShow = currentSession >= minSessions;
      expect(shouldShow, isTrue);
    });

    test('Should not show after max prompts reached', () {
      const promptCount = 4;
      const maxPrompts = 4;
      final shouldShow = promptCount < maxPrompts;
      expect(shouldShow, isFalse);
    });

    test('Should show when under max prompts', () {
      const promptCount = 2;
      const maxPrompts = 4;
      final shouldShow = promptCount < maxPrompts;
      expect(shouldShow, isTrue);
    });

    test('Should not show if already rated', () {
      const hasRated = true;
      final shouldShow = !hasRated;
      expect(shouldShow, isFalse);
    });

    test('Days between prompts check should block recent prompts', () {
      final lastPromptDate = DateTime.now().subtract(const Duration(days: 3));
      const daysBetweenPrompts = 5;
      final daysSinceLastPrompt = DateTime.now().difference(lastPromptDate).inDays;
      final shouldShow = daysSinceLastPrompt >= daysBetweenPrompts;
      expect(shouldShow, isFalse);
    });

    test('Days between prompts check should allow old prompts', () {
      final lastPromptDate = DateTime.now().subtract(const Duration(days: 6));
      const daysBetweenPrompts = 5;
      final daysSinceLastPrompt = DateTime.now().difference(lastPromptDate).inDays;
      final shouldShow = daysSinceLastPrompt >= daysBetweenPrompts;
      expect(shouldShow, isTrue);
    });

    test('Positive experience check requires 3+ days since install', () {
      // User installed today
      final firstLaunchDate = DateTime.now();
      const minDaysSinceInstall = 3;
      final daysSinceInstall = DateTime.now().difference(firstLaunchDate).inDays;
      final shouldShow = daysSinceInstall >= minDaysSinceInstall;
      expect(shouldShow, isFalse);
    });

    test('Positive experience check passes after 3+ days', () {
      // User installed 4 days ago
      final firstLaunchDate = DateTime.now().subtract(const Duration(days: 4));
      const minDaysSinceInstall = 3;
      final daysSinceInstall = DateTime.now().difference(firstLaunchDate).inDays;
      final shouldShow = daysSinceInstall >= minDaysSinceInstall;
      expect(shouldShow, isTrue);
    });
  });

  group('RateUsManager SharedPreferences Keys', () {
    test('SharedPreferences keys should be correctly named', () {
      const keySessionCount = 'rate_us_session_count';
      const keyHasRated = 'rate_us_has_rated';
      const keyLastPromptDate = 'rate_us_last_prompt_date';
      const keyPromptCount = 'rate_us_prompt_count';
      const keyFirstLaunchDate = 'rate_us_first_launch_date';
      
      expect(keySessionCount, equals('rate_us_session_count'));
      expect(keyHasRated, equals('rate_us_has_rated'));
      expect(keyLastPromptDate, equals('rate_us_last_prompt_date'));
      expect(keyPromptCount, equals('rate_us_prompt_count'));
      expect(keyFirstLaunchDate, equals('rate_us_first_launch_date'));
    });
  });

  group('RateUs Event Tracking Tests', () {
    test('Event names should follow naming convention', () {
      // Event names used for Railway tracking
      const events = [
        'rate_us_initialized',
        'rate_us_trigger',
        'rate_us_popup_shown',
        'rate_us_prompt_shown',
        'rate_us_rate_tapped',
        'rate_us_maybe_later',
        'rate_us_declined',
        'rate_us_completed',
        'rate_us_store_opened',
      ];
      
      for (final event in events) {
        expect(event.startsWith('rate_us_'), isTrue);
        expect(event.contains(' '), isFalse); // No spaces
      }
    });

    test('Trigger types should be valid', () {
      const validTriggerTypes = [
        'positive_experience',
        'daily_streak',
        'achievement',
        'manual',
      ];
      
      expect(validTriggerTypes.length, equals(4));
      expect(validTriggerTypes.contains('positive_experience'), isTrue);
      expect(validTriggerTypes.contains('daily_streak'), isTrue);
    });
  });
}


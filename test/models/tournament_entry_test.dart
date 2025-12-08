import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/models/tournament_entry.dart';

void main() {
  group('TournamentEntry', () {
    test('serializes and restores bracket jet order', () {
      final entry = TournamentEntry.start(
        tournamentId: 'bosses_showdown',
        tournamentName: 'Bosses',
        totalTries: 3,
      );
      final order = [
        'player',
        'a',
        'b',
        'c',
        'd',
        'e',
        'f',
        'g',
      ];
      entry.ensureBracketJetOrder(order);
      final json = entry.toJson();
      final restored = TournamentEntry.fromJson(json);
      expect(restored.bracketJetOrder, order);
    });

    group('creation', () {
      test('should create new entry with start factory', () {
        final entry = TournamentEntry.start(
          tournamentId: 'rookie_cup',
          tournamentName: 'Rookie Cup',
          totalTries: 3,
        );

        expect(entry.tournamentId, 'rookie_cup');
        expect(entry.tournamentName, 'Rookie Cup');
        expect(entry.totalTries, 3);
        expect(entry.triesRemaining, 3);
        expect(entry.currentTry, 1);
        expect(entry.currentRound, 1);
        expect(entry.status, TournamentEntryStatus.inProgress);
        expect(entry.coinsEarned, 0);
        expect(entry.gemsEarned, 0);
        expect(entry.roundResults, isEmpty);
        expect(entry.id, startsWith('entry_rookie_cup_'));
      });

      test('should create entry with all parameters', () {
        final startTime = DateTime(2025, 1, 1, 12, 0);
        final entry = TournamentEntry(
          id: 'test_entry_1',
          tournamentId: 'challenger_cup',
          tournamentName: 'Challenger Cup',
          startedAt: startTime,
          totalTries: 5,
          currentTry: 2,
          currentRound: 3,
          triesRemaining: 3,
          continuesUsedThisTry: 2,
          totalContinuesUsed: 4,
          coinsEarned: 500,
          gemsEarned: 10,
        );

        expect(entry.id, 'test_entry_1');
        expect(entry.currentTry, 2);
        expect(entry.currentRound, 3);
        expect(entry.triesRemaining, 3);
        expect(entry.continuesUsedThisTry, 2);
        expect(entry.totalContinuesUsed, 4);
        expect(entry.coinsEarned, 500);
        expect(entry.gemsEarned, 10);
      });
    });

    group('round completion', () {
      test('should complete round and accumulate rewards', () {
        final entry = TournamentEntry.start(
          tournamentId: 'rookie_cup',
          tournamentName: 'Rookie Cup',
          totalTries: 3,
        );

        entry.completeRound(
          roundNumber: 1,
          coinsReward: 100,
          gemsReward: 5,
          heartsUsed: 2,
          continuesUsed: 1,
          duration: const Duration(minutes: 2),
        );

        expect(entry.coinsEarned, 100);
        expect(entry.gemsEarned, 5);
        expect(entry.totalContinuesUsed, 1);
        expect(entry.roundResults, hasLength(1));
        expect(entry.roundResults.first.success, true);
        expect(entry.roundResults.first.roundNumber, 1);
      });

      test('should accumulate rewards across multiple rounds', () {
        final entry = TournamentEntry.start(
          tournamentId: 'rookie_cup',
          tournamentName: 'Rookie Cup',
          totalTries: 3,
        );

        entry.completeRound(
          roundNumber: 1,
          coinsReward: 100,
          gemsReward: 5,
          heartsUsed: 1,
          continuesUsed: 0,
          duration: const Duration(minutes: 1),
        );

        entry.completeRound(
          roundNumber: 2,
          coinsReward: 200,
          gemsReward: 10,
          heartsUsed: 2,
          continuesUsed: 1,
          duration: const Duration(minutes: 2),
        );

        expect(entry.coinsEarned, 300);
        expect(entry.gemsEarned, 15);
        expect(entry.totalContinuesUsed, 1);
        expect(entry.roundResults, hasLength(2));
      });

      test('should track failed round without rewards', () {
        final entry = TournamentEntry.start(
          tournamentId: 'rookie_cup',
          tournamentName: 'Rookie Cup',
          totalTries: 3,
        );

        entry.failRound(
          roundNumber: 1,
          heartsUsed: 3,
          continuesUsed: 5,
          duration: const Duration(minutes: 5),
        );

        expect(entry.coinsEarned, 0);
        expect(entry.gemsEarned, 0);
        expect(entry.totalContinuesUsed, 5);
        expect(entry.roundResults, hasLength(1));
        expect(entry.roundResults.first.success, false);
      });
    });

    group('continues', () {
      test('should track continues used this try', () {
        final entry = TournamentEntry.start(
          tournamentId: 'rookie_cup',
          tournamentName: 'Rookie Cup',
          totalTries: 3,
        );

        expect(entry.continuesUsedThisTry, 0);
        expect(entry.canUseContinue(5), true);

        entry.useContinue();
        expect(entry.continuesUsedThisTry, 1);
        expect(entry.canUseContinue(5), true);

        // Use 4 more continues
        entry.useContinue();
        entry.useContinue();
        entry.useContinue();
        entry.useContinue();

        expect(entry.continuesUsedThisTry, 5);
        expect(entry.canUseContinue(5), false);
      });

      test('should reset continues on next try', () {
        final entry = TournamentEntry.start(
          tournamentId: 'rookie_cup',
          tournamentName: 'Rookie Cup',
          totalTries: 3,
        );

        entry.useContinue();
        entry.useContinue();
        expect(entry.continuesUsedThisTry, 2);

        entry.failCurrentTry();
        expect(entry.continuesUsedThisTry, 0);
        expect(entry.currentTry, 2);
      });
    });

    group('tries management', () {
      test('should decrement tries on failure', () {
        final entry = TournamentEntry.start(
          tournamentId: 'rookie_cup',
          tournamentName: 'Rookie Cup',
          totalTries: 3,
        );

        expect(entry.triesRemaining, 3);
        expect(entry.canRetry, true);

        entry.failCurrentTry();
        expect(entry.triesRemaining, 2);
        expect(entry.currentTry, 2);
        expect(entry.status, TournamentEntryStatus.inProgress);

        entry.failCurrentTry();
        expect(entry.triesRemaining, 1);
        expect(entry.currentTry, 3);

        entry.failCurrentTry();
        expect(entry.triesRemaining, 0);
        expect(entry.status, TournamentEntryStatus.failed);
        expect(entry.canRetry, false);
      });

      test('should add extra tries and revert failed status', () {
        final entry = TournamentEntry.start(
          tournamentId: 'rookie_cup',
          tournamentName: 'Rookie Cup',
          totalTries: 3,
        );

        // Fail all tries
        entry.failCurrentTry();
        entry.failCurrentTry();
        entry.failCurrentTry();

        expect(entry.status, TournamentEntryStatus.failed);
        expect(entry.triesRemaining, 0);

        // Add extra tries from special deal
        entry.addExtraTries(2);

        expect(entry.status, TournamentEntryStatus.inProgress);
        expect(entry.triesRemaining, 2);
        expect(entry.canRetry, true);
      });

      test('startNextTry should throw if no tries remaining', () {
        final entry = TournamentEntry.start(
          tournamentId: 'rookie_cup',
          tournamentName: 'Rookie Cup',
          totalTries: 1,
        );

        entry.triesRemaining = 0;

        expect(
          () => entry.startNextTry(),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('tournament completion', () {
      test('should complete tournament with bonus rewards', () {
        final entry = TournamentEntry.start(
          tournamentId: 'rookie_cup',
          tournamentName: 'Rookie Cup',
          totalTries: 3,
        );

        // Earn some round rewards
        entry.completeRound(
          roundNumber: 1,
          coinsReward: 100,
          gemsReward: 5,
          heartsUsed: 1,
          continuesUsed: 0,
          duration: const Duration(minutes: 1),
        );

        // Complete tournament
        entry.completeTournament(bonusCoins: 500, bonusGems: 20);

        expect(entry.status, TournamentEntryStatus.completed);
        expect(entry.coinsEarned, 600); // 100 + 500 bonus
        expect(entry.gemsEarned, 25); // 5 + 20 bonus
        expect(entry.completedAt, isNotNull);
      });

      test('should abandon tournament', () {
        final entry = TournamentEntry.start(
          tournamentId: 'rookie_cup',
          tournamentName: 'Rookie Cup',
          totalTries: 3,
        );

        entry.abandon();

        expect(entry.status, TournamentEntryStatus.abandoned);
        expect(entry.completedAt, isNotNull);
      });
    });

    group('statistics', () {
      test('should calculate success rate', () {
        final entry = TournamentEntry.start(
          tournamentId: 'rookie_cup',
          tournamentName: 'Rookie Cup',
          totalTries: 3,
        );

        expect(entry.successRate, 0.0);

        // Complete 2 rounds successfully
        entry.completeRound(
          roundNumber: 1,
          coinsReward: 100,
          gemsReward: 0,
          heartsUsed: 1,
          continuesUsed: 0,
          duration: const Duration(minutes: 1),
        );

        entry.completeRound(
          roundNumber: 2,
          coinsReward: 100,
          gemsReward: 0,
          heartsUsed: 1,
          continuesUsed: 0,
          duration: const Duration(minutes: 1),
        );

        // Fail 1 round
        entry.failRound(
          roundNumber: 3,
          heartsUsed: 3,
          continuesUsed: 5,
          duration: const Duration(minutes: 2),
        );

        expect(entry.successRate, closeTo(0.666, 0.01));
      });

      test('should track highest round reached', () {
        final entry = TournamentEntry.start(
          tournamentId: 'rookie_cup',
          tournamentName: 'Rookie Cup',
          totalTries: 3,
        );

        expect(entry.highestRoundReached, 0);

        entry.completeRound(
          roundNumber: 1,
          coinsReward: 100,
          gemsReward: 0,
          heartsUsed: 1,
          continuesUsed: 0,
          duration: const Duration(minutes: 1),
        );

        entry.completeRound(
          roundNumber: 2,
          coinsReward: 100,
          gemsReward: 0,
          heartsUsed: 1,
          continuesUsed: 0,
          duration: const Duration(minutes: 1),
        );

        entry.failRound(
          roundNumber: 3,
          heartsUsed: 3,
          continuesUsed: 5,
          duration: const Duration(minutes: 2),
        );

        expect(entry.highestRoundReached, 3);
      });

      test('should calculate duration', () {
        final startTime = DateTime(2025, 1, 1, 12, 0);
        final entry = TournamentEntry(
          id: 'test_entry',
          tournamentId: 'rookie_cup',
          tournamentName: 'Rookie Cup',
          startedAt: startTime,
          totalTries: 3,
          completedAt: DateTime(2025, 1, 1, 12, 30),
        );

        expect(entry.duration, const Duration(minutes: 30));
      });
    });

    group('JSON serialization', () {
      test('should serialize to JSON', () {
        final startTime = DateTime(2025, 1, 1, 12, 0);
        final entry = TournamentEntry(
          id: 'test_entry_1',
          tournamentId: 'rookie_cup',
          tournamentName: 'Rookie Cup',
          startedAt: startTime,
          totalTries: 3,
          currentTry: 2,
          currentRound: 3,
          triesRemaining: 1,
          coinsEarned: 500,
          gemsEarned: 10,
          status: TournamentEntryStatus.inProgress,
        );

        final json = entry.toJson();

        expect(json['id'], 'test_entry_1');
        expect(json['tournament_id'], 'rookie_cup');
        expect(json['tournament_name'], 'Rookie Cup');
        expect(json['total_tries'], 3);
        expect(json['current_try'], 2);
        expect(json['current_round'], 3);
        expect(json['tries_remaining'], 1);
        expect(json['coins_earned'], 500);
        expect(json['gems_earned'], 10);
        expect(json['status'], 'inProgress');
      });

      test('should deserialize from JSON', () {
        final json = {
          'id': 'test_entry_1',
          'tournament_id': 'rookie_cup',
          'tournament_name': 'Rookie Cup',
          'started_at': '2025-01-01T12:00:00.000',
          'total_tries': 3,
          'current_try': 2,
          'current_round': 3,
          'tries_remaining': 1,
          'continues_used_this_try': 2,
          'total_continues_used': 5,
          'coins_earned': 500,
          'gems_earned': 10,
          'round_results': <Map<String, dynamic>>[],
          'status': 'inProgress',
        };

        final entry = TournamentEntry.fromJson(json);

        expect(entry.id, 'test_entry_1');
        expect(entry.tournamentId, 'rookie_cup');
        expect(entry.tournamentName, 'Rookie Cup');
        expect(entry.currentTry, 2);
        expect(entry.currentRound, 3);
        expect(entry.triesRemaining, 1);
        expect(entry.coinsEarned, 500);
        expect(entry.gemsEarned, 10);
        expect(entry.status, TournamentEntryStatus.inProgress);
      });

      test('should round-trip serialize and deserialize', () {
        final entry = TournamentEntry.start(
          tournamentId: 'rookie_cup',
          tournamentName: 'Rookie Cup',
          totalTries: 3,
        );

        entry.completeRound(
          roundNumber: 1,
          coinsReward: 100,
          gemsReward: 5,
          heartsUsed: 2,
          continuesUsed: 1,
          duration: const Duration(minutes: 2),
        );

        final jsonString = entry.toJsonString();
        final restored = TournamentEntry.fromJsonString(jsonString);

        expect(restored.tournamentId, entry.tournamentId);
        expect(restored.tournamentName, entry.tournamentName);
        expect(restored.totalTries, entry.totalTries);
        expect(restored.coinsEarned, entry.coinsEarned);
        expect(restored.gemsEarned, entry.gemsEarned);
        expect(restored.roundResults, hasLength(1));
        expect(restored.roundResults.first.success, true);
      });

      test('should handle completed status with completedAt', () {
        final entry = TournamentEntry.start(
          tournamentId: 'rookie_cup',
          tournamentName: 'Rookie Cup',
          totalTries: 3,
        );

        entry.completeTournament(bonusCoins: 500, bonusGems: 20);

        final json = entry.toJson();
        expect(json['status'], 'completed');
        expect(json['completed_at'], isNotNull);

        final restored = TournamentEntry.fromJson(json);
        expect(restored.status, TournamentEntryStatus.completed);
        expect(restored.completedAt, isNotNull);
      });
    });

    group('RoundResult', () {
      test('should serialize and deserialize', () {
        const result = RoundResult(
          roundNumber: 1,
          tryNumber: 1,
          success: true,
          coinsEarned: 100,
          gemsEarned: 5,
          heartsUsed: 2,
          continuesUsed: 1,
          duration: Duration(minutes: 2, seconds: 30),
        );

        final json = result.toJson();
        expect(json['round_number'], 1);
        expect(json['try_number'], 1);
        expect(json['success'], true);
        expect(json['coins_earned'], 100);
        expect(json['gems_earned'], 5);
        expect(json['hearts_used'], 2);
        expect(json['continues_used'], 1);
        expect(json['duration_seconds'], 150);

        final restored = RoundResult.fromJson(json);
        expect(restored.roundNumber, 1);
        expect(restored.success, true);
        expect(restored.coinsEarned, 100);
        expect(restored.duration.inSeconds, 150);
      });

      test('should have meaningful toString', () {
        const result = RoundResult(
          roundNumber: 2,
          tryNumber: 1,
          success: true,
          coinsEarned: 200,
          gemsEarned: 10,
          heartsUsed: 1,
          continuesUsed: 0,
          duration: Duration(minutes: 1),
        );

        expect(result.toString(), contains('round: 2'));
        expect(result.toString(), contains('success: true'));
        expect(result.toString(), contains('coins: 200'));
      });
    });

    group('TournamentEntryStatus', () {
      test('isActive should be true only for inProgress', () {
        expect(TournamentEntryStatus.inProgress.isActive, true);
        expect(TournamentEntryStatus.completed.isActive, false);
        expect(TournamentEntryStatus.failed.isActive, false);
        expect(TournamentEntryStatus.abandoned.isActive, false);
      });

      test('isFinished should be true for all except inProgress', () {
        expect(TournamentEntryStatus.inProgress.isFinished, false);
        expect(TournamentEntryStatus.completed.isFinished, true);
        expect(TournamentEntryStatus.failed.isFinished, true);
        expect(TournamentEntryStatus.abandoned.isFinished, true);
      });
    });

    group('toString', () {
      test('should have meaningful toString', () {
        final entry = TournamentEntry.start(
          tournamentId: 'rookie_cup',
          tournamentName: 'Rookie Cup',
          totalTries: 3,
        );

        final str = entry.toString();
        expect(str, contains('Rookie Cup'));
        expect(str, contains('try: 1/3'));
        expect(str, contains('inProgress'));
      });
    });
  });
}


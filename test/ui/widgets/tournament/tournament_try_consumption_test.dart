/// 🧪 Tournament Try Consumption Test
/// 
/// Tests that tries are consumed correctly when a user crashes in a tournament,
/// regardless of whether they click "Start Over" or "X" to quit.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flappy_jet_pro/game/systems/tournament_manager.dart';
import 'package:flappy_jet_pro/game/systems/lives_manager.dart';
import 'package:flappy_jet_pro/models/tournament_config.dart';
import 'package:flappy_jet_pro/models/tournament_entry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tournament Try Consumption Flow', () {
    late TournamentManager tournamentManager;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      
      // Reset managers
      TournamentManager().resetForTesting();
      LivesManager().forceResetToNewPlayer();
      
      tournamentManager = TournamentManager();
      await tournamentManager.initialize();
    });

    test('Try is consumed immediately on crash, not on Start Over', () async {
      // Create a tournament with 5 tries
      final tournament = TournamentConfig.fromJson({
        'id': 'test_tournament',
        'name': 'Test Tournament',
        'description': 'Test',
        'tier': 'bronze',
        'status': 'active',
        'progression_type': 'linear',
        'entry': {'type': 'coins', 'amount': 400},
        'tries': {'count': 5},
        'continues': {'max_per_try': 5, 'gem_cost': 3, 'ad_available': true},
        'levels': [
          {
            'round': 1,
            'name': 'Round 1',
            'difficulty': {
              'speedMultiplier': 1.0,
              'obstacleGap': 350,
              'obstacleFrequency': 2.5,
              'maxGapShift': 50,
              'requiredDistance': 20,
            },
            'reward': {'coins': 100, 'gems': 5},
          },
        ],
        'completion_reward': {'coins': 100, 'gems': 50},
        'display': {'banner_image': 'test.png', 'icon': 'trophy_bronze', 'color_primary': '#CD7F32', 'color_secondary': '#8B4513'},
      });

      // Enter tournament (mock currency check)
      final entry = await tournamentManager.enterTournament(
        tournament,
        useFreeTicket: false,
      );
      expect(entry, isNotNull);
      expect(entry!.triesRemaining, equals(5));
      expect(entry.currentRound, equals(1));

      // Simulate crashing 3 times in level 3
      entry.startRound(3); // Move to level 3
      await tournamentManager.updateActiveEntry(tournament.id, entry);

      // Crash 1: Should consume try immediately
      final preservedRound1 = entry.currentRound;
      await tournamentManager.failCurrentTry(tournamentId: tournament.id);
      entry.startRound(preservedRound1);
      await tournamentManager.updateActiveEntry(tournament.id, entry);
      expect(entry.triesRemaining, equals(4), reason: 'First crash should consume 1 try');

      // Crash 2: Should consume another try
      final preservedRound2 = entry.currentRound;
      await tournamentManager.failCurrentTry(tournamentId: tournament.id);
      entry.startRound(preservedRound2);
      await tournamentManager.updateActiveEntry(tournament.id, entry);
      expect(entry.triesRemaining, equals(3), reason: 'Second crash should consume 1 try');

      // Crash 3: Should consume another try
      final preservedRound3 = entry.currentRound;
      await tournamentManager.failCurrentTry(tournamentId: tournament.id);
      entry.startRound(preservedRound3);
      await tournamentManager.updateActiveEntry(tournament.id, entry);
      expect(entry.triesRemaining, equals(2), reason: 'Third crash should consume 1 try');
      expect(entry.currentRound, equals(3), reason: 'Round should be preserved');

      // User clicks "X" to quit (no try consumed, already consumed on crash)
      // Entry should remain active with 2 tries remaining
      final activeEntry = tournamentManager.activeEntryFor(tournament.id);
      expect(activeEntry, isNotNull);
      expect(activeEntry!.triesRemaining, equals(2));
      expect(activeEntry.currentRound, equals(3));
      expect(activeEntry.status, equals(TournamentEntryStatus.inProgress));

      // User continues from tournament hub and crashes again
      // Crash 4: Should consume another try
      final preservedRound4 = activeEntry.currentRound;
      await tournamentManager.failCurrentTry(tournamentId: tournament.id);
      activeEntry.startRound(preservedRound4);
      await tournamentManager.updateActiveEntry(tournament.id, activeEntry);
      expect(activeEntry.triesRemaining, equals(1), reason: 'Fourth crash should consume 1 try');
      expect(activeEntry.currentRound, equals(3), reason: 'Round should still be preserved');

      // User clicks "X" again and continues
      // Crash 5: Should consume the last try
      final preservedRound5 = activeEntry.currentRound;
      await tournamentManager.failCurrentTry(tournamentId: tournament.id);
      activeEntry.startRound(preservedRound5);
      await tournamentManager.updateActiveEntry(tournament.id, activeEntry);
      expect(activeEntry.triesRemaining, equals(0), reason: 'Fifth crash should consume last try');
      expect(activeEntry.status, equals(TournamentEntryStatus.failed), reason: 'Tournament should be failed when no tries left');
    });

    test('Try consumption preserves current round for retry', () async {
      final tournament = TournamentConfig.fromJson({
        'id': 'test_tournament_2',
        'name': 'Test Tournament 2',
        'description': 'Test',
        'tier': 'bronze',
        'status': 'active',
        'progression_type': 'linear',
        'entry': {'type': 'coins', 'amount': 400},
        'tries': {'count': 3},
        'continues': {'max_per_try': 5, 'gem_cost': 3, 'ad_available': true},
        'levels': [
          {
            'round': 1,
            'name': 'Round 1',
            'difficulty': {
              'speedMultiplier': 1.0,
              'obstacleGap': 350,
              'obstacleFrequency': 2.5,
              'maxGapShift': 50,
              'requiredDistance': 20,
            },
            'reward': {'coins': 100, 'gems': 5},
          },
        ],
        'completion_reward': {'coins': 100, 'gems': 50},
        'display': {'banner_image': 'test.png', 'icon': 'trophy_bronze', 'color_primary': '#CD7F32', 'color_secondary': '#8B4513'},
      });

      final entry = await tournamentManager.enterTournament(
        tournament,
        useFreeTicket: false,
      );
      expect(entry, isNotNull);

      // Move to level 5
      entry!.startRound(5);
      await tournamentManager.updateActiveEntry(tournament.id, entry);
      expect(entry.currentRound, equals(5));

      // Crash: Try should be consumed, round should be preserved
      final preservedRound = entry.currentRound;
      await tournamentManager.failCurrentTry(tournamentId: tournament.id);
      entry.startRound(preservedRound);
      await tournamentManager.updateActiveEntry(tournament.id, entry);

      expect(entry.triesRemaining, equals(2), reason: 'Try should be consumed');
      expect(entry.currentRound, equals(5), reason: 'Round should be preserved for retry');
    });

    test('Quitting with tries remaining keeps entry active', () async {
      final tournament = TournamentConfig.fromJson({
        'id': 'test_tournament_3',
        'name': 'Test Tournament 3',
        'description': 'Test',
        'tier': 'bronze',
        'status': 'active',
        'progression_type': 'linear',
        'entry': {'type': 'coins', 'amount': 400},
        'tries': {'count': 3},
        'continues': {'max_per_try': 5, 'gem_cost': 3, 'ad_available': true},
        'levels': [
          {
            'round': 1,
            'name': 'Round 1',
            'difficulty': {
              'speedMultiplier': 1.0,
              'obstacleGap': 350,
              'obstacleFrequency': 2.5,
              'maxGapShift': 50,
              'requiredDistance': 20,
            },
            'reward': {'coins': 100, 'gems': 5},
          },
        ],
        'completion_reward': {'coins': 100, 'gems': 50},
        'display': {'banner_image': 'test.png', 'icon': 'trophy_bronze', 'color_primary': '#CD7F32', 'color_secondary': '#8B4513'},
      });

      final entry = await tournamentManager.enterTournament(
        tournament,
        useFreeTicket: false,
      );
      expect(entry, isNotNull);
      expect(entry!.triesRemaining, equals(3));

      // Crash once
      final preservedRound = entry.currentRound;
      await tournamentManager.failCurrentTry(tournamentId: tournament.id);
      entry.startRound(preservedRound);
      await tournamentManager.updateActiveEntry(tournament.id, entry);
      expect(entry.triesRemaining, equals(2));

      // User quits (clicks "X") - entry should remain active
      final activeEntry = tournamentManager.activeEntryFor(tournament.id);
      expect(activeEntry, isNotNull);
      expect(activeEntry!.triesRemaining, equals(2));
      expect(activeEntry.status, equals(TournamentEntryStatus.inProgress));
      expect(tournamentManager.hasActiveEntryFor(tournament.id), isTrue, reason: 'Entry should be active for continuation');
    });
  });
}


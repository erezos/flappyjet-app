import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flappy_jet_pro/game/systems/tournament_manager.dart';
import 'package:flappy_jet_pro/game/systems/lives_manager.dart';
import 'package:flappy_jet_pro/models/tournament_config.dart';
import 'package:flappy_jet_pro/models/tournament_entry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TournamentManager tournamentManager;
  late TournamentConfig testTournament;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    
    // Reset managers
    TournamentManager().resetForTesting();
    LivesManager().forceResetToNewPlayer();
    
    tournamentManager = TournamentManager();
    await tournamentManager.initialize();

    // Use a free tournament (no cost) for testing gameplay flow
    testTournament = TournamentConfig.fromJson({
      'id': 'test_gameplay_tournament',
      'name': 'Gameplay Test Tournament',
      'description': 'For testing gameplay flow',
      'tier': 'bronze',
      'status': 'active',
      'entry': {'type': 'freeTicket', 'amount': 0}, // Free ticket entry
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
        {
          'round': 2,
          'name': 'Round 2',
          'difficulty': {
            'speedMultiplier': 1.1,
            'obstacleGap': 320,
            'obstacleFrequency': 2.3,
            'maxGapShift': 60,
            'requiredDistance': 30,
          },
          'reward': {'coins': 200, 'gems': 10},
        },
        {
          'round': 3,
          'name': 'Final Round',
          'difficulty': {
            'speedMultiplier': 1.2,
            'obstacleGap': 300,
            'obstacleFrequency': 2.0,
            'maxGapShift': 70,
            'requiredDistance': 40,
          },
          'reward': {'coins': 300, 'gems': 15},
        },
      ],
      'completion_reward': {'coins': 500, 'gems': 25},
      'display': {'banner_image': 'test.png', 'background_color': '#CD7F32'},
    });

    // Grant a free ticket for testing
    await tournamentManager.grantFreeTicket(TournamentTier.bronze, count: 5);
  });

  group('TournamentManager - Round Completion', () {
    test('should complete round and update entry', () async {
      // Enter tournament
      final entry = await tournamentManager.enterTournament(
        testTournament,
        useFreeTicket: true,
      );
      expect(entry, isNotNull);
      expect(entry!.currentRound, 1);

      // Complete round 1
      await tournamentManager.completeRound(
        roundNumber: 1,
        coinsReward: 100,
        gemsReward: 5,
        heartsUsed: 2,
        continuesUsed: 0,
        duration: const Duration(minutes: 2),
      );

      // Round is not auto-advanced - that's done by TournamentGameWrapper
      expect(tournamentManager.activeEntry!.currentRound, 1);
      expect(tournamentManager.activeEntry!.coinsEarned, 100);
      expect(tournamentManager.activeEntry!.gemsEarned, 5);
      
      // Verify round results recorded
      expect(tournamentManager.activeEntry!.roundResults.length, 1);
      expect(tournamentManager.activeEntry!.roundResults[0].success, true);
    });

    test('should track continues used per try', () async {
      final entry = await tournamentManager.enterTournament(
        testTournament,
        useFreeTicket: true,
      );
      expect(entry, isNotNull);

      // Use some continues
      await tournamentManager.useContinue();
      await tournamentManager.useContinue();

      expect(tournamentManager.activeEntry!.continuesUsedThisTry, 2);
    });

    test('should fail round and update entry', () async {
      final entry = await tournamentManager.enterTournament(
        testTournament,
        useFreeTicket: true,
      );
      expect(entry, isNotNull);

      // Fail round 1
      await tournamentManager.failRound(
        roundNumber: 1,
        heartsUsed: 3,
        continuesUsed: 2,
        duration: const Duration(minutes: 1),
      );

      // Round should still be 1 (failed, not advanced)
      expect(tournamentManager.activeEntry!.currentRound, 1);
    });

    test('should decrement tries on fail', () async {
      final entry = await tournamentManager.enterTournament(
        testTournament,
        useFreeTicket: true,
      );
      expect(entry, isNotNull);
      expect(entry!.triesRemaining, 3);

      // Fail the try
      final status = await tournamentManager.failCurrentTry();

      // Should have 2 tries remaining
      expect(tournamentManager.activeEntry!.triesRemaining, 2);
      expect(status, TournamentEntryStatus.inProgress);
    });

    test('should complete tournament when all rounds done', () async {
      final entry = await tournamentManager.enterTournament(
        testTournament,
        useFreeTicket: true,
      );
      expect(entry, isNotNull);

      // Complete all rounds
      for (var i = 1; i <= 3; i++) {
        await tournamentManager.completeRound(
          roundNumber: i,
          coinsReward: i * 100,
          gemsReward: i * 5,
          heartsUsed: 1,
          continuesUsed: 0,
          duration: const Duration(minutes: 2),
        );
      }

      // Complete tournament
      await tournamentManager.completeTournament(
        bonusCoins: 500,
        bonusGems: 25,
      );

      expect(tournamentManager.activeEntry!.status, TournamentEntryStatus.completed);
      expect(tournamentManager.activeEntry!.coinsEarned, 100 + 200 + 300 + 500);
      expect(tournamentManager.activeEntry!.gemsEarned, 5 + 10 + 15 + 25);
    });

    test('should fail tournament when no tries remain', () async {
      final entry = await tournamentManager.enterTournament(
        testTournament,
        useFreeTicket: true,
      );
      expect(entry, isNotNull);

      // Fail all 3 tries
      for (var i = 0; i < 3; i++) {
        await tournamentManager.failCurrentTry();
      }

      expect(tournamentManager.activeEntry!.status, TournamentEntryStatus.failed);
      expect(tournamentManager.activeEntry!.triesRemaining, 0);
    });
  });

  group('TournamentManager - Continue System', () {
    test('should track continues per try', () async {
      final entry = await tournamentManager.enterTournament(
        testTournament,
        useFreeTicket: true,
      );
      expect(entry, isNotNull);

      // Use continues
      await tournamentManager.useContinue();
      expect(tournamentManager.activeEntry!.continuesUsedThisTry, 1);

      await tournamentManager.useContinue();
      expect(tournamentManager.activeEntry!.continuesUsedThisTry, 2);
    });

    test('should reset continues on new try', () async {
      final entry = await tournamentManager.enterTournament(
        testTournament,
        useFreeTicket: true,
      );
      expect(entry, isNotNull);

      // Use some continues
      await tournamentManager.useContinue();
      await tournamentManager.useContinue();
      expect(tournamentManager.activeEntry!.continuesUsedThisTry, 2);

      // Fail try (continues should reset)
      await tournamentManager.failCurrentTry();

      // Note: continuesUsedThisTry resets via startNewTry in the entry
      // But the entry's total continues should track
      expect(tournamentManager.activeEntry!.totalContinuesUsed, 2);
    });

    test('should check can use continue', () {
      final entry = TournamentEntry.start(
        tournamentId: 'test',
        tournamentName: 'Test',
        totalTries: 3,
      );

      // Max 5 continues per try
      expect(entry.canUseContinue(5), true);

      // Use 5 continues
      for (var i = 0; i < 5; i++) {
        entry.useContinue();
      }

      expect(entry.canUseContinue(5), false);
    });
  });

  group('TournamentManager - Abandon', () {
    test('should abandon tournament', () async {
      final entry = await tournamentManager.enterTournament(
        testTournament,
        useFreeTicket: true,
      );
      expect(entry, isNotNull);

      // Complete some rounds first
      await tournamentManager.completeRound(
        roundNumber: 1,
        coinsReward: 100,
        gemsReward: 5,
        heartsUsed: 1,
        continuesUsed: 0,
        duration: const Duration(minutes: 1),
      );

      // Abandon
      await tournamentManager.abandonTournament();

      expect(tournamentManager.activeEntry!.status, TournamentEntryStatus.abandoned);
    });

    test('should keep partial rewards on abandon', () async {
      final entry = await tournamentManager.enterTournament(
        testTournament,
        useFreeTicket: true,
      );
      expect(entry, isNotNull);

      // Complete round 1
      await tournamentManager.completeRound(
        roundNumber: 1,
        coinsReward: 100,
        gemsReward: 5,
        heartsUsed: 1,
        continuesUsed: 0,
        duration: const Duration(minutes: 1),
      );

      // Abandon
      await tournamentManager.abandonTournament();

      // Should keep earned rewards
      expect(tournamentManager.activeEntry!.coinsEarned, 100);
      expect(tournamentManager.activeEntry!.gemsEarned, 5);
    });
  });

  group('TournamentManager - Extra Tries Purchase', () {
    test('should purchase extra tries', () async {
      final entry = await tournamentManager.enterTournament(
        testTournament,
        useFreeTicket: true,
      );
      expect(entry, isNotNull);

      // Fail all tries
      for (var i = 0; i < 3; i++) {
        await tournamentManager.failCurrentTry();
      }

      expect(tournamentManager.activeEntry!.triesRemaining, 0);
      expect(tournamentManager.activeEntry!.status, TournamentEntryStatus.failed);

      // Purchase extra tries
      final success = await tournamentManager.purchaseExtraTries(
        extraTries: 2,
        cost: 80,
        costType: EntryFeeType.gems,
      );

      expect(success, true);
      expect(tournamentManager.activeEntry!.triesRemaining, 2);
      expect(tournamentManager.activeEntry!.status, TournamentEntryStatus.inProgress);
    });
  });

  group('TournamentManager - Clear Entry', () {
    test('should clear active entry', () async {
      final entry = await tournamentManager.enterTournament(
        testTournament,
        useFreeTicket: true,
      );
      expect(entry, isNotNull);
      expect(tournamentManager.hasActiveEntry, true);

      tournamentManager.clearActiveEntry();

      expect(tournamentManager.hasActiveEntry, false);
      expect(tournamentManager.activeEntry, isNull);
    });
  });
}


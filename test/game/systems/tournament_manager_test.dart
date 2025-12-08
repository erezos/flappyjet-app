import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flappy_jet_pro/game/systems/tournament_manager.dart';
import 'package:flappy_jet_pro/models/tournament_config.dart';
import 'package:flappy_jet_pro/models/tournament_entry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Reset SharedPreferences
    SharedPreferences.setMockInitialValues({});
    
    // Reset singleton
    TournamentManager().resetForTesting();
  });

  group('TournamentManager - Singleton', () {
    test('should return same instance', () {
      final manager1 = TournamentManager();
      final manager2 = TournamentManager();
      
      expect(identical(manager1, manager2), true);
    });
  });

  group('TournamentManager - State', () {
    test('should start uninitialized', () {
      final manager = TournamentManager();
      
      expect(manager.isInitialized, false);
      expect(manager.hasActiveEntry, false);
      expect(manager.availableTournaments, isEmpty);
    });

    test('should have no active entry initially', () {
      final manager = TournamentManager();
      
      expect(manager.activeEntry, isNull);
      expect(manager.hasActiveEntry, false);
    });
  });

  group('TournamentManager - canEnterTournament', () {
    late TournamentConfig coinsTournament;
    late TournamentConfig gemsTournament;

    setUp(() {
      // Create test tournament configs
      coinsTournament = TournamentConfig.fromJson({
        'id': 'coins_tournament',
        'name': 'Coins Tournament',
        'description': 'Test',
        'tier': 'bronze',
        'status': 'active',
        'entry': {'type': 'coins', 'amount': 100},
        'tries': {'count': 3},
        'continues': {'max_per_try': 5, 'gem_cost': 3, 'ad_available': true},
        'levels': [],
        'completion_reward': {'coins': 500, 'gems': 20},
        'display': {'banner_image': 'test.png', 'background_color': '#FF0000'},
      });

      gemsTournament = TournamentConfig.fromJson({
        'id': 'gems_tournament',
        'name': 'Gems Tournament',
        'description': 'Test',
        'tier': 'silver',
        'status': 'active',
        'entry': {'type': 'gems', 'amount': 50},
        'tries': {'count': 3},
        'continues': {'max_per_try': 5, 'gem_cost': 3, 'ad_available': true},
        'levels': [],
        'completion_reward': {'coins': 500, 'gems': 20},
        'display': {'banner_image': 'test.png', 'background_color': '#FF0000'},
      });
    });

    test('should allow entry with sufficient coins', () {
      final manager = TournamentManager();
      
      final result = manager.canEnterTournament(
        coinsTournament,
        playerCoins: 200,
        playerGems: 0,
      );
      
      expect(result.canEnter, true);
      expect(result.cost, 100);
      expect(result.costType, EntryFeeType.coins);
    });

    test('should deny entry with insufficient coins', () {
      final manager = TournamentManager();
      
      final result = manager.canEnterTournament(
        coinsTournament,
        playerCoins: 50,
        playerGems: 0,
      );
      
      expect(result.canEnter, false);
      expect(result.reason, contains('Not enough coins'));
    });

    test('should allow entry with sufficient gems', () {
      final manager = TournamentManager();
      
      final result = manager.canEnterTournament(
        gemsTournament,
        playerCoins: 0,
        playerGems: 100,
      );
      
      expect(result.canEnter, true);
      expect(result.cost, 50);
      expect(result.costType, EntryFeeType.gems);
    });

    test('should deny entry with insufficient gems', () {
      final manager = TournamentManager();
      
      final result = manager.canEnterTournament(
        gemsTournament,
        playerCoins: 1000,
        playerGems: 10,
      );
      
      expect(result.canEnter, false);
      expect(result.reason, contains('Not enough gems'));
    });

    test('should prefer free ticket if available', () async {
      final manager = TournamentManager();
      await manager.grantFreeTicket(TournamentTier.bronze);
      
      final result = manager.canEnterTournament(
        coinsTournament,
        playerCoins: 0,
        playerGems: 0,
      );
      
      expect(result.canEnter, true);
      expect(result.useFreeTicket, true);
      expect(result.freeTicketTier, TournamentTier.bronze);
    });
  });

  group('TournamentManager - Free Tickets', () {
    test('should start with zero free tickets', () {
      final manager = TournamentManager();
      
      expect(manager.totalFreeTickets, 0);
      expect(manager.getFreeTickets(TournamentTier.bronze), 0);
    });

    test('should grant free tickets', () async {
      final manager = TournamentManager();
      
      await manager.grantFreeTicket(TournamentTier.bronze);
      
      expect(manager.getFreeTickets(TournamentTier.bronze), 1);
      expect(manager.totalFreeTickets, 1);
    });

    test('should grant multiple free tickets', () async {
      final manager = TournamentManager();
      
      await manager.grantFreeTicket(TournamentTier.bronze, count: 3);
      
      expect(manager.getFreeTickets(TournamentTier.bronze), 3);
    });

    test('should track tickets by tier', () async {
      final manager = TournamentManager();
      
      await manager.grantFreeTicket(TournamentTier.bronze, count: 2);
      await manager.grantFreeTicket(TournamentTier.silver, count: 1);
      
      expect(manager.getFreeTickets(TournamentTier.bronze), 2);
      expect(manager.getFreeTickets(TournamentTier.silver), 1);
      expect(manager.getFreeTickets(TournamentTier.gold), 0);
      expect(manager.totalFreeTickets, 3);
    });

    test('hasFreeTicketFor should check correct tier', () async {
      final manager = TournamentManager();
      await manager.grantFreeTicket(TournamentTier.bronze);

      final bronzeTournament = TournamentConfig.fromJson({
        'id': 'bronze_test',
        'name': 'Bronze Test',
        'description': 'Test',
        'tier': 'bronze',
        'status': 'active',
        'entry': {'type': 'coins', 'amount': 100},
        'tries': {'count': 3},
        'continues': {'max_per_try': 5, 'gem_cost': 3, 'ad_available': true},
        'levels': [],
        'completion_reward': {'coins': 500, 'gems': 20},
        'display': {'banner_image': 'test.png', 'background_color': '#FF0000'},
      });

      final silverTournament = TournamentConfig.fromJson({
        'id': 'silver_test',
        'name': 'Silver Test',
        'description': 'Test',
        'tier': 'silver',
        'status': 'active',
        'entry': {'type': 'coins', 'amount': 100},
        'tries': {'count': 3},
        'continues': {'max_per_try': 5, 'gem_cost': 3, 'ad_available': true},
        'levels': [],
        'completion_reward': {'coins': 500, 'gems': 20},
        'display': {'banner_image': 'test.png', 'background_color': '#FF0000'},
      });
      
      expect(manager.hasFreeTicketFor(bronzeTournament), true);
      expect(manager.hasFreeTicketFor(silverTournament), false);
    });
  });

  group('TournamentManager - Tournament Entry', () {
    late TournamentConfig testTournament;

    setUp(() {
      testTournament = TournamentConfig.fromJson({
        'id': 'test_entry',
        'name': 'Entry Test Tournament',
        'description': 'Test',
        'tier': 'bronze',
        'status': 'active',
        'entry': {'type': 'coins', 'amount': 100},
        'tries': {'count': 3},
        'continues': {'max_per_try': 5, 'gem_cost': 3, 'ad_available': true},
        'levels': [
          {
            'round': 1,
            'name': 'Round 1',
            'difficulty': {'speed': 1.0, 'gap': 200, 'frequency': 2.5},
            'reward': {'coins': 50, 'gems': 0},
          },
        ],
        'completion_reward': {'coins': 500, 'gems': 20},
        'display': {'banner_image': 'test.png', 'background_color': '#FF0000'},
      });
    });

    test('should create entry when entering tournament', () async {
      final manager = TournamentManager();
      
      final entry = await manager.enterTournament(
        testTournament,
        useFreeTicket: false,
      );
      
      expect(entry, isNotNull);
      expect(entry!.tournamentId, 'test_entry');
      expect(entry.tournamentName, 'Entry Test Tournament');
      expect(entry.totalTries, 3);
      expect(entry.triesRemaining, 3);
      expect(entry.status, TournamentEntryStatus.inProgress);
    });

    test('should set active entry after entering', () async {
      final manager = TournamentManager();
      
      await manager.enterTournament(testTournament, useFreeTicket: false);
      
      expect(manager.hasActiveEntry, true);
      expect(manager.activeEntry, isNotNull);
      expect(manager.activeEntry!.tournamentId, 'test_entry');
    });

    test('should use free ticket when entering with ticket', () async {
      final manager = TournamentManager();
      await manager.grantFreeTicket(TournamentTier.bronze);
      
      expect(manager.getFreeTickets(TournamentTier.bronze), 1);
      
      await manager.enterTournament(testTournament, useFreeTicket: true);
      
      expect(manager.getFreeTickets(TournamentTier.bronze), 0);
      expect(manager.hasActiveEntry, true);
    });

    test('should return null when entering with no ticket available', () async {
      final manager = TournamentManager();
      
      expect(manager.getFreeTickets(TournamentTier.bronze), 0);
      
      final entry = await manager.enterTournament(testTournament, useFreeTicket: true);
      
      expect(entry, isNull);
      expect(manager.hasActiveEntry, false);
    });

    test('should resume active entry', () async {
      final manager = TournamentManager();
      await manager.enterTournament(testTournament, useFreeTicket: false);
      
      final resumed = manager.resumeActiveEntry();
      
      expect(resumed, isNotNull);
      expect(resumed!.tournamentId, 'test_entry');
    });
  });

  group('TournamentManager - Round Completion', () {
    late TournamentConfig testTournament;

    setUp(() async {
      testTournament = TournamentConfig.fromJson({
        'id': 'round_test',
        'name': 'Round Test Tournament',
        'description': 'Test',
        'tier': 'bronze',
        'status': 'active',
        'entry': {'type': 'coins', 'amount': 100},
        'tries': {'count': 3},
        'continues': {'max_per_try': 5, 'gem_cost': 3, 'ad_available': true},
        'levels': [
          {
            'round': 1,
            'name': 'Round 1',
            'difficulty': {'speed': 1.0, 'gap': 200, 'frequency': 2.5},
            'reward': {'coins': 100, 'gems': 5},
          },
          {
            'round': 2,
            'name': 'Round 2',
            'difficulty': {'speed': 1.1, 'gap': 190, 'frequency': 2.3},
            'reward': {'coins': 200, 'gems': 10},
          },
        ],
        'completion_reward': {'coins': 500, 'gems': 20},
        'display': {'banner_image': 'test.png', 'background_color': '#FF0000'},
      });

      final manager = TournamentManager();
      await manager.enterTournament(testTournament, useFreeTicket: false);
    });

    test('should complete round and earn rewards', () async {
      final manager = TournamentManager();
      
      await manager.completeRound(
        roundNumber: 1,
        coinsReward: 100,
        gemsReward: 5,
        heartsUsed: 2,
        continuesUsed: 0,
        duration: const Duration(minutes: 2),
      );
      
      expect(manager.activeEntry!.coinsEarned, 100);
      expect(manager.activeEntry!.gemsEarned, 5);
      expect(manager.activeEntry!.roundResults, hasLength(1));
    });

    test('should accumulate rewards across rounds', () async {
      final manager = TournamentManager();
      
      await manager.completeRound(
        roundNumber: 1,
        coinsReward: 100,
        gemsReward: 5,
        heartsUsed: 1,
        continuesUsed: 0,
        duration: const Duration(minutes: 1),
      );
      
      await manager.completeRound(
        roundNumber: 2,
        coinsReward: 200,
        gemsReward: 10,
        heartsUsed: 2,
        continuesUsed: 1,
        duration: const Duration(minutes: 2),
      );
      
      expect(manager.activeEntry!.coinsEarned, 300);
      expect(manager.activeEntry!.gemsEarned, 15);
    });

    test('should track failed round', () async {
      final manager = TournamentManager();
      
      await manager.failRound(
        roundNumber: 1,
        heartsUsed: 3,
        continuesUsed: 5,
        duration: const Duration(minutes: 5),
      );
      
      expect(manager.activeEntry!.coinsEarned, 0);
      expect(manager.activeEntry!.roundResults, hasLength(1));
      expect(manager.activeEntry!.roundResults.first.success, false);
    });
  });

  group('TournamentManager - Continues', () {
    late TournamentConfig testTournament;

    setUp(() async {
      testTournament = TournamentConfig.fromJson({
        'id': 'continue_test',
        'name': 'Continue Test Tournament',
        'description': 'Test',
        'tier': 'bronze',
        'status': 'active',
        'entry': {'type': 'coins', 'amount': 100},
        'tries': {'count': 3},
        'continues': {'max_per_try': 5, 'gem_cost': 3, 'ad_available': true},
        'levels': [],
        'completion_reward': {'coins': 500, 'gems': 20},
        'display': {'banner_image': 'test.png', 'background_color': '#FF0000'},
      });

      final manager = TournamentManager();
      await manager.enterTournament(testTournament, useFreeTicket: false);
    });

    test('should track continue usage', () async {
      final manager = TournamentManager();
      
      await manager.useContinue();
      
      expect(manager.activeEntry!.continuesUsedThisTry, 1);
    });

    test('should track total continues across tries', () async {
      final manager = TournamentManager();
      
      await manager.useContinue();
      await manager.useContinue();
      
      expect(manager.activeEntry!.continuesUsedThisTry, 2);
      expect(manager.activeEntry!.totalContinuesUsed, 2);
    });
  });

  group('TournamentManager - Try Failure', () {
    late TournamentConfig testTournament;

    setUp(() async {
      testTournament = TournamentConfig.fromJson({
        'id': 'try_test',
        'name': 'Try Test Tournament',
        'description': 'Test',
        'tier': 'bronze',
        'status': 'active',
        'entry': {'type': 'coins', 'amount': 100},
        'tries': {'count': 3},
        'continues': {'max_per_try': 5, 'gem_cost': 3, 'ad_available': true},
        'levels': [],
        'completion_reward': {'coins': 500, 'gems': 20},
        'display': {'banner_image': 'test.png', 'background_color': '#FF0000'},
      });

      final manager = TournamentManager();
      await manager.enterTournament(testTournament, useFreeTicket: false);
    });

    test('should decrement tries on failure', () async {
      final manager = TournamentManager();
      
      expect(manager.activeEntry!.triesRemaining, 3);
      
      await manager.failCurrentTry();
      
      expect(manager.activeEntry!.triesRemaining, 2);
      expect(manager.activeEntry!.status, TournamentEntryStatus.inProgress);
    });

    test('should fail tournament after all tries exhausted', () async {
      final manager = TournamentManager();
      
      await manager.failCurrentTry();
      await manager.failCurrentTry();
      final status = await manager.failCurrentTry();
      
      expect(status, TournamentEntryStatus.failed);
      expect(manager.activeEntry!.triesRemaining, 0);
    });
  });

  group('TournamentManager - Tournament Completion', () {
    late TournamentConfig testTournament;

    setUp(() async {
      testTournament = TournamentConfig.fromJson({
        'id': 'complete_test',
        'name': 'Completion Test Tournament',
        'description': 'Test',
        'tier': 'bronze',
        'status': 'active',
        'entry': {'type': 'coins', 'amount': 100},
        'tries': {'count': 3},
        'continues': {'max_per_try': 5, 'gem_cost': 3, 'ad_available': true},
        'levels': [
          {
            'round': 1,
            'name': 'Round 1',
            'difficulty': {'speed': 1.0, 'gap': 200, 'frequency': 2.5},
            'reward': {'coins': 100, 'gems': 5},
          },
        ],
        'completion_reward': {'coins': 500, 'gems': 20},
        'display': {'banner_image': 'test.png', 'background_color': '#FF0000'},
      });

      final manager = TournamentManager();
      await manager.enterTournament(testTournament, useFreeTicket: false);
    });

    test('should complete tournament with bonus rewards', () async {
      final manager = TournamentManager();
      
      // Complete round first
      await manager.completeRound(
        roundNumber: 1,
        coinsReward: 100,
        gemsReward: 5,
        heartsUsed: 1,
        continuesUsed: 0,
        duration: const Duration(minutes: 1),
      );
      
      // Complete tournament
      await manager.completeTournament(bonusCoins: 500, bonusGems: 20);
      
      expect(manager.activeEntry!.status, TournamentEntryStatus.completed);
      expect(manager.activeEntry!.coinsEarned, 600); // 100 + 500
      expect(manager.activeEntry!.gemsEarned, 25); // 5 + 20
    });

    test('should add to completed tournaments set', () async {
      final manager = TournamentManager();
      
      await manager.completeTournament(bonusCoins: 500, bonusGems: 20);
      
      expect(manager.completedTournamentIds, contains('complete_test'));
    });

    test('should add to history on completion', () async {
      final manager = TournamentManager();
      
      await manager.completeTournament(bonusCoins: 500, bonusGems: 20);
      
      expect(manager.history, hasLength(1));
      expect(manager.history.first.success, true);
      expect(manager.history.first.tournamentId, 'complete_test');
    });
  });

  group('TournamentManager - Abandon', () {
    test('should abandon tournament', () async {
      final manager = TournamentManager();
      final testTournament = TournamentConfig.fromJson({
        'id': 'abandon_test',
        'name': 'Abandon Test',
        'description': 'Test',
        'tier': 'bronze',
        'status': 'active',
        'entry': {'type': 'coins', 'amount': 100},
        'tries': {'count': 3},
        'continues': {'max_per_try': 5, 'gem_cost': 3, 'ad_available': true},
        'levels': [],
        'completion_reward': {'coins': 500, 'gems': 20},
        'display': {'banner_image': 'test.png', 'background_color': '#FF0000'},
      });

      await manager.enterTournament(testTournament, useFreeTicket: false);
      
      await manager.abandonTournament();
      
      expect(manager.activeEntry!.status, TournamentEntryStatus.abandoned);
    });

    test('should add to history on abandon', () async {
      final manager = TournamentManager();
      final testTournament = TournamentConfig.fromJson({
        'id': 'abandon_history_test',
        'name': 'Abandon History Test',
        'description': 'Test',
        'tier': 'bronze',
        'status': 'active',
        'entry': {'type': 'coins', 'amount': 100},
        'tries': {'count': 3},
        'continues': {'max_per_try': 5, 'gem_cost': 3, 'ad_available': true},
        'levels': [],
        'completion_reward': {'coins': 500, 'gems': 20},
        'display': {'banner_image': 'test.png', 'background_color': '#FF0000'},
      });

      await manager.enterTournament(testTournament, useFreeTicket: false);
      await manager.abandonTournament();
      
      expect(manager.history, hasLength(1));
      expect(manager.history.first.success, false);
    });
  });

  group('TournamentManager - Extra Tries', () {
    test('should purchase extra tries after failure', () async {
      final manager = TournamentManager();
      final testTournament = TournamentConfig.fromJson({
        'id': 'extra_tries_test',
        'name': 'Extra Tries Test',
        'description': 'Test',
        'tier': 'bronze',
        'status': 'active',
        'entry': {'type': 'coins', 'amount': 100},
        'tries': {'count': 3},
        'continues': {'max_per_try': 5, 'gem_cost': 3, 'ad_available': true},
        'levels': [],
        'completion_reward': {'coins': 500, 'gems': 20},
        'display': {'banner_image': 'test.png', 'background_color': '#FF0000'},
      });

      await manager.enterTournament(testTournament, useFreeTicket: false);
      
      // Fail all tries
      await manager.failCurrentTry();
      await manager.failCurrentTry();
      await manager.failCurrentTry();
      
      expect(manager.activeEntry!.status, TournamentEntryStatus.failed);
      expect(manager.activeEntry!.triesRemaining, 0);
      
      // Purchase extra tries
      final success = await manager.purchaseExtraTries(
        extraTries: 2,
        cost: 100,
        costType: EntryFeeType.gems,
      );
      
      expect(success, true);
      expect(manager.activeEntry!.status, TournamentEntryStatus.inProgress);
      expect(manager.activeEntry!.triesRemaining, 2);
    });

    test('should not purchase extra tries if not failed', () async {
      final manager = TournamentManager();
      final testTournament = TournamentConfig.fromJson({
        'id': 'extra_tries_not_failed_test',
        'name': 'Extra Tries Not Failed Test',
        'description': 'Test',
        'tier': 'bronze',
        'status': 'active',
        'entry': {'type': 'coins', 'amount': 100},
        'tries': {'count': 3},
        'continues': {'max_per_try': 5, 'gem_cost': 3, 'ad_available': true},
        'levels': [],
        'completion_reward': {'coins': 500, 'gems': 20},
        'display': {'banner_image': 'test.png', 'background_color': '#FF0000'},
      });

      await manager.enterTournament(testTournament, useFreeTicket: false);
      
      // Try to purchase without failing
      final success = await manager.purchaseExtraTries(
        extraTries: 2,
        cost: 100,
        costType: EntryFeeType.gems,
      );
      
      expect(success, false);
    });
  });

  group('TournamentManager - Clear Active Entry', () {
    test('should clear active entry', () async {
      final manager = TournamentManager();
      final testTournament = TournamentConfig.fromJson({
        'id': 'clear_test',
        'name': 'Clear Test',
        'description': 'Test',
        'tier': 'bronze',
        'status': 'active',
        'entry': {'type': 'coins', 'amount': 100},
        'tries': {'count': 3},
        'continues': {'max_per_try': 5, 'gem_cost': 3, 'ad_available': true},
        'levels': [],
        'completion_reward': {'coins': 500, 'gems': 20},
        'display': {'banner_image': 'test.png', 'background_color': '#FF0000'},
      });

      await manager.enterTournament(testTournament, useFreeTicket: false);
      expect(manager.hasActiveEntry, true);
      
      await manager.clearActiveEntry();
      
      expect(manager.hasActiveEntry, false);
      expect(manager.activeEntry, isNull);
    });
  });

  group('TournamentHistoryEntry', () {
    test('should serialize and deserialize', () {
      final entry = TournamentHistoryEntry(
        tournamentId: 'test_history',
        tournamentName: 'Test History Tournament',
        completedAt: DateTime(2025, 1, 1, 12, 0),
        success: true,
        highestRound: 3,
        coinsEarned: 500,
        gemsEarned: 20,
        triesUsed: 2,
        continuesUsed: 3,
        duration: const Duration(minutes: 15),
      );

      final json = entry.toJson();
      final restored = TournamentHistoryEntry.fromJson(json);

      expect(restored.tournamentId, 'test_history');
      expect(restored.tournamentName, 'Test History Tournament');
      expect(restored.success, true);
      expect(restored.highestRound, 3);
      expect(restored.coinsEarned, 500);
      expect(restored.gemsEarned, 20);
      expect(restored.triesUsed, 2);
      expect(restored.continuesUsed, 3);
      expect(restored.duration.inMinutes, 15);
    });

    test('should have meaningful toString', () {
      final entry = TournamentHistoryEntry(
        tournamentId: 'test_history',
        tournamentName: 'Test Tournament',
        completedAt: DateTime.now(),
        success: true,
        highestRound: 5,
        coinsEarned: 1000,
        gemsEarned: 50,
        triesUsed: 1,
        continuesUsed: 0,
        duration: const Duration(minutes: 10),
      );

      final str = entry.toString();
      expect(str, contains('Test Tournament'));
      expect(str, contains('success: true'));
      expect(str, contains('highest_round: 5'));
    });
  });

  group('CanEnterResult', () {
    test('should have meaningful toString', () {
      const result = CanEnterResult(
        canEnter: true,
        reason: 'Sufficient coins',
        cost: 100,
        costType: EntryFeeType.coins,
      );

      final str = result.toString();
      expect(str, contains('canEnter: true'));
      expect(str, contains('Sufficient coins'));
    });
  });
}


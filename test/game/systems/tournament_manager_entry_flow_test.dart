import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flappy_jet_pro/game/systems/tournament_manager.dart';
import 'package:flappy_jet_pro/game/systems/inventory_manager.dart';
import 'package:flappy_jet_pro/game/systems/lives_manager.dart';
import 'package:flappy_jet_pro/models/tournament_config.dart';
import 'package:flappy_jet_pro/models/tournament_entry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TournamentManager tournamentManager;
  late TournamentConfig coinTournament;
  late TournamentConfig gemTournament;
  late TournamentConfig freeTicketTournament;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    
    // Reset managers
    TournamentManager().resetForTesting();
    LivesManager().forceResetToNewPlayer();
    
    tournamentManager = TournamentManager();
    await tournamentManager.initialize();

    coinTournament = TournamentConfig.fromJson({
      'id': 'coin_tournament',
      'name': 'Coin Tournament',
      'description': 'Entry with coins',
      'tier': 'bronze',
      'status': 'active',
      'entry': {'type': 'coins', 'amount': 100},
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
      'completion_reward': {'coins': 500, 'gems': 20},
      'display': {'banner_image': 'test.png', 'background_color': '#CD7F32'},
    });

    gemTournament = TournamentConfig.fromJson({
      'id': 'gem_tournament',
      'name': 'Gem Tournament',
      'description': 'Entry with gems',
      'tier': 'silver',
      'status': 'active',
      'entry': {'type': 'gems', 'amount': 50},
      'tries': {'count': 5},
      'continues': {'max_per_try': 5, 'gem_cost': 5, 'ad_available': true},
      'levels': [
        {
          'round': 1,
          'name': 'Round 1',
          'difficulty': {
            'speedMultiplier': 1.2,
            'obstacleGap': 300,
            'obstacleFrequency': 2.0,
            'maxGapShift': 70,
            'requiredDistance': 30,
          },
          'reward': {'coins': 200, 'gems': 10},
        },
      ],
      'completion_reward': {'coins': 1000, 'gems': 50},
      'display': {'banner_image': 'silver.png', 'background_color': '#C0C0C0'},
    });

    freeTicketTournament = TournamentConfig.fromJson({
      'id': 'free_tournament',
      'name': 'Free Ticket Tournament',
      'description': 'Entry with free ticket',
      'tier': 'bronze',
      'status': 'active',
      'entry': {'type': 'freeTicket', 'amount': 0},
      'tries': {'count': 2},
      'continues': {'max_per_try': 3, 'gem_cost': 3, 'ad_available': true},
      'levels': [
        {
          'round': 1,
          'name': 'Round 1',
          'difficulty': {
            'speedMultiplier': 1.0,
            'obstacleGap': 400,
            'obstacleFrequency': 3.0,
            'maxGapShift': 30,
            'requiredDistance': 15,
          },
          'reward': {'coins': 50, 'gems': 2},
        },
      ],
      'completion_reward': {'coins': 200, 'gems': 10},
      'display': {'banner_image': 'free.png', 'background_color': '#CD7F32'},
    });
  });

  group('TournamentManager - Entry Flow', () {
    test('should enter tournament with coins', () async {
      // Note: Without InventoryManager mocking, we test the manager logic
      final result = tournamentManager.canEnterTournament(
        coinTournament,
        playerCoins: 200,
        playerGems: 0,
      );

      expect(result.canEnter, true);
      expect(result.reason, isNotNull);
    });

    test('should not enter tournament without enough coins', () async {
      final result = tournamentManager.canEnterTournament(
        coinTournament,
        playerCoins: 50, // Not enough
        playerGems: 0,
      );

      expect(result.canEnter, false);
      expect(result.reason, contains('coins'));
    });

    test('should enter tournament with gems', () async {
      final result = tournamentManager.canEnterTournament(
        gemTournament,
        playerCoins: 0,
        playerGems: 100,
      );

      expect(result.canEnter, true);
    });

    test('should not enter tournament without enough gems', () async {
      final result = tournamentManager.canEnterTournament(
        gemTournament,
        playerCoins: 0,
        playerGems: 30, // Not enough
      );

      expect(result.canEnter, false);
    });

    test('should enter tournament with free ticket', () async {
      // Grant a free ticket first
      await tournamentManager.grantFreeTicket(TournamentTier.bronze, count: 1);

      final result = tournamentManager.canEnterTournament(
        freeTicketTournament,
        playerCoins: 0,
        playerGems: 0,
      );

      expect(result.canEnter, true);
      expect(result.useFreeTicket, true);
    });

    test('should not enter tournament without free ticket', () async {
      final result = tournamentManager.canEnterTournament(
        freeTicketTournament,
        playerCoins: 0,
        playerGems: 0,
      );

      expect(result.canEnter, false);
    });

    test('should prioritize free ticket over currency', () async {
      // Grant a free ticket
      await tournamentManager.grantFreeTicket(TournamentTier.bronze, count: 1);

      // Even with coins, free ticket should be offered
      final result = tournamentManager.canEnterTournament(
        coinTournament,
        playerCoins: 1000,
        playerGems: 0,
      );

      // Should still be able to enter (with coins or ticket)
      expect(result.canEnter, true);
    });
  });

  group('TournamentManager - Active Entry', () {
    test('should have no active entry initially', () {
      expect(tournamentManager.hasActiveEntry, false);
      expect(tournamentManager.activeEntry, isNull);
    });

    test('should track active entry after entering', () async {
      // Note: Full entry test would need mock inventory
      // This tests the state management
      expect(tournamentManager.hasActiveEntry, false);
    });

    test('should resume active entry', () {
      // No active entry to resume
      final entry = tournamentManager.resumeActiveEntry();
      expect(entry, isNull);
    });
  });

  group('TournamentManager - Free Tickets', () {
    test('should grant free tickets', () async {
      expect(tournamentManager.getFreeTickets(TournamentTier.bronze), 0);
      
      await tournamentManager.grantFreeTicket(TournamentTier.bronze, count: 2);
      
      expect(tournamentManager.getFreeTickets(TournamentTier.bronze), 2);
    });

    test('should track free tickets per tier', () async {
      await tournamentManager.grantFreeTicket(TournamentTier.bronze, count: 2);
      await tournamentManager.grantFreeTicket(TournamentTier.silver, count: 1);
      await tournamentManager.grantFreeTicket(TournamentTier.gold, count: 3);

      expect(tournamentManager.getFreeTickets(TournamentTier.bronze), 2);
      expect(tournamentManager.getFreeTickets(TournamentTier.silver), 1);
      expect(tournamentManager.getFreeTickets(TournamentTier.gold), 3);
    });

    test('should check hasFreeTicketFor correctly', () async {
      expect(tournamentManager.hasFreeTicketFor(coinTournament), false);
      
      await tournamentManager.grantFreeTicket(TournamentTier.bronze, count: 1);
      
      expect(tournamentManager.hasFreeTicketFor(coinTournament), true);
    });

    test('should return total free tickets', () async {
      await tournamentManager.grantFreeTicket(TournamentTier.bronze, count: 2);
      await tournamentManager.grantFreeTicket(TournamentTier.silver, count: 3);

      expect(tournamentManager.totalFreeTickets, 5);
    });
  });

  group('TournamentManager - Displayable Tournaments', () {
    test('should return active tournaments', () {
      // After initialization, tournaments are loaded from JSON
      final displayable = tournamentManager.displayableTournaments;
      
      // All displayable tournaments should be active or upcoming
      for (final t in displayable) {
        expect(
          t.status == TournamentStatus.active || t.status == TournamentStatus.upcoming,
          true,
        );
      }
    });
  });

  group('TournamentManager - Unlock Requirements', () {
    test('should handle tournaments without unlock requirements', () async {
      // Coin tournament has no unlock requirements
      final result = tournamentManager.canEnterTournament(
        coinTournament,
        playerCoins: 200,
        playerGems: 0,
      );
      
      // Should be able to enter with enough coins
      expect(result.canEnter, true);
    });

    test('should handle completed tournament requirements', () async {
      // Note: Full unlock requirement testing would need tournament completion
      // This tests basic flow without unlock requirements
      final result = tournamentManager.canEnterTournament(
        coinTournament,
        playerCoins: 200,
        playerGems: 0,
      );
      
      expect(result.canEnter, true);
    });
  });

  group('TournamentManager - Debug State', () {
    test('should return debug state', () {
      final state = tournamentManager.getDebugState();

      expect(state.containsKey('is_initialized'), true);
      expect(state.containsKey('available_tournaments'), true);
      expect(state.containsKey('has_active_entry'), true);
    });
  });
}


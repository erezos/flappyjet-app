import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flappy_jet_pro/game/systems/tournament_manager.dart';
import 'package:flappy_jet_pro/game/systems/game_events_tracker.dart';
import 'package:flappy_jet_pro/ui/widgets/tournament/linear_tournament_game_wrapper.dart';

import '../../../helpers/mock_managers.dart';

class MockTournamentManager extends Mock implements TournamentManager {}

class MockGameEventsTracker extends Mock implements GameEventsTracker {}

void main() {

  group('Linear tournament continues', () {
    test('ad continue adds one heart and tracks continue', () async {
      final monetization = MockMonetizationManager();
      final lives = MockLivesManager();
      final tournamentManager = MockTournamentManager();
      final eventsTracker = MockGameEventsTracker();

      when(() => tournamentManager.useContinue(tournamentId: any(named: 'tournamentId')))
          .thenAnswer((_) async {});
      when(() => lives.addLife(any())).thenAnswer((_) async {});
      when(() => eventsTracker.onContinueUsed(gemsCost: any(named: 'gemsCost')))
          .thenAnswer((_) async {});

      var continued = false;

      final rewarded = await runRewardedContinueForLinearTournament(
        monetizationManager: monetization,
        livesManager: lives,
        tournamentManager: tournamentManager,
        tournamentId: 'stunt_tournament',
        eventsTracker: eventsTracker,
        onAdStart: () {},
        onAdEnd: () {},
        onContinue: () async {
          continued = true;
        },
      );

      expect(rewarded, isTrue);
      expect(continued, isTrue);
      verify(() => tournamentManager.useContinue(tournamentId: 'stunt_tournament')).called(1);
      verify(() => lives.addLife(1)).called(1);
      verify(() => eventsTracker.onContinueUsed(gemsCost: 0)).called(1);
    });

    test('ad continue handles ad failure without granting reward', () async {
      final monetization = MockMonetizationManager();
      final lives = MockLivesManager();
      final tournamentManager = MockTournamentManager();
      final eventsTracker = MockGameEventsTracker();

      // Override behavior to simulate ad failure (no reward)
      when(() => monetization.showRewardedAdForExtraLife(
            onAdStart: any(named: 'onAdStart'),
            onAdEnd: any(named: 'onAdEnd'),
            onReward: any(named: 'onReward'),
            onAdLoading: any(named: 'onAdLoading'),
            onAdFailure: any(named: 'onAdFailure'),
          )).thenAnswer((invocation) async {
        final failure = invocation.namedArguments[#onAdFailure] as VoidCallback?;
        failure?.call();
      });

      final rewarded = await runRewardedContinueForLinearTournament(
        monetizationManager: monetization,
        livesManager: lives,
        tournamentManager: tournamentManager,
        tournamentId: 'stunt_tournament',
        eventsTracker: eventsTracker,
        onAdStart: () {},
        onAdEnd: () {},
        onContinue: () async {},
      );

      expect(rewarded, isFalse);
      verifyNever(() => tournamentManager.useContinue(tournamentId: any(named: 'tournamentId')));
      verifyNever(() => lives.addLife(any()));
      verifyNever(() => eventsTracker.onContinueUsed(gemsCost: any(named: 'gemsCost')));
    });

    test('gem continue spends gems, adds one heart, and tracks continue', () async {
      final inventory = MockInventoryManager();
      final lives = MockLivesManager();
      final tournamentManager = MockTournamentManager();
      final eventsTracker = MockGameEventsTracker();

      when(() => inventory.spendGems(any(), spentOn: any(named: 'spentOn'), itemId: any(named: 'itemId')))
          .thenAnswer((_) async => true);
      when(() => tournamentManager.useContinue(tournamentId: any(named: 'tournamentId')))
          .thenAnswer((_) async {});
      when(() => lives.addLife(any())).thenAnswer((_) async {});
      when(() => eventsTracker.onContinueUsed(gemsCost: any(named: 'gemsCost')))
          .thenAnswer((_) async {});

      final success = await runGemContinueForLinearTournament(
        inventoryManager: inventory,
        livesManager: lives,
        tournamentManager: tournamentManager,
        tournamentId: 'stunt_tournament',
        eventsTracker: eventsTracker,
        gemCost: 3,
      );

      expect(success, isTrue);
      verify(() => inventory.spendGems(3, spentOn: any(named: 'spentOn'), itemId: any(named: 'itemId'))).called(1);
      verify(() => tournamentManager.useContinue(tournamentId: 'stunt_tournament')).called(1);
      verify(() => lives.addLife(1)).called(1);
      verify(() => eventsTracker.onContinueUsed(gemsCost: 3)).called(1);
    });

    test('gem continue aborts when not enough gems', () async {
      final inventory = MockInventoryManager();
      final lives = MockLivesManager();
      final tournamentManager = MockTournamentManager();
      final eventsTracker = MockGameEventsTracker();

      when(() => inventory.spendGems(any(), spentOn: any(named: 'spentOn'), itemId: any(named: 'itemId')))
          .thenAnswer((_) async => false);

      final success = await runGemContinueForLinearTournament(
        inventoryManager: inventory,
        livesManager: lives,
        tournamentManager: tournamentManager,
        tournamentId: 'stunt_tournament',
        eventsTracker: eventsTracker,
        gemCost: 5,
      );

      expect(success, isFalse);
      verify(() => inventory.spendGems(5, spentOn: any(named: 'spentOn'), itemId: any(named: 'itemId'))).called(1);
      verifyNever(() => tournamentManager.useContinue(tournamentId: any(named: 'tournamentId')));
      verifyNever(() => lives.addLife(any()));
      verifyNever(() => eventsTracker.onContinueUsed(gemsCost: any(named: 'gemsCost')));
    });
  });
}


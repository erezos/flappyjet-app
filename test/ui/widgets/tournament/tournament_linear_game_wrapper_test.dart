import 'package:flappy_jet_pro/models/tournament_config.dart';
import 'package:flappy_jet_pro/ui/widgets/tournament/tournament_linear_game_wrapper.dart';
import 'package:flappy_jet_pro/models/tournament_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

TournamentConfig _stubTournament() {
  return TournamentConfig(
    id: 'stunt_tournament',
    name: 'Stunt',
    description: 'desc',
    tier: TournamentTier.silver,
    status: TournamentStatus.active,
    progressionType: TournamentProgressionType.linear,
    entry: TournamentEntryConfig(type: EntryFeeType.coins, amount: 0, freeTicketTier: TournamentTier.silver),
    tries: const TournamentTriesConfig(count: 3),
    continues: const TournamentContinuesConfig(maxPerTry: 5, gemCost: 3, adAvailable: true),
    levels: [
      TournamentLevel(
        round: 1,
        name: 'Stage 1',
        background: 'bg',
        opponentJet: null,
        difficulty: const TournamentDifficulty(
          speedMultiplier: 1.0,
          obstacleGap: 380,
          obstacleFrequency: 2.5,
          maxGapShift: 50,
          requiredDistance: 1,
        ),
        obstaclePatterns: const [],
        reward: const TournamentReward(coins: 100, gems: 2),
      ),
    ],
    completionReward: const TournamentReward(coins: 1000, gems: 10),
    display: const TournamentDisplay(
      bannerImage: 'banner',
      icon: 'icon',
      colorPrimary: '#FFFFFF',
      colorSecondary: '#000000',
    ),
  );
}

void main() {
  testWidgets('renders linear wrapper and HUD', (tester) async {
    final tournament = _stubTournament();
    bool winCalled = false;
    bool loseCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: TournamentLinearGameWrapper(
          tournament: tournament,
          entry: TournamentEntry.start(
            tournamentId: 'stunt_tournament',
            tournamentName: 'Stunt',
            totalTries: 3,
          ),
          levelConfig: tournament.levels.first,
          onWin: () => winCalled = true,
          onLose: () => loseCalled = true,
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Stage 1'), findsOneWidget);
    expect(winCalled || loseCalled, false);
  });
}


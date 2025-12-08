import 'package:flappy_jet_pro/models/tournament_config.dart';
import 'package:flappy_jet_pro/ui/screens/tournament_world_map_screen.dart';
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
    levels: List.generate(
      5,
      (i) => TournamentLevel(
        round: i + 1,
        name: 'Stage ${i + 1}',
        background: 'bg',
        opponentJet: null,
        difficulty: TournamentDifficulty(
          speedMultiplier: 1.0,
          obstacleGap: 380,
          obstacleFrequency: 2.5,
          maxGapShift: 50,
          requiredDistance: 50,
        ),
        obstaclePatterns: const [],
        reward: const TournamentReward(coins: 100, gems: 2),
      ),
    ),
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
  testWidgets('shows nodes and play button', (tester) async {
    final tournament = _stubTournament();

    await tester.pumpWidget(
      MaterialApp(
        home: TournamentWorldMapScreen(
          tournament: tournament,
          entrySummary: const TournamentEntrySummary(
            currentRound: 2,
            totalRounds: 5,
            triesRemaining: 2,
          ),
          onPlayLevel: () {},
          onBack: () {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Nodes labels
    expect(find.text('Stage 1'), findsOneWidget);
    expect(find.text('Stage 2'), findsOneWidget);
    // Play CTA
    expect(find.text('PLAY'), findsOneWidget);
  });
}


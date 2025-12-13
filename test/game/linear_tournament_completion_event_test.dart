import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/models/tournament_config.dart';
import 'package:flappy_jet_pro/models/tournament_entry.dart';
import 'package:flappy_jet_pro/ui/widgets/tournament/linear_tournament_completion_payload.dart';

void main() {
  group('LinearTournamentGameWrapper.buildCompletionEventPayload', () {
    test('includes tournament, level, rewards, and usage fields', () {
      final tournament = TournamentConfig(
        id: 'stunt_tournament',
        name: 'Stunt Tournament',
        description: 'desc',
        tier: TournamentTier.silver,
        status: TournamentStatus.active,
        progressionType: TournamentProgressionType.linear,
        entry: const TournamentEntryConfig(type: EntryFeeType.coins, amount: 100, freeTicketTier: null),
        tries: const TournamentTriesConfig(count: 3),
        continues: const TournamentContinuesConfig(maxPerTry: 3, gemCost: 5, adAvailable: true),
        levels: const [
          TournamentLevel(
            round: 1,
            name: 'Level 1',
            background: 'bg.png',
            difficulty: TournamentDifficulty(
              speedMultiplier: 1.0,
              obstacleGap: 300,
              obstacleFrequency: 2.0,
              maxGapShift: 40,
              requiredDistance: 50,
            ),
            obstaclePatterns: [],
            reward: TournamentReward(coins: 120, gems: 4),
          ),
        ],
        completionReward: const TournamentReward(coins: 1000, gems: 20),
        display: const TournamentDisplay(
          bannerImage: 'banner.png',
          icon: 'icon',
          colorPrimary: '#FF6B35',
          colorSecondary: '#F7931E',
        ),
      );

      final entry = TournamentEntry(
        id: 'entry',
        tournamentId: tournament.id,
        tournamentName: tournament.name,
        startedAt: DateTime.now(),
        totalTries: 3,
        currentTry: 1,
        currentRound: 1,
        triesRemaining: 3,
        continuesUsedThisTry: 0,
        totalContinuesUsed: 0,
        coinsEarned: 0,
        gemsEarned: 0,
        roundResults: const [],
        bracketWinners: const {},
        bracketJetOrder: const [],
      );

      final payload = buildLinearTournamentCompletionPayload(
        tournament: tournament,
        entry: entry,
        duration: const Duration(seconds: 75),
        heartsUsed: 2,
        continuesUsed: 1,
        level: tournament.levels.first,
      );

      expect(payload['tournament_id'], tournament.id);
      expect(payload['tournament_name'], tournament.name);
      expect(payload['level_number'], entry.currentRound);
      expect(payload['duration_seconds'], 75);
      expect(payload['continues_used'], 1);
      expect(payload['hearts_used'], 2);
      expect(payload['reward_coins'], 120);
      expect(payload['reward_gems'], 4);
    });
  });
}


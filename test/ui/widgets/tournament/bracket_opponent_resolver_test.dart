import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/models/tournament_config.dart';
import 'package:flappy_jet_pro/models/tournament_entry.dart';
import 'package:flappy_jet_pro/ui/widgets/tournament/bracket_opponent_resolver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PlayoffBracketConfig playoffConfig;
  late TournamentEntry entry;

  setUp(() {
    // Create a test playoff config
    playoffConfig = PlayoffBracketConfig(
      totalOpponents: 8,
      opponentJetSkins: ['defender', 'red_alert', 'stealth_bomber', 'diamond_storm', 'stealth_fire', 'space_destroyer', 'supreme_commander'],
      rounds: [
        PlayoffRound(
          roundNumber: 1,
          stageName: 'Quarter Finals',
          opponentJet: 'defender',
          displayName: 'Defender',
          opponentNickname: 'The Iron Shield',
        ),
        PlayoffRound(
          roundNumber: 2,
          stageName: 'Semi Finals',
          opponentJet: 'red_alert', // This should be overridden by bracket state
          displayName: 'Red Alert',
          opponentNickname: 'The Crimson Fury',
        ),
        PlayoffRound(
          roundNumber: 3,
          stageName: 'Grand Finals',
          opponentJet: 'space_destroyer', // This should be overridden by bracket state
          displayName: 'Space Destroyer',
          opponentNickname: 'The Cosmic Overlord',
        ),
      ],
    );

    // Create a test entry with bracket state
    entry = TournamentEntry(
      id: 'test_entry',
      tournamentId: 'bosses_showdown',
      tournamentName: 'Bosses Showdown',
      startedAt: DateTime.now(),
      totalTries: 3,
      currentTry: 1,
      currentRound: 1,
      triesRemaining: 3,
      bracketJetOrder: [
        'sky_rookie', // Player at position 0
        'defender',   // Player's QF opponent at position 1
        'stealth_bomber', // Position 2 - Match 1
        'diamond_storm',  // Position 3 - Match 1
        'stealth_fire',   // Position 4 - Match 2
        'space_destroyer', // Position 5 - Match 2
        'supreme_commander', // Position 6 - Match 3
        'red_alert',       // Position 7 - Match 3
      ],
      bracketWinners: {},
    );
  });

  group('BracketOpponentResolver', () {
    test('Round 1 - should return position 1 opponent (defender)', () {
      final opponent = BracketOpponentResolver.resolveOpponent(
        currentRound: 1,
        entry: entry,
        playoffConfig: playoffConfig,
        playerSkinId: 'sky_rookie',
      );

      expect(opponent, isNotNull);
      expect(opponent!.skinId, equals('defender'));
    });

    test('Round 2 - should return winner of Match 1 (not hardcoded red_alert)', () {
      // Simulate Round 1 completion - player won match 0
      entry.bracketWinners['round_1_match_0'] = 'sky_rookie';
      
      // Simulate Match 1 (pos 2 vs pos 3) - stealth_bomber won
      entry.bracketWinners['round_1_match_1'] = 'stealth_bomber';
      
      final opponent = BracketOpponentResolver.resolveOpponent(
        currentRound: 2,
        entry: entry,
        playoffConfig: playoffConfig,
        playerSkinId: 'sky_rookie',
      );

      expect(opponent, isNotNull);
      // Should be stealth_bomber (winner of match 1), NOT red_alert from config
      expect(opponent!.skinId, equals('stealth_bomber'));
    });

    test('Round 2 - should use diamond_storm if that jet won Match 1', () {
      entry.bracketWinners['round_1_match_0'] = 'sky_rookie';
      entry.bracketWinners['round_1_match_1'] = 'diamond_storm'; // Different winner
      
      final opponent = BracketOpponentResolver.resolveOpponent(
        currentRound: 2,
        entry: entry,
        playoffConfig: playoffConfig,
        playerSkinId: 'sky_rookie',
      );

      expect(opponent, isNotNull);
      expect(opponent!.skinId, equals('diamond_storm'));
    });

    test('Round 3 - should return winner of Semi Match 1', () {
      // All Round 1 matches resolved
      entry.bracketWinners['round_1_match_0'] = 'sky_rookie';
      entry.bracketWinners['round_1_match_1'] = 'stealth_bomber';
      entry.bracketWinners['round_1_match_2'] = 'stealth_fire';
      entry.bracketWinners['round_1_match_3'] = 'supreme_commander';
      
      // Semi finals resolved - player won their semi, other semi result:
      entry.bracketWinners['round_2_match_0'] = 'sky_rookie';
      entry.bracketWinners['round_2_match_1'] = 'stealth_fire'; // Winner of semi 1
      
      final opponent = BracketOpponentResolver.resolveOpponent(
        currentRound: 3,
        entry: entry,
        playoffConfig: playoffConfig,
        playerSkinId: 'sky_rookie',
      );

      expect(opponent, isNotNull);
      // Should be stealth_fire (winner of semi 1), NOT space_destroyer from config
      expect(opponent!.skinId, equals('stealth_fire'));
    });

    test('should fall back to config when bracket state is empty', () {
      // Empty bracket order - should fall back to config
      final emptyEntry = TournamentEntry(
        id: 'test_empty',
        tournamentId: 'bosses_showdown',
        tournamentName: 'Bosses Showdown',
        startedAt: DateTime.now(),
        totalTries: 3,
        currentTry: 1,
        currentRound: 2,
        triesRemaining: 3,
        bracketJetOrder: [], // Empty!
        bracketWinners: {},
      );

      final opponent = BracketOpponentResolver.resolveOpponent(
        currentRound: 2,
        entry: emptyEntry,
        playoffConfig: playoffConfig,
        playerSkinId: 'sky_rookie',
      );

      expect(opponent, isNotNull);
      // Falls back to config value
      expect(opponent!.skinId, equals('red_alert'));
    });

    test('ResolvedOpponent should have correct display name', () {
      final opponent = BracketOpponentResolver.resolveOpponent(
        currentRound: 1,
        entry: entry,
        playoffConfig: playoffConfig,
        playerSkinId: 'sky_rookie',
      );

      expect(opponent, isNotNull);
      expect(opponent!.displayName, equals('Defender'));
    });
  });
}


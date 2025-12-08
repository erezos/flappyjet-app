import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/models/tournament_config.dart';
import 'package:flappy_jet_pro/ui/widgets/tournament/playoff_bracket_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TournamentConfig playoffTournament3Rounds;
  late TournamentConfig linearTournament;

  setUp(() {
    // 3-round playoff tournament (8 opponents)
    playoffTournament3Rounds = TournamentConfig(
      id: 'test_playoff',
      name: 'Boss Showdown',
      description: 'Test playoff tournament',
      tier: TournamentTier.gold,
      status: TournamentStatus.active,
      progressionType: TournamentProgressionType.playoff,
      entry: const TournamentEntryConfig(type: EntryFeeType.freeTicket, amount: 0),
      tries: const TournamentTriesConfig(count: 3),
      continues: const TournamentContinuesConfig(
        maxPerTry: 5,
        gemCost: 3,
        adAvailable: true,
      ),
      levels: [
        TournamentLevel(
          round: 1,
          name: 'Quarter Finals',
          background: 'space',
          opponentJet: 'iron_shield',
          difficulty: const TournamentDifficulty(
            speedMultiplier: 1.0,
            obstacleGap: 150,
            obstacleFrequency: 1.0,
            maxGapShift: 30,
            requiredDistance: 50,
          ),
          obstaclePatterns: [],
          reward: const TournamentReward(coins: 100, gems: 5),
        ),
        TournamentLevel(
          round: 2,
          name: 'Semi Finals',
          background: 'space',
          opponentJet: 'crimson_fury',
          difficulty: const TournamentDifficulty(
            speedMultiplier: 1.2,
            obstacleGap: 140,
            obstacleFrequency: 1.2,
            maxGapShift: 40,
            requiredDistance: 60,
          ),
          obstaclePatterns: [],
          reward: const TournamentReward(coins: 200, gems: 10),
        ),
        TournamentLevel(
          round: 3,
          name: 'Grand Finals',
          background: 'space',
          opponentJet: 'cosmic_overlord',
          difficulty: const TournamentDifficulty(
            speedMultiplier: 1.5,
            obstacleGap: 130,
            obstacleFrequency: 1.5,
            maxGapShift: 50,
            requiredDistance: 70,
          ),
          obstaclePatterns: [],
          reward: const TournamentReward(coins: 300, gems: 15),
        ),
      ],
      completionReward: const TournamentReward(coins: 1000, gems: 50),
      display: const TournamentDisplay(
        bannerImage: 'test_banner',
        icon: '🏆',
        colorPrimary: '#FFD700',
      ),
      playoffConfig: PlayoffBracketConfig(
        totalOpponents: 8,
        opponentJetSkins: ['iron_shield', 'crimson_fury', 'cosmic_overlord', 'jet_1', 'jet_2', 'jet_3', 'jet_4'],
        rounds: [
          PlayoffRound(
            roundNumber: 1,
            stageName: 'Quarter Finals',
            opponentJet: 'iron_shield',
            displayName: 'Iron Shield',
            opponentNickname: 'The Impenetrable',
          ),
          PlayoffRound(
            roundNumber: 2,
            stageName: 'Semi Finals',
            opponentJet: 'crimson_fury',
            displayName: 'Crimson Fury',
            opponentNickname: 'The Red Menace',
          ),
          PlayoffRound(
            roundNumber: 3,
            stageName: 'Grand Finals',
            opponentJet: 'cosmic_overlord',
            displayName: 'Cosmic Overlord',
            opponentNickname: 'The Final Boss',
          ),
        ],
      ),
    );

    // Linear tournament (non-playoff)
    linearTournament = TournamentConfig(
      id: 'test_linear',
      name: 'Stunt Championship',
      description: 'Test linear tournament',
      tier: TournamentTier.silver,
      status: TournamentStatus.active,
      progressionType: TournamentProgressionType.linear,
      entry: const TournamentEntryConfig(type: EntryFeeType.coins, amount: 500),
      tries: const TournamentTriesConfig(count: 5),
      continues: const TournamentContinuesConfig(
        maxPerTry: 3,
        gemCost: 3,
        adAvailable: true,
      ),
      levels: [
        TournamentLevel(
          round: 1,
          name: 'Level 1',
          background: 'city',
          difficulty: const TournamentDifficulty(
            speedMultiplier: 1.0,
            obstacleGap: 150,
            obstacleFrequency: 1.0,
            maxGapShift: 30,
            requiredDistance: 50,
          ),
          obstaclePatterns: [],
          reward: const TournamentReward(coins: 50),
        ),
        TournamentLevel(
          round: 2,
          name: 'Level 2',
          background: 'city',
          difficulty: const TournamentDifficulty(
            speedMultiplier: 1.1,
            obstacleGap: 145,
            obstacleFrequency: 1.1,
            maxGapShift: 35,
            requiredDistance: 55,
          ),
          obstaclePatterns: [],
          reward: const TournamentReward(coins: 75),
        ),
      ],
      completionReward: const TournamentReward(coins: 500, gems: 20),
      display: const TournamentDisplay(
        bannerImage: 'test_banner',
        icon: '🎮',
        colorPrimary: '#C0C0C0',
      ),
    );
  });

  Widget buildTestWidget({
    required TournamentConfig tournament,
    int currentRound = 1,
    VoidCallback? onPlay,
    VoidCallback? onBack,
  }) {
    return MaterialApp(
      home: PlayoffBracketScreen(
        tournament: tournament,
        currentRound: currentRound,
        onPlay: onPlay ?? () {},
        onBack: onBack ?? () {},
      ),
    );
  }

  group('PlayoffBracketScreen - Basic Rendering', () {
    testWidgets('should display tournament name', (tester) async {
      await tester.pumpWidget(buildTestWidget(tournament: playoffTournament3Rounds));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('BOSS SHOWDOWN'), findsOneWidget);
    });

    testWidgets('should display round name', (tester) async {
      await tester.pumpWidget(buildTestWidget(tournament: playoffTournament3Rounds));
      await tester.pump(const Duration(seconds: 1));

      // Round label contains "QUARTER FINALS"
      expect(find.textContaining('QUARTER FINALS'), findsWidgets);
    });

    testWidgets('should display GRAND PRIZE text', (tester) async {
      await tester.pumpWidget(buildTestWidget(tournament: playoffTournament3Rounds));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('GRAND PRIZE'), findsOneWidget);
    });

    testWidgets('should display back button', (tester) async {
      await tester.pumpWidget(buildTestWidget(tournament: playoffTournament3Rounds));
      await tester.pump(const Duration(seconds: 1));

      expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
    });

    testWidgets('should call onBack when back button tapped', (tester) async {
      bool backCalled = false;
      await tester.pumpWidget(buildTestWidget(
        tournament: playoffTournament3Rounds,
        onBack: () => backCalled = true,
      ));
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pump();

      expect(backCalled, isTrue);
    });
  });

  group('PlayoffBracketScreen - Play Button', () {
    testWidgets('should display PLAY button in round 1', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        tournament: playoffTournament3Rounds,
        currentRound: 1,
      ));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('PLAY'), findsOneWidget);
    });

    testWidgets('should display PLAY button in round 2', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        tournament: playoffTournament3Rounds,
        currentRound: 2,
      ));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('PLAY'), findsOneWidget);
    });

    testWidgets('should display PLAY button in round 3', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        tournament: playoffTournament3Rounds,
        currentRound: 3,
      ));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('PLAY'), findsOneWidget);
    });

    testWidgets('should call onPlay when PLAY button tapped', (tester) async {
      bool playCalled = false;
      await tester.pumpWidget(buildTestWidget(
        tournament: playoffTournament3Rounds,
        onPlay: () => playCalled = true,
      ));
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('PLAY'));
      await tester.pump();

      expect(playCalled, isTrue);
    });
  });

  group('PlayoffBracketScreen - Champion State', () {
    testWidgets('should show CHAMPION text when round > totalRounds', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        tournament: playoffTournament3Rounds,
        currentRound: 4, // Past final round
      ));
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('CHAMPION'), findsWidgets);
    });

    testWidgets('should show CLAIM TROPHY button when champion', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        tournament: playoffTournament3Rounds,
        currentRound: 4,
      ));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('CLAIM TROPHY!'), findsOneWidget);
    });
  });

  group('PlayoffBracketScreen - Round Progression', () {
    testWidgets('should show QUARTER FINALS in round 1', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        tournament: playoffTournament3Rounds,
        currentRound: 1,
      ));
      await tester.pump(const Duration(seconds: 1));

      // "QUARTER FINALS" appears in round label and "OTHER QUARTER FINALS" section
      expect(find.textContaining('QUARTER FINALS'), findsWidgets);
    });

    testWidgets('should show SEMI FINALS in round 2', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        tournament: playoffTournament3Rounds,
        currentRound: 2,
      ));
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('SEMI FINALS'), findsOneWidget);
    });

    testWidgets('should show GRAND FINALS in round 3', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        tournament: playoffTournament3Rounds,
        currentRound: 3,
      ));
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('GRAND FINALS'), findsOneWidget);
    });
  });

  group('PlayoffBracketScreen - VS Matches', () {
    testWidgets('should display VS badge for current match', (tester) async {
      await tester.pumpWidget(buildTestWidget(tournament: playoffTournament3Rounds));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('VS'), findsWidgets);
    });

    testWidgets('should display match cards', (tester) async {
      await tester.pumpWidget(buildTestWidget(tournament: playoffTournament3Rounds));
      await tester.pump(const Duration(seconds: 1));

      // Match cards use Container widgets
      expect(find.byType(Container), findsWidgets);
    });
  });

  group('PlayoffBracketScreen - Vertical Layout', () {
    testWidgets('should use SingleChildScrollView for vertical scrolling', (tester) async {
      await tester.pumpWidget(buildTestWidget(tournament: playoffTournament3Rounds));
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('should display trophy section at top', (tester) async {
      await tester.pumpWidget(buildTestWidget(tournament: playoffTournament3Rounds));
      await tester.pump(const Duration(seconds: 1));

      // Trophy section should have GRAND PRIZE text
      expect(find.text('GRAND PRIZE'), findsOneWidget);
    });

    testWidgets('should display current match prominently', (tester) async {
      await tester.pumpWidget(buildTestWidget(tournament: playoffTournament3Rounds));
      await tester.pump(const Duration(seconds: 1));

      // Current match has VS badge
      expect(find.text('VS'), findsWidgets);
    });
  });

  group('PlayoffBracketScreen - Rewards Display', () {
    testWidgets('should display round rewards', (tester) async {
      await tester.pumpWidget(buildTestWidget(tournament: playoffTournament3Rounds));
      await tester.pump(const Duration(seconds: 1));

      // Round 1 rewards: 100 coins, 5 gems
      expect(find.textContaining('+100'), findsOneWidget);
      expect(find.textContaining('+5'), findsOneWidget);
    });

    testWidgets('should display grand prize coins', (tester) async {
      await tester.pumpWidget(buildTestWidget(tournament: playoffTournament3Rounds));
      await tester.pump(const Duration(seconds: 1));

      // Grand prize: 1000 coins, 50 gems
      expect(find.text('1000'), findsOneWidget);
      expect(find.text('50'), findsOneWidget);
    });
  });

  group('PlayoffBracketScreen - No Playoff Config', () {
    testWidgets('should show error when no playoff config', (tester) async {
      await tester.pumpWidget(buildTestWidget(tournament: linearTournament));
      await tester.pump(const Duration(seconds: 1));

      // Should show error state
      expect(find.text('Bracket not available'), findsOneWidget);
      expect(find.text('Go Back'), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flappy_jet_pro/ui/widgets/tournament/tournament_round_failed_popup.dart';
import 'package:flappy_jet_pro/ui/widgets/tournament/tournament_round_complete_popup.dart';
import 'package:flappy_jet_pro/models/tournament_config.dart';
import 'package:flappy_jet_pro/models/tournament_entry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TournamentConfig testTournament;
  late TournamentEntry testEntry;

  setUp(() {
    SharedPreferences.setMockInitialValues({});

    testTournament = TournamentConfig.fromJson({
      'id': 'test_tournament',
      'name': 'Test Tournament',
      'description': 'A test tournament',
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
      ],
      'completion_reward': {'coins': 500, 'gems': 20},
      'display': {'banner_image': 'test.png', 'background_color': '#CD7F32'},
    });

    testEntry = TournamentEntry.start(
      tournamentId: testTournament.id,
      tournamentName: testTournament.name,
      totalTries: testTournament.tries.count,
    );
  });

  group('TournamentRoundFailedPopup', () {
    testWidgets('should display round failed title', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TournamentRoundFailedPopup(
            tournament: testTournament,
            entry: testEntry,
            obstaclesPassed: 15,
            obstacleTarget: 20,
            canContinue: true,
            continuesRemaining: 5,
            playerGems: 100,
            gemCost: 3,
            onRetry: () {},
            onQuit: () {},
          ),
        ),
      ));

      expect(find.text('ROUND FAILED'), findsOneWidget);
    });

    testWidgets('should display progress', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TournamentRoundFailedPopup(
            tournament: testTournament,
            entry: testEntry,
            obstaclesPassed: 15,
            obstacleTarget: 20,
            canContinue: false,
            continuesRemaining: 0,
            playerGems: 100,
            gemCost: 3,
            onRetry: () {},
            onQuit: () {},
          ),
        ),
      ));

      expect(find.text('15 / 20'), findsOneWidget);
    });

    testWidgets('should show continue options when available', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TournamentRoundFailedPopup(
            tournament: testTournament,
            entry: testEntry,
            obstaclesPassed: 15,
            obstacleTarget: 20,
            canContinue: true,
            continuesRemaining: 3,
            playerGems: 100,
            gemCost: 3,
            onContinueWithAd: () {},
            onContinueWithGems: () {},
            onRetry: () {},
            onQuit: () {},
          ),
        ),
      ));

      expect(find.textContaining('Continue?'), findsOneWidget);
      expect(find.text('AD'), findsOneWidget);
      expect(find.text('3'), findsAtLeastNWidgets(1)); // Gem cost
    });

    testWidgets('should hide continue options when not available', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TournamentRoundFailedPopup(
            tournament: testTournament,
            entry: testEntry,
            obstaclesPassed: 15,
            obstacleTarget: 20,
            canContinue: false,
            continuesRemaining: 0,
            playerGems: 100,
            gemCost: 3,
            onRetry: () {},
            onQuit: () {},
          ),
        ),
      ));

      expect(find.textContaining('Continue?'), findsNothing);
    });

    testWidgets('should display tries remaining', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TournamentRoundFailedPopup(
            tournament: testTournament,
            entry: testEntry,
            obstaclesPassed: 15,
            obstacleTarget: 20,
            canContinue: false,
            continuesRemaining: 0,
            playerGems: 100,
            gemCost: 3,
            onRetry: () {},
            onQuit: () {},
          ),
        ),
      ));

      expect(find.textContaining('tries remaining'), findsOneWidget);
    });

    testWidgets('should call onRetry when USE TRY tapped', (tester) async {
      bool retried = false;
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TournamentRoundFailedPopup(
            tournament: testTournament,
            entry: testEntry,
            obstaclesPassed: 15,
            obstacleTarget: 20,
            canContinue: false,
            continuesRemaining: 0,
            playerGems: 100,
            gemCost: 3,
            onRetry: () => retried = true,
            onQuit: () {},
          ),
        ),
      ));

      await tester.tap(find.text('USE TRY'));
      await tester.pump();

      expect(retried, true);
    });

    testWidgets('should call onQuit when QUIT tapped', (tester) async {
      bool quit = false;
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TournamentRoundFailedPopup(
            tournament: testTournament,
            entry: testEntry,
            obstaclesPassed: 15,
            obstacleTarget: 20,
            canContinue: false,
            continuesRemaining: 0,
            playerGems: 100,
            gemCost: 3,
            onRetry: () {},
            onQuit: () => quit = true,
          ),
        ),
      ));

      await tester.tap(find.text('QUIT'));
      await tester.pump();

      expect(quit, true);
    });
  });

  group('TournamentRoundCompletePopup', () {
    // Note: This popup has entrance animations, use pump(duration) instead of pumpAndSettle
    
    testWidgets('should display round complete title', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TournamentRoundCompletePopup(
            tournament: testTournament,
            roundNumber: 1,
            coinsEarned: 100,
            gemsEarned: 5,
            onNextRound: () {},
          ),
        ),
      ));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('ROUND COMPLETE!'), findsOneWidget);
    });

    testWidgets('should display round number', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TournamentRoundCompletePopup(
            tournament: testTournament,
            roundNumber: 1,
            coinsEarned: 100,
            gemsEarned: 5,
            onNextRound: () {},
          ),
        ),
      ));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Round 1 of 2'), findsOneWidget);
    });

    testWidgets('should display rewards', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TournamentRoundCompletePopup(
            tournament: testTournament,
            roundNumber: 1,
            coinsEarned: 100,
            gemsEarned: 5,
            onNextRound: () {},
          ),
        ),
      ));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('+100'), findsOneWidget);
      expect(find.text('+5'), findsOneWidget);
    });

    testWidgets('should show NEXT ROUND for non-final rounds', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TournamentRoundCompletePopup(
            tournament: testTournament,
            roundNumber: 1,
            coinsEarned: 100,
            gemsEarned: 5,
            onNextRound: () {},
          ),
        ),
      ));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('NEXT ROUND'), findsOneWidget);
    });

    testWidgets('should show CLAIM VICTORY for final round', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TournamentRoundCompletePopup(
            tournament: testTournament,
            roundNumber: 2, // Last round
            coinsEarned: 200,
            gemsEarned: 10,
            onNextRound: () {},
          ),
        ),
      ));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('CLAIM VICTORY!'), findsOneWidget);
    });

    testWidgets('should call onNextRound when button tapped', (tester) async {
      bool nextRoundCalled = false;
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TournamentRoundCompletePopup(
            tournament: testTournament,
            roundNumber: 1,
            coinsEarned: 100,
            gemsEarned: 5,
            onNextRound: () => nextRoundCalled = true,
          ),
        ),
      ));
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('NEXT ROUND'));
      await tester.pump();

      expect(nextRoundCalled, true);
    });

    testWidgets('should display progress indicators', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TournamentRoundCompletePopup(
            tournament: testTournament,
            roundNumber: 1,
            coinsEarned: 100,
            gemsEarned: 5,
            onNextRound: () {},
          ),
        ),
      ));
      await tester.pump(const Duration(seconds: 1));

      // Should have check icons (one in header, one in progress indicator for completed round)
      // The popup has animations and progress indicators with check marks
      expect(find.byIcon(Icons.check), findsAtLeastNWidgets(1));
    });
  });
}


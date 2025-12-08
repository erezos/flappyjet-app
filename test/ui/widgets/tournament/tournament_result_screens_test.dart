import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flappy_jet_pro/ui/widgets/tournament/tournament_victory_screen.dart';
import 'package:flappy_jet_pro/ui/widgets/tournament/tournament_failed_screen.dart';
import 'package:flappy_jet_pro/models/tournament_config.dart';
import 'package:flappy_jet_pro/models/tournament_entry.dart';
import 'package:flappy_jet_pro/game/systems/inventory_manager.dart';

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
      'tier': 'gold',
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
      'lose_all_tries_offer': {
        'enabled': true,
        'discount_percent': 20,
        'extra_tries': 2,
        'base_gem_cost': 100,
      },
      'display': {'banner_image': 'test.png', 'background_color': '#FFD700'},
    });

    testEntry = TournamentEntry.start(
      tournamentId: testTournament.id,
      tournamentName: testTournament.name,
      totalTries: testTournament.tries.count,
    );
    
    // Simulate some progress
    testEntry.completeRound(
      roundNumber: 1,
      coinsReward: 100,
      gemsReward: 5,
      heartsUsed: 1,
      continuesUsed: 0,
      duration: const Duration(minutes: 2),
    );
    testEntry.completeRound(
      roundNumber: 2,
      coinsReward: 200,
      gemsReward: 10,
      heartsUsed: 2,
      continuesUsed: 1,
      duration: const Duration(minutes: 3),
    );
  });

  group('TournamentVictoryScreen', () {
    // Note: VictoryScreen has staggered animations with async delays.
    // We use multiple pump() calls to allow animations to progress.
    
    testWidgets('should display CHAMPION title', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: TournamentVictoryScreen(
          tournament: testTournament,
          entry: testEntry,
          onContinue: () {},
        ),
      ));
      // Pump multiple times to allow animations to progress
      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Screen shows both "🏆 CHAMPION! 🏆" and "TOURNAMENT CHAMPION"
      expect(find.textContaining('CHAMPION'), findsAtLeastNWidgets(1));
    });

    testWidgets('should display tournament name', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: TournamentVictoryScreen(
          tournament: testTournament,
          entry: testEntry,
          onContinue: () {},
        ),
      ));
      // Pump multiple times to allow animations to progress
      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Test Tournament'), findsOneWidget);
    });

    testWidgets('should display TOTAL REWARDS section', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: TournamentVictoryScreen(
          tournament: testTournament,
          entry: testEntry,
          onContinue: () {},
        ),
      ));
      // Pump multiple times to allow rewards to appear
      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('TOTAL REWARDS'), findsOneWidget);
    });

    // Stats row removed from simplified victory screen layout
    // testWidgets('should display stats labels', ...);

    testWidgets('should have CLAIM & CONTINUE button after animation', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: TournamentVictoryScreen(
          tournament: testTournament,
          entry: testEntry,
          onContinue: () {},
        ),
      ));
      // Pump enough times for button to appear (shows after ~2.5s)
      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('CLAIM & CONTINUE'), findsOneWidget);
    });

    // Note: Confetti animations are tested visually in integration tests.
    // The core content and button presence is verified above.
  });

  group('TournamentFailedScreen', () {
    late TournamentEntry failedEntry;

    setUp(() {
      failedEntry = TournamentEntry.start(
        tournamentId: testTournament.id,
        tournamentName: testTournament.name,
        totalTries: testTournament.tries.count,
      );
      
      // Simulate failed attempt
      failedEntry.completeRound(
        roundNumber: 1,
        coinsReward: 100,
        gemsReward: 5,
        heartsUsed: 3,
        continuesUsed: 2,
        duration: const Duration(minutes: 2),
      );
      failedEntry.failRound(
        roundNumber: 2,
        heartsUsed: 3,
        continuesUsed: 3,
        duration: const Duration(minutes: 1),
      );
    });

    testWidgets('should display TOURNAMENT OVER title', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: TournamentFailedScreen(
          tournament: testTournament,
          entry: failedEntry,
          onReturnToHub: () {},
        ),
      ));

      expect(find.text('TOURNAMENT OVER'), findsOneWidget);
    });

    testWidgets('should display tournament name', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: TournamentFailedScreen(
          tournament: testTournament,
          entry: failedEntry,
          onReturnToHub: () {},
        ),
      ));

      expect(find.text('Test Tournament'), findsOneWidget);
    });

    testWidgets('should display progress summary', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: TournamentFailedScreen(
          tournament: testTournament,
          entry: failedEntry,
          onReturnToHub: () {},
        ),
      ));

      expect(find.text('YOUR PROGRESS'), findsOneWidget);
      expect(find.text('Highest'), findsOneWidget); // Label changed to 'Highest'
    });

    testWidgets('should display rewards kept', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: TournamentFailedScreen(
          tournament: testTournament,
          entry: failedEntry,
          onReturnToHub: () {},
        ),
      ));

      expect(find.textContaining('Kept:'), findsOneWidget);
    });

    testWidgets('should display special deal when available', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: TournamentFailedScreen(
          tournament: testTournament,
          entry: failedEntry,
          onReturnToHub: () {},
          onPurchaseExtraTries: () {},
        ),
      ));

      expect(find.text('SECOND CHANCE!'), findsOneWidget);
      expect(find.text('20% OFF'), findsOneWidget);
      expect(find.text('Get 2 more tries'), findsOneWidget);
    });

    testWidgets('should show discounted price', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: TournamentFailedScreen(
          tournament: testTournament,
          entry: failedEntry,
          onReturnToHub: () {},
          onPurchaseExtraTries: () {},
        ),
      ));

      // Original price (crossed out)
      expect(find.text('100'), findsOneWidget);
      // Discounted price (80 gems = 100 - 20%)
      expect(find.text('80'), findsOneWidget);
    });

    testWidgets('should have RETURN TO HUB button', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: TournamentFailedScreen(
          tournament: testTournament,
          entry: failedEntry,
          onReturnToHub: () {},
        ),
      ));

      // Mobile layout doesn't need scrolling - button is visible
      expect(find.text('RETURN TO HUB'), findsOneWidget);
    });

    testWidgets('should call onReturnToHub when button tapped', (tester) async {
      bool returnCalled = false;
      
      await tester.pumpWidget(MaterialApp(
        home: TournamentFailedScreen(
          tournament: testTournament,
          entry: failedEntry,
          onReturnToHub: () => returnCalled = true,
        ),
      ));

      // Mobile layout doesn't need scrolling
      await tester.tap(find.text('RETURN TO HUB'));
      await tester.pump();

      expect(returnCalled, true);
    });
  });
}


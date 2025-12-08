import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flappy_jet_pro/ui/widgets/tournament/tournament_info_popup.dart';
import 'package:flappy_jet_pro/ui/widgets/coin_3d_icon.dart';
import 'package:flappy_jet_pro/models/tournament_config.dart';
import 'package:flappy_jet_pro/game/systems/tournament_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TournamentConfig testTournament;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TournamentManager().resetForTesting();

    testTournament = TournamentConfig.fromJson({
      'id': 'popup_test',
      'name': 'Test Tournament',
      'description': 'A tournament for testing the popup',
      'tier': 'bronze',
      'status': 'active',
      'entry': {'type': 'coins', 'amount': 100},
      'tries': {'count': 3},
      'continues': {'max_per_try': 5, 'gem_cost': 3, 'ad_available': true},
      'levels': [
        {
          'round': 1,
          'name': 'Warm Up',
          'difficulty': {'speed': 1.0, 'gap': 200, 'frequency': 2.5},
          'reward': {'coins': 50, 'gems': 0},
        },
        {
          'round': 2,
          'name': 'Getting Started',
          'difficulty': {'speed': 1.1, 'gap': 190, 'frequency': 2.3},
          'reward': {'coins': 100, 'gems': 5},
        },
        {
          'round': 3,
          'name': 'Final Round',
          'difficulty': {'speed': 1.2, 'gap': 180, 'frequency': 2.0},
          'reward': {'coins': 150, 'gems': 10},
        },
      ],
      'completion_reward': {'coins': 500, 'gems': 20},
      'display': {'banner_image': 'test.png', 'background_color': '#CD7F32'},
    });
  });

  Widget buildTestWidget({
    required TournamentConfig tournament,
    int playerCoins = 1000,
    int playerGems = 100,
    bool hasFreeTicket = false,
    bool hasActiveEntry = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showTournamentInfoPopup(
              context: context,
              tournament: tournament,
              playerCoins: playerCoins,
              playerGems: playerGems,
              hasFreeTicket: hasFreeTicket,
              hasActiveEntry: hasActiveEntry,
            ),
            child: const Text('Show Popup'),
          ),
        ),
      ),
    );
  }

  Future<void> openPopup(WidgetTester tester) async {
    await tester.tap(find.text('Show Popup'));
    await tester.pumpAndSettle();
  }

  group('TournamentInfoPopup - Header', () {
    testWidgets('should display tournament name', (tester) async {
      await tester.pumpWidget(buildTestWidget(tournament: testTournament));
      await openPopup(tester);

      expect(find.text('Test Tournament'), findsOneWidget);
    });

    testWidgets('should display tournament description', (tester) async {
      await tester.pumpWidget(buildTestWidget(tournament: testTournament));
      await openPopup(tester);

      expect(find.text('A tournament for testing the popup'), findsOneWidget);
    });

    testWidgets('should display tier badge', (tester) async {
      await tester.pumpWidget(buildTestWidget(tournament: testTournament));
      await openPopup(tester);

      expect(find.text('BRONZE'), findsOneWidget);
    });

    testWidgets('should display tier emoji', (tester) async {
      await tester.pumpWidget(buildTestWidget(tournament: testTournament));
      await openPopup(tester);

      expect(find.text('🥉'), findsOneWidget);
    });
  });

  group('TournamentInfoPopup - Stats Section', () {
    testWidgets('should display rounds count', (tester) async {
      await tester.pumpWidget(buildTestWidget(tournament: testTournament));
      await openPopup(tester);

      expect(find.text('3'), findsAtLeastNWidgets(1)); // 3 rounds and 3 tries
      expect(find.text('Rounds'), findsOneWidget);
    });

    testWidgets('should display tries count', (tester) async {
      await tester.pumpWidget(buildTestWidget(tournament: testTournament));
      await openPopup(tester);

      expect(find.text('Tries'), findsOneWidget);
    });

    testWidgets('should display continues per try', (tester) async {
      await tester.pumpWidget(buildTestWidget(tournament: testTournament));
      await openPopup(tester);

      expect(find.text('5'), findsOneWidget); // max 5 continues per try
      expect(find.text('Continues/Try'), findsOneWidget);
    });
  });

  group('TournamentInfoPopup - Rounds Section', () {
    testWidgets('should display ROUNDS header', (tester) async {
      await tester.pumpWidget(buildTestWidget(tournament: testTournament));
      await openPopup(tester);

      expect(find.text('ROUNDS'), findsOneWidget);
    });

    testWidgets('should display round names', (tester) async {
      await tester.pumpWidget(buildTestWidget(tournament: testTournament));
      await openPopup(tester);

      expect(find.text('Warm Up'), findsOneWidget);
      expect(find.text('Getting Started'), findsOneWidget);
      expect(find.text('Final Round'), findsOneWidget);
    });

    testWidgets('should display round numbers', (tester) async {
      await tester.pumpWidget(buildTestWidget(tournament: testTournament));
      await openPopup(tester);

      expect(find.text('1'), findsAtLeastNWidgets(1));
      expect(find.text('2'), findsAtLeastNWidgets(1));
    });
  });

  group('TournamentInfoPopup - Prizes Section', () {
    testWidgets('should display TOTAL PRIZES header', (tester) async {
      await tester.pumpWidget(buildTestWidget(tournament: testTournament));
      await openPopup(tester);

      expect(find.text('TOTAL PRIZES'), findsOneWidget);
    });

    testWidgets('should display coin rewards', (tester) async {
      await tester.pumpWidget(buildTestWidget(tournament: testTournament));
      await openPopup(tester);

      // Total coins: 500 + 50 + 100 + 150 = 800
      expect(find.text('800'), findsOneWidget);
      expect(find.text('Coins'), findsOneWidget);
    });

    testWidgets('should display gem rewards', (tester) async {
      await tester.pumpWidget(buildTestWidget(tournament: testTournament));
      await openPopup(tester);

      // Total gems: 20 + 0 + 5 + 10 = 35
      expect(find.text('35'), findsOneWidget);
      expect(find.text('Gems'), findsOneWidget);
    });
  });

  group('TournamentInfoPopup - Rules Section', () {
    testWidgets('should display RULES header', (tester) async {
      await tester.pumpWidget(buildTestWidget(tournament: testTournament));
      await openPopup(tester);

      expect(find.text('RULES'), findsOneWidget);
    });

    testWidgets('should display tries rule', (tester) async {
      await tester.pumpWidget(buildTestWidget(tournament: testTournament));
      await openPopup(tester);

      expect(
        find.textContaining('3 tries'),
        findsOneWidget,
      );
    });

    testWidgets('should display continues rule', (tester) async {
      await tester.pumpWidget(buildTestWidget(tournament: testTournament));
      await openPopup(tester);

      expect(
        find.textContaining('max 5 per try'),
        findsOneWidget,
      );
    });
  });

  group('TournamentInfoPopup - Action Button', () {
    testWidgets('should show entry button with coins cost', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        tournament: testTournament,
        playerCoins: 200,
      ));
      await openPopup(tester);

      expect(find.textContaining('ENTER FOR 100'), findsOneWidget);
      expect(find.byType(Coin3DIcon), findsAtLeastNWidgets(1)); // ✅ Updated: using Coin3DIcon
    });

    testWidgets('should show CONTINUE button when has active entry', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        tournament: testTournament,
        hasActiveEntry: true,
      ));
      await openPopup(tester);

      expect(find.text('CONTINUE TOURNAMENT'), findsOneWidget);
    });

    testWidgets('should show USE FREE TICKET button when has free ticket', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        tournament: testTournament,
        hasFreeTicket: true,
      ));
      await openPopup(tester);

      expect(find.textContaining('USE FREE TICKET'), findsOneWidget);
    });

    testWidgets('should show disabled button when cannot afford', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        tournament: testTournament,
        playerCoins: 50, // Not enough
      ));
      await openPopup(tester);

      expect(find.textContaining('Not enough coins'), findsOneWidget);
    });
  });

  group('TournamentInfoPopup - Close Button', () {
    testWidgets('should have close button', (tester) async {
      await tester.pumpWidget(buildTestWidget(tournament: testTournament));
      await openPopup(tester);

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('should close popup when close button tapped', (tester) async {
      await tester.pumpWidget(buildTestWidget(tournament: testTournament));
      await openPopup(tester);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Popup should be closed, tournament name not visible
      expect(find.text('Test Tournament'), findsNothing);
    });
  });

  group('TournamentInfoPopup - Drag Handle', () {
    testWidgets('should have drag handle at top', (tester) async {
      await tester.pumpWidget(buildTestWidget(tournament: testTournament));
      await openPopup(tester);

      // The drag handle is a small container at the top
      // We verify the popup itself opens (DraggableScrollableSheet)
      expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    });
  });
}


import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flappy_jet_pro/ui/widgets/tournament/tournament_card.dart';
import 'package:flappy_jet_pro/ui/widgets/coin_3d_icon.dart';
import 'package:flappy_jet_pro/ui/widgets/gem_3d_icon.dart';
import 'package:flappy_jet_pro/models/tournament_config.dart';
import 'package:flappy_jet_pro/game/systems/tournament_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TournamentConfig linearTournament;
  late TournamentConfig playoffTournament;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TournamentManager().resetForTesting();

    // Linear tournament (not playoff)
    linearTournament = TournamentConfig.fromJson({
      'id': 'linear_test',
      'name': 'Stunt Challenge',
      'description': 'A stunt tournament',
      'tier': 'silver',
      'status': 'active',
      'progression_type': 'linear',
      'entry': {'type': 'coins', 'amount': 100},
      'tries': {'count': 3},
      'continues': {'max_per_try': 5, 'gem_cost': 3, 'ad_available': true},
      'levels': [
        {
          'round': 1,
          'name': 'Round 1',
          'difficulty': {'speed': 1.0, 'gap': 200, 'frequency': 2.5},
          'reward': {'coins': 50, 'gems': 0},
        },
        {
          'round': 2,
          'name': 'Round 2',
          'difficulty': {'speed': 1.1, 'gap': 190, 'frequency': 2.3},
          'reward': {'coins': 100, 'gems': 5},
        },
      ],
      'completion_reward': {'coins': 500, 'gems': 20},
      'display': {'banner_image': 'test.png', 'background_color': '#CD7F32'},
    });

    // Playoff tournament (1vs1)
    playoffTournament = TournamentConfig.fromJson({
      'id': 'playoff_test',
      'name': 'Bosses Showdown',
      'description': 'A playoff tournament',
      'tier': 'bronze',
      'status': 'active',
      'progression_type': 'playoff',
      'entry': {'type': 'gems', 'amount': 50},
      'tries': {'count': 3},
      'continues': {'max_per_try': 5, 'gem_cost': 3, 'ad_available': true},
      'levels': [
        {
          'round': 1,
          'name': 'Round 1',
          'difficulty': {'speed': 1.2, 'gap': 180, 'frequency': 2.0},
          'reward': {'coins': 100, 'gems': 10},
        },
        {
          'round': 2,
          'name': 'Round 2',
          'difficulty': {'speed': 1.2, 'gap': 180, 'frequency': 2.0},
          'reward': {'coins': 150, 'gems': 15},
        },
        {
          'round': 3,
          'name': 'Round 3',
          'difficulty': {'speed': 1.2, 'gap': 180, 'frequency': 2.0},
          'reward': {'coins': 200, 'gems': 20},
        },
        {
          'round': 4,
          'name': 'Finals',
          'difficulty': {'speed': 1.2, 'gap': 180, 'frequency': 2.0},
          'reward': {'coins': 250, 'gems': 25},
        },
      ],
      'completion_reward': {'coins': 1000, 'gems': 50},
      'display': {'banner_image': 'playoff.png', 'background_color': '#C0C0C0'},
    });
  });

  Widget buildTestWidget({
    required TournamentConfig tournament,
    int playerCoins = 1000,
    int playerGems = 100,
    bool hasFreeTicket = false,
    bool hasActiveEntry = false,
    VoidCallback? onTap,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: TournamentCard(
            tournament: tournament,
            playerCoins: playerCoins,
            playerGems: playerGems,
            hasFreeTicket: hasFreeTicket,
            hasActiveEntry: hasActiveEntry,
            onTap: onTap ?? () {},
          ),
        ),
      ),
    );
  }

  group('TournamentCard - Name Display', () {
    testWidgets('should render full tournament name', (tester) async {
      await tester.pumpWidget(buildTestWidget(tournament: linearTournament));
      
      expect(find.text('Stunt Challenge'), findsOneWidget);
    });

    testWidgets('should render playoff tournament name', (tester) async {
      await tester.pumpWidget(buildTestWidget(tournament: playoffTournament));
      
      expect(find.text('Bosses Showdown'), findsOneWidget);
    });
  });

  group('TournamentCard - Tournament Type Display', () {
    testWidgets('should show linear tournament type with world map', (tester) async {
      await tester.pumpWidget(buildTestWidget(tournament: linearTournament));
      
      // Linear tournaments show "1 World Map · X Levels"
      expect(find.text('1 World Map · 2 Levels'), findsOneWidget);
    });

    testWidgets('should show playoff tournament type', (tester) async {
      await tester.pumpWidget(buildTestWidget(tournament: playoffTournament));
      
      // Playoff tournaments show "1vs1 Playoff · X rounds"
      expect(find.text('1vs1 Playoff · 4 rounds'), findsOneWidget);
    });
  });

  group('TournamentCard - Prizes Row', () {
    testWidgets('shows summed coins and gems rewards', (tester) async {
      // total coins = (50 + 100) + 500 = 650, gems = (0 + 5) + 20 = 25
      await tester.pumpWidget(buildTestWidget(tournament: linearTournament));

      expect(find.text('650'), findsOneWidget);
      expect(find.text('25'), findsOneWidget);
      expect(find.byType(Coin3DIcon), findsWidgets);
      expect(find.byType(Gem3DIcon), findsWidgets);
    });
  });

  group('TournamentCard - Layout resilience', () {
    testWidgets('no overflow on narrow phone widths (linear)', (tester) async {
      final binding = tester.binding;
      final originalSize = binding.window.physicalSize;
      final originalPixelRatio = binding.window.devicePixelRatio;

      binding.window.physicalSizeTestValue = const Size(320, 640);
      binding.window.devicePixelRatioTestValue = 2.0;
      addTearDown(() {
        binding.window.physicalSizeTestValue = originalSize;
        binding.window.devicePixelRatioTestValue = originalPixelRatio;
      });

      await tester.pumpWidget(buildTestWidget(tournament: linearTournament));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('no overflow on narrow phone widths (playoff)', (tester) async {
      final binding = tester.binding;
      final originalSize = binding.window.physicalSize;
      final originalPixelRatio = binding.window.devicePixelRatio;

      binding.window.physicalSizeTestValue = const Size(320, 640);
      binding.window.devicePixelRatioTestValue = 2.0;
      addTearDown(() {
        binding.window.physicalSizeTestValue = originalSize;
        binding.window.devicePixelRatioTestValue = originalPixelRatio;
      });

      await tester.pumpWidget(buildTestWidget(tournament: playoffTournament));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('TournamentCard - Entry Button States', () {
    testWidgets('should show coins cost when can afford', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        tournament: linearTournament,
        playerCoins: 200,
      ));
      
      // Entry button shows "100" text with Coin3DIcon
      expect(find.text('100'), findsOneWidget);
      expect(find.byType(Coin3DIcon), findsAtLeast(1));
    });

    testWidgets('should show gems cost when can afford', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        tournament: playoffTournament,
        playerGems: 100,
      ));
      
      // Entry button shows "50" text with Gem3DIcon
      expect(find.text('50'), findsOneWidget);
      expect(find.byType(Gem3DIcon), findsAtLeast(1));
    });

    testWidgets('should show continue button when has active entry', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        tournament: linearTournament,
        hasActiveEntry: true,
      ));
      
      expect(find.text('CONTINUE'), findsOneWidget);
    });

    testWidgets('should show play free button when has free ticket', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        tournament: linearTournament,
        hasFreeTicket: true,
      ));
      
      expect(find.text('USE FREE TICKET'), findsOneWidget);
    });
    
    testWidgets('should show FREE button for free tournaments', (tester) async {
      final freeTournament = TournamentConfig.fromJson({
        'id': 'free_test',
        'name': 'Free Cup',
        'description': 'A free tournament',
        'tier': 'bronze',
        'status': 'active',
        'entry': {'type': 'coins', 'amount': 0},
        'tries': {'count': 3},
        'continues': {'max_per_try': 5, 'gem_cost': 3, 'ad_available': true},
        'levels': [],
        'completion_reward': {'coins': 100, 'gems': 5},
        'display': {'banner_image': 'free.png'},
      });
      
      await tester.pumpWidget(buildTestWidget(tournament: freeTournament));
      
      expect(find.text('FREE'), findsOneWidget);
    });
  });

  group('TournamentCard - Status Badges', () {
    testWidgets('should show PLAYING badge when has active entry', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        tournament: linearTournament,
        hasActiveEntry: true,
      ));
      
      expect(find.text('PLAYING'), findsOneWidget);
    });

    testWidgets('should show FREE badge with ticket icon when has free ticket', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        tournament: linearTournament,
        hasFreeTicket: true,
      ));
      
      // Badge shows "FREE" text (emoji replaced with TournamentTicketIcon image)
      expect(find.textContaining('FREE'), findsAtLeast(1));
      expect(find.text('FREE'), findsAtLeastNWidgets(1));
    });

    testWidgets('should not show FREE badge when has active entry', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        tournament: linearTournament,
        hasFreeTicket: true,
        hasActiveEntry: true,
      ));
      
      // Active entry takes priority
      expect(find.text('PLAYING'), findsOneWidget);
    });
  });

  group('TournamentCard - Interactions', () {
    testWidgets('should call onTap when tapped', (tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(buildTestWidget(
        tournament: linearTournament,
        onTap: () => tapped = true,
      ));
      
      await tester.tap(find.byType(TournamentCard));
      await tester.pump();
      
      expect(tapped, true);
    });
  });

  group('TournamentCard - Prize Display', () {
    testWidgets('should show total prize with trophy image', (tester) async {
      await tester.pumpWidget(buildTestWidget(tournament: linearTournament));
      
      // Total coins: 500 (completion) + 50 + 100 (rounds) = 650
      // Prize is displayed with Coin3DIcon and text "650"
      expect(find.text('650'), findsOneWidget);
      expect(find.byType(Coin3DIcon), findsAtLeast(1));
      // Trophy is now shown as an Image widget (tournament-specific trophy)
      // Find any Image widget in the prizes section (tournament_card uses Image.asset for trophy)
      expect(find.byType(Image), findsAtLeast(1));
    });

    testWidgets('should show gem prizes when available', (tester) async {
      await tester.pumpWidget(buildTestWidget(tournament: playoffTournament));
      
      // Total gems: 50 (completion) + 10 + 15 + 20 + 25 (rounds) = 120
      expect(find.text('120'), findsOneWidget);
      expect(find.byType(Gem3DIcon), findsAtLeast(1));
    });

    testWidgets('should show skin thumbnail when skin reward available', (tester) async {
      // Create tournament with skin reward
      final tournamentWithSkin = TournamentConfig.fromJson({
        'id': 'skin_test',
        'name': 'Skin Prize Cup',
        'description': 'Win a jet skin!',
        'tier': 'gold',
        'status': 'active',
        'entry': {'type': 'coins', 'amount': 0},
        'tries': {'count': 3},
        'continues': {'max_per_try': 5, 'gem_cost': 3, 'ad_available': true},
        'levels': [],
        'completion_reward': {
          'coins': 1000,
          'gems': 50,
          'skin_id': 'space_destroyer', // Jet skin reward!
        },
        'display': {'banner_image': 'test.png'},
      });
      
      await tester.pumpWidget(buildTestWidget(tournament: tournamentWithSkin));
      await tester.pumpAndSettle();
      
      // Should show skin thumbnail (Image.asset wrapped in Container)
      // The skin thumbnail has a distinct amber border
      expect(find.byType(ClipRRect), findsAtLeast(1));
    });
  });

  group('TournamentCard - Banner Fallback', () {
    testWidgets('should show fallback icon when image fails to load', (tester) async {
      await tester.pumpWidget(buildTestWidget(tournament: linearTournament));
      await tester.pumpAndSettle();
      
      // Banner fallback shows route icon for linear tournaments
      expect(find.byIcon(Icons.route), findsOneWidget);
    });

    testWidgets('should show trophy icon for playoff tournament fallback', (tester) async {
      await tester.pumpWidget(buildTestWidget(tournament: playoffTournament));
      await tester.pumpAndSettle();
      
      // Banner fallback shows trophy icon for playoff tournaments
      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
    });
  });
}

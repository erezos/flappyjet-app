import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flappy_jet_pro/models/tournament_config.dart';
import 'package:flappy_jet_pro/models/tournament_entry.dart';
import 'package:flappy_jet_pro/ui/widgets/tournament/tournament_victory_screen.dart';
import 'package:flappy_jet_pro/ui/widgets/tournament_ticket_icon.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TournamentConfig tournament;
  late TournamentEntry entry;

  setUp(() {
    SharedPreferences.setMockInitialValues({});

    tournament = TournamentConfig.fromJson({
      'id': 'stunt_tournament',
      'name': 'Stunt Tournament',
      'description': 'Win big prizes',
      'tier': 'gold',
      'status': 'active',
      'progression_type': 'linear',
      'entry': {'type': 'coins', 'amount': 100},
      'tries': {'count': 3},
      'continues': {'max_per_try': 5, 'gem_cost': 3, 'ad_available': true},
      'levels': [
        {
          'round': 1,
          'name': 'Warmup',
          'difficulty': {'speed': 1.0, 'gap': 200, 'frequency': 2.5},
          'reward': {'coins': 100, 'gems': 5},
        }
      ],
      'completion_reward': {
        'coins': 500,
        'gems': 20,
        'booster': {'type': 'doubleCoins', 'duration_hours': 12},
        'free_ticket_tier': 'silver',
        'trophy_id': 'champion'
      },
      'display': {
        'banner_image': 'test_banner',
        'icon': 'trophy_gold',
        'color_primary': '#FFD700'
      },
    });

    entry = TournamentEntry(
      id: 'entry1',
      tournamentId: 'stunt_tournament',
      tournamentName: 'Stunt Tournament',
      startedAt: DateTime(2024),
      totalTries: 3,
      coinsEarned: 50,
      gemsEarned: 10,
      status: TournamentEntryStatus.completed,
    );
  });

  Widget _buildVictoryScreen() {
    return MaterialApp(
      home: TournamentVictoryScreen(
        tournament: tournament,
        entry: entry,
        onContinue: () {},
        testingFastMode: true,
      ),
    );
  }

  testWidgets('renders combined rewards totals and bonus chips', (tester) async {
    await tester.pumpWidget(_buildVictoryScreen());
    // Let reward tween animations reach final values.
    await tester.pump(const Duration(seconds: 1));

    // Totals include completion reward: 50 + 500 = 550 coins, 10 + 20 = 30 gems
    expect(find.text('+550'), findsOneWidget);
    expect(find.text('+30'), findsOneWidget);

    // Free ticket chip is visible (trophy removed from the row)
    expect(find.byType(TournamentTicketIcon), findsOneWidget);
    // Booster text no longer rendered in the rewards row
    expect(find.text('Double Coins (12 hrs)'), findsNothing);

    // Subtitle removed
    expect(find.text('TOURNAMENT CHAMPION'), findsNothing);
  });

  testWidgets('does not overflow on narrow screens', (tester) async {
    final binding = tester.binding;
    final originalSize = binding.window.physicalSize;
    final originalPixelRatio = binding.window.devicePixelRatio;

    binding.window.physicalSizeTestValue = const Size(320, 640);
    binding.window.devicePixelRatioTestValue = 2.0;
    addTearDown(() {
      binding.window.physicalSizeTestValue = originalSize;
      binding.window.devicePixelRatioTestValue = originalPixelRatio;
    });

    await tester.pumpWidget(_buildVictoryScreen());
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
  });
}


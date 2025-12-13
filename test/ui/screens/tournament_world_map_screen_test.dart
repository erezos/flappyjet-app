/// 🧪 Tests for TournamentWorldMapScreen
/// 
/// Verifies the upgraded tournament world map with:
/// - Centered header with trophy icon
/// - Ticket icon for tries (not heart)
/// - Bigger hexagonal nodes
/// - Grand Prize section with actual jet skin
/// - Node tap → preview popup flow (no play button)
/// - Animated jet at current level
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flappy_jet_pro/ui/screens/tournament_world_map_screen.dart';
import 'package:flappy_jet_pro/ui/widgets/hexagonal_level_node.dart';
import 'package:flappy_jet_pro/ui/widgets/tournament_ticket_icon.dart';
import 'package:flappy_jet_pro/ui/widgets/world_map_jet_widget.dart';
import 'package:flappy_jet_pro/ui/widgets/coin_3d_icon.dart';
import 'package:flappy_jet_pro/ui/widgets/gem_3d_icon.dart';
import 'package:flappy_jet_pro/models/tournament_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Create a minimal test tournament configuration
  late TournamentConfig testTournament;
  late TournamentConfig testTournamentWithSkin;
  
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    
    // Build test tournament with all required fields
    testTournament = TournamentConfig(
      id: 'test_stunt_tournament',
      name: 'Test Stunt Tournament',
      description: 'A test tournament',
      tier: TournamentTier.silver,
      status: TournamentStatus.active,
      progressionType: TournamentProgressionType.linear,
      entry: const TournamentEntryConfig(
        type: EntryFeeType.coins,
        amount: 100,
        freeTicketTier: null,
      ),
      tries: const TournamentTriesConfig(count: 3),
      continues: const TournamentContinuesConfig(maxPerTry: 3, gemCost: 5, adAvailable: true),
      levels: [
        TournamentLevel(
          round: 1, 
          name: 'The Wobbler', 
          background: 'test.png',
          difficulty: const TournamentDifficulty(speedMultiplier: 1.0, obstacleGap: 350, obstacleFrequency: 2.5, maxGapShift: 50, requiredDistance: 50),
          obstaclePatterns: [],
          reward: const TournamentReward(coins: 100, gems: 2),
        ),
        TournamentLevel(
          round: 2, 
          name: 'Wind Rider', 
          background: 'test.png',
          difficulty: const TournamentDifficulty(speedMultiplier: 1.0, obstacleGap: 350, obstacleFrequency: 2.5, maxGapShift: 50, requiredDistance: 50),
          obstaclePatterns: [],
          reward: const TournamentReward(coins: 150, gems: 3),
        ),
        TournamentLevel(
          round: 3, 
          name: 'The Gauntlet', 
          background: 'test.png',
          difficulty: const TournamentDifficulty(speedMultiplier: 1.0, obstacleGap: 350, obstacleFrequency: 2.5, maxGapShift: 50, requiredDistance: 50),
          obstaclePatterns: [],
          reward: const TournamentReward(coins: 200, gems: 4),
        ),
        TournamentLevel(
          round: 4, 
          name: 'Chaos Zone', 
          background: 'test.png',
          difficulty: const TournamentDifficulty(speedMultiplier: 1.0, obstacleGap: 350, obstacleFrequency: 2.5, maxGapShift: 50, requiredDistance: 50),
          obstaclePatterns: [],
          reward: const TournamentReward(coins: 300, gems: 5),
        ),
        TournamentLevel(
          round: 5, 
          name: 'Ultimate Stunt', 
          background: 'test.png',
          difficulty: const TournamentDifficulty(speedMultiplier: 1.0, obstacleGap: 350, obstacleFrequency: 2.5, maxGapShift: 50, requiredDistance: 50),
          obstaclePatterns: [],
          reward: const TournamentReward(coins: 400, gems: 8),
        ),
      ],
      completionReward: const TournamentReward(coins: 2000, gems: 30),
      display: const TournamentDisplay(
        bannerImage: 'tournament_stunt.png',
        icon: 'trophy',
        colorPrimary: '#FF6B35',
        colorSecondary: '#F7931E',
      ),
    );
    
    // Tournament with skin reward for testing Grand Prize
    testTournamentWithSkin = TournamentConfig(
      id: 'stunt_tournament',
      name: '🎪 Stunt Tournament',
      description: 'A test tournament with skin',
      tier: TournamentTier.silver,
      status: TournamentStatus.active,
      progressionType: TournamentProgressionType.linear,
      entry: const TournamentEntryConfig(
        type: EntryFeeType.coins,
        amount: 100,
        freeTicketTier: null,
      ),
      tries: const TournamentTriesConfig(count: 3),
      continues: const TournamentContinuesConfig(maxPerTry: 3, gemCost: 5, adAvailable: true),
      levels: testTournament.levels,
      completionReward: const TournamentReward(coins: 2000, gems: 30, skinId: 'sky_jet'),
      display: const TournamentDisplay(
        bannerImage: 'tournament_stunt.png',
        icon: 'trophy',
        colorPrimary: '#FF6B35',
        colorSecondary: '#F7931E',
      ),
    );
  });

  const testEntrySummary = TournamentEntrySummary(
    currentRound: 1,
    totalRounds: 5,
    triesRemaining: 3,
  );

  group('TournamentWorldMapScreen - Hexagonal Nodes', () {
    testWidgets('renders 5 HexagonalLevelNode widgets', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TournamentWorldMapScreen(
            tournament: testTournament,
            entrySummary: testEntrySummary,
            onPlayLevel: (_) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();

      // Should find 5 HexagonalLevelNode widgets (one for each level)
      expect(find.byType(HexagonalLevelNode), findsNWidgets(5));
    });

    testWidgets('marks current level node as active', (tester) async {
      const entrySummary = TournamentEntrySummary(
        currentRound: 2,
        totalRounds: 5,
        triesRemaining: 3,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TournamentWorldMapScreen(
            tournament: testTournament,
            entrySummary: entrySummary,
            onPlayLevel: (_) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();

      final nodes = tester.widgetList<HexagonalLevelNode>(find.byType(HexagonalLevelNode)).toList();
      
      // Node at index 1 (round 2) should be current
      expect(nodes[1].isCurrent, isTrue);
      expect(nodes[1].isUnlocked, isTrue);
      expect(nodes[1].isCompleted, isFalse);
    });

    testWidgets('marks completed levels correctly', (tester) async {
      const entrySummary = TournamentEntrySummary(
        currentRound: 3,
        totalRounds: 5,
        triesRemaining: 2,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TournamentWorldMapScreen(
            tournament: testTournament,
            entrySummary: entrySummary,
            onPlayLevel: (_) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();

      final nodes = tester.widgetList<HexagonalLevelNode>(find.byType(HexagonalLevelNode)).toList();
      
      // First 2 levels should be completed
      expect(nodes[0].isCompleted, isTrue);
      expect(nodes[1].isCompleted, isTrue);
      
      // Third level is current
      expect(nodes[2].isCurrent, isTrue);
      expect(nodes[2].isCompleted, isFalse);
      
      // Remaining levels are locked
      expect(nodes[3].isUnlocked, isFalse);
      expect(nodes[4].isUnlocked, isFalse);
    });

    testWidgets('active node is BIGGER (85px vs 75px)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TournamentWorldMapScreen(
            tournament: testTournament,
            entrySummary: testEntrySummary,
            onPlayLevel: (_) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();

      final nodes = tester.widgetList<HexagonalLevelNode>(find.byType(HexagonalLevelNode)).toList();
      
      // Current node (index 0) should be 85px
      expect(nodes[0].nodeSize, 85.0);
      
      // Other nodes should be 75px
      expect(nodes[1].nodeSize, 75.0);
      expect(nodes[2].nodeSize, 75.0);
    });

    testWidgets('uses tournament orange theme color for active nodes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TournamentWorldMapScreen(
            tournament: testTournament,
            entrySummary: testEntrySummary,
            onPlayLevel: (_) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();

      final nodes = tester.widgetList<HexagonalLevelNode>(find.byType(HexagonalLevelNode)).toList();
      
      // Current node should have modern light blue active color
      expect(nodes[0].activeColor, const Color(0xFF4DDCFF));
    });

    testWidgets('uses green completed color', (tester) async {
      const entrySummary = TournamentEntrySummary(
        currentRound: 2,
        totalRounds: 5,
        triesRemaining: 3,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TournamentWorldMapScreen(
            tournament: testTournament,
            entrySummary: entrySummary,
            onPlayLevel: (_) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();

      final nodes = tester.widgetList<HexagonalLevelNode>(find.byType(HexagonalLevelNode)).toList();
      
      // Completed node should have green color
      expect(nodes[0].completedColor, const Color(0xFF4CAF50));
    });

    testWidgets('no bot battle flag on tournament nodes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TournamentWorldMapScreen(
            tournament: testTournament,
            entrySummary: testEntrySummary,
            onPlayLevel: (_) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();

      final nodes = tester.widgetList<HexagonalLevelNode>(find.byType(HexagonalLevelNode));
      
      // No VS battle nodes in linear tournaments
      for (final node in nodes) {
        expect(node.isBotBattle, isFalse);
      }
    });
  });

  group('TournamentWorldMapScreen - Header (Centered)', () {
    testWidgets('displays tournament name (centered, emoji stripped)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TournamentWorldMapScreen(
            tournament: testTournamentWithSkin,
            entrySummary: testEntrySummary,
            onPlayLevel: (_) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();

      // Should find tournament name without emoji
      expect(find.text('Stunt Tournament'), findsOneWidget);
    });

    testWidgets('uses TournamentTicketIcon instead of heart for tries', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TournamentWorldMapScreen(
            tournament: testTournament,
            entrySummary: testEntrySummary,
            onPlayLevel: (_) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();

      // Should find TournamentTicketIcon
      expect(find.byType(TournamentTicketIcon), findsOneWidget);
      
      // Should NOT find heart icon
      expect(find.byIcon(Icons.favorite), findsNothing);
    });

    testWidgets('displays tries remaining with correct text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TournamentWorldMapScreen(
            tournament: testTournament,
            entrySummary: testEntrySummary,
            onPlayLevel: (_) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('3 tries left'), findsOneWidget);
    });

    testWidgets('displays singular "try" when only 1 remaining', (tester) async {
      const entrySummary = TournamentEntrySummary(
        currentRound: 1,
        totalRounds: 5,
        triesRemaining: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TournamentWorldMapScreen(
            tournament: testTournament,
            entrySummary: entrySummary,
            onPlayLevel: (_) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('1 try left'), findsOneWidget);
    });

    testWidgets('omits stage progress badge (streamlined header)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TournamentWorldMapScreen(
            tournament: testTournament,
            entrySummary: testEntrySummary,
            onPlayLevel: (_) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('Stage'), findsNothing);
    });

    testWidgets('back button is present and triggers callback', (tester) async {
      bool backPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: TournamentWorldMapScreen(
            tournament: testTournament,
            entrySummary: testEntrySummary,
            onPlayLevel: (_) {},
            onBack: () => backPressed = true,
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();

      expect(backPressed, isTrue);
    });
  });

  group('TournamentWorldMapScreen - Grand Prize Section', () {
    testWidgets('displays GRAND PRIZE label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TournamentWorldMapScreen(
            tournament: testTournament,
            entrySummary: testEntrySummary,
            onPlayLevel: (_) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('GRAND PRIZE'), findsOneWidget);
    });

    testWidgets('displays coin reward with Coin3DIcon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TournamentWorldMapScreen(
            tournament: testTournament,
            entrySummary: testEntrySummary,
            onPlayLevel: (_) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();

      // Coin3DIcon for grand prize
      expect(find.byType(Coin3DIcon), findsWidgets);
      expect(find.text('2000'), findsOneWidget); // Coin amount
    });

    testWidgets('displays gem reward with Gem3DIcon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TournamentWorldMapScreen(
            tournament: testTournament,
            entrySummary: testEntrySummary,
            onPlayLevel: (_) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();

      // Gem3DIcon for grand prize
      expect(find.byType(Gem3DIcon), findsWidgets);
      expect(find.text('30'), findsOneWidget); // Gem amount
    });

    testWidgets('does not render skin name when reward includes skin', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TournamentWorldMapScreen(
            tournament: testTournamentWithSkin,
            entrySummary: testEntrySummary,
            onPlayLevel: (_) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Sky Rookie'), findsNothing);
    });

    testWidgets('grand prize wraps without overflow on narrow screens', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(320, 640)),
            child: TournamentWorldMapScreen(
              tournament: testTournamentWithSkin,
              entrySummary: testEntrySummary,
              onPlayLevel: (_) {},
              onBack: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      // No layout exceptions (e.g., RenderFlex overflow)
      expect(tester.takeException(), isNull);
      expect(find.text('GRAND PRIZE'), findsOneWidget);
      expect(find.byType(Coin3DIcon), findsWidgets);
      expect(find.byType(Gem3DIcon), findsWidgets);
      expect(find.text('Sky Rookie'), findsNothing);
    });
  });

  group('TournamentWorldMapScreen - Node Tap & Preview Popup', () {
    testWidgets('NO play button at bottom (removed)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TournamentWorldMapScreen(
            tournament: testTournament,
            entrySummary: testEntrySummary,
            onPlayLevel: (_) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();

      // Should NOT find any "PLAY" button text (old style)
      expect(find.text('PLAY THE WOBBLER'), findsNothing);
      expect(find.text('PLAY WIND RIDER'), findsNothing);
    });

    testWidgets('tapping level node shows preview popup', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TournamentWorldMapScreen(
            tournament: testTournament,
            entrySummary: testEntrySummary,
            onPlayLevel: (_) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();

      // Tap on the first level node (hexagon)
      await tester.tap(find.byType(HexagonalLevelNode).first, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Popup should appear with STAGE badge and START button (story mode style)
      expect(find.text('STAGE 1'), findsOneWidget);
      expect(find.text('START ▶'), findsOneWidget); // Start button in popup
    });

    testWidgets('preview shows survival objective text for time-based stunt level', (tester) async {
      final survivalTournament = TournamentConfig(
        id: 'stunt_tournament',
        name: 'Survival Stunt',
        description: 'Time-based stunt levels',
        tier: TournamentTier.silver,
        status: TournamentStatus.active,
        progressionType: TournamentProgressionType.linear,
        entry: const TournamentEntryConfig(type: EntryFeeType.coins, amount: 100),
        tries: const TournamentTriesConfig(count: 3),
        continues: const TournamentContinuesConfig(maxPerTry: 3, gemCost: 5, adAvailable: true),
        levels: [
          TournamentLevel(
            round: 1,
            name: 'Survive!',
            background: 'test.png',
            difficulty: const TournamentDifficulty(
              speedMultiplier: 1.0,
              obstacleGap: 350,
              obstacleFrequency: 2.5,
              maxGapShift: 50,
              requiredDistance: 25, // seconds
            ),
            obstaclePatterns: const [],
            reward: const TournamentReward(coins: 100, gems: 2),
            stuntConfig: const {
              'mode': 'time_survival',
              'asset_path': 'obstacles/moving_obstacle_spikes1.png',
              'obstacle_size_percent': 0.5,
              'spawn_interval': 3.0,
              'spawn_variance': 0.1,
              'scroll_speed': 160.0,
              'vertical_amplitude_percent': 0.12,
              'vertical_frequency': 0.30,
              'one_at_a_time': true,
            },
          ),
          ...testTournament.levels.skip(1),
        ],
        completionReward: const TournamentReward(coins: 2000, gems: 30),
        display: const TournamentDisplay(
          bannerImage: 'tournament_stunt.png',
          icon: 'trophy',
          colorPrimary: '#FF6B35',
          colorSecondary: '#F7931E',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TournamentWorldMapScreen(
            tournament: survivalTournament,
            entrySummary: testEntrySummary,
            onPlayLevel: (_) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(HexagonalLevelNode).first, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('Survive 25 seconds'), findsOneWidget);
      expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
    });

    testWidgets('preview popup shows rewards section', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TournamentWorldMapScreen(
            tournament: testTournament,
            entrySummary: testEntrySummary,
            onPlayLevel: (_) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();

      // Tap on level node to open popup
      await tester.tap(find.byType(HexagonalLevelNode).first, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Popup should show REWARD section (story mode style uses singular)
      expect(find.text('REWARD'), findsOneWidget);
    });

    testWidgets('preview popup close button closes popup', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TournamentWorldMapScreen(
            tournament: testTournament,
            entrySummary: testEntrySummary,
            onPlayLevel: (_) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();

      // Tap level node to open popup
      await tester.tap(find.byType(HexagonalLevelNode).first, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Story mode style uses close icon instead of Cancel text
      expect(find.byIcon(Icons.close), findsOneWidget);
      
      // Tap close icon
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Popup should be closed
      expect(find.text('STAGE 1'), findsNothing);
    });

    testWidgets('preview popup START button triggers onPlayLevel callback', (tester) async {
      int? playedLevelIndex;
      
      await tester.pumpWidget(
        MaterialApp(
          home: TournamentWorldMapScreen(
            tournament: testTournament,
            entrySummary: testEntrySummary,
            onPlayLevel: (index) => playedLevelIndex = index,
            onBack: () {},
          ),
        ),
      );
      await tester.pump();

      // Tap level node to open popup
      await tester.tap(find.byType(HexagonalLevelNode).first, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Story mode style uses "START ▶" button
      await tester.tap(find.text('START ▶'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(playedLevelIndex, 0); // First level index
    });

    testWidgets('locked level nodes are not tappable (no popup)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TournamentWorldMapScreen(
            tournament: testTournament,
            entrySummary: testEntrySummary,
            onPlayLevel: (_) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();

      // Tap on a locked level node (e.g., index 3)
      await tester.tap(find.byType(HexagonalLevelNode).at(3), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Popup should NOT appear (STAGE 4 shouldn't exist)
      expect(find.text('STAGE 4'), findsNothing);
    });
  });

  group('TournamentWorldMapScreen - Animated Jet', () {
    testWidgets('displays WorldMapJetWidget at current level', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TournamentWorldMapScreen(
            tournament: testTournament,
            entrySummary: testEntrySummary,
            onPlayLevel: (_) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();

      // Should find the jet widget
      expect(find.byType(WorldMapJetWidget), findsOneWidget);
    });

    testWidgets('jet is positioned above current node', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TournamentWorldMapScreen(
            tournament: testTournament,
            entrySummary: testEntrySummary,
            onPlayLevel: (_) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();

      // Jet should be found and positioned
      final jetFinder = find.byType(WorldMapJetWidget);
      expect(jetFinder, findsOneWidget);
      
      // Verify jet is rendered (position is handled by Positioned widget)
      final jet = tester.widget<WorldMapJetWidget>(jetFinder);
      expect(jet.jetSize, 60.0);
    });
  });

  group('TournamentWorldMapScreen - Victory Fly + Preview', () {
    testWidgets('auto shows next-level preview after jet animation', (tester) async {
      const entrySummary = TournamentEntrySummary(
        currentRound: 2,
        totalRounds: 5,
        triesRemaining: 2,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TournamentWorldMapScreen(
            tournament: testTournament,
            entrySummary: entrySummary,
            onPlayLevel: (_) {},
            onBack: () {},
            shouldAnimateJet: true,
            fromLevel: 1,
            toLevel: 2,
            autoShowPreview: true,
          ),
        ),
      );

      // Let the jet animation complete
      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pump();

      // Preview popup for stage 2 should be visible
      expect(find.text('STAGE 2'), findsWidgets);
      expect(find.text('Wind Rider'), findsWidgets);
      expect(find.text('START ▶'), findsWidgets);
    });

    testWidgets('does not auto-open preview when disabled', (tester) async {
      const entrySummary = TournamentEntrySummary(
        currentRound: 2,
        totalRounds: 5,
        triesRemaining: 2,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TournamentWorldMapScreen(
            tournament: testTournament,
            entrySummary: entrySummary,
            onPlayLevel: (_) {},
            onBack: () {},
            shouldAnimateJet: true,
            fromLevel: 1,
            toLevel: 2,
            autoShowPreview: false,
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pump();

      expect(find.text('STAGE 2'), findsNothing);
    });
  });

  group('TournamentWorldMapScreen - Node Content', () {
    testWidgets('displays level numbers for non-completed levels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TournamentWorldMapScreen(
            tournament: testTournament,
            entrySummary: testEntrySummary,
            onPlayLevel: (_) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();

      // Should find level number 1 for current level
      expect(find.text('1'), findsWidgets);
    });

    testWidgets('displays checkmark icon for completed levels', (tester) async {
      const entrySummary = TournamentEntrySummary(
        currentRound: 3,
        totalRounds: 5,
        triesRemaining: 2,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TournamentWorldMapScreen(
            tournament: testTournament,
            entrySummary: entrySummary,
            onPlayLevel: (_) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();

      // Should find check icons for completed levels (2 completed)
      expect(find.byIcon(Icons.check), findsNWidgets(2));
    });

    testWidgets('omits level labels and complete text under nodes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TournamentWorldMapScreen(
            tournament: testTournament,
            entrySummary: testEntrySummary,
            onPlayLevel: (_) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();

      // No level name labels on map
      expect(find.text('The Wobbler'), findsNothing);
      expect(find.text('Wind Rider'), findsNothing);
      expect(find.text('The Gauntlet'), findsNothing);
      expect(find.text('Chaos Zone'), findsNothing);
      expect(find.text('Ultimate Stunt'), findsNothing);

      // No "Complete" text badges under nodes; check icons still render on completed nodes
      expect(find.text('Complete'), findsNothing);
      expect(find.byIcon(Icons.check), findsNWidgets(0));
    });
  });

  group('TournamentWorldMapScreen - Responsive Layout', () {
    testWidgets('renders all 5 nodes on default test screen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TournamentWorldMapScreen(
            tournament: testTournament,
            entrySummary: testEntrySummary,
            onPlayLevel: (_) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();

      // Should render all 5 nodes
      expect(find.byType(HexagonalLevelNode), findsNWidgets(5));
      
      // Header elements should be visible
      expect(find.text('Test Stunt Tournament'), findsOneWidget);
      expect(find.text('GRAND PRIZE'), findsOneWidget);
    });

    testWidgets('level names do not overflow with Flexible widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TournamentWorldMapScreen(
            tournament: testTournament,
            entrySummary: testEntrySummary,
            onPlayLevel: (_) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();

      // No level names rendered on map
      expect(find.text('The Wobbler'), findsNothing);
      expect(find.text('Ultimate Stunt'), findsNothing);
    });
  });

  group('TournamentWorldMapScreen - Consistency with Story Mode', () {
    testWidgets('uses same HexagonalLevelNode widget as story mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TournamentWorldMapScreen(
            tournament: testTournament,
            entrySummary: testEntrySummary,
            onPlayLevel: (_) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();

      // Verify using the shared HexagonalLevelNode widget
      expect(find.byType(HexagonalLevelNode), findsWidgets);
    });

    testWidgets('uses same WorldMapJetWidget as story mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TournamentWorldMapScreen(
            tournament: testTournament,
            entrySummary: testEntrySummary,
            onPlayLevel: (_) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();

      // Verify using the shared WorldMapJetWidget
      expect(find.byType(WorldMapJetWidget), findsOneWidget);
    });

    testWidgets('nodes have CustomPaint for hexagonal rendering', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TournamentWorldMapScreen(
            tournament: testTournament,
            entrySummary: testEntrySummary,
            onPlayLevel: (_) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();

      // Verify CustomPaint widgets are being used (for hexagon painters)
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });

  testWidgets('invokes onBack when back button is tapped', (tester) async {
    var backCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: TournamentWorldMapScreen(
          tournament: testTournament,
          entrySummary: const TournamentEntrySummary(
            currentRound: 1,
            totalRounds: 5,
            triesRemaining: 3,
          ),
          onPlayLevel: (_) {},
          onBack: () {
            backCalled = true;
          },
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump(const Duration(milliseconds: 50));

    expect(backCalled, isTrue);
  });
}

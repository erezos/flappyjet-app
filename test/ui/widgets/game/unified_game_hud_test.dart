/// 🧪 UNIFIED GAME HUD TESTS
/// 
/// Comprehensive tests for the UnifiedGameHUD widget.
/// Verifies all game modes, configurations, and component composition.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/ui/widgets/game/unified_game_hud.dart';
import 'package:flappy_jet_pro/ui/widgets/game/objective_indicator.dart';
import 'package:flappy_jet_pro/ui/widgets/game/in_game_hearts_display.dart';
import 'package:flappy_jet_pro/ui/widgets/game/vs_indicator.dart';
import 'package:flappy_jet_pro/models/level_data_schema.dart';
import 'package:flappy_jet_pro/game/core/jet_skins.dart';

void main() {
  setUpAll(() async {
    await JetSkinCatalog.initializeFromAssets();
  });

  group('GameHUDConfig', () {
    group('factory constructors', () {
      test('storyMode creates correct config', () {
        final config = GameHUDConfig.storyMode(
          objectiveType: ObjectiveType.passObstacles,
          currentProgress: 5,
          targetProgress: 10,
        );
        
        expect(config.objectiveType, equals(ObjectiveType.passObstacles));
        expect(config.currentProgress, equals(5));
        expect(config.targetProgress, equals(10));
        expect(config.showHearts, isTrue);
        expect(config.isVsBattle, isFalse);
        expect(config.heartsShowBackground, isFalse);
      });
      
      test('storyMode with beatBot enables VS battle', () {
        final config = GameHUDConfig.storyMode(
          objectiveType: ObjectiveType.beatBot,
          currentProgress: 3,
          targetProgress: 1,
          botScore: 2,
          botIsActive: true,
        );
        
        expect(config.isVsBattle, isTrue);
        expect(config.opponentScore, equals(2));
        expect(config.opponentIsActive, isTrue);
      });
      
      test('stuntTournament creates correct config', () {
        final config = GameHUDConfig.stuntTournament(
          currentProgress: 10,
          targetProgress: 30,
        );
        
        expect(config.objectiveType, equals(ObjectiveType.surviveTime));
        expect(config.currentProgress, equals(10));
        expect(config.targetProgress, equals(30));
        expect(config.showHearts, isTrue);
        expect(config.heartsShowBackground, isTrue);
        expect(config.isVsBattle, isFalse);
      });
      
      test('playoffBattle creates correct config', () {
        final config = GameHUDConfig.playoffBattle(
          playerScore: 7,
          opponentSkinId: 'storm_ace',
          opponentName: 'Storm Ace',
          opponentScore: 5,
          opponentIsActive: true,
        );
        
        expect(config.objectiveType, equals(ObjectiveType.beatBot));
        expect(config.currentProgress, equals(7));
        expect(config.isVsBattle, isTrue);
        expect(config.opponentSkinId, equals('storm_ace'));
        expect(config.opponentName, equals('Storm Ace'));
        expect(config.opponentScore, equals(5));
      });
      
      test('minimal creates correct config', () {
        final config = GameHUDConfig.minimal(
          objectiveType: ObjectiveType.passObstacles,
          currentProgress: 3,
          targetProgress: 5,
        );
        
        expect(config.showHearts, isFalse);
        expect(config.isVsBattle, isFalse);
      });
    });
    
    test('copyWith preserves unchanged values', () {
      final original = GameHUDConfig.storyMode(
        objectiveType: ObjectiveType.passObstacles,
        currentProgress: 5,
        targetProgress: 10,
      );
      
      final copied = original.copyWith(currentProgress: 7);
      
      expect(copied.objectiveType, equals(ObjectiveType.passObstacles));
      expect(copied.currentProgress, equals(7));
      expect(copied.targetProgress, equals(10));
    });
  });
  
  group('UnifiedGameHUD', () {
    testWidgets('renders story mode HUD correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnifiedGameHUD(
              config: GameHUDConfig.storyMode(
                objectiveType: ObjectiveType.passObstacles,
                currentProgress: 3,
                targetProgress: 10,
              ),
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Should have objective indicator
      expect(find.byType(ObjectiveIndicator), findsOneWidget);
      // Should have hearts display
      expect(find.byType(InGameHeartsDisplay), findsOneWidget);
    });
    
    testWidgets('renders stunt tournament HUD correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnifiedGameHUD(
              config: GameHUDConfig.stuntTournament(
                currentProgress: 15,
                targetProgress: 30,
              ),
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Should have time-based objective indicator
      expect(find.byType(ObjectiveIndicator), findsOneWidget);
      expect(find.text('15s'), findsOneWidget); // 30 - 15 = 15s remaining
      
      // Should have hearts display
      expect(find.byType(InGameHeartsDisplay), findsOneWidget);
    });
    
    testWidgets('renders playoff battle HUD with VS indicator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnifiedGameHUD(
              config: GameHUDConfig.playoffBattle(
                playerScore: 7,
                opponentSkinId: 'sky_rookie',
                opponentName: 'Test Opponent',
                opponentScore: 5,
                opponentIsActive: true,
              ),
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Should have VS indicator
      expect(find.byType(VSIndicator), findsOneWidget);
      expect(find.text('VS'), findsOneWidget);
    });
    
    testWidgets('hides hearts when configured', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnifiedGameHUD(
              config: GameHUDConfig.minimal(
                objectiveType: ObjectiveType.passObstacles,
                currentProgress: 3,
                targetProgress: 10,
              ),
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Should NOT have hearts display
      expect(find.byType(InGameHeartsDisplay), findsNothing);
    });
    
    testWidgets('supports custom hearts count', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnifiedGameHUD(
              config: const GameHUDConfig(
                objectiveType: ObjectiveType.surviveTime,
                currentProgress: 10,
                targetProgress: 30,
                customHearts: 2,
                customMaxHearts: 3,
              ),
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Should have hearts display
      expect(find.byType(InGameHeartsDisplay), findsOneWidget);
    });
    
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnifiedGameHUD(
              config: GameHUDConfig.storyMode(
                objectiveType: ObjectiveType.passObstacles,
                currentProgress: 0,
                targetProgress: 10,
              ),
              child: const Center(
                child: Text('Game Content'),
              ),
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      expect(find.text('Game Content'), findsOneWidget);
    });
    
    testWidgets('uses SafeArea', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnifiedGameHUD(
              config: GameHUDConfig.storyMode(
                objectiveType: ObjectiveType.passObstacles,
                currentProgress: 0,
                targetProgress: 10,
              ),
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      expect(find.byType(SafeArea), findsOneWidget);
    });
  });
  
  group('ScoreCounterHUD', () {
    testWidgets('displays score correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: ScoreCounterHUD(score: 42),
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      expect(find.text('42'), findsOneWidget);
    });
    
    testWidgets('animates on score change', (tester) async {
      int score = 0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Column(
                  children: [
                    ScoreCounterHUD(score: score),
                    ElevatedButton(
                      onPressed: () => setState(() => score++),
                      child: const Text('Increment'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
      
      expect(find.text('0'), findsOneWidget);
      
      await tester.tap(find.text('Increment'));
      await tester.pump();
      
      // Animation should start
      expect(find.text('1'), findsOneWidget);
    });
    
    testWidgets('displays large scores', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ScoreCounterHUD(score: 999),
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      expect(find.text('999'), findsOneWidget);
    });
  });
}


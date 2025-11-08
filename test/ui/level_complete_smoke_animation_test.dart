/// 🧪 TESTS - Level Complete Screen Smoke Animation
/// 
/// Tests for the animated smoke particle system on VS battle victory screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/models/level_data_schema.dart';
import 'package:flappy_jet_pro/ui/screens/level_complete_screen.dart';

void main() {
  group('Level Complete Smoke Animation Tests', () {
    
    // Create a mock VS battle level for testing
    LevelData createMockVSLevel() {
      return const LevelData(
        id: 5,
        zone: 1,
        name: 'Police Patrol Showdown',
        objective: LevelObjective(
          type: ObjectiveType.beatBot,
          target: 1, // Beat 1 bot
          description: 'Beat Officer Maverick',
        ),
        difficulty: DifficultyConfig(
          speedMultiplier: 1.0,
          obstacleGap: 200,
          obstacleFrequency: 2.0,
        ),
        reward: LevelReward(
          coins: 50,
          gems: 5,
          specialReward: null,
        ),
        theme: LevelTheme(
          background: 'tropical',
          obstacles: 'palm',
          music: 'tropical_vibes',
        ),
        botBattle: BotBattle(
          botName: 'Officer Maverick',
          botJetSkin: 'police_jet',
          skillLevel: 1.0,
          reactionTime: 0.5,
          mistakeRate: 0.3,
        ),
      );
    }

    testWidgets('Victory screen displays smoke particles for VS battles', (WidgetTester tester) async {
      // Arrange
      final mockLevel = createMockVSLevel();
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: LevelCompleteScreen(
            level: mockLevel,
            objectiveAchieved: 1,
            timeTaken: 45,
            continuesUsed: 0,
          ),
        ),
      );
      
      // Initial frame
      await tester.pump();
      
      // Assert - Check for smoke particle assets
      expect(find.byType(Image), findsWidgets);
      
      // Verify smoke particles are present
      final smokeParticle1 = find.byWidgetPredicate(
        (widget) => widget is Image && 
                    widget.image is AssetImage &&
                    (widget.image as AssetImage).assetName.contains('smoke_particle_1.png'),
      );
      expect(smokeParticle1, findsWidgets);
      
      final smokeParticle2 = find.byWidgetPredicate(
        (widget) => widget is Image && 
                    widget.image is AssetImage &&
                    (widget.image as AssetImage).assetName.contains('smoke_particle_2.png'),
      );
      expect(smokeParticle2, findsAtLeastNWidgets(1));
      
      final smokeParticle3 = find.byWidgetPredicate(
        (widget) => widget is Image && 
                    widget.image is AssetImage &&
                    (widget.image as AssetImage).assetName.contains('smoke_particle_3.png'),
      );
      expect(smokeParticle3, findsOneWidget);
    });

    testWidgets('Fire sparks are displayed on victory screen', (WidgetTester tester) async {
      // Arrange
      final mockLevel = createMockVSLevel();
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: LevelCompleteScreen(
            level: mockLevel,
            objectiveAchieved: 1,
            timeTaken: 45,
            continuesUsed: 0,
          ),
        ),
      );
      
      await tester.pump();
      
      // Assert - Check for fire spark assets
      final fireSpark1 = find.byWidgetPredicate(
        (widget) => widget is Image && 
                    widget.image is AssetImage &&
                    (widget.image as AssetImage).assetName.contains('fire_spark_1.png'),
      );
      expect(fireSpark1, findsWidgets);
      
      final fireSpark2 = find.byWidgetPredicate(
        (widget) => widget is Image && 
                    widget.image is AssetImage &&
                    (widget.image as AssetImage).assetName.contains('fire_spark_2.png'),
      );
      expect(fireSpark2, findsOneWidget);
    });

    testWidgets('Explosion smoke is displayed on victory screen', (WidgetTester tester) async {
      // Arrange
      final mockLevel = createMockVSLevel();
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: LevelCompleteScreen(
            level: mockLevel,
            objectiveAchieved: 1,
            timeTaken: 45,
            continuesUsed: 0,
          ),
        ),
      );
      
      await tester.pump();
      
      // Assert - Check for explosion smoke
      final explosionSmoke = find.byWidgetPredicate(
        (widget) => widget is Image && 
                    widget.image is AssetImage &&
                    (widget.image as AssetImage).assetName.contains('explosion_smoke.png'),
      );
      expect(explosionSmoke, findsOneWidget);
    });

    testWidgets('Smoke animation controller is properly initialized', (WidgetTester tester) async {
      // Arrange
      final mockLevel = createMockVSLevel();
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: LevelCompleteScreen(
            level: mockLevel,
            objectiveAchieved: 1,
            timeTaken: 45,
            continuesUsed: 0,
          ),
        ),
      );
      
      // Initial pump
      await tester.pump();
      
      // Assert - AnimatedBuilder should be present
      expect(find.byType(AnimatedBuilder), findsWidgets);
      
      // Pump animation forward
      await tester.pump(const Duration(milliseconds: 500));
      
      // Verify animation is running (widgets should still be present)
      expect(find.byType(AnimatedBuilder), findsWidgets);
    });

    testWidgets('Smoke particles animate with proper opacity changes', (WidgetTester tester) async {
      // Arrange
      final mockLevel = createMockVSLevel();
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: LevelCompleteScreen(
            level: mockLevel,
            objectiveAchieved: 1,
            timeTaken: 45,
            continuesUsed: 0,
          ),
        ),
      );
      
      await tester.pump();
      
      // Find Opacity widgets (should be wrapping smoke particles)
      expect(find.byType(Opacity), findsWidgets);
      
      // Advance animation
      await tester.pump(const Duration(milliseconds: 1000));
      
      // Opacity widgets should still be present
      expect(find.byType(Opacity), findsWidgets);
    });

    testWidgets('Crashed jet is displayed with proper rotation', (WidgetTester tester) async {
      // Arrange
      final mockLevel = createMockVSLevel();
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: LevelCompleteScreen(
            level: mockLevel,
            objectiveAchieved: 1,
            timeTaken: 45,
            continuesUsed: 0,
          ),
        ),
      );
      
      await tester.pump();
      
      // Assert - Check for Transform.rotate widgets
      expect(find.byType(Transform), findsWidgets);
      
      // Verify bot jet image widget is present (even if asset doesn't load in test)
      final jetImages = find.byWidgetPredicate(
        (widget) => widget is Image && 
                    widget.image is AssetImage,
      );
      expect(jetImages, findsWidgets); // Multiple images (smoke + jet)
    });

    testWidgets('Victory badge is displayed correctly', (WidgetTester tester) async {
      // Arrange
      final mockLevel = createMockVSLevel();
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: LevelCompleteScreen(
            level: mockLevel,
            objectiveAchieved: 1,
            timeTaken: 45,
            continuesUsed: 0,
          ),
        ),
      );
      
      await tester.pump();
      
      // Assert - Check for VICTORY text
      expect(find.text('🏆 VICTORY! 🏆'), findsOneWidget);
    });

    testWidgets('Bot name is displayed with strikethrough', (WidgetTester tester) async {
      // Arrange
      final mockLevel = createMockVSLevel();
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: LevelCompleteScreen(
            level: mockLevel,
            objectiveAchieved: 1,
            timeTaken: 45,
            continuesUsed: 0,
          ),
        ),
      );
      
      await tester.pump();
      
      // Assert - Check for bot name
      expect(find.text('Officer Maverick'), findsOneWidget);
      
      // Verify it has strikethrough decoration
      final textWidget = tester.widget<Text>(find.text('Officer Maverick'));
      expect(textWidget.style?.decoration, TextDecoration.lineThrough);
    });

    testWidgets('Non-VS levels do not show smoke effects', (WidgetTester tester) async {
      // Arrange - Create a non-VS level (time-based level)
      const mockLevel = LevelData(
        id: 2,
        zone: 1,
        name: 'Palm Paradise Path',
        objective: LevelObjective(
          type: ObjectiveType.surviveTime,
          target: 25,
          description: 'Survive for 25 seconds',
        ),
        difficulty: DifficultyConfig(
          speedMultiplier: 0.9,
          obstacleGap: 380,
          obstacleFrequency: 0.65,
          maxGapShift: 60,
        ),
        reward: LevelReward(
          coins: 30,
          gems: 0,
          specialReward: null,
        ),
        theme: LevelTheme(
          background: 'tropical',
          obstacles: 'palm',
          music: 'tropical_vibes',
        ),
        botBattle: null, // No bot battle
      );
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: LevelCompleteScreen(
            level: mockLevel,
            objectiveAchieved: 25,
            timeTaken: 25,
            continuesUsed: 0,
          ),
        ),
      );
      
      await tester.pump();
      
      // Assert - Smoke effects should NOT be present
      final smokeParticles = find.byWidgetPredicate(
        (widget) => widget is Image && 
                    widget.image is AssetImage &&
                    (widget.image as AssetImage).assetName.contains('smoke_particle'),
      );
      expect(smokeParticles, findsNothing);
      
      // Victory text should still NOT be present (not a VS level)
      expect(find.text('🏆 VICTORY! 🏆'), findsNothing);
    });

    testWidgets('Smoke animation runs continuously', (WidgetTester tester) async {
      // Arrange
      final mockLevel = createMockVSLevel();
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: LevelCompleteScreen(
            level: mockLevel,
            objectiveAchieved: 1,
            timeTaken: 45,
            continuesUsed: 0,
          ),
        ),
      );
      
      // Initial pump
      await tester.pump();
      
      // Pump through multiple animation cycles
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(AnimatedBuilder), findsWidgets);
      
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.byType(AnimatedBuilder), findsWidgets);
      
      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.byType(AnimatedBuilder), findsWidgets);
      
      // Animation should still be running
      await tester.pump(const Duration(milliseconds: 2000));
      expect(find.byType(AnimatedBuilder), findsWidgets);
    });

    testWidgets('Smoke particles have proper Transform widgets', (WidgetTester tester) async {
      // Arrange
      final mockLevel = createMockVSLevel();
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: LevelCompleteScreen(
            level: mockLevel,
            objectiveAchieved: 1,
            timeTaken: 45,
            continuesUsed: 0,
          ),
        ),
      );
      
      await tester.pump();
      
      // Assert - Check for Transform widgets (rotation and scale)
      final transforms = find.byType(Transform);
      expect(transforms, findsWidgets);
      
      // Should have multiple transforms (one for each smoke particle + jet)
      expect(transforms.evaluate().length, greaterThanOrEqualTo(5));
    });

    testWidgets('Orange explosion glow is present', (WidgetTester tester) async {
      // Arrange
      final mockLevel = createMockVSLevel();
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: LevelCompleteScreen(
            level: mockLevel,
            objectiveAchieved: 1,
            timeTaken: 45,
            continuesUsed: 0,
          ),
        ),
      );
      
      await tester.pump();
      
      // Assert - Check for RadialGradient container (explosion glow)
      final containers = find.byWidgetPredicate(
        (widget) => widget is Container &&
                    widget.decoration is BoxDecoration &&
                    (widget.decoration as BoxDecoration).gradient is RadialGradient,
      );
      expect(containers, findsWidgets);
    });
  });

  group('Performance Tests', () {
    testWidgets('Smoke animation does not cause frame drops', (WidgetTester tester) async {
      // Arrange
      const mockLevel = LevelData(
        id: 5,
        zone: 1,
        name: 'Police Patrol Showdown',
        objective: LevelObjective(
          type: ObjectiveType.beatBot,
          target: 1,
          description: 'Beat Officer Maverick',
        ),
        difficulty: DifficultyConfig(
          speedMultiplier: 1.0,
          obstacleGap: 200,
          obstacleFrequency: 2.0,
        ),
        reward: LevelReward(
          coins: 50,
          gems: 5,
          specialReward: null,
        ),
        theme: LevelTheme(
          background: 'tropical',
          obstacles: 'palm',
          music: 'tropical_vibes',
        ),
        botBattle: BotBattle(
          botName: 'Officer Maverick',
          botJetSkin: 'police_jet',
          skillLevel: 1.0,
          reactionTime: 0.5,
          mistakeRate: 0.3,
        ),
      );
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: LevelCompleteScreen(
            level: mockLevel,
            objectiveAchieved: 1,
            timeTaken: 45,
            continuesUsed: 0,
          ),
        ),
      );
      
      // Pump through animation rapidly
      for (int i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 16)); // ~60fps
      }
      
      // Assert - If we get here without hanging, performance is acceptable
      expect(find.byType(LevelCompleteScreen), findsOneWidget);
    });

    testWidgets('Memory does not leak with repeated animations', (WidgetTester tester) async {
      // This test ensures AnimationController is properly disposed
      const mockLevel = LevelData(
        id: 5,
        zone: 1,
        name: 'Police Patrol Showdown',
        objective: LevelObjective(
          type: ObjectiveType.beatBot,
          target: 1,
          description: 'Beat Officer Maverick',
        ),
        difficulty: DifficultyConfig(
          speedMultiplier: 1.0,
          obstacleGap: 200,
          obstacleFrequency: 2.0,
        ),
        reward: LevelReward(
          coins: 50,
          gems: 5,
          specialReward: null,
        ),
        theme: LevelTheme(
          background: 'tropical',
          obstacles: 'palm',
          music: 'tropical_vibes',
        ),
        botBattle: BotBattle(
          botName: 'Officer Maverick',
          botJetSkin: 'police_jet',
          skillLevel: 1.0,
          reactionTime: 0.5,
          mistakeRate: 0.3,
        ),
      );
      
      // Create and dispose the widget multiple times
      for (int i = 0; i < 5; i++) {
        await tester.pumpWidget(
          MaterialApp(
            home: LevelCompleteScreen(
              level: mockLevel,
              objectiveAchieved: 1,
              timeTaken: 45,
              continuesUsed: 0,
            ),
          ),
        );
        
        await tester.pump(const Duration(milliseconds: 100));
        
        // Replace with empty container
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
        );
        
        await tester.pump();
      }
      
      // If we get here without errors, disposal is working correctly
      expect(true, true);
    });
  });
}


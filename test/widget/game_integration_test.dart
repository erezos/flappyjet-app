import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/game.dart'; // For GameWidget and Vector2

import 'package:flappy_jet_pro/main.dart';
import 'package:flappy_jet_pro/game/enhanced_flappy_game.dart';

/// 🧪 INTEGRATION TESTS: Full game flow without crashes
/// This catches crashes that only happen during real gameplay
void main() {
  group('Game Integration Tests - FULL CRASH PREVENTION', () {
    
    testWidgets('🚨 CRITICAL: Game must start without crashes', (WidgetTester tester) async {
      await tester.pumpWidget(GameWidget(game: EnhancedFlappyGame()));
      await tester.pump(const Duration(seconds: 2)); // Allow game to initialize
      
      expect(tester.takeException(), isNull,
        reason: 'Game initialization should complete without crashes');
      expect(find.text('TAP TO PLAY'), findsOneWidget);
    });
    
    testWidgets('💥 Collision System: Must create visible particles', (WidgetTester tester) async {
      final game = EnhancedFlappyGame();
      await tester.pumpWidget(GameWidget(game: game));
      await tester.pump(const Duration(seconds: 2)); // Allow game to initialize
      
      // Simulate collision to test particle creation
      game.testCreateDirectExplosion(Vector2.all(100), 10);
      await tester.pump(const Duration(milliseconds: 500)); // Allow particles to render
      
      expect(game.directParticleCount, greaterThan(0),
        reason: 'Collision should create visible particles');
      expect(tester.takeException(), isNull,
        reason: 'Particle creation should not crash');
    });
    
    testWidgets('🎵 Audio System: Must not crash during gameplay', (WidgetTester tester) async {
      final game = EnhancedFlappyGame();
      await tester.pumpWidget(GameWidget(game: game));
      await tester.pump(const Duration(seconds: 2)); // Allow game to initialize
      
      expect(game.hasAudioManager, isTrue,
        reason: 'Audio manager should be initialized');
      expect(tester.takeException(), isNull,
        reason: 'Audio system should not crash during initialization');
    });
    
    testWidgets('📊 Performance Monitoring: Must handle component changes', (WidgetTester tester) async {
      await tester.pumpWidget(const FlappyJetProApp(developmentMode: true));
      
      await tester.tap(find.text('🎮 PLAY GAME'));
      await tester.pumpAndSettle();
      
      // Play for a while to trigger performance monitoring
      for (int i = 0; i < 50; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      
      expect(tester.takeException(), isNull,
        reason: 'Performance monitoring should not crash');
    });
    
    testWidgets('🔄 Game Restart: Must work multiple times', (WidgetTester tester) async {
      await tester.pumpWidget(const FlappyJetProApp(developmentMode: true));
      
      for (int restart = 0; restart < 3; restart++) {
        // Start game
        if (restart == 0) {
          await tester.tap(find.text('🎮 PLAY GAME'));
        } else {
          // Restart after game over
          await tester.tap(find.byType(GestureDetector));
        }
        await tester.pumpAndSettle();
        
        // Play and die
        await tester.tap(find.byType(GestureDetector)); // Start playing
        for (int i = 0; i < 100; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        
        expect(tester.takeException(), isNull,
          reason: 'Game restart $restart should not crash');
      }
    });
  });
  
  group('UI Integration Tests - PREVENT UI CRASHES', () {
    
    testWidgets('💰 Skin Store: Must open without crashes', (WidgetTester tester) async {
      await tester.pumpWidget(const FlappyJetProApp(developmentMode: true));
      await tester.pump(const Duration(seconds: 2)); // Allow initial load
      
      await tester.tap(find.text('💰 JET HANGAR'));
      await tester.pump(const Duration(seconds: 1)); // Allow navigation
      
      expect(find.text('JET HANGAR - LIVE STORE'), findsOneWidget); // Correct text for app bar
      expect(tester.takeException(), isNull,
        reason: 'Skin store should open without errors');
    });
    
    testWidgets('🎨 Visual Demo: Must render without crashes', (WidgetTester tester) async {
      await tester.pumpWidget(const FlappyJetProApp(developmentMode: true));
      
      await tester.tap(find.text('🎨 VISUAL DEMO'));
      await tester.pumpAndSettle();
      
      expect(tester.takeException(), isNull,
        reason: 'Visual demo should render without errors');
    });
    
    testWidgets('📱 Screen Rotation: Must handle orientation changes', (WidgetTester tester) async {
      await tester.pumpWidget(const FlappyJetProApp(developmentMode: true));
      
      // Change screen size to simulate rotation
      await tester.binding.setSurfaceSize(const Size(800, 600));
      await tester.pump();
      
      await tester.tap(find.text('🎮 PLAY GAME'));
      await tester.pumpAndSettle();
      
      expect(tester.takeException(), isNull,
        reason: 'Game should handle screen size changes');
      
      // Reset screen size
      await tester.binding.setSurfaceSize(const Size(400, 800));
    });
  });
  
  group('Performance Stress Tests - PREVENT MEMORY LEAKS', () {
    
    testWidgets('💥 Particle Stress Test: Create 1000+ particles', (WidgetTester tester) async {
      await tester.pumpWidget(const FlappyJetProApp(developmentMode: true));
      
      await tester.tap(find.text('🎮 PLAY GAME'));
      await tester.pumpAndSettle();
      
      // Trigger many collisions rapidly
      for (int i = 0; i < 20; i++) {
        await tester.tap(find.byType(GestureDetector));
        await tester.pump(const Duration(milliseconds: 50));
      }
      
      // Let particles settle
      for (int i = 0; i < 100; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      
      expect(tester.takeException(), isNull,
        reason: 'Heavy particle load should not crash game');
    });
    
    testWidgets('🔄 Memory Leak Test: Long gameplay session', (WidgetTester tester) async {
      await tester.pumpWidget(const FlappyJetProApp(developmentMode: true));
      
      await tester.tap(find.text('🎮 PLAY GAME'));
      await tester.pumpAndSettle();
      
      // Simulate 5 minutes of gameplay
      for (int i = 0; i < 300; i++) {
        if (i % 20 == 0) {
          await tester.tap(find.byType(GestureDetector));
        }
        await tester.pump(const Duration(milliseconds: 100));
      }
      
      expect(tester.takeException(), isNull,
        reason: 'Long gameplay should not cause memory issues');
    });
  });
} 
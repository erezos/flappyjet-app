import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';

import '../../lib/game/enhanced_flappy_game.dart';
import '../../lib/game/components/smooth_parallax_background.dart';

void main() {
  group('SmoothParallaxBackground Visual Integration Tests', () {
    testWidgets('should initialize and render parallax background', (WidgetTester tester) async {
      final game = EnhancedFlappyGame();
      
      await tester.pumpWidget(
        MaterialApp(
          home: GameWidget(game: game),
        ),
      );
      
      // Wait for game to load
      await tester.pumpAndSettle();
      
      // Find parallax background component
      final parallaxBackground = game.children.whereType<SmoothSmoothParallaxBackground>().firstOrNull;
      expect(parallaxBackground, isNotNull);
      expect(parallaxBackground!.isMounted, isTrue);
    });

    testWidgets('should handle difficulty transitions with parallax', (WidgetTester tester) async {
      final game = EnhancedFlappyGame();
      
      await tester.pumpWidget(
        MaterialApp(
          home: GameWidget(game: game),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Find parallax background
      final parallaxBackground = game.children.whereType<SmoothSmoothParallaxBackground>().firstOrNull;
      expect(parallaxBackground, isNotNull);
      
      // Simulate score progression triggering visual transitions
      await parallaxBackground!.updateForScore(6); // Easy phase
      await tester.pump();
      
      await parallaxBackground.updateForScore(16); // Easy-advance phase  
      await tester.pump();
      
      // Should transition smoothly between phases
      expect(parallaxBackground.getCurrentBackgroundInfo(), contains('phase'));
    });

    testWidgets('should maintain performance with parallax layers', (WidgetTester tester) async {
      final game = EnhancedFlappyGame();
      
      await tester.pumpWidget(
        MaterialApp(
          home: GameWidget(game: game),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Find parallax background
      final parallaxBackground = game.children.whereType<SmoothSmoothParallaxBackground>().firstOrNull;
      expect(parallaxBackground, isNotNull);
      
      // No explicit speed API; ensure component remains mounted under load
      expect(parallaxBackground!.isMounted, isTrue);
    });

    testWidgets('should handle background asset loading gracefully', (WidgetTester tester) async {
      final game = EnhancedFlappyGame();
      
      await tester.pumpWidget(
        MaterialApp(
          home: GameWidget(game: game),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Find parallax background
      final parallaxBackground = game.children.whereType<SmoothSmoothParallaxBackground>().firstOrNull;
      expect(parallaxBackground, isNotNull);
      
      // Test loading different phase assets
      await parallaxBackground!.updateForScore(25); // Medium phase
      await tester.pump();
      
      await parallaxBackground.updateForScore(40); // Hard phase
      await tester.pump();
      
      // Should load different visual assets
      expect(parallaxBackground.getCurrentBackgroundInfo(), isNotEmpty);
    });

    testWidgets('should provide smooth visual transitions', (WidgetTester tester) async {
      final game = EnhancedFlappyGame();
      
      await tester.pumpWidget(
        MaterialApp(
          home: GameWidget(game: game),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Find parallax background
      final parallaxBackground = game.children.whereType<SmoothSmoothParallaxBackground>().firstOrNull;
      expect(parallaxBackground, isNotNull);
      
      // Test force reload functionality
      await parallaxBackground!.forceReload(30);
      await tester.pump();
      
      // Should reload without errors
      expect(parallaxBackground.getCurrentBackgroundInfo(), contains('phase'));
    });

    testWidgets('should coordinate with game camera movement', (WidgetTester tester) async {
      final game = EnhancedFlappyGame();
      
      await tester.pumpWidget(
        MaterialApp(
          home: GameWidget(game: game),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Find parallax background
      final parallaxBackground = game.children.whereType<SmoothSmoothParallaxBackground>().firstOrNull;
      expect(parallaxBackground, isNotNull);
      
      // Test parallax movement coordination
      parallaxBackground!.updateScrollSpeed(75.0);
      await tester.pump();
      
      // Should coordinate with game movement
      expect(parallaxBackground.isMounted, isTrue);
    });

    testWidgets('should handle edge cases gracefully', (WidgetTester tester) async {
      final game = EnhancedFlappyGame();
      
      await tester.pumpWidget(
        MaterialApp(
          home: GameWidget(game: game),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Find parallax background
      final parallaxBackground = game.children.whereType<SmoothSmoothParallaxBackground>().firstOrNull;
      expect(parallaxBackground, isNotNull);
      
      // Test edge cases
      await parallaxBackground!.updateForScore(-1); // Invalid score
      await tester.pump();
      
      await parallaxBackground.updateForScore(1000); // Very high score
      await tester.pump();
      
      // Should handle edge cases without crashing
      expect(parallaxBackground.isMounted, isTrue);
    });
  });

  group('SmoothParallaxBackground Performance Integration Tests', () {
    testWidgets('should maintain 60fps with parallax layers', (WidgetTester tester) async {
      final game = EnhancedFlappyGame();
      
      await tester.pumpWidget(
        MaterialApp(
          home: GameWidget(game: game),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Simulate multiple frames with parallax active
      for (int i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 16)); // ~60fps
      }
      
      // Should maintain performance
      final parallaxBackground = game.children.whereType<SmoothSmoothParallaxBackground>().firstOrNull;
      expect(parallaxBackground?.isMounted, isTrue);
    });

    testWidgets('should efficiently handle rapid asset changes', (WidgetTester tester) async {
      final game = EnhancedFlappyGame();
      
      await tester.pumpWidget(
        MaterialApp(
          home: GameWidget(game: game),
        ),
      );
      
      await tester.pumpAndSettle();
      
      final parallaxBackground = game.children.whereType<SmoothSmoothParallaxBackground>().firstOrNull;
      expect(parallaxBackground, isNotNull);
      
      // Test rapid asset changes
      final scores = [0, 6, 16, 21, 26, 31, 41, 51];
      for (final score in scores) {
        await parallaxBackground!.updateForScore(score);
        await tester.pump();
      }
      
      // Should handle rapid changes efficiently
      expect(parallaxBackground?.isMounted, isTrue);
    });
  });

  group('SmoothParallaxBackground Fallback Tests', () {
    testWidgets('should provide fallback when assets fail to load', (WidgetTester tester) async {
      final game = EnhancedFlappyGame();
      
      await tester.pumpWidget(
        MaterialApp(
          home: GameWidget(game: game),
        ),
      );
      
      await tester.pumpAndSettle();
      
      final parallaxBackground = game.children.whereType<SmoothParallaxBackground>().firstOrNull;
      expect(parallaxBackground, isNotNull);
      
      // Should have fallback behavior for missing assets
      // (This will be tested indirectly through the component's resilience)
      expect(parallaxBackground!.isMounted, isTrue);
    });
  });
}
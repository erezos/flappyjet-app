/// 🧪 Refactored Components Test Suite - Ensure new architecture works
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../lib/game/systems/particle_system.dart';
import '../../lib/game/systems/game_state_manager.dart';
import '../../lib/game/components/enhanced_hud.dart';
import '../../lib/game/components/explosion_particle.dart';
import '../../lib/game/core/game_themes.dart';

void main() {
  group('Refactored Components Tests', () {
    group('ParticleSystem', () {
      late ParticleSystem particleSystem;

      setUp(() {
        particleSystem = ParticleSystem();
      });

      test('should create score burst particles', () {
        final position = Vector2(100, 100);
        final theme = GameThemes.skyRookie;
        
        particleSystem.createScoreBurst(position, theme, 10);
        
        final metrics = particleSystem.getPerformanceMetrics();
        expect(metrics['active_particles'], greaterThan(0));
        expect(metrics['active_particles'], lessThanOrEqualTo(20));
      });

      test('should create jet trail particles', () {
        final position = Vector2(50, 50);
        final velocity = Vector2(100, -50);
        final theme = GameThemes.skyRookie;
        
        particleSystem.createJetTrail(position, velocity, theme);
        
        final metrics = particleSystem.getPerformanceMetrics();
        expect(metrics['active_particles'], equals(3));
      });

      test('should respect particle limit', () {
        final position = Vector2(100, 100);
        final theme = GameThemes.skyRookie;
        
        // Create way more particles than the limit
        for (int i = 0; i < 50; i++) {
          particleSystem.createScoreBurst(position, theme, 100);
        }
        
        final metrics = particleSystem.getPerformanceMetrics();
        expect(metrics['active_particles'], lessThanOrEqualTo(200));
      });

      test('should update and remove dead particles', () {
        final position = Vector2(100, 100);
        final theme = GameThemes.skyRookie;
        
        particleSystem.createScoreBurst(position, theme, 5);
        
        // Update particles for a long time to kill them
        for (int i = 0; i < 100; i++) {
          particleSystem.update(0.1); // 10 seconds total
        }
        
        final metrics = particleSystem.getPerformanceMetrics();
        expect(metrics['active_particles'], equals(0));
      });

      test('should clear all particles', () {
        final position = Vector2(100, 100);
        final theme = GameThemes.skyRookie;
        
        particleSystem.createScoreBurst(position, theme, 10);
        particleSystem.clearAll();
        
        final metrics = particleSystem.getPerformanceMetrics();
        expect(metrics['active_particles'], equals(0));
      });
    });

    group('GameStateManager', () {
      late GameStateManager gameState;

      setUp(() {
        gameState = GameStateManager();
      });

      test('should start in waiting state', () {
        expect(gameState.currentState, equals(GameState.waitingToStart));
        expect(gameState.isWaitingToStart, isTrue);
        expect(gameState.isPlaying, isFalse);
        expect(gameState.isGameOver, isFalse);
      });

      test('should transition states correctly', () {
        // Start game
        gameState.startGame();
        expect(gameState.currentState, equals(GameState.playing));
        expect(gameState.isPlaying, isTrue);

        // End game
        gameState.endGame();
        expect(gameState.currentState, equals(GameState.gameOver));
        expect(gameState.isGameOver, isTrue);

        // Reset game
        gameState.resetGame();
        expect(gameState.currentState, equals(GameState.waitingToStart));
        expect(gameState.isWaitingToStart, isTrue);
      });

      test('should manage score correctly', () {
        expect(gameState.score, equals(0));
        
        gameState.incrementScore();
        expect(gameState.score, equals(1));
        
        gameState.setScore(10);
        expect(gameState.score, equals(10));
        
        // End game with high score
        gameState.endGame();
        expect(gameState.bestScore, equals(10));
      });

      test('should manage lives correctly', () {
        expect(gameState.lives, equals(3));
        
        gameState.decrementLives();
        expect(gameState.lives, equals(2));
        
        gameState.addLife();
        expect(gameState.lives, equals(3));
        
        gameState.setLives(6);
        expect(gameState.lives, equals(6));
      });

      test('should manage continues correctly', () {
        expect(gameState.continuesUsedThisRun, equals(0));
        expect(gameState.canContinueWithAd(), isTrue);
        expect(gameState.continuesRemaining, equals(5));
        
        // Use all continues
        for (int i = 0; i < 5; i++) {
          gameState.incrementContinues();
        }
        
        expect(gameState.continuesUsedThisRun, equals(5));
        expect(gameState.canContinueWithAd(), isFalse);
        expect(gameState.continuesRemaining, equals(0));
      });

      test('should manage theme correctly', () {
        expect(gameState.currentTheme, equals(GameThemes.skyRookie));
        
        gameState.setTheme(GameThemes.spaceCadet);
        expect(gameState.currentTheme, equals(GameThemes.spaceCadet));
      });

      test('should provide debug info', () {
        gameState.setScore(42);
        gameState.setTheme(GameThemes.spaceCadet);
        
        final debugInfo = gameState.getDebugInfo();
        expect(debugInfo['score'], equals(42));
        expect(debugInfo['theme'], equals('Space Cadet'));
        expect(debugInfo['state'], contains('waitingToStart'));
      });
    });

    group('EnhancedHUD', () {
      test('should initialize with correct values', () {
        final hud = EnhancedHUD(3, 6);
        
        expect(hud.currentLives, equals(3));
        expect(hud.currentScore, equals(0));
      });

      test('should update score correctly', () {
        final hud = EnhancedHUD(3, 6);
        
        hud.updateScore(42);
        expect(hud.currentScore, equals(42));
      });

      test('should update lives correctly', () {
        final hud = EnhancedHUD(3, 6);
        
        hud.updateLives(5);
        expect(hud.currentLives, equals(5));
      });

      test('should update max lives correctly', () {
        final hud = EnhancedHUD(3, 3);
        
        // Simulate Heart Booster activation
        hud.updateMaxLives(6);
        
        // Should handle the new max lives
        hud.updateLives(6);
        expect(hud.currentLives, equals(6));
      });
    });

    group('ExplosionParticle', () {
      test('should initialize with correct properties', () {
        final explosion = ExplosionParticle(
          position: Vector2(100, 100),
          color: Colors.red,
          maxSize: 30.0,
          duration: 1.0,
        );
        
        expect(explosion.position, equals(Vector2(100, 100)));
        expect(explosion.color, equals(Colors.red));
        expect(explosion.maxSize, equals(30.0));
        expect(explosion.duration, equals(1.0));
      });
    });
  });
}

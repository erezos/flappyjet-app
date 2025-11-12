import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/game/systems/game_state_manager.dart';
import 'package:flappy_jet_pro/game/core/game_config.dart';
import 'package:flappy_jet_pro/game/core/game_themes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('GameStateManager - Collision & Game Over', () {
    late GameStateManager manager;

    setUp(() {
      manager = GameStateManager();
    });

    test('should start in waiting state', () {
      expect(manager.isWaitingToStart, isTrue);
      expect(manager.isGameOver, isFalse);
      expect(manager.isPlaying, isFalse);
      expect(manager.lives, equals(GameConfig.maxLives));
    });

    test('startGame() should transition to playing state', () {
      manager.startGame();
      
      expect(manager.isWaitingToStart, isFalse);
      expect(manager.isGameOver, isFalse);
      expect(manager.isPlaying, isTrue);
      expect(manager.gameStartTime, greaterThan(0));
    });

    test('handleCollision() should reduce lives and continue playing', () {
      manager.startGame();
      
      final isGameOver = manager.handleCollision();
      
      expect(isGameOver, isFalse);
      expect(manager.lives, equals(GameConfig.maxLives - 1));
      expect(manager.isInvulnerable, isTrue);
      expect(manager.isGameOver, isFalse);
    });

    test('handleCollision() at 1 life should trigger game over', () {
      manager.startGame();
      
      // Reduce to 1 life
      for (int i = 0; i < GameConfig.maxLives - 1; i++) {
        manager.handleCollision();
      }
      
      expect(manager.lives, equals(1));
      expect(manager.isGameOver, isFalse);
      
      // Final collision
      final isGameOver = manager.handleCollision();
      
      expect(isGameOver, isTrue);
      expect(manager.lives, equals(0));
      expect(manager.isGameOver, isTrue);
    });

    test('setGameOver() should update internal state immediately', () {
      // Start game
      manager.startGame();
      
      // Initial state
      expect(manager.isGameOver, isFalse);
      
      // Call setGameOver
      manager.setGameOver();
      
      // Internal state should be updated immediately (critical for game logic)
      expect(manager.isGameOver, isTrue);
      
      // Note: gameOverNotifier.value update is deferred to next frame to avoid
      // "setState during build" errors, which is the correct behavior.
      // This cannot be reliably tested in unit tests.
    });

    test('addExtraLife() should restore game state', () {
      // Start game and trigger game over
      manager.startGame();
      for (int i = 0; i < GameConfig.maxLives; i++) {
        manager.handleCollision();
      }
      
      expect(manager.isGameOver, isTrue);
      expect(manager.lives, equals(0));
      
      // Add extra life
      manager.addExtraLife();
      
      // Internal state should update immediately (critical for game logic)
      expect(manager.isGameOver, isFalse);
      expect(manager.lives, equals(1));
      expect(manager.isInvulnerable, isTrue);
      
      // Note: gameOverNotifier.value update is deferred to next frame to avoid
      // "setState during build" errors, which is the correct behavior.
      // This cannot be reliably tested in unit tests.
    });

    test('continueGame() should restore playing state', () {
      // Start game and trigger game over
      manager.startGame();
      for (int i = 0; i < GameConfig.maxLives; i++) {
        manager.handleCollision();
      }
      
      expect(manager.isGameOver, isTrue);
      expect(manager.lives, equals(0));
      
      // Continue game
      manager.continueGame();
      
      // Internal state should update immediately (critical for game logic)
      expect(manager.isGameOver, isFalse);
      expect(manager.continuesUsedThisRun, equals(1));
      expect(manager.isPlaying, isTrue);
      expect(manager.lives, greaterThan(0));
      
      // Note: gameOverNotifier.value update is deferred to next frame to avoid
      // "setState during build" errors, which is the correct behavior.
      // This cannot be reliably tested in unit tests.
    });

    test('resetGame() should return to initial state', () {
      // Start game and trigger game over
      manager.startGame();
      manager.updateScore(10);
      manager.setGameOver();
      
      expect(manager.isGameOver, isTrue);
      expect(manager.score, equals(10));
      
      // Reset game
      manager.resetGame();
      
      // Internal state should update immediately (critical for game logic)
      expect(manager.isWaitingToStart, isTrue);
      expect(manager.isGameOver, isFalse);
      expect(manager.score, equals(0));
      expect(manager.continuesUsedThisRun, equals(0));
      
      // Note: gameOverNotifier.value update is deferred to next frame to avoid
      // "setState during build" errors, which is the correct behavior.
      // This cannot be reliably tested in unit tests.
    });

    test('updateScore() should transition themes correctly', () {
      manager.startGame();
      
      expect(manager.currentTheme, equals(GameThemes.skyRookie));
      
      // Score for theme transitions
      manager.updateScore(10);
      expect(manager.currentTheme, equals(GameThemes.getThemeForScore(10)));
      
      manager.updateScore(50);
      expect(manager.currentTheme, equals(GameThemes.getThemeForScore(50)));
    });

    test('continue system should track usage correctly', () {
      manager.startGame();
      
      expect(manager.continuesUsedThisRun, equals(0));
      expect(manager.canContinueWithAd, isTrue);
      expect(manager.continuesRemaining, equals(5));
      
      // Use 3 continues
      for (int i = 0; i < 3; i++) {
        manager.continueGame();
      }
      
      expect(manager.continuesUsedThisRun, equals(3));
      expect(manager.canContinueWithAd, isTrue);
      expect(manager.continuesRemaining, equals(2));
    });

    test('continue system should cap at 5 continues', () {
      manager.startGame();
      
      // Use max continues
      for (int i = 0; i < 5; i++) {
        manager.continueGame();
      }
      
      expect(manager.continuesUsedThisRun, equals(5));
      expect(manager.canContinueWithAd, isFalse);
      expect(manager.continuesRemaining, equals(0));
      
      // Try one more (should still count, just canContinue returns false)
      manager.continueGame();
      expect(manager.continuesUsedThisRun, equals(6));
    });

    test('invulnerability should be set correctly', () {
      manager.startGame();
      
      expect(manager.isInvulnerable, isFalse);
      
      manager.setInvulnerable(true);
      expect(manager.isInvulnerable, isTrue);
      
      manager.setInvulnerable(false);
      expect(manager.isInvulnerable, isFalse);
    });
  });

  group('GameStateManager - Time Tracking', () {
    late GameStateManager manager;

    setUp(() {
      manager = GameStateManager();
    });

    test('getElapsedGameTime() should return 0 before game starts', () {
      expect(manager.getElapsedGameTime(), equals(0));
    });

    test('getElapsedGameTime() should track time after game starts', () async {
      manager.startGame();
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      final elapsed = manager.getElapsedGameTime();
      expect(elapsed, greaterThan(90)); // Allow some margin
      expect(elapsed, lessThan(150));
    });

    test('pauseGameTime() and resumeGameTime() should exclude pause duration', () async {
      manager.startGame();
      
      await Future.delayed(const Duration(milliseconds: 50));
      
      manager.pauseGameTime();
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      manager.resumeGameTime();
      
      await Future.delayed(const Duration(milliseconds: 50));
      
      final elapsed = manager.getElapsedGameTime();
      
      // Should be ~100ms (50ms + 50ms), not 200ms
      expect(elapsed, greaterThan(80));
      expect(elapsed, lessThan(150));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flappy_jet_pro/game/systems/lives_manager.dart';
import 'package:flappy_jet_pro/game/enhanced_flappy_game.dart';
import 'package:flappy_jet_pro/game/systems/monetization_manager.dart';

/// Comprehensive tests for the hearts/lives system
/// Tests all critical user flows and edge cases
void main() {
  group('Hearts System Comprehensive Tests', () {
    late LivesManager livesManager;
    late EnhancedFlappyGame game;
    late MonetizationManager monetization;

    setUp(() async {
      // Reset SharedPreferences for each test
      SharedPreferences.setMockInitialValues({});
      
      livesManager = LivesManager();
      await livesManager.initialize();
      
      monetization = MonetizationManager();
      game = EnhancedFlappyGame(monetization: monetization);
    });

    tearDown(() async {
      livesManager.dispose();
    });

    group('Game Start Flow', () {
      test('should start game when hearts > 0', () async {
        // Arrange: Set hearts to 2
        await livesManager.setLives(2);
        
        // Act: Try to start game
        await game.handleTap(); // This should consume 1 heart and start game
        
        // Assert: Game should start and hearts should be reduced
        expect(livesManager.currentLives, equals(1));
        expect(game.isGameOver, isFalse);
      });

      test('should prevent game start when hearts = 0', () async {
        // Arrange: Set hearts to 0
        await livesManager.setLives(0);
        
        // Act: Try to start game
        await game.handleTap();
        
        // Assert: Game should not start, hearts remain 0
        expect(livesManager.currentLives, equals(0));
        expect(game.isGameOver, isFalse); // Still in waiting state
      });

      test('should show correct heart count after game over', () async {
        // Arrange: Start with 3 hearts
        await livesManager.setLives(3);
        
        // Act: Simulate game over (all lives lost)
        // This would happen through game collision system
        await livesManager.setLives(0);
        
        // Assert: Hearts should be 0
        expect(livesManager.currentLives, equals(0));
      });
    });

    group('Continue System', () {
      test('should allow continues up to limit', () {
        // Arrange: Fresh game
        game.resetGame();
        
        // Assert: Should allow continues initially
        expect(game.canContinueWithAd, isTrue);
        expect(game.continuesRemaining, equals(5));
        
        // Act: Use continues
        for (int i = 0; i < 5; i++) {
          game.continueGame();
        }
        
        // Assert: Should not allow more continues
        expect(game.canContinueWithAd, isFalse);
        expect(game.continuesRemaining, equals(0));
      });

      test('should reset continue counter on new game', () {
        // Arrange: Use all continues
        for (int i = 0; i < 5; i++) {
          game.continueGame();
        }
        expect(game.canContinueWithAd, isFalse);
        
        // Act: Reset game
        game.resetGame();
        
        // Assert: Continue counter should reset
        expect(game.canContinueWithAd, isTrue);
        expect(game.continuesRemaining, equals(5));
      });
    });

    group('Heart Regeneration', () {
      test('should calculate correct regeneration time', () async {
        // Arrange: Set hearts to 2 (not full)
        await livesManager.setLives(2);
        
        // Act: Get regeneration time
        final seconds = await livesManager.getSecondsUntilNextRegen();
        
        // Assert: Should have a positive regeneration time
        expect(seconds, isNotNull);
        expect(seconds!, greaterThan(0));
        expect(seconds, lessThanOrEqualTo(10 * 60)); // Max 10 minutes
      });

      test('should return null when hearts are full', () async {
        // Arrange: Set hearts to max
        await livesManager.setLives(3);
        
        // Act: Get regeneration time
        final seconds = await livesManager.getSecondsUntilNextRegen();
        
        // Assert: Should return null (no regeneration needed)
        expect(seconds, isNull);
      });
    });

    group('Restart Flow', () {
      test('should allow restart when hearts > 0', () async {
        // Arrange: Set hearts to 2
        await livesManager.setLives(2);
        
        // Act: Reset game
        game.resetGame();
        
        // Assert: Game should reset properly with current hearts
        expect(game.currentLives, equals(2));
        expect(game.isGameOver, isFalse);
      });

      test('should handle restart when hearts = 0', () async {
        // Arrange: Set hearts to 0
        await livesManager.setLives(0);
        
        // Act: Reset game
        game.resetGame();
        
        // Assert: Game should reset but with 0 hearts
        expect(game.currentLives, equals(0));
        expect(game.isGameOver, isFalse); // In waiting state
      });
    });

    group('Ad Rewards', () {
      test('should grant heart after watching ad', () async {
        // Arrange: Set hearts to 0
        await livesManager.setLives(0);
        
        // Act: Simulate watching ad and getting reward
        await livesManager.addLife(1);
        
        // Assert: Should have 1 heart
        expect(livesManager.currentLives, equals(1));
      });

      test('should not exceed max hearts from ad', () async {
        // Arrange: Set hearts to max
        await livesManager.setLives(3);
        
        // Act: Try to add more hearts
        await livesManager.addLife(1);
        
        // Assert: Should still be at max
        expect(livesManager.currentLives, equals(3));
      });
    });

    group('Edge Cases', () {
      test('should handle negative hearts gracefully', () async {
        // Act: Try to set negative hearts
        await livesManager.setLives(-1);
        
        // Assert: Should clamp to 0
        expect(livesManager.currentLives, equals(0));
      });

      test('should handle hearts above max gracefully', () async {
        // Act: Try to set hearts above max
        await livesManager.setLives(10);
        
        // Assert: Should clamp to max
        expect(livesManager.currentLives, equals(3));
      });

      test('should maintain consistency between game and lives manager', () async {
        // Arrange: Set hearts to 2
        await livesManager.setLives(2);
        
        // Act: Reset game (should sync with lives manager)
        game.resetGame();
        
        // Assert: Game internal lives should match lives manager
        expect(game.currentLives, equals(livesManager.currentLives));
      });
    });

    group('Heart Booster Integration', () {
      test('should respect heart booster max hearts', () async {
        // Note: This test would need InventoryManager integration
        // For now, just test the basic max hearts logic
        final maxHearts = livesManager.maxLives;
        expect(maxHearts, greaterThanOrEqualTo(3));
        expect(maxHearts, lessThanOrEqualTo(6));
      });
    });
  });
}

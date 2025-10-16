/// Baseline Game State Tests
/// 
/// Verifies game state transitions before refactoring
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flame_test/flame_test.dart';
import '../../lib/game/flappy_game.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Baseline: Game State Transitions', () {
    testWidgets('Game starts in waiting state', (tester) async {
      final game = TestHelpers.createTestGame();
      await tester.pumpWidget(GameWidget(game: game));
      await tester.pump();
      
      await TestHelpers.waitForGameReady(game);
      
      // BASELINE: Game should be waiting to start
      TestHelpers.assertGameState(
        game,
        isWaiting: true,
        isPlaying: false,
        isGameOver: false,
      );
    });
    
    testWidgets('Tap transitions from waiting to playing', (tester) async {
      final game = TestHelpers.createTestGame();
      await tester.pumpWidget(GameWidget(game: game));
      await tester.pump();
      
      await TestHelpers.waitForGameReady(game);
      
      // Tap to start
      await TestHelpers.simulateTap(game);
      await tester.pump();
      
      // BASELINE: Should now be playing
      TestHelpers.assertGameState(
        game,
        isWaiting: false,
        isPlaying: true,
        isGameOver: false,
      );
    });
    
    testWidgets('Collision transitions to game over', (tester) async {
      final game = TestHelpers.createTestGame();
      await tester.pumpWidget(GameWidget(game: game));
      await tester.pump();
      
      await TestHelpers.waitForGameReady(game);
      await TestHelpers.simulateTap(game);
      await tester.pump();
      
      // Trigger collision
      game.gameStateManager.setGameOver();
      
      // BASELINE: Should be game over
      TestHelpers.assertGameState(
        game,
        isWaiting: false,
        isPlaying: false,
        isGameOver: true,
      );
    });
    
    testWidgets('Reset returns to waiting state', (tester) async {
      final game = TestHelpers.createTestGame();
      await tester.pumpWidget(GameWidget(game: game));
      await tester.pump();
      
      await TestHelpers.waitForGameReady(game);
      await TestHelpers.simulateTap(game);
      await tester.pump();
      
      game.gameStateManager.setGameOver();
      game.resetGame();
      await tester.pump();
      
      // BASELINE: Should return to waiting
      TestHelpers.assertGameState(
        game,
        isWaiting: true,
        isPlaying: false,
        isGameOver: false,
      );
    });
  });
  
  group('Baseline: Lives System', () {
    testWidgets('Game starts with correct number of lives', (tester) async {
      final game = TestHelpers.createTestGame();
      await tester.pumpWidget(GameWidget(game: game));
      await tester.pump();
      
      await TestHelpers.waitForGameReady(game);
      
      // BASELINE: Should have 3 lives initially
      expect(
        TestHelpers.getLives(game),
        greaterThanOrEqualTo(1),
        reason: 'Should have at least 1 life at start',
      );
    });
    
    testWidgets('Continue system restores life', (tester) async {
      final game = TestHelpers.createTestGame();
      await tester.pumpWidget(GameWidget(game: game));
      await tester.pump();
      
      await TestHelpers.waitForGameReady(game);
      await TestHelpers.simulateTap(game);
      await tester.pump();
      
      game.gameStateManager.setGameOver();
      final livesBeforeContinue = TestHelpers.getLives(game);
      
      game.continueGame();
      await tester.pump();
      
      // BASELINE: Lives should be restored
      expect(
        TestHelpers.getLives(game),
        greaterThanOrEqualTo(livesBeforeContinue),
        reason: 'Continue should restore at least 1 life',
      );
      
      // BASELINE: Should no longer be game over
      expect(
        game.gameStateManager.isGameOver,
        false,
        reason: 'Continue should exit game over state',
      );
    });
  });
}


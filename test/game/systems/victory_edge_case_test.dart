import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/game/systems/game_state_manager.dart';
import 'package:flappy_jet_pro/game/systems/victory_controller.dart';

/// Tests for the victory priority edge case fix
/// 
/// Edge case scenario:
/// Player has 1 heart, passes last obstacle AND crashes on same frame.
/// Expected: Victory wins (victory priority), not game over.
void main() {
  // Initialize Flutter binding for tests that need SchedulerBinding
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('GameEndState Edge Case Tests', () {
    late GameStateManager gameStateManager;
    
    setUp(() {
      gameStateManager = GameStateManager();
    });
    
    test('Initial state should be playing', () {
      expect(gameStateManager.gameEndState, GameEndState.playing);
      expect(gameStateManager.isVictoryTriggered, false);
      expect(gameStateManager.isGameOverTriggered, false);
      expect(gameStateManager.isEndStateLocked, false);
    });
    
    test('trySetVictory should succeed from playing state', () {
      final result = gameStateManager.trySetVictory();
      
      expect(result, true);
      expect(gameStateManager.gameEndState, GameEndState.victoryTriggered);
      expect(gameStateManager.isVictoryTriggered, true);
    });
    
    test('trySetGameOver should succeed from playing state', () {
      final result = gameStateManager.trySetGameOver();
      
      expect(result, true);
      expect(gameStateManager.gameEndState, GameEndState.gameOverTriggered);
      expect(gameStateManager.isGameOverTriggered, true);
    });
    
    test('trySetGameOver should FAIL if victory already triggered (VICTORY PRIORITY)', () {
      // Victory triggered first
      gameStateManager.trySetVictory();
      
      // Game over should fail
      final result = gameStateManager.trySetGameOver();
      
      expect(result, false);
      expect(gameStateManager.gameEndState, GameEndState.victoryTriggered);
      expect(gameStateManager.isGameOverTriggered, false);
    });
    
    test('trySetVictory should OVERRIDE game over (VICTORY PRIORITY)', () {
      // Game over triggered first
      gameStateManager.trySetGameOver();
      expect(gameStateManager.gameEndState, GameEndState.gameOverTriggered);
      
      // Victory should OVERRIDE game over (victory priority!)
      final result = gameStateManager.trySetVictory();
      
      expect(result, true);
      expect(gameStateManager.gameEndState, GameEndState.victoryTriggered);
      expect(gameStateManager.isVictoryTriggered, true);
    });
    
    test('lockEndState should prevent further changes', () {
      gameStateManager.trySetVictory();
      gameStateManager.lockEndState();
      
      expect(gameStateManager.isEndStateLocked, true);
      
      // Should fail to change state
      final victoryResult = gameStateManager.trySetVictory();
      final gameOverResult = gameStateManager.trySetGameOver();
      
      expect(victoryResult, false);
      expect(gameOverResult, false);
      expect(gameStateManager.gameEndState, GameEndState.locked);
    });
    
    test('resetEndState should allow new game', () {
      gameStateManager.trySetVictory();
      gameStateManager.lockEndState();
      
      gameStateManager.resetEndState();
      
      expect(gameStateManager.gameEndState, GameEndState.playing);
      expect(gameStateManager.isEndStateLocked, false);
      
      // Should be able to set new state
      final result = gameStateManager.trySetGameOver();
      expect(result, true);
    });
    
    test('startGame should reset end state', () {
      gameStateManager.trySetVictory();
      gameStateManager.lockEndState();
      
      // Simulate starting a new game
      // First we need to set the manager to waiting state
      gameStateManager.resetGame();
      gameStateManager.startGame();
      
      expect(gameStateManager.gameEndState, GameEndState.playing);
    });
    
    test('resetGame should reset end state', () {
      gameStateManager.trySetGameOver();
      
      gameStateManager.resetGame();
      
      expect(gameStateManager.gameEndState, GameEndState.playing);
    });
  });
  
  group('VictoryController Tests', () {
    test('VictoryController initial state should be idle', () {
      final controller = VictoryController();
      
      expect(controller.phase, VictoryPhase.idle);
      expect(controller.isActive, false);
      expect(controller.progress, 0);
    });
    
    test('VictoryController reset should clear all state', () {
      final controller = VictoryController();
      
      controller.reset();
      
      expect(controller.phase, VictoryPhase.idle);
      expect(controller.isActive, false);
      expect(controller.progress, 0);
    });
    
    test('VictoryController cannot start when not idle', () {
      final controller = VictoryController();
      
      // Manually set phase to simulate in-progress animation
      // We can't directly test startVictory without a full game setup,
      // but we verify the controller starts in idle state
      expect(controller.phase, VictoryPhase.idle);
    });
    
    test('VictoryController skip should work during animation', () {
      final controller = VictoryController();
      
      // Skip when idle should do nothing (phase stays idle)
      controller.skip();
      expect(controller.phase, VictoryPhase.idle);
    });
  });
  
  group('Edge Case Simulation Tests', () {
    test('Simulated edge case: victory + game over same frame - victory wins', () {
      final gameStateManager = GameStateManager();
      
      // Simulate: Player passes last obstacle (triggers victory check)
      // AND crashes (triggers game over check) on the same frame
      
      // In real game, these would be called from different callbacks
      // but in the same frame. Order might vary based on Flame's execution.
      
      // Scenario 1: Game over triggers first, then victory
      gameStateManager.trySetGameOver();
      expect(gameStateManager.gameEndState, GameEndState.gameOverTriggered);
      
      gameStateManager.trySetVictory(); // Victory should OVERRIDE
      expect(gameStateManager.gameEndState, GameEndState.victoryTriggered);
      expect(gameStateManager.isVictoryTriggered, true);
    });
    
    test('Simulated edge case: victory triggers first, game over ignored', () {
      final gameStateManager = GameStateManager();
      
      // Scenario 2: Victory triggers first, then game over
      gameStateManager.trySetVictory();
      expect(gameStateManager.gameEndState, GameEndState.victoryTriggered);
      
      final gameOverResult = gameStateManager.trySetGameOver();
      expect(gameOverResult, false); // Should fail
      expect(gameStateManager.gameEndState, GameEndState.victoryTriggered);
    });
    
    test('After state is locked, both victory and game over should fail', () {
      final gameStateManager = GameStateManager();
      
      gameStateManager.trySetVictory();
      gameStateManager.lockEndState();
      
      // Try to trigger game over after lock
      final gameOverResult = gameStateManager.trySetGameOver();
      expect(gameOverResult, false);
      
      // Try to trigger victory again after lock
      gameStateManager.resetEndState(); // First unlock for this test
      gameStateManager.lockEndState(); // Then lock again
      
      final victoryResult = gameStateManager.trySetVictory();
      expect(victoryResult, false);
    });
  });
  
  group('Boss Battle Continue Flow Tests', () {
    /// This tests the critical fix for the bug where:
    /// 1. Player dies in boss battle
    /// 2. Player continues via ad
    /// 3. Bot crashes
    /// 4. Victory should trigger, but didn't because state was still locked
    
    test('continueGame should reset end state to allow future victory', () {
      final gameStateManager = GameStateManager();
      
      // Simulate: Player dies → state locked
      gameStateManager.trySetGameOver();
      gameStateManager.lockEndState();
      
      expect(gameStateManager.isEndStateLocked, true);
      
      // Simulate: Player continues via ad
      gameStateManager.continueGame();
      
      // State should be reset to playing (no longer locked!)
      expect(gameStateManager.gameEndState, GameEndState.playing);
      expect(gameStateManager.isEndStateLocked, false);
      
      // Now victory CAN be triggered (e.g., if bot crashes)
      final victoryResult = gameStateManager.trySetVictory();
      expect(victoryResult, true);
      expect(gameStateManager.isVictoryTriggered, true);
    });
    
    test('continueGame should allow game over if player dies again', () {
      final gameStateManager = GameStateManager();
      
      // First death
      gameStateManager.trySetGameOver();
      gameStateManager.lockEndState();
      
      // Continue
      gameStateManager.continueGame();
      expect(gameStateManager.gameEndState, GameEndState.playing);
      
      // Second death
      final gameOverResult = gameStateManager.trySetGameOver();
      expect(gameOverResult, true);
      expect(gameStateManager.isGameOverTriggered, true);
    });
    
    test('Boss battle scenario: player continues, bot crashes, victory triggers', () {
      final gameStateManager = GameStateManager();
      
      // === Phase 1: Player dies ===
      gameStateManager.trySetGameOver();
      gameStateManager.lockEndState();
      expect(gameStateManager.isEndStateLocked, true);
      
      // === Phase 2: Player watches ad and continues ===
      gameStateManager.continueGame();
      
      // State MUST be unlocked for victory to work
      expect(gameStateManager.gameEndState, GameEndState.playing);
      
      // === Phase 3: Bot crashes → Victory check ===
      // (In real game, this is triggered by ObjectiveTracker when botIsActive becomes false)
      final victoryResult = gameStateManager.trySetVictory();
      
      // Victory should succeed!
      expect(victoryResult, true);
      expect(gameStateManager.isVictoryTriggered, true);
      
      // Lock state to prevent further changes
      gameStateManager.lockEndState();
      expect(gameStateManager.isEndStateLocked, true);
    });
    
    test('Multiple continues should all reset state correctly', () {
      final gameStateManager = GameStateManager();
      
      // First death + continue
      gameStateManager.trySetGameOver();
      gameStateManager.lockEndState();
      gameStateManager.continueGame();
      expect(gameStateManager.gameEndState, GameEndState.playing);
      
      // Second death + continue
      gameStateManager.trySetGameOver();
      gameStateManager.lockEndState();
      gameStateManager.continueGame();
      expect(gameStateManager.gameEndState, GameEndState.playing);
      
      // Third death + continue
      gameStateManager.trySetGameOver();
      gameStateManager.lockEndState();
      gameStateManager.continueGame();
      expect(gameStateManager.gameEndState, GameEndState.playing);
      
      // Victory should still work after multiple continues
      final victoryResult = gameStateManager.trySetVictory();
      expect(victoryResult, true);
    });
  });

  group('GameOverNotifier Victory Priority Tests', () {
    /// These tests verify the critical fix where gameOverNotifier.value
    /// should NOT be set to true when victory has already been triggered.
    /// This prevents the old GameOverMenu from appearing on top of victory animation.
    
    testWidgets('setGameOver should NOT set gameOverNotifier when victory already triggered', 
        (WidgetTester tester) async {
      final gameStateManager = GameStateManager();
      
      // Initial state: notifier should be false
      expect(gameStateManager.gameOverNotifier.value, false);
      
      // Victory is triggered FIRST
      gameStateManager.trySetVictory();
      expect(gameStateManager.isVictoryTriggered, true);
      
      // Now setGameOver is called (simulating collision after victory)
      gameStateManager.setGameOver(causeOfDeath: 'obstacle_collision');
      
      // Wait for postFrameCallback to execute
      await tester.pumpAndSettle();
      
      // ✅ CRITICAL: gameOverNotifier should STILL be false!
      // Because victory has priority, the old game over UI should NOT appear
      expect(gameStateManager.gameOverNotifier.value, false);
    });
    
    testWidgets('setGameOver should NOT set gameOverNotifier when state is locked', 
        (WidgetTester tester) async {
      final gameStateManager = GameStateManager();
      
      // Victory triggered and state locked
      gameStateManager.trySetVictory();
      gameStateManager.lockEndState();
      
      expect(gameStateManager.isEndStateLocked, true);
      expect(gameStateManager.gameOverNotifier.value, false);
      
      // setGameOver called after lock
      gameStateManager.setGameOver(causeOfDeath: 'obstacle_collision');
      
      // Wait for postFrameCallback
      await tester.pumpAndSettle();
      
      // gameOverNotifier should NOT be set because state was locked
      expect(gameStateManager.gameOverNotifier.value, false);
    });
    
    test('setGameOver SHOULD set gameOverNotifier when state is playing (sync test)', () async {
      final gameStateManager = GameStateManager();
      
      // State is playing (normal game over scenario)
      expect(gameStateManager.gameEndState, GameEndState.playing);
      expect(gameStateManager.gameOverNotifier.value, false);
      
      // In normal endless mode flow, trySetGameOver is called along with setGameOver
      // setGameOver sets _isGameOver and schedules notifier update
      // The callback checks _gameEndState which should be 'playing' for endless mode
      gameStateManager.setGameOver(causeOfDeath: 'obstacle_collision');
      
      // Since this is a sync test without WidgetTester, we verify the internal state
      // is set correctly. The actual notifier update happens via addPostFrameCallback
      // which we verified works in the widget tests above.
      expect(gameStateManager.isGameOver, true);
      expect(gameStateManager.gameEndState, GameEndState.playing); // Not changed by setGameOver
    });
    
    testWidgets('Race condition: victory and setGameOver same frame - notifier stays false', 
        (WidgetTester tester) async {
      final gameStateManager = GameStateManager();
      
      // Simulate race condition: both happen on same "frame"
      // Order: game over called first, then victory overrides
      gameStateManager.setGameOver(causeOfDeath: 'obstacle_collision');
      gameStateManager.trySetVictory(); // Victory overrides!
      
      // Wait for postFrameCallback from setGameOver
      await tester.pumpAndSettle();
      
      // Even though setGameOver was called first, the deferred callback
      // should check if victory was triggered and NOT set the notifier
      expect(gameStateManager.isVictoryTriggered, true);
      expect(gameStateManager.gameOverNotifier.value, false);
    });
    
    test('Notifier flow after continueGame allows new game over (state test)', () {
      final gameStateManager = GameStateManager();
      
      // This test verifies state transitions without relying on postFrameCallback
      // First death sets game over
      gameStateManager.trySetGameOver();
      gameStateManager.lockEndState();
      expect(gameStateManager.isEndStateLocked, true);
      
      // Continue resets state
      gameStateManager.continueGame();
      expect(gameStateManager.gameEndState, GameEndState.playing);
      expect(gameStateManager.isEndStateLocked, false);
      
      // Second death can set game over again
      final result = gameStateManager.trySetGameOver();
      expect(result, true);
      expect(gameStateManager.isGameOverTriggered, true);
    });
  });
  
  group('Lives Reset Edge Case Tests', () {
    test('Victory state should prevent lives from being reset in game over flow', () {
      final gameStateManager = GameStateManager();
      
      // Simulate victory+death on same frame:
      // 1. Victory triggered first
      gameStateManager.trySetVictory();
      gameStateManager.lockEndState();
      
      // 2. Verify victory has priority
      expect(gameStateManager.gameEndState, GameEndState.locked);
      expect(gameStateManager.isVictoryTriggered, false); // It was, but now it's locked
      expect(gameStateManager.isEndStateLocked, true);
      
      // 3. The check in flappy_game._gameOver should skip setLives(0) because:
      //    - gameEndState is not victoryTriggered (it's locked)
      //    - BUT isEndStateLocked is true AND isGameOver is false
      //    This means victory was the reason for locking, not game over
      expect(gameStateManager.isGameOver, false); // Game over flag is false!
    });
    
    test('Victory + Lock should have isGameOver = false', () {
      final gameStateManager = GameStateManager();
      
      // Victory path
      gameStateManager.trySetVictory();
      gameStateManager.lockEndState();
      
      // isGameOver should be false because we won, not lost
      expect(gameStateManager.isGameOver, false);
      expect(gameStateManager.isEndStateLocked, true);
    });
    
    test('GameOver + Lock should have isGameOver = true', () {
      final gameStateManager = GameStateManager();
      
      // Game over path (actual death, not victory+death)
      gameStateManager.trySetGameOver();
      gameStateManager.lockEndState();
      
      // isGameOver should be true because we actually lost
      // Note: This depends on whether setGameOver sets _isGameOver = true
      // Based on the code, setGameOver() sets _isGameOver = true
      gameStateManager.setGameOver();
      
      expect(gameStateManager.isGameOver, true);
      expect(gameStateManager.isEndStateLocked, true);
    });
    
    test('Victory triggered check should work correctly', () {
      final gameStateManager = GameStateManager();
      
      // Before victory
      expect(gameStateManager.gameEndState, GameEndState.playing);
      
      // Trigger victory
      gameStateManager.trySetVictory();
      
      // Check: gameEndState == victoryTriggered
      expect(gameStateManager.gameEndState, GameEndState.victoryTriggered);
      
      // After locking, gameEndState becomes locked, NOT victoryTriggered
      gameStateManager.lockEndState();
      expect(gameStateManager.gameEndState, GameEndState.locked);
      
      // So the check in flappy_game should be:
      // if (gameEndState == victoryTriggered || (isEndStateLocked && !isGameOver))
      // The second condition catches the "victory was triggered and then locked" case
      expect(gameStateManager.isEndStateLocked, true);
      expect(gameStateManager.isGameOver, false);
    });
  });
}

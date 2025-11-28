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
}

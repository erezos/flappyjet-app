/// Test Helpers - Shared utilities for testing FlappyJet
/// 
/// Provides helper functions to create test instances of game components,
/// run frame simulations, and verify game state.
library;

import 'package:flame/game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/material.dart';
import '../../lib/game/flappy_game.dart';
import '../../lib/game/components/dynamic_obstacle.dart';
import '../../lib/models/level_data_schema.dart';
import 'mock_managers.dart';

/// Helper methods for creating test instances
class TestHelpers {
  /// Create a test FlappyGame with mocked dependencies
  /// 
  /// [isStoryMode]: Whether this is a story mode game
  /// [level]: Story mode level data (if applicable)
  static FlappyGame createTestGame({
    bool isStoryMode = false,
    LevelData? level,
  }) {
    return FlappyGame(
      monetization: MockMonetizationManager(),
      missions: MockMissionsManager(),
      isStoryMode: isStoryMode,
      storyModeLevel: level,
    );
  }
  
  /// Create a test obstacle at specified position
  /// 
  /// [x]: Horizontal position
  /// [y]: Vertical position (gap center)
  /// [gapSize]: Size of the gap (default: 200)
  static DynamicObstacle createTestObstacle({
    double x = 300,
    double y = 200,
    double gapSize = 200,
  }) {
    return DynamicObstacle(
      Vector2(x, y),
      gapSize: gapSize,
    );
  }
  
  /// Create a test level for story mode
  /// 
  /// [id]: Level ID
  /// [zone]: Zone number
  /// [type]: Objective type
  static LevelData createTestLevel({
    int id = 1,
    int zone = 1,
    ObjectiveType type = ObjectiveType.reachScore,
    int target = 10,
  }) {
    return LevelData(
      id: id,
      name: 'Test Level $id',
      zone: zone,
      objective: LevelObjective(
        type: type,
        target: target,
        description: 'Test objective',
      ),
      difficulty: LevelDifficulty(
        speedMultiplier: 1.0,
        obstacleGap: 200,
        obstacleFrequency: 2.0,
      ),
      reward: LevelReward(
        coins: 50,
        gems: 0,
      ),
      theme: LevelTheme(
        background: 'test_bg.png',
        obstacles: 'test_obstacles.png',
        music: 'test_music.mp3',
      ),
    );
  }
  
  /// Run the game update loop for N frames
  /// 
  /// Simulates game running at 60 FPS
  /// 
  /// [game]: The game instance
  /// [frames]: Number of frames to run
  static Future<void> runFrames(FlappyGame game, int frames) async {
    const double dt = 1 / 60; // 60 FPS
    
    for (int i = 0; i < frames; i++) {
      game.update(dt);
      // Pump microtask queue to allow async operations
      await Future.delayed(Duration.zero);
    }
  }
  
  /// Wait for game to be fully loaded and ready
  /// 
  /// [game]: The game instance
  static Future<void> waitForGameReady(FlappyGame game) async {
    await game.onLoad();
    await game.ready();
    
    // Wait one extra frame for everything to settle
    await runFrames(game, 1);
  }
  
  /// Simulate a tap event
  /// 
  /// [game]: The game instance
  static Future<void> simulateTap(FlappyGame game) async {
    await game.handleTap();
    await runFrames(game, 1);
  }
  
  /// Assert game is in expected state
  /// 
  /// [game]: The game instance
  /// [isWaiting]: Expected waiting state
  /// [isPlaying]: Expected playing state
  /// [isGameOver]: Expected game over state
  static void assertGameState(
    FlappyGame game, {
    bool? isWaiting,
    bool? isPlaying,
    bool? isGameOver,
  }) {
    if (isWaiting != null) {
      assert(
        game.gameStateManager.isWaitingToStart == isWaiting,
        'Expected waiting=$isWaiting, got ${game.gameStateManager.isWaitingToStart}',
      );
    }
    
    if (isPlaying != null) {
      assert(
        game.gameStateManager.isPlaying == isPlaying,
        'Expected playing=$isPlaying, got ${game.gameStateManager.isPlaying}',
      );
    }
    
    if (isGameOver != null) {
      assert(
        game.gameStateManager.isGameOver == isGameOver,
        'Expected gameOver=$isGameOver, got ${game.gameStateManager.isGameOver}',
      );
    }
  }
  
  /// Get current game score
  static int getScore(FlappyGame game) {
    return game.gameStateManager.score;
  }
  
  /// Get current game lives
  static int getLives(FlappyGame game) {
    return game.gameStateManager.lives;
  }
}


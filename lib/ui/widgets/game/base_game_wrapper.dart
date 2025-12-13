/// 🎮 BASE GAME WRAPPER - Abstract base class for all game modes
/// 
/// Provides shared functionality for Story Mode, Tournaments, and future modes.
/// Concrete implementations only need to handle mode-specific logic.
/// 
/// ✅ FLAME ENGINE BEST PRACTICES:
/// - Single responsibility: Base class handles common concerns
/// - DRY: No duplicate code across wrappers
/// - Testable: Mode-specific logic is isolated
/// - LivesManager: Global lives for all modes (tournaments share global lives)
/// 
/// USAGE:
/// ```dart
/// class MyGameWrapper extends BaseGameWrapper {
///   @override
///   UnifiedLevelData get levelData => ...; // Provide level data
///   
///   @override
///   void onLevelCompleted() { ... } // Handle completion
/// }
/// ```
library;

import 'dart:async';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../../../game/flappy_game.dart';
import '../../../game/systems/lives_manager.dart';
import '../../../game/systems/monetization_manager.dart';
import '../../../game/systems/objective_tracker.dart';
import '../../../game/systems/inventory_manager.dart';
import '../../../core/events/event_bus.dart';
import '../../../core/debug_logger.dart';
import '../../../models/unified_level_data.dart';
import '../../../models/level_data_schema.dart';
import '../../../integrations/interstitial_ad_manager.dart';
import 'unified_game_hud.dart';

/// Abstract base class for all game mode wrappers
/// 
/// Handles:
/// - FlappyGame initialization and lifecycle
/// - LivesManager integration (global lives)
/// - Objective tracking
/// - Event bus and analytics
/// - HUD rendering
/// - Update loop for time-based objectives
abstract class BaseGameWrapper extends StatefulWidget {
  const BaseGameWrapper({super.key});
}

/// Base state class with shared functionality
abstract class BaseGameWrapperState<T extends BaseGameWrapper> extends State<T> {
  // ─────────────────────────────────────────────────────────────────
  // Core Dependencies (Singletons/Managers)
  // ─────────────────────────────────────────────────────────────────
  
  /// Global lives manager (shared across all modes)
  final LivesManager livesManager = LivesManager();
  
  /// Monetization manager for ads
  final MonetizationManager monetizationManager = MonetizationManager();
  
  /// Inventory manager for currency
  final InventoryManager inventoryManager = InventoryManager();
  
  /// Event bus for analytics
  final EventBus eventBus = EventBus();
  
  /// Objective tracker
  final ObjectiveTracker objectiveTracker = ObjectiveTracker();
  
  /// Interstitial ad manager
  final InterstitialAdManager interstitialAdManager = InterstitialAdManager();
  
  // ─────────────────────────────────────────────────────────────────
  // Game State
  // ─────────────────────────────────────────────────────────────────
  
  /// The Flame game instance
  late FlappyGame game;
  
  /// Whether the level has ended (completed or failed)
  bool levelEnded = false;
  
  /// Timer for update loop (time-based objectives)
  Timer? updateTimer;
  
  // ─────────────────────────────────────────────────────────────────
  // Abstract Methods (Must be implemented by subclasses)
  // ─────────────────────────────────────────────────────────────────
  
  /// The unified level data for this game session
  /// Subclasses must provide this based on their mode
  UnifiedLevelData get levelData;
  
  /// Called when the level is completed successfully
  void onLevelCompleted();
  
  /// Called when the player fails (loses all lives in current attempt)
  void onLevelFailed();
  
  /// Build the HUD configuration for this mode
  GameHUDConfig buildHUDConfig();
  
  /// Get event data for analytics
  Map<String, dynamic> getEventData();
  
  // ─────────────────────────────────────────────────────────────────
  // Optional Overrides
  // ─────────────────────────────────────────────────────────────────
  
  /// Called when game is about to start (after initialization)
  /// Override to add mode-specific pre-game logic
  void onGameStarting() {}
  
  /// Called when an obstacle is passed
  /// Override for custom obstacle handling
  void onObstaclePassed() {
    if (levelEnded) return;
    
    objectiveTracker.incrementProgress();
    
    // Check for completion if objective is passObstacles
    if (levelData.objective.type == ObjectiveType.passObstacles &&
        objectiveTracker.isCompleted &&
        !levelEnded) {
      _handleLevelCompleted();
    }
  }
  
  /// Called when the player dies/crashes
  /// Override for custom death handling
  void onGameOver() {
    if (levelEnded) return;
    
    safePrint('💀 Game over! Lives: ${livesManager.currentLives}');
    
    // Consume a life
    livesManager.consumeLife();
    
    // Check if we should show game over
    if (livesManager.currentLives <= 0) {
      _handleLevelFailed();
    } else {
      // Still have lives, show continue option or auto-restart
      showContinueOption();
    }
  }
  
  /// Show continue option (after losing a life but still have lives remaining)
  /// Override for mode-specific continue flow
  void showContinueOption() {
    // Default: just restart the game
    game.continueGame();
    _startUpdateTimer();
  }
  
  /// Build additional overlay widgets
  /// Override to add mode-specific overlays (VS indicator, etc.)
  List<Widget> buildAdditionalOverlays() => [];
  
  /// Whether to hide the game's internal lives display
  /// Most modes should return true since we use UnifiedGameHUD
  bool get hideLivesDisplay => true;
  
  /// Delay before auto-starting the game (milliseconds)
  int get autoStartDelay => 800;
  
  // ─────────────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────────────
  
  @override
  void initState() {
    super.initState();
    _initializeGame();
  }
  
  @override
  void dispose() {
    updateTimer?.cancel();
    game.gameStateManager.removeListener(_onGameStateChanged);
    super.dispose();
  }
  
  // ─────────────────────────────────────────────────────────────────
  // Game Initialization
  // ─────────────────────────────────────────────────────────────────
  
  void _initializeGame() {
    safePrint('🎮 Initializing game: ${levelData.name}');
    safePrint('🎮 Mode: ${levelData.gameMode.name}');
    safePrint('🎮 Objective: ${levelData.objective.type.name} -> ${levelData.objective.target}');
    
    levelEnded = false;
    
    // Start objective tracking
    objectiveTracker.startTracking(levelData.objective);
    
    // Fire level started event
    eventBus.fire('level_started', {
      ...getEventData(),
      'lives_remaining': livesManager.currentLives,
    });
    
    // Create the Flame game
    game = FlappyGame(
      monetization: monetizationManager,
      isStoryMode: levelData.gameMode == GameMode.story,
      storyModeLevel: levelData.toLevelData(),
      onObstaclePassed: onObstaclePassed,
      onGameOver: onGameOver,
      eventBus: eventBus,
      hideLivesDisplay: hideLivesDisplay,
    );
    
    // Listen to game state changes
    game.gameStateManager.addListener(_onGameStateChanged);
    
    // Hook for subclasses
    onGameStarting();
    
    // Auto-start after delay
    Future.delayed(Duration(milliseconds: autoStartDelay), () {
      if (mounted && !levelEnded) {
        _startGame();
      }
    });
  }
  
  void _startGame() {
    safePrint('🎮 Starting game...');
    game.handleTap();
    _startUpdateTimer();
  }
  
  // ─────────────────────────────────────────────────────────────────
  // Update Loop (for time-based objectives)
  // ─────────────────────────────────────────────────────────────────
  
  void _startUpdateTimer() {
    updateTimer?.cancel();
    updateTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted || levelEnded || game.gameStateManager.isGameOver) {
        timer.cancel();
        return;
      }
      
      // Update time-based progress
      if (levelData.objective.type == ObjectiveType.surviveTime) {
        final elapsedMs = game.gameStateManager.getElapsedGameTime();
        objectiveTracker.updateTimeProgress(elapsedMs);
        
        // Check for completion
        if (objectiveTracker.isCompleted && !levelEnded) {
          timer.cancel();
          _handleLevelCompleted();
        }
      }
      
      // Trigger rebuild for HUD update
      if (mounted) {
        setState(() {});
      }
    });
  }
  
  // ─────────────────────────────────────────────────────────────────
  // Game State Handlers
  // ─────────────────────────────────────────────────────────────────
  
  void _onGameStateChanged() {
    if (game.gameStateManager.isGameOver && !levelEnded) {
      onGameOver();
    }
  }
  
  void _handleLevelCompleted() {
    if (levelEnded) return;
    levelEnded = true;
    updateTimer?.cancel();
    
    safePrint('🎉 Level completed: ${levelData.name}');
    
    // Fire analytics event
    eventBus.fire('level_completed', {
      ...getEventData(),
      'time_elapsed': objectiveTracker.elapsedSeconds.floor(),
      'obstacles_passed': objectiveTracker.currentProgress,
      'lives_remaining': livesManager.currentLives,
    });
    
    // Call subclass handler
    onLevelCompleted();
  }
  
  void _handleLevelFailed() {
    if (levelEnded) return;
    levelEnded = true;
    updateTimer?.cancel();
    
    safePrint('💔 Level failed: ${levelData.name}');
    
    // Fire analytics event
    eventBus.fire('level_failed', {
      ...getEventData(),
      'time_elapsed': objectiveTracker.elapsedSeconds.floor(),
      'obstacles_passed': objectiveTracker.currentProgress,
      'reason': 'no_lives',
    });
    
    // Call subclass handler
    onLevelFailed();
  }
  
  // ─────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────
  
  /// Get current objective progress
  int get currentProgress {
    switch (levelData.objective.type) {
      case ObjectiveType.passObstacles:
        return objectiveTracker.currentProgress;
      case ObjectiveType.surviveTime:
        return objectiveTracker.elapsedSeconds.floor();
      case ObjectiveType.beatBot:
        return objectiveTracker.currentProgress;
    }
  }
  
  /// Get target progress
  int get targetProgress => levelData.objective.target;
  
  /// Whether objective is completed
  bool get isObjectiveCompleted => objectiveTracker.isCompleted;
  
  // ─────────────────────────────────────────────────────────────────
  // Build Methods
  // ─────────────────────────────────────────────────────────────────
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Flame Game Widget with tap detection
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                safePrint('🎯 TAP: Forwarding to game');
                game.handleTap();
              },
              child: GameWidget(game: game),
            ),
          ),
          
          // Unified HUD Overlay
          Positioned.fill(
            child: IgnorePointer(
              child: SafeArea(
                child: UnifiedGameHUD(
                  config: buildHUDConfig(),
                ),
              ),
            ),
          ),
          
          // Additional mode-specific overlays
          ...buildAdditionalOverlays(),
        ],
      ),
    );
  }
}

/// Mixin for tournament-specific functionality
/// 
/// Provides:
/// - Tournament entry management
/// - Continue flow (gems/ads)
/// - Try tracking
/// - Tournament-specific events
mixin TournamentWrapperMixin<T extends BaseGameWrapper> on BaseGameWrapperState<T> {
  /// Tournament ID
  String get tournamentId;
  
  /// Current tournament try
  int get currentTry;
  
  /// Current round/level in tournament
  int get currentRound;
  
  /// Total rounds in tournament
  int get totalRounds;
  
  /// Number of continues used in current try
  int continuesUsed = 0;
  
  /// Maximum continues allowed per try
  int get maxContinuesPerTry;
  
  /// Gem cost per continue
  int get continueGemCost;
  
  /// Whether ad continues are available
  bool get adContinueAvailable;
  
  @override
  Map<String, dynamic> getEventData() {
    return {
      'tournament_id': tournamentId,
      'tournament_round': currentRound,
      'total_rounds': totalRounds,
      'try_number': currentTry,
      'level_name': levelData.name,
      'objective_type': levelData.objective.type.name,
      'continues_used': continuesUsed,
    };
  }
  
  /// Check if continue with ad is possible
  bool get canContinueWithAd => 
      adContinueAvailable && continuesUsed < maxContinuesPerTry;
  
  /// Check if continue with gems is possible
  bool canContinueWithGems(int currentGems) => 
      currentGems >= continueGemCost && continuesUsed < maxContinuesPerTry;
  
  /// Continue game via ad
  Future<bool> continueWithAd() async {
    if (!canContinueWithAd) return false;
    
    bool adWatched = false;
    await monetizationManager.showRewardedAdForExtraLife(
      onReward: () {
        adWatched = true;
      },
      onAdFailure: () {
        adWatched = false;
      },
    );
    
    if (adWatched) {
      continuesUsed++;
      eventBus.fire('continue_used', {
        ...getEventData(),
        'continue_type': 'ad',
      });
      game.continueGame();
      _startUpdateTimer();
      return true;
    }
    return false;
  }
  
  /// Continue game via gems
  Future<bool> continueWithGems() async {
    final currentGems = inventoryManager.gems;
    if (!canContinueWithGems(currentGems)) return false;
    
    final success = await inventoryManager.spendGems(
      continueGemCost, 
      spentOn: 'tournament_continue',
    );
    if (!success) return false;
    
    continuesUsed++;
    eventBus.fire('continue_used', {
      ...getEventData(),
      'continue_type': 'gems',
      'gems_cost': continueGemCost,
    });
    game.continueGame();
    _startUpdateTimer();
    return true;
  }
  
  void _startUpdateTimer() {
    // Call the parent's timer start - this is a bit awkward
    // In a real implementation, you might want to restructure this
    super._startUpdateTimer();
  }
}


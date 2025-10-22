/// 🎮 STORY MODE - GAME WRAPPER
/// 
/// Wraps the existing FlappyGame with story mode logic.
/// Tracks objectives and handles level completion/failure.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flame/game.dart';
import '../../models/level_data_schema.dart';
import '../../game/flappy_game.dart';
import '../../game/systems/objective_tracker.dart';
import '../../game/systems/inventory_manager.dart';
import '../../game/systems/lives_manager.dart';
import '../../game/systems/monetization_manager.dart';
import '../screens/level_complete_screen.dart';
import '../screens/level_failed_screen.dart';
import '../screens/world_map_screen.dart';
import '../widgets/game_over_menu.dart';
import '../../core/debug_logger.dart';

class StoryModeGameWrapper extends StatefulWidget {
  final LevelData level;

  const StoryModeGameWrapper({
    super.key,
    required this.level,
  });

  @override
  State<StoryModeGameWrapper> createState() => _StoryModeGameWrapperState();
}

class _StoryModeGameWrapperState extends State<StoryModeGameWrapper> {
  late FlappyGame _game;
  final ObjectiveTracker _objectiveTracker = ObjectiveTracker();
  bool _levelEnded = false;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    safePrint('🎮 Initializing story mode game for level ${widget.level.id}');

    // Start tracking objective
    _objectiveTracker.startTracking(widget.level.objective);

    // Create game instance with story mode configuration
    _game = FlappyGame(
      monetization: MonetizationManager(), // ✅ Pass monetization for continue option
      isStoryMode: true,
      storyModeLevel: widget.level,
      onObstaclePassed: _onObstaclePassed,
      onGameOver: _onGameOver,
    );

    // Listen to game state changes (use game's GameStateManager, not our own)
    _game.gameStateManager.addListener(_onGameStateChanged);

    // 🎯 AUTO-START: Story mode should start immediately (no "tap to play")
    // Wait for game to load, then auto-start (initial jump handled by FlappyGame)
    Future.delayed(const Duration(milliseconds: 800), () async {
      if (mounted) {
        safePrint('🎯 Auto-starting story mode game...');
        await _game.handleTap(); // Start the game + initial jump
        
        // 🎯 Start UI update timer for ALL objectives (not just time-based)
        // This ensures the UI updates in real-time for all objective types
        _startUpdateTimer();
      }
    });
  }

  void _startUpdateTimer() {
    safePrint('🎯 TIMER: Starting update timer for objective type: ${widget.level.objective.type}');
    safePrint('🎯 TIMER: Initial gameStartTime from GameStateManager: ${_game.gameStateManager.gameStartTime}');
    
    // Update UI every 100ms for smooth countdown
    _updateTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted || _levelEnded || _game.gameStateManager.isGameOver) {
        safePrint('🎯 TIMER: Cancelling timer - mounted: $mounted, levelEnded: $_levelEnded, gameOver: ${_game.gameStateManager.isGameOver}');
        timer.cancel();
        return;
      }

      // Update progress based on objective type
      if (widget.level.objective.type == ObjectiveType.surviveTime) {
        final gameStartTime = _game.gameStateManager.gameStartTime;
        // Only log every second to avoid spam
        if (DateTime.now().millisecond < 200) {
          safePrint('🎯 TIMER TICK: gameStartTime = $gameStartTime');
        }
        _objectiveTracker.updateTimeProgress(gameStartTime);
      } else if (widget.level.objective.type == ObjectiveType.beatBot) {
        // Update bot battle scores from game
        final playerScore = _game.gameStateManager.score;
        final botScore = _game.botScore; // Get bot score from game
        final botIsActive = _game.botIsActive; // ✅ Track if bot crashed
        _objectiveTracker.updateBotBattleScore(
          playerScore: playerScore,
          botScore: botScore,
          botIsActive: botIsActive, // ✅ Pass bot active state
        );
      }

      // Trigger UI rebuild
      if (mounted) {
        setState(() {});
      }

      // Check if objective is completed
      if (_objectiveTracker.isCompleted && !_levelEnded) {
        safePrint('🎯 STORY MODE: ✅ OBJECTIVE COMPLETED! Type: ${widget.level.objective.type}');
        timer.cancel();
        _onLevelCompleted();
      }
    });
  }

  void _onObstaclePassed() {
    safePrint('🎯 STORY MODE: _onObstaclePassed called!');
    safePrint('🎯 STORY MODE: Objective type = ${widget.level.objective.type}');
    
    // Update objective progress for "pass obstacles" type
    if (widget.level.objective.type == ObjectiveType.passObstacles) {
      _objectiveTracker.incrementProgress();
      
      safePrint('🎯 STORY MODE: Progress incremented! Current: ${_objectiveTracker.currentProgress}/${widget.level.objective.target}');
      safePrint('🎯 STORY MODE: Is completed? ${_objectiveTracker.isCompleted}');
      safePrint('🎯 STORY MODE: Level ended? $_levelEnded');

      // 🎯 UPDATE UI: Defer setState to avoid calling during build phase
      if (mounted) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {});
          }
        });
      }

      // Check if objective is completed
      if (_objectiveTracker.isCompleted && !_levelEnded) {
        safePrint('🎯 STORY MODE: ✅ OBJECTIVE COMPLETED! Calling _onLevelCompleted()');
        _onLevelCompleted();
      }
    } else {
      safePrint('🎯 STORY MODE: ⚠️ Objective type is NOT passObstacles, skipping increment');
    }
  }

  void _onGameStateChanged() {
    // Update time for "survive time" objectives
    if (widget.level.objective.type == ObjectiveType.surviveTime) {
      // This will be called every frame by the game
      // We'll implement this in the FlappyGame integration
    }
  }

  void _onGameOver() {
    if (_levelEnded) return;

    safePrint('🎮 Game over in story mode');

    // Stop update timer
    _updateTimer?.cancel();

    // Check if objective was completed before game over
    final objectiveCompleted = _objectiveTracker.checkFinalCompletion();

    if (objectiveCompleted) {
      _onLevelCompleted();
    } else {
      // ❌ Objective not completed - show game over menu with Continue/Quit options
      // The game over menu will be shown automatically by the ValueListenableBuilder
      // When the player clicks "Main Menu", _handleBackToMap() will navigate to Level Failed Screen
      safePrint('🎮 ❌ Objective not completed. Showing game over menu with continue options.');
    }
  }

  void _onLevelCompleted() async {
    if (_levelEnded) return;
    _levelEnded = true;

    safePrint('🎮 ✅ Level ${widget.level.id} completed!');

    // ✅ FIX: Refill hearts to max when level is completed successfully
    final livesManager = LivesManager();
    await livesManager.refillToMax();
    safePrint('💖 Story Mode: Hearts refilled to max after level completion (now: ${livesManager.currentLives})');

    // Calculate time taken
    final now = DateTime.now().millisecondsSinceEpoch;
    final timeTaken = ((now - _game.gameStateManager.gameStartTime) / 1000).round();

    // Navigate to level complete screen
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => LevelCompleteScreen(
            level: widget.level,
            objectiveAchieved: _objectiveTracker.currentProgress,
            timeTaken: timeTaken,
            continuesUsed: _game.gameStateManager.continuesUsedThisRun,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _game.gameStateManager.removeListener(_onGameStateChanged);
    _objectiveTracker.reset();
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Game with tap detection
          GestureDetector(
            onTap: () {
              safePrint('🎯 STORY MODE: UI TAP DETECTED - calling game.handleTap()');
              _game.handleTap();
            },
            child: GameWidget(game: _game),
          ),

          // Objective tracker overlay
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: _buildObjectiveTracker(),
          ),

          // 🎮 STORY MODE: Game Over Menu Overlay (same as endless mode)
          ValueListenableBuilder<bool>(
            valueListenable: _game.gameOverNotifier,
            builder: (context, isGameOver, child) {
              return isGameOver
                  ? _buildStoryModeGameOverMenu()
                  : const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStoryModeGameOverMenu() {
    // Get monetization manager from the game
    final monetization = _game.monetization;
    
    if (monetization == null) {
      // Fallback if monetization is not available
      return Container(
        color: Colors.black54,
        child: Center(
          child: Text(
            'GAME OVER\n\n'
            'Objective: ${widget.level.objective.description}\n'
            'Progress: ${_objectiveTracker.currentProgress}/${widget.level.objective.target}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
    
    // Use the same GameOverMenu as endless mode
    return ListenableBuilder(
      listenable: monetization,
      builder: (context, child) {
        return GameOverMenu(
          score: _game.currentScore,
          bestScore: _game.bestScore,
          onRestart: () => _handleStoryModeRestart(),
          onMainMenu: () => _handleBackToMap(),
          onContinueWithAd: () async {
            safePrint('🎯 STORY MODE: Continue with ad requested');
            
            await monetization.showRewardedAdForExtraLife(
              onAdStart: () {
                // 🎯 CRITICAL: Pause Flame game engine when ad starts
                _game.pauseForAd();
                safePrint('⏸️ STORY MODE: Game engine paused for ad');
              },
              onAdEnd: () {
                // 🎯 CRITICAL: Resume Flame game engine when ad ends
                _game.resumeFromAd();
                safePrint('▶️ STORY MODE: Game engine resumed after ad');
              },
              onReward: () async {
                safePrint('🎯 STORY MODE: Ad reward granted - continuing game');
                
                // ✅ FIX: Restore 1 heart in LivesManager when continuing
                final livesManager = LivesManager();
                await livesManager.addLife(1);
                safePrint('💖 Story Mode: Restored 1 heart after ad continue (now: ${livesManager.currentLives})');
                
                // 🎮 CRITICAL FIX: Force UI rebuild FIRST to remove overlay, THEN continue game
                // This ensures the game over menu is fully removed before the game resumes
                if (mounted) {
                  setState(() {
                    // Trigger gameOverNotifier update synchronously
                    // This will cause the overlay builder to rebuild WITHOUT the game over menu
                  });
                  
                  // Wait for the UI to rebuild (2 frames to be safe)
                  await Future.delayed(const Duration(milliseconds: 50));
                }
                
                // NOW continue the game after the overlay is definitely gone
                _game.continueGame();
                
                safePrint('🎬 Game continued after ad - back in action! Lives=${livesManager.currentLives}, continues remaining: ${_game.continuesRemaining}');
              },
              onAdFailure: () {
                safePrint('🎯 STORY MODE: Ad failed - staying on game over');
              },
            );
          },
          onBuySingleHeart: () => _handleBuySingleHeart(),
          onGoToStore: () => _handleGoToStore(),
          secondsUntilHeart: null,
          onShare: (platform) => _shareScore(platform),
          canContinue: _game.canContinueWithAd,
          continuesRemaining: _game.continuesRemaining,
          playerGems: InventoryManager().gems,
          singleHeartPrice: 3, // Story mode: 3 gems per continue
          isAdLoading: monetization.isAdLoading,
        );
      },
    );
  }
  
  void _handleStoryModeRestart() {
    safePrint('🎯 STORY MODE: Restart requested');
    _game.resetGame();
  }
  
  void _handleBackToMap() {
    if (_levelEnded) return;
    _levelEnded = true;

    safePrint('🎯 STORY MODE: Back to map requested');
    
    // Check if objective was completed
    final objectiveCompleted = _objectiveTracker.isCompleted;
    
    if (objectiveCompleted) {
      // Objective completed - go directly to world map
      safePrint('🎯 STORY MODE: Objective completed, returning to world map');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const WorldMapScreen(),
        ),
        (route) => false,
      );
    } else {
      // Objective NOT completed - show level failed screen
      safePrint('🎯 STORY MODE: Objective NOT completed, showing level failed screen');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => LevelFailedScreen(
            level: widget.level,
            objectiveAchieved: _objectiveTracker.currentProgress,
            objectiveTarget: widget.level.objective.target,
          ),
        ),
      );
    }
  }
  
  void _handleBuySingleHeart() async {
    safePrint('🎯 STORY MODE: Buy single heart with 3 gems');
    
    final inventory = InventoryManager();
    if (inventory.gems >= 3) {
      // Deduct 3 gems
      inventory.spendGems(3);
      
      // ✅ FIX: Restore 1 heart in LivesManager when continuing
      final livesManager = LivesManager();
      await livesManager.addLife(1);
      safePrint('💖 Story Mode: Restored 1 heart after gem continue (now: ${livesManager.currentLives})');
      
      // 🎮 CRITICAL FIX: Force UI rebuild FIRST to remove overlay, THEN continue game
      // This ensures the game over menu is fully removed before the game resumes
      if (mounted) {
        setState(() {
          // Trigger gameOverNotifier update synchronously
          // This will cause the overlay builder to rebuild WITHOUT the game over menu
        });
        
        // Wait for the UI to rebuild (2 frames to be safe)
        await Future.delayed(const Duration(milliseconds: 50));
      }
      
      // NOW continue the game after the overlay is definitely gone
      _game.continueGame();
      
      safePrint('🎯 STORY MODE: Purchased continue with 3 gems');
      safePrint('🎬 Game continued after gem purchase - back in action! Lives=${livesManager.currentLives}');
    } else {
      safePrint('🎯 STORY MODE: Not enough gems (${inventory.gems}/3)');
      _handleGoToStore();
    }
  }
  
  void _handleGoToStore() {
    safePrint('🎯 STORY MODE: Go to store requested');
    // TODO: Navigate to store or show store dialog
    // For now, just go back to map
    _handleBackToMap();
  }
  
  void _shareScore(String platform) {
    safePrint('🎯 STORY MODE: Share score on $platform');
    // TODO: Implement social sharing for story mode
  }

  Widget _buildObjectiveTracker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getObjectiveIcon(),
            color: _objectiveTracker.isCompleted ? Colors.green : Colors.amber,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            _objectiveTracker.getProgressDescription(),
            style: TextStyle(
              color: _objectiveTracker.isCompleted ? Colors.green : Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_objectiveTracker.isCompleted) ...[
            const SizedBox(width: 8),
            const Icon(Icons.check_circle, color: Colors.green, size: 24),
          ],
        ],
      ),
    );
  }

  IconData _getObjectiveIcon() {
    switch (widget.level.objective.type) {
      case ObjectiveType.passObstacles:
        return Icons.flag;
      case ObjectiveType.surviveTime:
        return Icons.timer;
      case ObjectiveType.beatBot:
        return Icons.sports_esports;
    }
  }
}

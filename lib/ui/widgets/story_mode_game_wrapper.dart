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
import '../../game/systems/level_system_manager.dart'; // 🔥 NEW
import '../../game/systems/game_events_tracker.dart'; // 🎯 For mission/achievement tracking
import '../../game/systems/achievements_manager.dart'; // 🏅 For story mode achievements
import '../../game/systems/missions_manager.dart'; // 🎯 For level completion mission tracking
import '../../integrations/interstitial_ad_manager.dart'; // 📺 For interstitial ads
import '../screens/level_complete_screen.dart';
import '../screens/level_failed_screen.dart';
import '../screens/world_map_screen.dart';
import '../screens/zone_completion_screen.dart'; // 🏆 Zone celebration
// ✅ FIX: Removed unused import - Story mode no longer uses GameOverMenu
// import '../widgets/game_over_menu.dart';
import '../../core/debug_logger.dart';
import '../../core/events/event_bus.dart';
import '../../core/repositories/user_stats_repository.dart';
import '../../core/database/local_database_manager.dart';
import 'game/in_game_hearts_display.dart';
import 'game/vs_indicator.dart';
import 'game/objective_indicator.dart';
import 'game/unified_game_hud.dart';

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
  
  // ✅ FIX: Store first attempt status for accurate analytics
  // This is checked at game START and used at game END
  bool _wasFirstAttempt = false;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    safePrint('🎮 Initializing story mode game for level ${widget.level.id}');

    // Phase 3: Get EventBus and UserStatsRepository for game_ended events
    final eventBus = EventBus();
    final database = LocalDatabaseManager();
    final userStats = UserStatsRepository(database);

    // Get LivesManager to track hearts
    final livesManager = LivesManager();

    // 🔥 CRITICAL: Check first attempt status BEFORE marking level as attempted
    // This ensures FlappyWorld can see the correct first-attempt status for bot override
    final levelManager = LevelSystemManager();
    _wasFirstAttempt = levelManager.isFirstAttempt(widget.level.id); // ✅ Store for use in _onLevelCompleted
    final attemptNumber = _wasFirstAttempt ? 1 : 2; // 1 for first, 2+ for retries (we don't track exact count yet)
    
    safePrint('🔥 Level ${widget.level.id}: isFirstAttempt=$_wasFirstAttempt');

    // 🔥 Mark this level as attempted (AFTER checking status)
    // This must happen AFTER checking isFirstAttempt but BEFORE game initialization
    levelManager.markLevelAttempted(widget.level.id);

    // Start tracking objective
    _objectiveTracker.startTracking(widget.level.objective);

    // Fire level_started event for analytics
    eventBus.fire('level_started', {
      'level_id': widget.level.id,
      'zone_id': widget.level.zone,
      'level_name': widget.level.name,
      'difficulty': widget.level.difficulty.toString(),
      'objective_type': widget.level.objective.type.toString(),
      'attempt_number': attemptNumber,
      'hearts_remaining': livesManager.currentLives,
      'is_first_attempt': _wasFirstAttempt, // ✅ FIX: Use stored class member
    });

    // Create game instance with story mode configuration
    _game = FlappyGame(
      monetization: MonetizationManager(), // ✅ Pass monetization for continue option
      isStoryMode: true,
      storyModeLevel: widget.level,
      onObstaclePassed: _onObstaclePassed,
      onGameOver: _onGameOver,
      levelSystemManager: LevelSystemManager(), // 🔥 Pass level system manager
      userStatsRepository: userStats,  // Phase 2: For persistence
      eventBus: eventBus,               // Phase 3: For game_ended events
      hideLivesDisplay: true, // ❤️ Wrapper shows consistent Flutter hearts overlay
    );

    // Listen to game state changes (use game's GameStateManager, not our own)
    _game.gameStateManager.addListener(_onGameStateChanged);

    // 🎯 AUTO-START: Story mode should start immediately (no "tap to play")
    // Wait for game to load, then auto-start (initial jump handled by FlappyGame)
    Future.delayed(const Duration(milliseconds: 800), () async {
      if (mounted) {
        safePrint('🎯 Auto-starting story mode game...');
        
        // ✅ SAFETY NET: If hearts are somehow 0 at level start, restore to max
        // This catches edge cases where victory + death on same frame incorrectly resets hearts
        final currentHearts = livesManager.currentLives;
        if (currentHearts <= 0) {
          safePrint('⚠️ SAFETY NET: Hearts were $currentHearts at level start - restoring to max!');
          await livesManager.setLives(livesManager.maxLives);
          safePrint('💖 Hearts restored to ${livesManager.maxLives}');
        }
        
        // Wait for the game to be fully loaded before starting
        // Check if game components are mounted (loaded is a Future, not bool)
        int attempts = 0;
        while (!_game.isMounted && attempts < 100) {
          safePrint('🎯 Waiting for game to load... (attempt $attempts)');
          await Future.delayed(const Duration(milliseconds: 50));
          attempts++;
        }
        
        if (!_game.isMounted) {
          safePrint('🎯 ⚠️ Game failed to load after ${attempts * 50}ms');
          return;
        }
        
        safePrint('🎯 Game loaded! Starting now...');
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
        // ⏱️ FIX: Use getElapsedGameTime() to exclude ad pauses
        final elapsedGameTimeMs = _game.gameStateManager.getElapsedGameTime();
        // 🛑 PERFORMANCE: Timer tick logging removed to reduce log spam
        // Only the TIME UPDATE logs (every second) remain for debugging
        _objectiveTracker.updateTimeProgress(elapsedGameTimeMs);
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

  /// 🎯 ZONE 1: Award points for positionally passed obstacles
  /// Called when player crashes in Zone 1 - awards objective progress for obstacles
  /// that were positionally passed (jet X > obstacle right edge) but not scored via gap
  /// 
  /// ✅ PERFORMANCE: Event-driven approach - only checks on crash, not every frame
  void _awardZone1PositionalPassingPoints() {
    // Get unscored obstacles that were positionally passed
    // This checks all obstacles once on crash (O(n) on rare event)
    final unscoredObstacles = _game.obstacleManager.getPositionallyPassedButUnscored(
      _game.jet.position,
    );
    
    if (unscoredObstacles.isEmpty) {
      safePrint('🎯 ZONE 1: No unscored positionally passed obstacles found');
      return;
    }
    
    safePrint('🎯 ZONE 1: Awarding ${unscoredObstacles.length} positional passing points');
    
    // Award objective progress for each unscored obstacle
    for (final obstacle in unscoredObstacles) {
      // Mark as scored to prevent double scoring
      obstacle.scored = true;
      
      // Increment objective progress
      if (widget.level.objective.type == ObjectiveType.passObstacles) {
        _objectiveTracker.incrementProgress();
        safePrint('🎯 ZONE 1: Progress incremented via positional passing: ${_objectiveTracker.currentProgress}/${widget.level.objective.target}');
      }
      
      // For bot battles (1v1), also increment game score
      if (widget.level.objective.type == ObjectiveType.beatBot) {
        _game.gameStateManager.updateScore(_game.gameStateManager.score + 1);
        _objectiveTracker.updateBotBattleScore(
          playerScore: _game.gameStateManager.score,
        );
        safePrint('🎯 ZONE 1: Bot battle score incremented via positional passing: ${_game.gameStateManager.score}');
      }
    }
    
    // Update UI
    if (mounted) {
      setState(() {});
    }
    
    // Check if objective is now completed
    if (_objectiveTracker.isCompleted && !_levelEnded) {
      safePrint('🎯 ZONE 1: ✅ Objective completed via positional passing!');
      // Note: _onLevelCompleted() will be called by the completion check in _onGameOver()
    }
  }

  void _onGameOver() {
    if (_levelEnded) return;
    
    // ✅ EDGE CASE FIX: Use state lock to prevent race condition
    // If victory was already triggered, don't show game over
    if (!_game.gameStateManager.trySetGameOver()) {
      safePrint('🎮 Game over ignored - victory already triggered (victory priority)');
      return;
    }

    // ✅ CRITICAL FIX: Set _levelEnded immediately to prevent duplicate calls
    _levelEnded = true;

    safePrint('🎮 Game over in story mode');

    // Stop update timer
    _updateTimer?.cancel();
    
    // ⏱️ CRITICAL FIX: Pause game time IMMEDIATELY when game over screen appears
    // This prevents the timer from running while the player views the game over menu
    _game.gameStateManager.pauseGameTime();
    safePrint('⏸️ STORY MODE: Game time paused on game over (before ad)');

    // 🎯 ZONE 1: Check for positional passing before checking objective completion
    // Award points for obstacles that were positionally passed but not scored via gap
    if (widget.level.zone == 1 && 
        (widget.level.objective.type == ObjectiveType.passObstacles ||
         widget.level.objective.type == ObjectiveType.beatBot)) {
      _awardZone1PositionalPassingPoints();
    }

    // Check if objective was completed before game over
    final objectiveCompleted = _objectiveTracker.checkFinalCompletion();

    if (objectiveCompleted) {
      // ✅ EDGE CASE: Objective was completed! Use victory priority
      // Reset _levelEnded so _onLevelCompleted can proceed
      _levelEnded = false;
      _game.gameStateManager.resetEndState(); // Allow victory to take over
      _onLevelCompleted();
    } else {
      // ❌ Objective not completed - navigate DIRECTLY to beautiful game over popup
      // Skip the GameOverMenu entirely for a cleaner, more engaging experience
      safePrint('🎮 ❌ Objective not completed. Showing story mode game over popup.');
      
      // Lock state to prevent any further changes
      _game.gameStateManager.lockEndState();
      
      // ✅ FIX: Defer popup showing until after current frame completes
      // This prevents "Navigator is locked" errors when called during Flame's update loop
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showStoryModeGameOverPopup();
        }
      });
    }
  }

  /// 💀 Show beautiful story mode game over popup (bypasses endless game over menu)
  void _showStoryModeGameOverPopup() {
    final monetization = MonetizationManager();
    
    // 🎯 Track story mode failure for missions/achievements (still counts as playing)
    final gameEventsTracker = GameEventsTracker();
    final finalScore = _objectiveTracker.currentProgress;
    final usedContinue = _game.gameStateManager.continuesUsedThisRun > 0;
    final elapsedGameTimeMs = _game.gameStateManager.getElapsedGameTime();
    
    // ✅ FIX: Track actual coins earned (in-game coins collected)
    // Note: Level completion rewards are not earned on failure, so only track in-game coins
    final coinsCollected = _game.gameStateManager.coinsCollectedThisRun;
    
    gameEventsTracker.onGameEnd(
      finalScore: finalScore,
      survivalTimeMs: elapsedGameTimeMs.toInt(),
      coinsEarned: coinsCollected, // ✅ Track in-game coins collected before failure
      usedContinue: usedContinue,
      cause: 'story_level_failed',
    );
    safePrint('🎯 Story mode: Mission progress updated (level failed, $coinsCollected coins)');
    
    // Fire level_failed event for analytics
    final eventBus = EventBus();
    eventBus.fire('level_failed', {
      'level_id': widget.level.id,
      'zone_id': widget.level.zone,
      'level_name': widget.level.name,
      'score': _objectiveTracker.currentProgress,
      'objective_target': widget.level.objective.target,
      'objective_type': widget.level.objective.type.toString(),
      'cause_of_death': 'obstacle_collision', // TODO: Get actual cause from game
      'time_survived_seconds': _game.gameStateManager.getElapsedGameTime() ~/ 1000,
      'hearts_remaining': LivesManager().currentLives,
      'continues_used': _game.gameStateManager.continuesUsedThisRun,
      'is_first_attempt': _wasFirstAttempt, // ✅ NEW: Track if this was user's first attempt
    });
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LevelFailedScreen(
          level: widget.level,
          objectiveAchieved: _objectiveTracker.currentProgress,
          objectiveTarget: widget.level.objective.target,
          continuesUsed: _game.gameStateManager.continuesUsedThisRun,
          continuesRemaining: _game.gameStateManager.continuesRemaining,
          // Continue with ad callback
          onContinueWithAd: _game.canContinueWithAd 
            ? () async {
                safePrint('🎯 STORY MODE: Continue with ad requested from popup');
                
                await monetization.showRewardedAdForExtraLife(
                  onAdStart: () {
                    _game.pauseForAd();
                    safePrint('⏸️ STORY MODE: Game engine paused for ad');
                    _game.gameStateManager.pauseGameTime();
                  },
                  onAdEnd: () {
                    _game.resumeFromAd();
                    safePrint('▶️ STORY MODE: Game engine resumed after ad');
                    _game.gameStateManager.resumeGameTime();
                  },
                  onReward: () async {
                    safePrint('🎯 STORY MODE: Ad reward granted - continuing game');
                    
                    // Restore 1 heart
                    final livesManager = LivesManager();
                    await livesManager.addLife(1);
                    safePrint('💖 Story Mode: Restored 1 heart after ad (now: ${livesManager.currentLives})');
                    
                    // ✅ FIX: Track continue usage for missions
                    final gameEventsTracker = GameEventsTracker();
                    await gameEventsTracker.onContinueUsed(gemsCost: 0); // Ad-based, no gems
                    safePrint('🎯 MISSIONS: Continue with ad tracked');
                    
                    // ✅ FIX: Defer popup closing until after current frame completes
                    // This prevents "Navigator is locked" errors when called during animations
                    if (mounted) {
                      SchedulerBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          Navigator.of(context).pop();
                        }
                      });
                    }
                    
                    // ✅ CRITICAL FIX: Reset _levelEnded so timer can run!
                    // This was causing the timer to immediately cancel after continue
                    _levelEnded = false;
                    safePrint('🔄 STORY MODE: _levelEnded reset to false for continue');
                    
                    // Continue game (this also resets end state now)
                    _game.continueGame();
                    
                    // Restart timer for time-based levels
                    if (widget.level.objective.type == ObjectiveType.surviveTime || 
                        widget.level.objective.type == ObjectiveType.beatBot) {
                      _updateTimer?.cancel();
                      _startUpdateTimer();
                      safePrint('🎯 TIMER: Restarted after ad continue');
                    }
                  },
                  onAdFailure: () {
                    safePrint('🎯 STORY MODE: Ad failed - staying on popup');
                  },
                );
              }
            : null,
          // Continue with gems callback (3 gems)
          onContinueWithGems: _game.canContinueWithAd
            ? () async {
                safePrint('🎯 STORY MODE: Continue with gems requested');
                
                final inventory = InventoryManager();
                const gemCost = 3;
                
                if (inventory.gems >= gemCost) {
                  // Deduct gems
                  final success = await inventory.spendGems(gemCost);
                  if (!success) {
                    safePrint('⚠️ Failed to spend gems for continue');
                    return;
                  }
                  safePrint('💎 Deducted $gemCost gems for continue');
                  
                  // Restore 1 heart
                  final livesManager = LivesManager();
                  await livesManager.addLife(1);
                  safePrint('💖 Story Mode: Restored 1 heart after gem continue (now: ${livesManager.currentLives})');
                  
                  // ✅ FIX: Track continue usage for missions
                  final gameEventsTracker = GameEventsTracker();
                  await gameEventsTracker.onContinueUsed(gemsCost: gemCost);
                  safePrint('🎯 MISSIONS: Continue with gems tracked');
                  
                  // ✅ FIX: Defer popup closing until after current frame completes
                  // This prevents "Navigator is locked" errors when called during animations
                  if (mounted) {
                    SchedulerBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        Navigator.of(context).pop();
                      }
                    });
                  }
                  
                  // ✅ CRITICAL FIX: Reset _levelEnded so timer can run!
                  // This was causing the timer to immediately cancel after continue
                  _levelEnded = false;
                  safePrint('🔄 STORY MODE: _levelEnded reset to false for gem continue');
                  
                  // Continue game (this also resets end state now)
                  _game.continueGame();
                  
                  // Restart timer for time-based levels
                  if (widget.level.objective.type == ObjectiveType.surviveTime || 
                      widget.level.objective.type == ObjectiveType.beatBot) {
                    _updateTimer?.cancel();
                    _startUpdateTimer();
                    safePrint('🎯 TIMER: Restarted after gem continue');
                  }
                } else {
                  safePrint('⚠️ Not enough gems for continue');
                }
              }
            : null,
        ),
      ),
    );
  }

  void _onLevelCompleted() async {
    if (_levelEnded) return;
    
    // ✅ EDGE CASE FIX: Use victory state lock
    // Victory has priority - always succeeds unless state is already locked
    if (!_game.gameStateManager.trySetVictory()) {
      // State is locked, but check if we can still proceed
      // This handles the case where game over checked objective and redirected here
      if (_game.gameStateManager.isEndStateLocked) {
        safePrint('🎮 Level completed ignored - state already locked');
        return;
      }
    }
    
    _levelEnded = true;
    
    // Lock state to prevent any game over from interfering
    _game.gameStateManager.lockEndState();

    safePrint('🎮 ✅ Level ${widget.level.id} completed!');

    // ═══════════════════════════════════════════════════════════════════════════
    // 🚀 PERFORMANCE OPTIMIZATION: Animation-First Architecture
    // ═══════════════════════════════════════════════════════════════════════════
    // On low-end devices, heavy operations (DB writes, analytics, achievement checks)
    // were blocking the main thread, causing 200-300ms stutter at victory.
    // 
    // NEW FLOW:
    // 1. Capture lightweight data synchronously (fast)
    // 2. Start victory animation IMMEDIATELY (visual feedback)
    // 3. Defer heavy operations to background (non-blocking)
    // ═══════════════════════════════════════════════════════════════════════════

    // 📸 PHASE 1: Capture all data synchronously (fast, ~1-2ms)
    final levelManager = LevelSystemManager();
    final livesManager = LivesManager();
    final actualHeartsRemaining = _game.gameStateManager.lives;
    final elapsedGameTimeMs = _game.gameStateManager.getElapsedGameTime();
    final timeTaken = (elapsedGameTimeMs / 1000).round();
    final finalScore = _objectiveTracker.currentProgress;
    final usedContinue = _game.gameStateManager.continuesUsedThisRun > 0;
    final continuesUsed = _game.gameStateManager.continuesUsedThisRun;
    final levelCoins = widget.level.reward.coins;
    final inGameCoins = _game.gameStateManager.coinsCollectedThisRun;
    final totalCoins = levelCoins + inGameCoins;
    final isReplay = levelManager.isLevelReplay(widget.level.id);
    final zoneCompleted = levelManager.isZoneCompleted(widget.level.zone) ? widget.level.zone : 0;
    final wasFlawless = continuesUsed == 0;
    // Use cached count instead of looping 100 times
    final totalCompleted = levelManager.totalLevelsCompleted;
    
    safePrint('📸 Data captured: score=$finalScore, time=${timeTaken}s, hearts=$actualHeartsRemaining, isReplay=$isReplay');

    // 🎵 PHASE 2: Fire-and-forget audio (non-blocking)
    unawaited(_game.audioManager.stopMusic().catchError((e) {
      safePrint('⚠️ Failed to stop story mode music: $e');
    }));

    // 🎉 PHASE 3: Start victory animation IMMEDIATELY (visual feedback first!)
    final victoryStarted = _game.victoryController.startVictory(widget.level.id);
    safePrint('🎉 Victory animation ${victoryStarted ? "started" : "could not start"} for level ${widget.level.id}');

    // 📊 PHASE 4: Defer heavy operations to background (non-blocking)
    // These run while the animation plays, so user sees smooth visuals
    unawaited(_performBackgroundOperations(
      livesManager: livesManager,
      actualHeartsRemaining: actualHeartsRemaining,
      finalScore: finalScore,
      elapsedGameTimeMs: elapsedGameTimeMs,
      totalCoins: totalCoins,
      usedContinue: usedContinue,
      continuesUsed: continuesUsed,
      timeTaken: timeTaken,
      totalCompleted: totalCompleted,
      zoneCompleted: zoneCompleted,
      wasFlawless: wasFlawless,
    ));

    // 🎬 PHASE 5: Set up victory completion callback
    if (victoryStarted) {
      _game.victoryController.onVictoryComplete = () {
        safePrint('🎉 Victory animation complete - showing popup');
        _game.pauseEngine();
        _showLevelCompletePopup(isReplay, levelManager, timeTaken);
      };
    } else {
      // Victory couldn't start - show popup immediately
      safePrint('⚠️ Victory animation could not start - showing popup immediately');
      _game.pauseEngine();
      _showLevelCompletePopup(isReplay, levelManager, timeTaken);
    }
  }

  /// 🔄 Perform heavy operations in background (non-blocking)
  /// These run while the victory animation plays
  Future<void> _performBackgroundOperations({
    required LivesManager livesManager,
    required int actualHeartsRemaining,
    required int finalScore,
    required int elapsedGameTimeMs, // ✅ FIX: int, not double
    required int totalCoins,
    required bool usedContinue,
    required int continuesUsed,
    required int timeTaken,
    required int totalCompleted,
    required int zoneCompleted,
    required bool wasFlawless,
  }) async {
    try {
      // 💖 Sync lives (SharedPreferences write)
      await livesManager.setLives(actualHeartsRemaining);
      safePrint('💖 [BG] Lives synced: $actualHeartsRemaining');

      // 🎯 Track missions/achievements
      final gameEventsTracker = GameEventsTracker();
      await gameEventsTracker.onGameEnd(
        finalScore: finalScore,
        survivalTimeMs: elapsedGameTimeMs.toInt(),
        coinsEarned: totalCoins,
        usedContinue: usedContinue,
        cause: 'story_level_completed',
      );
      safePrint('🎯 [BG] Mission progress updated');

      // 📊 Fire analytics event (EventBus is non-blocking)
      final eventBus = EventBus();
      eventBus.fire('level_completed', {
        'level_id': widget.level.id,
        'zone_id': widget.level.zone,
        'level_name': widget.level.name,
        'score': finalScore,
        'stars': 0,
        'time_seconds': timeTaken,
        'hearts_remaining': actualHeartsRemaining,
        'first_attempt': _wasFirstAttempt,
        'objective_type': widget.level.objective.type.toString(),
        'continues_used': continuesUsed,
      });
      safePrint('📊 [BG] Analytics event fired');

      // 🎯 Update mission progress for completeLevel mission type
      final missionsManager = MissionsManager();
      await missionsManager.updatePlayerStats(
        completedLevel: widget.level.id,
        completedZone: zoneCompleted > 0 ? zoneCompleted : null,
      );
      safePrint('🎯 [BG] Level completion mission progress updated');

      // 🏅 Check achievements (can be heavy)
      final achievementsManager = AchievementsManager();
      await achievementsManager.checkStoryModeAchievements(
        levelCompleted: true,
        totalLevelsCompleted: totalCompleted,
        zoneCompleted: zoneCompleted,
        wasFlawless: wasFlawless,
        objectiveType: widget.level.objective.type.toString(),
        timeTaken: timeTaken,
      );
      safePrint('🏅 [BG] Achievements checked');
      
    } catch (e) {
      // Background errors shouldn't crash the game
      safePrint('⚠️ [BG] Background operation error (non-fatal): $e');
    }
  }
  
  /// Show the level complete popup (extracted to allow calling after animation)
  void _showLevelCompletePopup(bool isReplay, LevelSystemManager levelManager, int timeTaken) {
    if (!mounted) return;
    
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => LevelCompleteScreen(
          level: widget.level,
          objectiveAchieved: _objectiveTracker.currentProgress,
          timeTaken: timeTaken,
          continuesUsed: _game.gameStateManager.continuesUsedThisRun,
          onContinue: () async {
            // ✅ DON'T close popup yet - keep celebration visible during ad
            
            // ✅ Track level win for interstitial ad frequency (for ALL wins, including replays)
            await InterstitialAdManager().onLevelWon();
            
            // ✅ Check and show interstitial ad if conditions are met
            final adShown = await InterstitialAdManager().checkAndShowAd(
              onAdClosed: () {
                // ✅ NOW close the popup after ad finishes
                if (mounted) Navigator.of(context).pop();
                _proceedAfterAd(isReplay, levelManager);
              },
            );
            
            // If no ad was shown, close popup and proceed immediately
            if (!adShown) {
              if (mounted) Navigator.of(context).pop();
              _proceedAfterAd(isReplay, levelManager);
            }
            
            // Note: No need to resumeEngine() - we're navigating away and game will be disposed
          },
        ),
      );
  }
  
  /// ✅ NEW: Helper to proceed after ad is shown (or skipped)
  void _proceedAfterAd(bool isReplay, LevelSystemManager levelManager) {
    // ✅ FIX: Use cached replay status (checked BEFORE rewards were granted)
    if (isReplay) {
      safePrint('🔄 Replay completed - returning to world map (no animation)');
      _navigateToWorldMapNoAnimation();
    } else {
      // 🏆 CRITICAL: Check if zone was just completed (last level in zone)
      final wasZoneCompleted = levelManager.wasZoneJustCompleted(widget.level.id);
      
      if (wasZoneCompleted) {
        safePrint('🏆 ZONE COMPLETED! Showing celebration, then switching to next zone');
        _navigateToZoneCompletionCelebration();
      } else {
        safePrint('🎉 First completion - navigating with jet animation');
        _navigateToWorldMapWithAnimation();
      }
    }
  }
  
  /// ✅ NEW: Navigate to world map with jet animation (first completion only)
  void _navigateToWorldMapWithAnimation() {
    if (!mounted) return;
    
    final currentLevel = widget.level.id;
    final nextLevel = currentLevel + 1;
    
    safePrint('✈️ Navigating to world map with animation: $currentLevel → $nextLevel');
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => WorldMapScreen(
          shouldAnimateJet: true,
          fromLevel: currentLevel,
          toLevel: nextLevel,
        ),
      ),
    );
  }
  
  /// 🏆 NEW: Navigate to zone completion celebration (no jet animation, zone switches)
  void _navigateToZoneCompletionCelebration() {
    if (!mounted) return;
    
    final completedZone = widget.level.zone;
    final nextZone = completedZone + 1;
    
    safePrint('🏆 Navigating to zone completion celebration for Zone $completedZone');
    
    // Calculate zone stats
    final levelManager = LevelSystemManager();
    final zoneStats = levelManager.getZoneStats(completedZone);
    final zoneLevels = levelManager.getLevelsByZone(completedZone);
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ZoneCompletionScreen(
          completedZone: completedZone,
          nextZone: nextZone,
          coinsEarned: zoneStats['coins'] ?? 0,
          gemsEarned: zoneStats['gems'] ?? 0,
          levelsCompleted: zoneLevels.length,
        ),
      ),
    );
  }
  
  /// ✅ NEW: Navigate to world map without animation (for replays)
  void _navigateToWorldMapNoAnimation() {
    if (!mounted) return;
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const WorldMapScreen(
          shouldAnimateJet: false,
        ),
      ),
    );
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

          // 🆚 HUD: VS indicator for 1v1 story levels, otherwise objective indicator
          StoryModeHudOverlay(
            objectiveType: widget.level.objective.type,
            currentProgress: _objectiveTracker.currentProgress,
            targetProgress: widget.level.objective.target,
            isCompleted: _objectiveTracker.isCompleted,
            botScore: _objectiveTracker.botScore,
            botIsActive: _objectiveTracker.botIsActive,
            botName: widget.level.botBattle?.botName,
            botSkinId: widget.level.botBattle?.botJetSkin,
          ),

          // ✅ FIX: Removed old GameOverMenu overlay that was causing race condition
          // Story mode now uses ONLY _showStoryModeGameOverPopup() (LevelFailedScreen)
          // The old ValueListenableBuilder was triggering the endless mode GameOverMenu
          // even when victory was already detected, causing the "old game over screen" bug
        ],
      ),
    );
  }
  
  // ✅ FIX: DELETED _buildStoryModeGameOverMenu() method (~110 lines of dead code)
  // ✅ REFACTOR: Replaced _buildTopObjectiveIndicator() with reusable ObjectiveIndicator widget
  // This old method used the endless mode GameOverMenu widget.
  // Story mode now exclusively uses _showStoryModeGameOverPopup() which shows
  // the beautiful LevelFailedScreen for failures, and _onLevelCompleted() for victories.
  // Removing this eliminates the race condition where the old GameOverMenu
  // would appear on top of the victory animation.
  //
  // Also DELETED related methods that were only used by the old menu:
  // - _handleStoryModeRestart() - old menu's restart button
  // - _handleBuySingleHeart() - old menu's gem purchase continue  
  // - _handleGoToStore() - old menu's store navigation
  // - _shareScore() - old menu's share functionality
  // - _handleBackToMap() - old menu's main menu button (now handled by LevelFailedScreen)
  
  // 🎯 Removed _buildObjectiveTracker and _getObjectiveIcon - no longer displayed
  // (story mode uses top indicator only)
}

/// HUD overlay for story mode.
/// - For beatBot (1v1) levels: shows VSIndicator like playoff tournament
/// - For other objectives: shows the existing ObjectiveIndicator
class StoryModeHudOverlay extends StatelessWidget {
  final ObjectiveType objectiveType;
  final int currentProgress;
  final int targetProgress;
  final bool isCompleted;
  final int? botScore;
  final bool botIsActive;
  final String? botName;
  final String? botSkinId;

  const StoryModeHudOverlay({
    super.key,
    required this.objectiveType,
    required this.currentProgress,
    required this.targetProgress,
    required this.isCompleted,
    this.botScore,
    this.botIsActive = true,
    this.botName,
    this.botSkinId,
  });

  bool get _isBeatBot => objectiveType == ObjectiveType.beatBot;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            if (_isBeatBot && botName != null && botSkinId != null)
              ...[
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: VSIndicator(
                      opponentSkinId: botSkinId!,
                      opponentName: botName!,
                      playerScore: currentProgress,
                      opponentScore: botScore ?? 0,
                      opponentIsActive: botIsActive,
                      showScores: false, // Use floating counter instead of inline scores
                    ),
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 72,
                  left: 16,
                  child: ScoreCounterHUD(score: currentProgress),
                ),
              ]
            else
              Positioned(
                top: 40,
                left: 16,
                child: ObjectiveIndicator(
                  objectiveType: objectiveType,
                  currentProgress: currentProgress,
                  targetProgress: targetProgress,
                  isCompleted: isCompleted,
                  botScore: _isBeatBot ? botScore : null,
                  botIsActive: botIsActive,
                ),
              ),

            // ❤️ Top-right hearts display (consistent InGameHeartsDisplay widget)
            Positioned(
              top: 40,
              right: 16,
              child: InGameHeartsDisplay(
                showBackground: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

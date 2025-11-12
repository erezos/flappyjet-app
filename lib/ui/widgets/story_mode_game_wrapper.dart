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
import '../screens/level_complete_screen.dart';
import '../screens/level_failed_screen.dart';
import '../screens/world_map_screen.dart';
import '../screens/zone_completion_screen.dart'; // 🏆 Zone celebration
import '../widgets/game_over_menu.dart';
import '../../core/debug_logger.dart';
import '../../core/events/event_bus.dart';
import '../../core/repositories/user_stats_repository.dart';
import '../../core/database/local_database_manager.dart';

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

    // Phase 3: Get EventBus and UserStatsRepository for game_ended events
    final eventBus = EventBus();
    final database = LocalDatabaseManager();
    final userStats = UserStatsRepository(database);

    // Get LivesManager to track hearts
    final livesManager = LivesManager();

    // Check if this is first attempt (check if level was already attempted)
    final levelManager = LevelSystemManager();
    final isFirstAttempt = !levelManager.isLevelCompleted(widget.level.id);
    final attemptNumber = isFirstAttempt ? 1 : 2; // 1 for first, 2+ for retries (we don't track exact count yet)

    // 🔥 Mark this level as attempted (for first-attempt boss logic)
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
      'is_first_attempt': isFirstAttempt,
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
    );

    // Listen to game state changes (use game's GameStateManager, not our own)
    _game.gameStateManager.addListener(_onGameStateChanged);

    // 🎯 AUTO-START: Story mode should start immediately (no "tap to play")
    // Wait for game to load, then auto-start (initial jump handled by FlappyGame)
    Future.delayed(const Duration(milliseconds: 800), () async {
      if (mounted) {
        safePrint('🎯 Auto-starting story mode game...');
        
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
        // Only log every second to avoid spam
        if (DateTime.now().millisecond < 200) {
          safePrint('🎯 TIMER TICK: elapsedGameTimeMs = $elapsedGameTimeMs');
        }
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

  void _onGameOver() {
    if (_levelEnded) return;

    safePrint('🎮 Game over in story mode');

    // Stop update timer
    _updateTimer?.cancel();
    
    // ⏱️ CRITICAL FIX: Pause game time IMMEDIATELY when game over screen appears
    // This prevents the timer from running while the player views the game over menu
    _game.gameStateManager.pauseGameTime();
    safePrint('⏸️ STORY MODE: Game time paused on game over (before ad)');

    // Check if objective was completed before game over
    final objectiveCompleted = _objectiveTracker.checkFinalCompletion();

    if (objectiveCompleted) {
      _onLevelCompleted();
    } else {
      // ❌ Objective not completed - navigate DIRECTLY to beautiful game over popup
      // Skip the GameOverMenu entirely for a cleaner, more engaging experience
      safePrint('🎮 ❌ Objective not completed. Showing story mode game over popup.');
      
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
    
    gameEventsTracker.onGameEnd(
      finalScore: finalScore,
      survivalTimeMs: elapsedGameTimeMs.toInt(),
      coinsEarned: 0,
      usedContinue: usedContinue,
      cause: 'story_level_failed',
    );
    safePrint('🎯 Story mode: Mission progress updated (level failed)');
    
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
                    
                    // ✅ FIX: Defer popup closing until after current frame completes
                    // This prevents "Navigator is locked" errors when called during animations
                    if (mounted) {
                      SchedulerBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          Navigator.of(context).pop();
                        }
                      });
                    }
                    
                    // Continue game
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
                  
                  // ✅ FIX: Defer popup closing until after current frame completes
                  // This prevents "Navigator is locked" errors when called during animations
                  if (mounted) {
                    SchedulerBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        Navigator.of(context).pop();
                      }
                    });
                  }
                  
                  // Continue game
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
    _levelEnded = true;

    safePrint('🎮 ✅ Level ${widget.level.id} completed!');

    // 🎵 STOP STORY MODE MUSIC: Stop level music before navigating away
    try {
      await _game.audioManager.stopMusic();
      safePrint('🎵 Story mode music stopped on level completion');
    } catch (e) {
      safePrint('⚠️ Failed to stop story mode music: $e');
    }

    // 🔥 CRITICAL FIX: Sync LivesManager with in-game heart count
    // The game's _gameStateManager.lives reflects the actual hearts remaining after crashes
    final livesManager = LivesManager();
    final actualHeartsRemaining = _game.gameStateManager.lives;
    await livesManager.setLives(actualHeartsRemaining);
    safePrint('💖 Story Mode: Level completed with ${actualHeartsRemaining} hearts remaining (synced to LivesManager)');
    
    // Hearts are NOT refilled - they persist across levels (Option 2)
    // Hearts regenerate naturally over time via LivesManager

    // Calculate time taken (excluding ad pauses)
    final elapsedGameTimeMs = _game.gameStateManager.getElapsedGameTime();
    final timeTaken = (elapsedGameTimeMs / 1000).round();
    
    // 🎯 CRITICAL: Track story mode completion for missions/achievements
    // Use objective progress as "score" for mission tracking
    final gameEventsTracker = GameEventsTracker();
    final finalScore = _objectiveTracker.currentProgress;
    final usedContinue = _game.gameStateManager.continuesUsedThisRun > 0;
    
    await gameEventsTracker.onGameEnd(
      finalScore: finalScore,
      survivalTimeMs: elapsedGameTimeMs.toInt(),
      coinsEarned: 0, // Story mode rewards handled separately
      usedContinue: usedContinue,
      cause: 'story_level_completed',
    );
    safePrint('🎯 Story mode: Mission/achievement progress updated');
    
    // 🏅 Check story mode achievements
    final achievementsManager = AchievementsManager(); // Use singleton
    final levelManager = LevelSystemManager();
    
    // Calculate total completed levels (count all completed levels in level manager)
    int totalCompleted = 0;
    for (int i = 1; i <= 100; i++) { // Check up to 100 levels (adjust as needed)
      if (levelManager.isLevelCompleted(i)) {
        totalCompleted++;
      }
    }
    
    // Check if zone is completed (current level is the last in zone)
    final zoneCompleted = levelManager.isZoneCompleted(widget.level.zone) ? widget.level.zone : 0;
    final wasFlawless = _game.gameStateManager.continuesUsedThisRun == 0;
    
    await achievementsManager.checkStoryModeAchievements(
      levelCompleted: true,
      totalLevelsCompleted: totalCompleted,
      zoneCompleted: zoneCompleted,
      wasFlawless: wasFlawless,
      objectiveType: widget.level.objective.type.toString(),
      timeTaken: timeTaken,
    );
    safePrint('🏅 Story mode achievements checked');

    // ✅ CRITICAL FIX: Check replay status BEFORE showing dialog
    // This must be done BEFORE rewards are granted (which marks level as complete)
    // (Reusing levelManager from above - already declared at line 441)
    final isReplay = levelManager.isLevelReplay(widget.level.id);
    safePrint('🎉 Level Complete Screen: isReplay = $isReplay (cached BEFORE dialog)');
    
    // ✅ CRITICAL FIX: Pause game engine before showing popup
    // This prevents crashes/collisions from happening while popup is visible
    _game.pauseEngine();
    safePrint('⏸️ Game paused - showing level complete popup');

    // ✅ NEW FLOW: Show popup instead of pushing new screen
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => LevelCompleteScreen(
          level: widget.level,
          objectiveAchieved: _objectiveTracker.currentProgress,
          timeTaken: timeTaken,
          continuesUsed: _game.gameStateManager.continuesUsedThisRun,
          onContinue: () {
            // Close the popup
            Navigator.of(context).pop();
            
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
            
            // Note: No need to resumeEngine() - we're navigating away and game will be disposed
          },
        ),
      );
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

          // 🎯 Top-left objective indicator (only UI element for objectives)
          Positioned(
            top: 40,
            left: 16,
            child: _buildTopObjectiveIndicator(),
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
  
  /// 🎯 Beautiful top-left objective indicator (replaces score display in story mode)
  Widget _buildTopObjectiveIndicator() {
    final objective = widget.level.objective;
    final isCompleted = _objectiveTracker.isCompleted;
    
    // Get color scheme based on objective type
    final Color primaryColor;
    final Color secondaryColor;
    final IconData icon;
    
    switch (objective.type) {
      case ObjectiveType.passObstacles:
        primaryColor = Colors.amber;
        secondaryColor = Colors.orange;
        icon = Icons.flag_rounded;
        break;
      case ObjectiveType.surviveTime:
        primaryColor = Colors.cyan;
        secondaryColor = Colors.blue;
        icon = Icons.timer_outlined;
        break;
      case ObjectiveType.beatBot:
        primaryColor = Colors.red;
        secondaryColor = Colors.deepOrange;
        icon = Icons.emoji_events_rounded;
        break;
    }
    
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.7 + (value * 0.3), // Animate from 70% to 100%
          child: Opacity(
            opacity: value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withValues(alpha: 0.9),
                    secondaryColor.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.5),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated icon
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 1200),
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    builder: (context, rotateValue, child) {
                      return Transform.rotate(
                        angle: isCompleted ? 0 : (rotateValue * 6.28), // Full rotation
                        child: Icon(
                          isCompleted ? Icons.check_circle_rounded : icon,
                          color: Colors.white,
                          size: 28,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  // Progress text
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getObjectiveTypeLabel(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getObjectiveProgress(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  String _getObjectiveTypeLabel() {
    switch (widget.level.objective.type) {
      case ObjectiveType.passObstacles:
        return 'OBSTACLES';
      case ObjectiveType.surviveTime:
        return 'TIME';
      case ObjectiveType.beatBot:
        return 'VS BATTLE';
    }
  }
  
  String _getObjectiveProgress() {
    final objective = widget.level.objective;
    switch (objective.type) {
      case ObjectiveType.passObstacles:
        return '${_objectiveTracker.currentProgress}/${objective.target}';
      case ObjectiveType.surviveTime:
        final elapsed = _objectiveTracker.currentProgress;
        final remaining = objective.target - elapsed;
        return remaining > 0 ? '${remaining}s' : 'DONE!';
      case ObjectiveType.beatBot:
        final playerScore = _objectiveTracker.currentProgress;
        // Bot score is tracked internally by the tracker
        return 'You: $playerScore';
    }
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
                
                // ⏱️ FIX: Pause game time tracking to exclude ad duration
                _game.gameStateManager.pauseGameTime();
              },
              onAdEnd: () {
                // 🎯 CRITICAL: Resume Flame game engine when ad ends
                _game.resumeFromAd();
                safePrint('▶️ STORY MODE: Game engine resumed after ad');
                
                // ⏱️ FIX: Resume game time tracking after ad dismissal
                _game.gameStateManager.resumeGameTime();
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
                
                // 🎯 CRITICAL FIX: Restart update timer for time-based objectives after continue
                if (widget.level.objective.type == ObjectiveType.surviveTime || 
                    widget.level.objective.type == ObjectiveType.beatBot) {
                  _updateTimer?.cancel();
                  _startUpdateTimer();
                  safePrint('🎯 TIMER: Restarted update timer after continue');
                }
                
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
    
    // ⏱️ CRITICAL FIX: Resume game time if it was paused (player restart without continuing)
    // This prevents the pause state from persisting into the restart
    _game.gameStateManager.resumeGameTime();
    safePrint('▶️ STORY MODE: Game time resumed (player restarting level)');
    
    _game.resetGame();
  }
  
  void _handleBackToMap() {
    if (_levelEnded) return;
    _levelEnded = true;

    safePrint('🎯 STORY MODE: Back to map requested');
    
    // ⏱️ CRITICAL FIX: Resume game time if it was paused (player quit without continuing)
    // This prevents the pause state from persisting into the next level attempt
    _game.gameStateManager.resumeGameTime();
    safePrint('▶️ STORY MODE: Game time resumed (player quit to map)');
    
    // 🎵 STOP STORY MODE MUSIC: Stop level music before navigating away
    _game.audioManager.stopMusic().then((_) {
      safePrint('🎵 Story mode music stopped on back to map');
    }).catchError((e) {
      safePrint('⚠️ Failed to stop story mode music: $e');
    });
    
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
      
      // Fire level_failed event for analytics
      final eventBus = EventBus();
      eventBus.fire('level_failed', {
        'level_id': widget.level.id,
        'zone_id': widget.level.zone,
        'level_name': widget.level.name,
        'score': _objectiveTracker.currentProgress,
        'objective_target': widget.level.objective.target,
        'objective_type': widget.level.objective.type.toString(),
        'cause_of_death': 'gave_up', // Player chose to quit
        'time_survived_seconds': _game.gameStateManager.getElapsedGameTime() ~/ 1000,
        'hearts_remaining': LivesManager().currentLives,
        'continues_used': _game.gameStateManager.continuesUsedThisRun,
      });
      
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
      
      // 🎯 CRITICAL FIX: Restart update timer for time-based objectives after continue
      if (widget.level.objective.type == ObjectiveType.surviveTime || 
          widget.level.objective.type == ObjectiveType.beatBot) {
        _updateTimer?.cancel();
        _startUpdateTimer();
        safePrint('🎯 TIMER: Restarted update timer after gem continue');
      }
      
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
  
  // 🎯 Removed _buildObjectiveTracker and _getObjectiveIcon - no longer displayed
  // (story mode uses top indicator only)
}

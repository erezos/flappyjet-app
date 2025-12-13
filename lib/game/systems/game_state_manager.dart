import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import '../../core/debug_logger.dart';
import '../../core/events/event_bus.dart';
import '../../core/analytics/conversion_events_manager.dart';
import '../core/game_config.dart';
import '../core/game_themes.dart';
import '../../core/repositories/user_stats_repository.dart';

/// State tracking for game end conditions (victory vs game over)
/// Used to prevent race conditions where both victory and death trigger simultaneously
enum GameEndState {
  /// Normal gameplay - no end condition triggered yet
  playing,
  
  /// Victory has been triggered (objective completed)
  /// Takes priority over gameOver if both happen on same frame
  victoryTriggered,
  
  /// Game over has been triggered (out of lives)
  gameOverTriggered,
  
  /// State is locked - no further transitions allowed
  /// Prevents duplicate popups or conflicting states
  locked,
}

/// Manages the core game state and transitions
/// Separated from FlappyGame for better testability and maintainability
/// 
/// ✅ MIGRATED: Now uses UserStatsRepository for persistence (no SharedPreferences/backend sync)
/// ✅ PHASE 3: Fires game_ended events to EventBus for leaderboard sync
/// ✅ EDGE CASE FIX: Added GameEndState for victory priority + state lock
class GameStateManager extends ChangeNotifier {
  final UserStatsRepository? _userStats;
  final EventBus? _eventBus;
  // Game state
  bool _isWaitingToStart = true;
  bool _isGameOver = false;
  GameTheme _currentTheme = GameThemes.skyRookie;
  
  // Game data
  int _score = 0;
  int _bestScore = 0;
  int _bestStreak = 0;
  int _lives = GameConfig.maxLives;
  int _gameStartTime = 0;
  bool _isInvulnerable = false;
  
  // Pause tracking for accurate time measurement (e.g., during ads)
  int _pauseStartTime = 0;
  int _totalPauseDuration = 0;
  
  // Continue tracking per run
  int _continuesUsedThisRun = 0;
  static const int _maxContinuesPerRun = 5;
  
  // Currency tracking per run
  int _coinsCollectedThisRun = 0;
  int _gemsCollectedThisRun = 0;
  
  // Death tracking
  String _causeOfDeath = 'unknown';
  
  // Theme notification state
  double _themeNotificationTime = 0.0;
  bool _showingThemeNotification = false;
  
  // ✅ EDGE CASE FIX: Game end state tracking
  // Prevents race condition where victory + death happen on same frame
  GameEndState _gameEndState = GameEndState.playing;
  
  // 🏆 Track if victory was triggered (persists after lock)
  // This is needed because once state is 'locked', we can't tell if it was victory or game over
  bool _victoryWasTriggered = false;
  
  // Game over notifier for UI
  final ValueNotifier<bool> gameOverNotifier = ValueNotifier<bool>(false);

  /// Constructor - optionally accepts UserStatsRepository for persistence and EventBus for events
  GameStateManager({
    UserStatsRepository? userStats,
    EventBus? eventBus,
  })  : _userStats = userStats,
        _eventBus = eventBus {
    // Load persisted best score/streak from repository
    if (_userStats != null) {
      _userStats.getUserStats().then((stats) {
        _bestScore = stats.highScore;
        _bestStreak = stats.bestStreak;
        safePrint('📊 Loaded persisted data from SQLite - Best: $_bestScore, Streak: $_bestStreak');
      }).catchError((e) {
        safePrint('⚠️ Failed to load persisted data from repository: $e');
      });
    }
  }

  // PUBLIC GETTERS for UI integration
  bool get isWaitingToStart => _isWaitingToStart;
  bool get isGameOver => _isGameOver;
  bool get isPlaying => !_isWaitingToStart && !_isGameOver;
  int get score => _score;
  int get bestScore => _bestScore;
  int get bestStreak => _bestStreak;
  int get lives => _lives;
  GameTheme get currentTheme => _currentTheme;
  bool get isInvulnerable => _isInvulnerable;
  int get continuesUsedThisRun => _continuesUsedThisRun;
  int get gameStartTime => _gameStartTime;
  double get themeNotificationTime => _themeNotificationTime;
  bool get showingThemeNotification => _showingThemeNotification;
  int get coinsCollectedThisRun => _coinsCollectedThisRun;
  int get gemsCollectedThisRun => _gemsCollectedThisRun;
  String get causeOfDeath => _causeOfDeath;

  // Continue system getters
  bool get canContinueWithAd => _continuesUsedThisRun < _maxContinuesPerRun;
  int get continuesRemaining => _maxContinuesPerRun - _continuesUsedThisRun;
  
  // ✅ EDGE CASE FIX: Game end state getters
  GameEndState get gameEndState => _gameEndState;
  bool get isVictoryTriggered => _gameEndState == GameEndState.victoryTriggered;
  bool get isGameOverTriggered => _gameEndState == GameEndState.gameOverTriggered;
  bool get isEndStateLocked => _gameEndState == GameEndState.locked;
  
  // 🏆 Victory priority flag - persists after lock to indicate victory "won"
  bool get victoryWasTriggered => _victoryWasTriggered;
  
  /// Attempt to set victory state (objective completed)
  /// Returns true if successful, false if another end state was already triggered
  /// Victory has PRIORITY over game over (player earned it!)
  bool trySetVictory() {
    if (_gameEndState == GameEndState.locked) {
      safePrint('🎮 trySetVictory: DENIED - state is locked');
      return false;
    }
    
    // Victory priority: allow even if gameOver was triggered
    // This handles the edge case where player passes last obstacle AND dies on same frame
    if (_gameEndState == GameEndState.gameOverTriggered) {
      safePrint('🎮 trySetVictory: VICTORY PRIORITY - overriding game over!');
    }
    
    _gameEndState = GameEndState.victoryTriggered;
    _victoryWasTriggered = true; // 🏆 Mark victory as the winner (persists after lock)
    safePrint('🎮 trySetVictory: SUCCESS - victory state set');
    return true;
  }
  
  /// Attempt to set game over state (out of lives)
  /// Returns true if successful, false if victory was already triggered
  bool trySetGameOver() {
    if (_gameEndState == GameEndState.locked) {
      safePrint('🎮 trySetGameOver: DENIED - state is locked');
      return false;
    }
    
    // Do NOT override victory - player earned it!
    if (_gameEndState == GameEndState.victoryTriggered) {
      safePrint('🎮 trySetGameOver: DENIED - victory already triggered (victory priority)');
      return false;
    }
    
    _gameEndState = GameEndState.gameOverTriggered;
    safePrint('🎮 trySetGameOver: SUCCESS - game over state set');
    return true;
  }
  
  /// Lock the game end state to prevent further changes
  /// Call this after showing the final popup
  void lockEndState() {
    _gameEndState = GameEndState.locked;
    safePrint('🎮 lockEndState: State locked');
  }
  
  /// Reset game end state for new game/level
  void resetEndState() {
    _gameEndState = GameEndState.playing;
    _victoryWasTriggered = false; // 🏆 Clear victory flag for new game/level
    safePrint('🎮 resetEndState: State reset to playing');
  }

  /// Start the game when user taps - transition from waiting to playing
  void startGame() {
    if (!_isWaitingToStart) return; // Already started

    safePrint('🎮 GAME STARTED! Transitioning from waiting to playing state');

    // Change game state
    _isWaitingToStart = false;
    _isGameOver = false;
    _gameStartTime = DateTime.now().millisecondsSinceEpoch;

    // Reset counters for new run
    _continuesUsedThisRun = 0;
    _coinsCollectedThisRun = 0;
    _gemsCollectedThisRun = 0;
    _causeOfDeath = 'unknown';
    
    // ✅ EDGE CASE FIX: Reset end state for new run
    resetEndState();
    
    // 🎯 Track game played for conversion events (non-blocking)
    ConversionEventsManager().onGamePlayed();


    safePrint('🚀 Game is now in playing state - tap to make the jet jump!');
    safePrint('🎯 GAME START TIME SET: $_gameStartTime (should be non-zero!)');
  }

  /// Handle collision - reduce lives and check for game over
  bool handleCollision() {
    _lives--;
    
    if (_lives > 0) {
      // Continue with invulnerability
      _isInvulnerable = true;
      safePrint('💖 Life lost! Lives remaining: $_lives');
      return false; // Not game over
    } else {
      // Game over
      setGameOver();
      return true; // Game over
    }
  }

  /// Set game over state (public so FlappyGame can trigger it)
  /// [causeOfDeath] - Reason for game over ('obstacle_collision', 'quit', 'out_of_bounds', etc.)
  /// 
  /// NOTE: This method ONLY sets the game over state. The game_ended event
  /// should be fired by FlappyGame._gameOver() to maintain single source of truth.
  void setGameOver({String causeOfDeath = 'unknown'}) {
    // 🏆 CRITICAL FIX: Check victory priority BEFORE setting _isGameOver
    // If victory was triggered, don't mark as game over at all
    // This prevents the 0-hearts issue when player wins + dies on same frame
    if (_victoryWasTriggered) {
      safePrint('🎮 setGameOver BLOCKED - victory was already triggered');
      return; // Don't set _isGameOver, don't schedule callback
    }
    
    _isGameOver = true;
    _causeOfDeath = causeOfDeath;
    
    // 🔥 FIX: Defer ValueNotifier update to avoid setState() during build
    // This can be called during FlappyGame.update() which is part of the build cycle
    SchedulerBinding.instance.addPostFrameCallback((_) {
      // Additional safety check (in case state changed between call and callback)
      if (_victoryWasTriggered) {
        safePrint('🎮 gameOverNotifier NOT set - victory was triggered');
        return;
      }
      gameOverNotifier.value = true; // Notify UI after build completes
    });
    
    safePrint('💀 Game Over! Final Score: $_score in ${_currentTheme.displayName} theme');
  }

  /// Add extra life (called from rewarded ad)
  void addExtraLife() {
    if (_isGameOver) {
      _lives = 1; // Restore one life
      _isGameOver = false;
      _isInvulnerable = true;
      
      // 🔥 FIX: Defer ValueNotifier update to avoid setState() during build
      SchedulerBinding.instance.addPostFrameCallback((_) {
        gameOverNotifier.value = false;
      });
      
      safePrint('💰 Extra life granted via rewarded ad! Lives: $_lives');
    }
  }

  /// Continue game after watching ad
  /// Continue game after death (via ad or purchase)
  /// [continueType] - How the continue was obtained ('ad_watch', 'coin_purchase', 'gem_purchase')
  /// [costCoins] - Coins spent (0 if ad or gems)
  /// [costGems] - Gems spent (0 if ad or coins)
  void continueGame({
    String continueType = 'ad_watch',
    int costCoins = 0,
    int costGems = 0,
  }) {
    // Track continue usage
    _continuesUsedThisRun++;

    _isGameOver = false;
    
    // 🔥 FIX: Defer ValueNotifier update to avoid setState() during build
    SchedulerBinding.instance.addPostFrameCallback((_) {
      gameOverNotifier.value = false;
    });
    
    // ✅ CRITICAL FIX: Resume playing state (not waiting!)
    _isWaitingToStart = false;
    
    // ✅ CRITICAL FIX: Reset end state to allow victory/game-over after continue
    // Without this, the state stays "locked" and victory can't be triggered even if bot crashes
    resetEndState();
    safePrint('🔄 continueGame: End state reset to playing');

    // Grant exactly +1 life (up to max). If at 0, restore to 1.
    final int newLives = (_lives <= 0)
        ? 1
        : (_lives + GameConfig.livesPerRewardedAd);
    _lives = newLives.clamp(1, GameConfig.maxLives);

    // Enable timed invulnerability
    _isInvulnerable = true;
    
    // CRITICAL FIX: Set up timer to disable invulnerability
    Future.delayed(
      Duration(
        milliseconds: (GameConfig.invulnerabilityDuration * 1000).toInt(),
      ),
      () {
        _isInvulnerable = false;
        safePrint('🛡️ Invulnerability ended after continue - collision detection restored');
      },
    );

    // 🎯 STORY MODE TIME FIX: Adjust game start time to exclude game-over-to-continue duration
    // When user crashes and watches an ad, the time spent on game over screen should not count
    // We do this by shifting the start time forward by (actual elapsed - playing time)
    if (_gameStartTime > 0) {
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final actualElapsedBeforeContinue = getElapsedGameTime(); // This is the REAL playing time
      final newStartTime = currentTime - actualElapsedBeforeContinue;
      
      safePrint('⏱️ TIME FIX: Adjusting game start time for continue');
      safePrint('⏱️ Old start time: $_gameStartTime');
      safePrint('⏱️ New start time: $newStartTime (shifted by ${newStartTime - _gameStartTime}ms)');
      safePrint('⏱️ Preserved playing time: ${actualElapsedBeforeContinue}ms');
      
      _gameStartTime = newStartTime;
      // Reset pause tracking since we've already accounted for it in the new start time
      _totalPauseDuration = 0;
      _pauseStartTime = 0;
    }

    // Fire continue_used event for analytics
    _eventBus?.fire('continue_used', {
      'game_mode': 'endless', // TODO: Get actual game mode from context
      'score_at_death': score,
      'continue_type': continueType,
      'cost_coins': costCoins,
      'cost_gems': costGems,
      'lives_restored': 1,
      'continues_used_this_run': _continuesUsedThisRun,
    });

    safePrint(
      '🎬 Game continued after ad - back in action! Lives=$_lives, continues used: $_continuesUsedThisRun/$_maxContinuesPerRun',
    );
  }

  /// Reset game state
  void resetGame() {
    _isWaitingToStart = true;
    _isGameOver = false;
    
    // 🔥 FIX: Defer ValueNotifier update to avoid setState() during build
    SchedulerBinding.instance.addPostFrameCallback((_) {
      gameOverNotifier.value = false;
    });
    
    _score = 0;
    _isInvulnerable = false;
    _currentTheme = GameThemes.skyRookie;
    _continuesUsedThisRun = 0;
    _pauseStartTime = 0;
    _totalPauseDuration = 0;
    // _timeSinceLastObstacle is managed by ObstacleManager
    _themeNotificationTime = 0.0;
    _showingThemeNotification = false;
    
    // ✅ EDGE CASE FIX: Reset end state
    resetEndState();
    
    safePrint('🔄 Game reset to starting state');
  }

  /// Mark the start of a pause (e.g., for ad display)
  void pauseGameTime() {
    if (_pauseStartTime == 0) { // Only pause if not already paused
      _pauseStartTime = DateTime.now().millisecondsSinceEpoch;
      safePrint('⏸️ Game time paused at $_pauseStartTime');
    }
  }

  /// Resume game time after a pause (e.g., after ad dismissal)
  void resumeGameTime() {
    if (_pauseStartTime > 0) {
      final pauseDuration = DateTime.now().millisecondsSinceEpoch - _pauseStartTime;
      _totalPauseDuration += pauseDuration;
      safePrint('▶️ Game time resumed. Pause duration: ${pauseDuration}ms, Total pause: ${_totalPauseDuration}ms');
      _pauseStartTime = 0;
    }
  }

  /// Get elapsed game time (excluding pause durations like ads)
  int getElapsedGameTime() {
    if (_gameStartTime == 0) return 0;
    
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final totalElapsed = currentTime - _gameStartTime;
    
    // Subtract total pause duration to get actual playing time
    final activePauseDuration = _pauseStartTime > 0 
        ? (currentTime - _pauseStartTime) 
        : 0;
    
    final actualGameTime = totalElapsed - _totalPauseDuration - activePauseDuration;
    
    return actualGameTime;
  }

  /// Update score and check for achievements
  void updateScore(int newScore) {
    _score = newScore;
    
    // Check for theme transitions
    final newTheme = GameThemes.getThemeForScore(_score);
    if (newTheme != _currentTheme) {
      _currentTheme = newTheme;
      // Theme transition log removed - too verbose during gameplay
    }
  }

  /// Set lives count
  void setLives(int lives) {
    _lives = lives;
  }

  /// Set invulnerability state
  void setInvulnerable(bool invulnerable) {
    _isInvulnerable = invulnerable;
  }

  /// Update theme notification timer
  void updateThemeNotificationTimer(double dt) {
    if (_showingThemeNotification) {
      _themeNotificationTime += dt;
      if (_themeNotificationTime >= GameConfig.themeTransitionDuration) {
        _showingThemeNotification = false;
        _themeNotificationTime = 0.0;
      }
    }
  }

  /// Set theme notification state
  void setShowingThemeNotification(bool showing) {
    _showingThemeNotification = showing;
  }

  /// Save best score (async, non-blocking)
  /// ✅ MIGRATED: Now uses UserStatsRepository instead of SharedPreferences
  Future<void> saveBestScore(int score) async {
    if (score > _bestScore) {
      _bestScore = score;
      safePrint('🏆 New best score: $_bestScore');
      
      // Save to SQLite via UserStatsRepository
      if (_userStats != null) {
        try {
          final isNewRecord = await _userStats.updateHighScore(score);
          if (isNewRecord) {
            safePrint('🏆 ✅ Best score saved to SQLite: $score');
          }
        } catch (e) {
          safePrint('🏆 ❌ Failed to save best score: $e');
        }
      }
      
      // Notify UI listeners
      notifyListeners();
    }
  }

  /// Save best streak (only for clean runs) (async, non-blocking)
  /// ✅ MIGRATED: Now uses UserStatsRepository instead of SharedPreferences
  Future<void> saveBestStreak(int score) async {
    if (_continuesUsedThisRun == 0 && score > _bestStreak) {
      _bestStreak = score;
      safePrint('🏆 New best streak (clean run): $_bestStreak');
      
      // Save to SQLite via UserStatsRepository
      if (_userStats != null) {
        try {
          final isNewRecord = await _userStats.updateBestStreak(score);
          if (isNewRecord) {
            safePrint('🏆 ✅ Best streak saved to SQLite: $score');
          }
        } catch (e) {
          safePrint('🏆 ❌ Failed to save best streak: $e');
        }
      }
      
      // Notify UI listeners
      notifyListeners();
    } else if (_continuesUsedThisRun > 0) {
      safePrint(
        '🔄 Score $score not counted as streak (used $_continuesUsedThisRun continues)',
      );
    }
  }

  /// 🔄 SET: Best score (for restoration from repository)
  void setBestScore(int score) {
    _bestScore = score;
    safePrint('🔄 🏆 Best score set from restoration: $score');
    notifyListeners();
  }

  /// 🔄 SET: Best streak (for restoration from repository)
  void setBestStreak(int score) {
    _bestStreak = score;
    safePrint('🔄 🏆 Best streak set from restoration: $score');
    notifyListeners();
  }

  /// 📊 Track currency collected during this run (for analytics)
  void addCoinCollected() {
    _coinsCollectedThisRun++;
  }
  
  /// 📊 Track multiple coins collected during this run (for bonuses)
  void addCoinsCollectedThisRun(int amount) {
    _coinsCollectedThisRun += amount;
  }

  /// 📊 Track currency collected during this run (for analytics)
  void addGemCollected() {
    _gemsCollectedThisRun++;
  }
  
  /// 📊 Track multiple gems collected during this run (for bonuses)
  void addGemsCollectedThisRun(int amount) {
    _gemsCollectedThisRun += amount;
  }

  /// Get comprehensive game state for debugging/analytics
  Map<String, dynamic> getGameState() {
    return {
      'game_state': {
        'score': _score,
        'lives': _lives,
        'theme': _currentTheme.displayName,
        'is_playing': isPlaying,
        'is_waiting': _isWaitingToStart,
        'is_game_over': _isGameOver,
        'is_invulnerable': _isInvulnerable,
        'continues_used': _continuesUsedThisRun,
        'can_continue': canContinueWithAd,
      },
      'persistence': {
        'best_score': _bestScore,
        'best_streak': _bestStreak,
      },
    };
  }
}
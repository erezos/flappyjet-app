import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/debug_logger.dart';
import '../core/game_config.dart';
import '../core/game_themes.dart';
import '../../core/data/game_data_manager.dart';

/// Manages the core game state and transitions
/// Separated from FlappyGame for better testability and maintainability
class GameStateManager extends ChangeNotifier {
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
  
  // Continue tracking per run
  int _continuesUsedThisRun = 0;
  static const int _maxContinuesPerRun = 5;
  
  // Theme notification state
  double _themeNotificationTime = 0.0;
  bool _showingThemeNotification = false;
  
  // Game over notifier for UI
  final ValueNotifier<bool> gameOverNotifier = ValueNotifier<bool>(false);

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

  // Continue system getters
  bool get canContinueWithAd => _continuesUsedThisRun < _maxContinuesPerRun;
  int get continuesRemaining => _maxContinuesPerRun - _continuesUsedThisRun;

  /// Start the game when user taps - transition from waiting to playing
  void startGame() {
    if (!_isWaitingToStart) return; // Already started

    safePrint('🎮 GAME STARTED! Transitioning from waiting to playing state');

    // Change game state
    _isWaitingToStart = false;
    _isGameOver = false;
    _gameStartTime = DateTime.now().millisecondsSinceEpoch;

    // Reset continue counter for new run
    _continuesUsedThisRun = 0;

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
  void setGameOver() {
    _isGameOver = true;
    gameOverNotifier.value = true; // Notify UI
    safePrint('💀 Game Over! Final Score: $_score in ${_currentTheme.displayName} theme');
  }

  /// Add extra life (called from rewarded ad)
  void addExtraLife() {
    if (_isGameOver) {
      _lives = 1; // Restore one life
      _isGameOver = false;
      _isInvulnerable = true;
      gameOverNotifier.value = false;
      safePrint('💰 Extra life granted via rewarded ad! Lives: $_lives');
    }
  }

  /// Continue game after watching ad
  void continueGame() {
    // Track continue usage
    _continuesUsedThisRun++;

    _isGameOver = false;
    gameOverNotifier.value = false;

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

    safePrint(
      '🎬 Game continued after ad - back in action! Lives=$_lives, continues used: $_continuesUsedThisRun/$_maxContinuesPerRun',
    );
  }

  /// Reset game state
  void resetGame() {
    _isWaitingToStart = true;
    _isGameOver = false;
    gameOverNotifier.value = false;
    _score = 0;
    _isInvulnerable = false;
    _currentTheme = GameThemes.skyRookie;
    _continuesUsedThisRun = 0;
    // _timeSinceLastObstacle is managed by ObstacleManager
    _themeNotificationTime = 0.0;
    _showingThemeNotification = false;
    safePrint('🔄 Game reset to starting state');
  }

  /// Update score and check for achievements
  void updateScore(int newScore) {
    _score = newScore;
    
    // Check for theme transitions
    final newTheme = GameThemes.getThemeForScore(_score);
    if (newTheme != _currentTheme) {
      _currentTheme = newTheme;
      safePrint('🎭 Theme transition: ${_currentTheme.displayName}');
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

  /// Load persisted best score and streak from SharedPreferences
  Future<void> loadPersistedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _bestScore = prefs.getInt('best_score') ?? 0;
      _bestStreak = prefs.getInt('best_streak') ?? 0;
      safePrint('📊 Loaded persisted data - Best: $_bestScore, Streak: $_bestStreak');
    } catch (e) {
      safePrint('⚠️ Failed to load persisted data: $e');
      _bestScore = 0;
      _bestStreak = 0;
    }
  }

  /// Save best score and streak (async, non-blocking)
  Future<void> saveBestScore(int score) async {
    if (score > _bestScore) {
      _bestScore = score;
      safePrint('🏆 New best score: $_bestScore');
      
      // 🚀 ASYNC: Persist to SharedPreferences (non-blocking)
      _persistBestScoreAsync(score);
      
      // 🚀 ASYNC: Sync to backend via GameDataManager (non-blocking)
      _syncBestScoreToBackendAsync(score);
      
      // 🚀 NOTIFY: Update UI listeners
      notifyListeners();
    }
  }

  /// Save best streak (only for clean runs) (async, non-blocking)
  Future<void> saveBestStreak(int score) async {
    if (_continuesUsedThisRun == 0 && score > _bestStreak) {
      _bestStreak = score;
      safePrint('🏆 New best streak (clean run): $_bestStreak');
      
      // 🚀 ASYNC: Persist to SharedPreferences (non-blocking)
      _persistBestStreakAsync(score);
      
      // 🚀 ASYNC: Sync to backend via GameDataManager (non-blocking)
      _syncBestStreakToBackendAsync(score);
      
      // 🚀 NOTIFY: Update UI listeners
      notifyListeners();
    } else if (_continuesUsedThisRun > 0) {
      safePrint(
        '🔄 Score $score not counted as streak (used $_continuesUsedThisRun continues)',
      );
    }
  }

  /// 🚀 ASYNC: Persist best score to SharedPreferences (non-blocking)
  void _persistBestScoreAsync(int score) {
    Future.microtask(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('best_score', score);
        safePrint('🏆 ✅ Best score persisted: $score');
      } catch (e) {
        safePrint('🏆 ❌ Failed to persist best score: $e');
      }
    });
  }

  /// 🚀 ASYNC: Persist best streak to SharedPreferences (non-blocking)
  void _persistBestStreakAsync(int score) {
    Future.microtask(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('best_streak', score);
        safePrint('🏆 ✅ Best streak persisted: $score');
      } catch (e) {
        safePrint('🏆 ❌ Failed to persist best streak: $e');
      }
    });
  }

  /// 🚀 ASYNC: Sync best score to backend via GameDataManager (non-blocking)
  void _syncBestScoreToBackendAsync(int score) {
    Future.microtask(() async {
      try {
        final gameDataManager = GameDataManager();
        await gameDataManager.updatePlayerStats(bestScore: score);
        safePrint('🏆 ✅ Best score synced to backend: $score');
      } catch (e) {
        safePrint('🏆 ❌ Failed to sync best score to backend: $e');
      }
    });
  }

  /// 🚀 ASYNC: Sync best streak to backend via GameDataManager (non-blocking)
  void _syncBestStreakToBackendAsync(int score) {
    Future.microtask(() async {
      try {
        final gameDataManager = GameDataManager();
        await gameDataManager.updatePlayerStats(bestStreak: score);
        safePrint('🏆 ✅ Best streak synced to backend: $score');
      } catch (e) {
        safePrint('🏆 ❌ Failed to sync best streak to backend: $e');
      }
    });
  }

  /// 🔄 SET: Best score (for restoration from backend)
  void setBestScore(int score) {
    _bestScore = score;
    safePrint('🔄 🏆 Best score set from restoration: $score');
    notifyListeners();
  }

  /// 🔄 SET: Best streak (for restoration from backend)
  void setBestStreak(int score) {
    _bestStreak = score;
    safePrint('🔄 🏆 Best streak set from restoration: $score');
    notifyListeners();
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
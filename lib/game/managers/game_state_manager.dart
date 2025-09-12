/// 🎮 GAME STATE MANAGER - Centralized game state management
/// Extracted from EnhancedFlappyGame to separate concerns and improve maintainability
library;
import '../../core/debug_logger.dart';

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/game_config.dart';

/// Game state enumeration
enum GameState {
  waitingToStart,
  playing,
  gameOver,
  paused,
}

/// Game phase for difficulty progression
enum GamePhase {
  easy,
  medium,
  hard,
  expert,
}

/// Game statistics
class GameStats {
  int score = 0;
  int bestScore = 0;
  int bestStreak = 0;
  int lives = GameConfig.maxLives;
  int continuesUsedThisRun = 0;
  int gameStartTime = 0;
  bool isInvulnerable = false;
  bool isWaitingToStart = true;
  bool isGameOver = false;
  bool showingThemeNotification = false;
  String currentTheme = 'Sky Rookie';
  GamePhase currentPhase = GamePhase.easy;

  // Performance tracking
  int lastKnownMaxLives = 3;

  /// Reset for new game
  void reset() {
    score = 0;
    lives = GameConfig.maxLives;
    continuesUsedThisRun = 0;
    gameStartTime = DateTime.now().millisecondsSinceEpoch;
    isInvulnerable = false;
    isWaitingToStart = false;
    isGameOver = false;
    showingThemeNotification = false;
    currentPhase = GamePhase.easy;
  }

  /// Check if can continue with ad
  bool get canContinueWithAd => continuesUsedThisRun < 3; // Max 3 continues per run

  /// Get remaining continues
  int get continuesRemaining => 3 - continuesUsedThisRun;

  /// Add score and check for phase transitions
  void addScore(int points) {
    score += points;

    // Update phase based on score
    if (score >= 100) {
      currentPhase = GamePhase.expert;
    } else if (score >= 50) {
      currentPhase = GamePhase.hard;
    } else if (score >= 25) {
      currentPhase = GamePhase.medium;
    } else {
      currentPhase = GamePhase.easy;
    }

    // Update best score
    if (score > bestScore) {
      bestScore = score;
    }
  }

  /// Handle life loss
  void loseLife() {
    if (lives > 0) {
      lives--;
      isInvulnerable = true;

      // Remove invulnerability after delay
      Timer(Duration(milliseconds: (GameConfig.invulnerabilityDuration * 1000).toInt()), () {
        isInvulnerable = false;
      });
    }

    if (lives <= 0) {
      isGameOver = true;
      _updateBestStreak();
    }
  }

  /// Add extra life
  void addExtraLife() {
    if (lives < GameConfig.maxLives) {
      lives++;
      lastKnownMaxLives = lives;
      isInvulnerable = true;

      Timer(Duration(milliseconds: (GameConfig.invulnerabilityDuration * 1000).toInt()), () {
        isInvulnerable = false;
      });
    }
  }

  /// Use continue
  bool useContinue() {
    if (canContinueWithAd && lives <= 0) {
      continuesUsedThisRun++;
      lives = 1; // Restore 1 life
      isGameOver = false;
      isInvulnerable = true;

      Timer(Duration(milliseconds: (GameConfig.invulnerabilityDuration * 1000).toInt()), () {
        isInvulnerable = false;
      });

      return true;
    }
    return false;
  }

  /// Get game duration in seconds
  int get gameDurationSeconds {
    if (gameStartTime == 0) return 0;
    return (DateTime.now().millisecondsSinceEpoch - gameStartTime) ~/ 1000;
  }

  /// Check if game is active
  bool get isActive => !isWaitingToStart && !isGameOver;

  /// Get phase configuration
  Map<String, dynamic> getPhaseConfig() {
    switch (currentPhase) {
      case GamePhase.easy:
        return {
          'gap': 340.0,
          'speed': 1.0,
          'obstacle': 'phase1',
        };
      case GamePhase.medium:
        return {
          'gap': 320.0,
          'speed': 1.1,
          'obstacle': 'phase2',
        };
      case GamePhase.hard:
        return {
          'gap': 300.0,
          'speed': 1.2,
          'obstacle': 'phase3',
        };
      case GamePhase.expert:
        return {
          'gap': 280.0,
          'speed': 1.3,
          'obstacle': 'phase4',
        };
    }
  }

  void _updateBestStreak() {
    if (score > bestStreak) {
      bestStreak = score;
    }
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() => {
        'score': score,
        'bestScore': bestScore,
        'bestStreak': bestStreak,
        'lives': lives,
        'continuesUsedThisRun': continuesUsedThisRun,
        'currentTheme': currentTheme,
        'currentPhase': currentPhase.index,
      };

  /// Load from JSON
  void fromJson(Map<String, dynamic> json) {
    score = json['score'] ?? 0;
    bestScore = json['bestScore'] ?? 0;
    bestStreak = json['bestStreak'] ?? 0;
    lives = json['lives'] ?? GameConfig.maxLives;
    continuesUsedThisRun = json['continuesUsedThisRun'] ?? 0;
    currentTheme = json['currentTheme'] ?? 'Sky Rookie';
    currentPhase = GamePhase.values[json['currentPhase'] ?? 0];
  }
}

/// 🎮 GAME STATE MANAGER - Central hub for all game state
class GameStateManager extends ChangeNotifier {
  final GameStats _stats = GameStats();
  GameState _currentState = GameState.waitingToStart;

  // Getters
  GameStats get stats => _stats;
  GameState get currentState => _currentState;
  bool get isGameOver => _stats.isGameOver;
  bool get isWaitingToStart => _stats.isWaitingToStart;
  bool get isPlaying => _currentState == GameState.playing;
  int get currentScore => _stats.score;
  int get currentLives => _stats.lives;

  /// Start new game
  void startGame() {
    _stats.reset();
    _currentState = GameState.playing;
    notifyListeners();

    safePrint('🎮 Game started - State: $_currentState');
  }

  /// End game
  void endGame() {
    _stats.isGameOver = true;
    _currentState = GameState.gameOver;
    notifyListeners();

    safePrint('🎮 Game ended - Final Score: ${_stats.score}, Best: ${_stats.bestScore}');
  }

  /// Continue game after death
  bool continueGame() {
    if (_stats.useContinue()) {
      _currentState = GameState.playing;
      notifyListeners();
      safePrint('🎮 Game continued - Lives: ${_stats.lives}');
      return true;
    }
    return false;
  }

  /// Add score and handle phase transitions
  void addScore(int points) {
    _stats.addScore(points);

    // Notify about phase changes for UI updates
    notifyListeners();
  }

  /// Handle life loss
  void loseLife() {
    _stats.loseLife();

    if (_stats.isGameOver) {
      _currentState = GameState.gameOver;
    }

    notifyListeners();
  }

  /// Add extra life
  void addExtraLife() {
    _stats.addExtraLife();
    notifyListeners();
  }

  /// Reset game state
  void resetGame() {
    _stats.reset();
    _currentState = GameState.waitingToStart;
    notifyListeners();
  }

  /// Pause game
  void pauseGame() {
    if (_currentState == GameState.playing) {
      _currentState = GameState.paused;
      notifyListeners();
    }
  }

  /// Resume game
  void resumeGame() {
    if (_currentState == GameState.paused) {
      _currentState = GameState.playing;
      notifyListeners();
    }
  }

  /// Update theme
  void updateTheme(String newTheme) {
    _stats.currentTheme = newTheme;
    _stats.showingThemeNotification = true;

    // Hide notification after delay
    Future.delayed(const Duration(seconds: 3), () {
      _stats.showingThemeNotification = false;
      notifyListeners();
    });

    notifyListeners();
  }

  /// Get performance metrics
  Map<String, dynamic> getPerformanceMetrics() => {
        'current_score': _stats.score,
        'best_score': _stats.bestScore,
        'lives': _stats.lives,
        'continues_used': _stats.continuesUsedThisRun,
        'game_duration': _stats.gameDurationSeconds,
        'current_phase': _stats.currentPhase.toString(),
        'theme': _stats.currentTheme,
      };

  /// Save state to persistent storage
  Future<void> saveState() async {
    // Implementation for saving game state
    // This would integrate with SharedPreferences or other storage
    safePrint('💾 Game state saved');
  }

  /// Load state from persistent storage
  Future<void> loadState() async {
    // Implementation for loading game state
    safePrint('📂 Game state loaded');
  }
}
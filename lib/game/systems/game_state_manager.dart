/// 🎮 Game State Manager - Centralized game state management
library;

import 'package:flutter/foundation.dart';
import '../core/game_themes.dart';

/// Game states
enum GameState {
  waitingToStart,
  playing,
  gameOver,
  paused,
}

/// Centralized game state management
class GameStateManager extends ChangeNotifier {
  GameState _currentState = GameState.waitingToStart;
  GameTheme _currentTheme = GameThemes.skyRookie;
  int _score = 0;
  int _bestScore = 0;
  int _bestStreak = 0;
  int _lives = 3;
  int _continuesUsedThisRun = 0;
  bool _isInvulnerable = false;

  // Constants
  static const int maxContinuesPerRun = 5;

  // Getters
  GameState get currentState => _currentState;
  GameTheme get currentTheme => _currentTheme;
  int get score => _score;
  int get bestScore => _bestScore;
  int get bestStreak => _bestStreak;
  int get lives => _lives;
  int get continuesUsedThisRun => _continuesUsedThisRun;
  bool get isInvulnerable => _isInvulnerable;
  bool get isWaitingToStart => _currentState == GameState.waitingToStart;
  bool get isPlaying => _currentState == GameState.playing;
  bool get isGameOver => _currentState == GameState.gameOver;
  bool get isPaused => _currentState == GameState.paused;

  // State transitions
  void startGame() {
    if (_currentState == GameState.waitingToStart) {
      _currentState = GameState.playing;
      notifyListeners();
    }
  }

  void pauseGame() {
    if (_currentState == GameState.playing) {
      _currentState = GameState.paused;
      notifyListeners();
    }
  }

  void resumeGame() {
    if (_currentState == GameState.paused) {
      _currentState = GameState.playing;
      notifyListeners();
    }
  }

  void endGame() {
    _currentState = GameState.gameOver;
    
    // Update best score if needed
    if (_score > _bestScore) {
      _bestScore = _score;
    }
    
    notifyListeners();
  }

  void resetGame() {
    _currentState = GameState.waitingToStart;
    _score = 0;
    _currentTheme = GameThemes.skyRookie;
    _continuesUsedThisRun = 0;
    _isInvulnerable = false;
    notifyListeners();
  }

  // Score management
  void incrementScore() {
    _score++;
    notifyListeners();
  }

  void setScore(int newScore) {
    _score = newScore;
    notifyListeners();
  }

  void setBestScore(int newBestScore) {
    _bestScore = newBestScore;
    notifyListeners();
  }

  void setBestStreak(int newBestStreak) {
    _bestStreak = newBestStreak;
    notifyListeners();
  }

  // Lives management
  void setLives(int newLives) {
    _lives = newLives;
    notifyListeners();
  }

  void decrementLives() {
    if (_lives > 0) {
      _lives--;
      notifyListeners();
    }
  }

  void addLife() {
    _lives++;
    notifyListeners();
  }

  // Theme management
  void setTheme(GameTheme newTheme) {
    _currentTheme = newTheme;
    notifyListeners();
  }

  // Continue management
  void incrementContinues() {
    _continuesUsedThisRun++;
    notifyListeners();
  }

  bool canContinueWithAd() {
    return _continuesUsedThisRun < maxContinuesPerRun;
  }

  int get continuesRemaining => maxContinuesPerRun - _continuesUsedThisRun;

  // Invulnerability management
  void setInvulnerable(bool invulnerable) {
    _isInvulnerable = invulnerable;
    notifyListeners();
  }

  // Debug information
  Map<String, dynamic> getDebugInfo() {
    return {
      'state': _currentState.toString(),
      'theme': _currentTheme.displayName,
      'score': _score,
      'bestScore': _bestScore,
      'lives': _lives,
      'continues': _continuesUsedThisRun,
      'invulnerable': _isInvulnerable,
    };
  }
}

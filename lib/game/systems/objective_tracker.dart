/// 🎯 STORY MODE - OBJECTIVE TRACKER
/// 
/// Tracks player progress toward level objectives in real-time.
/// Supports three objective types: pass obstacles, survive time, beat bot.
library;

import 'package:flutter/foundation.dart';
import '../../models/level_data_schema.dart';
import '../../core/debug_logger.dart';

class ObjectiveTracker extends ChangeNotifier {
  // Current level objective
  LevelObjective? _objective;
  
  // Progress tracking
  int _currentProgress = 0;
  bool _isCompleted = false;
  
  // Time tracking (for survive objectives)
  double _elapsedSeconds = 0.0;
  
  // Bot battle tracking
  int _playerScore = 0;
  int _botScore = 0;
  bool _botIsActive = true; // Track if bot is still alive
  
  // Previous values for change detection (to reduce log spam)
  int _prevPlayerScore = -1;
  int _prevBotScore = -1;
  bool _prevBotIsActive = true;

  // Getters
  LevelObjective? get objective => _objective;
  int get currentProgress => _currentProgress;
  int get targetProgress => _objective?.target ?? 0;
  bool get isCompleted => _isCompleted;
  double get progressPercentage => targetProgress > 0 ? (_currentProgress / targetProgress) * 100 : 0;
  double get elapsedSeconds => _elapsedSeconds;
  int get playerScore => _playerScore;
  int get botScore => _botScore;
  bool get botIsActive => _botIsActive;

  /// Initialize tracking for a new level
  void startTracking(LevelObjective objective) {
    _objective = objective;
    _currentProgress = 0;
    _isCompleted = false;
    _elapsedSeconds = 0.0;
    _playerScore = 0;
    _botScore = 0;
    _botIsActive = true; // Reset bot state
    _prevPlayerScore = -1;
    _prevBotScore = -1;
    _prevBotIsActive = true;
    
    safePrint('🎯 Started tracking objective: ${objective.description}');
    notifyListeners();
  }

  /// Update progress (for pass obstacles objective)
  void incrementProgress() {
    if (_objective == null || _isCompleted) return;
    
    if (_objective!.type == ObjectiveType.passObstacles) {
      _currentProgress++;
      // Progress log removed - too verbose during gameplay
      _checkCompletion();
      notifyListeners();
    }
  }

  /// Update time (for survive objectives) - call this every frame
  void updateTime(double deltaTime) {
    if (_objective == null || _isCompleted) return;
    
    if (_objective!.type == ObjectiveType.surviveTime) {
      _elapsedSeconds += deltaTime;
      _currentProgress = _elapsedSeconds.floor();
      
      if (_currentProgress % 5 == 0 && _currentProgress > 0) {
        // Log every 5 seconds
        safePrint('🎯 Survived: $_currentProgress/${_objective!.target} seconds');
      }
      
      _checkCompletion();
      notifyListeners();
    }
  }

  /// Update time progress based on elapsed game time in milliseconds (excluding pauses like ads)
  void updateTimeProgress(int elapsedGameTimeMs) {
    if (_objective == null) {
      safePrint('🎯 TIME UPDATE: ❌ _objective is null');
      return;
    }
    
    if (_isCompleted) {
      safePrint('🎯 TIME UPDATE: ❌ Already completed');
      return;
    }
    
    if (_objective!.type != ObjectiveType.surviveTime) {
      safePrint('🎯 TIME UPDATE: ❌ Wrong objective type: ${_objective!.type}');
      return;
    }
    
    if (elapsedGameTimeMs < 0) {
      safePrint('🎯 TIME UPDATE: ❌ Invalid elapsedGameTimeMs: $elapsedGameTimeMs');
      return;
    }
    
    _elapsedSeconds = elapsedGameTimeMs / 1000.0;
    final oldProgress = _currentProgress;
    _currentProgress = _elapsedSeconds.floor();
    
    // Log every second
    if (_currentProgress != oldProgress) {
      safePrint('🎯 TIME UPDATE: ${_currentProgress}s / ${_objective!.target}s (elapsed: ${_elapsedSeconds.toStringAsFixed(1)}s)');
    }
    
    _checkCompletion();
    // Don't call notifyListeners() here as we're calling setState in the wrapper
  }

  /// Update bot battle scores
  void updateBotBattleScore({int? playerScore, int? botScore, bool? botIsActive}) {
    if (_objective == null || _isCompleted) return;
    
    if (_objective!.type == ObjectiveType.beatBot) {
      bool scoreChanged = false;
      
      if (playerScore != null && playerScore != _playerScore) {
        _playerScore = playerScore;
        _currentProgress = _playerScore;
        scoreChanged = true;
      }
      if (botScore != null && botScore != _botScore) {
        _botScore = botScore;
        scoreChanged = true;
      }
      if (botIsActive != null && botIsActive != _botIsActive) {
        _botIsActive = botIsActive;
        scoreChanged = true;
      }
      
      // Only log when score or status actually changes (reduces log spam)
      if (scoreChanged || _playerScore != _prevPlayerScore || _botScore != _prevBotScore || _botIsActive != _prevBotIsActive) {
        final statusEmoji = _botIsActive ? '💪' : '💥';
        safePrint('🎯 Bot Battle: Player $_playerScore vs Bot $_botScore $statusEmoji');
        _prevPlayerScore = _playerScore;
        _prevBotScore = _botScore;
        _prevBotIsActive = _botIsActive;
      }
      
      _checkCompletion();
      notifyListeners();
    }
  }

  /// Check if objective is completed
  void _checkCompletion() {
    if (_objective == null || _isCompleted) return;
    
    bool completed = false;
    
    switch (_objective!.type) {
      case ObjectiveType.passObstacles:
        completed = _currentProgress >= _objective!.target;
        break;
        
      case ObjectiveType.surviveTime:
        completed = _currentProgress >= _objective!.target;
        break;
        
      case ObjectiveType.beatBot:
        // ✅ FIX: Win conditions:
        // 1. Bot crashed: Player wins if score > bot score (immediately!)
        // 2. Bot alive: Player must reach target AND beat bot
        if (!_botIsActive) {
          // Bot crashed - player wins immediately if ahead
          completed = _playerScore > _botScore;
          if (completed) {
            safePrint('🎯 🏆 INSTANT WIN! Bot crashed, player wins with score $_playerScore > $_botScore');
          }
        } else {
          // Bot still alive - normal rules apply
          completed = _currentProgress >= _objective!.target && _playerScore > _botScore;
        }
        break;
    }
    
    if (completed && !_isCompleted) {
      _isCompleted = true;
      safePrint('🎯 ✅ Objective completed! ${_objective!.description}');
      notifyListeners();
    }
  }

  /// Force completion check (useful for bot battles when game ends)
  bool checkFinalCompletion() {
    if (_objective == null) return false;
    
    switch (_objective!.type) {
      case ObjectiveType.passObstacles:
        return _currentProgress >= _objective!.target;
        
      case ObjectiveType.surviveTime:
        return _currentProgress >= _objective!.target;
        
      case ObjectiveType.beatBot:
        // For bot battles, check if player won
        return _playerScore > _botScore;
    }
  }

  /// Get progress description for UI
  String getProgressDescription() {
    if (_objective == null) return '';
    
    switch (_objective!.type) {
      case ObjectiveType.passObstacles:
        return '$_currentProgress/${_objective!.target} obstacles';
        
      case ObjectiveType.surviveTime:
        // Show countdown instead of count-up
        final remaining = timeRemaining;
        return '$remaining seconds remaining';
        
      case ObjectiveType.beatBot:
        return 'You: $_playerScore | Bot: $_botScore';
    }
  }

  /// Get completion status for UI
  String getCompletionStatus() {
    if (_objective == null) return '';
    
    if (_isCompleted) {
      return '✅ ${_objective!.description}';
    } else {
      return '⏳ ${getProgressDescription()}';
    }
  }

  /// Reset tracker
  void reset() {
    _objective = null;
    _currentProgress = 0;
    _isCompleted = false;
    _elapsedSeconds = 0.0;
    _playerScore = 0;
    _botScore = 0;
    _botIsActive = true;
    
    safePrint('🎯 Tracker reset');
    notifyListeners();
  }

  /// Get time remaining (for survive objectives)
  int get timeRemaining {
    if (_objective == null || _objective!.type != ObjectiveType.surviveTime) {
      return 0;
    }
    return (_objective!.target - _currentProgress).clamp(0, _objective!.target);
  }

  /// Get obstacles remaining (for pass obstacles)
  int get obstaclesRemaining {
    if (_objective == null || _objective!.type != ObjectiveType.passObstacles) {
      return 0;
    }
    return (_objective!.target - _currentProgress).clamp(0, _objective!.target);
  }

  /// Check if player is winning (for bot battles)
  bool get isPlayerWinning {
    if (_objective == null || _objective!.type != ObjectiveType.beatBot) {
      return false;
    }
    return _playerScore > _botScore;
  }

  /// Get score difference (for bot battles)
  int get scoreDifference {
    return (_playerScore - _botScore).abs();
  }
}

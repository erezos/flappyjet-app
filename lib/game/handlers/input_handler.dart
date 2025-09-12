/// 🎮 INPUT HANDLER - Manages all user input and gesture handling
/// Extracted from EnhancedFlappyGame to separate input concerns
library;
import '../../core/debug_logger.dart';

import 'dart:async';
// flutter/foundation.dart import removed - not needed
import '../../game/managers/game_state_manager.dart';
import '../systems/flappy_jet_audio_manager.dart';

/// Input event types
enum InputEvent {
  tap,
  doubleTap,
  longPress,
  swipeUp,
  swipeDown,
}

/// Input handler configuration
class InputConfig {
  final Duration doubleTapThreshold;
  final Duration longPressThreshold;
  final double swipeThreshold;

  const InputConfig({
    this.doubleTapThreshold = const Duration(milliseconds: 300),
    this.longPressThreshold = const Duration(milliseconds: 500),
    this.swipeThreshold = 50.0,
  });
}

/// 🎮 Input Handler - Processes all user input events
class InputHandler {
  final GameStateManager _gameState;
  // TODO: Add collision manager, tournament service, and config when needed
  
  // UNIFIED AUDIO: Single audio manager instance
  late FlappyJetAudioManager _audioManager; // Modern FlappyJet audio

  // Input tracking
  DateTime? _lastTapTime;
  Timer? _longPressTimer;
  bool _isProcessingInput = false;

  // Callbacks for game actions
  void Function()? _onJump;
  void Function()? _onContinue;
  void Function()? _onPause;
  void Function()? _onRestart;

  InputHandler({
    required GameStateManager gameState,
    // TODO: Add other parameters when needed
  }) : _gameState = gameState {
    _audioManager = _audioManager;
  }

  /// Set callback functions
  void setCallbacks({
    void Function()? onJump,
    void Function()? onContinue,
    void Function()? onPause,
    void Function()? onRestart,
  }) {
    _onJump = onJump;
    _onContinue = onContinue;
    _onPause = onPause;
    _onRestart = onRestart;
  }

  /// Handle tap input
  Future<void> handleTap() async {
    if (_isProcessingInput) return;
    _isProcessingInput = true;

    try {
      safePrint('🎮 UI TAP DETECTED - Processing input');

      // Handle different game states
      switch (_gameState.currentState) {
        case GameState.waitingToStart:
          await _handleStartGame();
          break;

        case GameState.playing:
          await _handleGameplayTap();
          break;

        case GameState.gameOver:
          await _handleGameOverTap();
          break;

        case GameState.paused:
          await _handlePausedTap();
          break;
      }
    } catch (e) {
      safePrint('⚠️ Error handling tap input: $e');
    } finally {
      _isProcessingInput = false;
    }
  }

  /// Handle double tap input
  Future<void> handleDoubleTap() async {
    if (_isProcessingInput) return;
    _isProcessingInput = true;

    try {
      safePrint('🎮 DOUBLE TAP DETECTED');

      // Double tap for special actions (like boost or emergency jump)
      if (_gameState.currentState == GameState.playing) {
        await _handleDoubleTapAction();
      }
    } catch (e) {
      safePrint('⚠️ Error handling double tap: $e');
    } finally {
      _isProcessingInput = false;
    }
  }

  /// Handle long press input
  Future<void> handleLongPress() async {
    if (_isProcessingInput) return;
    _isProcessingInput = true;

    try {
      safePrint('🎮 LONG PRESS DETECTED');

      // Long press for special actions (like slow motion or pause)
      if (_gameState.currentState == GameState.playing) {
        await _handleLongPressAction();
      }
    } catch (e) {
      safePrint('⚠️ Error handling long press: $e');
    } finally {
      _isProcessingInput = false;
    }
  }

  /// Handle swipe gestures
  Future<void> handleSwipe(InputEvent swipeType, double velocity) async {
    if (_isProcessingInput) return;
    _isProcessingInput = true;

    try {
      safePrint('🎮 SWIPE DETECTED: $swipeType with velocity $velocity');

      switch (swipeType) {
        case InputEvent.swipeUp:
          await _handleSwipeUp(velocity);
          break;
        case InputEvent.swipeDown:
          await _handleSwipeDown(velocity);
          break;
        default:
          break;
      }
    } catch (e) {
      safePrint('⚠️ Error handling swipe: $e');
    } finally {
      _isProcessingInput = false;
    }
  }

  /// Handle game start
  Future<void> _handleStartGame() async {
    safePrint('🎮 Starting new game');

    // Play start sound
    await _audioManager.playSFX('audio/jump.wav'); // Using jump sound for button tap

    // Start the game
    _gameState.startGame();

    // Trigger jump to begin flight
    _onJump?.call();

    // Track analytics
    await _trackGameStart();
  }

  /// Handle gameplay tap
  Future<void> _handleGameplayTap() async {
    safePrint('🎮 Gameplay tap - triggering jump');

    // Play jump sound
    await _audioManager.playSFX('jump.wav');

    // Trigger jump action
    _onJump?.call();

    // Check for rapid tapping achievements
    await _checkRapidTapAchievement();
  }

  /// Handle game over tap
  Future<void> _handleGameOverTap() async {
    safePrint('🎮 Game over tap - showing continue options');

    // Play button sound
    await _audioManager.playSFX('audio/jump.wav'); // Using jump sound for button tap

    // Try to continue game
    if (_gameState.continueGame()) {
      _onContinue?.call();
    } else {
      // No continues available, restart
      _onRestart?.call();
    }
  }

  /// Handle paused tap
  Future<void> _handlePausedTap() async {
    safePrint('🎮 Paused tap - resuming game');

    // Play button sound
    await _audioManager.playSFX('audio/jump.wav'); // Using jump sound for button tap

    // Resume game
    _gameState.resumeGame();
  }

  /// Handle double tap action during gameplay
  Future<void> _handleDoubleTapAction() async {
    // Implement double tap boost or emergency action
    safePrint('🎮 Double tap action triggered');

    // Play special sound
    await _audioManager.playSFX('audio/achievement.wav'); // Using achievement sound for power up

    // Could implement boost, shield, or emergency jump
    // _onBoost?.call(); // Future enhancement
  }

  /// Handle long press action during gameplay
  Future<void> _handleLongPressAction() async {
    safePrint('🎮 Long press action triggered');

    // Implement slow motion or pause
    _gameState.pauseGame();
    _onPause?.call();
  }

  /// Handle swipe up
  Future<void> _handleSwipeUp(double velocity) async {
    safePrint('🎮 Swipe up detected');

    // Could implement flap boost or special maneuver
    if (_gameState.currentState == GameState.playing) {
      await _audioManager.playSFX('audio/achievement.wav');
      // Implement swipe-based special action
    }
  }

  /// Handle swipe down
  Future<void> _handleSwipeDown(double velocity) async {
    safePrint('🎮 Swipe down detected');

    // Could implement dive maneuver or emergency landing
    if (_gameState.currentState == GameState.playing) {
      await _audioManager.playSFX('audio/collision.wav');
      // Implement dive action
    }
  }

  /// Check for rapid tapping achievements
  Future<void> _checkRapidTapAchievement() async {
    final now = DateTime.now();
    final timeSinceLastTap = _lastTapTime != null
        ? now.difference(_lastTapTime!)
        : null;

    _lastTapTime = now;

    // Track rapid tapping patterns for achievements
    if (timeSinceLastTap != null && timeSinceLastTap.inMilliseconds < 200) {
      safePrint('🎯 Rapid tap detected - potential achievement');
      // Could trigger rapid tapper achievement
    }
  }

  /// Track game start analytics
  Future<void> _trackGameStart() async {
    try {
      // Track game start event - using debug print for now
      safePrint('🎯 Game started - timestamp: ${DateTime.now().millisecondsSinceEpoch}');
    } catch (e) {
      safePrint('⚠️ Failed to track game start: $e');
    }
  }

  /// Check if input is currently being processed
  bool get isProcessingInput => _isProcessingInput;

  /// Get input statistics
  Map<String, dynamic> getInputStats() => {
        'last_tap_time': _lastTapTime?.toIso8601String(),
        'is_processing_input': _isProcessingInput,
        'long_press_timer_active': _longPressTimer?.isActive ?? false,
      };

  /// Reset input handler state
  void reset() {
    _lastTapTime = null;
    _longPressTimer?.cancel();
    _longPressTimer = null;
    _isProcessingInput = false;
  }

  /// Dispose of resources
  void dispose() {
    _longPressTimer?.cancel();
    _longPressTimer = null;
    reset();
    safePrint('🎮 InputHandler disposed');
  }
}
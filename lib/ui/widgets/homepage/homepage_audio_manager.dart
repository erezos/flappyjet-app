/// 🎵 HOMEPAGE AUDIO MANAGER - Handles all audio-related functionality for homepage
/// Extracted from StunningHomepage to separate audio concerns
library;

import 'dart:async' as async;
import 'package:flutter/foundation.dart';
// Use FlameAudioManager for consistent audio across the app
import '../../../game/systems/flappy_jet_audio_manager.dart';
import '../../../game/systems/audio_settings_manager.dart';
import '../../../core/debug_logger.dart';

/// 🎵 Homepage Audio Manager - Manages menu music and audio state
class HomepageAudioManager extends ChangeNotifier {
  async.Timer? _ensureAudioTimer;
  bool _isInitialized = false;
  bool _disposed = false;
  bool _isInitializing = false;
  bool _musicIsPlaying = false;
  bool _hasHandledRouteChange = false; // Prevent repeated route change handling
  bool _isNavigatedAway =
      false; // Track if user has navigated away from homepage

  // UNIFIED AUDIO: Use single FlameAudioManager instance
  late FlappyJetAudioManager _audioManager;

  HomepageAudioManager() {
    _audioManager = FlappyJetAudioManager.instance;
  }

  bool get isInitialized => _isInitialized;

  /// Initialize audio for homepage and start menu music
  Future<void> initializeAudio() async {
    if (_disposed) return;

    try {
      safePrint('🎵 Starting initial homepage audio initialization...');

      // Initialize audio system
      await _audioManager.initialize();
      _isInitialized = true;

      // Start menu music immediately on initial load
      await _startMenuMusic();

      safePrint(
        '🎵 Initial homepage audio initialization completed successfully',
      );
      notifyListeners();
    } catch (e) {
      safePrint('⚠️ Failed to initialize homepage audio');
    }
  }

  /// Ensure audio is playing when homepage becomes active
  void ensureAudioActive() {
    if (_disposed || !_isInitialized || _isInitializing) {
      safePrint(
        '🎵 Skipping ensureAudioActive - disposed: $_disposed, initialized: $_isInitialized, initializing: $_isInitializing',
      );
      return;
    }

    // If music is already playing, don't restart it
    if (_musicIsPlaying) {
      safePrint('🎵 Menu music already playing - skipping restart');
      return;
    }

    _ensureAudioTimer?.cancel();
    _ensureAudioTimer = async.Timer(
      const Duration(milliseconds: 300),
      () async {
        if (!_disposed && _isInitialized && !_isInitializing) {
          safePrint('🎵 Ensuring homepage menu music is active');

          // 🛑 CRITICAL: Only stop game audio if we're actually on the homepage
          // Don't interfere with game audio when user is playing the game!
          try {
            safePrint('🎵 Ensuring menu music without stopping game audio');
            // Small delay to ensure clean state
            await Future.delayed(const Duration(milliseconds: 100));
          } catch (e) {
            safePrint('⚠️ Audio preparation failed: $e');
          }

          // Then restart menu music
          await _restartMenuMusic();
        }
      },
    );
  }

  /// Handle app lifecycle changes
  void handleAppLifecycleChange(bool isResumed) {
    if (_disposed) return;
    
    if (isResumed) {
      safePrint('🎵 App resumed - restarting homepage menu music');
      _initializeAudio();
    } else {
      safePrint('🎵 App went to background - pausing all audio');
      _pauseAllAudio();
    }
  }
  
  /// Pause all audio when app goes to background
  Future<void> _pauseAllAudio() async {
    if (_disposed) return;
    
    try {
      safePrint('🎵 Pausing all audio for background state');
      _musicIsPlaying = false;
      
      // Pause menu music (so it can resume from same position)
      await _audioManager.pauseMusic();
      
      // Cancel any pending audio timers
      _ensureAudioTimer?.cancel();
      _ensureAudioTimer = null;
      
      safePrint('🎵 All audio paused successfully');
    } catch (e) {
      safePrint('⚠️ Failed to pause audio: $e');
    }
  }

  /// Handle route changes (DISABLED during navigation)
  void handleRouteChange(bool isCurrentRoute) {
    // CRITICAL FIX: Ignore all route changes if user has navigated away
    if (_isNavigatedAway) {
      safePrint('🎵 User navigated away - ignoring route change');
      return;
    }

    if (isCurrentRoute && !_disposed && _isInitialized) {
      // Prevent repeated route change handling
      if (_hasHandledRouteChange && _musicIsPlaying) {
        safePrint(
          '🎵 Route change already handled and music playing - skipping',
        );
        return;
      }

      safePrint('🎵 Homepage is now current route - ensuring menu music');
      _hasHandledRouteChange = true;

      // Start menu music (don't force stop game audio here)
      _startMenuMusic();
    } else if (!isCurrentRoute) {
      // Reset flag when leaving the route
      _hasHandledRouteChange = false;
    }
  }

  /// Start menu music (internal method)
  Future<void> _startMenuMusic() async {
    safePrint(
      '🎵 CRITICAL: _startMenuMusic called - disposed: $_disposed, initializing: $_isInitializing',
    );

    if (_disposed || _isInitializing) {
      safePrint(
        '🎵 CRITICAL: Skipping _startMenuMusic - disposed: $_disposed, initializing: $_isInitializing',
      );
      return;
    }

    // Check if music is enabled in settings
    final audioSettings = AudioSettingsManager();
    final musicEnabled = audioSettings.shouldPlayMusic();
    safePrint('🎵 CRITICAL: Music enabled in settings: $musicEnabled');

    if (!musicEnabled) {
      safePrint('🎵 CRITICAL: Music disabled in settings, skipping menu music');
      _musicIsPlaying = false;
      return;
    }

    // CRITICAL FIX: Always reset state when navigated away and back
    // This prevents race conditions with the flag
    if (_isNavigatedAway) {
      safePrint(
        '🎵 CRITICAL: Just returned from navigation - forcing music restart',
      );
      _musicIsPlaying = false; // Force restart after navigation
    } else if (_musicIsPlaying) {
      safePrint('🎵 CRITICAL: Menu music already playing - skipping restart');
      return;
    }

    try {
      _isInitializing = true;
      safePrint('🎵 Starting menu music...');

      // Stop any existing music first (only if needed)
      await _audioManager.stopMusic();
      _musicIsPlaying = false;

      // Small delay to ensure clean state
      await Future.delayed(const Duration(milliseconds: 100));

      // Start menu music directly with higher volume for better audibility
      await _audioManager.playMenuMusic(); // FlappyJet menu music
      _musicIsPlaying = true;

      // Reset navigation flag after successful start
      _isNavigatedAway = false;
      safePrint('🎵 Menu music successfully started with volume 1.0');

      safePrint('🎵 Menu music started successfully');
    } catch (e) {
      _musicIsPlaying = false;
      safePrint('⚠️ Failed to start menu music');
    } finally {
      _isInitializing = false;
    }
  }

  /// Restart menu music when returning to homepage (lightweight)
  Future<void> _restartMenuMusic() async {
    if (_disposed || _isInitializing) return;

    try {
      safePrint('🎵 Restarting menu music for navigation return...');
      await _startMenuMusic();
      safePrint('🎵 Menu music restart completed successfully');
    } catch (e) {
      safePrint('⚠️ Failed to restart menu music');
    }
  }

  /// Internal audio re-initialization when returning to homepage (full reinit)
  Future<void> _initializeAudio() async {
    if (_disposed || _isInitializing) return;

    try {
      safePrint('🎵 Re-initializing homepage audio...');

      // Ensure audio systems are ready
      await _audioManager.initialize();
      // Music manager removed - using BulletproofAudioManager directly

      // Start menu music
      await _startMenuMusic();

      safePrint('🎵 Homepage audio re-initialization completed successfully');
    } catch (e) {
      safePrint('⚠️ Failed to re-initialize homepage audio');
    }
  }

  /// Stop menu music when navigating away
  Future<void> stopMenuMusic() async {
    if (_disposed) return;

    try {
      safePrint('🎵 Stopping menu music for navigation...');
      _musicIsPlaying = false;
      _hasHandledRouteChange = false; // Reset route change flag
      _isNavigatedAway = true; // Mark as navigated away

      // Stop ONLY SimpleAudioManager (menu music)
      // DON'T stop PlatformAudioManager - the game needs it!
      await _audioManager.stopMusic();

      safePrint('🎵 Menu music stopped, game audio system preserved');
    } catch (e) {
      safePrint('⚠️ Failed to stop menu music');
    }
  }

  /// Mark that user has returned to homepage (re-enable audio management)
  void markReturnedToHomepage() {
    safePrint(
      '🎵 CRITICAL: User returned to homepage - re-enabling audio management',
    );
    safePrint(
      '🎵 CRITICAL: _isInitialized: $_isInitialized, _disposed: $_disposed, _musicIsPlaying: $_musicIsPlaying, _isNavigatedAway: $_isNavigatedAway',
    );

    // Don't reset _isNavigatedAway immediately - let _startMenuMusic handle it
    _hasHandledRouteChange = false;

    // Always try to ensure menu music is playing when returning to homepage
    if (_isInitialized && !_disposed) {
      safePrint('🎵 CRITICAL: Scheduling menu music check in 100ms...');
      // Use a small delay to ensure the route transition is complete
      Future.delayed(const Duration(milliseconds: 100), () {
        safePrint(
          '🎵 CRITICAL: Delayed check - _disposed: $_disposed, _musicIsPlaying: $_musicIsPlaying, _isNavigatedAway: $_isNavigatedAway',
        );
        if (!_disposed) {
          safePrint(
            '🎵 CRITICAL: Starting menu music after return from navigation',
          );
          _startMenuMusic();
        } else {
          safePrint('🎵 CRITICAL: Skipping music start - disposed: $_disposed');
        }
      });
    } else {
      safePrint(
        '🎵 CRITICAL: Cannot start music - initialized: $_isInitialized, disposed: $_disposed',
      );
    }
  }

  /// Clean up resources
  @override
  void dispose() {
    _disposed = true;
    _ensureAudioTimer?.cancel();
    _ensureAudioTimer = null;
    safePrint('🎵 HomepageAudioManager disposed');
    super.dispose();
  }
}

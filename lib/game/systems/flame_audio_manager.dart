/// 🎵 Production-Ready Audio Manager
/// Optimized for mobile gaming with proper Android AudioFocus handling
/// Uses audioplayers with industry-standard Android audio configuration
library;
import '../../core/debug_logger.dart';

import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'audio_settings_manager.dart';

class FlameAudioManager {
  static FlameAudioManager? _instance;
  static FlameAudioManager get instance => _instance ??= FlameAudioManager._();

  FlameAudioManager._();

  bool _isInitialized = false;
  bool _musicEnabled = true;
  bool _sfxEnabled = true;

  // Audio players for music and SFX
  AudioPlayer? _musicPlayer;
  final Map<String, AudioPlayer> _sfxPlayers = {};
  final List<AudioPlayer> _activeSfxPlayers = [];

  // Critical SFX that need instant playback
  static const List<String> _criticalSfx = [
    'jump.wav',
    'collision.wav',
    'score.wav',
    'achievement.wav',
    'game_over.wav',
    'theme_unlock.wav',
  ];

  /// Initialize the audio system with proper Android AudioFocus
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (kDebugMode) safePrint('🎮 Initializing Production Audio Manager...');

      // Create music player
      _musicPlayer = AudioPlayer();

      // Setup Android AudioFocus for volume controls
      if (Platform.isAndroid) {
        await _setupAndroidAudioConfiguration();
      }

      // Initialize SFX players
      await _initializeSfxPlayers();

      _isInitialized = true;
      safePrint('✅ Production Audio Manager initialized successfully');
    } catch (e) {
      safePrint('❌ Failed to initialize Production Audio Manager: $e');
      rethrow;
    }
  }

  /// Setup Android AudioFocus for proper volume control handling
  Future<void> _setupAndroidAudioConfiguration() async {
    try {
      safePrint('🔊 Setting up Android AudioFocus for volume controls...');

      // Configure music player for proper AudioFocus
      if (_musicPlayer != null) {
        await _musicPlayer!.setAudioContext(
          AudioContext(
            android: AudioContextAndroid(
              isSpeakerphoneOn: false,
              stayAwake: true,
              contentType: AndroidContentType.music,
              usageType: AndroidUsageType.media,
              audioFocus:
                  AndroidAudioFocus.gain, // This is key for volume controls
            ),
          ),
        );
      }

      safePrint('✅ Android AudioFocus setup completed');
    } catch (e) {
      safePrint('⚠️ Android AudioFocus setup failed: $e');
    }
  }

  /// Initialize SFX players with proper AudioFocus
  Future<void> _initializeSfxPlayers() async {
    safePrint('🔊 Creating SFX players...');

    for (final sfx in _criticalSfx) {
      try {
        final player = AudioPlayer();

        // Configure SFX player for Android with proper AudioFocus
        if (Platform.isAndroid) {
          await player.setAudioContext(
            AudioContext(
              android: AudioContextAndroid(
                isSpeakerphoneOn: false,
                stayAwake: false,
                contentType: AndroidContentType.sonification,
                usageType: AndroidUsageType.game,
                audioFocus: AndroidAudioFocus
                    .gainTransientMayDuck, // Duck music, don't interrupt
              ),
            ),
          );
        }

        _sfxPlayers[sfx] = player;
        safePrint('✅ SFX player created: $sfx');
      } catch (e) {
        safePrint('⚠️ Failed to create player for $sfx: $e');
      }
    }

    safePrint(
      '🎯 SFX players ready: ${_sfxPlayers.length}/${_criticalSfx.length}',
    );
  }

  /// Play background music with proper AudioFocus and OPPO device crash protection
  Future<void> playMusic(String musicFile, {double volume = 1.0}) async {
    if (!_isInitialized || _musicPlayer == null) return;
    
    // Check AudioSettingsManager for music setting
    final audioSettings = AudioSettingsManager();
    if (!audioSettings.shouldPlayMusic()) return;

    try {
      // OPPO CRASH PROTECTION: Wrap all music operations
      try {
        // Stop any current music
        await _musicPlayer!.stop();

        // Set source and play with loop
        await _musicPlayer!.setSource(AssetSource('audio/$musicFile'));
        await _musicPlayer!.setVolume(volume);
        await _musicPlayer!.setReleaseMode(ReleaseMode.loop);
        await _musicPlayer!.resume();

        safePrint('🎵 Music started: $musicFile (volume: $volume)');
      } catch (oppoError) {
        safePrint('⚠️ OPPO music error (ignoring): $oppoError');
        // Silently fail on OPPO devices to prevent crash
      }
    } catch (e) {
      safePrint('❌ Failed to play music $musicFile: $e');
      // Don't rethrow - prevent crashes
    }
  }

  /// Stop background music with OPPO device crash protection
  Future<void> stopMusic() async {
    if (!_isInitialized || _musicPlayer == null) return;

    try {
      // OPPO CRASH PROTECTION: Wrap stop operation
      try {
        await _musicPlayer!.stop();
        safePrint('🎵 Music stopped');
      } catch (oppoError) {
        safePrint('⚠️ OPPO music stop error (ignoring): $oppoError');
        // Silently fail on OPPO devices to prevent crash
      }
    } catch (e) {
      safePrint('❌ Failed to stop music: $e');
      // Don't rethrow - prevent crashes
    }
  }

  /// Pause background music
  Future<void> pauseMusic() async {
    if (!_isInitialized || _musicPlayer == null) return;

    try {
      await _musicPlayer!.pause();
      safePrint('🎵 Music paused');
    } catch (e) {
      safePrint('❌ Failed to pause music: $e');
    }
  }

  /// Resume background music
  Future<void> resumeMusic() async {
    if (!_isInitialized || _musicPlayer == null) return;

    try {
      await _musicPlayer!.resume();
      safePrint('🎵 Music resumed');
    } catch (e) {
      safePrint('❌ Failed to resume music: $e');
    }
  }

  /// Play sound effect with proper AudioFocus and OPPO device crash protection
  Future<void> playSFX(String sfxFile, {double volume = 1.0}) async {
    if (!_isInitialized) return;
    
    // Check AudioSettingsManager for sound setting
    final audioSettings = AudioSettingsManager();
    if (!audioSettings.shouldPlaySound()) return;

    try {
      // Remove .wav extension if present for player lookup
      final playerKey = sfxFile
          .replaceAll('audio/', '')
          .replaceAll('.wav', '.wav');

      // Use dedicated player if available
      if (_sfxPlayers.containsKey(playerKey)) {
        final player = _sfxPlayers[playerKey]!;

        // Clean up completed players to prevent resource leaks
        _activeSfxPlayers.removeWhere((p) => p.state == PlayerState.stopped);

        // OPPO CRASH PROTECTION: Wrap all audio operations in try-catch
        try {
          await player.stop();
          await player.setSource(AssetSource('audio/$playerKey'));
          await player.setVolume(volume);
          await player.resume();

          _activeSfxPlayers.add(player);
          safePrint('🔊 SFX played: $playerKey (volume: $volume)');
          return;
        } catch (oppoError) {
          safePrint('⚠️ OPPO audio error (ignoring): $oppoError');
          return; // Silently fail on OPPO devices to prevent crash
        }
      }

      // Fallback to direct play for non-pooled sounds
      final fallbackPlayer = AudioPlayer();
      
      // OPPO CRASH PROTECTION: Wrap audio context setup
      try {
        if (Platform.isAndroid) {
          await fallbackPlayer.setAudioContext(
            AudioContext(
              android: AudioContextAndroid(
                contentType: AndroidContentType.sonification,
                usageType: AndroidUsageType.game,
                audioFocus: AndroidAudioFocus.gainTransientMayDuck,
              ),
            ),
          );
        }

        await fallbackPlayer.setSource(AssetSource('audio/$sfxFile'));
        await fallbackPlayer.setVolume(volume);
        await fallbackPlayer.resume();

        safePrint('🔊 SFX played (fallback): $sfxFile (volume: $volume)');
      } catch (oppoError) {
        safePrint('⚠️ OPPO audio fallback error (ignoring): $oppoError');
        // Silently fail on OPPO devices to prevent crash
      }
      
    } catch (e) {
      safePrint('❌ Failed to play SFX $sfxFile: $e');
      // Don't rethrow - prevent crashes
    }
  }

  /// Set music enabled state
  void setMusicEnabled(bool enabled) {
    _musicEnabled = enabled;
    if (!enabled) {
      stopMusic();
    }
    safePrint('🎵 Music enabled: $enabled');
  }

  /// Set SFX enabled state
  void setSfxEnabled(bool enabled) {
    _sfxEnabled = enabled;
    safePrint('🔊 SFX enabled: $enabled');
  }

  /// Get music enabled state
  bool get isMusicEnabled => _musicEnabled;

  /// Get SFX enabled state
  bool get isSfxEnabled => _sfxEnabled;

  /// Dispose resources
  Future<void> dispose() async {
    if (!_isInitialized) return;

    try {
      // Stop music
      await _musicPlayer?.stop();
      await _musicPlayer?.dispose();

      // Stop and dispose all SFX players
      for (final player in _sfxPlayers.values) {
        await player.stop();
        await player.dispose();
      }
      _sfxPlayers.clear();
      _activeSfxPlayers.clear();

      _isInitialized = false;
      safePrint('🧹 Production Audio Manager disposed');
    } catch (e) {
      safePrint('❌ Error disposing Production Audio Manager: $e');
    }
  }

  /// Get performance metrics
  Map<String, dynamic> get performanceMetrics => {
    'initialized': _isInitialized,
    'musicEnabled': _musicEnabled,
    'sfxEnabled': _sfxEnabled,
    'sfxPlayersCount': _sfxPlayers.length,
    'activeSfxPlayersCount': _activeSfxPlayers.length,
    'criticalSfxCount': _criticalSfx.length,
  };
}

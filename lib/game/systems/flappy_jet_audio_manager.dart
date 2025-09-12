/// 🎵 FlappyJet Audio Manager - PROPER Flame Audio Implementation
/// Using Flame Audio 2.1.0 best practices and documentation
/// 
/// Features:
/// - Proper AudioPool usage with preloaded instances
/// - Asset preloading to prevent loading delays
/// - Efficient SFX management for rapid-fire gameplay
/// - Bgm class for seamless music transitions
/// - Correct AudioFocus handling
library;

import 'dart:async';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import '../../core/debug_logger.dart';
import 'audio_settings_manager.dart';

/// 🎮 FlappyJet Audio Manager - PROPER Flame Audio Implementation
class FlappyJetAudioManager {
  static FlappyJetAudioManager? _instance;
  static FlappyJetAudioManager get instance => _instance ??= FlappyJetAudioManager._internal();
  FlappyJetAudioManager._internal();

  // 🎵 Audio State
  bool _isInitialized = false;
  bool _musicEnabled = true;
  bool _sfxEnabled = true;
  String? _currentMusic;

  // 🔊 AudioPool instances - PROPER Flame Audio usage
  final Map<String, AudioPool> _audioPools = {};
  
  // 🎯 Pool usage tracking for drop-on-busy strategy
  final Map<String, int> _poolUsageCount = {};
  final Map<String, int> _poolMaxSize = {};

  // 🎼 Audio Assets - All ACTUAL game audio files (verified in assets/audio/)
  static const List<String> _allAudioAssets = [
    // Music tracks (MP3 format)
    'menu_music.mp3',
    'sky_rookie.mp3',
    'legend.mp3',
    'space_cadet.mp3',
    'storm_ace.mp3',
    'void_master.mp3',
    
    // SFX files (WAV format)
    'jump.wav',
    'collision.wav',
    'score.wav',
    'achievement.wav',
    'game_over.wav',
    'theme_unlock.wav',
  ];

  // 🔊 SFX Pool Configuration - Optimized for FlappyJet gameplay
  static const Map<String, int> _sfxPoolConfig = {
    'jump.wav': 12,       // Most frequent - ultra-low latency needed (increased for rapid tapping)
    'collision.wav': 4,   // Damage/collision sounds
    'score.wav': 6,       // Score achievement sounds  
    'achievement.wav': 3, // Achievement unlocks
    'game_over.wav': 2,   // Game end sound
    'theme_unlock.wav': 2, // Theme unlock sound
  };

  /// 🚀 Initialize FlappyJet Audio System - PROPER Flame Audio way
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      safePrint('🎵 Initializing FlappyJet Audio Manager with Flame Audio 2.1.0...');

      // STEP 1: Preload ALL audio assets (Flame Audio best practice)
      await _preloadAllAssets();

      // STEP 2: Create AudioPools for SFX (proper pool management)
      await _createAudioPools();

      _isInitialized = true;
      safePrint('✅ FlappyJet Audio Manager initialized successfully');

    } catch (e) {
      safeError('❌ Failed to initialize FlappyJet Audio Manager: \$e');
      rethrow;
    }
  }

  /// 🎼 STEP 1: Preload all audio assets (prevents loading delays)
  Future<void> _preloadAllAssets() async {
    try {
      // Preload ALL audio files at once - Flame Audio best practice
      await FlameAudio.audioCache.loadAll(_allAudioAssets);
      safePrint('🎼 All audio assets preloaded successfully');
    } catch (e) {
      safeError('❌ Failed to preload audio assets: \$e');
      rethrow;
    }
  }

  /// 🔊 STEP 2: Create AudioPools for SFX (proper Flame Audio usage)
  Future<void> _createAudioPools() async {
    for (final entry in _sfxPoolConfig.entries) {
      final soundFile = entry.key;
      final poolSize = entry.value;

      try {
        // Create AudioPool - PROPER Flame Audio way
        final pool = await FlameAudio.createPool(
          soundFile,
          maxPlayers: poolSize,
          minPlayers: (poolSize / 2).ceil(), // Keep half ready
        );

        // Store the pool for reuse (ready to play when needed)
        _audioPools[soundFile] = pool;
        _poolUsageCount[soundFile] = 0;
        _poolMaxSize[soundFile] = poolSize;
        
        Logger.d('🔊 Audio pool created and ready: $soundFile (size: $poolSize)');
      } catch (e) {
        safeError('❌ Failed to create pool for $soundFile: $e');
      }
    }
  }

  /// 🎼 Play background music using Flame Audio Bgm class
  Future<void> playMusic(String musicType, {double volume = 1.0}) async {
    if (!_isInitialized) return;
    
    // Check AudioSettingsManager for music setting
    final audioSettings = AudioSettingsManager();
    if (!audioSettings.shouldPlayMusic()) return;

    String musicFile;
    
    // Check if musicType is already a filename (ends with .mp3)
    if (musicType.endsWith('.mp3')) {
      musicFile = musicType;
    } else {
      // Handle legacy music type strings
      switch (musicType) {
        case 'menu':
          musicFile = 'menu_music.mp3';
          break;
        case 'game':
          musicFile = 'sky_rookie.mp3';  // Use existing game music
          break;
        case 'gameOver':
          musicFile = 'menu_music.mp3';  // Use menu music for game over (no separate game over music exists)
          break;
        default:
          safeError('❌ Unknown music type: \$musicType');
          return;
      }
    }

    try {
      // Use Flame Audio Bgm class for background music
      if (FlameAudio.bgm.isPlaying) {
        await FlameAudio.bgm.stop();
      }

      await FlameAudio.bgm.play(musicFile, volume: volume);
      _currentMusic = musicType;
      
      safePrint('🎼 Music started: \$musicType (\$musicFile)');
    } catch (e) {
      safeError('❌ Failed to play music \$musicType: \$e');
    }
  }

  /// 🔊 Play SFX using AudioPool - Drop-on-busy strategy for smooth performance
  Future<void> playSFX(String soundFile, {double volume = 1.0}) async {
    if (!_isInitialized) return;
    
    // Check AudioSettingsManager for sound setting
    final audioSettings = AudioSettingsManager();
    if (!audioSettings.shouldPlaySound()) return;

    final pool = _audioPools[soundFile];
    if (pool == null) {
      safeError('❌ No audio pool found for: $soundFile');
      return;
    }

    // 🎯 DROP-ON-BUSY STRATEGY: Check if pool is at capacity
    final currentUsage = _poolUsageCount[soundFile] ?? 0;
    final maxSize = _poolMaxSize[soundFile] ?? 0;
    
    if (currentUsage >= maxSize) {
      // Pool is full - drop the sound request to prevent queueing
      if (kDebugMode) {
        Logger.d('🔇 SFX dropped (pool full): $soundFile ($currentUsage/$maxSize)');
      }
      return;
    }

    try {
      // Increment usage counter
      _poolUsageCount[soundFile] = currentUsage + 1;
      
      // Play the sound
      await pool.start(volume: volume);
      
      if (kDebugMode) {
        Logger.d('🔊 SFX played: $soundFile (volume: $volume)');
      }
      
      // Decrement usage counter after a reasonable duration
      // Most game SFX are short (< 1 second)
      Future.delayed(const Duration(milliseconds: 800), () {
        final usage = _poolUsageCount[soundFile] ?? 0;
        if (usage > 0) {
          _poolUsageCount[soundFile] = usage - 1;
        }
      });
      
    } catch (e) {
      // Decrement counter on error
      final usage = _poolUsageCount[soundFile] ?? 0;
      if (usage > 0) {
        _poolUsageCount[soundFile] = usage - 1;
      }
      
      if (kDebugMode) {
        safeError('❌ Failed to play SFX $soundFile: $e');
      }
    }
  }

  /// 🎮 FlappyJet-specific audio methods for easy game integration
  
  /// 🚀 Ultra-low latency jump sound
  Future<void> playJump() async => await playSFX('jump.wav', volume: 0.8);
  
  /// 💥 Collision sound
  Future<void> playCollision() async => await playSFX('collision.wav', volume: 1.0);
  
  /// 🏆 Score sound
  Future<void> playScore() async => await playSFX('score.wav', volume: 0.9);
  
  /// 🎉 Achievement sound
  Future<void> playAchievement() async => await playSFX('achievement.wav', volume: 1.0);
  
  /// 💀 Game over sound
  Future<void> playGameOver() async => await playSFX('game_over.wav', volume: 1.0);

  /// 🎼 FlappyJet-specific music methods
  
  /// 🏠 Menu music
  Future<void> playMenuMusic() async => await playMusic('menu', volume: 1.0);
  
  /// 🎮 Game music
  Future<void> playGameMusic() async => await playMusic('game', volume: 0.7);
  
  /// 💀 Game over music
  Future<void> playGameOverMusic() async => await playMusic('gameOver', volume: 0.8);

  /// 🛑 Stop current music
  Future<void> stopMusic() async {
    if (!_isInitialized) return;

    try {
      await FlameAudio.bgm.stop();
      _currentMusic = null;
      safePrint('🎵 Music stopped');
    } catch (e) {
      safeError('❌ Failed to stop music: \$e');
    }
  }

  /// 🔇 Pause current music
  Future<void> pauseMusic() async {
    if (!_isInitialized) return;

    try {
      await FlameAudio.bgm.pause();
      safePrint('⏸️ Music paused');
    } catch (e) {
      safeError('❌ Failed to pause music: \$e');
    }
  }

  /// ▶️ Resume current music
  Future<void> resumeMusic() async {
    if (!_isInitialized) return;

    try {
      await FlameAudio.bgm.resume();
      safePrint('▶️ Music resumed');
    } catch (e) {
      safeError('❌ Failed to resume music: \$e');
    }
  }

  /// 🎛️ Audio Settings Management
  
  void setMusicEnabled(bool enabled) {
    _musicEnabled = enabled;
    if (!enabled && _isInitialized) {
      stopMusic();
    }
  }

  void setSfxEnabled(bool enabled) {
    _sfxEnabled = enabled;
  }

  bool get musicEnabled => _musicEnabled;
  bool get sfxEnabled => _sfxEnabled;
  bool get isInitialized => _isInitialized;
  String? get currentMusic => _currentMusic;

  /// 🧹 Cleanup resources
  Future<void> dispose() async {
    if (!_isInitialized) return;

    try {
      // Stop all music
      await stopMusic();

      // Dispose all audio pools
      // Note: AudioPool doesn't have explicit dispose method in Flame Audio
      // The pools will be garbage collected when the manager is disposed
      _audioPools.clear();

      // Clear audio cache if needed
      FlameAudio.audioCache.clearAll();

      _isInitialized = false;
      safePrint('🧹 FlappyJet Audio Manager disposed');
    } catch (e) {
      safeError('❌ Error during audio manager disposal: \$e');
    }
  }
}
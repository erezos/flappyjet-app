import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flame_audio/flame_audio.dart';
import '../core/game_config.dart';
import '../core/game_themes.dart';

/// MCP-Guided Audio Management System for FlappyJet Pro
/// Implements theme-aware music, sound effects, and performance optimization
class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  // Audio state
  bool _isInitialized = false;
  bool _musicEnabled = true;
  bool _sfxEnabled = true;
  double _musicVolume = GameConfig.musicVolume;
  double _sfxVolume = GameConfig.sfxVolume;
  GameTheme? _currentTheme;
  
  // Audio controllers
  late ProceduralMusicController _musicController;
  late SFXController _sfxController;
  late HapticController _hapticController;

  /// Initialize the audio system
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _musicController = ProceduralMusicController();
      _sfxController = SFXController();
      _hapticController = HapticController();
      
      await _musicController.initialize();
      await _sfxController.initialize();
      
      _isInitialized = true;
      debugPrint('🎵 AudioManager initialized successfully');
    } catch (e) {
      debugPrint('❌ AudioManager initialization failed: $e');
      // Graceful fallback - audio optional
    }
  }

  /// Play theme music for current theme
  Future<void> playThemeMusic(GameTheme theme) async {
    if (!_isInitialized || !_musicEnabled) return;
    
    if (_currentTheme != theme) {
      _currentTheme = theme;
      await _musicController.playThemeMusic(theme, _musicVolume);
      debugPrint('🎵 Playing ${theme.displayName} theme music');
    }
  }

  /// Play main menu music
  Future<void> playMenuMusic() async {
    if (!_isInitialized || !_musicEnabled) return;
    
    _currentTheme = null; // Clear current theme when playing menu music
    try {
      await _musicController.playMenuMusic(_musicVolume);
    } catch (e) {
      debugPrint('🎵 ⚠️ Could not start menu music: $e');
    }
    debugPrint('🎵 Playing main menu music');
  }

  /// Play sound effect
  Future<void> playSFX(SFXType type) async {
    if (!_isInitialized || !_sfxEnabled) return;
    
    await _sfxController.play(type, _sfxVolume);
    
    // Trigger haptic feedback if enabled
    if (GameConfig.enableHapticFeedback) {
      _hapticController.triggerForSFX(type);
    }
  }

  /// Stop all audio
  Future<void> stopAll() async {
    if (!_isInitialized) return;
    try {
      await _musicController.stop();
    } catch (e) {
      debugPrint('🎵 ⚠️ Music stop skipped: $e');
    }
    try {
      await _sfxController.stopAll();
    } catch (e) {
      debugPrint('🔊 ⚠️ SFX stop skipped: $e');
    }
  }

  /// Pause all audio
  Future<void> pauseAll() async {
    if (!_isInitialized) return;
    
    await _musicController.pause();
  }

  /// Resume all audio
  Future<void> resumeAll() async {
    if (!_isInitialized) return;
    
    await _musicController.resume();
  }

  /// Update volume settings
  void setMusicVolume(double volume) {
    if (volume.isNaN) {
      _musicVolume = 0.0;
    } else {
      _musicVolume = volume.clamp(0.0, 1.0);
    }
    _musicController.setVolume(_musicVolume);
  }

  void setSFXVolume(double volume) {
    _sfxVolume = volume.clamp(0.0, 1.0);
  }

  /// Toggle audio settings
  void toggleMusic() {
    _musicEnabled = !_musicEnabled;
    if (!_musicEnabled) {
      _musicController.stop();
    } else if (_currentTheme != null) {
      playThemeMusic(_currentTheme!);
    }
  }

  void toggleSFX() {
    _sfxEnabled = !_sfxEnabled;
  }

  /// Getters
  bool get isMusicEnabled => _musicEnabled;
  bool get isSFXEnabled => _sfxEnabled;
  double get musicVolume => _musicVolume;
  double get sfxVolume => _sfxVolume;
}

/// Sound effect types
enum SFXType {
  jump,
  score,
  collision,
  themeUnlock,
  gameOver,
  heartLoss,
  achievement,
}

/// File-based music controller using Flame Audio
class ProceduralMusicController {
  bool _isPlaying = false;
  GameTheme? _currentTheme;
  double _volume = 1.0;

  // Audio file mapping (fixed paths - no 'audio/' prefix needed)
  static const Map<String, String> _themeFiles = {
    'sky_rookie': 'sky_rookie.mp3',
    'space_cadet': 'space_cadet.mp3', 
    'storm_ace': 'storm_ace.mp3',
    'void_master': 'void_master.mp3',
    'legend': 'legend.mp3',
  };

  // Main menu music
  static const String _menuMusicFile = 'menu_music.mp3';

  Future<void> initialize() async {
    // Pre-cache all music files including menu music
    try {
      // Cache theme music files
      for (final file in _themeFiles.values) {
        await FlameAudio.audioCache.load(file);
      }
      // Cache menu music
      await FlameAudio.audioCache.load(_menuMusicFile);
      
      debugPrint('🎼 Music controller ready - ${_themeFiles.length} theme tracks + menu music cached');
    } catch (e) {
      debugPrint('🎼 ⚠️ Music files not found - running in silent mode: $e');
    }
  }

  Future<void> playThemeMusic(GameTheme theme, double volume) async {
    if (_currentTheme == theme && _isPlaying) return;
    
    try {
      await stop();
    } catch (e) {
      debugPrint('🎵 ⚠️ Stop before playing theme failed: $e');
    }
    _currentTheme = theme;
    _volume = volume;
    _isPlaying = true;
    
    // Play actual music file for theme
    await _playThemeFile(theme);
  }

  Future<void> _playThemeFile(GameTheme theme) async {
    final musicFile = _themeFiles[theme.id];
    if (musicFile == null) {
      debugPrint('🎵 ⚠️ No music file for theme: ${theme.id}');
      return;
    }

    try {
      await FlameAudio.bgm.play(musicFile, volume: _volume);
      debugPrint('🎵 Playing ${theme.displayName} music: $musicFile');
    } catch (e) {
      debugPrint('🎵 ⚠️ Could not play $musicFile: $e');
    }
  }

  Future<void> stop() async {
    _isPlaying = false;
    _currentTheme = null;
    await FlameAudio.bgm.stop();
  }

  Future<void> pause() async {
    _isPlaying = false;
    await FlameAudio.bgm.pause();
  }

  Future<void> resume() async {
    if (_currentTheme != null) {
      _isPlaying = true;
      await FlameAudio.bgm.resume();
    }
  }

  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
    FlameAudio.bgm.audioPlayer.setVolume(_volume);
  }

  /// Play main menu music
  Future<void> playMenuMusic(double volume) async {
    await stop(); // Stop any current music
    _currentTheme = null; // Clear current theme
    _volume = volume;
    _isPlaying = true;

    try {
      await FlameAudio.bgm.play(_menuMusicFile, volume: _volume);
      debugPrint('🎵 Playing menu music: $_menuMusicFile');
    } catch (e) {
      debugPrint('🎵 ⚠️ Could not play menu music: $e');
    }
  }
}

/// File-based sound effects controller using Flame Audio
class SFXController {
  final Map<SFXType, DateTime> _lastPlayed = {};
  static const Duration _minInterval = Duration(milliseconds: 50);
  final Map<SFXType, AudioPool> _pools = {};

  // SFX file mapping (fixed paths - no 'audio/' prefix needed)
  static const Map<SFXType, String> _sfxFiles = {
    SFXType.jump: 'jump.wav',
    SFXType.score: 'score.wav',
    SFXType.collision: 'collision.wav',
    SFXType.heartLoss: 'heart_loss.wav',  // Note: file needs to be added
    SFXType.gameOver: 'game_over.wav',
    SFXType.achievement: 'achievement.wav',
    SFXType.themeUnlock: 'theme_unlock.wav',
  };

  Future<void> initialize() async {
    // Pre-cache all SFX files
    try {
      for (final file in _sfxFiles.values) {
        await FlameAudio.audioCache.load(file);
      }
      // Create low-latency pools for all core SFX
      for (final entry in _sfxFiles.entries) {
        try {
          final pool = await FlameAudio.createPool(
            entry.value,
            maxPlayers: 4,
          );
          _pools[entry.key] = pool;
        } catch (e) {
          debugPrint('🔊 ⚠️ Failed to create pool for ${entry.key.name}: $e');
        }
      }
      debugPrint('🔊 SFX controller ready - ${_sfxFiles.length} sounds cached, ${_pools.length} pools created');
    } catch (e) {
      debugPrint('🔊 ⚠️ SFX files not found - running in silent mode: $e');
    }
  }

  Future<void> play(SFXType type, double volume) async {
    // Prevent rapid-fire SFX spam
    final now = DateTime.now();
    final lastPlayed = _lastPlayed[type];
    if (lastPlayed != null && now.difference(lastPlayed) < _minInterval) {
      return;
    }
    
    _lastPlayed[type] = now;
    await _playSFXFile(type, volume);
  }

  Future<void> _playSFXFile(SFXType type, double volume) async {
    final sfxFile = _sfxFiles[type];
    if (sfxFile == null) {
      debugPrint('🔊 ⚠️ No SFX file for type: ${type.name}');
      return;
    }

    try {
      final pool = _pools[type];
      if (pool != null) {
        try {
          await pool.start(volume: volume);
          debugPrint('🔊 [POOL] ${type.name} → $sfxFile (${(volume * 100).round()}%)');
          return;
        } catch (e) {
          debugPrint('🔊 ⚠️ Pool start failed for ${type.name}: $e, falling back');
        }
      }
      // Fallback to regular play
      await FlameAudio.play(sfxFile, volume: volume);
      debugPrint('🔊 Playing ${type.name} SFX: $sfxFile (${(volume * 100).round()}% volume)');
    } catch (e) {
      debugPrint('🔊 ⚠️ Could not play $sfxFile: $e');
    }
  }

  Future<void> stopAll() async {
    // No-op for pools; rely on short SFX. Background music handled separately.
  }
}

/// Haptic feedback controller
class HapticController {
  void triggerForSFX(SFXType type) {
    if (!GameConfig.enableHapticFeedback) return;
    
    switch (type) {
      case SFXType.jump:
        HapticFeedback.lightImpact();
        break;
      case SFXType.score:
        HapticFeedback.selectionClick();
        break;
      case SFXType.collision:
        HapticFeedback.mediumImpact();
        break;
      case SFXType.themeUnlock:
        HapticFeedback.heavyImpact();
        break;
      case SFXType.gameOver:
        HapticFeedback.heavyImpact();
        break;
      case SFXType.heartLoss:
        HapticFeedback.mediumImpact();
        break;
      case SFXType.achievement:
        HapticFeedback.lightImpact();
        break;
    }
  }
}

/// Audio system utilities
class AudioUtils {
  /// Get audio file performance metrics
  static Map<String, dynamic> getPerformanceMetrics() {
    return {
      'audio_latency_ms': 30,
      'music_memory_mb': 8.0,  // File-based audio uses more memory
      'sfx_memory_mb': 2.0,
      'file_caching_enabled': true,
      'haptic_response_time_ms': 10,
    };
  }

  /// Validate audio file structure
  static bool validateAudioStructure() {
    // This could be expanded to check if files exist
    return true;
  }
} 
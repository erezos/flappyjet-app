/// 🎵 FLAPPY JET AUDIO MANAGER - Direct Native Audio Implementation
/// Simple, direct interface to native audio system
/// Zero complexity, maximum performance
library;

import 'dart:async';
import '../../core/debug_logger.dart';
import 'audio_settings_manager.dart';
import 'native_audio_engine.dart';

/// 🎵 FlappyJet Audio Manager - Native Audio Bridge Implementation
/// 
/// This class maintains the exact same API as the original FlappyJetAudioManager
/// but uses the Native Audio Bridge internally for crash-free, low-latency audio.
/// 
/// Key Features:
/// - Zero breaking changes to existing code
/// - Native audio performance (no MediaPlayer ANRs)
/// - Automatic fallback handling
/// - Settings integration
/// - Lifecycle management
class FlappyJetAudioManager {
  static FlappyJetAudioManager? _instance;
  static FlappyJetAudioManager get instance => _instance ??= FlappyJetAudioManager._internal();
  
  FlappyJetAudioManager._internal();

  // Direct native audio system
  final NativeAudioEngine _nativeAudio = NativeAudioEngine.instance;
  final AudioSettingsManager _settings = AudioSettingsManager();
  
  bool _isInitialized = false;
  bool _isInitializing = false;
  
  // Current music state
  String? _currentMusic;
  bool _musicPlaying = false;
  bool _musicPaused = false;

  /// Initialize the audio manager
  Future<void> initialize() async {
    if (_isInitialized || _isInitializing) return;
    _isInitializing = true;

    try {
      safePrint('🎵 FlappyJetAudioManager: Initializing direct native audio...');
      
      // Initialize native audio engine
      await _nativeAudio.initialize();
      
      // Register all audio tracks
      await _registerAllTracks();
      
      _isInitialized = true;
      safePrint('🎵 FlappyJetAudioManager: Initialization completed successfully');
    } catch (e) {
      safePrint('🎵 FlappyJetAudioManager: Initialization failed: $e');
    } finally {
      _isInitializing = false;
    }
  }

  /// Register all game audio tracks with the native engine
  Future<void> _registerAllTracks() async {
    // Import the AudioTrack class
    // Music tracks
    await _nativeAudio.registerTrack(AudioTrack(
      id: 'menu_music',
      assetPath: 'assets/audio/menu_music.mp3',
      type: AudioTrackType.music,
      loop: true,
      volume: 0.7,
    ));
    await _nativeAudio.registerTrack(AudioTrack(
      id: 'sky_rookie',
      assetPath: 'assets/audio/sky_rookie.mp3',
      type: AudioTrackType.music,
      loop: true,
      volume: 0.7,
    ));
    await _nativeAudio.registerTrack(AudioTrack(
      id: 'space_cadet',
      assetPath: 'assets/audio/space_cadet.mp3',
      type: AudioTrackType.music,
      loop: true,
      volume: 0.7,
    ));
    await _nativeAudio.registerTrack(AudioTrack(
      id: 'storm_ace',
      assetPath: 'assets/audio/storm_ace.mp3',
      type: AudioTrackType.music,
      loop: true,
      volume: 0.7,
    ));
    await _nativeAudio.registerTrack(AudioTrack(
      id: 'void_master',
      assetPath: 'assets/audio/void_master.mp3',
      type: AudioTrackType.music,
      loop: true,
      volume: 0.7,
    ));
    await _nativeAudio.registerTrack(AudioTrack(
      id: 'legend',
      assetPath: 'assets/audio/legend.mp3',
      type: AudioTrackType.music,
      loop: true,
      volume: 0.7,
    ));
    
    // SFX tracks
    await _nativeAudio.registerTrack(AudioTrack(
      id: 'jump',
      assetPath: 'assets/audio/jump.wav',
      type: AudioTrackType.sfx,
      volume: 0.8,
      preload: true,
    ));
    await _nativeAudio.registerTrack(AudioTrack(
      id: 'collision',
      assetPath: 'assets/audio/collision.wav',
      type: AudioTrackType.sfx,
      volume: 0.9,
      preload: true,
    ));
    await _nativeAudio.registerTrack(AudioTrack(
      id: 'score',
      assetPath: 'assets/audio/score.wav',
      type: AudioTrackType.sfx,
      volume: 0.7,
      preload: true,
    ));
    await _nativeAudio.registerTrack(AudioTrack(
      id: 'achievement',
      assetPath: 'assets/audio/achievement.wav',
      type: AudioTrackType.sfx,
      volume: 0.9,
      preload: true,
    ));
    await _nativeAudio.registerTrack(AudioTrack(
      id: 'game_over',
      assetPath: 'assets/audio/game_over.wav',
      type: AudioTrackType.sfx,
      volume: 0.8,
      preload: true,
    ));
    await _nativeAudio.registerTrack(AudioTrack(
      id: 'theme_unlock',
      assetPath: 'assets/audio/theme_unlock.wav',
      type: AudioTrackType.sfx,
      volume: 1.0,
      preload: true,
    ));
  }

  /// Play jump sound effect
  Future<void> playJump() async {
    if (!_isInitialized || !_settings.shouldPlaySound()) return;
    
    try {
      await _nativeAudio.playSFX('jump', volume: 0.8);
    } catch (e) {
      safePrint('🎵 FlappyJetAudioManager: Jump sound failed: $e');
    }
  }

  /// Play score sound effect
  Future<void> playScore() async {
    if (!_isInitialized || !_settings.shouldPlaySound()) return;
    
    try {
      await _nativeAudio.playSFX('score', volume: 0.7);
    } catch (e) {
      safePrint('🎵 FlappyJetAudioManager: Score sound failed: $e');
    }
  }

  /// Play collision sound effect
  Future<void> playCollision() async {
    if (!_isInitialized || !_settings.shouldPlaySound()) return;
    
    try {
      await _nativeAudio.playSFX('collision', volume: 0.9);
    } catch (e) {
      safePrint('🎵 FlappyJetAudioManager: Collision sound failed: $e');
    }
  }

  /// Play game over sound effect
  Future<void> playGameOver() async {
    if (!_isInitialized || !_settings.shouldPlaySound()) return;
    
    try {
      await _nativeAudio.playSFX('game_over', volume: 0.8);
    } catch (e) {
      safePrint('🎵 FlappyJetAudioManager: Game over sound failed: $e');
    }
  }

  /// Play achievement sound effect
  Future<void> playAchievement() async {
    if (!_isInitialized || !_settings.shouldPlaySound()) return;
    
    try {
      await _nativeAudio.playSFX('achievement', volume: 0.9);
    } catch (e) {
      safePrint('🎵 FlappyJetAudioManager: Achievement sound failed: $e');
    }
  }

  /// Play theme unlock sound effect
  Future<void> playThemeUnlock() async {
    if (!_isInitialized || !_settings.shouldPlaySound()) return;
    
    try {
      await _nativeAudio.playSFX('theme_unlock', volume: 1.0);
    } catch (e) {
      safePrint('🎵 FlappyJetAudioManager: Theme unlock sound failed: $e');
    }
  }

  /// Play generic SFX by filename (maintains compatibility)
  Future<void> playSFX(String filename, {double volume = 1.0}) async {
    if (!_isInitialized || !_settings.shouldPlaySound()) return;
    
    try {
      // Clean filename and play directly
      final trackId = filename.toLowerCase().replaceAll('.wav', '').replaceAll('.mp3', '');
      await _nativeAudio.playSFX(trackId, volume: volume);
    } catch (e) {
      safePrint('🎵 FlappyJetAudioManager: SFX $filename failed: $e');
    }
  }

  /// Play background music
  Future<void> playMusic(String musicFile, {double volume = 0.7}) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final stackTrace = StackTrace.current.toString().split('\n').take(5).join('\n');
    
    safePrint('🎵 🔍 MUSIC REQUEST: $musicFile at $timestamp');
    safePrint('🎵 🔍 CURRENT STATE: _currentMusic=$_currentMusic, _musicPlaying=$_musicPlaying, _initialized=$_isInitialized');
    safePrint('🎵 🔍 CALL STACK:\n$stackTrace');
    
    if (!_isInitialized || !_settings.shouldPlayMusic()) {
      safePrint('🎵 🔍 REJECTED: initialized=$_isInitialized, musicEnabled=${_settings.shouldPlayMusic()}');
      return;
    }
    
    try {
      safePrint('🎵 🔍 PROCESSING: Playing music: $musicFile');
      
      // Stop current music if different
      if (_currentMusic != musicFile && _musicPlaying) {
        safePrint('🎵 🔍 STOPPING: Current music $_currentMusic before playing $musicFile');
        await stopMusic();
      }
      
      _currentMusic = musicFile;
      _musicPlaying = true;
      _musicPaused = false;
      
      // Clean filename and play directly
      final trackId = musicFile.toLowerCase().replaceAll('.mp3', '').replaceAll('.wav', '');
      safePrint('🎵 🔍 NATIVE CALL: About to call native playMusic with trackId=$trackId, volume=$volume');
      await _nativeAudio.playMusic(trackId, volume: volume, loop: true);
      
      safePrint('🎵 🔍 SUCCESS: Music started successfully - $musicFile');
    } catch (e) {
      _musicPlaying = false;
      safePrint('🎵 🔍 ERROR: Music playback failed: $e');
    }
  }

  /// Play menu music specifically
  Future<void> playMenuMusic({double volume = 1.0}) async {
    await playMusic('menu_music.mp3', volume: volume);
  }

  /// Stop background music
  Future<void> stopMusic() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final stackTrace = StackTrace.current.toString().split('\n').take(5).join('\n');
    
    safePrint('🎵 🔍 STOP REQUEST: at $timestamp');
    safePrint('🎵 🔍 STOP STATE: _currentMusic=$_currentMusic, _musicPlaying=$_musicPlaying');
    safePrint('🎵 🔍 STOP STACK:\n$stackTrace');
    
    if (!_isInitialized) {
      safePrint('🎵 🔍 STOP REJECTED: Not initialized');
      return;
    }
    
    try {
      safePrint('🎵 🔍 STOP NATIVE: Calling native stopMusic');
      await _nativeAudio.stopMusic();
      _musicPlaying = false;
      _musicPaused = false;
      _currentMusic = null;
      safePrint('🎵 🔍 STOP SUCCESS: Music stopped');
    } catch (e) {
      safePrint('🎵 🔍 STOP ERROR: Stop music failed: $e');
    }
  }

  /// Pause background music
  Future<void> pauseMusic() async {
    if (!_isInitialized || !_musicPlaying || _musicPaused) return;
    
    try {
      await _nativeAudio.pauseMusic();
      _musicPaused = true;
      safePrint('🎵 FlappyJetAudioManager: Music paused');
    } catch (e) {
      safePrint('🎵 FlappyJetAudioManager: Pause music failed: $e');
    }
  }

  /// Resume background music
  Future<void> resumeMusic() async {
    if (!_isInitialized || !_musicPaused) return;
    
    try {
      await _nativeAudio.resumeMusic();
      _musicPaused = false;
      safePrint('🎵 FlappyJetAudioManager: Music resumed');
    } catch (e) {
      safePrint('🎵 FlappyJetAudioManager: Resume music failed: $e');
    }
  }

  /// Set music volume (placeholder for compatibility)
  Future<void> setMusicVolume(double volume) async {
    if (!_isInitialized) return;
    
    try {
      // Volume control handled by native audio system internally
      safePrint('🎵 FlappyJetAudioManager: Music volume set to $volume');
    } catch (e) {
      safePrint('🎵 FlappyJetAudioManager: Set music volume failed: $e');
    }
  }

  /// Set SFX volume (placeholder for compatibility)
  Future<void> setSFXVolume(double volume) async {
    if (!_isInitialized) return;
    
    try {
      // Volume control handled by native audio system internally
      safePrint('🎵 FlappyJetAudioManager: SFX volume set to $volume');
    } catch (e) {
      safePrint('🎵 FlappyJetAudioManager: Set SFX volume failed: $e');
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    try {
      await stopMusic();
      await _nativeAudio.dispose();
      _isInitialized = false;
      safePrint('🎵 FlappyJetAudioManager: Disposed successfully');
    } catch (e) {
      safePrint('🎵 FlappyJetAudioManager: Dispose failed: $e');
    }
  }

  // Getters for compatibility
  bool get isInitialized => _isInitialized;
  bool get isMusicPlaying => _musicPlaying && !_musicPaused;
  bool get isMusicPaused => _musicPaused;
  String? get currentMusic => _currentMusic;
}

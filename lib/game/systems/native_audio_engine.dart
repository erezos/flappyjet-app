/// 🎵 Native Audio Engine - AAA Mobile Game Audio System
/// 
/// Features:
/// - Native OpenSL ES/AAudio for Android (ultra-low latency)
/// - Native AVAudioEngine for iOS (professional audio)
/// - Zero MediaPlayer crashes (no Java MediaPlayer dependency)
/// - Sub-20ms audio latency for game SFX
/// - Professional audio mixing and effects
/// - Bulletproof error handling with graceful fallbacks
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'audio_settings_manager.dart';

/// Audio engine states
enum AudioEngineState {
  uninitialized,
  initializing,
  ready,
  error,
  disposed,
}

/// Audio track types for optimization
enum AudioTrackType {
  music,      // Streaming, compressed, looping
  sfx,        // Preloaded, uncompressed, low-latency
  voice,      // Dynamic, real-time processing
}

/// Audio track configuration
class AudioTrack {
  final String id;
  final String assetPath;
  final AudioTrackType type;
  final double volume;
  final bool loop;
  final int priority;
  final bool preload;

  const AudioTrack({
    required this.id,
    required this.assetPath,
    required this.type,
    this.volume = 1.0,
    this.loop = false,
    this.priority = 0,
    this.preload = true,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'assetPath': assetPath,
    'type': type.name,
    'volume': volume,
    'loop': loop,
    'priority': priority,
    'preload': preload,
  };
}

/// Native Audio Engine - Direct platform audio without MediaPlayer
class NativeAudioEngine {
  static const MethodChannel _channel = MethodChannel('flappyjet.audio.native');
  
  static NativeAudioEngine? _instance;
  static NativeAudioEngine get instance => _instance ??= NativeAudioEngine._internal();
  NativeAudioEngine._internal();

  // Engine state
  AudioEngineState _state = AudioEngineState.uninitialized;
  final Map<String, AudioTrack> _tracks = {};
  final Map<String, bool> _loadedTracks = {};
  
  // Settings integration
  final AudioSettingsManager _settings = AudioSettingsManager();
  
  // Performance monitoring
  int _totalTracksLoaded = 0;
  int _activeSounds = 0;
  double _engineLatency = 0.0;

  // Getters
  AudioEngineState get state => _state;
  bool get isReady => _state == AudioEngineState.ready;
  int get totalTracksLoaded => _totalTracksLoaded;
  int get activeSounds => _activeSounds;
  double get engineLatency => _engineLatency;

  /// Initialize the native audio engine
  Future<bool> initialize() async {
    if (_state == AudioEngineState.ready) return true;
    if (_state == AudioEngineState.initializing) {
      // Wait for initialization to complete
      while (_state == AudioEngineState.initializing) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return _state == AudioEngineState.ready;
    }

    _state = AudioEngineState.initializing;
    
    try {
        print('🎵 Initializing Native Audio Engine...');
      
      // Initialize settings
      await _settings.initialize();
      
      // Initialize native engine
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('initialize', {
        'sampleRate': 44100,
        'bufferSize': 256,  // Low latency buffer
        'maxTracks': 32,    // Sufficient for game audio
        'enableEffects': true,
      });

      if (result?['success'] == true) {
        _engineLatency = (result?['latency'] as num?)?.toDouble() ?? 0.0;
        _state = AudioEngineState.ready;
        
        print('🎵 ✅ Native Audio Engine initialized successfully');
        print('🎵 📊 Engine latency: ${_engineLatency.toStringAsFixed(1)}ms');
        
        // Set up method call handler for callbacks
        _channel.setMethodCallHandler(_handleNativeCallback);
        
        return true;
      } else {
        throw Exception('Native engine initialization failed: ${result?['error']}');
      }
    } catch (e) {
      print('🎵 ❌ Native Audio Engine initialization failed: $e');
      _state = AudioEngineState.error;
      return false;
    }
  }

  /// Handle callbacks from native code
  Future<void> _handleNativeCallback(MethodCall call) async {
    switch (call.method) {
      case 'onTrackLoaded':
        final trackId = call.arguments['trackId'] as String;
        _loadedTracks[trackId] = true;
        _totalTracksLoaded++;
        print('🎵 Track loaded: $trackId');
        break;
        
      case 'onTrackStarted':
        _activeSounds++;
        break;
        
      case 'onTrackStopped':
        if (_activeSounds > 0) _activeSounds--;
        break;
        
      case 'onMusicStarted':
        // REMOVED: This callback was causing restart loops
        print('🎵 ⚠️ Unexpected music started callback (should not happen)');
        break;
        
      case 'onMusicStopped':
        print('🎵 🛑 Music stopped');
        break;
        
      case 'onEngineError':
        final error = call.arguments['error'] as String;
        print('🎵 ❌ Native engine error: $error');
        break;
        
      default:
        print('🎵 Unknown callback: ${call.method}');
    }
  }

  /// Register an audio track for use
  Future<bool> registerTrack(AudioTrack track) async {
    if (!isReady) {
      print('🎵 ❌ Engine not ready, cannot register track: ${track.id}');
      return false;
    }

    try {
      // Load asset data
      final ByteData assetData = await rootBundle.load(track.assetPath);
      final Uint8List audioData = assetData.buffer.asUint8List();

      final result = await _channel.invokeMethod<bool>('registerTrack', {
        'track': track.toMap(),
        'audioData': audioData,
      });

      if (result == true) {
        _tracks[track.id] = track;
        print('🎵 ✅ Track registered: ${track.id}');
        return true;
      } else {
        print('🎵 ❌ Failed to register track: ${track.id}');
        return false;
      }
    } catch (e) {
      print('🎵 ❌ Error registering track ${track.id}: $e');
      return false;
    }
  }

  /// Play a sound effect (ultra-low latency)
  Future<bool> playSFX(String trackId, {double volume = 1.0}) async {
    if (!isReady || !_settings.shouldPlaySound()) return false;
    
    final track = _tracks[trackId];
    if (track == null) {
      print('🎵 ❌ Track not found: $trackId');
      return false;
    }

    try {
      final result = await _channel.invokeMethod<bool>('playSFX', {
        'trackId': trackId,
        'volume': volume * (track.volume),
      });

      if (result == true) {
        if (kDebugMode) {
          print('🎵 🔊 SFX played: $trackId');
        }
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('🎵 ❌ Error playing SFX $trackId: $e');
      }
      return false;
    }
  }

  /// Play background music (streaming)
  Future<bool> playMusic(String trackId, {double volume = 1.0, bool loop = true}) async {
    if (!isReady || !_settings.shouldPlayMusic()) return false;
    
    final track = _tracks[trackId];
    if (track == null) {
      print('🎵 ❌ Music track not found: $trackId');
      return false;
    }

    try {
      final result = await _channel.invokeMethod<bool>('playMusic', {
        'trackId': trackId,
        'volume': volume * track.volume,
        'loop': loop,
      });

      if (result == true) {
        print('🎵 🎼 Music started: $trackId');
        return true;
      }
      return false;
    } catch (e) {
      print('🎵 ❌ Error playing music $trackId: $e');
      return false;
    }
  }

  /// Stop music
  Future<bool> stopMusic() async {
    if (!isReady) return false;

    try {
      final result = await _channel.invokeMethod<bool>('stopMusic');
      if (result == true) {
        print('🎵 🛑 Music stopped');
        return true;
      }
      return false;
    } catch (e) {
      print('🎵 ❌ Error stopping music: $e');
      return false;
    }
  }

  /// Pause music
  Future<bool> pauseMusic() async {
    if (!isReady) return false;

    try {
      final result = await _channel.invokeMethod<bool>('pauseMusic');
      if (result == true) {
        print('🎵 ⏸️ Music paused');
        return true;
      }
      return false;
    } catch (e) {
      print('🎵 ❌ Error pausing music: $e');
      return false;
    }
  }

  /// Resume music
  Future<bool> resumeMusic() async {
    if (!isReady) return false;

    try {
      final result = await _channel.invokeMethod<bool>('resumeMusic');
      if (result == true) {
        print('🎵 ▶️ Music resumed');
        return true;
      }
      return false;
    } catch (e) {
      print('🎵 ❌ Error resuming music: $e');
      return false;
    }
  }

  /// Set master volume
  Future<bool> setMasterVolume(double volume) async {
    if (!isReady) return false;

    try {
      final result = await _channel.invokeMethod<bool>('setMasterVolume', {
        'volume': volume.clamp(0.0, 1.0),
      });
      return result == true;
    } catch (e) {
      print('🎵 ❌ Error setting master volume: $e');
      return false;
    }
  }

  /// Get engine performance stats
  Future<Map<String, dynamic>> getPerformanceStats() async {
    if (!isReady) return {};

    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getStats');
      return Map<String, dynamic>.from(result ?? {});
    } catch (e) {
      print('🎵 ❌ Error getting performance stats: $e');
      return {};
    }
  }

  /// Dispose the audio engine
  Future<void> dispose() async {
    if (_state == AudioEngineState.disposed) return;

    try {
      await _channel.invokeMethod<void>('dispose');
      _state = AudioEngineState.disposed;
      _tracks.clear();
      _loadedTracks.clear();
      print('🎵 🧹 Native Audio Engine disposed');
    } catch (e) {
      print('🎵 ❌ Error disposing audio engine: $e');
    }
  }
}

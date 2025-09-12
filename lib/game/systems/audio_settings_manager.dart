/// 🎵 Audio Settings Manager - Handles sound and music toggle settings
library;
import '../../core/debug_logger.dart';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'flame_audio_manager.dart';
import 'flappy_jet_audio_manager.dart';

/// Audio Settings Manager - Controls sound effects and music on/off states
class AudioSettingsManager extends ChangeNotifier {
  static final AudioSettingsManager _instance = AudioSettingsManager._internal();
  factory AudioSettingsManager() => _instance;
  AudioSettingsManager._internal();

  static const String _keyMusicEnabled = 'audio_music_enabled';
  static const String _keySoundEnabled = 'audio_sound_enabled';

  bool _musicEnabled = true;
  bool _soundEnabled = true;
  bool _isInitialized = false;

  bool get musicEnabled => _musicEnabled;
  bool get soundEnabled => _soundEnabled;
  bool get isInitialized => _isInitialized;

  /// Initialize audio settings from storage
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _musicEnabled = prefs.getBool(_keyMusicEnabled) ?? true;
      _soundEnabled = prefs.getBool(_keySoundEnabled) ?? true;
      
      _isInitialized = true;
      safePrint('🎵 AudioSettingsManager initialized - Music: $_musicEnabled, Sound: $_soundEnabled');
      notifyListeners();
    } catch (e) {
      safePrint('⚠️ Failed to initialize audio settings: $e');
    }
  }

  /// Toggle music on/off
  Future<void> toggleMusic() async {
    _musicEnabled = !_musicEnabled;
    await _saveMusicSetting();
    
    // Apply the setting immediately to both audio managers
    if (!_musicEnabled) {
      // Stop music in both audio managers
      final flameAudioManager = FlameAudioManager.instance;
      await flameAudioManager.stopMusic();
      
      final flappyJetAudioManager = FlappyJetAudioManager.instance;
      await flappyJetAudioManager.stopMusic();
    }
    
    safePrint('🎵 Music toggled: $_musicEnabled');
    notifyListeners();
  }

  /// Toggle sound effects on/off
  Future<void> toggleSound() async {
    _soundEnabled = !_soundEnabled;
    await _saveSoundSetting();
    
    safePrint('🔊 Sound effects toggled: $_soundEnabled');
    notifyListeners();
  }

  /// Set music enabled state
  Future<void> setMusicEnabled(bool enabled) async {
    if (_musicEnabled == enabled) return;
    
    _musicEnabled = enabled;
    await _saveMusicSetting();
    
    // Apply the setting immediately to both audio managers
    if (!_musicEnabled) {
      // Stop music in both audio managers
      final flameAudioManager = FlameAudioManager.instance;
      await flameAudioManager.stopMusic();
      
      final flappyJetAudioManager = FlappyJetAudioManager.instance;
      await flappyJetAudioManager.stopMusic();
    }
    
    safePrint('🎵 Music set to: $_musicEnabled');
    notifyListeners();
  }

  /// Set sound effects enabled state
  Future<void> setSoundEnabled(bool enabled) async {
    if (_soundEnabled == enabled) return;
    
    _soundEnabled = enabled;
    await _saveSoundSetting();
    
    safePrint('🔊 Sound effects set to: $_soundEnabled');
    notifyListeners();
  }

  /// Save music setting to storage
  Future<void> _saveMusicSetting() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyMusicEnabled, _musicEnabled);
    } catch (e) {
      safePrint('⚠️ Failed to save music setting: $e');
    }
  }

  /// Save sound setting to storage
  Future<void> _saveSoundSetting() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keySoundEnabled, _soundEnabled);
    } catch (e) {
      safePrint('⚠️ Failed to save sound setting: $e');
    }
  }

  /// Check if music should play (used by audio manager)
  bool shouldPlayMusic() => _musicEnabled;

  /// Check if sound effects should play (used by audio manager)
  bool shouldPlaySound() => _soundEnabled;
}
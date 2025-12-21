/// 🎵 MENU AUDIO MANAGER - Global menu music for tab navigation
/// Manages menu music across all tabs in the app
library;

import 'package:flutter/widgets.dart';
import '../../core/debug_logger.dart';
import 'audio_settings_manager.dart';
import 'flappy_jet_audio_manager.dart';

/// Manages menu music for the entire app (tab navigation)
/// 
/// Features:
/// - ✅ Start menu music when app initializes
/// - ✅ Stop menu music when entering game
/// - ✅ Resume menu music when exiting game
/// - ✅ Pause/resume on app lifecycle changes
/// - ✅ Respect audio settings (music on/off)
/// 
/// Usage:
/// ```dart
/// class MyApp extends StatefulWidget {
///   @override
///   State<MyApp> createState() => _MyAppState();
/// }
/// 
/// class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
///   late MenuAudioManager _menuAudio;
///   
///   @override
///   void initState() {
///     super.initState();
///     WidgetsBinding.instance.addObserver(this);
///     
///     _menuAudio = MenuAudioManager();
///     _menuAudio.initialize();
///   }
///   
///   @override
///   void dispose() {
///     WidgetsBinding.instance.removeObserver(this);
///     _menuAudio.dispose();
///     super.dispose();
///   }
///   
///   @override
///   void didChangeAppLifecycleState(AppLifecycleState state) {
///     _menuAudio.handleAppLifecycle(state);
///   }
/// }
/// ```
class MenuAudioManager extends ChangeNotifier {
  final FlappyJetAudioManager _audio = FlappyJetAudioManager.instance;
  final AudioSettingsManager _settings = AudioSettingsManager();
  
  bool _initialized = false;
  bool _musicPlaying = false;
  bool _gameScreenActive = false;
  bool _disposed = false;
  
  bool get isInitialized => _initialized;
  bool get isMusicPlaying => _musicPlaying;
  bool get isGameScreenActive => _gameScreenActive;
  
  /// Initialize audio system and start menu music
  Future<void> initialize() async {
    if (_disposed) return;
    
    try {
      safePrint('🎵 MenuAudioManager: Initializing...');
      
      // Initialize audio system
      await _audio.initialize();
      _initialized = true;
      
      // Start menu music
      await startMenuMusic();
      
      safePrint('🎵 MenuAudioManager: Initialized successfully');
      notifyListeners();
    } catch (e) {
      safePrint('⚠️ MenuAudioManager: Failed to initialize: $e');
    }
  }
  
  /// Start menu music
  Future<void> startMenuMusic() async {
    if (_disposed || !_initialized || _gameScreenActive) {
      safePrint('🎵 MenuAudioManager: Skip start - disposed: $_disposed, initialized: $_initialized, gameActive: $_gameScreenActive');
      return;
    }
    
    // Check if music is enabled in settings
    if (!_settings.shouldPlayMusic()) {
      safePrint('🎵 MenuAudioManager: Music disabled in settings');
      _musicPlaying = false;
      return;
    }
    
    // Don't restart if already playing
    if (_musicPlaying) {
      safePrint('🎵 MenuAudioManager: Music already playing');
      return;
    }
    
    try {
      safePrint('🎵 MenuAudioManager: Starting menu music...');
      
      // Stop any existing music first
      await _audio.stopMusic();
      
      // Small delay to ensure clean state
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Start menu music
      await _audio.playMenuMusic();
      _musicPlaying = true;
      
      safePrint('🎵 MenuAudioManager: Menu music started');
      notifyListeners();
    } catch (e) {
      _musicPlaying = false;
      safePrint('⚠️ MenuAudioManager: Failed to start menu music: $e');
    }
  }
  
  /// Stop menu music (e.g., when entering game)
  Future<void> stopMenuMusic() async {
    if (_disposed || !_musicPlaying) {
      return;
    }
    
    try {
      safePrint('🎵 MenuAudioManager: Stopping menu music...');
      
      await _audio.stopMusic();
      _musicPlaying = false;
      
      safePrint('🎵 MenuAudioManager: Menu music stopped');
      notifyListeners();
    } catch (e) {
      safePrint('⚠️ MenuAudioManager: Failed to stop menu music: $e');
    }
  }
  
  /// Handle app lifecycle (pause/resume)
  Future<void> handleAppLifecycle(AppLifecycleState state) async {
    if (_disposed) return;
    
    if (state == AppLifecycleState.resumed) {
      // App resumed - restart menu music if game is not active
      if (!_gameScreenActive) {
        safePrint('🎵 MenuAudioManager: App resumed - restarting menu music');
        _musicPlaying = false; // Force restart
        await startMenuMusic();
      } else {
        safePrint('🎵 MenuAudioManager: App resumed - game active, skip music');
      }
    } else if (state == AppLifecycleState.paused || 
               state == AppLifecycleState.inactive) {
      // App paused/backgrounded - pause audio
      safePrint('🎵 MenuAudioManager: App paused - pausing audio');
      await _audio.pauseMusic();
    }
  }
  
  /// Mark game screen as active (suspend menu music)
  Future<void> onGameScreenOpened() async {
    safePrint('🎵 MenuAudioManager: Game screen opened');
    _gameScreenActive = true;
    await stopMenuMusic();
    notifyListeners();
  }
  
  /// Mark game screen as closed (resume menu music)
  Future<void> onGameScreenClosed() async {
    safePrint('🎵 MenuAudioManager: Game screen closed');
    _gameScreenActive = false;
    _musicPlaying = false; // Force restart
    await startMenuMusic();
    notifyListeners();
  }
  
  /// Force refresh menu music (e.g., after settings change)
  Future<void> refresh() async {
    if (_disposed || _gameScreenActive) return;
    
    safePrint('🎵 MenuAudioManager: Refreshing...');
    _musicPlaying = false;
    await startMenuMusic();
  }
  
  @override
  void dispose() {
    _disposed = true;
    safePrint('🎵 MenuAudioManager: Disposed');
    super.dispose();
  }
}


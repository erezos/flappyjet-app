/// 🚀 Performance Optimized Game Launcher
/// Designed to eliminate main thread blocking and improve Android performance
library;
import '../../core/debug_logger.dart';

import 'dart:async';
import 'package:flutter/services.dart';

import '../systems/player_identity_manager.dart';
import '../systems/audio_settings_manager.dart';
import '../systems/inventory_manager.dart';
import '../systems/lives_manager.dart';

/// Performance-optimized initialization system
class PerformanceOptimizedLauncher {
  static final PerformanceOptimizedLauncher _instance = PerformanceOptimizedLauncher._internal();
  factory PerformanceOptimizedLauncher() => _instance;
  PerformanceOptimizedLauncher._internal();

  bool _isInitialized = false;
  final Map<String, bool> _systemStatus = {};
  final StreamController<InitializationProgress> _progressController = StreamController.broadcast();

  Stream<InitializationProgress> get progressStream => _progressController.stream;
  bool get isInitialized => _isInitialized;

  /// Initialize all systems with maximum performance optimization
  Future<void> initializeOptimized() async {
    if (_isInitialized) return;

    safePrint('🚀 Starting PERFORMANCE OPTIMIZED initialization...');
    final stopwatch = Stopwatch()..start();

    try {
      // Phase 1: Critical systems only (< 100ms target)
      await _initializeCriticalSystems();
      _emitProgress('Critical systems loaded', 0.2);

      // Phase 2: Background initialization (non-blocking)
      _initializeBackgroundSystems();
      _emitProgress('Background systems starting', 0.4);

      // Phase 3: Lazy initialization markers
      _setupLazyInitialization();
      _emitProgress('Lazy systems configured', 0.6);

      // Phase 4: Asset preloading (background)
      _preloadCriticalAssets();
      _emitProgress('Assets preloading', 0.8);

      _isInitialized = true;
      _emitProgress('Ready to play!', 1.0);

      stopwatch.stop();
      safePrint('🚀 ✅ Optimized initialization completed in ${stopwatch.elapsedMilliseconds}ms');

    } catch (e) {
      safePrint('🚀 ❌ Initialization failed: $e');
      _emitProgress('Initialization failed', 0.0);
    }
  }

  /// Phase 1: Only absolutely critical systems (synchronous, fast)
  Future<void> _initializeCriticalSystems() async {
    safePrint('🚀 Phase 1: Critical systems (target: <100ms)');
    final stopwatch = Stopwatch()..start();

    // Only the most essential systems that must be ready immediately
    try {
      // Basic platform services
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);

      _systemStatus['platform'] = true;
      safePrint('🚀 ✅ Critical systems ready in ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      safePrint('🚀 ❌ Critical systems failed: $e');
    }
  }

  /// Phase 2: Background systems (asynchronous, non-blocking)
  void _initializeBackgroundSystems() {
    safePrint('🚀 Phase 2: Background systems (async)');

    // Initialize systems in parallel, non-blocking
    _initializeSystemAsync('player_identity', () async {
      // Player identity initialization
      final playerIdentity = PlayerIdentityManager();
      await playerIdentity.initialize();
      return playerIdentity;
    });

    _initializeSystemAsync('audio', () async {
      // Audio system initialization
      final audioSettings = AudioSettingsManager();
      await audioSettings.initialize();
      return audioSettings;
    });

    _initializeSystemAsync('inventory', () async {
      // Inventory system initialization
      final inventory = InventoryManager();
      await inventory.initialize();
      return inventory;
    });

    _initializeSystemAsync('lives', () async {
      // Lives system initialization
      final lives = LivesManager();
      await lives.initialize();
      return lives;
    });
  }

  /// Phase 3: Lazy initialization setup
  void _setupLazyInitialization() {
    safePrint('🚀 Phase 3: Lazy initialization setup');

    // Mark systems for lazy initialization
    _systemStatus['leaderboard_lazy'] = false;
    _systemStatus['missions_lazy'] = false;
    _systemStatus['monetization_lazy'] = false;
    _systemStatus['remote_config_lazy'] = false;

    safePrint('🚀 ✅ Lazy systems configured');
  }

  /// Phase 4: Asset preloading (background)
  void _preloadCriticalAssets() {
    safePrint('🚀 Phase 4: Asset preloading (background)');

    // Preload only critical assets in background
    _initializeSystemAsync('critical_assets', () async {
      // Load only essential game assets
      await _loadEssentialAssets();
      return true;
    });
  }

  /// Initialize a system asynchronously without blocking main thread
  void _initializeSystemAsync(String systemName, Future<dynamic> Function() initializer) {
    initializer().then((result) {
      _systemStatus[systemName] = true;
      safePrint('🚀 ✅ Background system ready: $systemName');
    }).catchError((error) {
      safePrint('🚀 ❌ Background system failed: $systemName - $error');
      _systemStatus[systemName] = false;
    });
  }

  /// Load only essential assets for immediate gameplay
  Future<void> _loadEssentialAssets() async {
    try {
      // Load only the most critical assets
      // - Default jet skin
      // - Basic UI elements
      // - Essential audio files
      
      // This would be implemented based on your asset structure
      safePrint('🚀 Loading essential assets...');
      
      // Simulate asset loading (replace with actual asset loading)
      await Future.delayed(const Duration(milliseconds: 50));
      
      safePrint('🚀 ✅ Essential assets loaded');
    } catch (e) {
      safePrint('🚀 ❌ Essential asset loading failed: $e');
    }
  }

  /// Lazy initialize a system when first needed
  Future<T> lazyInitialize<T>(String systemName, Future<T> Function() initializer) async {
    if (_systemStatus[systemName] == true) {
      // System already initialized
      return await initializer();
    }

    safePrint('🚀 Lazy initializing: $systemName');
    final result = await initializer();
    _systemStatus[systemName] = true;
    safePrint('🚀 ✅ Lazy system ready: $systemName');
    return result;
  }

  /// Check if a system is ready
  bool isSystemReady(String systemName) {
    return _systemStatus[systemName] == true;
  }

  /// Emit progress update
  void _emitProgress(String message, double progress) {
    _progressController.add(InitializationProgress(message, progress));
  }

  /// Cleanup resources
  void dispose() {
    _progressController.close();
  }
}

/// Progress information for initialization
class InitializationProgress {
  final String message;
  final double progress;

  InitializationProgress(this.message, this.progress);
}
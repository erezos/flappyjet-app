/// 🎯 Platform Optimizer - Tailored Performance for iOS & Android
/// 
/// This system provides platform-specific optimizations while maintaining
/// a single codebase. Based on real-world mobile game performance data.
library;
import 'debug_logger.dart';

import 'dart:io';
import 'package:flutter/foundation.dart';

/// Platform-specific optimization profiles
enum PlatformProfile {
  ios,
  android,
  unknown,
}

/// Initialization strategies based on platform capabilities
enum InitializationStrategy {
  immediate,    // iOS: Fast initialization, plenty of resources
  background,   // Android: Slower initialization, resource-conscious
  minimal,      // Low-end devices: Bare minimum initialization
}

/// Performance tier based on platform and device capabilities
enum PerformanceTier {
  high,    // iOS, high-end Android
  medium,  // Mid-range Android
  low,     // Low-end Android, emulators
}

/// 🎯 Platform Optimizer - The brain of cross-platform performance
class PlatformOptimizer {
  static final PlatformOptimizer _instance = PlatformOptimizer._internal();
  factory PlatformOptimizer() => _instance;
  PlatformOptimizer._internal();

  // Platform detection
  static PlatformProfile get currentPlatform {
    if (Platform.isIOS) return PlatformProfile.ios;
    if (Platform.isAndroid) return PlatformProfile.android;
    return PlatformProfile.unknown;
  }

  static bool get isIOS => currentPlatform == PlatformProfile.ios;
  static bool get isAndroid => currentPlatform == PlatformProfile.android;
  static bool get isEmulator => !kReleaseMode; // Simplified detection

  // Performance tier detection (can be enhanced with device info)
  static PerformanceTier get performanceTier {
    if (isIOS) return PerformanceTier.high; // iOS generally performs better
    if (isEmulator) return PerformanceTier.low; // Emulators are slower
    return PerformanceTier.medium; // Default for Android
  }

  /// 🎵 AUDIO OPTIMIZATIONS
  static AudioOptimizations get audio => AudioOptimizations._();

  /// 🎮 GAME PERFORMANCE OPTIMIZATIONS  
  static GameOptimizations get game => GameOptimizations._();

  /// 🚀 INITIALIZATION OPTIMIZATIONS
  static InitializationOptimizations get initialization => InitializationOptimizations._();

  /// 🎨 VISUAL OPTIMIZATIONS
  static VisualOptimizations get visual => VisualOptimizations._();
}

/// 🎵 Audio-specific optimizations
class AudioOptimizations {
  AudioOptimizations._();

  /// Optimal audio pool size based on platform
  int get sfxPoolSize {
    if (PlatformOptimizer.isAndroid) {
      // CRITICAL FIX: Reduced Android pool sizes to prevent MediaPlayer crashes
      switch (PlatformOptimizer.performanceTier) {
        case PerformanceTier.high:
          return 4; // REDUCED: Android MediaPlayer has stability issues with large pools
        case PerformanceTier.medium:
          return 3; // REDUCED: Conservative approach for stability
        case PerformanceTier.low:
          return 2; // REDUCED: Minimal pool for crash prevention
      }
    } else {
      // iOS - keep existing optimized values (iOS is more stable)
      switch (PlatformOptimizer.performanceTier) {
        case PerformanceTier.high:
          return 12; // iOS can handle more concurrent audio
        case PerformanceTier.medium:
          return 8; 
        case PerformanceTier.low:
          return 6;
      }
    }
  }

  /// Audio timeout for releasing players
  Duration get playerTimeout {
    return PlatformOptimizer.isAndroid 
        ? const Duration(milliseconds: 500)  // Faster cleanup on Android
        : const Duration(milliseconds: 1000); // iOS can handle longer
  }

  /// Should use audio focus management
  bool get useAudioFocus => PlatformOptimizer.isAndroid;

  /// Audio buffer size optimization
  int get bufferSize {
    return PlatformOptimizer.isIOS ? 1024 : 512; // iOS handles larger buffers better
  }

  /// Maximum concurrent sound effects
  int get maxConcurrentSfx {
    switch (PlatformOptimizer.performanceTier) {
      case PerformanceTier.high: return 8;
      case PerformanceTier.medium: return 4;
      case PerformanceTier.low: return 2;
    }
  }
}

/// 🎮 Game performance optimizations
class GameOptimizations {
  GameOptimizations._();

  /// Maximum particles based on platform
  int get maxParticles {
    switch (PlatformOptimizer.performanceTier) {
      case PerformanceTier.high: return 150;  // iOS can handle more
      case PerformanceTier.medium: return 75; // Standard Android
      case PerformanceTier.low: return 30;    // Emulators/low-end
    }
  }

  /// Frame rate target
  int get targetFPS {
    return PlatformOptimizer.isIOS ? 60 : 45; // iOS targets higher FPS
  }

  /// Use high-quality effects
  bool get useHighQualityEffects {
    return PlatformOptimizer.performanceTier == PerformanceTier.high;
  }

  /// Collision detection precision
  double get collisionPrecision {
    switch (PlatformOptimizer.performanceTier) {
      case PerformanceTier.high: return 1.0;   // Full precision
      case PerformanceTier.medium: return 0.8; // Slightly reduced
      case PerformanceTier.low: return 0.6;    // Reduced for performance
    }
  }

  /// Update frequency for non-critical systems
  Duration get backgroundUpdateInterval {
    return PlatformOptimizer.isAndroid 
        ? const Duration(milliseconds: 100) // More frequent on Android
        : const Duration(milliseconds: 50);  // Less frequent on iOS
  }
}

/// 🚀 Initialization optimizations
class InitializationOptimizations {
  InitializationOptimizations._();

  /// Initialization strategy based on platform
  InitializationStrategy get strategy {
    if (PlatformOptimizer.isIOS) return InitializationStrategy.immediate;
    if (PlatformOptimizer.isEmulator) return InitializationStrategy.minimal;
    return InitializationStrategy.background; // Android default
  }

  /// Systems to initialize immediately vs background
  List<String> get criticalSystems => [
    'PlayerIdentity',
    'AudioSettings',
    'GameEngine',
  ];

  List<String> get backgroundSystems => [
    'Inventory',
    'Lives', 
    'Leaderboards',
    'Monetization',
    'RemoteConfig',
    'Analytics',
  ];

  /// Initialization batch size (how many systems to init at once)
  int get batchSize {
    switch (PlatformOptimizer.performanceTier) {
      case PerformanceTier.high: return 3;  // iOS can handle more
      case PerformanceTier.medium: return 2; // Standard Android
      case PerformanceTier.low: return 1;    // One at a time for emulators
    }
  }

  /// Delay between initialization batches
  Duration get batchDelay {
    return PlatformOptimizer.isAndroid 
        ? const Duration(milliseconds: 50)  // Longer delay on Android
        : const Duration(milliseconds: 20); // Shorter on iOS
  }
}

/// 🎨 Visual optimizations
class VisualOptimizations {
  VisualOptimizations._();

  /// Texture quality multiplier
  double get textureQuality {
    switch (PlatformOptimizer.performanceTier) {
      case PerformanceTier.high: return 1.0;   // Full quality
      case PerformanceTier.medium: return 0.8; // Slightly reduced
      case PerformanceTier.low: return 0.6;    // Reduced for performance
    }
  }

  /// Use anti-aliasing
  bool get useAntiAliasing {
    return PlatformOptimizer.performanceTier != PerformanceTier.low;
  }

  /// Shadow quality
  int get shadowQuality {
    switch (PlatformOptimizer.performanceTier) {
      case PerformanceTier.high: return 3;  // High quality shadows
      case PerformanceTier.medium: return 2; // Medium quality
      case PerformanceTier.low: return 0;    // No shadows
    }
  }

  /// Animation smoothness (interpolation steps)
  int get animationSteps {
    return PlatformOptimizer.isIOS ? 60 : 30; // iOS can handle smoother animations
  }
}

/// 📊 Platform-specific debugging and metrics
class PlatformMetrics {
  static void logPlatformInfo() {
    final platform = PlatformOptimizer.currentPlatform;
    final tier = PlatformOptimizer.performanceTier;
    final audio = PlatformOptimizer.audio;
    final game = PlatformOptimizer.game;
    
    safePrint('🎯 PLATFORM OPTIMIZER INITIALIZED');
    safePrint('📱 Platform: $platform');
    safePrint('⚡ Performance Tier: $tier');
    safePrint('🎵 Audio Pool Size: ${audio.sfxPoolSize}');
    safePrint('🎮 Max Particles: ${game.maxParticles}');
    safePrint('🎯 Target FPS: ${game.targetFPS}');
    safePrint('🚀 Init Strategy: ${PlatformOptimizer.initialization.strategy}');
  }
}
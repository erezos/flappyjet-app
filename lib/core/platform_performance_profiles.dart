/// 🎯 Platform Performance Profiles - Tailored Settings for Optimal Performance
/// 
/// This system provides detailed performance configurations for different
/// platforms and device tiers, ensuring smooth gameplay across all devices.
library;
import 'debug_logger.dart';

import 'platform_optimizer.dart';

/// Performance profile configuration for different aspects of the game
class PerformanceProfile {
  final String name;
  final PlatformProfile platform;
  final PerformanceTier tier;
  
  // Audio settings
  final int audioPoolSize;
  final Duration audioTimeout;
  final int maxConcurrentAudio;
  final bool useAudioFocus;
  
  // Visual settings
  final int maxParticles;
  final double textureQuality;
  final bool useAntiAliasing;
  final int shadowQuality;
  final int animationSteps;
  
  // Game performance
  final int targetFPS;
  final double collisionPrecision;
  final Duration backgroundUpdateInterval;
  final int maxObstacles;
  
  // Initialization settings
  final InitializationStrategy initStrategy;
  final int initBatchSize;
  final Duration initBatchDelay;
  final List<String> criticalSystems;
  final List<String> backgroundSystems;
  
  // Memory management
  final int maxCachedAssets;
  final Duration assetCacheTimeout;
  final bool useAssetPreloading;
  final int gcThreshold;

  const PerformanceProfile({
    required this.name,
    required this.platform,
    required this.tier,
    required this.audioPoolSize,
    required this.audioTimeout,
    required this.maxConcurrentAudio,
    required this.useAudioFocus,
    required this.maxParticles,
    required this.textureQuality,
    required this.useAntiAliasing,
    required this.shadowQuality,
    required this.animationSteps,
    required this.targetFPS,
    required this.collisionPrecision,
    required this.backgroundUpdateInterval,
    required this.maxObstacles,
    required this.initStrategy,
    required this.initBatchSize,
    required this.initBatchDelay,
    required this.criticalSystems,
    required this.backgroundSystems,
    required this.maxCachedAssets,
    required this.assetCacheTimeout,
    required this.useAssetPreloading,
    required this.gcThreshold,
  });
}

/// 📱 Platform-specific performance profiles
class PlatformPerformanceProfiles {
  static final PlatformPerformanceProfiles _instance = PlatformPerformanceProfiles._internal();
  factory PlatformPerformanceProfiles() => _instance;
  PlatformPerformanceProfiles._internal();

  /// Get the optimal performance profile for the current platform
  static PerformanceProfile get current {
    final platform = PlatformOptimizer.currentPlatform;
    final tier = PlatformOptimizer.performanceTier;
    
    switch (platform) {
      case PlatformProfile.ios:
        return _getIOSProfile(tier);
      case PlatformProfile.android:
        return _getAndroidProfile(tier);
      case PlatformProfile.unknown:
        return _getDefaultProfile();
    }
  }

  /// 🍎 iOS Performance Profiles
  static PerformanceProfile _getIOSProfile(PerformanceTier tier) {
    switch (tier) {
      case PerformanceTier.high:
        return const PerformanceProfile(
          name: 'iOS High Performance',
          platform: PlatformProfile.ios,
          tier: PerformanceTier.high,
          
          // Audio - iOS handles audio excellently
          audioPoolSize: 8,
          audioTimeout: Duration(milliseconds: 1000),
          maxConcurrentAudio: 12,
          useAudioFocus: false, // iOS manages this automatically
          
          // Visual - iOS can handle high-quality graphics
          maxParticles: 200,
          textureQuality: 1.0,
          useAntiAliasing: true,
          shadowQuality: 3,
          animationSteps: 60,
          
          // Game performance - Target high FPS on iOS
          targetFPS: 60,
          collisionPrecision: 1.0,
          backgroundUpdateInterval: Duration(milliseconds: 16), // 60 FPS
          maxObstacles: 10,
          
          // Initialization - iOS can handle immediate loading
          initStrategy: InitializationStrategy.immediate,
          initBatchSize: 4,
          initBatchDelay: Duration(milliseconds: 10),
          criticalSystems: ['PlayerIdentity', 'AudioSettings', 'GameEngine', 'AssetRegistry'],
          backgroundSystems: ['Inventory', 'Lives', 'Leaderboards', 'Monetization'],
          
          // Memory - iOS has good memory management
          maxCachedAssets: 100,
          assetCacheTimeout: Duration(minutes: 10),
          useAssetPreloading: true,
          gcThreshold: 50, // MB before triggering GC suggestions
        );
        
      case PerformanceTier.medium:
      case PerformanceTier.low:
        return const PerformanceProfile(
          name: 'iOS Standard Performance',
          platform: PlatformProfile.ios,
          tier: PerformanceTier.medium,
          
          // Audio - Slightly reduced for older iOS devices
          audioPoolSize: 6,
          audioTimeout: Duration(milliseconds: 800),
          maxConcurrentAudio: 8,
          useAudioFocus: false,
          
          // Visual - Good quality but not maximum
          maxParticles: 150,
          textureQuality: 0.9,
          useAntiAliasing: true,
          shadowQuality: 2,
          animationSteps: 45,
          
          // Game performance
          targetFPS: 45,
          collisionPrecision: 0.9,
          backgroundUpdateInterval: Duration(milliseconds: 22), // ~45 FPS
          maxObstacles: 8,
          
          // Initialization
          initStrategy: InitializationStrategy.immediate,
          initBatchSize: 3,
          initBatchDelay: Duration(milliseconds: 20),
          criticalSystems: ['PlayerIdentity', 'AudioSettings', 'GameEngine'],
          backgroundSystems: ['Inventory', 'Lives', 'Leaderboards', 'Monetization', 'AssetRegistry'],
          
          // Memory
          maxCachedAssets: 75,
          assetCacheTimeout: Duration(minutes: 5),
          useAssetPreloading: true,
          gcThreshold: 30,
        );
    }
  }

  /// 🤖 Android Performance Profiles
  static PerformanceProfile _getAndroidProfile(PerformanceTier tier) {
    switch (tier) {
      case PerformanceTier.high:
        return const PerformanceProfile(
          name: 'Android High Performance',
          platform: PlatformProfile.android,
          tier: PerformanceTier.high,
          
          // Audio - Android needs careful audio management
          audioPoolSize: 6,
          audioTimeout: Duration(milliseconds: 600),
          maxConcurrentAudio: 8,
          useAudioFocus: true, // Critical for Android
          
          // Visual - High-end Android can handle good graphics
          maxParticles: 120,
          textureQuality: 0.9,
          useAntiAliasing: true,
          shadowQuality: 2,
          animationSteps: 45,
          
          // Game performance - Conservative FPS target
          targetFPS: 45,
          collisionPrecision: 0.9,
          backgroundUpdateInterval: Duration(milliseconds: 22),
          maxObstacles: 8,
          
          // Initialization - Background loading for Android
          initStrategy: InitializationStrategy.background,
          initBatchSize: 2,
          initBatchDelay: Duration(milliseconds: 50),
          criticalSystems: ['PlayerIdentity', 'AudioSettings'],
          backgroundSystems: ['GameEngine', 'Inventory', 'Lives', 'Leaderboards', 'Monetization', 'AssetRegistry'],
          
          // Memory - More conservative on Android
          maxCachedAssets: 60,
          assetCacheTimeout: Duration(minutes: 3),
          useAssetPreloading: false, // Load on demand
          gcThreshold: 25,
        );
        
      case PerformanceTier.medium:
        return const PerformanceProfile(
          name: 'Android Medium Performance',
          platform: PlatformProfile.android,
          tier: PerformanceTier.medium,
          
          // Audio - Reduced for mid-range devices
          audioPoolSize: 4,
          audioTimeout: Duration(milliseconds: 500),
          maxConcurrentAudio: 6,
          useAudioFocus: true,
          
          // Visual - Balanced settings
          maxParticles: 80,
          textureQuality: 0.8,
          useAntiAliasing: false,
          shadowQuality: 1,
          animationSteps: 30,
          
          // Game performance
          targetFPS: 30,
          collisionPrecision: 0.8,
          backgroundUpdateInterval: Duration(milliseconds: 33), // 30 FPS
          maxObstacles: 6,
          
          // Initialization
          initStrategy: InitializationStrategy.background,
          initBatchSize: 2,
          initBatchDelay: Duration(milliseconds: 75),
          criticalSystems: ['PlayerIdentity', 'AudioSettings'],
          backgroundSystems: ['GameEngine', 'Inventory', 'Lives', 'Leaderboards', 'Monetization', 'AssetRegistry'],
          
          // Memory
          maxCachedAssets: 40,
          assetCacheTimeout: Duration(minutes: 2),
          useAssetPreloading: false,
          gcThreshold: 20,
        );
        
      case PerformanceTier.low:
        return const PerformanceProfile(
          name: 'Android Low Performance (Emulator/Low-end)',
          platform: PlatformProfile.android,
          tier: PerformanceTier.low,
          
          // Audio - Increased pool size to prevent exhaustion
          audioPoolSize: 4,
          audioTimeout: Duration(milliseconds: 500),
          maxConcurrentAudio: 6,
          useAudioFocus: true,
          
          // Visual - Minimal quality for performance
          maxParticles: 30,
          textureQuality: 0.6,
          useAntiAliasing: false,
          shadowQuality: 0,
          animationSteps: 15,
          
          // Game performance - Focus on stability over smoothness
          targetFPS: 24,
          collisionPrecision: 0.7,
          backgroundUpdateInterval: Duration(milliseconds: 50), // 20 FPS background
          maxObstacles: 4,
          
          // Initialization - Minimal loading
          initStrategy: InitializationStrategy.minimal,
          initBatchSize: 1,
          initBatchDelay: Duration(milliseconds: 100),
          criticalSystems: ['PlayerIdentity'],
          backgroundSystems: ['AudioSettings', 'GameEngine', 'Inventory', 'Lives', 'Leaderboards', 'Monetization', 'AssetRegistry'],
          
          // Memory - Very conservative
          maxCachedAssets: 20,
          assetCacheTimeout: Duration(minutes: 1),
          useAssetPreloading: false,
          gcThreshold: 10,
        );
    }
  }

  /// 🔧 Default/Unknown Platform Profile
  static PerformanceProfile _getDefaultProfile() {
    return const PerformanceProfile(
      name: 'Default Performance',
      platform: PlatformProfile.unknown,
      tier: PerformanceTier.medium,
      
      // Conservative defaults
      audioPoolSize: 4,
      audioTimeout: Duration(milliseconds: 500),
      maxConcurrentAudio: 6,
      useAudioFocus: false,
      
      maxParticles: 60,
      textureQuality: 0.8,
      useAntiAliasing: false,
      shadowQuality: 1,
      animationSteps: 30,
      
      targetFPS: 30,
      collisionPrecision: 0.8,
      backgroundUpdateInterval: Duration(milliseconds: 33),
      maxObstacles: 6,
      
      initStrategy: InitializationStrategy.background,
      initBatchSize: 2,
      initBatchDelay: Duration(milliseconds: 50),
      criticalSystems: ['PlayerIdentity', 'AudioSettings'],
      backgroundSystems: ['GameEngine', 'Inventory', 'Lives', 'Leaderboards'],
      
      maxCachedAssets: 30,
      assetCacheTimeout: Duration(minutes: 2),
      useAssetPreloading: false,
      gcThreshold: 15,
    );
  }

  /// 📊 Get performance recommendations based on current profile
  static Map<String, dynamic> getPerformanceRecommendations() {
    final profile = current;
    
    return {
      'profile_name': profile.name,
      'platform': profile.platform.toString(),
      'tier': profile.tier.toString(),
      'recommendations': {
        'audio': {
          'pool_size': profile.audioPoolSize,
          'concurrent_limit': profile.maxConcurrentAudio,
          'use_focus_management': profile.useAudioFocus,
        },
        'visual': {
          'max_particles': profile.maxParticles,
          'texture_quality': '${(profile.textureQuality * 100).round()}%',
          'anti_aliasing': profile.useAntiAliasing,
          'shadow_quality': profile.shadowQuality,
        },
        'performance': {
          'target_fps': profile.targetFPS,
          'collision_precision': '${(profile.collisionPrecision * 100).round()}%',
          'max_obstacles': profile.maxObstacles,
        },
        'memory': {
          'max_cached_assets': profile.maxCachedAssets,
          'preload_assets': profile.useAssetPreloading,
          'gc_threshold_mb': profile.gcThreshold,
        },
      },
    };
  }

  /// 🔧 Apply performance profile to game systems
  static void applyToGameSystems() {
    final profile = current;
    safePrint('🎯 Applying performance profile: ${profile.name}');
    safePrint('📊 Target FPS: ${profile.targetFPS}');
    safePrint('🎵 Audio Pool: ${profile.audioPoolSize}');
    safePrint('✨ Max Particles: ${profile.maxParticles}');
    safePrint('🎨 Texture Quality: ${(profile.textureQuality * 100).round()}%');
  }
}
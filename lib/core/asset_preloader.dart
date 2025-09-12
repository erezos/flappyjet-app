/// 🚀 ASSET PRELOADER - Optimizes asset loading for better performance
/// Preloads critical assets and manages loading states for smooth user experience
library;
import 'debug_logger.dart';

import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import '../game/systems/lightweight_performance_timer.dart';

/// Asset loading priority levels
enum AssetPriority {
  critical,    // Must load before game starts (jet, obstacles)
  important,   // Should load early (backgrounds, UI elements)
  optional,    // Can load in background (achievements, themes)
}

/// Asset loading state
enum AssetLoadState {
  notLoaded,
  loading,
  loaded,
  failed,
}

/// Individual asset information
class AssetInfo {
  final String path;
  final AssetPriority priority;
  final int expectedSizeBytes;
  final String category;

  AssetInfo({
    required this.path,
    required this.priority,
    this.expectedSizeBytes = 0,
    this.category = 'general',
  });
}

/// Asset loading result
class AssetLoadResult {
  final AssetInfo asset;
  final AssetLoadState state;
  final double loadTimeMs;
  final String? error;

  const AssetLoadResult({
    required this.asset,
    required this.state,
    required this.loadTimeMs,
    this.error,
  });
}

/// 🚀 ASSET PRELOADER - Manages intelligent asset loading
class AssetPreloader {
  static final AssetPreloader _instance = AssetPreloader._internal();
  factory AssetPreloader() => _instance;
  AssetPreloader._internal();

  final LightweightPerformanceTimer _performanceTimer = LightweightPerformanceTimer();

  // Asset cache
  final Map<String, ui.Image> _imageCache = {};
  final Map<String, ByteData> _byteDataCache = {};
  final Map<String, AssetLoadResult> _loadResults = {};

  // Loading state
  bool _isInitialized = false;
  double _loadingProgress = 0.0;
  String _currentLoadingAsset = '';

  // Asset definitions
  late final List<AssetInfo> _criticalAssets;
  late final List<AssetInfo> _importantAssets;
  late final List<AssetInfo> _optionalAssets;

  /// Initialize asset preloader with asset lists
  Future<void> initialize({
    List<AssetInfo>? criticalAssets,
    List<AssetInfo>? importantAssets,
    List<AssetInfo>? optionalAssets,
  }) async {
    if (_isInitialized) return;

    _setupDefaultAssets();
    _performanceTimer.startTimer('asset_preloader_init');

    try {
      // Preload critical assets first (blocking)
      await _preloadAssetsByPriority(AssetPriority.critical);

      // Start loading important assets (non-blocking)
      _preloadAssetsByPriority(AssetPriority.important).then((_) {
        safePrint('🚀 Important assets loaded');
      });

      // Queue optional assets for background loading
      Timer(const Duration(seconds: 2), () {
        _preloadAssetsByPriority(AssetPriority.optional).then((_) {
          safePrint('🚀 Optional assets loaded');
        });
      });

      _isInitialized = true;
      _performanceTimer.stopTimer('asset_preloader_init');

      safePrint('🚀 AssetPreloader initialized - ${getLoadedAssetCount()} assets ready');
    } catch (e) {
      safePrint('❌ AssetPreloader initialization failed: $e');
      _performanceTimer.stopTimer('asset_preloader_init');
    }
  }

  /// Get loading progress (0.0 to 1.0)
  double get loadingProgress => _loadingProgress;

  /// Get current loading asset name
  String get currentLoadingAsset => _currentLoadingAsset;

  /// Check if critical assets are loaded
  bool get isReady => _isInitialized && _areCriticalAssetsLoaded();

  /// Get total asset count
  int get totalAssetCount => _criticalAssets.length + _importantAssets.length + _optionalAssets.length;

  /// Get loaded asset count
  int getLoadedAssetCount() {
    return _loadResults.values.where((result) => result.state == AssetLoadState.loaded).length;
  }

  /// Preload assets by priority level
  Future<void> _preloadAssetsByPriority(AssetPriority priority) async {
    final assets = _getAssetsByPriority(priority);

    if (assets.isEmpty) return;

    safePrint('🚀 Preloading ${assets.length} ${priority.name} assets');

    final futures = assets.map((asset) => _loadAsset(asset));
    await Future.wait(futures);

    safePrint('✅ ${priority.name} assets preloaded successfully');
  }

  /// Load individual asset
  Future<AssetLoadResult> _loadAsset(AssetInfo asset) async {
    if (_loadResults.containsKey(asset.path)) {
      return _loadResults[asset.path]!;
    }

    _performanceTimer.startTimer('asset_load_${asset.path}');
    _currentLoadingAsset = asset.path;

    final stopwatch = Stopwatch()..start();

    try {
      // Load asset based on type
      if (asset.path.endsWith('.png') || asset.path.endsWith('.jpg') || asset.path.endsWith('.jpeg')) {
        await _loadImageAsset(asset);
      } else {
        await _loadByteDataAsset(asset);
      }

      stopwatch.stop();
      final loadTimeMs = stopwatch.elapsedMilliseconds.toDouble();

      final result = AssetLoadResult(
        asset: asset,
        state: AssetLoadState.loaded,
        loadTimeMs: loadTimeMs,
      );

      _loadResults[asset.path] = result;
      _performanceTimer.recordAssetLoad(
        asset.path,
        loadTimeMs.toInt(),
        true,
      );

      safePrint('✅ Asset loaded: ${asset.path} (${loadTimeMs.toStringAsFixed(0)}ms)');
      return result;

    } catch (e) {
      stopwatch.stop();
      final loadTimeMs = stopwatch.elapsedMilliseconds.toDouble();

      final result = AssetLoadResult(
        asset: asset,
        state: AssetLoadState.failed,
        loadTimeMs: loadTimeMs,
        error: e.toString(),
      );

      _loadResults[asset.path] = result;
      safePrint('❌ Asset failed: ${asset.path} - $e');

      return result;
    } finally {
      _performanceTimer.stopTimer('asset_load_${asset.path}');
      _updateLoadingProgress();
    }
  }

  /// Load image asset
  Future<void> _loadImageAsset(AssetInfo asset) async {
    final byteData = await rootBundle.load(asset.path);
    final codec = await ui.instantiateImageCodec(byteData.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    _imageCache[asset.path] = frame.image;
  }

  /// Load byte data asset
  Future<void> _loadByteDataAsset(AssetInfo asset) async {
    final byteData = await rootBundle.load(asset.path);
    _byteDataCache[asset.path] = byteData;
  }

  /// Get cached image
  ui.Image? getCachedImage(String path) {
    return _imageCache[path];
  }

  /// Get cached byte data
  ByteData? getCachedByteData(String path) {
    return _byteDataCache[path];
  }

  /// Check if asset is loaded
  bool isAssetLoaded(String path) {
    final result = _loadResults[path];
    return result != null && result.state == AssetLoadState.loaded;
  }

  /// Get asset load result
  AssetLoadResult? getAssetLoadResult(String path) {
    return _loadResults[path];
  }

  /// Force reload an asset
  Future<bool> reloadAsset(String path) async {
    _loadResults.remove(path);
    _imageCache.remove(path);
    _byteDataCache.remove(path);

    final asset = _findAssetByPath(path);
    if (asset != null) {
      final result = await _loadAsset(asset);
      return result.state == AssetLoadState.loaded;
    }

    return false;
  }

  /// Preload assets for specific game mode
  Future<void> preloadForGameMode(String gameMode) async {
    safePrint('🎮 Preloading assets for game mode: $gameMode');

    final modeSpecificAssets = _getAssetsForGameMode(gameMode);
    final futures = modeSpecificAssets.map((asset) => _loadAsset(asset));
    await Future.wait(futures);

    safePrint('🎮 Game mode assets preloaded: $gameMode');
  }

  /// Clear cache and force reload
  Future<void> clearCache() async {
    _imageCache.clear();
    _byteDataCache.clear();
    _loadResults.clear();
    _loadingProgress = 0.0;

    safePrint('🧹 Asset cache cleared');
  }

  /// Get performance metrics
  Map<String, dynamic> getPerformanceMetrics() {
    final totalAssets = totalAssetCount;
    final loadedAssets = getLoadedAssetCount();
    final failedAssets = _loadResults.values.where((r) => r.state == AssetLoadState.failed).length;

    final loadTimes = _loadResults.values
        .where((r) => r.state == AssetLoadState.loaded)
        .map((r) => r.loadTimeMs);

    final avgLoadTime = loadTimes.isEmpty ? 0.0 : loadTimes.reduce((a, b) => a + b) / loadTimes.length;
    final maxLoadTime = loadTimes.isEmpty ? 0.0 : loadTimes.reduce((a, b) => a > b ? a : b);

    return {
      'total_assets': totalAssets,
      'loaded_assets': loadedAssets,
      'failed_assets': failedAssets,
      'loading_progress': _loadingProgress,
      'average_load_time_ms': avgLoadTime,
      'max_load_time_ms': maxLoadTime,
      'cache_size_mb': _calculateCacheSizeMB(),
      'assets_by_priority': {
        'critical': _criticalAssets.length,
        'important': _importantAssets.length,
        'optional': _optionalAssets.length,
      },
    };
  }

  /// Export loading report
  String exportLoadingReport() {
    final buffer = StringBuffer();
    buffer.writeln('🚀 ASSET LOADING REPORT');
    buffer.writeln('Generated: ${DateTime.now()}');
    buffer.writeln('');

    final metrics = getPerformanceMetrics();
    buffer.writeln('📊 SUMMARY:');
    buffer.writeln('  Total Assets: ${metrics['total_assets']}');
    buffer.writeln('  Loaded: ${metrics['loaded_assets']}');
    buffer.writeln('  Failed: ${metrics['failed_assets']}');
    buffer.writeln('  Progress: ${(metrics['loading_progress'] * 100).toStringAsFixed(1)}%');
    buffer.writeln('  Avg Load Time: ${metrics['average_load_time_ms'].toStringAsFixed(2)}ms');
    buffer.writeln('  Cache Size: ${metrics['cache_size_mb'].toStringAsFixed(2)}MB');
    buffer.writeln('');

    buffer.writeln('📋 CRITICAL ASSETS:');
    _exportAssetsByPriority(buffer, AssetPriority.critical);

    buffer.writeln('📋 IMPORTANT ASSETS:');
    _exportAssetsByPriority(buffer, AssetPriority.important);

    buffer.writeln('📋 OPTIONAL ASSETS:');
    _exportAssetsByPriority(buffer, AssetPriority.optional);

    return buffer.toString();
  }

  // Private methods

  void _setupDefaultAssets() {
    // Critical assets (must load before game starts)
    _criticalAssets = [
      AssetInfo(path: 'assets/images/jets/sky_jet.png', priority: AssetPriority.critical, expectedSizeBytes: 50000, category: 'jet'),
      AssetInfo(path: 'assets/images/obstacles/pipe.png', priority: AssetPriority.critical, expectedSizeBytes: 30000, category: 'obstacle'),
      AssetInfo(path: 'assets/images/obstacles/pipe_top.png', priority: AssetPriority.critical, expectedSizeBytes: 25000, category: 'obstacle'),
      AssetInfo(path: 'assets/images/backgrounds/sky_background.png', priority: AssetPriority.critical, expectedSizeBytes: 150000, category: 'background'),
    ];

    // Important assets (should load early)
    _importantAssets = [
      AssetInfo(path: 'assets/images/jets/green_lightning.png', priority: AssetPriority.important, expectedSizeBytes: 45000, category: 'jet'),
      AssetInfo(path: 'assets/images/jets/blue_falcon.png', priority: AssetPriority.important, expectedSizeBytes: 45000, category: 'jet'),
      AssetInfo(path: 'assets/images/effects/particle.png', priority: AssetPriority.important, expectedSizeBytes: 5000, category: 'effect'),
      AssetInfo(path: 'assets/images/homepage/flappy_jet_title.png', priority: AssetPriority.important, expectedSizeBytes: 80000, category: 'ui'),
    ];

    // Optional assets (load in background)
    _optionalAssets = [
      AssetInfo(path: 'assets/images/jets/purple_comet.png', priority: AssetPriority.optional, expectedSizeBytes: 50000, category: 'jet'),
      AssetInfo(path: 'assets/images/jets/red_phoenix.png', priority: AssetPriority.optional, expectedSizeBytes: 50000, category: 'jet'),
      AssetInfo(path: 'assets/images/achievements/first_score.png', priority: AssetPriority.optional, expectedSizeBytes: 15000, category: 'achievement'),
      AssetInfo(path: 'assets/images/achievements/score_100.png', priority: AssetPriority.optional, expectedSizeBytes: 15000, category: 'achievement'),
    ];
  }

  List<AssetInfo> _getAssetsByPriority(AssetPriority priority) {
    switch (priority) {
      case AssetPriority.critical:
        return _criticalAssets;
      case AssetPriority.important:
        return _importantAssets;
      case AssetPriority.optional:
        return _optionalAssets;
    }
  }

  bool _areCriticalAssetsLoaded() {
    return _criticalAssets.every((asset) => isAssetLoaded(asset.path));
  }

  AssetInfo? _findAssetByPath(String path) {
    return [..._criticalAssets, ..._importantAssets, ..._optionalAssets]
        .cast<AssetInfo?>()
        .firstWhere((asset) => asset?.path == path, orElse: () => null);
  }

  List<AssetInfo> _getAssetsForGameMode(String gameMode) {
    // Return assets specific to game mode
    // This could be expanded based on game mode requirements
    return _criticalAssets; // Default to critical assets
  }

  void _updateLoadingProgress() {
    final totalAssets = totalAssetCount;
    final loadedAssets = getLoadedAssetCount();

    _loadingProgress = totalAssets > 0 ? loadedAssets / totalAssets : 0.0;
  }

  double _calculateCacheSizeMB() {
    int totalBytes = 0;

    // Calculate image cache size (rough estimate)
    totalBytes += _imageCache.length * 100000; // ~100KB per image

    // Calculate byte data cache size
    for (final byteData in _byteDataCache.values) {
      totalBytes += byteData.lengthInBytes;
    }

    return totalBytes / (1024 * 1024); // Convert to MB
  }

  void _exportAssetsByPriority(StringBuffer buffer, AssetPriority priority) {
    final assets = _getAssetsByPriority(priority);
    final loaded = assets.where((asset) => isAssetLoaded(asset.path)).length;
    final failed = assets.where((asset) => _loadResults[asset.path]?.state == AssetLoadState.failed).length;

    buffer.writeln('  Priority: ${priority.name}');
    buffer.writeln('  Loaded: $loaded/${assets.length}');
    buffer.writeln('  Failed: $failed');
    buffer.writeln('');

    for (final asset in assets) {
      final result = _loadResults[asset.path];
      if (result != null) {
        final status = result.state == AssetLoadState.loaded ? '✅' :
                      result.state == AssetLoadState.failed ? '❌' : '⏳';
        buffer.writeln('    $status ${asset.path} (${result.loadTimeMs.toStringAsFixed(0)}ms)');
      } else {
        buffer.writeln('    ⏳ ${asset.path} (not loaded)');
      }
    }
    buffer.writeln('');
  }
}
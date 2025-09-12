/// 📦 ASYNC ASSET LOADER - Prevents main thread blocking during asset loading
/// Fixes frame drops and "Skipped frames" issues during gameplay
library;
import '../../core/debug_logger.dart';

import 'dart:async';
import 'dart:isolate';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

/// Asset loading priority levels
enum AssetPriority {
  critical,  // Must be loaded immediately (UI, core game assets)
  high,      // Should be loaded soon (common game objects)
  medium,    // Can be loaded when convenient (effects, particles)
  low,       // Background loading (optional assets, future levels)
}

/// Asset loading request
class AssetLoadRequest {
  final String assetPath;
  final AssetPriority priority;
  final String category;
  final DateTime requestTime;
  final Completer<bool> completer;
  
  AssetLoadRequest({
    required this.assetPath,
    required this.priority,
    required this.category,
  }) : requestTime = DateTime.now(),
       completer = Completer<bool>();

  Future<bool> get future => completer.future;
}

/// Asset cache entry with metadata
class CachedAsset {
  final String assetPath;
  final Uint8List? data;
  final ui.Image? image;
  final DateTime loadTime;
  final int accessCount;
  final DateTime lastAccessed;
  final int sizeBytes;
  
  CachedAsset({
    required this.assetPath,
    this.data,
    this.image,
    required this.loadTime,
    this.accessCount = 0,
    DateTime? lastAccessed,
    this.sizeBytes = 0,
  }) : lastAccessed = lastAccessed ?? DateTime.now();

  /// Create copy with updated access info
  CachedAsset copyWithAccess() => CachedAsset(
    assetPath: assetPath,
    data: data,
    image: image,
    loadTime: loadTime,
    accessCount: accessCount + 1,
    lastAccessed: DateTime.now(),
    sizeBytes: sizeBytes,
  );
}

/// 📦 ASYNC ASSET LOADER - Background asset loading system
class AsyncAssetLoader {
  static AsyncAssetLoader? _instance;
  static AsyncAssetLoader get instance => _instance ??= AsyncAssetLoader._();
  
  AsyncAssetLoader._();

  // Asset cache and loading queues
  final Map<String, CachedAsset> _cache = {};
  final Map<AssetPriority, List<AssetLoadRequest>> _loadQueues = {
    AssetPriority.critical: [],
    AssetPriority.high: [],
    AssetPriority.medium: [],
    AssetPriority.low: [],
  };
  
  // Loading state
  bool _isInitialized = false;
  Timer? _loadingTimer;
  Isolate? _loadingIsolate;
  
  // Configuration
  static const int maxConcurrentLoads = 3;
  static const Duration loadingInterval = Duration(milliseconds: 16); // ~60fps
  static const Duration cacheTimeout = Duration(minutes: 10);
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB
  
  // Performance tracking
  int _totalLoadRequests = 0;
  int _cacheHits = 0;
  int _cacheMisses = 0;
  int _loadFailures = 0;
  int _currentLoadingCount = 0;
  
  /// Initialize the asset loader
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    safePrint('📦 Initializing AsyncAssetLoader...');
    
    // Start loading timer
    _loadingTimer = Timer.periodic(loadingInterval, (_) => _processLoadQueue());
    
    _isInitialized = true;
    safePrint('📦 AsyncAssetLoader initialized');
  }

  /// Load asset with priority
  Future<bool> loadAsset({
    required String assetPath,
    AssetPriority priority = AssetPriority.medium,
    String category = 'general',
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    _totalLoadRequests++;

    // Check cache first
    final cached = _cache[assetPath];
    if (cached != null) {
      _cacheHits++;
      _cache[assetPath] = cached.copyWithAccess();
      safePrint('📦 Cache hit: $assetPath');
      return true;
    }

    _cacheMisses++;

    // Create load request
    final request = AssetLoadRequest(
      assetPath: assetPath,
      priority: priority,
      category: category,
    );

    // Add to appropriate queue
    _loadQueues[priority]!.add(request);
    
    safePrint('📦 Queued for loading: $assetPath (${priority.name} priority)');
    
    return request.future;
  }

  /// Process loading queue
  void _processLoadQueue() {
    if (_currentLoadingCount >= maxConcurrentLoads) return;

    // Process queues by priority
    for (final priority in AssetPriority.values) {
      final queue = _loadQueues[priority]!;
      
      while (queue.isNotEmpty && _currentLoadingCount < maxConcurrentLoads) {
        final request = queue.removeAt(0);
        _loadAssetAsync(request);
      }
      
      if (_currentLoadingCount >= maxConcurrentLoads) break;
    }
  }

  /// Load asset asynchronously
  void _loadAssetAsync(AssetLoadRequest request) {
    _currentLoadingCount++;
    
    safePrint('📦 Loading asset: ${request.assetPath}');
    
    // Load in background
    _loadAssetInBackground(request.assetPath).then((result) {
      _currentLoadingCount--;
      
      if (result != null) {
        // Cache the result
        _cache[request.assetPath] = CachedAsset(
          assetPath: request.assetPath,
          data: result['data'] as Uint8List?,
          image: result['image'] as ui.Image?,
          loadTime: DateTime.now(),
          sizeBytes: result['size'] as int? ?? 0,
        );
        
        request.completer.complete(true);
        safePrint('📦 Loaded successfully: ${request.assetPath}');
      } else {
        _loadFailures++;
        request.completer.complete(false);
        safePrint('❌ Failed to load: ${request.assetPath}');
      }
    }).catchError((error) {
      _currentLoadingCount--;
      _loadFailures++;
      request.completer.complete(false);
      safePrint('❌ Error loading ${request.assetPath}: $error');
    });
  }

  /// Load asset in background (can be moved to isolate)
  Future<Map<String, dynamic>?> _loadAssetInBackground(String assetPath) async {
    try {
      // Load raw data
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List bytes = data.buffer.asUint8List();
      
      // If it's an image, decode it
      ui.Image? image;
      if (_isImageAsset(assetPath)) {
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        image = frame.image;
      }
      
      return {
        'data': bytes,
        'image': image,
        'size': bytes.length,
      };
    } catch (e) {
      safePrint('❌ Background loading error for $assetPath: $e');
      return null;
    }
  }

  /// Check if asset is an image
  bool _isImageAsset(String assetPath) {
    final extension = assetPath.toLowerCase().split('.').last;
    return ['png', 'jpg', 'jpeg', 'gif', 'webp'].contains(extension);
  }

  /// Get cached asset
  CachedAsset? getCachedAsset(String assetPath) {
    final cached = _cache[assetPath];
    if (cached != null) {
      _cache[assetPath] = cached.copyWithAccess();
      return cached;
    }
    return null;
  }

  /// Check if asset is loaded
  bool isAssetLoaded(String assetPath) {
    return _cache.containsKey(assetPath);
  }

  /// Preload assets by category
  Future<void> preloadCategory(String category, List<String> assetPaths, {
    AssetPriority priority = AssetPriority.high,
  }) async {
    safePrint('📦 Preloading category "$category" with ${assetPaths.length} assets');
    
    final futures = assetPaths.map((path) => loadAsset(
      assetPath: path,
      priority: priority,
      category: category,
    ));
    
    await Future.wait(futures);
    safePrint('📦 Preloading completed for category "$category"');
  }

  /// Cleanup cache
  void cleanupCache() {
    final now = DateTime.now();
    final toRemove = <String>[];
    int totalSize = 0;
    
    // Calculate current cache size and find expired entries
    for (final entry in _cache.entries) {
      totalSize += entry.value.sizeBytes;
      
      if (now.difference(entry.value.lastAccessed) > cacheTimeout) {
        toRemove.add(entry.key);
      }
    }
    
    // Remove expired entries
    for (final key in toRemove) {
      final removed = _cache.remove(key);
      if (removed != null) {
        totalSize -= removed.sizeBytes;
      }
    }
    
    // If still over limit, remove least recently used
    if (totalSize > maxCacheSize) {
      final entries = _cache.entries.toList();
      entries.sort((a, b) => a.value.lastAccessed.compareTo(b.value.lastAccessed));
      
      while (totalSize > maxCacheSize && entries.isNotEmpty) {
        final entry = entries.removeAt(0);
        _cache.remove(entry.key);
        totalSize -= entry.value.sizeBytes;
      }
    }
    
    if (toRemove.isNotEmpty) {
      safePrint('🧹 Cleaned up ${toRemove.length} cached assets');
    }
  }

  /// Get loading statistics
  Map<String, dynamic> getStats() {
    final hitRate = _totalLoadRequests > 0 
        ? (_cacheHits / _totalLoadRequests * 100).toStringAsFixed(1)
        : '0.0';
    
    final totalCacheSize = _cache.values
        .map((asset) => asset.sizeBytes)
        .fold(0, (a, b) => a + b);
    
    final queueSizes = <String, int>{};
    for (final entry in _loadQueues.entries) {
      queueSizes[entry.key.name] = entry.value.length;
    }
    
    return {
      'cached_assets': _cache.length,
      'total_cache_size_mb': (totalCacheSize / 1024 / 1024).toStringAsFixed(2),
      'total_load_requests': _totalLoadRequests,
      'cache_hits': _cacheHits,
      'cache_misses': _cacheMisses,
      'hit_rate_percent': hitRate,
      'load_failures': _loadFailures,
      'currently_loading': _currentLoadingCount,
      'queue_sizes': queueSizes,
      'is_initialized': _isInitialized,
    };
  }

  /// Dispose resources
  Future<void> dispose() async {
    _loadingTimer?.cancel();
    
    // Cancel all pending requests
    for (final queue in _loadQueues.values) {
      for (final request in queue) {
        request.completer.complete(false);
      }
      queue.clear();
    }
    
    // Clear cache
    _cache.clear();
    
    // Kill isolate if running
    _loadingIsolate?.kill();
    
    _isInitialized = false;
    safePrint('📦 AsyncAssetLoader disposed');
  }
}

/// 📦 ASSET LOADER EXTENSIONS - Convenience methods
extension AssetLoaderExtensions on AsyncAssetLoader {
  /// Load critical assets (blocks until loaded)
  Future<bool> loadCritical(String assetPath) => 
      loadAsset(assetPath: assetPath, priority: AssetPriority.critical);
  
  /// Load high priority assets
  Future<bool> loadHigh(String assetPath) => 
      loadAsset(assetPath: assetPath, priority: AssetPriority.high);
  
  /// Load medium priority assets
  Future<bool> loadMedium(String assetPath) => 
      loadAsset(assetPath: assetPath, priority: AssetPriority.medium);
  
  /// Load low priority assets
  Future<bool> loadLow(String assetPath) => 
      loadAsset(assetPath: assetPath, priority: AssetPriority.low);
  
  /// Preload game essentials
  Future<void> preloadGameEssentials(List<String> essentialAssets) =>
      preloadCategory('essentials', essentialAssets, priority: AssetPriority.critical);
  
  /// Preload UI assets
  Future<void> preloadUI(List<String> uiAssets) =>
      preloadCategory('ui', uiAssets, priority: AssetPriority.high);
  
  /// Preload effects
  Future<void> preloadEffects(List<String> effectAssets) =>
      preloadCategory('effects', effectAssets, priority: AssetPriority.medium);
}
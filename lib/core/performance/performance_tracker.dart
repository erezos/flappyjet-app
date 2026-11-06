/// 📊 Performance Tracker
/// 
/// Tracks FPS, load times, memory usage, and other performance metrics
/// Sends metrics to EventBus for backend analytics
/// 
/// Follows Flame game engine best practices:
/// - Non-blocking tracking (doesn't impact gameplay)
/// - Batched reporting (reduces event volume)
/// - Lightweight (minimal overhead)
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../debug_logger.dart';
import '../events/event_bus.dart';

/// Performance Tracker
/// 
/// Tracks and reports performance metrics to backend
class PerformanceTracker {
  static final PerformanceTracker _instance = PerformanceTracker._internal();
  factory PerformanceTracker() => _instance;
  PerformanceTracker._internal();

  bool _isInitialized = false;
  Timer? _reportingTimer;
  DateTime? _appStartTime;
  DateTime? _gameLoadStartTime;
  String? _deviceModel;
  String? _osVersion;

  bool get isInitialized => _isInitialized;

  // Performance metrics cache
  double _lastFps = 60.0;
  double _minFps = 60.0;
  double _maxFps = 60.0;
  List<double> _fpsSamples = [];
  static const int _fpsSampleSize = 60; // 1 second at 60fps

  /// Initialize performance tracker
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      safePrint('📊 Initializing Performance Tracker...');

      // Get device info
      await _loadDeviceInfo();

      // Record app start time
      _appStartTime = DateTime.now();

      // Start periodic reporting (every 30 seconds)
      _reportingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        _reportPerformanceMetrics();
      });

      _isInitialized = true;
      safePrint('📊 ✅ Performance Tracker initialized');
    } catch (e) {
      safePrint('📊 ❌ Performance Tracker initialization failed: $e');
    }
  }

  /// Load device information
  Future<void> _loadDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await deviceInfo.androidInfo;
        _deviceModel = '${androidInfo.manufacturer} ${androidInfo.model}';
        _osVersion = 'Android ${androidInfo.version.release}';
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _deviceModel = '${iosInfo.name} ${iosInfo.model}';
        _osVersion = 'iOS ${iosInfo.systemVersion}';
      }
    } catch (e) {
      safePrint('📊 Failed to load device info: $e');
    }
  }

  /// Update FPS metrics (called from FrameRateOptimizer)
  void updateFps(double fps) {
    if (!_isInitialized) return;

    _lastFps = fps;
    _fpsSamples.add(fps);

    // Keep only last N samples
    if (_fpsSamples.length > _fpsSampleSize) {
      _fpsSamples.removeAt(0);
    }

    // Update min/max
    if (fps < _minFps) _minFps = fps;
    if (fps > _maxFps) _maxFps = fps;
  }

  /// Track app load time
  void trackAppLoadTime() {
    if (!_isInitialized || _appStartTime == null) return;

    final loadTime = DateTime.now().difference(_appStartTime!).inMilliseconds;

    EventBus().fire('app_load_time', {
      'load_time_ms': loadTime,
      'device_model': _deviceModel ?? 'unknown',
      'os_version': _osVersion ?? 'unknown',
    });

    safePrint('📊 App load time: ${loadTime}ms');
  }

  /// Track game load time
  void trackGameLoadTime() {
    if (!_isInitialized) return;

    _gameLoadStartTime = DateTime.now();
  }

  /// Track game load complete
  void trackGameLoadComplete() {
    if (!_isInitialized || _gameLoadStartTime == null) return;

    final loadTime = DateTime.now().difference(_gameLoadStartTime!).inMilliseconds;

    EventBus().fire('game_load_time', {
      'load_time_ms': loadTime,
      'device_model': _deviceModel ?? 'unknown',
      'os_version': _osVersion ?? 'unknown',
    });

    safePrint('📊 Game load time: ${loadTime}ms');
    _gameLoadStartTime = null;
  }

  /// Report performance metrics periodically
  void _reportPerformanceMetrics() {
    if (!_isInitialized || _fpsSamples.isEmpty) return;

    // Calculate average FPS from samples
    final avgFps = _fpsSamples.reduce((a, b) => a + b) / _fpsSamples.length;

    // Calculate frame time from FPS samples
    double frameTimeMs = 0.0;
    if (_fpsSamples.isNotEmpty && avgFps > 0) {
      frameTimeMs = 1000.0 / avgFps; // Convert FPS to frame time in ms
    }

    EventBus().fire('performance_metrics', {
      'fps_average': avgFps,
      'fps_min': _minFps,
      'fps_max': _maxFps,
      'fps_current': _lastFps,
      'fps_samples': _fpsSamples.length,
      'frame_time_ms': frameTimeMs,
      'device_model': _deviceModel ?? 'unknown',
      'os_version': _osVersion ?? 'unknown',
    });

    // Reset min/max for next period
    _minFps = 60.0;
    _maxFps = 60.0;
  }

  /// Track memory usage (if available)
  void trackMemoryUsage(int memoryBytes) {
    if (!_isInitialized) return;

    final memoryMb = memoryBytes / (1024 * 1024);

    EventBus().fire('memory_usage', {
      'memory_mb': memoryMb,
      'device_model': _deviceModel ?? 'unknown',
    });
  }

  /// Track error (non-fatal)
  void trackError({
    required String errorType,
    required String errorMessage,
    String? stackTrace,
    String? context,
  }) {
    if (!_isInitialized) return;

    EventBus().fire('app_error', {
      'error_type': errorType,
      'error_message': errorMessage,
      'stack_trace': stackTrace,
      'context': context ?? 'unknown',
      'device_model': _deviceModel ?? 'unknown',
      'os_version': _osVersion ?? 'unknown',
      'fatal': false,
    });
  }

  /// Track crash (fatal)
  void trackCrash({
    required String crashType,
    required String crashMessage,
    String? stackTrace,
    String? context,
  }) {
    if (!_isInitialized) return;

    EventBus().fire('app_crashed', {
      'crash_type': crashType,
      'crash_message': crashMessage,
      'stack_trace': stackTrace,
      'context': context ?? 'unknown',
      'device_model': _deviceModel ?? 'unknown',
      'os_version': _osVersion ?? 'unknown',
      'fatal': true,
    });
  }

  /// Dispose resources
  void dispose() {
    _reportingTimer?.cancel();
    _reportingTimer = null;
    _isInitialized = false;
  }
}


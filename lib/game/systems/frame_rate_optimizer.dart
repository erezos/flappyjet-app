/// 🎯 FRAME RATE OPTIMIZER - Prevents "Skipped frames" and maintains 60fps
/// Implements LOD system and adaptive quality based on performance
library;
import '../../core/debug_logger.dart';

import 'dart:collection';
import 'dart:math' as math;
import 'package:flutter/scheduler.dart';

/// Performance quality levels
enum QualityLevel {
  potato,    // Minimum quality for very low-end devices
  low,       // Reduced effects and particles
  medium,    // Balanced quality and performance
  high,      // Full quality with all effects
  ultra,     // Maximum quality for high-end devices
}

/// Frame timing data for analysis
class FrameData {
  final Duration frameTime;
  final DateTime timestamp;
  final int frameNumber;
  
  FrameData({
    required this.frameTime,
    required this.timestamp,
    required this.frameNumber,
  });
  
  double get fps => 1000.0 / frameTime.inMicroseconds * 1000;
}

/// Performance metrics tracker
class PerformanceMetrics {
  final Queue<FrameData> _frameHistory = Queue<FrameData>();
  final Queue<double> _fpsHistory = Queue<double>();
  
  static const int maxFrameHistory = 120; // 2 seconds at 60fps
  static const int maxFpsHistory = 30;    // 0.5 seconds at 60fps
  
  int _frameCount = 0;
  double _currentFps = 60.0;
  double _averageFps = 60.0;
  double _minFps = 60.0;
  double _maxFps = 60.0;
  
  /// Add frame timing data
  void addFrame(Duration frameTime) {
    final now = DateTime.now();
    final frameData = FrameData(
      frameTime: frameTime,
      timestamp: now,
      frameNumber: _frameCount++,
    );
    
    _frameHistory.add(frameData);
    if (_frameHistory.length > maxFrameHistory) {
      _frameHistory.removeFirst();
    }
    
    // Calculate current FPS
    _currentFps = frameData.fps;
    _fpsHistory.add(_currentFps);
    if (_fpsHistory.length > maxFpsHistory) {
      _fpsHistory.removeFirst();
    }
    
    // Update statistics every 30 frames
    if (_frameCount % 30 == 0) {
      _updateStatistics();
    }
  }
  
  /// Update performance statistics
  void _updateStatistics() {
    if (_fpsHistory.isEmpty) return;
    
    _averageFps = _fpsHistory.reduce((a, b) => a + b) / _fpsHistory.length;
    _minFps = _fpsHistory.reduce(math.min);
    _maxFps = _fpsHistory.reduce(math.max);
  }
  
  /// Get current performance data
  Map<String, dynamic> getMetrics() {
    final frameTimeMs = _frameHistory.isNotEmpty 
        ? _frameHistory.last.frameTime.inMicroseconds / 1000.0
        : 0.0;
    
    return {
      'current_fps': _currentFps.toStringAsFixed(1),
      'average_fps': _averageFps.toStringAsFixed(1),
      'min_fps': _minFps.toStringAsFixed(1),
      'max_fps': _maxFps.toStringAsFixed(1),
      'frame_time_ms': frameTimeMs.toStringAsFixed(2),
      'frame_count': _frameCount,
      'frame_history_size': _frameHistory.length,
    };
  }
  
  /// Check if performance is stable
  bool get isPerformanceStable {
    if (_fpsHistory.length < 10) return true;
    
    final variance = _calculateVariance();
    return variance < 100; // Low variance indicates stability
  }
  
  /// Calculate FPS variance
  double _calculateVariance() {
    if (_fpsHistory.length < 2) return 0.0;
    
    final mean = _averageFps;
    final squaredDiffs = _fpsHistory.map((fps) => math.pow(fps - mean, 2));
    return squaredDiffs.reduce((a, b) => a + b) / _fpsHistory.length;
  }
}

/// Quality settings for different performance levels
class QualitySettings {
  final QualityLevel level;
  final int maxParticles;
  final int maxTrailSegments;
  final bool enableShadows;
  final bool enableBloom;
  final bool enableMotionBlur;
  final double renderScale;
  final int targetFps;
  
  const QualitySettings({
    required this.level,
    required this.maxParticles,
    required this.maxTrailSegments,
    required this.enableShadows,
    required this.enableBloom,
    required this.enableMotionBlur,
    required this.renderScale,
    required this.targetFps,
  });
  
  static const Map<QualityLevel, QualitySettings> presets = {
    QualityLevel.potato: QualitySettings(
      level: QualityLevel.potato,
      maxParticles: 10,
      maxTrailSegments: 3,
      enableShadows: false,
      enableBloom: false,
      enableMotionBlur: false,
      renderScale: 0.7,
      targetFps: 30,
    ),
    QualityLevel.low: QualitySettings(
      level: QualityLevel.low,
      maxParticles: 25,
      maxTrailSegments: 5,
      enableShadows: false,
      enableBloom: false,
      enableMotionBlur: false,
      renderScale: 0.8,
      targetFps: 45,
    ),
    QualityLevel.medium: QualitySettings(
      level: QualityLevel.medium,
      maxParticles: 50,
      maxTrailSegments: 8,
      enableShadows: true,
      enableBloom: false,
      enableMotionBlur: false,
      renderScale: 0.9,
      targetFps: 60,
    ),
    QualityLevel.high: QualitySettings(
      level: QualityLevel.high,
      maxParticles: 100,
      maxTrailSegments: 12,
      enableShadows: true,
      enableBloom: true,
      enableMotionBlur: false,
      renderScale: 1.0,
      targetFps: 60,
    ),
    QualityLevel.ultra: QualitySettings(
      level: QualityLevel.ultra,
      maxParticles: 200,
      maxTrailSegments: 20,
      enableShadows: true,
      enableBloom: true,
      enableMotionBlur: true,
      renderScale: 1.0,
      targetFps: 60,
    ),
  };
}

/// 🎯 FRAME RATE OPTIMIZER - Adaptive performance management
class FrameRateOptimizer {
  static FrameRateOptimizer? _instance;
  static FrameRateOptimizer get instance => _instance ??= FrameRateOptimizer._();
  
  FrameRateOptimizer._();

  // Performance tracking
  final PerformanceMetrics _metrics = PerformanceMetrics();
  QualityLevel _currentQuality = QualityLevel.medium;
  QualitySettings _currentSettings = QualitySettings.presets[QualityLevel.medium]!;
  
  // Adaptive quality control
  bool _adaptiveQualityEnabled = true;
  DateTime _lastQualityAdjustment = DateTime.now();
  int _consecutiveLowFrames = 0;
  int _consecutiveHighFrames = 0;
  
  // Configuration
  static const Duration qualityAdjustmentCooldown = Duration(seconds: 3);
  static const int lowFrameThreshold = 5;   // Consecutive low frames before downgrade
  static const int highFrameThreshold = 30; // Consecutive high frames before upgrade
  static const double lowFpsThreshold = 45.0;
  static const double highFpsThreshold = 55.0;
  
  // Frame timing
  Ticker? _ticker;
  Duration _lastFrameTime = Duration.zero;
  bool _isInitialized = false;

  /// Initialize the frame rate optimizer
  void initialize() {
    if (_isInitialized) return;
    
    safePrint('🎯 Initializing FrameRateOptimizer...');
    
    // Start frame timing
    _ticker = Ticker(_onTick);
    _ticker!.start();
    
    // Set initial quality based on device capabilities
    _detectInitialQuality();
    
    _isInitialized = true;
    safePrint('🎯 FrameRateOptimizer initialized with ${_currentQuality.name} quality');
  }

  /// Detect initial quality level based on device
  void _detectInitialQuality() {
    // This would ideally use device info, but for now use medium as default
    // In a real implementation, you'd check:
    // - Device model/chipset
    // - Available RAM
    // - GPU capabilities
    // - Screen resolution
    
    setQualityLevel(QualityLevel.medium);
  }

  /// Frame tick callback
  void _onTick(Duration elapsed) {
    final frameTime = elapsed - _lastFrameTime;
    _lastFrameTime = elapsed;
    
    // Add frame data
    _metrics.addFrame(frameTime);
    
    // Check for adaptive quality adjustment
    if (_adaptiveQualityEnabled) {
      _checkAdaptiveQuality();
    }
  }

  /// Check if quality should be adjusted
  void _checkAdaptiveQuality() {
    final now = DateTime.now();
    if (now.difference(_lastQualityAdjustment) < qualityAdjustmentCooldown) {
      return;
    }
    
    final currentFps = double.parse(_metrics.getMetrics()['current_fps']);
    
    // Check for low performance
    if (currentFps < lowFpsThreshold) {
      _consecutiveLowFrames++;
      _consecutiveHighFrames = 0;
      
      if (_consecutiveLowFrames >= lowFrameThreshold) {
        _downgradeQuality();
        _consecutiveLowFrames = 0;
      }
    }
    // Check for high performance (room for upgrade)
    else if (currentFps > highFpsThreshold) {
      _consecutiveHighFrames++;
      _consecutiveLowFrames = 0;
      
      if (_consecutiveHighFrames >= highFrameThreshold) {
        _upgradeQuality();
        _consecutiveHighFrames = 0;
      }
    }
    // Reset counters for stable performance
    else {
      _consecutiveLowFrames = 0;
      _consecutiveHighFrames = 0;
    }
  }

  /// Downgrade quality level
  void _downgradeQuality() {
    final currentIndex = QualityLevel.values.indexOf(_currentQuality);
    if (currentIndex > 0) {
      final newQuality = QualityLevel.values[currentIndex - 1];
      setQualityLevel(newQuality);
      _lastQualityAdjustment = DateTime.now();
      
      safePrint('🎯 Performance downgrade: ${_currentQuality.name} → ${newQuality.name}');
    }
  }

  /// Upgrade quality level
  void _upgradeQuality() {
    final currentIndex = QualityLevel.values.indexOf(_currentQuality);
    if (currentIndex < QualityLevel.values.length - 1) {
      final newQuality = QualityLevel.values[currentIndex + 1];
      setQualityLevel(newQuality);
      _lastQualityAdjustment = DateTime.now();
      
      safePrint('🎯 Performance upgrade: ${_currentQuality.name} → ${newQuality.name}');
    }
  }

  /// Set specific quality level
  void setQualityLevel(QualityLevel quality) {
    _currentQuality = quality;
    _currentSettings = QualitySettings.presets[quality]!;
    
    safePrint('🎯 Quality set to ${quality.name}: '
        '${_currentSettings.maxParticles} particles, '
        '${_currentSettings.renderScale}x scale, '
        '${_currentSettings.targetFps} target fps');
  }

  /// Get current quality settings
  QualitySettings get currentSettings => _currentSettings;

  /// Get current quality level
  QualityLevel get currentQuality => _currentQuality;

  /// Enable/disable adaptive quality
  void setAdaptiveQuality(bool enabled) {
    _adaptiveQualityEnabled = enabled;
    safePrint('🎯 Adaptive quality ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Check if should render particle
  bool shouldRenderParticle(int currentParticleCount) {
    return currentParticleCount < _currentSettings.maxParticles;
  }

  /// Check if should render trail segment
  bool shouldRenderTrailSegment(int currentSegmentCount) {
    return currentSegmentCount < _currentSettings.maxTrailSegments;
  }

  /// Get LOD (Level of Detail) multiplier for distance
  double getLODMultiplier(double distance, double maxDistance) {
    if (!_currentSettings.enableShadows) return 0.5; // Simplified rendering
    
    final normalizedDistance = (distance / maxDistance).clamp(0.0, 1.0);
    
    switch (_currentQuality) {
      case QualityLevel.potato:
      case QualityLevel.low:
        return normalizedDistance > 0.5 ? 0.3 : 0.7;
      case QualityLevel.medium:
        return 1.0 - (normalizedDistance * 0.3);
      case QualityLevel.high:
      case QualityLevel.ultra:
        return 1.0 - (normalizedDistance * 0.2);
    }
  }

  /// Get performance metrics
  Map<String, dynamic> getPerformanceMetrics() {
    final baseMetrics = _metrics.getMetrics();
    
    return {
      ...baseMetrics,
      'current_quality': _currentQuality.name,
      'adaptive_quality_enabled': _adaptiveQualityEnabled,
      'max_particles': _currentSettings.maxParticles,
      'max_trail_segments': _currentSettings.maxTrailSegments,
      'render_scale': _currentSettings.renderScale,
      'target_fps': _currentSettings.targetFps,
      'consecutive_low_frames': _consecutiveLowFrames,
      'consecutive_high_frames': _consecutiveHighFrames,
      'performance_stable': _metrics.isPerformanceStable,
    };
  }

  /// Force quality adjustment for testing
  void forceQualityAdjustment() {
    _lastQualityAdjustment = DateTime.now().subtract(qualityAdjustmentCooldown);
  }

  /// Dispose resources
  void dispose() {
    _ticker?.dispose();
    _ticker = null;
    _isInitialized = false;
    safePrint('🎯 FrameRateOptimizer disposed');
  }
}

/// 🎯 FRAME OPTIMIZER EXTENSIONS - Convenience methods
extension FrameOptimizerExtensions on FrameRateOptimizer {
  /// Quick quality checks
  bool get isLowQuality => currentQuality.index <= QualityLevel.low.index;
  bool get isMediumQuality => currentQuality == QualityLevel.medium;
  bool get isHighQuality => currentQuality.index >= QualityLevel.high.index;
  
  /// Effect enablement checks
  bool get shouldRenderShadows => currentSettings.enableShadows;
  bool get shouldRenderBloom => currentSettings.enableBloom;
  bool get shouldRenderMotionBlur => currentSettings.enableMotionBlur;
  
  /// Performance-based rendering decisions
  bool shouldSkipFrame(int frameNumber) {
    // Skip every other frame on potato quality
    return currentQuality == QualityLevel.potato && frameNumber % 2 == 1;
  }
  
  /// Get simplified particle count for current quality
  int getOptimalParticleCount(int requestedCount) {
    return math.min(requestedCount, currentSettings.maxParticles);
  }
  
  /// Get render scale for UI elements
  double get uiRenderScale => math.max(currentSettings.renderScale, 0.8);
}
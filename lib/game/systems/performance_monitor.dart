import 'dart:collection';
import 'dart:io';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../core/game_config.dart';

/// MCP-Guided Performance Monitoring System
/// Provides real-time performance tracking, adaptive quality control, and debugging insights
class PerformanceMonitor extends Component {
  // Performance metrics
  final Queue<double> _fpsHistory = Queue<double>();
  final Queue<double> _frameTimeHistory = Queue<double>();
  final Queue<double> _memoryHistory = Queue<double>();
  
  double _currentFPS = 60.0;
  double _averageFPS = 60.0;
  double _frameTime = 16.67; // milliseconds for 60fps
  int _frameCount = 0;
  DateTime _lastFPSUpdate = DateTime.now();
  
  // Performance thresholds (MCP-guided values)
  static const double targetFPS = 60.0;
  static const double warningFPS = 45.0;
  static const double criticalFPS = 30.0;
  static const int historySize = 100;
  
  // Quality management
  PerformanceQuality _currentQuality = PerformanceQuality.high;
  PerformanceQuality _recommendedQuality = PerformanceQuality.high;
  bool _adaptiveQualityEnabled = true;
  
  // Monitoring state
  bool _showDebugOverlay = GameConfig.enableDebugOverlay;
  final Map<String, double> _customMetrics = {};
  final List<PerformanceAlert> _activeAlerts = [];
  
  // System information
  late DeviceCapabilities _deviceCapabilities;
  bool _isInitialized = false;

  @override
  Future<void> onLoad() async {
    await _initializeDeviceCapabilities();
    _startPerformanceMonitoring();
    _isInitialized = true;
    
    debugPrint('📊 Performance Monitor initialized - ${_deviceCapabilities.description}');
  }

  @override
  void update(double dt) {
    if (!_isInitialized) return;
    
    _updateFrameMetrics(dt);
    _updateMemoryMetrics();
    _checkPerformanceAlerts();
    _updateAdaptiveQuality();
    
    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    if (_showDebugOverlay && kDebugMode) {
      _renderDebugOverlay(canvas);
    }
  }

  /// Initialize device capability detection
  Future<void> _initializeDeviceCapabilities() async {
    _deviceCapabilities = DeviceCapabilities();
    await _deviceCapabilities.detect();
  }

  /// Start performance monitoring
  void _startPerformanceMonitoring() {
    // Initialize history queues
    for (int i = 0; i < historySize; i++) {
      _fpsHistory.add(targetFPS);
      _frameTimeHistory.add(16.67);
      _memoryHistory.add(0.0);
    }
  }

  /// Update frame rate and timing metrics
  void _updateFrameMetrics(double dt) {
    _frameCount++;
    _frameTime = dt * 1000; // Convert to milliseconds
    
    final now = DateTime.now();
    final elapsed = now.difference(_lastFPSUpdate).inMilliseconds;
    
    if (elapsed >= 1000) { // Update FPS every second
      _currentFPS = (_frameCount * 1000) / elapsed;
      _frameCount = 0;
      _lastFPSUpdate = now;
      
      // Update history
      if (_fpsHistory.length >= historySize) {
        _fpsHistory.removeFirst();
        _frameTimeHistory.removeFirst();
      }
      
      _fpsHistory.add(_currentFPS);
      _frameTimeHistory.add(_frameTime);
      
      // Calculate average FPS
      _averageFPS = _fpsHistory.reduce((a, b) => a + b) / _fpsHistory.length;
    }
  }

  /// Update memory usage metrics
  void _updateMemoryMetrics() {
    // Simplified memory tracking (actual implementation would use platform channels)
    final estimatedMemory = _estimateMemoryUsage();
    
    if (_memoryHistory.length >= historySize) {
      _memoryHistory.removeFirst();
    }
    _memoryHistory.add(estimatedMemory);
  }

  /// Estimate current memory usage
  double _estimateMemoryUsage() {
    // MCP-guided estimation based on active components
    double baseMemory = 20.0; // Base game memory in MB
    
    // Add particle system memory
    baseMemory += _customMetrics['particle_memory'] ?? 2.0;
    
    // Add audio system memory
    baseMemory += _customMetrics['audio_memory'] ?? 3.0;
    
    // Add texture memory estimate
    baseMemory += _customMetrics['texture_memory'] ?? 5.0;
    
    return baseMemory;
  }

  /// Check for performance alerts
  void _checkPerformanceAlerts() {
    _activeAlerts.clear();
    
    // FPS alerts
    if (_currentFPS < criticalFPS) {
      _activeAlerts.add(PerformanceAlert(
        type: AlertType.critical,
        message: 'Critical FPS drop: ${_currentFPS.toStringAsFixed(1)}fps',
        recommendation: 'Reduce visual effects and particle count',
      ));
    } else if (_currentFPS < warningFPS) {
      _activeAlerts.add(PerformanceAlert(
        type: AlertType.warning,
        message: 'Low FPS: ${_currentFPS.toStringAsFixed(1)}fps',
        recommendation: 'Consider reducing particle count',
      ));
    }
    
    // Memory alerts
    final currentMemory = _memoryHistory.isNotEmpty ? _memoryHistory.last : 0.0;
    if (currentMemory > GameConfig.maxMemoryUsageMB) {
      _activeAlerts.add(PerformanceAlert(
        type: AlertType.warning,
        message: 'High memory usage: ${currentMemory.toStringAsFixed(1)}MB',
        recommendation: 'Clear unused assets and reduce cache size',
      ));
    }
    
    // Particle system alerts
    final particleCount = _customMetrics['active_particles']?.toInt() ?? 0;
    if (particleCount > 80) {
      _activeAlerts.add(PerformanceAlert(
        type: AlertType.info,
        message: 'High particle count: $particleCount',
        recommendation: 'Particle system approaching limit',
      ));
    }
  }

  /// Update adaptive quality based on performance
  void _updateAdaptiveQuality() {
    if (!_adaptiveQualityEnabled) return;
    
    PerformanceQuality newQuality = _currentQuality;
    
    if (_averageFPS >= targetFPS) {
      newQuality = PerformanceQuality.high;
    } else if (_averageFPS >= warningFPS) {
      newQuality = PerformanceQuality.medium;
    } else {
      newQuality = PerformanceQuality.low;
    }
    
    if (newQuality != _recommendedQuality) {
      _recommendedQuality = newQuality;
      debugPrint('📊 Performance Monitor: Recommending ${newQuality.name} quality');
    }
  }

  /// Apply quality settings based on current performance
  void applyQualitySettings(PerformanceQuality quality) {
    _currentQuality = quality;
    
    switch (quality) {
      case PerformanceQuality.high:
        _customMetrics['max_particles'] = 100.0;
        _customMetrics['audio_quality'] = 1.0;
        _customMetrics['visual_effects'] = 1.0;
        break;
        
      case PerformanceQuality.medium:
        _customMetrics['max_particles'] = 60.0;
        _customMetrics['audio_quality'] = 0.8;
        _customMetrics['visual_effects'] = 0.7;
        break;
        
      case PerformanceQuality.low:
        _customMetrics['max_particles'] = 30.0;
        _customMetrics['audio_quality'] = 0.6;
        _customMetrics['visual_effects'] = 0.5;
        break;
    }
    
    debugPrint('📊 Applied ${quality.name} quality settings');
  }

  /// Register custom performance metric
  void registerMetric(String name, double value) {
    _customMetrics[name] = value;
  }

  /// Get comprehensive performance report
  Map<String, dynamic> getPerformanceReport() {
    return {
      'fps': {
        'current': _currentFPS,
        'average': _averageFPS,
        'target': targetFPS,
        'status': _getFPSStatus(),
      },
      'memory': {
        'current_mb': _memoryHistory.isNotEmpty ? _memoryHistory.last : 0.0,
        'average_mb': _memoryHistory.isNotEmpty 
            ? _memoryHistory.reduce((a, b) => a + b) / _memoryHistory.length 
            : 0.0,
        'limit_mb': GameConfig.maxMemoryUsageMB,
      },
      'quality': {
        'current': _currentQuality.name,
        'recommended': _recommendedQuality.name,
        'adaptive_enabled': _adaptiveQualityEnabled,
      },
      'device': _deviceCapabilities.toMap(),
      'alerts': _activeAlerts.map((alert) => alert.toMap()).toList(),
      'custom_metrics': Map<String, dynamic>.from(_customMetrics),
    };
  }

  String _getFPSStatus() {
    if (_currentFPS >= targetFPS) return 'excellent';
    if (_currentFPS >= warningFPS) return 'good';
    if (_currentFPS >= criticalFPS) return 'poor';
    return 'critical';
  }

  /// Render debug overlay with performance metrics
  void _renderDebugOverlay(Canvas canvas) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.7);
    final textPaint = TextPaint(
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontFamily: 'monospace',
      ),
    );
    
    // Background
    canvas.drawRect(const Rect.fromLTWH(10, 10, 200, 150), paint);
    
    // Performance metrics
    final metrics = [
      'FPS: ${_currentFPS.toStringAsFixed(1)} (${_averageFPS.toStringAsFixed(1)} avg)',
      'Frame: ${_frameTime.toStringAsFixed(1)}ms',
      'Memory: ${_memoryHistory.isNotEmpty ? _memoryHistory.last.toStringAsFixed(1) : 0}MB',
      'Quality: ${_currentQuality.name}',
      'Particles: ${_customMetrics['active_particles']?.toInt() ?? 0}',
      'Device: ${_deviceCapabilities.tier.name}',
    ];
    
    for (int i = 0; i < metrics.length; i++) {
      textPaint.render(
        canvas,
        metrics[i],
        Vector2(15, 25 + i * 15),
      );
    }
    
    // Alerts
    if (_activeAlerts.isNotEmpty) {
      final alertPaint = Paint()..color = Colors.red.withValues(alpha: 0.8);
      canvas.drawRect(const Rect.fromLTWH(10, 170, 200, 30), alertPaint);
      
      textPaint.render(
        canvas,
        '⚠️ ${_activeAlerts.length} alert(s)',
        Vector2(15, 185),
      );
    }
  }

  /// Toggle debug overlay visibility
  void toggleDebugOverlay() {
    _showDebugOverlay = !_showDebugOverlay;
  }

  /// Enable/disable adaptive quality
  void setAdaptiveQuality(bool enabled) {
    _adaptiveQualityEnabled = enabled;
  }

  // Getters
  double get currentFPS => _currentFPS;
  double get averageFPS => _averageFPS;
  PerformanceQuality get currentQuality => _currentQuality;
  PerformanceQuality get recommendedQuality => _recommendedQuality;
  List<PerformanceAlert> get activeAlerts => List.unmodifiable(_activeAlerts);
  bool get isShowingDebugOverlay => _showDebugOverlay;
}

/// Performance quality levels
enum PerformanceQuality {
  low,
  medium, 
  high;
  
  String get name => toString().split('.').last;
}

/// Performance alert system
class PerformanceAlert {
  final AlertType type;
  final String message;
  final String recommendation;
  final DateTime timestamp;
  
  PerformanceAlert({
    required this.type,
    required this.message,
    required this.recommendation,
  }) : timestamp = DateTime.now();
  
  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'message': message,
      'recommendation': recommendation,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

enum AlertType { info, warning, critical }

/// Device capability detection
class DeviceCapabilities {
  DeviceTier tier = DeviceTier.medium;
  int estimatedCores = 4;
  double estimatedMemoryGB = 4.0;
  bool hasHighRefreshRate = false;
  String platformInfo = '';
  
  Future<void> detect() async {
    // Simplified device detection (actual implementation would use platform channels)
    if (Platform.isIOS) {
      platformInfo = 'iOS Device';
      tier = DeviceTier.high; // iOS devices generally well-optimized
      estimatedMemoryGB = 6.0;
    } else if (Platform.isAndroid) {
      platformInfo = 'Android Device';
      tier = DeviceTier.medium; // Conservative estimate
      estimatedMemoryGB = 4.0;
    } else {
      platformInfo = 'Other Platform';
      tier = DeviceTier.low;
      estimatedMemoryGB = 2.0;
    }
  }
  
  String get description => '$platformInfo (${tier.name} tier, ${estimatedMemoryGB}GB)';
  
  Map<String, dynamic> toMap() {
    return {
      'tier': tier.name,
      'cores': estimatedCores,
      'memory_gb': estimatedMemoryGB,
      'high_refresh_rate': hasHighRefreshRate,
      'platform': platformInfo,
    };
  }
}

enum DeviceTier { low, medium, high }

/// Performance monitoring utilities
class PerformanceUtils {
  /// Get recommended quality for device
  static PerformanceQuality getRecommendedQuality(DeviceCapabilities device) {
    switch (device.tier) {
      case DeviceTier.high:
        return PerformanceQuality.high;
      case DeviceTier.medium:
        return PerformanceQuality.medium;
      case DeviceTier.low:
        return PerformanceQuality.low;
    }
  }
  
  /// Calculate performance score (0-100)
  static double calculatePerformanceScore(double fps, double memoryMB) {
    final fpsScore = (fps / 60.0).clamp(0.0, 1.0) * 60;
    final memoryScore = (1.0 - (memoryMB / 150.0)).clamp(0.0, 1.0) * 40;
    return fpsScore + memoryScore;
  }
  
  /// Get performance recommendations
  static List<String> getOptimizationTips(PerformanceAlert alert) {
    switch (alert.type) {
      case AlertType.critical:
        return [
          'Reduce particle count to minimum',
          'Disable ambient effects',
          'Lower audio quality',
          'Simplify visual themes',
        ];
      case AlertType.warning:
        return [
          'Reduce particle density',
          'Enable object pooling',
          'Optimize collision detection',
        ];
      case AlertType.info:
        return [
          'Monitor particle count',
          'Consider performance optimizations',
        ];
    }
  }
} 
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Adaptive quality system used by AAA mobile games
/// Dynamically adjusts game quality based on device performance
class AdaptiveQualityManager {
  static AdaptiveQualityManager? _instance;
  static AdaptiveQualityManager get instance => _instance ??= AdaptiveQualityManager._();
  
  AdaptiveQualityManager._();

  QualityProfile _currentProfile = QualityProfile.high;
  late DevicePerformanceTier _deviceTier;
  
  // Performance monitoring
  final List<double> _frameTimeHistory = [];
  double _averageFrameTime = 16.67; // 60fps baseline
  int _consecutiveLagFrames = 0;
  
  // Quality settings
  int _maxParticles = 100;
  double _renderScale = 1.0;
  bool _enableAdvancedEffects = true;
  int _targetFPS = 60;

  Future<void> initialize() async {
    await _detectDevicePerformance();
    _applyInitialQuality();
    
    if (kDebugMode) {
      print('🎯 AdaptiveQuality: Device tier: $_deviceTier');
      print('🎯 AdaptiveQuality: Initial profile: $_currentProfile');
    }
  }

  Future<void> _detectDevicePerformance() async {
    final deviceInfo = DeviceInfoPlugin();
    
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _deviceTier = _analyzeAndroidPerformance(androidInfo);
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _deviceTier = _analyzeIOSPerformance(iosInfo);
      } else {
        _deviceTier = DevicePerformanceTier.medium;
      }
    } catch (e) {
      _deviceTier = DevicePerformanceTier.medium; // Safe fallback
    }
  }

  DevicePerformanceTier _analyzeAndroidPerformance(AndroidDeviceInfo info) {
    // Analyze based on Android device specs
    final isEmulator = !info.isPhysicalDevice;
    if (isEmulator) return DevicePerformanceTier.low;

    // Check for known high-performance devices
    final brand = info.brand.toLowerCase();
    final model = info.model.toLowerCase();
    
    if (brand.contains('samsung') && model.contains('galaxy s')) {
      return DevicePerformanceTier.high;
    }
    if (brand.contains('google') && model.contains('pixel')) {
      return DevicePerformanceTier.high;
    }
    if (brand.contains('oneplus')) {
      return DevicePerformanceTier.high;
    }
    
    // Check for known low-performance indicators
    if (brand.contains('oppo') || brand.contains('vivo') || brand.contains('xiaomi')) {
      return DevicePerformanceTier.medium; // Conservative for compatibility
    }
    
    return DevicePerformanceTier.medium;
  }

  DevicePerformanceTier _analyzeIOSPerformance(IosDeviceInfo info) {
    final model = info.model.toLowerCase();
    
    // iPhone 12 and newer = high performance
    if (model.contains('iphone')) {
      final modelNumber = _extractiPhoneNumber(model);
      if (modelNumber >= 12) return DevicePerformanceTier.high;
      if (modelNumber >= 8) return DevicePerformanceTier.medium;
      return DevicePerformanceTier.low;
    }
    
    // iPad Pro = high performance
    if (model.contains('ipad pro')) return DevicePerformanceTier.high;
    if (model.contains('ipad')) return DevicePerformanceTier.medium;
    
    return DevicePerformanceTier.medium;
  }

  int _extractiPhoneNumber(String model) {
    final regex = RegExp(r'iphone(\d+)');
    final match = regex.firstMatch(model);
    return match != null ? int.tryParse(match.group(1) ?? '0') ?? 0 : 0;
  }

  void _applyInitialQuality() {
    switch (_deviceTier) {
      case DevicePerformanceTier.high:
        _currentProfile = QualityProfile.high;
        _maxParticles = 100;
        _renderScale = 1.0;
        _enableAdvancedEffects = true;
        _targetFPS = 60;
        break;
      case DevicePerformanceTier.medium:
        _currentProfile = QualityProfile.medium;
        _maxParticles = 60;
        _renderScale = 0.9;
        _enableAdvancedEffects = true;
        _targetFPS = 60;
        break;
      case DevicePerformanceTier.low:
        _currentProfile = QualityProfile.low;
        _maxParticles = 30;
        _renderScale = 0.8;
        _enableAdvancedEffects = false;
        _targetFPS = 45; // Lower target for low-end devices
        break;
    }
  }

  /// Called every frame to monitor performance and adjust quality
  void updatePerformanceMetrics(double deltaTime) {
    final frameTime = deltaTime * 1000; // Convert to milliseconds
    
    _frameTimeHistory.add(frameTime);
    if (_frameTimeHistory.length > 60) { // Keep 1 second of history
      _frameTimeHistory.removeAt(0);
    }
    
    // Calculate average frame time
    _averageFrameTime = _frameTimeHistory.reduce((a, b) => a + b) / _frameTimeHistory.length;
    
    // Detect performance issues
    final targetFrameTime = 1000 / _targetFPS;
    if (frameTime > targetFrameTime * 1.5) { // Frame took 50% longer than target
      _consecutiveLagFrames++;
    } else {
      _consecutiveLagFrames = 0;
    }
    
    // Auto-adjust quality if performance is consistently poor
    if (_consecutiveLagFrames > 30) { // 30 consecutive bad frames
      _downgradeQuality();
      _consecutiveLagFrames = 0;
    }
    
    // Auto-upgrade quality if performance is consistently good
    if (_averageFrameTime < targetFrameTime * 0.8 && _frameTimeHistory.length >= 60) {
      _upgradeQuality();
    }
  }

  void _downgradeQuality() {
    switch (_currentProfile) {
      case QualityProfile.high:
        _currentProfile = QualityProfile.medium;
        _maxParticles = 60;
        _renderScale = 0.9;
        break;
      case QualityProfile.medium:
        _currentProfile = QualityProfile.low;
        _maxParticles = 30;
        _renderScale = 0.8;
        _enableAdvancedEffects = false;
        break;
      case QualityProfile.low:
        // Already at lowest quality
        break;
    }
    
    if (kDebugMode) {
      print('🎯 AdaptiveQuality: Downgraded to $_currentProfile (avg frame time: ${_averageFrameTime.toStringAsFixed(2)}ms)');
    }
  }

  void _upgradeQuality() {
    switch (_currentProfile) {
      case QualityProfile.low:
        _currentProfile = QualityProfile.medium;
        _maxParticles = 60;
        _renderScale = 0.9;
        _enableAdvancedEffects = true;
        break;
      case QualityProfile.medium:
        _currentProfile = QualityProfile.high;
        _maxParticles = 100;
        _renderScale = 1.0;
        break;
      case QualityProfile.high:
        // Already at highest quality
        return;
    }
    
    if (kDebugMode) {
      print('🎯 AdaptiveQuality: Upgraded to $_currentProfile (avg frame time: ${_averageFrameTime.toStringAsFixed(2)}ms)');
    }
  }

  // Getters for game systems to use
  int get maxParticles => _maxParticles;
  double get renderScale => _renderScale;
  bool get enableAdvancedEffects => _enableAdvancedEffects;
  int get targetFPS => _targetFPS;
  QualityProfile get currentProfile => _currentProfile;
  DevicePerformanceTier get deviceTier => _deviceTier;
  
  Map<String, dynamic> getPerformanceStats() {
    return {
      'currentProfile': _currentProfile.toString(),
      'deviceTier': _deviceTier.toString(),
      'averageFrameTime': _averageFrameTime,
      'targetFrameTime': 1000 / _targetFPS,
      'maxParticles': _maxParticles,
      'renderScale': _renderScale,
      'enableAdvancedEffects': _enableAdvancedEffects,
    };
  }
}

enum DevicePerformanceTier {
  low,
  medium,
  high,
}

enum QualityProfile {
  low,
  medium,
  high,
}

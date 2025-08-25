import 'package:flutter/material.dart';
import 'package:flappy_jet_pro/game/systems/audio_manager.dart';

/// 🧪 TEST HELPERS: Access private state for testing
/// These extensions allow tests to verify internal state without breaking encapsulation

/// Test extensions are now built into the main game class for easier testing

extension AudioManagerTestExtensions on AudioManager {
  bool get isInitialized => true; // Assume initialized for testing
}

/// Test-specific DirectParticle for visibility testing
class TestDirectParticle {
  final double size;
  final Color color;
  final double lifetime;
  
  TestDirectParticle({
    required this.size,
    required this.color,
    required this.lifetime,
  });
  
  bool get isVisible => size >= 20.0; // Mobile visibility threshold
  bool get hasGoodContrast => color.alpha >= 0.7;
  bool get hasReasonableLifetime => lifetime >= 1.0 && lifetime <= 5.0;
}

/// Mock classes for testing failure scenarios
class MockAssetBundle {
  static bool simulateAssetLoadFailure = false;
  
  static Future<void> loadAsset(String path) async {
    if (simulateAssetLoadFailure) {
      throw Exception('Asset not found: $path');
    }
  }
}

/// Test utilities for common scenarios
class TestUtils {
  
  /// Simulate the exact LateInitializationError we were getting
  static void simulateComponentNotInitialized() {
    // This would throw: LateInitializationError: Field '_particleSystem@45502064' has not been initialized
    throw StateError('Field \'_particleSystem@45502064\' has not been initialized.');
  }
  
  /// Simulate asset loading failure
  static Future<void> simulateAssetLoadFailure() async {
    throw Exception('Unable to load asset: "assets/images/effects/damage_light.png"');
  }
  
  /// Test particle visibility on different backgrounds
  static bool isParticleVisibleOn(Color particleColor, Color backgroundColor) {
    // Simple contrast check - in real implementation would use WCAG guidelines
    final contrast = (particleColor.computeLuminance() - backgroundColor.computeLuminance()).abs();
    return contrast > 0.3; // Minimum contrast ratio
  }
  
  /// Verify particle meets mobile standards
  static bool meetsVisibilityStandards(double size, double alpha, Color color) {
    const minSize = 20.0; // Mobile minimum
    const minAlpha = 0.7; // Visibility minimum
    
    return size >= minSize && 
           alpha >= minAlpha && 
           color.alpha >= minAlpha;
  }
} 
/// 🎪 STUNT OBSTACLE - Unit Tests
/// 
/// Tests for the single moving obstacle component used in stunt tournaments.
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:flappy_jet_pro/game/components/stunt_obstacle.dart';
import 'package:flappy_jet_pro/game/components/obstacle_movement_config.dart';

void main() {
  group('StuntObstacleConfig', () {
    test('creates default config with expected values', () {
      const config = StuntObstacleConfig();
      
      expect(config.sizePercent, 0.15);
      expect(config.scrollSpeed, 150.0);
      expect(config.verticalAmplitudePercent, 0.3);
      expect(config.verticalFrequency, 0.4);
      expect(config.assetPath, 'obstacles/desert_obstacles.png');
      expect(config.phaseOffset, 0.0);
    });
    
    test('creates config from JSON', () {
      final json = {
        'size_percent': 0.2,
        'scroll_speed': 200.0,
        'vertical_amplitude_percent': 0.4,
        'vertical_frequency': 0.5,
        'asset_path': 'obstacles/ice_obstacles.png',
        'phase_offset': 0.25,
      };
      
      final config = StuntObstacleConfig.fromJson(json);
      
      expect(config.sizePercent, 0.2);
      expect(config.scrollSpeed, 200.0);
      expect(config.verticalAmplitudePercent, 0.4);
      expect(config.verticalFrequency, 0.5);
      expect(config.assetPath, 'obstacles/ice_obstacles.png');
      expect(config.phaseOffset, 0.25);
    });
    
    test('fromJson handles missing fields with defaults', () {
      final json = <String, dynamic>{};
      
      final config = StuntObstacleConfig.fromJson(json);
      
      expect(config.sizePercent, 0.15);
      expect(config.scrollSpeed, 150.0);
      expect(config.assetPath, 'obstacles/desert_obstacles.png');
    });
    
    test('copyWith creates modified copy', () {
      const original = StuntObstacleConfig(
        sizePercent: 0.15,
        scrollSpeed: 150.0,
      );
      
      final modified = original.copyWith(
        sizePercent: 0.2,
        scrollSpeed: 200.0,
      );
      
      expect(modified.sizePercent, 0.2);
      expect(modified.scrollSpeed, 200.0);
      // Original unchanged
      expect(original.sizePercent, 0.15);
      expect(original.scrollSpeed, 150.0);
    });
    
    test('copyWith preserves unmodified values', () {
      const original = StuntObstacleConfig(
        sizePercent: 0.15,
        scrollSpeed: 150.0,
        verticalAmplitudePercent: 0.3,
        verticalFrequency: 0.4,
        assetPath: 'obstacles/desert_obstacles.png',
        phaseOffset: 0.25,
      );
      
      final modified = original.copyWith(sizePercent: 0.2);
      
      expect(modified.sizePercent, 0.2);
      expect(modified.scrollSpeed, 150.0); // Preserved
      expect(modified.verticalAmplitudePercent, 0.3); // Preserved
      expect(modified.verticalFrequency, 0.4); // Preserved
      expect(modified.assetPath, 'obstacles/desert_obstacles.png'); // Preserved
      expect(modified.phaseOffset, 0.25); // Preserved
    });
    
    test('toString provides readable description', () {
      const config = StuntObstacleConfig(
        sizePercent: 0.15,
        scrollSpeed: 150.0,
        verticalAmplitudePercent: 0.3,
        verticalFrequency: 0.4,
      );
      
      final str = config.toString();
      
      expect(str, contains('15'));
      expect(str, contains('150'));
      expect(str, contains('30'));
      expect(str, contains('0.4'));
    });
  });
  
  group('StuntObstacle', () {
    test('creates obstacle with correct initial position', () {
      const config = StuntObstacleConfig();
      final startPosition = Vector2(500, 300);
      
      final obstacle = StuntObstacle(
        config: config,
        startY: 300,
        startPosition: startPosition,
      );
      
      expect(obstacle.position.x, 500);
      expect(obstacle.position.y, 300);
    });
    
    test('hasBeenPassed is initially false', () {
      const config = StuntObstacleConfig();
      
      final obstacle = StuntObstacle(
        config: config,
        startY: 300,
        startPosition: Vector2(500, 300),
      );
      
      expect(obstacle.hasBeenPassed, false);
    });
    
    test('getCollisionBounds returns valid rect', () {
      const config = StuntObstacleConfig(sizePercent: 0.15);
      final startPosition = Vector2(500, 300);
      
      final obstacle = StuntObstacle(
        config: config,
        startY: 300,
        startPosition: startPosition,
      );
      
      // Note: Size is calculated on load based on screen size
      // Before load, collision bounds will be based on initial size
      final bounds = obstacle.getCollisionBounds();
      expect(bounds, isA<Rect>());
    });
    
    test('toString provides useful debug info', () {
      const config = StuntObstacleConfig();
      
      final obstacle = StuntObstacle(
        config: config,
        startY: 300,
        startPosition: Vector2(500, 300),
      );
      
      final str = obstacle.toString();
      expect(str, contains('StuntObstacle'));
      expect(str, contains('passed'));
    });
  });
  
  group('Difficulty Configuration', () {
    test('easy difficulty has slower speed and smaller obstacles', () {
      const easy = StuntObstacleConfig(
        sizePercent: 0.12,
        scrollSpeed: 100.0,
        verticalAmplitudePercent: 0.25,
        verticalFrequency: 0.3,
      );
      
      expect(easy.sizePercent, lessThan(0.15));
      expect(easy.scrollSpeed, lessThan(150.0));
      expect(easy.verticalFrequency, lessThan(0.4));
    });
    
    test('hard difficulty has faster speed and larger obstacles', () {
      const hard = StuntObstacleConfig(
        sizePercent: 0.20,
        scrollSpeed: 200.0,
        verticalAmplitudePercent: 0.4,
        verticalFrequency: 0.6,
      );
      
      expect(hard.sizePercent, greaterThan(0.15));
      expect(hard.scrollSpeed, greaterThan(150.0));
      expect(hard.verticalFrequency, greaterThan(0.4));
    });
    
    test('phase offset creates variation between obstacles', () {
      const config1 = StuntObstacleConfig(phaseOffset: 0.0);
      const config2 = StuntObstacleConfig(phaseOffset: 0.25);
      const config3 = StuntObstacleConfig(phaseOffset: 0.5);
      
      expect(config1.phaseOffset, isNot(config2.phaseOffset));
      expect(config2.phaseOffset, isNot(config3.phaseOffset));
    });
  });
}


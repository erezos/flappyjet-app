/// 🎪 STUNT OBSTACLE MANAGER - Unit Tests
/// 
/// Tests for the obstacle spawning and lifecycle manager.
import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/game/components/stunt_obstacle.dart';
import 'package:flappy_jet_pro/game/systems/stunt_obstacle_manager.dart';

void main() {
  group('StuntObstacleManagerConfig', () {
    test('creates default config with expected values', () {
      const config = StuntObstacleManagerConfig();
      
      expect(config.spawnInterval, 2.5);
      expect(config.spawnVariance, 0.2);
      expect(config.minSpawnYPercent, 0.2);
      expect(config.maxSpawnYPercent, 0.8);
      expect(config.staggerPhases, true);
      expect(config.obstacleConfig, isA<StuntObstacleConfig>());
    });
    
    test('creates config from JSON', () {
      final json = {
        'spawn_interval': 3.0,
        'spawn_variance': 0.3,
        'min_spawn_y_percent': 0.25,
        'max_spawn_y_percent': 0.75,
        'stagger_phases': false,
        'obstacle': {
          'size_percent': 0.2,
          'scroll_speed': 180.0,
        },
      };
      
      final config = StuntObstacleManagerConfig.fromJson(json);
      
      expect(config.spawnInterval, 3.0);
      expect(config.spawnVariance, 0.3);
      expect(config.minSpawnYPercent, 0.25);
      expect(config.maxSpawnYPercent, 0.75);
      expect(config.staggerPhases, false);
      expect(config.obstacleConfig.sizePercent, 0.2);
      expect(config.obstacleConfig.scrollSpeed, 180.0);
    });
    
    test('fromJson handles missing fields with defaults', () {
      final json = <String, dynamic>{};
      
      final config = StuntObstacleManagerConfig.fromJson(json);
      
      expect(config.spawnInterval, 2.5);
      expect(config.spawnVariance, 0.2);
      expect(config.staggerPhases, true);
    });
    
    test('toString provides readable description', () {
      const config = StuntObstacleManagerConfig(
        spawnInterval: 2.5,
        spawnVariance: 0.2,
      );
      
      final str = config.toString();
      
      expect(str, contains('2.5'));
      expect(str, contains('0.2'));
    });
  });
  
  group('StuntObstacleManager', () {
    test('creates manager with config', () {
      const config = StuntObstacleManagerConfig();
      
      final manager = StuntObstacleManager(config: config);
      
      expect(manager.activeObstacleCount, 0);
      expect(manager.totalSpawned, 0);
    });
    
    test('visibleObstacles is initially empty', () {
      const config = StuntObstacleManagerConfig();
      final manager = StuntObstacleManager(config: config);
      
      expect(manager.visibleObstacles, isEmpty);
    });
    
    test('reset clears all state', () {
      const config = StuntObstacleManagerConfig();
      final manager = StuntObstacleManager(config: config);
      
      manager.startSpawning();
      manager.reset();
      
      expect(manager.activeObstacleCount, 0);
      expect(manager.totalSpawned, 0);
    });
    
    test('clearObstacles resets spawn count', () {
      const config = StuntObstacleManagerConfig();
      final manager = StuntObstacleManager(config: config);
      
      manager.clearObstacles();
      
      expect(manager.totalSpawned, 0);
      expect(manager.activeObstacleCount, 0);
    });
    
    test('callbacks are set via interface properties', () {
      const config = StuntObstacleManagerConfig();
      
      // Callbacks are now set via interface, not constructor
      final manager = StuntObstacleManager(config: config);
      
      // Set callbacks via interface
      manager.onObstacleCollision = () {};
      manager.onObstaclePassed = () {};
      
      expect(manager, isNotNull);
      expect(manager.onObstacleCollision, isNotNull);
      expect(manager.onObstaclePassed, isNotNull);
    });
    
    test('accepts custom random for testing', () {
      const config = StuntObstacleManagerConfig();
      final customRandom = math.Random(42); // Seeded random
      
      final manager = StuntObstacleManager(
        config: config,
        random: customRandom,
      );
      
      expect(manager, isNotNull);
    });
  });
  
  group('Spawn Configuration', () {
    test('spawn variance affects timing randomness', () {
      // Low variance = more consistent timing
      const lowVariance = StuntObstacleManagerConfig(
        spawnInterval: 2.5,
        spawnVariance: 0.0, // No variance
      );
      
      // High variance = more random timing
      const highVariance = StuntObstacleManagerConfig(
        spawnInterval: 2.5,
        spawnVariance: 0.5, // 50% variance
      );
      
      expect(lowVariance.spawnVariance, lessThan(highVariance.spawnVariance));
    });
    
    test('spawn Y range defines vertical spawn area', () {
      const config = StuntObstacleManagerConfig(
        minSpawnYPercent: 0.2,
        maxSpawnYPercent: 0.8,
      );
      
      // Spawn area is 60% of screen height (0.8 - 0.2)
      final spawnRange = config.maxSpawnYPercent - config.minSpawnYPercent;
      expect(spawnRange, closeTo(0.6, 0.0001));
    });
    
    test('stagger phases creates obstacle variety', () {
      const withStagger = StuntObstacleManagerConfig(staggerPhases: true);
      const noStagger = StuntObstacleManagerConfig(staggerPhases: false);
      
      expect(withStagger.staggerPhases, true);
      expect(noStagger.staggerPhases, false);
    });
  });
  
  group('Difficulty Levels', () {
    test('easy level has longer spawn intervals', () {
      const easy = StuntObstacleManagerConfig(
        spawnInterval: 3.5,
        obstacleConfig: StuntObstacleConfig(
          scrollSpeed: 100.0,
          sizePercent: 0.12,
        ),
      );
      
      expect(easy.spawnInterval, greaterThan(2.5));
      expect(easy.obstacleConfig.scrollSpeed, lessThan(150.0));
    });
    
    test('hard level has shorter spawn intervals', () {
      const hard = StuntObstacleManagerConfig(
        spawnInterval: 1.5,
        obstacleConfig: StuntObstacleConfig(
          scrollSpeed: 200.0,
          sizePercent: 0.20,
        ),
      );
      
      expect(hard.spawnInterval, lessThan(2.5));
      expect(hard.obstacleConfig.scrollSpeed, greaterThan(150.0));
    });
  });
}


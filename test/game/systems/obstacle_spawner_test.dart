/// 🎮 OBSTACLE SPAWNER - Unit Tests
/// 
/// Tests for the unified obstacle spawning interface.
import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/game/systems/obstacle_spawner.dart';

void main() {
  group('ObstacleType', () {
    test('has all expected values', () {
      expect(ObstacleType.values, contains(ObstacleType.pillarPair));
      expect(ObstacleType.values, contains(ObstacleType.singleVertical));
      expect(ObstacleType.values, contains(ObstacleType.singleApproaching));
      expect(ObstacleType.values, contains(ObstacleType.singleDiagonal));
      expect(ObstacleType.values, contains(ObstacleType.mixed));
      expect(ObstacleType.values.length, 5);
    });
  });
  
  group('ObstacleSpawnerConfig', () {
    test('creates default config', () {
      const config = ObstacleSpawnerConfig();
      
      expect(config.primaryType, ObstacleType.pillarPair);
      expect(config.spawnInterval, 2.5);
      expect(config.spawnVariance, 0.2);
      expect(config.scrollSpeed, 150.0);
      expect(config.typeWeights, isNull);
      expect(config.assetPath, isNull);
      expect(config.params, isEmpty);
    });
    
    test('pillarPair factory creates correct config', () {
      final config = ObstacleSpawnerConfig.pillarPair(
        spawnInterval: 3.0,
        scrollSpeed: 200.0,
        gapSize: 400.0,
        maxGapShift: 60.0,
      );
      
      expect(config.primaryType, ObstacleType.pillarPair);
      expect(config.spawnInterval, 3.0);
      expect(config.scrollSpeed, 200.0);
      expect(config.params['gap_size'], 400.0);
      expect(config.params['max_gap_shift'], 60.0);
    });
    
    test('singleVertical factory creates correct config', () {
      final config = ObstacleSpawnerConfig.singleVertical(
        spawnInterval: 2.0,
        scrollSpeed: 150.0,
        sizePercent: 0.2,
        verticalAmplitude: 0.4,
        verticalFrequency: 0.5,
      );
      
      expect(config.primaryType, ObstacleType.singleVertical);
      expect(config.spawnInterval, 2.0);
      expect(config.scrollSpeed, 150.0);
      expect(config.params['size_percent'], 0.2);
      expect(config.params['vertical_amplitude_percent'], 0.4);
      expect(config.params['vertical_frequency'], 0.5);
    });
    
    test('mixed factory creates correct config', () {
      final config = ObstacleSpawnerConfig.mixed(
        typeWeights: {
          ObstacleType.pillarPair: 50,
          ObstacleType.singleVertical: 30,
          ObstacleType.singleDiagonal: 20,
        },
        spawnInterval: 2.5,
      );
      
      expect(config.primaryType, ObstacleType.mixed);
      expect(config.typeWeights, isNotNull);
      expect(config.typeWeights![ObstacleType.pillarPair], 50);
      expect(config.typeWeights![ObstacleType.singleVertical], 30);
      expect(config.typeWeights![ObstacleType.singleDiagonal], 20);
    });
    
    test('fromJson parses pillar_pair type', () {
      final json = {
        'obstacle_type': 'pillar_pair',
        'spawn_interval': 3.0,
        'scroll_speed': 180.0,
      };
      
      final config = ObstacleSpawnerConfig.fromJson(json);
      
      expect(config.primaryType, ObstacleType.pillarPair);
      expect(config.spawnInterval, 3.0);
      expect(config.scrollSpeed, 180.0);
    });
    
    test('fromJson parses single_vertical type', () {
      final json = {
        'obstacle_type': 'single_vertical',
        'spawn_interval': 2.5,
        'params': {
          'size_percent': 0.15,
        },
      };
      
      final config = ObstacleSpawnerConfig.fromJson(json);
      
      expect(config.primaryType, ObstacleType.singleVertical);
      expect(config.params['size_percent'], 0.15);
    });
    
    test('fromJson parses type_weights', () {
      final json = {
        'obstacle_type': 'mixed',
        'type_weights': {
          'pillar_pair': 60,
          'single_vertical': 40,
        },
      };
      
      final config = ObstacleSpawnerConfig.fromJson(json);
      
      expect(config.primaryType, ObstacleType.mixed);
      expect(config.typeWeights, isNotNull);
      expect(config.typeWeights![ObstacleType.pillarPair], 60);
      expect(config.typeWeights![ObstacleType.singleVertical], 40);
    });
    
    test('fromJson handles missing fields with defaults', () {
      final config = ObstacleSpawnerConfig.fromJson({});
      
      expect(config.primaryType, ObstacleType.pillarPair);
      expect(config.spawnInterval, 2.5);
      expect(config.spawnVariance, 0.2);
      expect(config.scrollSpeed, 150.0);
    });
    
    test('toString provides readable description', () {
      const config = ObstacleSpawnerConfig();
      final str = config.toString();
      
      expect(str, contains('pillarPair'));
      expect(str, contains('2.5'));
    });
  });
  
  group('PillarPairSpawnerAdapter', () {
    test('initializes with correct default state', () {
      final adapter = PillarPairSpawnerAdapter();
      
      expect(adapter.isPaused, false);
      expect(adapter.isActive, false);
      expect(adapter.activeObstacleCount, 0);
      expect(adapter.totalSpawned, 0);
    });
    
    test('startSpawning sets isActive to true', () {
      final adapter = PillarPairSpawnerAdapter();
      
      adapter.startSpawning();
      
      expect(adapter.isActive, true);
    });
    
    test('stopSpawning sets isActive to false', () {
      final adapter = PillarPairSpawnerAdapter();
      adapter.startSpawning();
      
      adapter.stopSpawning();
      
      expect(adapter.isActive, false);
    });
    
    test('pause sets isPaused to true', () {
      final adapter = PillarPairSpawnerAdapter();
      
      adapter.pause();
      
      expect(adapter.isPaused, true);
    });
    
    test('resume sets isPaused to false', () {
      final adapter = PillarPairSpawnerAdapter();
      adapter.pause();
      
      adapter.resume();
      
      expect(adapter.isPaused, false);
    });
    
    test('reset clears all state', () {
      final adapter = PillarPairSpawnerAdapter();
      adapter.startSpawning();
      adapter.pause();
      
      adapter.reset();
      
      expect(adapter.isPaused, false);
      expect(adapter.isActive, false);
      expect(adapter.totalSpawned, 0);
    });
    
    test('callbacks can be set', () {
      final adapter = PillarPairSpawnerAdapter();
      
      adapter.onObstaclePassed = () {};
      adapter.onObstacleCollision = () {};
      
      expect(adapter.onObstaclePassed, isNotNull);
      expect(adapter.onObstacleCollision, isNotNull);
    });
  });
  
  group('Obstacle Type Parsing', () {
    test('parses all snake_case types', () {
      final types = [
        ('pillar_pair', ObstacleType.pillarPair),
        ('single_vertical', ObstacleType.singleVertical),
        ('single_approaching', ObstacleType.singleApproaching),
        ('single_diagonal', ObstacleType.singleDiagonal),
        ('mixed', ObstacleType.mixed),
      ];
      
      for (final (typeStr, expected) in types) {
        final json = {'obstacle_type': typeStr};
        final config = ObstacleSpawnerConfig.fromJson(json);
        expect(config.primaryType, expected, reason: 'Failed for $typeStr');
      }
    });
    
    test('parses all camelCase types', () {
      final types = [
        ('pillarPair', ObstacleType.pillarPair),
        ('singleVertical', ObstacleType.singleVertical),
        ('singleApproaching', ObstacleType.singleApproaching),
        ('singleDiagonal', ObstacleType.singleDiagonal),
      ];
      
      for (final (typeStr, expected) in types) {
        final json = {'obstacle_type': typeStr};
        final config = ObstacleSpawnerConfig.fromJson(json);
        expect(config.primaryType, expected, reason: 'Failed for $typeStr');
      }
    });
    
    test('defaults to pillarPair for unknown types', () {
      final json = {'obstacle_type': 'unknown_type'};
      final config = ObstacleSpawnerConfig.fromJson(json);
      
      expect(config.primaryType, ObstacleType.pillarPair);
    });
  });
}


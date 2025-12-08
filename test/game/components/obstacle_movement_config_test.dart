import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/game/components/obstacle_movement_config.dart';
import 'package:flappy_jet_pro/models/tournament_config.dart';

void main() {
  group('MovementType', () {
    test('has all expected types', () {
      expect(MovementType.values, hasLength(4));
      expect(MovementType.values, contains(MovementType.static));
      expect(MovementType.values, contains(MovementType.verticalOscillate));
      expect(MovementType.values, contains(MovementType.horizontalApproach));
      expect(MovementType.values, contains(MovementType.diagonal));
    });
  });

  group('ObstacleMovementConfig', () {
    group('Construction', () {
      test('default constructor creates static config', () {
        const config = ObstacleMovementConfig();
        
        expect(config.type, equals(MovementType.static));
        expect(config.hasMovement, isFalse);
        expect(config.amplitude, equals(0.0));
        expect(config.frequency, equals(0.0));
        expect(config.approachSpeed, equals(0.0));
        expect(config.angle, equals(0.0));
        expect(config.diagonalSpeed, equals(0.0));
        expect(config.phaseOffset, equals(0.0));
      });

      test('none constant is static', () {
        expect(ObstacleMovementConfig.none.type, equals(MovementType.static));
        expect(ObstacleMovementConfig.none.hasMovement, isFalse);
      });

      test('verticalOscillate factory creates correct config', () {
        final config = ObstacleMovementConfig.verticalOscillate(
          amplitude: 50.0,
          frequency: 0.8,
          phaseOffset: 0.25,
        );
        
        expect(config.type, equals(MovementType.verticalOscillate));
        expect(config.hasMovement, isTrue);
        expect(config.amplitude, equals(50.0));
        expect(config.frequency, equals(0.8));
        expect(config.phaseOffset, equals(0.25));
      });

      test('horizontalApproach factory creates correct config', () {
        final config = ObstacleMovementConfig.horizontalApproach(
          approachSpeed: 75.0,
          phaseOffset: 0.5,
        );
        
        expect(config.type, equals(MovementType.horizontalApproach));
        expect(config.hasMovement, isTrue);
        expect(config.approachSpeed, equals(75.0));
        expect(config.phaseOffset, equals(0.5));
      });

      test('diagonal factory creates correct config', () {
        final config = ObstacleMovementConfig.diagonal(
          angle: 30.0,
          speed: 60.0,
          phaseOffset: 0.75,
        );
        
        expect(config.type, equals(MovementType.diagonal));
        expect(config.hasMovement, isTrue);
        expect(config.angle, equals(30.0));
        expect(config.diagonalSpeed, equals(60.0));
        expect(config.phaseOffset, equals(0.75));
      });
    });

    group('fromPattern', () {
      test('parses static pattern', () {
        const pattern = ObstaclePattern(
          type: ObstaclePatternType.static,
          weight: 100,
        );
        
        final config = ObstacleMovementConfig.fromPattern(pattern);
        
        expect(config.type, equals(MovementType.static));
        expect(config.hasMovement, isFalse);
      });

      test('parses verticalOscillate pattern', () {
        const pattern = ObstaclePattern(
          type: ObstaclePatternType.verticalOscillate,
          weight: 50,
          params: {
            'amplitude': 40,
            'frequency': 0.6,
          },
        );
        
        final config = ObstacleMovementConfig.fromPattern(pattern);
        
        expect(config.type, equals(MovementType.verticalOscillate));
        expect(config.amplitude, equals(40.0));
        expect(config.frequency, equals(0.6));
      });

      test('parses horizontalApproach pattern', () {
        const pattern = ObstaclePattern(
          type: ObstaclePatternType.horizontalApproach,
          weight: 30,
          params: {
            'approachSpeed': 55,
          },
        );
        
        final config = ObstacleMovementConfig.fromPattern(pattern);
        
        expect(config.type, equals(MovementType.horizontalApproach));
        expect(config.approachSpeed, equals(55.0));
      });

      test('parses diagonal pattern', () {
        const pattern = ObstaclePattern(
          type: ObstaclePatternType.diagonal,
          weight: 20,
          params: {
            'angle': 20,
            'speed': 45,
          },
        );
        
        final config = ObstacleMovementConfig.fromPattern(pattern);
        
        expect(config.type, equals(MovementType.diagonal));
        expect(config.angle, equals(20.0));
        expect(config.diagonalSpeed, equals(45.0));
      });

      test('uses defaults for missing params', () {
        const pattern = ObstaclePattern(
          type: ObstaclePatternType.verticalOscillate,
          weight: 100,
          params: {}, // Empty params
        );
        
        final config = ObstacleMovementConfig.fromPattern(pattern);
        
        expect(config.amplitude, equals(30.0)); // Default
        expect(config.frequency, equals(0.5)); // Default
      });

      test('applies phaseOffset', () {
        const pattern = ObstaclePattern(
          type: ObstaclePatternType.verticalOscillate,
          weight: 100,
        );
        
        final config = ObstacleMovementConfig.fromPattern(
          pattern,
          phaseOffset: 0.5,
        );
        
        expect(config.phaseOffset, equals(0.5));
      });
    });

    group('Calculated properties', () {
      test('angularFrequency is correct', () {
        final config = ObstacleMovementConfig.verticalOscillate(
          amplitude: 30.0,
          frequency: 1.0, // 1 Hz = 2π rad/s
        );
        
        expect(config.angularFrequency, closeTo(2 * math.pi, 0.001));
      });

      test('angleRadians is correct', () {
        final config = ObstacleMovementConfig.diagonal(
          angle: 90.0,
          speed: 50.0,
        );
        
        expect(config.angleRadians, closeTo(math.pi / 2, 0.001));
      });

      test('diagonal velocity components are correct', () {
        final config = ObstacleMovementConfig.diagonal(
          angle: 45.0,
          speed: 100.0,
        );
        
        // At 45 degrees, both components should be equal
        expect(config.diagonalVelocityX, closeTo(config.diagonalVelocityY, 0.001));
        // And magnitude should be ~70.7 each (100 / sqrt(2))
        expect(config.diagonalVelocityX, closeTo(70.71, 0.1));
      });

      test('diagonal at 0 degrees moves right', () {
        final config = ObstacleMovementConfig.diagonal(
          angle: 0.0,
          speed: 100.0,
        );
        
        expect(config.diagonalVelocityX, closeTo(100.0, 0.001));
        expect(config.diagonalVelocityY, closeTo(0.0, 0.001));
      });

      test('diagonal at 90 degrees moves down', () {
        final config = ObstacleMovementConfig.diagonal(
          angle: 90.0,
          speed: 100.0,
        );
        
        expect(config.diagonalVelocityX, closeTo(0.0, 0.001));
        expect(config.diagonalVelocityY, closeTo(100.0, 0.001));
      });
    });

    group('Equality', () {
      test('equal configs are equal', () {
        final config1 = ObstacleMovementConfig.verticalOscillate(
          amplitude: 30.0,
          frequency: 0.5,
        );
        final config2 = ObstacleMovementConfig.verticalOscillate(
          amplitude: 30.0,
          frequency: 0.5,
        );
        
        expect(config1, equals(config2));
        expect(config1.hashCode, equals(config2.hashCode));
      });

      test('different configs are not equal', () {
        final config1 = ObstacleMovementConfig.verticalOscillate(
          amplitude: 30.0,
          frequency: 0.5,
        );
        final config2 = ObstacleMovementConfig.verticalOscillate(
          amplitude: 40.0,
          frequency: 0.5,
        );
        
        expect(config1, isNot(equals(config2)));
      });
    });

    group('toString', () {
      test('static config', () {
        expect(ObstacleMovementConfig.none.toString(), contains('Static'));
      });

      test('verticalOscillate config', () {
        final config = ObstacleMovementConfig.verticalOscillate(
          amplitude: 30.0,
          frequency: 0.5,
        );
        expect(config.toString(), contains('VerticalOscillate'));
        expect(config.toString(), contains('30'));
        expect(config.toString(), contains('0.5'));
      });

      test('horizontalApproach config', () {
        final config = ObstacleMovementConfig.horizontalApproach(
          approachSpeed: 50.0,
        );
        expect(config.toString(), contains('HorizontalApproach'));
        expect(config.toString(), contains('50'));
      });

      test('diagonal config', () {
        final config = ObstacleMovementConfig.diagonal(
          angle: 15.0,
          speed: 40.0,
        );
        expect(config.toString(), contains('Diagonal'));
        expect(config.toString(), contains('15'));
        expect(config.toString(), contains('40'));
      });
    });
  });

  group('ObstaclePatternSelector', () {
    test('returns default pattern for empty list', () {
      final selector = ObstaclePatternSelector(patterns: []);
      
      final pattern = selector.selectPattern();
      
      expect(pattern.type, equals(ObstaclePatternType.static));
      expect(pattern.weight, equals(100));
    });

    test('returns only pattern for single-element list', () {
      final selector = ObstaclePatternSelector(patterns: [
        const ObstaclePattern(
          type: ObstaclePatternType.verticalOscillate,
          weight: 50,
        ),
      ]);
      
      final pattern = selector.selectPattern();
      
      expect(pattern.type, equals(ObstaclePatternType.verticalOscillate));
    });

    test('respects weights over many selections', () {
      final selector = ObstaclePatternSelector(
        patterns: [
          const ObstaclePattern(
            type: ObstaclePatternType.static,
            weight: 80,
          ),
          const ObstaclePattern(
            type: ObstaclePatternType.verticalOscillate,
            weight: 20,
          ),
        ],
        random: math.Random(42), // Fixed seed for reproducibility
      );
      
      int staticCount = 0;
      int oscillateCount = 0;
      
      for (int i = 0; i < 1000; i++) {
        final pattern = selector.selectPattern();
        if (pattern.type == ObstaclePatternType.static) {
          staticCount++;
        } else {
          oscillateCount++;
        }
      }
      
      // Should be roughly 80/20 ratio (allowing for randomness)
      expect(staticCount, greaterThan(700));
      expect(oscillateCount, lessThan(300));
      expect(staticCount, greaterThan(oscillateCount * 2));
    });

    test('selectMovementConfig returns config with phase offset', () {
      final selector = ObstaclePatternSelector(patterns: [
        const ObstaclePattern(
          type: ObstaclePatternType.verticalOscillate,
          weight: 100,
          params: {'amplitude': 30, 'frequency': 0.5},
        ),
      ]);
      
      final config1 = selector.selectMovementConfig();
      final config2 = selector.selectMovementConfig();
      
      // Phase offsets should be different (staggered)
      expect(config1.phaseOffset, isNot(equals(config2.phaseOffset)));
    });

    test('reset clears spawn count', () {
      final selector = ObstaclePatternSelector(patterns: [
        const ObstaclePattern(
          type: ObstaclePatternType.verticalOscillate,
          weight: 100,
        ),
      ]);
      
      selector.selectMovementConfig();
      selector.selectMovementConfig();
      selector.reset();
      
      // After reset, first spawn should have 0.25 phase offset again
      final config = selector.selectMovementConfig();
      expect(config.phaseOffset, equals(0.25));
    });
  });
}


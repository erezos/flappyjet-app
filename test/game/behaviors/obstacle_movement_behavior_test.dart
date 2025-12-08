import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/game/components/obstacle_movement_config.dart';
import 'package:flappy_jet_pro/game/behaviors/obstacle_movement_behavior.dart';

void main() {
  group('ObstacleMovementBehavior', () {
    group('Static movement', () {
      testWithFlameGame(
        'does not modify position',
        (game) async {
          final parent = PositionComponent(position: Vector2(100, 200));
          await game.add(parent);
          await game.ready();
          
          final behavior = ObstacleMovementBehavior(
            config: const ObstacleMovementConfig(),
            basePositionY: 200,
          );
          await parent.add(behavior);
          await game.ready();
          
          final initialPosition = parent.position.clone();
          
          // Update multiple times
          game.update(0.1);
          game.update(0.1);
          game.update(0.1);
          
          expect(parent.position, equals(initialPosition));
        },
      );
    });

    group('Vertical oscillation', () {
      testWithFlameGame(
        'oscillates around base position',
        (game) async {
          final parent = PositionComponent(position: Vector2(100, 200));
          await game.add(parent);
          await game.ready();
          
          final behavior = ObstacleMovementBehavior(
            config: ObstacleMovementConfig.verticalOscillate(
              amplitude: 50.0,
              frequency: 1.0, // 1 Hz = complete cycle per second
            ),
            basePositionY: 200,
            clampToScreen: false, // Disable clamping for test
          );
          await parent.add(behavior);
          await game.ready();
          
          // At t=0, sin(0) = 0, so position should be at base
          expect(parent.position.y, closeTo(200, 1));
          
          // At t=0.25s (1/4 cycle), sin(π/2) = 1, so position should be at base + amplitude
          game.update(0.25);
          expect(parent.position.y, closeTo(250, 1));
          
          // At t=0.5s (1/2 cycle), sin(π) = 0, so position should be at base
          game.update(0.25);
          expect(parent.position.y, closeTo(200, 1));
          
          // At t=0.75s (3/4 cycle), sin(3π/2) = -1, so position should be at base - amplitude
          game.update(0.25);
          expect(parent.position.y, closeTo(150, 1));
          
          // At t=1.0s (full cycle), sin(2π) = 0, so position should be at base
          game.update(0.25);
          expect(parent.position.y, closeTo(200, 1));
        },
      );

      testWithFlameGame(
        'respects phase offset',
        (game) async {
          final parent = PositionComponent(position: Vector2(100, 200));
          await game.add(parent);
          await game.ready();
          
          // Phase offset of 0.25 = π/2 radians, so sin(π/2) = 1 at t=0
          final behavior = ObstacleMovementBehavior(
            config: ObstacleMovementConfig.verticalOscillate(
              amplitude: 50.0,
              frequency: 1.0,
              phaseOffset: 0.25,
            ),
            basePositionY: 200,
            clampToScreen: false,
          );
          await parent.add(behavior);
          await game.ready();
          
          // At t=0, with phase offset 0.25, should already be at peak
          game.update(0.001); // Small update to apply behavior
          expect(parent.position.y, closeTo(250, 2));
        },
      );

      testWithFlameGame(
        'amplitude controls range of motion',
        (game) async {
          final parent = PositionComponent(position: Vector2(100, 200));
          await game.add(parent);
          await game.ready();
          
          final behavior = ObstacleMovementBehavior(
            config: ObstacleMovementConfig.verticalOscillate(
              amplitude: 100.0, // Large amplitude
              frequency: 1.0,
            ),
            basePositionY: 200,
            clampToScreen: false,
          );
          await parent.add(behavior);
          await game.ready();
          
          // Track min and max Y positions
          double minY = parent.position.y;
          double maxY = parent.position.y;
          
          // Run for a full cycle
          for (int i = 0; i < 100; i++) {
            game.update(0.01);
            minY = math.min(minY, parent.position.y);
            maxY = math.max(maxY, parent.position.y);
          }
          
          // Should oscillate between 100 and 300 (200 ± 100)
          expect(minY, closeTo(100, 5));
          expect(maxY, closeTo(300, 5));
        },
      );
    });

    group('Horizontal approach', () {
      testWithFlameGame(
        'moves left (towards player)',
        (game) async {
          final parent = PositionComponent(position: Vector2(500, 200));
          await game.add(parent);
          await game.ready();
          
          final behavior = ObstacleMovementBehavior(
            config: ObstacleMovementConfig.horizontalApproach(
              approachSpeed: 100.0, // 100 pixels/second
            ),
            basePositionY: 200,
          );
          await parent.add(behavior);
          await game.ready();
          
          final initialX = parent.position.x;
          
          // Update for 1 second
          game.update(1.0);
          
          // Should have moved 100 pixels to the left
          expect(parent.position.x, closeTo(initialX - 100, 1));
          expect(parent.position.y, equals(200)); // Y unchanged
        },
      );

      testWithFlameGame(
        'approach speed is cumulative',
        (game) async {
          final parent = PositionComponent(position: Vector2(1000, 200));
          await game.add(parent);
          await game.ready();
          
          final behavior = ObstacleMovementBehavior(
            config: ObstacleMovementConfig.horizontalApproach(
              approachSpeed: 50.0,
            ),
            basePositionY: 200,
          );
          await parent.add(behavior);
          await game.ready();
          
          // Update multiple times
          game.update(0.5); // -25
          game.update(0.5); // -25
          game.update(1.0); // -50
          
          // Total: -100 pixels
          expect(parent.position.x, closeTo(900, 1));
        },
      );
    });

    group('Diagonal movement', () {
      testWithFlameGame(
        'moves at specified angle',
        (game) async {
          final parent = PositionComponent(position: Vector2(500, 200));
          await game.add(parent);
          await game.ready();
          
          final behavior = ObstacleMovementBehavior(
            config: ObstacleMovementConfig.diagonal(
              angle: 45.0,
              speed: 100.0,
            ),
            basePositionY: 200,
            clampToScreen: false,
          );
          await parent.add(behavior);
          await game.ready();
          
          final initialPos = parent.position.clone();
          
          game.update(1.0);
          
          // At 45 degrees, movement should be equal in X and Y
          // X moves left (negative direction in approach)
          final deltaX = parent.position.x - initialPos.x;
          final deltaY = parent.position.y - initialPos.y;
          
          // Both deltas should have same magnitude (~70.7)
          expect(deltaX.abs(), closeTo(deltaY.abs(), 1));
        },
      );

      testWithFlameGame(
        '0 degree angle moves right',
        (game) async {
          final parent = PositionComponent(position: Vector2(500, 200));
          await game.add(parent);
          await game.ready();
          
          final behavior = ObstacleMovementBehavior(
            config: ObstacleMovementConfig.diagonal(
              angle: 0.0,
              speed: 100.0,
            ),
            basePositionY: 200,
            clampToScreen: false,
          );
          await parent.add(behavior);
          await game.ready();
          
          game.update(1.0);
          
          // Should move 100 pixels left (negative X) due to approach direction
          expect(parent.position.x, closeTo(400, 1));
          expect(parent.position.y, closeTo(200, 0.1)); // Y unchanged
        },
      );

      testWithFlameGame(
        '90 degree angle moves down',
        (game) async {
          final parent = PositionComponent(position: Vector2(500, 200));
          await game.add(parent);
          await game.ready();
          
          final behavior = ObstacleMovementBehavior(
            config: ObstacleMovementConfig.diagonal(
              angle: 90.0,
              speed: 100.0,
            ),
            basePositionY: 200,
            clampToScreen: false,
          );
          await parent.add(behavior);
          await game.ready();
          
          game.update(1.0);
          
          // Should move 100 pixels down
          expect(parent.position.x, closeTo(500, 0.1)); // X nearly unchanged
          expect(parent.position.y, closeTo(300, 1));
        },
      );
    });

    group('Screen clamping', () {
      testWithFlameGame(
        'clamps to minY',
        (game) async {
          final parent = PositionComponent(position: Vector2(100, 200));
          await game.add(parent);
          await game.ready();
          
          final behavior = ObstacleMovementBehavior(
            config: ObstacleMovementConfig.verticalOscillate(
              amplitude: 300.0, // Very large amplitude
              frequency: 1.0,
            ),
            basePositionY: 200,
            minY: 50.0,
            maxY: 350.0,
            clampToScreen: true,
          );
          await parent.add(behavior);
          await game.ready();
          
          // Run through a full cycle
          double minY = double.infinity;
          for (int i = 0; i < 100; i++) {
            game.update(0.01);
            minY = math.min(minY, parent.position.y);
          }
          
          // Should not go below minY
          expect(minY, greaterThanOrEqualTo(50.0));
        },
      );

      testWithFlameGame(
        'clamps to maxY',
        (game) async {
          final parent = PositionComponent(position: Vector2(100, 200));
          await game.add(parent);
          await game.ready();
          
          final behavior = ObstacleMovementBehavior(
            config: ObstacleMovementConfig.verticalOscillate(
              amplitude: 300.0,
              frequency: 1.0,
            ),
            basePositionY: 200,
            minY: 50.0,
            maxY: 350.0,
            clampToScreen: true,
          );
          await parent.add(behavior);
          await game.ready();
          
          double maxY = double.negativeInfinity;
          for (int i = 0; i < 100; i++) {
            game.update(0.01);
            maxY = math.max(maxY, parent.position.y);
          }
          
          // Should not exceed maxY
          expect(maxY, lessThanOrEqualTo(350.0));
        },
      );

      testWithFlameGame(
        'no clamping when disabled',
        (game) async {
          final parent = PositionComponent(position: Vector2(100, 200));
          await game.add(parent);
          await game.ready();
          
          final behavior = ObstacleMovementBehavior(
            config: ObstacleMovementConfig.verticalOscillate(
              amplitude: 300.0,
              frequency: 1.0,
            ),
            basePositionY: 200,
            minY: 50.0,
            maxY: 350.0,
            clampToScreen: false, // Disabled
          );
          await parent.add(behavior);
          await game.ready();
          
          double minY = double.infinity;
          double maxY = double.negativeInfinity;
          for (int i = 0; i < 100; i++) {
            game.update(0.01);
            minY = math.min(minY, parent.position.y);
            maxY = math.max(maxY, parent.position.y);
          }
          
          // Should go beyond bounds when clamping is disabled
          expect(minY, lessThan(50.0));
          expect(maxY, greaterThan(350.0));
        },
      );
    });

    group('Utility methods', () {
      testWithFlameGame(
        'reset clears elapsed time',
        (game) async {
          final parent = PositionComponent(position: Vector2(100, 200));
          await game.add(parent);
          await game.ready();
          
          final behavior = ObstacleMovementBehavior(
            config: ObstacleMovementConfig.verticalOscillate(
              amplitude: 50.0,
              frequency: 1.0,
            ),
            basePositionY: 200,
            clampToScreen: false,
          );
          await parent.add(behavior);
          await game.ready();
          
          // Advance time
          game.update(0.25);
          final posBeforeReset = parent.position.y;
          
          // Reset
          behavior.reset();
          game.update(0.001);
          
          // Should be back to base position (sin(0) = 0)
          expect(parent.position.y, closeTo(200, 1));
          expect(parent.position.y, isNot(equals(posBeforeReset)));
        },
      );

      testWithFlameGame(
        'oscillationPhase returns normalized phase',
        (game) async {
          final parent = PositionComponent(position: Vector2(100, 200));
          await game.add(parent);
          await game.ready();
          
          final behavior = ObstacleMovementBehavior(
            config: ObstacleMovementConfig.verticalOscillate(
              amplitude: 50.0,
              frequency: 1.0,
            ),
            basePositionY: 200,
          );
          await parent.add(behavior);
          await game.ready();
          
          expect(behavior.oscillationPhase, closeTo(0.0, 0.01));
          
          game.update(0.25);
          expect(behavior.oscillationPhase, closeTo(0.25, 0.01));
          
          game.update(0.25);
          expect(behavior.oscillationPhase, closeTo(0.5, 0.01));
          
          game.update(0.5);
          expect(behavior.oscillationPhase, closeTo(0.0, 0.01)); // Wrapped
        },
      );

      testWithFlameGame(
        'currentOffset returns vertical offset for oscillation',
        (game) async {
          final parent = PositionComponent(position: Vector2(100, 200));
          await game.add(parent);
          await game.ready();
          
          final behavior = ObstacleMovementBehavior(
            config: ObstacleMovementConfig.verticalOscillate(
              amplitude: 50.0,
              frequency: 1.0,
            ),
            basePositionY: 200,
            clampToScreen: false,
          );
          await parent.add(behavior);
          await game.ready();
          
          game.update(0.25);
          
          final offset = behavior.currentOffset;
          expect(offset.x, equals(0.0));
          expect(offset.y, closeTo(50.0, 1)); // At peak
        },
      );

      testWithFlameGame(
        'toString includes type and elapsed time',
        (game) async {
          final parent = PositionComponent(position: Vector2(100, 200));
          await game.add(parent);
          await game.ready();
          
          final behavior = ObstacleMovementBehavior(
            config: ObstacleMovementConfig.verticalOscillate(
              amplitude: 50.0,
              frequency: 1.0,
            ),
            basePositionY: 200,
          );
          await parent.add(behavior);
          await game.ready();
          
          expect(behavior.toString(), contains('verticalOscillate'));
          expect(behavior.toString(), contains('elapsed'));
        },
      );
    });
  });

  group('ObstacleMovementExtension', () {
    testWithFlameGame(
      'addMovementBehavior adds behavior',
      (game) async {
        final parent = PositionComponent(position: Vector2(100, 200));
        await game.add(parent);
        await game.ready();
        
        await parent.addMovementBehavior(
          config: ObstacleMovementConfig.verticalOscillate(
            amplitude: 30.0,
            frequency: 0.5,
          ),
        );
        await game.ready();
        
        expect(parent.movementBehavior, isNotNull);
        expect(parent.movementBehavior!.config.type, equals(MovementType.verticalOscillate));
      },
    );

    testWithFlameGame(
      'movementBehavior returns null when not attached',
      (game) async {
        final parent = PositionComponent(position: Vector2(100, 200));
        await game.add(parent);
        await game.ready();
        
        expect(parent.movementBehavior, isNull);
      },
    );
  });
}

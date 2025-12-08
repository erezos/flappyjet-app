import 'dart:math' as math;
import '../../models/tournament_config.dart';

/// 🎮 Obstacle Movement Configuration
/// 
/// Defines movement patterns for dynamic obstacles in tournaments.
/// Supports multiple movement types: oscillation, approach, diagonal.
/// 
/// ✅ Flame Best Practices:
/// - Immutable configuration object (no runtime modifications)
/// - Pre-calculated values for zero per-frame allocations
/// - Clean separation from rendering logic
/// - Fully testable in isolation

/// Movement type enum (mirrors ObstaclePatternType for internal use)
enum MovementType {
  /// No movement - standard static obstacle
  static,
  
  /// Oscillates vertically (up and down)
  /// params: amplitude (pixels), frequency (Hz)
  verticalOscillate,
  
  /// Approaches the player (moves left faster than base speed)
  /// params: approachSpeed (extra pixels/second)
  horizontalApproach,
  
  /// Moves diagonally
  /// params: angle (degrees), speed (pixels/second)
  diagonal,
}

/// Immutable configuration for obstacle movement
class ObstacleMovementConfig {
  /// Type of movement pattern
  final MovementType type;
  
  /// Vertical oscillation amplitude in pixels (for verticalOscillate)
  final double amplitude;
  
  /// Oscillation frequency in Hz (for verticalOscillate)
  final double frequency;
  
  /// Extra approach speed in pixels/second (for horizontalApproach)
  final double approachSpeed;
  
  /// Movement angle in degrees (for diagonal) - 0 = right, 90 = down
  final double angle;
  
  /// Diagonal movement speed in pixels/second
  final double diagonalSpeed;
  
  /// Pre-calculated phase offset for staggered patterns (0-1)
  final double phaseOffset;

  const ObstacleMovementConfig({
    this.type = MovementType.static,
    this.amplitude = 0.0,
    this.frequency = 0.0,
    this.approachSpeed = 0.0,
    this.angle = 0.0,
    this.diagonalSpeed = 0.0,
    this.phaseOffset = 0.0,
  });

  /// Create a static (non-moving) config
  static const ObstacleMovementConfig none = ObstacleMovementConfig();

  /// Create from ObstaclePattern (tournament JSON format)
  factory ObstacleMovementConfig.fromPattern(
    ObstaclePattern pattern, {
    double? phaseOffset,
  }) {
    final offset = phaseOffset ?? 0.0;
    
    switch (pattern.type) {
      case ObstaclePatternType.static:
        return const ObstacleMovementConfig();
        
      case ObstaclePatternType.verticalOscillate:
        return ObstacleMovementConfig(
          type: MovementType.verticalOscillate,
          amplitude: (pattern.params['amplitude'] as num?)?.toDouble() ?? 30.0,
          frequency: (pattern.params['frequency'] as num?)?.toDouble() ?? 0.5,
          phaseOffset: offset,
        );
        
      case ObstaclePatternType.horizontalApproach:
        return ObstacleMovementConfig(
          type: MovementType.horizontalApproach,
          approachSpeed: (pattern.params['approachSpeed'] as num?)?.toDouble() ?? 50.0,
          phaseOffset: offset,
        );
        
      case ObstaclePatternType.diagonal:
        return ObstacleMovementConfig(
          type: MovementType.diagonal,
          angle: (pattern.params['angle'] as num?)?.toDouble() ?? 15.0,
          diagonalSpeed: (pattern.params['speed'] as num?)?.toDouble() ?? 40.0,
          phaseOffset: offset,
        );
    }
  }

  /// Create vertical oscillation config
  factory ObstacleMovementConfig.verticalOscillate({
    required double amplitude,
    required double frequency,
    double phaseOffset = 0.0,
  }) {
    return ObstacleMovementConfig(
      type: MovementType.verticalOscillate,
      amplitude: amplitude,
      frequency: frequency,
      phaseOffset: phaseOffset,
    );
  }

  /// Create horizontal approach config
  factory ObstacleMovementConfig.horizontalApproach({
    required double approachSpeed,
    double phaseOffset = 0.0,
  }) {
    return ObstacleMovementConfig(
      type: MovementType.horizontalApproach,
      approachSpeed: approachSpeed,
      phaseOffset: phaseOffset,
    );
  }

  /// Create diagonal movement config
  factory ObstacleMovementConfig.diagonal({
    required double angle,
    required double speed,
    double phaseOffset = 0.0,
  }) {
    return ObstacleMovementConfig(
      type: MovementType.diagonal,
      angle: angle,
      diagonalSpeed: speed,
      phaseOffset: phaseOffset,
    );
  }

  /// Whether this config has any movement
  bool get hasMovement => type != MovementType.static;

  /// Pre-calculate angular frequency for oscillation (rad/s)
  double get angularFrequency => frequency * 2 * math.pi;

  /// Pre-calculate angle in radians for diagonal movement
  double get angleRadians => angle * (math.pi / 180);

  /// Pre-calculate velocity components for diagonal movement
  double get diagonalVelocityX => diagonalSpeed * math.cos(angleRadians);
  double get diagonalVelocityY => diagonalSpeed * math.sin(angleRadians);

  @override
  String toString() {
    switch (type) {
      case MovementType.static:
        return 'Static';
      case MovementType.verticalOscillate:
        return 'VerticalOscillate(amp:${amplitude}px, freq:${frequency}Hz)';
      case MovementType.horizontalApproach:
        return 'HorizontalApproach(speed:${approachSpeed}px/s)';
      case MovementType.diagonal:
        return 'Diagonal(angle:${angle}°, speed:${diagonalSpeed}px/s)';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ObstacleMovementConfig &&
        other.type == type &&
        other.amplitude == amplitude &&
        other.frequency == frequency &&
        other.approachSpeed == approachSpeed &&
        other.angle == angle &&
        other.diagonalSpeed == diagonalSpeed &&
        other.phaseOffset == phaseOffset;
  }

  @override
  int get hashCode => Object.hash(
        type,
        amplitude,
        frequency,
        approachSpeed,
        angle,
        diagonalSpeed,
        phaseOffset,
      );
}

/// Pattern selector utility for weighted random selection
class ObstaclePatternSelector {
  final List<ObstaclePattern> patterns;
  final int _totalWeight;
  final math.Random _random;
  int _spawnCount = 0;

  ObstaclePatternSelector({
    required this.patterns,
    math.Random? random,
  })  : _totalWeight = patterns.fold(0, (sum, p) => sum + p.weight),
        _random = random ?? math.Random();

  /// Select a pattern using weighted random selection
  ObstaclePattern selectPattern() {
    if (patterns.isEmpty) {
      // Return default static pattern if no patterns defined
      return const ObstaclePattern(
        type: ObstaclePatternType.static,
        weight: 100,
      );
    }

    if (patterns.length == 1) {
      return patterns.first;
    }

    final roll = _random.nextInt(_totalWeight);
    int cumulative = 0;

    for (final pattern in patterns) {
      cumulative += pattern.weight;
      if (roll < cumulative) {
        return pattern;
      }
    }

    return patterns.last;
  }

  /// Select pattern and convert to movement config
  ObstacleMovementConfig selectMovementConfig() {
    final pattern = selectPattern();
    _spawnCount++;
    
    // Use spawn count to create varied phase offsets
    final phaseOffset = (_spawnCount * 0.25) % 1.0;
    
    return ObstacleMovementConfig.fromPattern(
      pattern,
      phaseOffset: phaseOffset,
    );
  }

  /// Reset spawn counter (e.g., on level restart)
  void reset() {
    _spawnCount = 0;
  }
}


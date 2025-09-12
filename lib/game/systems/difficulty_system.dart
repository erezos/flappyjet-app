/// 🎯 ENHANCED DIFFICULTY SYSTEM - Score-Based Progression
/// Replaces fragmented difficulty systems with unified, precise control
library;
import '../../core/debug_logger.dart';

/// Represents a difficulty phase with all its properties
class DifficultyPhase {
  final String name;
  final int minScore;
  final int maxScore;
  final double gapSize;
  final double speedMultiplier;
  final String description;
  
  const DifficultyPhase({
    required this.name,
    required this.minScore,
    required this.maxScore,
    required this.gapSize,
    required this.speedMultiplier,
    required this.description,
  });
  
  /// Check if this phase applies to the given score
  bool appliesTo(int score) {
    return score >= minScore && (maxScore == -1 || score <= maxScore);
  }
  
  @override
  String toString() => '$name ($minScore-${maxScore == -1 ? "∞" : maxScore}): gap=$gapSize, speed=${speedMultiplier}x';
}

/// 🎯 DIFFICULTY SYSTEM
/// Implements exact user specifications with framework for visual changes
class DifficultySystem {
  
  /// 🎯 CORE DIFFICULTY PHASES - Exact user specifications
  static const List<DifficultyPhase> _basePhases = [
    DifficultyPhase(
      name: 'Super Easy',
      minScore: 0,
      maxScore: 5,
      gapSize: 320.0,
      speedMultiplier: 1.0,
      description: 'Perfect for beginners - maximum confidence building',
    ),
    DifficultyPhase(
      name: 'Easy',
      minScore: 6,
      maxScore: 15,
      gapSize: 310.0,
      speedMultiplier: 1.05,
      description: 'Gentle introduction to speed',
    ),
    DifficultyPhase(
      name: 'Easy Advance',
      minScore: 16,
      maxScore: 20,
      gapSize: 300.0,
      speedMultiplier: 1.05,
      description: 'Smaller gaps, same speed',
    ),
    DifficultyPhase(
      name: 'Medium',
      minScore: 21,
      maxScore: 25,
      gapSize: 300.0,
      speedMultiplier: 1.1,
      description: 'Speed increases, gaps stay manageable',
    ),
    DifficultyPhase(
      name: 'Medium Advance',
      minScore: 26,
      maxScore: 30,
      gapSize: 290.0,
      speedMultiplier: 1.1,
      description: 'Tighter gaps, consistent speed',
    ),
    DifficultyPhase(
      name: 'Hard',
      minScore: 31,
      maxScore: 40,
      gapSize: 290.0,
      speedMultiplier: 1.15,
      description: 'Faster pace, precision required',
    ),
    DifficultyPhase(
      name: 'Expert',
      minScore: 41,
      maxScore: 50,
      gapSize: 280.0,
      speedMultiplier: 1.15,
      description: 'Narrow gaps, expert reflexes needed',
    ),
    DifficultyPhase(
      name: 'Master',
      minScore: 51,
      maxScore: -1, // Infinite
      gapSize: 280.0,
      speedMultiplier: 1.2,
      description: 'Elite tier - speed will continue increasing',
    ),
  ];
  
  /// Get the current difficulty phase for a score
  static DifficultyPhase getPhaseForScore(int score) {
    // Handle master tier with progressive speed increases
    if (score >= 51) {
      final masterSpeed = _calculateMasterSpeed(score);
      return DifficultyPhase(
        name: 'Master ${_getMasterTier(score)}',
        minScore: 51,
        maxScore: -1,
        gapSize: 280.0,
        speedMultiplier: masterSpeed,
        description: 'Master tier - speed ${masterSpeed.toStringAsFixed(2)}x',
      );
    }
    
    // Find base phase
    for (final phase in _basePhases) {
      if (phase.appliesTo(score)) {
        return phase;
      }
    }
    
    // Fallback to super easy
    return _basePhases.first;
  }

  /// === CONTINUOUS CURVES (no step jumps) ===
  /// Gap ratio relative to screen height. Starts ~0.40H and lerps to ~0.30H by score 60, then clamps ≥0.28H.
  static double getGapRatioContinuous(int score) {
    final s = score.clamp(0, 60);
    final start = 0.40; // 40% of screen height
    final end = 0.30;   // 30% of screen height by score 60
    final ratio = start + (end - start) * (s / 60.0);
    return ratio.clamp(0.28, 0.50);
  }

  /// Base horizontal speed in px/s. Starts 200, +1.8 px per score until ~360 (clamp 400).
  static double getBaseSpeedContinuous(int score) {
    final base = 200.0 + 1.8 * score;
    return base.clamp(200.0, 400.0);
  }

  /// Phase cadence helper to compute a phase index for visuals (0-based).
  /// 0–40 → every 10 points, then every 20 points after.
  static int getPhaseIndexForVisuals(int score) {
    if (score <= 40) return (score / 10).floor();
    return 4 + ((score - 40) / 20).floor();
  }
  
  /// Calculate speed for master tier (51+)
  /// - Score 51-55: +0.05 speed (1.25x)
  /// - Score 56-60: +0.05 speed (1.30x) 
  /// - Continue until 2.0x, then slow down progression
  static double _calculateMasterSpeed(int score) {
    const baseSpeed = 1.2; // Master base speed
    
    if (score < 51) return baseSpeed;
    
    final masterScore = score - 51; // Score above master threshold
    
    // Phase 1: Add 0.05 every 5 scores until 2.0x speed
    if (baseSpeed + (masterScore ~/ 5) * 0.05 < 2.0) {
      return baseSpeed + (masterScore ~/ 5) * 0.05;
    }
    
    // Phase 2: After 2.0x, add 0.05 every 10 scores
    final scoresTo2x = ((2.0 - baseSpeed) / 0.05) * 5; // Scores needed to reach 2.0x
    final remainingScore = masterScore - scoresTo2x.round();
    
    if (remainingScore <= 0) {
      return 2.0;
    }
    
    return 2.0 + (remainingScore ~/ 10) * 0.05;
  }
  
  /// Get master tier name based on score
  static String _getMasterTier(int score) {
    if (score < 51) return '';
    if (score < 75) return 'I';
    if (score < 100) return 'II';
    if (score < 150) return 'III';
    if (score < 200) return 'IV';
    return 'V+';
  }
  
  /// Get obstacle gap size for score
  static double getObstacleGap(int score) {
    return getPhaseForScore(score).gapSize;
  }
  
  /// Get speed multiplier for score
  static double getSpeedMultiplier(int score) {
    return getPhaseForScore(score).speedMultiplier;
  }
  
  /// Get base obstacle speed (before multiplier)
  static double getBaseObstacleSpeed() {
    return 200.0; // Base pixels per second
  }
  
  /// Get final obstacle speed for score
  static double getObstacleSpeed(int score) {
    return getBaseObstacleSpeed() * getSpeedMultiplier(score);
  }
  
  /// Check if score represents a phase transition
  static bool isPhaseTransition(int score) {
    if (score == 0) return true; // Game start
    
    for (final phase in _basePhases) {
      if (score == phase.minScore) return true;
    }
    
    // Master tier transitions every 25 scores
    if (score >= 51 && (score - 51) % 25 == 0) return true;
    
    return false;
  }
  
  /// Get phase transition message
  static String? getPhaseTransitionMessage(int score) {
    if (!isPhaseTransition(score)) return null;
    
    final phase = getPhaseForScore(score);
    return '🎯 ${phase.name} Mode!\n${phase.description}';
  }
  
  /// Get all phases for debugging/settings
  static List<DifficultyPhase> getAllPhases() {
    return List.from(_basePhases);
  }
  
  /// 🎨 VISUAL FRAMEWORK - Extensible for future visual changes
  /// Each phase can have different visual properties
  
  /// Get background theme for phase
  static String getBackgroundTheme(int score) {
    final phase = getPhaseForScore(score);
    
    // Framework for future visual changes
    switch (phase.name.split(' ').first) {
      case 'Super':
      case 'Easy':
        return 'peaceful_sky';
      case 'Medium':
        return 'dynamic_clouds';
      case 'Hard':
        return 'storm_clouds';
      case 'Expert':
        return 'lightning_storm';
      case 'Master':
        return 'space_void';
      default:
        return 'peaceful_sky';
    }
  }
  
  /// Get ground theme for phase
  static String getGroundTheme(int score) {
    final phase = getPhaseForScore(score);
    
    // Framework for future visual changes
    switch (phase.name.split(' ').first) {
      case 'Super':
      case 'Easy':
        return 'grass_hills';
      case 'Medium':
        return 'rocky_terrain';
      case 'Hard':
        return 'metal_platforms';
      case 'Expert':
        return 'lava_rocks';
      case 'Master':
        return 'space_debris';
      default:
        return 'grass_hills';
    }
  }
  
  /// Get obstacle theme for phase
  static String getObstacleTheme(int score) {
    final phase = getPhaseForScore(score);
    
    // Framework for future visual changes
    switch (phase.name.split(' ').first) {
      case 'Super':
      case 'Easy':
        return 'wooden_pipes';
      case 'Medium':
        return 'stone_pillars';
      case 'Hard':
        return 'metal_towers';
      case 'Expert':
        return 'crystal_spikes';
      case 'Master':
        return 'energy_barriers';
      default:
        return 'wooden_pipes';
    }
  }
  
  /// Get audio theme for phase
  static String getAudioTheme(int score) {
    final phase = getPhaseForScore(score);
    
    // Framework for future audio changes
    switch (phase.name.split(' ').first) {
      case 'Super':
      case 'Easy':
        return 'peaceful';
      case 'Medium':
        return 'upbeat';
      case 'Hard':
        return 'intense';
      case 'Expert':
        return 'dramatic';
      case 'Master':
        return 'epic';
      default:
        return 'peaceful';
    }
  }
  
  /// Debug: Print current difficulty info
  static void debugPrintDifficulty(int score) {
    final phase = getPhaseForScore(score);
    safePrint('🎯 DIFFICULTY: Score $score → ${phase.toString()}');
    safePrint('🎨 VISUAL: Background=${getBackgroundTheme(score)}, Ground=${getGroundTheme(score)}, Obstacles=${getObstacleTheme(score)}');
    safePrint('🎵 AUDIO: Theme=${getAudioTheme(score)}');
  }
}
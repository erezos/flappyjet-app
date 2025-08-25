import 'package:flutter/foundation.dart';
import 'enhanced_difficulty_system.dart';

/// Manages dynamic asset loading based on game difficulty phases
class VisualAssetManager {
  
  /// Background asset path mappings for each phase
  /// Note: Flame's Sprite.load() automatically prepends 'assets/images/' 
  static const Map<int, String> _backgroundAssets = {
    1: 'backgrounds/phase1_dawn_complete.png',
    2: 'backgrounds/phase2_sunny_complete.png',
    3: 'backgrounds/phase3_afternoon_complete.png',
    4: 'backgrounds/phase4_storm_complete.png',
    5: 'backgrounds/phase5_lightning_complete.png',
    6: 'backgrounds/phase6_altitude_complete.png',
    7: 'backgrounds/phase7_stratosphere_complete.png',
    8: 'backgrounds/phase8_cosmic_complete.png',
  };
  
  /// Obstacle asset path mappings for each phase
  /// Note: Flame's Sprite.load() automatically prepends 'assets/images/'
  static const Map<int, String> _obstacleAssets = {
    1: 'obstacles/phase1_wooden_pipes.png',
    2: 'obstacles/phase2_reinforced_wood.png',
    3: 'obstacles/phase3_stone_pillars.png',
    4: 'obstacles/phase4_stone_towers.png',
    5: 'obstacles/phase5_metal_lightning.png',
    6: 'obstacles/phase6_tech_structures.png',
    7: 'obstacles/phase7_crystal_energy.png',
    8: 'obstacles/phase8_energy_barriers.png',
  };
  
  /// Get background asset path for current score (staggered mapping)
  static String getBackgroundAsset(int score) {
    final phaseNumber = _getBackgroundPhaseForScore(score);
    final assetPath = _backgroundAssets[phaseNumber] ?? _backgroundAssets[1]!;
    
    debugPrint('🎨 ASSET: Score $score → BG Phase $phaseNumber → $assetPath');
    return assetPath;
  }
  
  /// Get obstacle asset path for current score (staggered mapping)
  static String getObstacleAsset(int score) {
    final phaseNumber = _getObstaclePhaseForScore(score);
    final assetPath = _obstacleAssets[phaseNumber] ?? _obstacleAssets[1]!;
    
    debugPrint('🎨 OBSTACLE: Score $score → OBS Phase $phaseNumber → $assetPath');
    return assetPath;
  }
  
  /// Check if we should transition to new assets based on score change
  static bool shouldUpdateAssets(int oldScore, int newScore) {
    final oldBg = _getBackgroundPhaseForScore(oldScore);
    final newBg = _getBackgroundPhaseForScore(newScore);
    return oldBg != newBg;
  }
  
  /// Get all background asset paths (for preloading)
  static List<String> getAllBackgroundAssets() {
    return _backgroundAssets.values.toList();
  }
  
  /// Get all obstacle asset paths (for preloading)
  static List<String> getAllObstacleAssets() {
    return _obstacleAssets.values.toList();
  }
  
  /// Preload next phase assets for smooth transitions
  static List<String> getNextPhaseAssets(int currentScore) {
    final nextScore = currentScore + 1;
    final currBg = _getBackgroundPhaseForScore(currentScore);
    final nextBg = _getBackgroundPhaseForScore(nextScore);
    final currObs = _getObstaclePhaseForScore(currentScore);
    final nextObs = _getObstaclePhaseForScore(nextScore);
    final assets = <String>[];
    if (nextBg != currBg) assets.add(getBackgroundAsset(nextScore));
    if (nextObs != currObs) assets.add(getObstacleAsset(nextScore));
    return assets;
  }
  
  /// Extract phase number from phase name
  static int _getPhaseNumber(String phaseName) {
    // Handle Master tiers first (most specific)
    if (phaseName.startsWith('Master')) return 8;
    
    // Handle other phases with exact matching
    if (phaseName.startsWith('Super Easy')) return 1;
    if (phaseName.startsWith('Easy Advance')) return 3;  
    if (phaseName.startsWith('Easy')) return 2;
    if (phaseName.startsWith('Medium Advance')) return 5;
    if (phaseName.startsWith('Medium')) return 4;
    if (phaseName.startsWith('Hard')) return 6;
    if (phaseName.startsWith('Expert')) return 7;
    
    // Fallback to phase 1 for any unrecognized phases
    debugPrint('⚠️ Unknown phase name: $phaseName, falling back to phase 1');
    return 1;
  }

  /// Staggered background phase mapping by score
  static int _getBackgroundPhaseForScore(int s) {
    if (s <= 9) return 1;
    if (s <= 20) return 2;      // 10–12 bg2 (obs1), 13–20 bg2 (obs2)
    if (s <= 30) return 3;      // 21–23 bg3 (obs2), 24–30 bg3 (obs3)
    if (s <= 50) return 4;      // 31–35 bg4 (obs3), 36–50 bg4 (obs4)
    if (s <= 80) return 5;      // 51–60 bg5, 61–80 bg5
    if (s <= 130) return 6;     // 81–100 bg6, 101–130 bg6
    if (s <= 200) return 7;     // 131–160 bg7, 161–200 bg7
    return 8;                   // 201+ bg8
  }

  /// Public: background phase index for a given score (1..8)
  static int getBackgroundPhaseIndex(int score) => _getBackgroundPhaseForScore(score);

  /// Public: does this exact score advance background phase vs previous score?
  static bool isBackgroundChangeScore(int score) {
    if (score <= 0) return false;
    return _getBackgroundPhaseForScore(score) != _getBackgroundPhaseForScore(score - 1);
  }

  /// Staggered obstacle phase mapping by score
  static int _getObstaclePhaseForScore(int s) {
    if (s <= 6) return 1;       // 0–6 obs1
    if (s <= 23) return 2;      // 7–23 obs2 (moved earlier)
    if (s <= 35) return 3;      // 24–35 obs3
    if (s <= 60) return 4;      // 36–60 obs4
    if (s <= 100) return 5;     // 61–100 obs5
    if (s <= 160) return 6;     // 101–160 obs6
    if (s <= 260) return 7;     // 161–260 obs7
    return 8;                   // 261+ obs8
  }
  
  /// Get phase-appropriate color scheme for UI elements
  static Map<String, dynamic> getPhaseColors(int score) {
    final phaseNumber = _getPhaseNumber(
      EnhancedDifficultySystem.getPhaseForScore(score).name
    );
    
    switch (phaseNumber) {
      case 1: // Dawn
        return {
          'primary': 0xFF87CEEB,   // Sky blue
          'accent': 0xFFFFB6C1,   // Light pink
          'text': 0xFF2F4F4F,     // Dark slate gray
        };
      case 2: // Sunny
        return {
          'primary': 0xFF1E90FF,   // Dodger blue
          'accent': 0xFFFFD700,    // Gold
          'text': 0xFF000080,      // Navy
        };
      case 3: // Afternoon
        return {
          'primary': 0xFF4682B4,   // Steel blue
          'accent': 0xFFFFA500,    // Orange
          'text': 0xFF2F4F4F,      // Dark slate gray
        };
      case 4: // Storm
        return {
          'primary': 0xFF696969,   // Dim gray
          'accent': 0xFFB22222,    // Fire brick
          'text': 0xFFFFFFFF,      // White
        };
      case 5: // Lightning
        return {
          'primary': 0xFF2F2F2F,   // Dark gray
          'accent': 0xFF00BFFF,    // Deep sky blue (electric)
          'text': 0xFFFFFFFF,      // White
        };
      case 6: // Altitude
        return {
          'primary': 0xFF4169E1,   // Royal blue
          'accent': 0xFFC0C0C0,    // Silver
          'text': 0xFFFFFFFF,      // White
        };
      case 7: // Stratosphere
        return {
          'primary': 0xFF191970,   // Midnight blue
          'accent': 0xFFE6E6FA,    // Lavender
          'text': 0xFFFFFFFF,      // White
        };
      case 8: // Cosmic
        return {
          'primary': 0xFF0A0A0A,   // Almost black
          'accent': 0xFF9370DB,    // Medium purple
          'text': 0xFFFFFFFF,      // White
        };
      default:
        return {
          'primary': 0xFF87CEEB,
          'accent': 0xFFFFB6C1,
          'text': 0xFF2F4F4F,
        };
    }
  }
  
  /// Debug: Print all available assets
  static void debugPrintAssets() {
    debugPrint('🎨 === AVAILABLE BACKGROUND ASSETS ===');
    _backgroundAssets.forEach((phase, path) {
      debugPrint('🎨 Phase $phase: $path');
    });
    
    debugPrint('🎨 === AVAILABLE OBSTACLE ASSETS ===');
    _obstacleAssets.forEach((phase, path) {
      debugPrint('🎨 Phase $phase: $path');
    });
  }
}
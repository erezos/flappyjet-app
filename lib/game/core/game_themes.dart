import 'package:flutter/material.dart';

/// Game theme data structure - ENVIRONMENTAL ONLY (no jet appearance)
class GameTheme {
  final String id;
  final String displayName;
  final String description;
  final int scoreThreshold;
  final ThemeColors colors;
  final ThemeVisuals visuals;
  final String musicTrack;
  final double difficultyMultiplier;
  
  const GameTheme({
    required this.id,
    required this.displayName,
    required this.description,
    required this.scoreThreshold,
    required this.colors,
    required this.visuals,
    required this.musicTrack,
    required this.difficultyMultiplier,
  });
}

/// Theme color palette - ENVIRONMENTAL ONLY
class ThemeColors {
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color background;
  final Color backgroundSecondary;
  final Color obstacle;
  final Color obstacleAccent;
  final Color text;
  final Color particle;
  
  const ThemeColors({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.backgroundSecondary,
    required this.obstacle,
    required this.obstacleAccent,
    required this.text,
    required this.particle,
  });
}

/// Theme visual elements - ENVIRONMENTAL ONLY (removed jetTint)
class ThemeVisuals {
  final ParticleStyle particleStyle;
  final ObstacleStyle obstacleStyle;
  final String backgroundPattern;
  final double backgroundOpacity;
  final bool hasStars;
  final bool hasNebula;
  final bool hasLightning;
  final bool hasMeteors;
  final bool hasAurora;
  
  const ThemeVisuals({
    required this.particleStyle,
    required this.obstacleStyle,
    required this.backgroundPattern,
    required this.backgroundOpacity,
    required this.hasStars,
    required this.hasNebula,
    required this.hasLightning,
    required this.hasMeteors,
    required this.hasAurora,
  });
}

/// Particle effect style
enum ParticleStyle {
  sparkles,    // Sky theme
  stars,       // Space theme  
  lightning,   // Storm theme
  energy,      // Void theme
  cosmic,      // Legend theme
}

/// Obstacle visual style
enum ObstacleStyle {
  pipes,       // Sky theme - classic pipes
  crystals,    // Space theme - crystal formations
  storm,       // Storm theme - lightning rods
  voidEnergy,  // Void theme - dark energy
  legendary,   // Legend theme - golden pillars
}

/// Complete theme definitions for FlappyJet Pro
class GameThemes {
  
  /// Sky Rookie - Beginner theme (Score: 0+)
  static const skyRookie = GameTheme(
    id: 'sky_rookie',
    displayName: 'Sky Rookie',
    description: 'Clear blue skies for new pilots',
    scoreThreshold: 0,
    colors: ThemeColors(
      primary: Color(0xFF4A90E2),
      secondary: Color(0xFF357ABD),
      accent: Color(0xFF85C1FF),
      background: Color(0xFF87CEEB),
      backgroundSecondary: Color(0xFF98D8E8),
      obstacle: Color(0xFF32CD32),
      obstacleAccent: Color(0xFF228B22),
      text: Colors.white,
      particle: Color(0xFFFFD700),
    ),
    visuals: ThemeVisuals(
      particleStyle: ParticleStyle.sparkles,
      obstacleStyle: ObstacleStyle.pipes,
      backgroundPattern: 'gradient',
      backgroundOpacity: 1.0,
      hasStars: true,
      hasNebula: false,
      hasLightning: false,
      hasMeteors: false,
      hasAurora: false,
    ),
    musicTrack: 'sky_theme',
    difficultyMultiplier: 1.0,
  );
  
  /// Space Cadet - Cosmic theme (Score: 25+)
  static const spaceCadet = GameTheme(
    id: 'space_cadet',
    displayName: 'Space Cadet',
    description: 'Journey through the cosmos',
    scoreThreshold: 25,
    colors: ThemeColors(
      primary: Color(0xFF4B0082),
      secondary: Color(0xFF663399),
      accent: Color(0xFF9966CC),
      background: Color(0xFF191970),
      backgroundSecondary: Color(0xFF2E2E2E),
      obstacle: Color(0xFF8A2BE2),
      obstacleAccent: Color(0xFF6A1B9A),
      text: Colors.white,
      particle: Color(0xFFFFFFFF),
    ),
    visuals: ThemeVisuals(
      particleStyle: ParticleStyle.stars,
      obstacleStyle: ObstacleStyle.crystals,
      backgroundPattern: 'gradient',
      backgroundOpacity: 1.0,
      hasStars: true,
      hasNebula: true,
      hasLightning: false,
      hasMeteors: false,
      hasAurora: false,
    ),
    musicTrack: 'space_theme',
    difficultyMultiplier: 1.3,
  );
  
  /// Storm Ace - Turbulent theme (Score: 75+)
  static const stormAce = GameTheme(
    id: 'storm_ace',
    displayName: 'Storm Ace',
    description: 'Navigate the lightning storms',
    scoreThreshold: 75,
    colors: ThemeColors(
      primary: Color(0xFF2F4F4F),
      secondary: Color(0xFF708090),
      accent: Color(0xFFFFFF00),
      background: Color(0xFF2C3E50),
      backgroundSecondary: Color(0xFF34495E),
      obstacle: Color(0xFF4169E1),
      obstacleAccent: Color(0xFF1E90FF),
      text: Colors.white,
      particle: Color(0xFFFFFF00),
    ),
    visuals: ThemeVisuals(
      particleStyle: ParticleStyle.lightning,
      obstacleStyle: ObstacleStyle.storm,
      backgroundPattern: 'gradient',
      backgroundOpacity: 1.0,
      hasStars: false,
      hasNebula: false,
      hasLightning: true,
      hasMeteors: false,
      hasAurora: false,
    ),
    musicTrack: 'storm_theme',
    difficultyMultiplier: 1.6,
  );
  
  /// Void Master - Dark dimension theme (Score: 150+)
  static const voidMaster = GameTheme(
    id: 'void_master',
    displayName: 'Void Master',
    description: 'Master the dark dimensions',
    scoreThreshold: 150,
    colors: ThemeColors(
      primary: Color(0xFF1C1C1C),
      secondary: Color(0xFF4A4A4A),
      accent: Color(0xFF8B008B),
      background: Color(0xFF0D0D0D),
      backgroundSecondary: Color(0xFF1A1A1A),
      obstacle: Color(0xFF8B008B),
      obstacleAccent: Color(0xFF9932CC),
      text: Colors.white,
      particle: Color(0xFF8B008B),
    ),
    visuals: ThemeVisuals(
      particleStyle: ParticleStyle.energy,
      obstacleStyle: ObstacleStyle.voidEnergy,
      backgroundPattern: 'gradient',
      backgroundOpacity: 1.0,
      hasStars: false,
      hasNebula: false,
      hasLightning: false,
      hasMeteors: false,
      hasAurora: false,
    ),
    musicTrack: 'void_theme',
    difficultyMultiplier: 2.0,
  );
  
  /// Legend - Ultimate mastery theme (Score: 300+)
  static const legend = GameTheme(
    id: 'legend',
    displayName: 'Legend',
    description: 'Legendary pilot status achieved',
    scoreThreshold: 300,
    colors: ThemeColors(
      primary: Color(0xFFFFD700),
      secondary: Color(0xFFFFA500),
      accent: Color(0xFFFFFFFF),
      background: Color(0xFF8B4513),
      backgroundSecondary: Color(0xFFDAA520),
      obstacle: Color(0xFFFFD700),
      obstacleAccent: Color(0xFFFFA500),
      text: Colors.white,
      particle: Color(0xFFFFD700),
    ),
    visuals: ThemeVisuals(
      particleStyle: ParticleStyle.cosmic,
      obstacleStyle: ObstacleStyle.legendary,
      backgroundPattern: 'gradient',
      backgroundOpacity: 1.0,
      hasStars: true,
      hasNebula: true,
      hasLightning: false,
      hasMeteors: false,
      hasAurora: true,
    ),
    musicTrack: 'legend_theme',
    difficultyMultiplier: 2.5,
  );
  
  /// All themes in order
  static const List<GameTheme> allThemes = [
    skyRookie,
    spaceCadet, 
    stormAce,
    voidMaster,
    legend,
  ];
  
  /// Get theme by score
  static GameTheme getThemeForScore(int score) {
    for (int i = allThemes.length - 1; i >= 0; i--) {
      if (score >= allThemes[i].scoreThreshold) {
        return allThemes[i];
      }
    }
    return skyRookie; // Default fallback
  }
  
  /// Get next theme (for progression preview)
  static GameTheme? getNextTheme(GameTheme currentTheme) {
    final currentIndex = allThemes.indexOf(currentTheme);
    if (currentIndex >= 0 && currentIndex < allThemes.length - 1) {
      return allThemes[currentIndex + 1];
    }
    return null; // Already at max theme
  }
  
  /// Check if score unlocks new theme
  static bool isThemeUnlocked(int score, GameTheme theme) {
    return score >= theme.scoreThreshold;
  }
  
  /// Get progression percentage to next theme
  static double getProgressToNext(int score, GameTheme currentTheme) {
    final nextTheme = getNextTheme(currentTheme);
    if (nextTheme == null) return 1.0; // Max level
    
    final current = currentTheme.scoreThreshold;
    final next = nextTheme.scoreThreshold;
    final progress = (score - current) / (next - current);
    
    return progress.clamp(0.0, 1.0);
  }
} 
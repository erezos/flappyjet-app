import 'game_themes.dart';

/// Game states for proper flow control
enum GameState { waitingToStart, playing, gameOver, paused }

/// Core game configuration constants
/// All game balance and visual settings centralized here
class GameConfig {
  // === GAME STATE MANAGEMENT ===
  static const GameState initialState = GameState.waitingToStart;

  // === CORE GAME DIMENSIONS ===
  static const double gameWidth = 400.0;
  static const double gameHeight = 800.0;
  static const double targetFPS = 30.0; // REDUCED: Prevent VSync crashes on low-end devices

  // === JET PHYSICS === (ULTRA-CASUAL: Extremely beginner friendly)
  static const double jetSize = 84.0; // Slightly larger for better readability
  static const double jetRadius = jetSize / 2;
  static const double gravity = 1200.0; // Standard fall
  static const double jumpVelocity = -460.0; // Higher jump
  static const double maxFallSpeed =
      500.0; // ULTRA GENTLE: Much slower max fall speed
  static const double jetRotationSpeed =
      2.0; // ULTRA GENTLE: Very smooth visual rotation

  // === START SCREEN SETTINGS ===
  static const double startScreenJetXRatio =
      0.20; // 🎯 PERFECT FIX: 20% from left edge (ensures full jet visibility with center anchor)
  static const double startScreenJetYRatio =
      0.30; // 🎯 SIMPLE FIX: 30% from top (middle screen height)
  static const double startScreenBobAmount = 10.0; // Gentle floating
  static const double startScreenBobSpeed = 2.0; // Floating frequency

  /// 🔥 RESPONSIVE: Calculate jet X position based on screen width
  static double getStartScreenJetX(double screenWidth) =>
      screenWidth * startScreenJetXRatio;

  /// 🔥 SIMPLE FIX: Position jet at screen center (50%) - always visible and properly positioned
  static double getStartScreenJetY(double screenHeight) =>
      screenHeight * startScreenJetYRatio;

  // === OBSTACLE SETTINGS === (ULTRA-CASUAL: Maximum beginner friendliness)
  // Make pillars 5% smaller again (total ≈10% from original 150 → 135.375)
  static const double obstacleWidth = 150.0 * 0.9025; // ≈135.4
  static const double obstacleSpeed =
      45.0; // ULTRA SLOW: Beginner-friendly speed
  static const double obstacleGap = 320.0; // MASSIVE: Even more generous gap
  static const double obstacleSpawnInterval =
      4.0; // SLOWER: More time between obstacles

  // === SCORING SYSTEM ===
  static const int pointsPerObstacle = 1; // Points awarded per obstacle
  static const int bonusPointsPerTheme = 0; // Bonus points for theme unlock

  // === LIFE SYSTEM ===
  static const int maxLives = 3; // Maximum lives
  static const double invulnerabilityDuration =
      5.0; // PRODUCTION: Extended recovery time for better player experience
  static const double heartFlashDuration = 0.5; // Heart loss animation duration
  static const int lifeRegenIntervalSeconds = 10 * 60; // 10 minutes per heart

  // === DIFFICULTY PROGRESSION === (PRODUCTION TUNED: Extremely gentle for mass market appeal)
  static const double baseDifficultyMultiplier = 1.0;
  static const double difficultyIncreaseRate =
      0.002; // ULTRA GENTLE: Barely noticeable progression for first 50 points
  static const double maxDifficultyMultiplier =
      2.0; // REDUCED: More reasonable maximum difficulty
  static const double minObstacleGap =
      220.0; // MAJOR INCREASE: Even at max difficulty, stays very playable
  static const double gapReductionRate =
      0.08; // ULTRA SLOW: Gap barely shrinks, maintains confidence

  // === THEME SYSTEM ===
  static const List<GameTheme> themes = GameThemes.allThemes;
  static const double themeTransitionDuration =
      3.0; // Theme notification duration
  static const double themeUnlockBonusMultiplier =
      2.0; // Score multiplier on unlock

  // === AUDIO SYSTEM ===
  static const double masterVolume = 0.8;
  static const double musicVolume = 0.6;
  static const double sfxVolume = 0.8;
  static const bool enableHapticFeedback = true;

  // === VISUAL EFFECTS ===
  static const int maxParticles = 100; // Maximum particles on screen
  static const double particleLifetime = 2.0; // Default particle lifetime
  static const double explosionParticleCount = 15; // Particles per explosion
  static const double scoreParticleCount = 8; // Particles per score
  static const double thrustParticleCount = 3; // Particles per thrust

  // === PERFORMANCE SETTINGS ===
  static const bool enablePerformanceMonitoring = true;
  static const double performanceWarningThreshold = 45.0; // FPS threshold
  static const int maxMemoryUsageMB = 150; // Memory usage warning
  static const bool enableDebugOverlay = false; // Debug info overlay
  static const bool debugCollisionRects =
      false; // Disable collision debug drawing for production

  // === MONETIZATION ===
  static const bool enableRewardedAds = true;
  static const int adCooldownSeconds = 300; // 5 minutes between ads
  static const int livesPerRewardedAd = 1; // Lives gained from watching ad
  static const double continueOfferDuration =
      10.0; // Seconds to show continue offer

  // === PROGRESSION MILESTONES === (PRODUCTION TUNED: More frequent early rewards)
  // Designed for maximum casual player retention and dopamine hits
  static const Map<int, String> achievementScores = {
    1: 'First Flight', // IMMEDIATE: First point celebration
    3: 'Getting Started', // EARLY: Quick second win
    5: 'Taking Flight', // EARLY: Third celebration
    8: 'Gaining Confidence', // FREQUENT: Keep momentum going
    10: 'Bronze Pilot', // Classic milestone
    15: 'Steady Flyer', // MID-GAME: Maintain engagement
    20: 'Silver Aviator', // Classic milestone
    25: 'Space Explorer', // Theme unlock celebration
    30: 'Golden Wings', // Classic milestone
    40: 'Platinum Ace', // Classic milestone
    50: 'Storm Survivor', // Theme unlock celebration
    75: 'Advanced Pilot', // Skill recognition
    100: 'Void Walker', // Theme unlock celebration
    150: 'Legend Master', // Elite tier
    200: 'Elite Commander', // Very dedicated
    300: 'Impossible Score', // Extremely rare
    500: 'FlappyJet Master', // Ultimate achievement
  };

  /// Get current difficulty multiplier based on score and theme
  static double getDifficultyMultiplier(int score) {
    final theme = GameThemes.getThemeForScore(score);
    final scoreMultiplier = 1.0 + (score * difficultyIncreaseRate);
    final themeMultiplier = theme.difficultyMultiplier;

    return (scoreMultiplier * themeMultiplier).clamp(
      baseDifficultyMultiplier,
      maxDifficultyMultiplier,
    );
  }

  /// Get obstacle gap size based on difficulty
  static double getObstacleGap(int score) {
    final reduction = score * gapReductionRate;
    return (obstacleGap - reduction).clamp(minObstacleGap, obstacleGap);
  }

  /// Get obstacle spawn interval based on difficulty
  static double getSpawnInterval(int score) {
    final theme = GameThemes.getThemeForScore(score);
    final baseInterval = obstacleSpawnInterval / theme.difficultyMultiplier;
    final scoreReduction = score * 0.01;

    return (baseInterval - scoreReduction).clamp(0.8, obstacleSpawnInterval);
  }

  /// Check if score qualifies for achievement
  static String? getAchievementForScore(int score) {
    return achievementScores[score];
  }

  /// Get theme unlock notification text
  static String getThemeUnlockText(GameTheme theme) {
    return '🎉 THEME UNLOCKED: ${theme.displayName.toUpperCase()}!';
  }

  /// Get continue offer text
  static String getContinueOfferText(int livesRemaining) {
    if (livesRemaining > 0) {
      return 'Continue with $livesRemaining ❤️ remaining?';
    } else {
      return 'Watch ad for +1 ❤️ and continue?';
    }
  }
}

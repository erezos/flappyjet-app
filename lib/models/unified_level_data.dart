/// 🎮 UNIFIED LEVEL DATA MODEL
/// 
/// Single runtime data model for all game modes (Story, Tournament, etc.)
/// This model is the single source of truth that FlappyGame consumes.
/// 
/// ✅ FLAME ENGINE BEST PRACTICES:
/// - Data-driven configuration
/// - Mode-agnostic game logic
/// - Easy to test and extend
/// 
/// USAGE:
/// ```dart
/// // From story mode
/// final level = UnifiedLevelData.fromStoryLevel(levelData);
/// 
/// // From tournament level
/// final level = UnifiedLevelData.fromTournamentLevel(tournamentLevel, tournament);
/// ```
library;

import 'level_data_schema.dart';
import 'tournament_config.dart';
import 'bonus_config.dart';

/// Game mode types
enum GameMode {
  /// Story mode with zones and progression
  story,
  /// Linear tournament (world map style)
  tournamentLinear,
  /// Playoff tournament (1v1 bracket style)
  tournamentPlayoff,
}

/// Obstacle spawner type
enum ObstacleSpawnerType {
  /// Classic pillar pairs with gap
  pillarPair,
  /// Single vertically moving obstacles (stunt mode)
  singleVertical,
}

/// Unified level data that all game modes use
/// 
/// This is the single model that FlappyGame consumes, regardless of
/// whether it's a story level, tournament level, or any future mode.
class UnifiedLevelData {
  // ─────────────────────────────────────────────────────────────────
  // Core Identifiers
  // ─────────────────────────────────────────────────────────────────
  
  /// Unique level ID
  final String id;
  
  /// Display name
  final String name;
  
  /// Game mode this level belongs to
  final GameMode gameMode;
  
  /// Zone number (for story mode) or round number (for tournaments)
  final int stageNumber;
  
  // ─────────────────────────────────────────────────────────────────
  // Objective Configuration
  // ─────────────────────────────────────────────────────────────────
  
  /// Level objective
  final LevelObjective objective;
  
  // ─────────────────────────────────────────────────────────────────
  // Visual Theme
  // ─────────────────────────────────────────────────────────────────
  
  /// Theme configuration (background, obstacles, music)
  final LevelTheme theme;
  
  // ─────────────────────────────────────────────────────────────────
  // Difficulty & Gameplay
  // ─────────────────────────────────────────────────────────────────
  
  /// Difficulty configuration
  final DifficultyConfig difficulty;
  
  /// Obstacle spawner type
  final ObstacleSpawnerType obstacleSpawnerType;
  
  /// Obstacle patterns (for weighted random selection)
  final List<ObstaclePattern> obstaclePatterns;
  
  /// Stunt obstacle config (when spawnerType is singleVertical)
  final StuntObstacleConfiguration? stuntConfig;
  
  // ─────────────────────────────────────────────────────────────────
  // Bot Battle (Optional)
  // ─────────────────────────────────────────────────────────────────
  
  /// Bot battle configuration (for beatBot objectives)
  final UnifiedBotConfig? botBattle;
  
  // ─────────────────────────────────────────────────────────────────
  // Rewards
  // ─────────────────────────────────────────────────────────────────
  
  /// Rewards for completing this level
  final LevelReward reward;
  
  // ─────────────────────────────────────────────────────────────────
  // Bonuses (In-game collectibles)
  // ─────────────────────────────────────────────────────────────────
  
  /// Bonus configuration (coins, power-ups, etc.)
  final BonusConfig bonuses;
  
  // ─────────────────────────────────────────────────────────────────
  // Tournament-specific (Optional)
  // ─────────────────────────────────────────────────────────────────
  
  /// Tournament ID (if this is a tournament level)
  final String? tournamentId;
  
  /// Original story level ID (for story mode reference)
  final int? originalLevelId;

  const UnifiedLevelData({
    required this.id,
    required this.name,
    required this.gameMode,
    required this.stageNumber,
    required this.objective,
    required this.theme,
    required this.difficulty,
    this.obstacleSpawnerType = ObstacleSpawnerType.pillarPair,
    this.obstaclePatterns = const [],
    this.stuntConfig,
    this.botBattle,
    required this.reward,
    this.bonuses = BonusConfig.disabled,
    this.tournamentId,
    this.originalLevelId,
  });
  
  // ─────────────────────────────────────────────────────────────────
  // Factory: From Story Mode Level
  // ─────────────────────────────────────────────────────────────────
  
  /// Create from a story mode LevelData
  factory UnifiedLevelData.fromStoryLevel(LevelData level) {
    return UnifiedLevelData(
      id: 'story_${level.id}',
      name: level.name,
      gameMode: GameMode.story,
      stageNumber: level.zone,
      objective: level.objective,
      theme: level.theme,
      difficulty: level.difficulty,
      obstacleSpawnerType: ObstacleSpawnerType.pillarPair,
      obstaclePatterns: const [], // Story mode uses default patterns
      botBattle: level.botBattle != null
          ? UnifiedBotConfig.fromStoryBotBattle(level.botBattle!)
          : null,
      reward: level.reward,
      bonuses: level.bonuses,
      originalLevelId: level.id,
    );
  }
  
  // ─────────────────────────────────────────────────────────────────
  // Factory: From Linear Tournament Level
  // ─────────────────────────────────────────────────────────────────
  
  /// Create from a tournament level (linear progression)
  factory UnifiedLevelData.fromTournamentLevel(
    TournamentLevel level,
    TournamentConfig tournament,
  ) {
    // Determine obstacle type based on stunt config presence
    final isStuntMode = level.isStuntMode;
    
    // Build objective based on tournament type
    final objective = _buildTournamentObjective(level, tournament);
    
    // Build theme
    final theme = LevelTheme(
      background: level.background,
      obstacles: isStuntMode 
          ? (level.stuntConfig?['asset_path'] as String? ?? 'obstacles/desert_obstacles.png')
          : 'obstacles/phase1_wooden_pipes.png',
      music: _inferMusicFromBackground(level.background),
    );
    
    // Build difficulty
    final difficulty = DifficultyConfig(
      speedMultiplier: level.difficulty.speedMultiplier,
      obstacleGap: level.difficulty.obstacleGap.toDouble(),
      obstacleFrequency: level.difficulty.obstacleFrequency,
      maxGapShift: level.difficulty.maxGapShift.toDouble(),
    );
    
    return UnifiedLevelData(
      id: 'tournament_${tournament.id}_${level.round}',
      name: level.name,
      gameMode: GameMode.tournamentLinear,
      stageNumber: level.round,
      objective: objective,
      theme: theme,
      difficulty: difficulty,
      obstacleSpawnerType: isStuntMode 
          ? ObstacleSpawnerType.singleVertical 
          : ObstacleSpawnerType.pillarPair,
      obstaclePatterns: level.obstaclePatterns,
      stuntConfig: isStuntMode 
          ? StuntObstacleConfiguration.fromJson(level.stuntConfig!)
          : null,
      reward: LevelReward(
        coins: level.reward.coins,
        gems: level.reward.gems,
      ),
      tournamentId: tournament.id,
    );
  }
  
  // ─────────────────────────────────────────────────────────────────
  // Factory: From Playoff Tournament Round
  // ─────────────────────────────────────────────────────────────────
  
  /// Create from a playoff tournament round
  factory UnifiedLevelData.fromPlayoffRound(
    PlayoffRound round,
    TournamentConfig tournament,
  ) {
    final bossBattle = round.bossBattle;
    
    // Use boss battle config if available, otherwise defaults
    final background = bossBattle?.background ?? 'phase1_dawn_complete.png';
    final obstacles = bossBattle?.obstacleTheme ?? 'phase1_wooden_pipes.png';
    final music = bossBattle?.music ?? 'battle';
    
    final theme = LevelTheme(
      background: background,
      obstacles: 'obstacles/$obstacles',
      music: music.contains('.mp3') ? music : '$music.mp3',
    );
    
    final difficulty = bossBattle != null
        ? DifficultyConfig(
            speedMultiplier: bossBattle.speedMultiplier,
            obstacleGap: bossBattle.obstacleGap.toDouble(),
            obstacleFrequency: bossBattle.obstacleFrequency,
            maxGapShift: bossBattle.maxGapShift.toDouble(),
          )
        : const DifficultyConfig(
            speedMultiplier: 1.0,
            obstacleGap: 350,
            obstacleFrequency: 2.5,
            maxGapShift: 50,
          );
    
    // Bot configuration from playoff round
    final botConfig = bossBattle != null
        ? UnifiedBotConfig(
            botName: round.displayName,
            botJetSkin: round.opponentJet,
            skillLevel: bossBattle.skillLevel,
            reactionTime: bossBattle.reactionTime,
            mistakeRate: bossBattle.mistakeRate,
            minObstaclePass: 0,
          )
        : UnifiedBotConfig(
            botName: round.displayName,
            botJetSkin: round.opponentJet,
            skillLevel: 0.6,
            reactionTime: 0.25,
            mistakeRate: 0.15,
            minObstaclePass: 0,
          );
    
    // Get round reward from tournament levels
    final roundIndex = round.roundNumber - 1;
    final levelReward = roundIndex < tournament.levels.length
        ? tournament.levels[roundIndex].reward
        : const TournamentReward(coins: 100, gems: 1);
    
    return UnifiedLevelData(
      id: 'playoff_${tournament.id}_${round.roundNumber}',
      name: round.stageName,
      gameMode: GameMode.tournamentPlayoff,
      stageNumber: round.roundNumber,
      objective: LevelObjective(
        type: ObjectiveType.beatBot,
        target: bossBattle?.requiredDistance ?? 50,
        description: 'Beat ${round.displayName}!',
      ),
      theme: theme,
      difficulty: difficulty,
      obstacleSpawnerType: ObstacleSpawnerType.pillarPair,
      obstaclePatterns: bossBattle?.obstaclePatterns ?? [],
      botBattle: botConfig,
      reward: LevelReward(
        coins: levelReward.coins,
        gems: levelReward.gems,
        specialReward: levelReward.skinId,
      ),
      tournamentId: tournament.id,
    );
  }
  
  // ─────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────
  
  /// Build objective from tournament level
  static LevelObjective _buildTournamentObjective(
    TournamentLevel level,
    TournamentConfig tournament,
  ) {
    // Check if stunt mode (time-based)
    if (level.isStuntMode) {
      final target = level.difficulty.requiredDistance;
      return LevelObjective(
        type: ObjectiveType.surviveTime,
        target: target,
        description: 'Survive for $target seconds',
      );
    }
    
    // Check if bot battle
    if (level.opponentJet != null) {
      return LevelObjective(
        type: ObjectiveType.beatBot,
        target: level.difficulty.requiredDistance,
        description: 'Beat the opponent!',
      );
    }
    
    // Default to pass obstacles
    return LevelObjective(
      type: ObjectiveType.passObstacles,
      target: level.difficulty.requiredDistance,
      description: 'Pass ${level.difficulty.requiredDistance} obstacles',
    );
  }
  
  /// Infer music track from background asset
  static String _inferMusicFromBackground(String background) {
    if (background.contains('frozen') || background.contains('ice')) {
      return 'frozen_theme.mp3';
    } else if (background.contains('lava') || background.contains('volcano')) {
      return 'lava_theme.mp3';
    } else if (background.contains('storm') || background.contains('phase4')) {
      return 'storm_theme.mp3';
    } else if (background.contains('sunny') || background.contains('phase2')) {
      return 'desert_theme.mp3';
    } else if (background.contains('afternoon') || background.contains('phase3')) {
      return 'afternoon_theme.mp3';
    }
    return 'game_music.mp3';
  }
  
  // ─────────────────────────────────────────────────────────────────
  // Getters
  // ─────────────────────────────────────────────────────────────────
  
  /// Whether this is a story mode level
  bool get isStoryMode => gameMode == GameMode.story;
  
  /// Whether this is a tournament level
  bool get isTournament => gameMode != GameMode.story;
  
  /// Whether this is a playoff tournament
  bool get isPlayoff => gameMode == GameMode.tournamentPlayoff;
  
  /// Whether this level has a bot battle
  bool get hasBotBattle => botBattle != null;
  
  /// Whether this level uses stunt obstacles
  bool get isStuntMode => obstacleSpawnerType == ObstacleSpawnerType.singleVertical;
  
  /// Get time target (for surviveTime objectives)
  int? get timeTarget => objective.type == ObjectiveType.surviveTime 
      ? objective.target 
      : null;
  
  /// Get obstacle target (for passObstacles objectives)
  int? get obstacleTarget => objective.type == ObjectiveType.passObstacles 
      ? objective.target 
      : null;
  
  // ─────────────────────────────────────────────────────────────────
  // Conversion
  // ─────────────────────────────────────────────────────────────────
  
  /// Convert back to LevelData (for backwards compatibility)
  LevelData toLevelData() {
    return LevelData(
      id: originalLevelId ?? int.tryParse(id.split('_').last) ?? 0,
      zone: stageNumber,
      name: name,
      objective: objective,
      difficulty: difficulty,
      reward: reward,
      theme: theme,
      botBattle: botBattle?.toBotBattle(),
      bonuses: bonuses,
    );
  }
  
  @override
  String toString() => 'UnifiedLevelData($id: $name, mode: $gameMode)';
}

/// Unified bot configuration
/// Works for both story mode bosses and tournament opponents
class UnifiedBotConfig {
  final String botName;
  final String botJetSkin;
  final double skillLevel;
  final double reactionTime;
  final double mistakeRate;
  final int minObstaclePass;
  
  const UnifiedBotConfig({
    required this.botName,
    required this.botJetSkin,
    required this.skillLevel,
    required this.reactionTime,
    required this.mistakeRate,
    this.minObstaclePass = 0,
  });
  
  /// Create from story mode BotBattle
  factory UnifiedBotConfig.fromStoryBotBattle(BotBattle bot) {
    return UnifiedBotConfig(
      botName: bot.botName,
      botJetSkin: bot.botJetSkin,
      skillLevel: bot.skillLevel,
      reactionTime: bot.reactionTime,
      mistakeRate: bot.mistakeRate,
      minObstaclePass: bot.minObstaclePass,
    );
  }
  
  /// Convert back to BotBattle (for backwards compatibility)
  BotBattle toBotBattle() {
    return BotBattle(
      botName: botName,
      botJetSkin: botJetSkin,
      skillLevel: skillLevel,
      reactionTime: reactionTime,
      mistakeRate: mistakeRate,
      minObstaclePass: minObstaclePass,
    );
  }
}

/// Stunt obstacle configuration
/// Used for single vertically moving obstacles
class StuntObstacleConfiguration {
  /// Mode identifier (e.g., "time_survival")
  final String mode;
  
  /// Asset path for the obstacle sprite
  final String assetPath;
  
  /// Obstacle size as percentage of screen width (0.0-1.0)
  final double obstacleSizePercent;
  
  /// Seconds between obstacle spawns
  final double spawnInterval;
  
  /// Horizontal scroll speed (pixels per second)
  final double scrollSpeed;
  
  /// Vertical movement amplitude as percentage of screen height (0.0-1.0)
  final double verticalAmplitudePercent;
  
  /// Vertical oscillation frequency (oscillations per second)
  final double verticalFrequency;
  
  const StuntObstacleConfiguration({
    required this.mode,
    required this.assetPath,
    required this.obstacleSizePercent,
    required this.spawnInterval,
    required this.scrollSpeed,
    required this.verticalAmplitudePercent,
    required this.verticalFrequency,
  });
  
  factory StuntObstacleConfiguration.fromJson(Map<String, dynamic> json) {
    return StuntObstacleConfiguration(
      mode: json['mode'] as String? ?? 'time_survival',
      assetPath: json['asset_path'] as String? ?? 'obstacles/desert_obstacles.png',
      obstacleSizePercent: (json['obstacle_size_percent'] as num?)?.toDouble() ?? 0.15,
      spawnInterval: (json['spawn_interval'] as num?)?.toDouble() ?? 2.5,
      scrollSpeed: (json['scroll_speed'] as num?)?.toDouble() ?? 150.0,
      verticalAmplitudePercent: (json['vertical_amplitude_percent'] as num?)?.toDouble() ?? 0.3,
      verticalFrequency: (json['vertical_frequency'] as num?)?.toDouble() ?? 0.4,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'mode': mode,
    'asset_path': assetPath,
    'obstacle_size_percent': obstacleSizePercent,
    'spawn_interval': spawnInterval,
    'scroll_speed': scrollSpeed,
    'vertical_amplitude_percent': verticalAmplitudePercent,
    'vertical_frequency': verticalFrequency,
  };
}


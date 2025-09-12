/// 🏆 ACHIEVEMENT HANDLER - Manages achievement checking and unlocking
/// Extracted from EnhancedFlappyGame to separate achievement concerns
library;
import '../../core/debug_logger.dart';

// dart:async import removed - not needed
import 'package:flutter/foundation.dart';
import '../../game/managers/game_state_manager.dart';
// CollisionManager import removed - no longer used
import '../systems/flappy_jet_audio_manager.dart';

/// Achievement types
enum AchievementType {
  scoreBased,
  survivalBased,
  actionBased,
  milestoneBased,
}

/// Achievement rarity
enum AchievementRarity {
  common,
  rare,
  epic,
  legendary,
}

/// Achievement definition
class Achievement {
  final String id;
  final String name;
  final String description;
  final AchievementType type;
  final AchievementRarity rarity;
  final Map<String, dynamic> criteria;
  final String iconAsset;
  final int rewardCoins;
  final int rewardGems;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.rarity,
    required this.criteria,
    required this.iconAsset,
    this.rewardCoins = 0,
    this.rewardGems = 0,
  });

  bool get isRare => rarity == AchievementRarity.rare;
  bool get isEpic => rarity == AchievementRarity.epic;
  bool get isLegendary => rarity == AchievementRarity.legendary;
}

/// Achievement progress
class AchievementProgress {
  final Achievement achievement;
  final Map<String, dynamic> progress;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  AchievementProgress({
    required this.achievement,
    required this.progress,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  double get completionPercentage {
    final target = achievement.criteria['target'] as num?;
    final current = progress['current'] as num?;

    if (target == null || current == null || target == 0) return 0.0;

    return (current / target).clamp(0.0, 1.0);
  }

  bool get isCompleted => completionPercentage >= 1.0 && !isUnlocked;
}

/// 🏆 Achievement Handler - Centralized achievement management
class AchievementHandler extends ChangeNotifier {
  final GameStateManager _gameState;
  final FlappyJetAudioManager _audioManager; // Modern FlappyJet audio

  // Achievement definitions
  late final List<Achievement> _achievements;

  // Progress tracking
  final Map<String, AchievementProgress> _achievementProgress = {};

  // Event callbacks
  void Function(Achievement achievement)? _onAchievementUnlocked;

  AchievementHandler({
    required GameStateManager gameState,
    required FlappyJetAudioManager audioManager,
  }) : _gameState = gameState,
       _audioManager = audioManager {
    _initializeAchievements();
    _setupEventListeners();
  }

  /// Set achievement unlocked callback
  void setOnAchievementUnlocked(void Function(Achievement achievement)? callback) {
    _onAchievementUnlocked = callback;
  }

  /// Get all achievements
  List<Achievement> get achievements => _achievements;

  /// Get achievement progress
  Map<String, AchievementProgress> get achievementProgress => _achievementProgress;

  /// Get unlocked achievements
  List<Achievement> get unlockedAchievements => _achievementProgress.values
      .where((progress) => progress.isUnlocked)
      .map((progress) => progress.achievement)
      .toList();

  /// Get recent unlocked achievements (last 5)
  List<Achievement> get recentAchievements {
    final unlockedProgress = _achievementProgress.values
        .where((progress) => progress.isUnlocked)
        .toList()
        ..sort((a, b) => (b.unlockedAt ?? DateTime.now())
            .compareTo(a.unlockedAt ?? DateTime.now()));
    
    return unlockedProgress
        .take(5)
        .map((progress) => progress.achievement)
        .toList();
  }

  /// Check if achievement is unlocked
  bool isAchievementUnlocked(String achievementId) {
    return _achievementProgress[achievementId]?.isUnlocked ?? false;
  }

  /// Get achievement progress percentage
  double getAchievementProgress(String achievementId) {
    return _achievementProgress[achievementId]?.completionPercentage ?? 0.0;
  }

  /// Initialize achievement definitions
  void _initializeAchievements() {
    _achievements = [
      // Score-based achievements
      const Achievement(
        id: 'first_score',
        name: 'First Flight',
        description: 'Score your first point',
        type: AchievementType.scoreBased,
        rarity: AchievementRarity.common,
        criteria: {'target': 1},
        iconAsset: 'achievements/first_score.png',
        rewardCoins: 10,
      ),
      const Achievement(
        id: 'score_25',
        name: 'Getting Started',
        description: 'Reach a score of 25',
        type: AchievementType.scoreBased,
        rarity: AchievementRarity.common,
        criteria: {'target': 25},
        iconAsset: 'achievements/score_25.png',
        rewardCoins: 25,
      ),
      const Achievement(
        id: 'score_100',
        name: 'Century Club',
        description: 'Reach a score of 100',
        type: AchievementType.scoreBased,
        rarity: AchievementRarity.rare,
        criteria: {'target': 100},
        iconAsset: 'achievements/score_100.png',
        rewardCoins: 50,
      ),
      const Achievement(
        id: 'score_500',
        name: 'High Flyer',
        description: 'Reach a score of 500',
        type: AchievementType.scoreBased,
        rarity: AchievementRarity.epic,
        criteria: {'target': 500},
        iconAsset: 'achievements/score_500.png',
        rewardCoins: 100,
        rewardGems: 1,
      ),

      // Survival-based achievements
      const Achievement(
        id: 'survive_10_seconds',
        name: 'Survivor',
        description: 'Survive for 10 seconds',
        type: AchievementType.survivalBased,
        rarity: AchievementRarity.common,
        criteria: {'target': 10},
        iconAsset: 'achievements/survive_10.png',
        rewardCoins: 15,
      ),
      const Achievement(
        id: 'survive_60_seconds',
        name: 'Minute Master',
        description: 'Survive for 60 seconds',
        type: AchievementType.survivalBased,
        rarity: AchievementRarity.rare,
        criteria: {'target': 60},
        iconAsset: 'achievements/survive_60.png',
        rewardCoins: 75,
      ),

      // Action-based achievements
      const Achievement(
        id: 'rapid_tapper',
        name: 'Rapid Tapper',
        description: 'Tap 10 times in under 5 seconds',
        type: AchievementType.actionBased,
        rarity: AchievementRarity.rare,
        criteria: {'target': 10, 'timeWindow': 5},
        iconAsset: 'achievements/rapid_tap.png',
        rewardCoins: 30,
      ),
      const Achievement(
        id: 'perfect_landing',
        name: 'Perfect Landing',
        description: 'Land perfectly between pillars',
        type: AchievementType.actionBased,
        rarity: AchievementRarity.epic,
        criteria: {'target': 1},
        iconAsset: 'achievements/perfect_landing.png',
        rewardCoins: 50,
      ),

      // Milestone achievements
      const Achievement(
        id: 'first_game',
        name: 'Welcome Pilot',
        description: 'Complete your first game',
        type: AchievementType.milestoneBased,
        rarity: AchievementRarity.common,
        criteria: {'target': 1},
        iconAsset: 'achievements/first_game.png',
        rewardCoins: 20,
      ),
      const Achievement(
        id: 'games_10',
        name: 'Experienced Pilot',
        description: 'Complete 10 games',
        type: AchievementType.milestoneBased,
        rarity: AchievementRarity.common,
        criteria: {'target': 10},
        iconAsset: 'achievements/games_10.png',
        rewardCoins: 50,
      ),
      const Achievement(
        id: 'games_100',
        name: 'Veteran Pilot',
        description: 'Complete 100 games',
        type: AchievementType.milestoneBased,
        rarity: AchievementRarity.epic,
        criteria: {'target': 100},
        iconAsset: 'achievements/games_100.png',
        rewardCoins: 200,
        rewardGems: 2,
      ),
    ];

    // Initialize progress for all achievements
    for (final achievement in _achievements) {
      _achievementProgress[achievement.id] = AchievementProgress(
        achievement: achievement,
        progress: {'current': 0},
      );
    }

    safePrint('🏆 Initialized ${_achievements.length} achievements');
  }

  /// Setup event listeners
  void _setupEventListeners() {
    _gameState.addListener(() {
      final state = _gameState.currentState;
      final stats = _gameState.stats;

      // Check achievements based on game state
      switch (state) {
        case GameState.gameOver:
          _checkGameOverAchievements(stats);
          break;
        case GameState.playing:
          _checkPlayingAchievements(stats);
          break;
        default:
          break;
      }
    });
  }

  /// Check achievements when game ends
  void _checkGameOverAchievements(GameStats stats) {
    // Score-based achievements
    _updateScoreAchievement(stats.score);

    // Survival-based achievements
    _updateSurvivalAchievement(stats.gameDurationSeconds);

    // Game completion achievements
    _updateGameCompletionAchievement();

    // Process completed achievements
    _processCompletedAchievements();
  }

  /// Check achievements during gameplay
  void _checkPlayingAchievements(GameStats stats) {
    // Real-time score updates
    _updateScoreAchievement(stats.score);

    // Real-time survival updates
    _updateSurvivalAchievement(stats.gameDurationSeconds);
  }

  /// Update score-based achievements
  void _updateScoreAchievement(int currentScore) {
    final scoreAchievements = _achievements.where(
      (a) => a.type == AchievementType.scoreBased
    );

    for (final achievement in scoreAchievements) {
      final progress = _achievementProgress[achievement.id]!;
      final target = achievement.criteria['target'] as int;

      if (progress.progress['current'] < currentScore) {
        progress.progress['current'] = currentScore;

        if (currentScore >= target && !progress.isUnlocked) {
          _unlockAchievement(achievement.id);
        }

        notifyListeners();
      }
    }
  }

  /// Update survival-based achievements
  void _updateSurvivalAchievement(int secondsSurvived) {
    final survivalAchievements = _achievements.where(
      (a) => a.type == AchievementType.survivalBased
    );

    for (final achievement in survivalAchievements) {
      final progress = _achievementProgress[achievement.id]!;
      final target = achievement.criteria['target'] as int;

      if (progress.progress['current'] < secondsSurvived) {
        progress.progress['current'] = secondsSurvived;

        if (secondsSurvived >= target && !progress.isUnlocked) {
          _unlockAchievement(achievement.id);
        }

        notifyListeners();
      }
    }
  }

  /// Update game completion achievement
  void _updateGameCompletionAchievement() {
    final gameAchievements = _achievements.where(
      (a) => a.type == AchievementType.milestoneBased &&
             a.id.startsWith('games_')
    );

    for (final achievement in gameAchievements) {
      final progress = _achievementProgress[achievement.id]!;
      final current = progress.progress['current'] as int;
      final target = achievement.criteria['target'] as int;

      if (current < target) {
        progress.progress['current'] = current + 1;

        if (current + 1 >= target && !progress.isUnlocked) {
          _unlockAchievement(achievement.id);
        }

        notifyListeners();
      }
    }
  }

  /// Handle rapid tapping detection
  void onRapidTapDetected(int tapCount, Duration timeWindow) {
    final achievement = _achievements.firstWhere(
      (a) => a.id == 'rapid_tapper',
      orElse: () => _achievements.first,
    );

    if (achievement.id == 'rapid_tapper') {
      final target = achievement.criteria['target'] as int;
      final windowSeconds = achievement.criteria['timeWindow'] as int;

      if (timeWindow.inSeconds <= windowSeconds && tapCount >= target) {
        _unlockAchievement(achievement.id);
      }
    }
  }

  /// Handle perfect landing detection
  void onPerfectLandingDetected() {
    _unlockAchievement('perfect_landing');
  }

  /// Unlock achievement
  void _unlockAchievement(String achievementId) {
    final progress = _achievementProgress[achievementId];
    if (progress == null || progress.isUnlocked) return;

    // Mark as unlocked
    _achievementProgress[achievementId] = AchievementProgress(
      achievement: progress.achievement,
      progress: progress.progress,
      isUnlocked: true,
      unlockedAt: DateTime.now(),
    );

    final achievement = progress.achievement;

    // Play achievement sound
    _audioManager.playAchievement(); // Optimized FlappyJet achievement sound

    // Grant rewards
    _grantAchievementRewards(achievement);

    // Notify listeners
    _onAchievementUnlocked?.call(achievement);
    notifyListeners();

    safePrint('🏆 Achievement unlocked: ${achievement.name} (${achievement.rarity})');
  }

  /// Grant achievement rewards
  void _grantAchievementRewards(Achievement achievement) {
    if (achievement.rewardCoins > 0) {
      safePrint('💰 Granted ${achievement.rewardCoins} coins for ${achievement.name}');
      // TODO: Integrate with inventory manager to grant coins
    }

    if (achievement.rewardGems > 0) {
      safePrint('💎 Granted ${achievement.rewardGems} gems for ${achievement.name}');
      // TODO: Integrate with inventory manager to grant gems
    }
  }

  /// Process completed achievements
  void _processCompletedAchievements() {
    final completedAchievements = _achievementProgress.values
        .where((progress) => progress.isCompleted)
        .map((progress) => progress.achievement.id)
        .toList();

    for (final achievementId in completedAchievements) {
      _unlockAchievement(achievementId);
    }
  }

  /// Reset achievement progress
  void resetProgress() {
    for (final achievement in _achievements) {
      if (!achievement.id.startsWith('games_')) { // Don't reset game count achievements
        _achievementProgress[achievement.id] = AchievementProgress(
          achievement: achievement,
          progress: {'current': 0},
        );
      }
    }
    notifyListeners();
    safePrint('🏆 Achievement progress reset');
  }

  /// Get achievement statistics
  Map<String, dynamic> getAchievementStats() => {
        'total_achievements': _achievements.length,
        'unlocked_count': unlockedAchievements.length,
        'completion_percentage': _achievements.isEmpty ? 0.0 :
            (unlockedAchievements.length / _achievements.length) * 100,
        'recent_achievements': recentAchievements.map((a) => a.name).toList(),
        'rarity_breakdown': {
          'common': unlockedAchievements.where((a) => a.rarity == AchievementRarity.common).length,
          'rare': unlockedAchievements.where((a) => a.rarity == AchievementRarity.rare).length,
          'epic': unlockedAchievements.where((a) => a.rarity == AchievementRarity.epic).length,
          'legendary': unlockedAchievements.where((a) => a.rarity == AchievementRarity.legendary).length,
        },
      };

  /// Dispose of resources
  @override
  void dispose() {
    safePrint('🏆 AchievementHandler disposed');
    super.dispose(); // Call super.dispose() as required by @mustCallSuper
  }
}
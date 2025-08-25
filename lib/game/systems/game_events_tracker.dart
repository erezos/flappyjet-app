/// 🎮 Game Events Tracker - Integrates missions and achievements with gameplay
library;

import 'package:flutter/foundation.dart';
import 'missions_manager.dart';
import 'achievements_manager.dart';
import 'inventory_manager.dart';
import 'server_manager.dart';

/// Game Events Tracker - Central hub for tracking all game events
class GameEventsTracker extends ChangeNotifier {
  static final GameEventsTracker _instance = GameEventsTracker._internal();
  factory GameEventsTracker() => _instance;
  GameEventsTracker._internal();

  final MissionsManager _missionsManager = MissionsManager();
  final AchievementsManager _achievementsManager = AchievementsManager();
  final InventoryManager _inventory = InventoryManager();
  final ServerManager _serverManager = ServerManager();

  bool _isInitialized = false;
  int _currentGameStartTime = 0;
  int _consecutiveGamesAboveThreshold = 0;
  int _lastGameScore = 0;
  final List<int> _recentScores = [];

  bool get isInitialized => _isInitialized;

  /// Initialize the events tracker
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _missionsManager.initialize();
    await _achievementsManager.initialize();
    await _inventory.initialize();
    await _serverManager.initialize();

    _isInitialized = true;
    debugPrint('🎮 Game Events Tracker initialized');
  }

  /// Track game start event
  Future<void> onGameStart() async {
    _currentGameStartTime = DateTime.now().millisecondsSinceEpoch;
    
    // Report analytics
    await _serverManager.reportEvent(
      eventName: 'game_start',
      parameters: {
        'timestamp': _currentGameStartTime,
        'equipped_skin': _inventory.equippedSkinId,
      },
    );
    
    debugPrint('🎮 Game started');
  }

  /// Track game end event with comprehensive data
  Future<void> onGameEnd({
    required int finalScore,
    required int survivalTimeMs,
    required int coinsEarned,
    required bool usedContinue,
    required String cause, // 'collision', 'quit', etc.
  }) async {
    final survivalTimeSeconds = (survivalTimeMs / 1000).round();
    
    // Update missions progress
    await _missionsManager.updatePlayerStats(
      newScore: finalScore,
      coinsEarned: coinsEarned,
      survivalTime: survivalTimeSeconds,
    );

    // Check achievements
    await _checkScoreAchievements(finalScore);
    await _checkSurvivalAchievements(survivalTimeSeconds);
    await _checkStreakAchievements(finalScore);

    // Grant coin rewards to inventory
    if (coinsEarned > 0) {
      await _inventory.grantSoftCurrency(coinsEarned);
      await _achievementsManager.updateProgress('coin_collector', coinsEarned);
    }

    // Submit score to server
    await _serverManager.submitScore(
      score: finalScore,
      survivalTime: survivalTimeSeconds,
      skinUsed: _inventory.equippedSkinId,
      coinsEarned: coinsEarned,
    );

    // Report analytics
    await _serverManager.reportEvent(
      eventName: 'game_end',
      parameters: {
        'score': finalScore,
        'survival_time': survivalTimeSeconds,
        'coins_earned': coinsEarned,
        'used_continue': usedContinue,
        'cause': cause,
        'skin_used': _inventory.equippedSkinId,
      },
    );

    _lastGameScore = finalScore;
    _recentScores.add(finalScore);
    if (_recentScores.length > 10) {
      _recentScores.removeAt(0); // Keep only last 10 scores
    }

    debugPrint('🎮 Game ended: Score $finalScore, Survival ${survivalTimeSeconds}s');
    notifyListeners();
  }

  /// Track continue usage
  Future<void> onContinueUsed({required int gemsCost}) async {
    await _missionsManager.updatePlayerStats(usedContinue: true);
    await _achievementsManager.updateProgress('never_give_up', 1);

    // Report analytics
    await _serverManager.reportEvent(
      eventName: 'continue_used',
      parameters: {
        'gems_cost': gemsCost,
        'current_score': _lastGameScore,
      },
    );

    debugPrint('🎮 Continue used for $gemsCost gems');
  }

  /// Track nickname change
  Future<void> onNicknameChanged(String newNickname) async {
    await _missionsManager.updatePlayerStats(changedNickname: true);
    await _achievementsManager.updateProgress('identity_established', 1);

    // Report analytics
    await _serverManager.reportEvent(
      eventName: 'nickname_changed',
      parameters: {
        'new_nickname_length': newNickname.length,
      },
    );

    debugPrint('🎮 Nickname changed to: $newNickname');
  }

  /// Track skin purchase
  Future<void> onSkinPurchased({
    required String skinId,
    required int coinCost,
    required String rarity,
  }) async {
    // Check collection achievements
    final ownedCount = _inventory.ownedSkinIds.length;
    await _achievementsManager.checkCollectionAchievements(ownedCount);

    // Report analytics
    await _serverManager.reportEvent(
      eventName: 'skin_purchased',
      parameters: {
        'skin_id': skinId,
        'coin_cost': coinCost,
        'rarity': rarity,
        'total_owned': ownedCount,
      },
    );

    debugPrint('🎮 Skin purchased: $skinId for $coinCost coins');
  }

  /// Track skin equipped
  Future<void> onSkinEquipped(String skinId) async {
    // Report analytics
    await _serverManager.reportEvent(
      eventName: 'skin_equipped',
      parameters: {
        'skin_id': skinId,
      },
    );

    debugPrint('🎮 Skin equipped: $skinId');
  }

  /// Track mission completion
  Future<void> onMissionCompleted({
    required String missionId,
    required String missionType,
    required int reward,
  }) async {
    // Grant mission reward
    await _inventory.grantSoftCurrency(reward);

    // Update mastery achievements
    await _achievementsManager.updateProgress('perfectionist', 1);

    // Report analytics
    await _serverManager.reportEvent(
      eventName: 'mission_completed',
      parameters: {
        'mission_id': missionId,
        'mission_type': missionType,
        'reward': reward,
      },
    );

    debugPrint('🎮 Mission completed: $missionId, reward: $reward coins');
  }

  /// Track achievement unlock
  Future<void> onAchievementUnlocked({
    required String achievementId,
    required String category,
    required String rarity,
    required int coinReward,
    required int gemReward,
  }) async {
    // Grant achievement rewards
    if (coinReward > 0) {
      await _inventory.grantSoftCurrency(coinReward);
    }
    if (gemReward > 0) {
      await _inventory.grantGems(gemReward);
    }

    // Report analytics
    await _serverManager.reportEvent(
      eventName: 'achievement_unlocked',
      parameters: {
        'achievement_id': achievementId,
        'category': category,
        'rarity': rarity,
        'coin_reward': coinReward,
        'gem_reward': gemReward,
      },
    );

    debugPrint('🎮 Achievement unlocked: $achievementId');
  }

  /// Track IAP purchase
  Future<void> onIAPPurchase({
    required String productId,
    required String purchaseToken,
    required String platform,
    required double priceUSD,
  }) async {
    // Note: Purchase validation not implemented in RailwayServerManager yet
    final isValid = true; // Assume valid for now

    // Note: IAP purchase analytics handled by monetization system
    debugPrint('🎮 Analytics: IAP purchase $productId, price: \$${priceUSD}, valid: $isValid');

    debugPrint('🎮 IAP Purchase: $productId, valid: $isValid');
  }

  /// Check score-based achievements
  Future<void> _checkScoreAchievements(int score) async {
    await _achievementsManager.checkScoreAchievements(score);
  }

  /// Check survival-based achievements
  Future<void> _checkSurvivalAchievements(int survivalTimeSeconds) async {
    await _achievementsManager.checkSurvivalAchievements(survivalTimeSeconds);
  }

  /// Check streak-based achievements
  Future<void> _checkStreakAchievements(int score) async {
    // Track consecutive games above threshold
    const streakThreshold = 5;
    
    if (score >= streakThreshold) {
      _consecutiveGamesAboveThreshold++;
    } else {
      _consecutiveGamesAboveThreshold = 0;
    }

    // Check streak achievements based on consecutive count
    if (_consecutiveGamesAboveThreshold >= 3) {
      await _achievementsManager.updateProgress('consistent_flyer', _consecutiveGamesAboveThreshold);
    }
    if (_consecutiveGamesAboveThreshold >= 5) {
      await _achievementsManager.updateProgress('streak_master', _consecutiveGamesAboveThreshold);
    }
    if (_consecutiveGamesAboveThreshold >= 7) {
      await _achievementsManager.updateProgress('unstoppable_force', _consecutiveGamesAboveThreshold);
    }
  }

  /// Get current streak count
  int get currentStreak => _consecutiveGamesAboveThreshold;

  /// Get recent performance stats
  Map<String, dynamic> get recentStats {
    if (_recentScores.isEmpty) {
      return {
        'average_score': 0,
        'best_recent': 0,
        'games_played': 0,
        'improvement_trend': 0.0,
      };
    }

    final average = _recentScores.reduce((a, b) => a + b) / _recentScores.length;
    final best = _recentScores.reduce((a, b) => a > b ? a : b);
    
    // Calculate improvement trend (last 5 vs first 5 games)
    double trend = 0.0;
    if (_recentScores.length >= 6) {
      final firstHalf = _recentScores.take(_recentScores.length ~/ 2).toList();
      final secondHalf = _recentScores.skip(_recentScores.length ~/ 2).toList();
      
      final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
      final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;
      
      trend = (secondAvg - firstAvg) / firstAvg;
    }

    return {
      'average_score': average.round(),
      'best_recent': best,
      'games_played': _recentScores.length,
      'improvement_trend': trend,
    };
  }

  /// Force sync all data with server
  Future<void> syncWithServer() async {
    await _serverManager.forceSyncNow();
  }

  /// Check if player needs encouragement (poor recent performance)
  bool get needsEncouragement {
    if (_recentScores.length < 3) return false;
    
    final recentAverage = _recentScores.take(3).reduce((a, b) => a + b) / 3;
    final overallAverage = _recentScores.reduce((a, b) => a + b) / _recentScores.length;
    
    return recentAverage < overallAverage * 0.7; // Recent performance is 30% below average
  }

  /// Get personalized encouragement message
  String get encouragementMessage {
    final stats = recentStats;
    final trend = stats['improvement_trend'] as double;
    
    if (trend > 0.1) {
      return "You're improving! Keep up the great work! 🚀";
    } else if (_consecutiveGamesAboveThreshold > 0) {
      return "Nice streak! You're on fire! 🔥";
    } else {
      return "Every expert was once a beginner. Keep flying! ✈️";
    }
  }
}

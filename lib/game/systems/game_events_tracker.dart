/// 🎮 Game Events Tracker - Integrates missions and achievements with gameplay
library;
import '../../core/debug_logger.dart';

import 'package:flutter/foundation.dart';
import 'missions_manager.dart';
import 'achievements_manager.dart';
import 'inventory_manager.dart';
import '../../core/network/network_manager.dart';
import '../../core/analytics/unified_analytics_manager.dart';

/// Game Events Tracker - Central hub for tracking all game events
class GameEventsTracker extends ChangeNotifier {
  static final GameEventsTracker _instance = GameEventsTracker._internal();
  factory GameEventsTracker() => _instance;
  GameEventsTracker._internal();

  MissionsManager? _missionsManager;
  AchievementsManager? _achievementsManager;
  InventoryManager? _inventory;
  NetworkManager? _networkManager;
  UnifiedAnalyticsManager? _analytics;

  bool _isInitialized = false;
  // int _currentGameStartTime = 0; // Unused field - removed for production
  int _consecutiveGamesAboveThreshold = 0;
  int _lastGameScore = 0;
  final List<int> _recentScores = [];

  bool get isInitialized => _isInitialized;

  /// Initialize the events tracker with shared instances
  Future<void> initialize({
    MissionsManager? missionsManager,
    AchievementsManager? achievementsManager,
    InventoryManager? inventoryManager,
    NetworkManager? networkManager,
  }) async {
    if (_isInitialized) return;

    // Use provided instances or create new ones
    _missionsManager = missionsManager ?? MissionsManager();
    _achievementsManager = achievementsManager ?? AchievementsManager();
    // Note: InventoryManager now requires repository dependencies, must be passed in
    _inventory = inventoryManager; // Will be null if not provided
    _networkManager = networkManager ?? NetworkManager();
    _analytics = UnifiedAnalyticsManager();

    await _missionsManager!.initialize();
    await _achievementsManager!.initialize();
    if (_inventory != null) {
      // InventoryManager is already initialized in main.dart
      safePrint('🎒 Using pre-initialized InventoryManager');
    }
    await _networkManager!.initialize();
    // Analytics already initialized in main.dart

    _isInitialized = true;
    safePrint('🎮 Game Events Tracker initialized with shared instances');
  }

  /// Track game start event
  Future<void> onGameStart() async {
    // 📊 Send analytics to both Firebase and Railway backend
    _analytics?.trackEvent('game_start', {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    safePrint('🎮 Game started');
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
    if (_missionsManager != null) {
      await _missionsManager!.updatePlayerStats(
        newScore: finalScore,
        coinsEarned: coinsEarned,
        survivalTime: survivalTimeSeconds,
      );
    }

    // Check achievements
    if (_achievementsManager != null) {
      await _achievementsManager!.checkScoreAchievements(finalScore);
      await _achievementsManager!.checkSurvivalAchievements(survivalTimeSeconds);
    }
    // Check streak achievements inline
    const streakThreshold = 5;
    if (finalScore >= streakThreshold) {
      _consecutiveGamesAboveThreshold++;
    } else {
      _consecutiveGamesAboveThreshold = 0;
    }

    // Check streak achievements based on consecutive count
    if (_achievementsManager != null) {
      if (_consecutiveGamesAboveThreshold >= 3) {
        await _achievementsManager!.updateProgress('consistent_flyer', _consecutiveGamesAboveThreshold);
      }
      if (_consecutiveGamesAboveThreshold >= 5) {
        await _achievementsManager!.updateProgress('streak_master', _consecutiveGamesAboveThreshold);
      }
      if (_consecutiveGamesAboveThreshold >= 7) {
        await _achievementsManager!.updateProgress('unstoppable_force', _consecutiveGamesAboveThreshold);
      }
    }

    // Grant coin rewards to inventory
    if (coinsEarned > 0 && _inventory != null && _achievementsManager != null) {
      await _inventory!.grantSoftCurrency(coinsEarned);
      await _achievementsManager!.updateProgress('coin_collector', coinsEarned);
    }

    // 📊 Send analytics to both Firebase and Railway backend
    _analytics?.trackGameEnd(
      finalScore: finalScore,
      survivalTimeSeconds: survivalTimeSeconds,
      causeOfDeath: cause,
      theme: 'current_theme', // TODO: Get actual theme
      selectedJet: 'current_jet', // TODO: Get actual jet
      coinsEarned: coinsEarned,
      usedContinue: usedContinue,
    );

    _lastGameScore = finalScore;
    _recentScores.add(finalScore);
    if (_recentScores.length > 10) {
      _recentScores.removeAt(0); // Keep only last 10 scores
    }

    safePrint('🎮 Game ended: Score $finalScore, Survival ${survivalTimeSeconds}s');
    notifyListeners();
  }

  /// Track continue usage
  Future<void> onContinueUsed({required int gemsCost}) async {
    if (_missionsManager != null) {
      await _missionsManager!.updatePlayerStats(usedContinue: true);
    }
    if (_achievementsManager != null) {
      await _achievementsManager!.updateProgress('never_give_up', 1);
    }

    // 📊 Report analytics
    _analytics?.trackEvent('continue_used', {
      'gems_cost': gemsCost,
      'current_score': _lastGameScore,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    safePrint('🎮 Continue used for $gemsCost gems');
  }

  /// Track nickname change
  Future<void> onNicknameChanged(String newNickname) async {
    safePrint('🎮 GameEventsTracker.onNicknameChanged called: $newNickname');
    
    // 🎯 CRITICAL FIX: Use singleton instances directly (like other achievements do)
    try {
      final missionsManager = MissionsManager();
      safePrint('🎮 Updating missions manager for nickname change');
      await missionsManager.updatePlayerStats(changedNickname: true);
    } catch (e) {
      safePrint('🎮 ❌ Failed to update missions manager: $e');
    }
    
    try {
      final achievementsManager = AchievementsManager();
      safePrint('🎮 Calling AchievementsManager.updateProgress for identity_established');
      await achievementsManager.updateProgress('identity_established', 1);
      safePrint('🎮 ✅ AchievementsManager.updateProgress completed');
    } catch (e) {
      safePrint('🎮 ❌ Failed to update achievements manager: $e');
    }

    // 📊 Report analytics
    _analytics?.trackEvent('nickname_changed', {
      'new_nickname_length': newNickname.length,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    safePrint('🎮 Nickname changed to: $newNickname');
  }

  /// Track skin purchase
  Future<void> onSkinPurchased({
    required String skinId,
    required int coinCost,
    required String rarity,
  }) async {
    // Check collection achievements
    int ownedCount = 0;
    if (_inventory != null && _achievementsManager != null) {
      ownedCount = _inventory!.ownedSkinIds.length;
      await _achievementsManager!.checkCollectionAchievements(ownedCount);
    }

    // 📊 Report analytics
    _analytics?.trackPurchase(
      itemId: skinId,
      itemName: 'jet_skin_$skinId',
      price: coinCost.toDouble(),
      currency: 'coins',
      purchaseType: 'coins',
    );

    safePrint('🎮 Skin purchased: $skinId for $coinCost coins');
  }

  /// Track skin equipped
  Future<void> onSkinEquipped(String skinId) async {
    // 📊 Report analytics
    _analytics?.trackEvent('skin_equipped', {
      'skin_id': skinId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    safePrint('🎮 Skin equipped: $skinId');
  }

  /// Track mission completion
  Future<void> onMissionCompleted({
    required String missionId,
    required String missionType,
    required int reward,
  }) async {
    // Grant mission reward
    if (_inventory != null) {
      await _inventory!.grantSoftCurrency(reward);
    }

    // Update mastery achievements
    if (_achievementsManager != null) {
      await _achievementsManager!.updateProgress('perfectionist', 1);
    }

    // 📊 Report analytics
    _analytics?.trackMissionComplete(
      missionId: missionId,
      missionType: missionType,
      rewardCoins: reward,
      rewardGems: 0, // TODO: Add gem rewards
      completionTimeSeconds: 0, // TODO: Track completion time
    );

    safePrint('🎮 Mission completed: $missionId, reward: $reward coins');
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
    if (_inventory != null) {
      if (coinReward > 0) {
        await _inventory!.grantSoftCurrency(coinReward);
      }
      if (gemReward > 0) {
        await _inventory!.grantGems(gemReward);
      }
    }

    // 📊 Report analytics
    _analytics?.trackAchievementUnlock(
      achievementId: achievementId,
      achievementName: achievementId, // TODO: Get actual achievement name
      category: category,
      rarity: rarity,
      rewardCoins: coinReward,
      rewardGems: gemReward,
    );

    safePrint('🎮 Achievement unlocked: $achievementId');
  }

  /// Track IAP purchase
  Future<void> onIAPPurchase({
    required String productId,
    required String purchaseToken,
    required String platform,
    required double priceUSD,
  }) async {
    // 📊 Report analytics (purchase validation will be added later)
    _analytics?.trackPurchase(
      itemId: productId,
      itemName: productId,
      price: priceUSD,
      currency: 'USD',
      purchaseType: 'real_money',
    );

    safePrint('🎮 IAP Purchase: $productId for \$${priceUSD.toStringAsFixed(2)}');
  }





  /// Get current streak count
  int get currentStreak => _consecutiveGamesAboveThreshold;
}
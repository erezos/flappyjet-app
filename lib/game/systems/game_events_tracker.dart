/// 🎮 Game Events Tracker - Integrates missions and achievements with gameplay
library;
import '../../core/debug_logger.dart';

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

  MissionsManager? _missionsManager;
  AchievementsManager? _achievementsManager;
  InventoryManager? _inventory;
  ServerManager? _serverManager;

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
    ServerManager? serverManager,
  }) async {
    if (_isInitialized) return;

    // Use provided instances or create new ones
    _missionsManager = missionsManager ?? MissionsManager();
    _achievementsManager = achievementsManager ?? AchievementsManager();
    _inventory = inventoryManager ?? InventoryManager();
    _serverManager = serverManager ?? ServerManager();

    await _missionsManager!.initialize();
    await _achievementsManager!.initialize();
    await _inventory!.initialize();
    await _serverManager!.initialize();

    _isInitialized = true;
    safePrint('🎮 Game Events Tracker initialized with shared instances');
  }

  /// Track game start event
  Future<void> onGameStart() async {
    // Game start time tracking removed for production optimization

    // Analytics tracking is now handled by FirebaseAnalyticsManager directly
    // No need for server-side event reporting

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

    // Analytics and scoring are now handled by FirebaseAnalyticsManager and Railway backend
    // No server-side event reporting needed here

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

    // Report analytics
    if (_serverManager != null) {
      await _serverManager!.reportEvent(
        eventName: 'continue_used',
        parameters: {
          'gems_cost': gemsCost,
          'current_score': _lastGameScore,
        },
      );
    }

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

    // Report analytics
    if (_serverManager != null) {
      await _serverManager!.reportEvent(
        eventName: 'nickname_changed',
        parameters: {
          'new_nickname_length': newNickname.length,
        },
      );
    }

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

    // Report analytics
    if (_serverManager != null) {
      await _serverManager!.reportEvent(
        eventName: 'skin_purchased',
        parameters: {
          'skin_id': skinId,
          'coin_cost': coinCost,
          'rarity': rarity,
          'total_owned': ownedCount,
        },
      );
    }

    safePrint('🎮 Skin purchased: $skinId for $coinCost coins');
  }

  /// Track skin equipped
  Future<void> onSkinEquipped(String skinId) async {
    // Report analytics
    if (_serverManager != null) {
      await _serverManager!.reportEvent(
        eventName: 'skin_equipped',
        parameters: {
          'skin_id': skinId,
        },
      );
    }

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

    // Report analytics
    if (_serverManager != null) {
      await _serverManager!.reportEvent(
        eventName: 'mission_completed',
        parameters: {
          'mission_id': missionId,
          'mission_type': missionType,
          'reward': reward,
        },
      );
    }

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

    // Report analytics
    if (_serverManager != null) {
      await _serverManager!.reportEvent(
        eventName: 'achievement_unlocked',
        parameters: {
          'achievement_id': achievementId,
          'category': category,
          'rarity': rarity,
          'coin_reward': coinReward,
          'gem_reward': gemReward,
        },
      );
    }

    safePrint('🎮 Achievement unlocked: $achievementId');
  }

  /// Track IAP purchase
  Future<void> onIAPPurchase({
    required String productId,
    required String purchaseToken,
    required String platform,
    required double priceUSD,
  }) async {
    // Validate purchase with server
    bool isValid = false;
    if (_serverManager != null) {
      isValid = await _serverManager!.validatePurchase(
        productId: productId,
        purchaseToken: purchaseToken,
        platform: platform,
      );

      // Report analytics
      await _serverManager!.reportEvent(
        eventName: 'iap_purchase',
        parameters: {
          'product_id': productId,
          'price_usd': priceUSD,
          'platform': platform,
          'valid': isValid,
        },
      );
    }

    safePrint('🎮 IAP Purchase: $productId, valid: $isValid');
  }





  /// Get current streak count
  int get currentStreak => _consecutiveGamesAboveThreshold;
}
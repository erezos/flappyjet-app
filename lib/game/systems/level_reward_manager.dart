/// 💰 STORY MODE - LEVEL REWARD MANAGER
/// 
/// Manages reward calculation and distribution for level completions.
/// Integrates with InventoryManager to grant coins and gems.
library;

import 'package:flutter/foundation.dart';
import '../../models/level_data_schema.dart';
import '../../core/debug_logger.dart';
import 'inventory_manager.dart';
import 'level_system_manager.dart';

class LevelRewardManager extends ChangeNotifier {
  static final LevelRewardManager _instance = LevelRewardManager._internal();
  factory LevelRewardManager() => _instance;
  LevelRewardManager._internal();

  final InventoryManager _inventoryManager = InventoryManager();
  final LevelSystemManager _levelSystemManager = LevelSystemManager();

  /// Calculate rewards for a level
  LevelReward calculateRewards(LevelData level, {bool botVictory = false, bool isReplay = false}) {
    // 🔄 REPLAY: Fixed 20 coins, no gems or special rewards
    if (isReplay) {
      safePrint('🔄 Replay mode: Fixed 20 coin reward');
      return LevelReward(
        coins: 20,
        gems: 0,
        specialReward: null,
      );
    }

    // Normal rewards for first completion
    int coins = level.reward.coins;
    int gems = level.reward.gems;
    String? specialReward = level.reward.specialReward;

    // Double coins for bot battle victories
    if (level.botBattle != null && botVictory) {
      coins *= 2;
      safePrint('💰 Bot battle victory! Coins doubled: $coins');
    }

    return LevelReward(
      coins: coins,
      gems: gems,
      specialReward: specialReward,
    );
  }

  /// Grant rewards to player
  Future<void> grantRewards({
    required int levelId,
    required LevelReward reward,
    bool? botDefeated,
    bool isReplay = false,
  }) async {
    try {
      final mode = isReplay ? '🔄 REPLAY' : '🎉 FIRST COMPLETION';
      safePrint('💰 Granting rewards for level $levelId ($mode)...');
      safePrint('💰 +${reward.coins} 🪙 coins');
      if (reward.gems > 0) {
        safePrint('💰 +${reward.gems} 💎 gems');
      }
      if (reward.specialReward != null) {
        safePrint('💰 🎁 Special reward: ${reward.specialReward}');
      }

      // Grant coins
      if (reward.coins > 0) {
        await _inventoryManager.grantSoftCurrency(reward.coins);
      }

      // Grant gems
      if (reward.gems > 0) {
        await _inventoryManager.grantGems(reward.gems);
      }

      // Handle special rewards (e.g., exclusive skins)
      if (reward.specialReward != null) {
        await _handleSpecialReward(reward.specialReward!);
      }

      // Update level system progress (only if not replay)
      if (!isReplay) {
        await _levelSystemManager.completeLevel(
          levelId: levelId,
          coinsEarned: reward.coins,
          gemsEarned: reward.gems,
          botDefeated: botDefeated,
        );
      }

      safePrint('💰 ✅ Rewards granted successfully');
      notifyListeners();
    } catch (e) {
      safePrint('❌ Error granting rewards: $e');
      rethrow;
    }
  }

  /// Handle special rewards (skins, boosters, etc.)
  Future<void> _handleSpecialReward(String rewardId) async {
    try {
      // Special rewards are typically skins
      if (rewardId.startsWith('exclusive_skin_')) {
        final skinId = rewardId.replaceFirst('exclusive_skin_', '');
        
        // Check if player already owns this skin
        if (!_inventoryManager.ownedSkinIds.contains(skinId)) {
          await _inventoryManager.unlockSkin(skinId);
          safePrint('💰 🎁 Unlocked exclusive skin: $skinId');
        } else {
          safePrint('💰 ⚠️ Player already owns skin: $skinId');
        }
      } else {
        safePrint('💰 ⚠️ Unknown special reward type: $rewardId');
      }
    } catch (e) {
      safePrint('❌ Error handling special reward: $e');
    }
  }

  /// Get total rewards earned from story mode
  int get totalCoinsEarned => _levelSystemManager.totalCoinsEarned;
  int get totalGemsEarned => _levelSystemManager.totalGemsEarned;

  /// Calculate potential rewards for a level (preview)
  Map<String, dynamic> previewRewards(LevelData level) {
    return {
      'coins': level.reward.coins,
      'gems': level.reward.gems,
      'coinsIfBotVictory': level.botBattle != null ? level.reward.coins * 2 : level.reward.coins,
      'hasSpecialReward': level.reward.hasSpecialReward,
      'specialReward': level.reward.specialReward,
    };
  }

  /// Check if level has bonus rewards (gems or special)
  bool hasBonusRewards(LevelData level) {
    return level.reward.gems > 0 || level.reward.hasSpecialReward;
  }
}

/// 🔄 User Restoration Service - Restores user state from Railway backend after app reinstall
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../game/systems/player_identity_manager.dart';
import '../game/systems/inventory_manager.dart';
import '../game/systems/daily_streak_manager.dart';
import '../game/systems/lives_manager.dart';
import '../game/systems/game_state_manager.dart';
import '../core/debug_logger.dart';
import 'enhanced_iap_manager.dart';

class UserRestorationService {
  static final UserRestorationService _instance = UserRestorationService._internal();
  factory UserRestorationService() => _instance;
  UserRestorationService._internal();

  static const String baseUrl = 'https://flappyjet-backend-production.up.railway.app';
  static const Duration timeout = Duration(seconds: 15);

  /// Restore complete user state from backend after successful authentication
  Future<bool> restoreUserState() async {
    try {
      final playerIdentityManager = PlayerIdentityManager();
      
      // Only restore if user is authenticated
      if (playerIdentityManager.authState != AuthState.authenticated) {
        safePrint('🔄 ⚠️ Cannot restore user state - not authenticated');
        return false;
      }

      safePrint('🔄 🚀 Starting user state restoration from backend...');

      // Get fresh user profile from backend
      final profileData = await _fetchUserProfile();
      if (profileData == null) {
        safePrint('🔄 ❌ Failed to fetch user profile from backend');
        return false;
      }

      // Restore all user systems in correct order
      // 1. Game state (best score & streak) - CRITICAL for profile display
      await _restoreGameStateManager(profileData);
      
      // 2. Inventory (needed for heart booster status)
      await _restoreInventoryManager(profileData);
      
      // 3. Daily streak manager
      await _restoreDailyStreakManager(profileData);
      
      // 4. Lives manager last (depends on inventory for heart booster status)
      await _restoreLivesManager(profileData);

      safePrint('🔄 ✅ User state restoration completed successfully');
      return true;

    } catch (e) {
      safePrint('🔄 ❌ Error during user state restoration: $e');
      return false;
    }
  }

  /// Fetch user profile from backend
  Future<Map<String, dynamic>?> _fetchUserProfile() async {
    try {
      final playerIdentityManager = PlayerIdentityManager();
      final authToken = playerIdentityManager.authToken;

      if (authToken.isEmpty) {
        safePrint('🔄 ❌ No auth token available for profile fetch');
        return null;
      }

      final uri = Uri.parse('$baseUrl/api/auth/profile');
      safePrint('🔄 📡 Fetching user profile from: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          safePrint('🔄 ✅ User profile fetched successfully');
          return data['player'];
        } else {
          safePrint('🔄 ❌ Backend returned error: ${data['error']}');
          return null;
        }
      } else {
        safePrint('🔄 ❌ HTTP error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      safePrint('🔄 ❌ Exception fetching user profile: $e');
      return null;
    }
  }

  /// Restore GameStateManager state (best score & streak) from backend data
  Future<void> _restoreGameStateManager(Map<String, dynamic> profileData) async {
    try {
      final gameStateManager = GameStateManager();
      
      // Get player data from backend
      final playerData = profileData['player'] as Map<String, dynamic>?;
      
      if (playerData != null) {
        final backendBestScore = playerData['best_score'] as int? ?? 0;
        final backendBestStreak = playerData['best_streak'] as int? ?? 0;
        
        // Get local values
        final prefs = await SharedPreferences.getInstance();
        final localBestScore = prefs.getInt('best_score') ?? 0;
        final localBestStreak = prefs.getInt('best_streak') ?? 0;
        
        // Smart conflict resolution: Take the HIGHER value (player's achievement)
        final finalBestScore = backendBestScore > localBestScore ? backendBestScore : localBestScore;
        final finalBestStreak = backendBestStreak > localBestStreak ? backendBestStreak : localBestStreak;
        
        safePrint('🔄 🏆 Smart score sync: Local($localBestScore score, $localBestStreak streak) + Backend($backendBestScore score, $backendBestStreak streak) = Final($finalBestScore score, $finalBestStreak streak)');
        
        // Restore to GameStateManager (in-memory)
        gameStateManager.setBestScore(finalBestScore);
        gameStateManager.setBestStreak(finalBestStreak);
        
        // Persist to SharedPreferences
        await prefs.setInt('best_score', finalBestScore);
        await prefs.setInt('best_streak', finalBestStreak);
        
        safePrint('🔄 🏆 Best score and streak restored: $finalBestScore score, $finalBestStreak streak');
        
        // Sync back to backend if local was higher
        if (finalBestScore > backendBestScore || finalBestStreak > backendBestStreak) {
          safePrint('🔄 🏆 Local scores higher - syncing to backend');
          // The GameStateManager will sync automatically via its async methods
        }
      } else {
        safePrint('🔄 🏆 No player data found in profile, using local state');
      }

      safePrint('🔄 ✅ GameStateManager state restored successfully');
    } catch (e) {
      safePrint('🔄 ❌ Error restoring GameStateManager: $e');
    }
  }

  /// Restore InventoryManager state from backend data with smart conflict resolution
  Future<void> _restoreInventoryManager(Map<String, dynamic> profileData) async {
    try {
      final inventoryManager = InventoryManager();
      
      // 🔥 CRITICAL: Check if IAP purchase is in progress or recently completed
      final enhancedIAP = EnhancedIAPManager();
      if (enhancedIAP.isProcessingPurchase || enhancedIAP.isRecentlyPurchased) {
        safePrint('🔄 🔒 Skipping currency restoration - IAP purchase in progress or recently completed');
        safePrint('🔄 🔒 Processing: ${enhancedIAP.isProcessingPurchase}, Recent: ${enhancedIAP.isRecentlyPurchased}');
        return;
      }
      
      // Get current local currency before restoration
      final localCoins = inventoryManager.softCurrency;
      final localGems = inventoryManager.gems;
      
      // Get backend currency
      final backendCoins = profileData['current_coins'] ?? 500;
      final backendGems = profileData['current_gems'] ?? 25;
      
      // Smart conflict resolution: 
      // - For coins: take the higher value to prevent loss
      // - For gems: trust local value if it's lower (user spent gems), otherwise take higher
      // Note: IAP purchases are protected by the isProcessingPurchase/isRecentlyPurchased checks above
      final finalCoins = localCoins > backendCoins ? localCoins : backendCoins;
      final finalGems = localGems <= backendGems ? localGems : backendGems;
      
      // Only update if there's a difference to avoid unnecessary operations
      if (localCoins != finalCoins || localGems != finalGems) {
        safePrint('🔄 💰 Smart currency sync: Local($localCoins coins, $localGems gems) + Backend($backendCoins coins, $backendGems gems) = Final($finalCoins coins, $finalGems gems)');
        await inventoryManager.setCurrency(finalCoins, finalGems);
        
        // Sync the resolved values back to backend if local was higher
        if (localCoins > backendCoins || localGems > backendGems) {
          await _syncCurrencyToBackend(finalCoins, finalGems);
        }
      } else {
        safePrint('🔄 💰 Currency already in sync: $finalCoins coins, $finalGems gems');
      }

      // Restore heart booster
      final heartBoosterExpiry = profileData['heart_booster_expiry'];
      if (heartBoosterExpiry != null) {
        final expiryDate = DateTime.parse(heartBoosterExpiry);
        if (expiryDate.isAfter(DateTime.now())) {
          safePrint('🔄 💖 Restoring active heart booster until: $expiryDate');
          await inventoryManager.activateHeartBooster(expiryDate.difference(DateTime.now()));
        }
      }

      // Restore inventory from backend inventory data
      final inventory = profileData['inventory'] as List<dynamic>? ?? [];
      final ownedSkins = <String>{};
      String? equippedSkin;
      DateTime? latestEquippedTime;

      safePrint('🔄 ✈️ Inventory restoration analysis:');
      safePrint('   Backend inventory items: ${inventory.length}');
      
      for (final item in inventory) {
        safePrint('   Item: ${item['item_type']} - ${item['item_id']} (equipped: ${item['equipped']})');
        
        if (item['item_type'] == 'skin') {
          final skinId = item['item_id'] as String;
          ownedSkins.add(skinId);
          
          if (item['equipped'] == true) {
            // 🔥 CRITICAL FIX: Use the most recently updated equipped skin
            final updatedAt = item['updated_at'] != null 
                ? DateTime.parse(item['updated_at']) 
                : DateTime.now();
            
            if (latestEquippedTime == null || updatedAt.isAfter(latestEquippedTime)) {
              equippedSkin = skinId;
              latestEquippedTime = updatedAt;
              safePrint('   🎯 New equipped skin candidate: $skinId (updated: $updatedAt)');
            }
          }
        }
      }

      safePrint('🔄 ✈️ Skin restoration summary:');
      safePrint('   Owned skins: ${ownedSkins.toList()}');
      safePrint('   Equipped skin: $equippedSkin');

      if (ownedSkins.isNotEmpty) {
        safePrint('🔄 ✈️ Restoring ${ownedSkins.length} owned skins');
        await inventoryManager.restoreOwnedSkins(ownedSkins);
        
        if (equippedSkin != null) {
          safePrint('🔄 ✈️ Restoring equipped skin: $equippedSkin');
          // 🔥 CRITICAL FIX: Ensure skin is owned before equipping
          if (inventoryManager.ownedSkinIds.contains(equippedSkin)) {
            await inventoryManager.equipSkin(equippedSkin);
            safePrint('🔄 ✈️ ✅ Equipped skin restored: $equippedSkin');
          } else {
            safePrint('🔄 ✈️ ⚠️ Cannot equip $equippedSkin - not owned after merge');
          }
        }
      } else {
        safePrint('🔄 ✈️ No skins found in backend inventory - using local state');
      }

      safePrint('🔄 ✅ InventoryManager state restored successfully');
    } catch (e) {
      safePrint('🔄 ❌ Error restoring InventoryManager: $e');
    }
  }

  /// Restore DailyStreakManager state from backend data
  Future<void> _restoreDailyStreakManager(Map<String, dynamic> profileData) async {
    try {
      final dailyStreakManager = DailyStreakManager();
      
      // Get daily streak data from backend
      final dailyStreakData = profileData['daily_streak'] as Map<String, dynamic>?;
      
      if (dailyStreakData != null) {
        final currentStreak = dailyStreakData['current_streak'] ?? 0;
        final currentCycle = dailyStreakData['current_cycle'] ?? 0;
        final cycleRewardSet = dailyStreakData['cycle_reward_set'] ?? 'new_player';
        final totalCyclesCompleted = dailyStreakData['total_cycles_completed'] ?? 0;
        
        safePrint('🔄 🔥 Restoring daily streak: $currentStreak days, cycle $currentCycle, reward set: $cycleRewardSet');
        
        if (currentStreak > 0) {
          await dailyStreakManager.restoreStreak(currentStreak);
        }
        
        // Restore cycle data
        await dailyStreakManager.restoreCycleData(
          currentCycle: currentCycle,
          cycleRewardSet: cycleRewardSet,
          totalCyclesCompleted: totalCyclesCompleted,
          cycleStartDate: dailyStreakData['cycle_start_date'] != null 
              ? DateTime.parse(dailyStreakData['cycle_start_date']) 
              : null,
        );
        
        safePrint('🔄 🔥 Daily streak data: cycle=$currentCycle, rewardSet=$cycleRewardSet, totalCycles=$totalCyclesCompleted');
      } else {
        safePrint('🔄 🔥 No daily streak data found in profile, using local state');
      }

      safePrint('🔄 ✅ DailyStreakManager state restored successfully');
    } catch (e) {
      safePrint('🔄 ❌ Error restoring DailyStreakManager: $e');
    }
  }

  /// Restore LivesManager state from backend data with heart booster awareness
  Future<void> _restoreLivesManager(Map<String, dynamic> profileData) async {
    try {
      final livesManager = LivesManager();
      final inventoryManager = InventoryManager();
      
      final backendHearts = profileData['current_hearts'] ?? 3;
      final localHearts = livesManager.currentLives;
      final maxHearts = livesManager.maxLives; // This accounts for heart booster (3 or 6)
      
      safePrint('🔄 💖 Heart restoration analysis:');
      safePrint('   Backend hearts: $backendHearts');
      safePrint('   Local hearts: $localHearts');
      safePrint('   Max hearts (with booster): $maxHearts');
      
      // Smart heart restoration logic
      int heartsToRestore = backendHearts;
      
      // If heart booster is active, ensure we don't go below the boosted maximum
      if (inventoryManager.isHeartBoosterActive) {
        safePrint('🔄 💖 Heart booster is active - ensuring minimum of $maxHearts hearts');
        
        // If backend has fewer hearts than the boosted maximum, use the boosted maximum
        if (backendHearts < maxHearts) {
          heartsToRestore = maxHearts;
          safePrint('🔄 💖 Backend hearts ($backendHearts) < boosted max ($maxHearts) - using boosted max');
        }
      }
      
      // Only restore if there's a meaningful difference
      if (heartsToRestore != localHearts) {
        safePrint('🔄 💖 Restoring hearts: $localHearts → $heartsToRestore');
        await livesManager.restoreHearts(heartsToRestore);
      } else {
        safePrint('🔄 💖 Hearts already correct: $localHearts (no restoration needed)');
      }

      safePrint('🔄 ✅ LivesManager state restored successfully');
    } catch (e) {
      safePrint('🔄 ❌ Error restoring LivesManager: $e');
    }
  }

  /// Sync resolved currency values back to backend
  Future<void> _syncCurrencyToBackend(int coins, int gems) async {
    try {
      final playerIdentityManager = PlayerIdentityManager();
      if (!playerIdentityManager.isAuthenticated) {
        safePrint('🔄 ⚠️ Cannot sync currency to backend - not authenticated');
        return;
      }

      final token = playerIdentityManager.authToken;
      if (token.isEmpty) return;

      final response = await http.put(
        Uri.parse('$baseUrl/api/player/sync-currency'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'coins': coins,
          'gems': gems,
          'syncReason': 'local_higher_value',
        }),
      ).timeout(timeout);

      if (response.statusCode == 200) {
        safePrint('🔄 ✅ Currency synced to backend: $coins coins, $gems gems');
      } else {
        safePrint('🔄 ⚠️ Failed to sync currency to backend: ${response.statusCode}');
      }
    } catch (e) {
      safePrint('🔄 ❌ Error syncing currency to backend: $e');
      // Don't throw - local functionality should work even if backend sync fails
    }
  }
}

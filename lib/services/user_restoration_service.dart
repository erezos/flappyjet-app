/// 🔄 User Restoration Service - Restores user state from Railway backend after app reinstall
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../game/systems/player_identity_manager.dart';
import '../game/systems/inventory_manager.dart';
import '../game/systems/daily_streak_manager.dart';
import '../game/systems/lives_manager.dart';
import '../core/debug_logger.dart';

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

      // Restore all user systems
      await _restoreInventoryManager(profileData);
      await _restoreDailyStreakManager(profileData);
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

  /// Restore InventoryManager state from backend data with smart conflict resolution
  Future<void> _restoreInventoryManager(Map<String, dynamic> profileData) async {
    try {
      final inventoryManager = InventoryManager();
      
      // Get current local currency before restoration
      final localCoins = inventoryManager.softCurrency;
      final localGems = inventoryManager.gems;
      
      // Get backend currency
      final backendCoins = profileData['current_coins'] ?? 500;
      final backendGems = profileData['current_gems'] ?? 25;
      
      // Smart conflict resolution: take the higher value to prevent loss
      final finalCoins = localCoins > backendCoins ? localCoins : backendCoins;
      final finalGems = localGems > backendGems ? localGems : backendGems;
      
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

      for (final item in inventory) {
        if (item['item_type'] == 'skin') {
          final skinId = item['item_id'] as String;
          ownedSkins.add(skinId);
          
          if (item['equipped'] == true) {
            equippedSkin = skinId;
          }
        }
      }

      if (ownedSkins.isNotEmpty) {
        safePrint('🔄 ✈️ Restoring ${ownedSkins.length} owned skins');
        await inventoryManager.restoreOwnedSkins(ownedSkins);
        
        if (equippedSkin != null) {
          safePrint('🔄 ✈️ Restoring equipped skin: $equippedSkin');
          await inventoryManager.equipSkin(equippedSkin);
        }
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
      
      // Use best_streak as current streak (we should add current_streak to backend later)
      final currentStreak = profileData['best_streak'] ?? 0;
      
      if (currentStreak > 0) {
        safePrint('🔄 🔥 Restoring daily streak: $currentStreak days');
        await dailyStreakManager.restoreStreak(currentStreak);
      }

      safePrint('🔄 ✅ DailyStreakManager state restored successfully');
    } catch (e) {
      safePrint('🔄 ❌ Error restoring DailyStreakManager: $e');
    }
  }

  /// Restore LivesManager state from backend data
  Future<void> _restoreLivesManager(Map<String, dynamic> profileData) async {
    try {
      final livesManager = LivesManager();
      
      final currentHearts = profileData['current_hearts'] ?? 3;
      safePrint('🔄 💖 Restoring hearts: $currentHearts');
      
      // Set hearts directly (LivesManager should have a restore method)
      await livesManager.restoreHearts(currentHearts);

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

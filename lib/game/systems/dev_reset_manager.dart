/// 🔧 Development Reset Manager - Reset to true new player state
library;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'lives_manager.dart';
import 'player_identity_manager.dart';
import 'ftue_manager.dart';
import 'daily_streak_manager.dart';
import '../../core/debug_logger.dart';

class DevResetManager {
  /// Reset all player data to simulate fresh app install
  static Future<void> resetToNewPlayerState() async {
    safePrint('🔧 🚨 RESET FUNCTION CALLED - Starting reset process...');
    
    if (!kDebugMode) {
      safePrint('🔧 Reset only available in debug mode');
      return;
    }

    safePrint('🔧 Resetting to new player state...');
    
    final prefs = await SharedPreferences.getInstance();
    
    // Clear ALL player identity data (multiple systems use different keys)
    await prefs.remove('unified_player_name');
    await prefs.remove('unified_player_id');
    
    // Clear profile data (ProfileManager)
    safePrint('🔧 Clearing profile_nickname: ${prefs.getString('profile_nickname')}');
    await prefs.remove('profile_nickname');
    await prefs.remove('pf_nickname'); // Old ProfileManager key
    
    // Clear leaderboard data (LeaderboardManager)
    await prefs.remove('leaderboard_local_scores');
    await prefs.remove('leaderboard_player_name');
    await prefs.remove('player_name'); // LeaderboardManager key
    await prefs.remove('best_score');
    await prefs.remove('best_streak');
    
    // Clear global leaderboard data (GlobalLeaderboardService)
    await prefs.remove('global_leaderboard_player_id');
    await prefs.remove('global_leaderboard_player_name');
    await prefs.remove('global_player_name'); // GlobalLeaderboardService key
    
    // Clear inventory data (InventoryManager)
    await prefs.remove('inv_owned_skins');
    await prefs.remove('inv_equipped_skin');
    await prefs.remove('inv_soft_currency');
    await prefs.remove('inv_gems');
    await prefs.remove('inv_heart_booster_expiry');
    
    // Clear lives data (LivesManager) - use correct keys
    await prefs.remove('lm_lives');
    await prefs.remove('lm_next_regen_at_ms');
    await prefs.remove('lm_best_score');
    await prefs.remove('lm_best_streak');
    await prefs.remove('lives_current'); // Legacy key
    await prefs.remove('lives_last_lost_time'); // Legacy key
    
    // Clear Railway server data
    await prefs.remove('railway_auth_token');
    await prefs.remove('railway_player_id');
    await prefs.remove('railway_device_id');
    await prefs.remove('railway_last_sync');
    
    // Clear any other game data
    await prefs.remove('first_time_setup_complete');
    
    // Clear FTUE data (First Time User Experience)
    await prefs.remove('ftue_is_first_session');
    await prefs.remove('ftue_games_played');
    await prefs.remove('ftue_popup1_shown');
    await prefs.remove('ftue_popup2_shown');
    
    // Clear daily streak data
    await prefs.remove('daily_streak_current');
    await prefs.remove('daily_streak_last_claim');
    await prefs.remove('daily_streak_claimed_today');
    await prefs.remove('daily_streak_start_date');
    await prefs.remove('daily_streak_total_completed');
    
    // Clear ALL keys that might contain player data (comprehensive cleanup)
    final allKeys = prefs.getKeys();
    for (final key in allKeys) {
      if (key.contains('player') || 
          key.contains('nickname') || 
          key.contains('name') ||
          key.contains('score') ||
          key.contains('streak') ||
          key.contains('leaderboard') ||
          key.contains('global')) {
        await prefs.remove(key);
        safePrint('🔧 Cleared key: $key');
      }
    }
    
    // Force re-initialize all managers with fresh data
    try {
      // Reset PlayerIdentityManager to generate new name
      final playerIdentity = PlayerIdentityManager();
      await playerIdentity.forceResetToNewPlayer();
      
      // Reset LivesManager to 3 hearts (new player default)
      final livesManager = LivesManager();
      await livesManager.forceResetToNewPlayer();
      
      // Reset FTUE Manager to new player state
      final ftueManager = FTUEManager();
      await ftueManager.resetFTUE();
      
      // Reset Daily Streak Manager
      final dailyStreakManager = DailyStreakManager();
      await dailyStreakManager.resetAllData();
      
      safePrint('🔧 ✅ Reset complete - All systems reset to new player state');
      safePrint('🔧 🎮 FTUE will trigger after first two games');
      safePrint('🔧 New player will have: 3 hearts, 500 coins, 25 gems, ${playerIdentity.playerName}');
    } catch (e) {
      safePrint('🔧 ⚠️ Error during manager reset: $e');
      safePrint('🔧 ✅ SharedPreferences cleared - Restart app for full reset');
    }
  }
  
  /// Check if this is a truly new player (no data exists)
  static Future<bool> isNewPlayer() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check key indicators of existing player data
    final hasPlayerName = prefs.getString('unified_player_name') != null;
    final hasPlayerId = prefs.getString('unified_player_id') != null;
    final hasScore = prefs.getInt('best_score') != null;
    final hasCoins = prefs.getInt('inv_soft_currency') != null;
    
    // If any of these exist, not a new player
    return !(hasPlayerName || hasPlayerId || hasScore || hasCoins);
  }
  
  /// Mark first-time setup as complete
  static Future<void> markSetupComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_time_setup_complete', true);
    safePrint('🎯 First-time setup marked as complete');
  }
  
  /// Check if first-time setup is complete
  static Future<bool> isSetupComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('first_time_setup_complete') ?? false;
  }
}
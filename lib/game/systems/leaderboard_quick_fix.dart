/// 🔧 Quick Fix for Leaderboard Display Issues
library;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class LeaderboardQuickFix {
  static const String _targetPlayerName = 'Erezos';
  
  /// Apply immediate fixes to leaderboard data
  static Future<void> applyFixes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. Force set the correct player name in all storage locations
      await prefs.setString('profile_nickname', _targetPlayerName);
      await prefs.setString('player_name', _targetPlayerName);
      await prefs.setString('global_player_name', _targetPlayerName);
      await prefs.setString('unified_player_name', _targetPlayerName);
      
      // 2. Clear and reset leaderboard data with correct name
      await _fixLocalLeaderboard(prefs);
      await _fixGlobalLeaderboard(prefs);
      
      debugPrint('🔧 LeaderboardQuickFix applied successfully');
    } catch (e) {
      debugPrint('⚠️ LeaderboardQuickFix failed: $e');
    }
  }
  
  static Future<void> _fixLocalLeaderboard(SharedPreferences prefs) async {
    // Clear existing local scores to force regeneration with correct name
    await prefs.remove('local_high_scores');
    debugPrint('🔧 Cleared local leaderboard data');
  }
  
  static Future<void> _fixGlobalLeaderboard(SharedPreferences prefs) async {
    // Reset global leaderboard player data
    await prefs.remove('global_player_id');
    await prefs.setString('global_player_name', _targetPlayerName);
    debugPrint('🔧 Fixed global leaderboard player name');
  }
}

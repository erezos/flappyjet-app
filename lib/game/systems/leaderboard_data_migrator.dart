/// 🔧 Leaderboard Data Migrator - Fixes corrupted leaderboard data
library;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'leaderboard_manager.dart';

/// Utility to migrate and fix corrupted leaderboard data
class LeaderboardDataMigrator {
  static const String _migrationVersionKey = 'leaderboard_migration_version';
  static const int _currentMigrationVersion = 1;

  /// Run all necessary data migrations
  static Future<void> migrate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentVersion = prefs.getInt(_migrationVersionKey) ?? 0;
      
      if (currentVersion < _currentMigrationVersion) {
        debugPrint('🔧 Running leaderboard data migration...');
        
        // Migration v1: Fix corrupted entries and ranks
        if (currentVersion < 1) {
          await _migrationV1_FixCorruptedEntries(prefs);
        }
        
        // Mark migration as complete
        await prefs.setInt(_migrationVersionKey, _currentMigrationVersion);
        debugPrint('🔧 Leaderboard migration completed');
      }
    } catch (e) {
      debugPrint('⚠️ Leaderboard migration failed: $e');
    }
  }

  /// Migration V1: Fix corrupted entries with missing ranks and "You" names
  static Future<void> _migrationV1_FixCorruptedEntries(SharedPreferences prefs) async {
    try {
      final scoresJson = prefs.getString('local_high_scores');
      if (scoresJson == null) return;

      final scoresList = jsonDecode(scoresJson) as List;
      final entries = scoresList
          .map((json) => LeaderboardEntry.fromJson(json))
          .toList();

      // Get the unified player name
      final unifiedPlayerName = prefs.getString('unified_player_name') ?? 'You';
      
      bool hasChanges = false;
      
      // Fix entries with "You" or empty names
      for (int i = 0; i < entries.length; i++) {
        if (entries[i].playerName == 'You' || 
            entries[i].playerName.isEmpty || 
            entries[i].playerName == 'Anonymous') {
          entries[i] = LeaderboardEntry(
            playerName: unifiedPlayerName,
            score: entries[i].score,
            achievedAt: entries[i].achievedAt,
            theme: entries[i].theme,
            rank: entries[i].rank,
          );
          hasChanges = true;
        }
      }

      // Sort and re-rank all entries
      entries.sort((a, b) => b.score.compareTo(a.score));
      for (int i = 0; i < entries.length; i++) {
        entries[i] = LeaderboardEntry(
          playerName: entries[i].playerName,
          score: entries[i].score,
          achievedAt: entries[i].achievedAt,
          theme: entries[i].theme,
          rank: i + 1,
        );
      }
      hasChanges = true;

      if (hasChanges) {
        // Save the fixed data
        final fixedJson = jsonEncode(entries.map((e) => e.toJson()).toList());
        await prefs.setString('local_high_scores', fixedJson);
        debugPrint('🔧 Fixed ${entries.length} leaderboard entries');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to fix corrupted entries: $e');
    }
  }
}

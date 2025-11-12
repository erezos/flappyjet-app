/// 🏆 Leaderboard Repository - Local leaderboard data management
/// 
/// Manages local storage and caching of leaderboard data for the hybrid
/// leaderboard system. Provides instant access to leaderboard data even
/// when offline, with background synchronization to global leaderboards.
library;

import 'package:sqflite/sqflite.dart';
import '../debug_logger.dart';
import '../database/local_database_manager.dart';

/// Leaderboard entry model
class LeaderboardEntry {
  final int rank;
  final String userId;
  final String? nickname;
  final int score;
  final String? jetSkin;
  final String? theme;
  final DateTime timestamp;
  final DateTime cachedAt;

  LeaderboardEntry({
    required this.rank,
    required this.userId,
    this.nickname,
    required this.score,
    this.jetSkin,
    this.theme,
    required this.timestamp,
    required this.cachedAt,
  });

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) {
    return LeaderboardEntry(
      rank: map['rank'] as int,
      userId: map['user_id'] as String,
      nickname: map['nickname'] as String?,
      score: map['score'] as int,
      jetSkin: map['jet_skin'] as String?,
      theme: map['theme'] as String?,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      cachedAt: DateTime.fromMillisecondsSinceEpoch(map['cached_at'] as int),
    );
  }

  Map<String, dynamic> toMap(String leaderboardType) {
    return {
      'leaderboard_type': leaderboardType,
      'rank': rank,
      'user_id': userId,
      'nickname': nickname,
      'score': score,
      'jet_skin': jetSkin,
      'theme': theme,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'cached_at': cachedAt.millisecondsSinceEpoch,
    };
  }

  @override
  String toString() => 'LeaderboardEntry(rank: $rank, userId: ${userId.substring(0, 8)}..., nickname: $nickname, score: $score)';
}

/// Tournament leaderboard entry model
class TournamentEntry {
  final String tournamentId;
  final int rank;
  final String userId;
  final String? nickname;
  final int score;
  final DateTime timestamp;
  final DateTime cachedAt;

  TournamentEntry({
    required this.tournamentId,
    required this.rank,
    required this.userId,
    this.nickname,
    required this.score,
    required this.timestamp,
    required this.cachedAt,
  });

  factory TournamentEntry.fromMap(Map<String, dynamic> map) {
    return TournamentEntry(
      tournamentId: map['tournament_id'] as String,
      rank: map['rank'] as int,
      userId: map['user_id'] as String,
      nickname: map['nickname'] as String?,
      score: map['score'] as int,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      cachedAt: DateTime.fromMillisecondsSinceEpoch(map['cached_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tournament_id': tournamentId,
      'rank': rank,
      'user_id': userId,
      'nickname': nickname,
      'score': score,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'cached_at': cachedAt.millisecondsSinceEpoch,
    };
  }
}

/// Leaderboard repository for managing local leaderboard data
class LeaderboardRepository {
  final LocalDatabaseManager _db;

  LeaderboardRepository(this._db);

  // ===== GLOBAL LEADERBOARD =====

  /// Get cached global leaderboard
  Future<List<LeaderboardEntry>> getGlobalLeaderboard({int limit = 100}) async {
    try {
      final db = _db.database;
      final results = await db.query(
        'leaderboard_cache',
        where: 'leaderboard_type = ?',
        whereArgs: ['global'],
        orderBy: 'score DESC',
        limit: limit,
      );

      return results.map((map) => LeaderboardEntry.fromMap(map)).toList();
    } catch (e) {
      safePrint('❌ Error getting global leaderboard: $e');
      return [];
    }
  }

  /// Update global leaderboard cache
  Future<void> updateGlobalCache(List<LeaderboardEntry> entries) async {
    try {
      final db = _db.database;
      final batch = db.batch();

      // Clear old global entries
      batch.delete('leaderboard_cache', where: 'leaderboard_type = ?', whereArgs: ['global']);

      // Insert new entries
      for (final entry in entries) {
        batch.insert(
          'leaderboard_cache',
          entry.toMap('global'),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);
      safePrint('🏆 ✅ Global leaderboard cache updated: ${entries.length} entries');
    } catch (e) {
      safePrint('❌ Error updating global cache: $e');
    }
  }

  /// Get user's global rank
  Future<int?> getUserGlobalRank(String userId) async {
    try {
      final db = _db.database;
      final result = await db.query(
        'leaderboard_cache',
        columns: ['rank'],
        where: 'leaderboard_type = ? AND user_id = ?',
        whereArgs: ['global', userId],
        limit: 1,
      );

      if (result.isEmpty) return null;
      return result.first['rank'] as int;
    } catch (e) {
      safePrint('❌ Error getting user rank: $e');
      return null;
    }
  }

  // ===== WEEKLY TOURNAMENT LEADERBOARD =====

  /// Get cached weekly tournament leaderboard
  Future<List<TournamentEntry>> getWeeklyLeaderboard(String tournamentId, {int limit = 100}) async {
    try {
      final db = _db.database;
      final results = await db.query(
        'tournament_leaderboard_cache',
        where: 'tournament_id = ?',
        whereArgs: [tournamentId],
        orderBy: 'score DESC',
        limit: limit,
      );

      return results.map((map) => TournamentEntry.fromMap(map)).toList();
    } catch (e) {
      safePrint('❌ Error getting tournament leaderboard: $e');
      return [];
    }
  }

  /// Update weekly tournament leaderboard cache
  Future<void> updateWeeklyCache(String tournamentId, List<TournamentEntry> entries) async {
    try {
      final db = _db.database;
      final batch = db.batch();

      // Clear old tournament entries
      batch.delete('tournament_leaderboard_cache', where: 'tournament_id = ?', whereArgs: [tournamentId]);

      // Insert new entries
      for (final entry in entries) {
        batch.insert(
          'tournament_leaderboard_cache',
          entry.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);
      safePrint('🏆 ✅ Tournament leaderboard cache updated: ${entries.length} entries');
    } catch (e) {
      safePrint('❌ Error updating tournament cache: $e');
    }
  }

  /// Get user's tournament rank
  Future<int?> getUserTournamentRank(String tournamentId, String userId) async {
    try {
      final db = _db.database;
      final result = await db.query(
        'tournament_leaderboard_cache',
        columns: ['rank'],
        where: 'tournament_id = ? AND user_id = ?',
        whereArgs: [tournamentId, userId],
        limit: 1,
      );

      if (result.isEmpty) return null;
      return result.first['rank'] as int;
    } catch (e) {
      safePrint('❌ Error getting user tournament rank: $e');
      return null;
    }
  }

  // ===== CACHE MANAGEMENT =====

  /// Get cache age for global leaderboard
  Future<Duration?> getGlobalCacheAge() async {
    try {
      final db = _db.database;
      final result = await db.query(
        'leaderboard_cache',
        columns: ['MAX(cached_at) as latest'],
        where: 'leaderboard_type = ?',
        whereArgs: ['global'],
        limit: 1,
      );

      if (result.isEmpty || result.first['latest'] == null) return null;
      
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(result.first['latest'] as int);
      return DateTime.now().difference(cachedAt);
    } catch (e) {
      safePrint('❌ Error getting cache age: $e');
      return null;
    }
  }

  /// Get cache age for tournament leaderboard
  Future<Duration?> getTournamentCacheAge(String tournamentId) async {
    try {
      final db = _db.database;
      final result = await db.query(
        'tournament_leaderboard_cache',
        columns: ['MAX(cached_at) as latest'],
        where: 'tournament_id = ?',
        whereArgs: [tournamentId],
        limit: 1,
      );

      if (result.isEmpty || result.first['latest'] == null) return null;
      
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(result.first['latest'] as int);
      return DateTime.now().difference(cachedAt);
    } catch (e) {
      safePrint('❌ Error getting tournament cache age: $e');
      return null;
    }
  }

  /// Clear old cache entries (older than 1 hour)
  Future<void> clearOldCache() async {
    try {
      final db = _db.database;
      final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1)).millisecondsSinceEpoch;

      final globalDeleted = await db.delete(
        'leaderboard_cache',
        where: 'cached_at < ?',
        whereArgs: [oneHourAgo],
      );

      final tournamentDeleted = await db.delete(
        'tournament_leaderboard_cache',
        where: 'cached_at < ?',
        whereArgs: [oneHourAgo],
      );

      if (globalDeleted > 0 || tournamentDeleted > 0) {
        safePrint('🏆 🗑️ Cleared old cache: $globalDeleted global, $tournamentDeleted tournament entries');
      }
    } catch (e) {
      safePrint('❌ Error clearing old cache: $e');
    }
  }

  /// Clear all leaderboard cache
  Future<void> clearAllCache() async {
    try {
      final db = _db.database;
      await db.delete('leaderboard_cache');
      await db.delete('tournament_leaderboard_cache');
      safePrint('🏆 🗑️ All leaderboard cache cleared');
    } catch (e) {
      safePrint('❌ Error clearing cache: $e');
    }
  }

  // ===== LOCAL SCORE TRACKING =====

  /// Add user's local score to games history
  Future<void> addLocalScore({
    required String userId,
    required int score,
    required String gameMode,
    String? levelId,
    int? survivalTimeSeconds,
    int? obstaclesPassed,
    int? coinsCollected,
    int? gemsCollected,
    String? jetUsed,
    String? themeUsed,
    int? continuesUsed,
  }) async {
    try {
      final db = _db.database;
      await db.insert('games_history', {
        'game_mode': gameMode,
        'level_id': levelId,
        'score': score,
        'survival_time_seconds': survivalTimeSeconds,
        'obstacles_passed': obstaclesPassed,
        'coins_collected': coinsCollected,
        'gems_collected': gemsCollected,
        'jet_used': jetUsed,
        'theme_used': themeUsed,
        'continues_used': continuesUsed,
        'played_at': DateTime.now().millisecondsSinceEpoch,
      });

      safePrint('🏆 ✅ Local score added: $score in $gameMode mode');
    } catch (e) {
      safePrint('❌ Error adding local score: $e');
    }
  }

  /// Get user's recent scores
  Future<List<Map<String, dynamic>>> getUserRecentScores({int limit = 10}) async {
    try {
      final db = _db.database;
      final results = await db.query(
        'games_history',
        orderBy: 'played_at DESC',
        limit: limit,
      );

      return results;
    } catch (e) {
      safePrint('❌ Error getting recent scores: $e');
      return [];
    }
  }

  /// Get user's best score in a game mode
  Future<int?> getUserBestScore(String gameMode) async {
    try {
      final db = _db.database;
      final result = await db.query(
        'games_history',
        columns: ['MAX(score) as best_score'],
        where: 'game_mode = ?',
        whereArgs: [gameMode],
        limit: 1,
      );

      if (result.isEmpty || result.first['best_score'] == null) return null;
      return result.first['best_score'] as int;
    } catch (e) {
      safePrint('❌ Error getting best score: $e');
      return null;
    }
  }
}


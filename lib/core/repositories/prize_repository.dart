/// Repository for managing prizes in the local SQLite database
/// Handles pending and claimed prizes
library;

import 'package:sqflite/sqflite.dart';
import '../database/local_database_manager.dart';
import '../../models/pending_prize.dart';
import '../debug_logger.dart';

class PrizeRepository {
  final LocalDatabaseManager _db;

  PrizeRepository(this._db);

  /// Get the database instance
  Database get _database => _db.database;

  // ============================================================================
  // PENDING PRIZES (Unclaimed)
  // ============================================================================

  /// Get all unclaimed prizes
  Future<List<PendingPrize>> getUnclaimedPrizes() async {
    try {
      final result = await _database.query(
        'pending_prizes',
        where: 'claimed_at IS NULL',
        orderBy: 'awarded_at DESC',
      );

      return result.map((map) => PendingPrize.fromDb(map)).toList();
    } catch (e) {
      safePrint('❌ Error getting unclaimed prizes: $e');
      return [];
    }
  }

  /// Get a specific prize by ID
  Future<PendingPrize?> getPrizeById(String prizeId) async {
    try {
      final result = await _database.query(
        'pending_prizes',
        where: 'prize_id = ?',
        whereArgs: [prizeId],
        limit: 1,
      );

      if (result.isEmpty) return null;
      return PendingPrize.fromDb(result.first);
    } catch (e) {
      safePrint('❌ Error getting prize $prizeId: $e');
      return null;
    }
  }

  /// Save or update a prize
  Future<void> savePrize(PendingPrize prize) async {
    try {
      await _database.insert(
        'pending_prizes',
        prize.toDb(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      safePrint('💾 Saved prize: ${prize.prizeId}');
    } catch (e) {
      safePrint('❌ Error saving prize: $e');
    }
  }

  /// Save multiple prizes at once
  Future<void> savePrizes(List<PendingPrize> prizes) async {
    if (prizes.isEmpty) return;

    try {
      final batch = _database.batch();
      for (final prize in prizes) {
        batch.insert(
          'pending_prizes',
          prize.toDb(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
      safePrint('💾 Saved ${prizes.length} prizes');
    } catch (e) {
      safePrint('❌ Error saving prizes: $e');
    }
  }

  /// Mark a prize as claimed
  Future<void> markPrizeClaimed(String prizeId, DateTime claimedAt) async {
    try {
      await _database.update(
        'pending_prizes',
        {'claimed_at': claimedAt.millisecondsSinceEpoch},
        where: 'prize_id = ?',
        whereArgs: [prizeId],
      );
      safePrint('✅ Marked prize $prizeId as claimed');
    } catch (e) {
      safePrint('❌ Error marking prize as claimed: $e');
    }
  }

  /// Delete a prize (usually after claiming and backend confirmation)
  Future<void> deletePrize(String prizeId) async {
    try {
      await _database.delete(
        'pending_prizes',
        where: 'prize_id = ?',
        whereArgs: [prizeId],
      );
      safePrint('🗑️ Deleted prize $prizeId');
    } catch (e) {
      safePrint('❌ Error deleting prize: $e');
    }
  }

  /// Delete all claimed prizes older than X days (cleanup)
  Future<void> deleteOldClaimedPrizes({int daysOld = 30}) async {
    try {
      final cutoffDate = DateTime.now()
          .subtract(Duration(days: daysOld))
          .millisecondsSinceEpoch;

      final count = await _database.delete(
        'pending_prizes',
        where: 'claimed_at IS NOT NULL AND claimed_at < ?',
        whereArgs: [cutoffDate],
      );

      safePrint('🗑️ Deleted $count old claimed prizes');
    } catch (e) {
      safePrint('❌ Error deleting old prizes: $e');
    }
  }

  // ============================================================================
  // STATISTICS
  // ============================================================================

  /// Get count of unclaimed prizes
  Future<int> getUnclaimedPrizeCount() async {
    try {
      final result = await _database.rawQuery(
        'SELECT COUNT(*) as count FROM pending_prizes WHERE claimed_at IS NULL',
      );
      return (result.first['count'] as int?) ?? 0;
    } catch (e) {
      safePrint('❌ Error counting unclaimed prizes: $e');
      return 0;
    }
  }

  /// Get total coins from unclaimed prizes
  Future<int> getUnclaimedCoins() async {
    try {
      final result = await _database.rawQuery(
        'SELECT SUM(coins) as total FROM pending_prizes WHERE claimed_at IS NULL',
      );
      return (result.first['total'] as int?) ?? 0;
    } catch (e) {
      safePrint('❌ Error calculating unclaimed coins: $e');
      return 0;
    }
  }

  /// Get total gems from unclaimed prizes
  Future<int> getUnclaimedGems() async {
    try {
      final result = await _database.rawQuery(
        'SELECT SUM(gems) as total FROM pending_prizes WHERE claimed_at IS NULL',
      );
      return (result.first['total'] as int?) ?? 0;
    } catch (e) {
      safePrint('❌ Error calculating unclaimed gems: $e');
      return 0;
    }
  }

  // ============================================================================
  // CLEANUP
  // ============================================================================

  /// Clear all prizes (for testing/reset)
  Future<void> clearAllPrizes() async {
    try {
      await _database.delete('pending_prizes');
      safePrint('🗑️ Cleared all prizes');
    } catch (e) {
      safePrint('❌ Error clearing prizes: $e');
    }
  }
}


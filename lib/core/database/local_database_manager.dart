/// 🗄️ Local Database Manager - Central database access layer
/// 
/// Manages SQLite database connection and provides high-level data access
/// All game data is stored locally for offline-first experience
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import '../debug_logger.dart';
import 'database_schema.dart';

/// Local database manager for all game data storage
class LocalDatabaseManager extends ChangeNotifier {
  static final LocalDatabaseManager _instance = LocalDatabaseManager._internal();
  factory LocalDatabaseManager() => _instance;
  LocalDatabaseManager._internal();

  Database? _db;
  bool _isInitialized = false;
  bool _isInitializing = false;

  /// Get database instance
  Database get database {
    if (_db == null) {
      throw StateError('Database not initialized. Call initialize() first.');
    }
    return _db!;
  }

  /// Check if database is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize database
  Future<void> initialize() async {
    if (_isInitialized) {
      safePrint('🗄️ Database already initialized');
      return;
    }

    if (_isInitializing) {
      safePrint('🗄️ Database initialization already in progress');
      // Wait for initialization to complete
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return;
    }

    _isInitializing = true;

    try {
      safePrint('🗄️ Initializing local database...');

      final dbPath = await getDatabasesPath();
      final dbFilePath = path.join(dbPath, DatabaseSchema.databaseName);

      _db = await openDatabase(
        dbFilePath,
        version: DatabaseSchema.databaseVersion,
        onCreate: (db, version) async {
          safePrint('🗄️ Creating new database v$version');
          await DatabaseSchema.createTables(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          safePrint('🗄️ Upgrading database from v$oldVersion to v$newVersion');
          await DatabaseSchema.upgradeTables(db, oldVersion, newVersion);
        },
        onOpen: (db) async {
          safePrint('🗄️ Database opened successfully');
        },
      );

      _isInitialized = true;
      _isInitializing = false;

      safePrint('🗄️ ✅ Local database initialized');

      // Initialize user_stats row if it doesn't exist
      await _ensureUserStatsExists();

      // Initialize level_progress row if it doesn't exist
      await _ensureLevelProgressExists();

      // Log table sizes
      if (kDebugMode) {
        final sizes = await DatabaseSchema.getTableSizes(_db!);
        safePrint('🗄️ Table sizes: $sizes');
      }

      notifyListeners();

    } catch (e, stackTrace) {
      safePrint('🗄️ ❌ Failed to initialize database: $e');
      safePrint('Stack trace: $stackTrace');
      _isInitializing = false;
      rethrow;
    }
  }

  /// Ensure user_stats table has exactly one row
  Future<void> _ensureUserStatsExists() async {
    final result = await _db!.query('user_stats', limit: 1);
    
    if (result.isEmpty) {
      safePrint('🗄️ Creating initial user_stats row');
      final now = DateTime.now().millisecondsSinceEpoch;
      await _db!.insert('user_stats', {
        'id': 1,
        'user_id': '', // Will be set by migration or initialization
        'coins': 500,
        'gems': 25,
        'hearts': 3,
        'high_score': 0,
        'best_streak': 0,
        'total_games_played': 0,
        'total_score': 0,
        'created_at': now,
        'updated_at': now,
      });
      safePrint('🗄️ ✅ Initial user_stats row created');
    }
  }

  /// Ensure level_progress table has exactly one row
  Future<void> _ensureLevelProgressExists() async {
    final result = await _db!.query('level_progress', limit: 1);
    
    if (result.isEmpty) {
      safePrint('🗄️ Creating initial level_progress row');
      final now = DateTime.now().millisecondsSinceEpoch;
      await _db!.insert('level_progress', {
        'id': 1,
        'user_id': '', // Will be set by migration or initialization
        'current_level': 1,
        'highest_unlocked': 1,
        'completed_levels': '[]',
        'current_zone': 1,
        'completed_zones': '[]',
        'first_attempt_completed': '[]',
        'created_at': now,
        'updated_at': now,
      });
      safePrint('🗄️ ✅ Initial level_progress row created');
    }
  }

  /// Close database
  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
      _isInitialized = false;
      safePrint('🗄️ Database closed');
    }
  }

  /// Clear all data (for testing/reset)
  Future<void> clearAllData() async {
    if (!kDebugMode) {
      safePrint('🗄️ ⚠️ clearAllData only allowed in debug mode');
      return;
    }

    safePrint('🗄️ ⚠️ Clearing all database data...');

    final tables = [
      'inventory',
      'games_history',
      'story_progress',
      'level_progress',
      'missions',
      'achievements',
      'leaderboard_cache',
      'tournament_cache',
      'tournament_leaderboard_cache',
      'settings',
      'sync_queue',
    ];

    final batch = _db!.batch();
    for (final table in tables) {
      batch.delete(table);
    }

    // Reset user_stats to default
    batch.update('user_stats', {
      'coins': 500,
      'gems': 25,
      'hearts': 3,
      'high_score': 0,
      'best_streak': 0,
      'total_games_played': 0,
      'total_score': 0,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, where: 'id = 1');

    // Reset level_progress to default
    batch.update('level_progress', {
      'current_level': 1,
      'highest_unlocked': 1,
      'completed_levels': '[]',
      'current_zone': 1,
      'completed_zones': '[]',
      'first_attempt_completed': '[]',
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, where: 'id = 1');

    await batch.commit(noResult: true);

    safePrint('🗄️ ✅ All data cleared');
    notifyListeners();
  }

  /// Get database file size
  Future<int> getDatabaseSize() async {
    if (_db == null) return 0;

    try {
      // Estimate database size by row counts
      // (dbFilePath would be needed for actual file size on device)
      final sizes = await DatabaseSchema.getTableSizes(_db!);
      final totalRows = sizes.values.reduce((a, b) => a + b);
      
      // Rough estimate: 100 bytes per row
      return totalRows * 100;
    } catch (e) {
      safePrint('🗄️ ⚠️ Failed to get database size: $e');
      return 0;
    }
  }

  /// Vacuum database (reclaim space)
  Future<void> vacuum() async {
    safePrint('🗄️ Vacuuming database...');
    await _db!.execute('VACUUM');
    safePrint('🗄️ ✅ Database vacuumed');
  }

  /// Run a transaction
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    return await _db!.transaction(action);
  }

  /// Get table row counts
  Future<Map<String, int>> getTableSizes() async {
    return await DatabaseSchema.getTableSizes(_db!);
  }

  /// Export database for debugging
  Future<Map<String, dynamic>> exportDatabaseInfo() async {
    final sizes = await getTableSizes();
    final dbSize = await getDatabaseSize();

    return {
      'databaseName': DatabaseSchema.databaseName,
      'databaseVersion': DatabaseSchema.databaseVersion,
      'isInitialized': _isInitialized,
      'tableSizes': sizes,
      'estimatedSizeBytes': dbSize,
      'estimatedSizeMB': (dbSize / 1024 / 1024).toStringAsFixed(2),
    };
  }
}


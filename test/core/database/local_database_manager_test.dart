/// Unit tests for LocalDatabaseManager and DatabaseSchema
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flappy_jet_pro/core/database/local_database_manager.dart';
import 'package:flappy_jet_pro/core/database/database_schema.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Initialize FFI for SQLite testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('DatabaseSchema', () {
    late Database db;

    setUp(() async {
      // Create in-memory database for testing
      db = await databaseFactory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await DatabaseSchema.createTables(db);
          },
        ),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('should create all required tables', () async {
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
      );

      final tableNames = tables.map((t) => t['name'] as String).toList();

      expect(tableNames, contains('user_stats'));
      expect(tableNames, contains('inventory'));
      expect(tableNames, contains('games_history'));
      expect(tableNames, contains('story_progress'));
      expect(tableNames, contains('missions'));
      expect(tableNames, contains('achievements'));
      expect(tableNames, contains('leaderboard_cache'));
      expect(tableNames, contains('tournament_cache'));
      expect(tableNames, contains('tournament_leaderboard_cache'));
      expect(tableNames, contains('settings'));
      expect(tableNames, contains('sync_queue'));
    });

    test('should create all required indexes', () async {
      final indexes = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND name NOT LIKE 'sqlite_%'"
      );

      final indexNames = indexes.map((i) => i['name'] as String).toList();

      expect(indexNames, contains('idx_games_played_at'));
      expect(indexNames, contains('idx_games_score'));
      expect(indexNames, contains('idx_story_zone'));
      expect(indexNames, contains('idx_missions_status'));
      expect(indexNames, contains('idx_leaderboard_score'));
      expect(indexNames, contains('idx_tournament_leaderboard'));
      expect(indexNames, contains('idx_sync_priority'));
    });

    test('user_stats table should have correct schema', () async {
      final columns = await db.rawQuery('PRAGMA table_info(user_stats)');
      final columnNames = columns.map((c) => c['name'] as String).toList();

      expect(columnNames, contains('id'));
      expect(columnNames, contains('user_id'));
      expect(columnNames, contains('nickname'));
      expect(columnNames, contains('high_score'));
      expect(columnNames, contains('best_streak'));
      expect(columnNames, contains('total_games_played'));
      expect(columnNames, contains('total_score'));
      expect(columnNames, contains('coins'));
      expect(columnNames, contains('gems'));
      expect(columnNames, contains('hearts'));
      expect(columnNames, contains('last_heart_regen'));
      expect(columnNames, contains('created_at'));
      expect(columnNames, contains('updated_at'));
    });

    test('inventory table should have correct schema', () async {
      final columns = await db.rawQuery('PRAGMA table_info(inventory)');
      final columnNames = columns.map((c) => c['name'] as String).toList();

      expect(columnNames, contains('id'));
      expect(columnNames, contains('item_type'));
      expect(columnNames, contains('item_id'));
      expect(columnNames, contains('quantity'));
      expect(columnNames, contains('is_equipped'));
      expect(columnNames, contains('unlocked_at'));
    });

    test('should get table sizes', () async {
      final sizes = await DatabaseSchema.getTableSizes(db);

      expect(sizes, isA<Map<String, int>>());
      expect(sizes.keys, contains('user_stats'));
      expect(sizes.keys, contains('inventory'));
      expect(sizes.keys, contains('games_history'));
    });

    test('should have table definitions for documentation', () {
      final definitions = DatabaseSchema.getTableDefinitions();

      expect(definitions, isA<Map<String, String>>());
      expect(definitions.keys, contains('user_stats'));
      expect(definitions.keys, contains('inventory'));
      expect(definitions['user_stats'], isNotEmpty);
    });
  });

  group('LocalDatabaseManager', () {
    late LocalDatabaseManager dbManager;

    setUp(() async {
      dbManager = LocalDatabaseManager();
      await dbManager.initialize();
    });

    tearDown(() async {
      await dbManager.close();
    });

    group('Initialization', () {
      test('should initialize successfully', () {
        expect(dbManager.isInitialized, isTrue);
        expect(dbManager.database, isNotNull);
      });

      test('should not reinitialize if already initialized', () async {
        final wasInitialized = dbManager.isInitialized;
        await dbManager.initialize();
        expect(dbManager.isInitialized, equals(wasInitialized));
      });

      test('should create user_stats row on initialization', () async {
        final result = await dbManager.database.query('user_stats');
        expect(result, hasLength(1));
        expect(result.first['id'], equals(1));
        expect(result.first['coins'], equals(500));
        expect(result.first['gems'], equals(25));
        expect(result.first['hearts'], equals(3));
      });
    });

    group('Database Operations', () {
      test('should get table sizes', () async {
        final sizes = await dbManager.getTableSizes();

        expect(sizes, isA<Map<String, int>>());
        expect(sizes['user_stats'], equals(1)); // Always has 1 row
      });

      test('should export database info', () async {
        final info = await dbManager.exportDatabaseInfo();

        expect(info, isA<Map<String, dynamic>>());
        expect(info['databaseName'], equals('flappyjet.db'));
        expect(info['databaseVersion'], equals(1));
        expect(info['isInitialized'], isTrue);
        expect(info['tableSizes'], isA<Map>());
      });

      test('should support transactions', () async {
        final result = await dbManager.transaction((txn) async {
          await txn.insert('inventory', {
            'id': 'test_item_1',
            'item_type': 'jet',
            'item_id': 'test_jet',
            'quantity': 1,
            'is_equipped': 0,
            'unlocked_at': DateTime.now().millisecondsSinceEpoch,
          });

          final items = await txn.query('inventory');
          return items.length;
        });

        expect(result, equals(1));
      });

      test('should vacuum database', () async {
        await dbManager.vacuum();
        // Vacuum should complete without error
        expect(dbManager.isInitialized, isTrue);
      });
    });

    group('Data Management', () {
      test('should clear all data in debug mode', () async {
        // Add some test data (but avoid duplicate due to previous test)
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        await dbManager.database.insert('inventory', {
          'id': 'test_item_clear_$timestamp',
          'item_type': 'jet',
          'item_id': 'test_jet_clear_$timestamp',
          'quantity': 1,
          'is_equipped': 0,
          'unlocked_at': timestamp,
        });

        // Verify data was added
        var inventory = await dbManager.database.query('inventory');
        expect(inventory, isNotEmpty);

        await dbManager.clearAllData();

        inventory = await dbManager.database.query('inventory');
        expect(inventory, isEmpty);

        final userStats = await dbManager.database.query('user_stats');
        expect(userStats, hasLength(1));
        expect(userStats.first['coins'], equals(500)); // Reset to default
      });
    });

    group('Error Handling', () {
      test('should throw error when accessing database before initialization', () async {
        // Create a completely new instance (not the singleton)
        // and try to access database before init
        final tempDb = LocalDatabaseManager();
        
        // Close existing connection first to avoid singleton
        await tempDb.close();
        
        expect(
          () => tempDb.database,
          throwsA(isA<StateError>()),
        );
        
        // Re-initialize for cleanup
        await tempDb.initialize();
      });
    });
  });
}


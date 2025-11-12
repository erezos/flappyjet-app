/// 🗄️ Database Schema - FlappyJet Pro Local Storage
/// 
/// Defines the complete SQLite schema for local-first game data storage
/// All game state is stored locally for instant access and offline support
library;

import 'package:sqflite/sqflite.dart';
import '../debug_logger.dart';

/// Database schema manager
class DatabaseSchema {
  static const String databaseName = 'flappyjet.db';
  static const int databaseVersion = 3; // Updated for Phase 4: Prize System

  /// Initialize all tables
  static Future<void> createTables(Database db) async {
    safePrint('📦 Creating database tables...');

    // User stats table
    await db.execute('''
      CREATE TABLE user_stats (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        user_id TEXT NOT NULL,
        nickname TEXT,
        high_score INTEGER DEFAULT 0,
        best_streak INTEGER DEFAULT 0,
        total_games_played INTEGER DEFAULT 0,
        total_score INTEGER DEFAULT 0,
        coins INTEGER DEFAULT 500,
        gems INTEGER DEFAULT 25,
        hearts INTEGER DEFAULT 3,
        last_heart_regen INTEGER,
        heart_booster_expiry INTEGER,
        equipped_skin_id TEXT,
        bot_battles_won INTEGER DEFAULT 0,
        bot_battles_lost INTEGER DEFAULT 0,
        total_distance_flown REAL DEFAULT 0.0,
        total_obstacles_dodged INTEGER DEFAULT 0,
        total_powerups_collected INTEGER DEFAULT 0,
        total_coins_collected INTEGER DEFAULT 0,
        total_gems_collected INTEGER DEFAULT 0,
        total_hearts_collected INTEGER DEFAULT 0,
        total_missions_completed INTEGER DEFAULT 0,
        total_achievements_unlocked INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Inventory table (jets, skins, power-ups)
    await db.execute('''
      CREATE TABLE inventory (
        id TEXT PRIMARY KEY,
        item_type TEXT NOT NULL,
        item_id TEXT NOT NULL,
        quantity INTEGER DEFAULT 1,
        is_equipped INTEGER DEFAULT 0,
        unlocked_at INTEGER NOT NULL,
        UNIQUE(item_type, item_id)
      )
    ''');

    // Games history (local game records)
    await db.execute('''
      CREATE TABLE games_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        game_mode TEXT NOT NULL,
        level_id TEXT,
        score INTEGER NOT NULL,
        survival_time_seconds INTEGER,
        obstacles_passed INTEGER DEFAULT 0,
        coins_collected INTEGER DEFAULT 0,
        gems_collected INTEGER DEFAULT 0,
        power_ups_used INTEGER DEFAULT 0,
        cause_of_death TEXT,
        continues_used INTEGER DEFAULT 0,
        jet_used TEXT,
        theme_used TEXT,
        played_at INTEGER NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_games_played_at ON games_history(played_at DESC)');
    await db.execute('CREATE INDEX idx_games_score ON games_history(score DESC)');

    // Story mode progress
    await db.execute('''
      CREATE TABLE story_progress (
        zone_id TEXT NOT NULL,
        level_id TEXT NOT NULL,
        stars INTEGER DEFAULT 0,
        best_score INTEGER DEFAULT 0,
        best_time_seconds INTEGER,
        attempts INTEGER DEFAULT 0,
        completed INTEGER DEFAULT 0,
        first_completed_at INTEGER,
        last_played_at INTEGER,
        PRIMARY KEY (zone_id, level_id)
      )
    ''');
    await db.execute('CREATE INDEX idx_story_zone ON story_progress(zone_id)');

    // Level progress table (for LevelSystemManager migration)
    await db.execute('''
      CREATE TABLE level_progress (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        user_id TEXT NOT NULL,
        current_level INTEGER DEFAULT 1,
        highest_unlocked INTEGER DEFAULT 1,
        completed_levels TEXT DEFAULT '[]',
        current_zone INTEGER DEFAULT 1,
        completed_zones TEXT DEFAULT '[]',
        first_attempt_completed TEXT DEFAULT '[]',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Missions (daily/weekly)
    await db.execute('''
      CREATE TABLE missions (
        id TEXT PRIMARY KEY,
        mission_type TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        target_value INTEGER NOT NULL,
        current_value INTEGER DEFAULT 0,
        reward_coins INTEGER DEFAULT 0,
        reward_gems INTEGER DEFAULT 0,
        status TEXT DEFAULT 'active',
        expires_at INTEGER,
        completed_at INTEGER,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_missions_status ON missions(status, expires_at)');

    // Achievements
    await db.execute('''
      CREATE TABLE achievements (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        achievement_points INTEGER DEFAULT 0,
        target_value INTEGER NOT NULL,
        current_value INTEGER DEFAULT 0,
        is_unlocked INTEGER DEFAULT 0,
        unlocked_at INTEGER,
        reward_coins INTEGER DEFAULT 0,
        reward_gems INTEGER DEFAULT 0
      )
    ''');

    // Local leaderboard cache (for display when offline)
    await db.execute('''
      CREATE TABLE leaderboard_cache (
        leaderboard_type TEXT NOT NULL,
        rank INTEGER NOT NULL,
        user_id TEXT NOT NULL,
        nickname TEXT,
        score INTEGER NOT NULL,
        jet_skin TEXT,
        theme TEXT,
        timestamp INTEGER NOT NULL,
        cached_at INTEGER NOT NULL,
        PRIMARY KEY (leaderboard_type, user_id)
      )
    ''');
    await db.execute('CREATE INDEX idx_leaderboard_score ON leaderboard_cache(leaderboard_type, score DESC)');

    // Tournament cache
    await db.execute('''
      CREATE TABLE tournament_cache (
        tournament_id TEXT PRIMARY KEY,
        start_time INTEGER NOT NULL,
        end_time INTEGER NOT NULL,
        prize_pool TEXT,
        user_score INTEGER DEFAULT 0,
        user_rank INTEGER,
        total_participants INTEGER DEFAULT 0,
        cached_at INTEGER NOT NULL
      )
    ''');

    // Tournament leaderboard cache
    await db.execute('''
      CREATE TABLE tournament_leaderboard_cache (
        tournament_id TEXT NOT NULL,
        rank INTEGER NOT NULL,
        user_id TEXT NOT NULL,
        nickname TEXT,
        score INTEGER NOT NULL,
        timestamp INTEGER NOT NULL,
        cached_at INTEGER NOT NULL,
        PRIMARY KEY (tournament_id, user_id)
      )
    ''');
    await db.execute('CREATE INDEX idx_tournament_leaderboard ON tournament_leaderboard_cache(tournament_id, score DESC)');

    // Pending prizes (Phase 4: Prize System)
    await db.execute('''
      CREATE TABLE pending_prizes (
        prize_id TEXT PRIMARY KEY,
        tournament_id TEXT NOT NULL,
        tournament_name TEXT NOT NULL,
        rank INTEGER NOT NULL,
        coins INTEGER DEFAULT 0,
        gems INTEGER DEFAULT 0,
        awarded_at INTEGER NOT NULL,
        claimed_at INTEGER,
        created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000)
      )
    ''');
    await db.execute('CREATE INDEX idx_pending_prizes_claimed ON pending_prizes(claimed_at)');
    await db.execute('CREATE INDEX idx_pending_prizes_awarded ON pending_prizes(awarded_at DESC)');

    // Settings
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Sync queue (for tracking what needs to be synced)
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sync_type TEXT NOT NULL,
        data TEXT NOT NULL,
        priority INTEGER DEFAULT 5,
        retry_count INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        last_attempt_at INTEGER
      )
    ''');
    await db.execute('CREATE INDEX idx_sync_priority ON sync_queue(priority DESC, created_at ASC)');

    safePrint('📦 ✅ All database tables created');
  }

  /// Upgrade database schema (for future versions)
  static Future<void> upgradeTables(Database db, int oldVersion, int newVersion) async {
    safePrint('📦 Upgrading database from v$oldVersion to v$newVersion...');

    // Migration from v1 to v2: Add new columns for Phase 2
    if (oldVersion < 2) {
      safePrint('📦 Migrating to v2: Adding Phase 2 columns...');
      
      // Add new columns to user_stats
      await db.execute('ALTER TABLE user_stats ADD COLUMN heart_booster_expiry INTEGER');
      await db.execute('ALTER TABLE user_stats ADD COLUMN equipped_skin_id TEXT');
      await db.execute('ALTER TABLE user_stats ADD COLUMN bot_battles_won INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE user_stats ADD COLUMN bot_battles_lost INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE user_stats ADD COLUMN total_distance_flown REAL DEFAULT 0.0');
      await db.execute('ALTER TABLE user_stats ADD COLUMN total_obstacles_dodged INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE user_stats ADD COLUMN total_powerups_collected INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE user_stats ADD COLUMN total_coins_collected INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE user_stats ADD COLUMN total_gems_collected INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE user_stats ADD COLUMN total_hearts_collected INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE user_stats ADD COLUMN total_missions_completed INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE user_stats ADD COLUMN total_achievements_unlocked INTEGER DEFAULT 0');
      
      // Create level_progress table
      await db.execute('''
        CREATE TABLE level_progress (
          id INTEGER PRIMARY KEY CHECK (id = 1),
          user_id TEXT NOT NULL,
          current_level INTEGER DEFAULT 1,
          highest_unlocked INTEGER DEFAULT 1,
          completed_levels TEXT DEFAULT '[]',
          current_zone INTEGER DEFAULT 1,
          completed_zones TEXT DEFAULT '[]',
          first_attempt_completed TEXT DEFAULT '[]',
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');
      
      safePrint('📦 ✅ v2 migration complete');
    }

    // Migration from v2 to v3: Add pending_prizes table for Phase 4
    if (oldVersion < 3) {
      safePrint('📦 Migrating to v3: Adding Phase 4 pending_prizes table...');
      
      await db.execute('''
        CREATE TABLE pending_prizes (
          prize_id TEXT PRIMARY KEY,
          tournament_id TEXT NOT NULL,
          tournament_name TEXT NOT NULL,
          rank INTEGER NOT NULL,
          coins INTEGER DEFAULT 0,
          gems INTEGER DEFAULT 0,
          awarded_at INTEGER NOT NULL,
          claimed_at INTEGER,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000)
        )
      ''');
      await db.execute('CREATE INDEX idx_pending_prizes_claimed ON pending_prizes(claimed_at)');
      await db.execute('CREATE INDEX idx_pending_prizes_awarded ON pending_prizes(awarded_at DESC)');
      
      safePrint('📦 ✅ v3 migration complete');
    }

    safePrint('📦 ✅ Database upgraded successfully');
  }

  /// Get table creation SQL for documentation
  static Map<String, String> getTableDefinitions() {
    return {
      'user_stats': '''
        Single row table storing user's core stats.
        - Coins, gems, hearts, high score, etc.
        - Always has exactly 1 row (id = 1)
      ''',
      'inventory': '''
        User's owned items (jets, skins, power-ups).
        - item_type: 'jet', 'skin', 'powerup'
        - is_equipped: 0 or 1 (only one item equipped per type)
      ''',
      'games_history': '''
        Record of all games played locally.
        - Used for stats, analytics, and personal records
        - Paginated queries for history screen
      ''',
      'story_progress': '''
        Story mode level completion tracking.
        - Stars earned (1-3), best score, best time
        - Attempts and completion status
      ''',
      'missions': '''
        Active and completed missions.
        - Daily and weekly missions
        - Tracks progress and rewards
      ''',
      'achievements': '''
        Achievement definitions and progress.
        - Unlocked status and progress tracking
      ''',
      'leaderboard_cache': '''
        Cached global leaderboard for offline display.
        - Updated periodically in background
        - Shows top players even when offline
      ''',
      'tournament_cache': '''
        Active tournament metadata.
        - Prize pool, dates, user's score/rank
      ''',
      'tournament_leaderboard_cache': '''
        Tournament participant rankings.
        - Cached for offline display
      ''',
      'settings': '''
        Key-value store for app settings.
        - Audio, notifications, preferences
      ''',
      'sync_queue': '''
        Queue for tracking data that needs backend sync.
        - Not used in Phase 2 (events handle sync)
        - Reserved for future use
      ''',
    };
  }

  /// Get table sizes (for monitoring)
  static Future<Map<String, int>> getTableSizes(Database db) async {
    final tables = [
      'user_stats',
      'inventory',
      'games_history',
      'story_progress',
      'level_progress',
      'missions',
      'achievements',
      'leaderboard_cache',
      'tournament_cache',
      'tournament_leaderboard_cache',
      'pending_prizes',
      'settings',
      'sync_queue',
    ];

    final sizes = <String, int>{};
    for (final table in tables) {
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM $table');
      sizes[table] = Sqflite.firstIntValue(result) ?? 0;
    }

    return sizes;
  }
}


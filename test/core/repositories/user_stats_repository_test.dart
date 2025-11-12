/// Unit tests for UserStatsRepository
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flappy_jet_pro/core/database/local_database_manager.dart';
import 'package:flappy_jet_pro/core/repositories/user_stats_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Initialize FFI for SQLite testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('UserStatsRepository', () {
    late LocalDatabaseManager dbManager;
    late UserStatsRepository repository;

    setUp(() async {
      dbManager = LocalDatabaseManager();
      await dbManager.initialize();
      
      // Clear all data to ensure clean state for each test
      await dbManager.clearAllData();
      
      repository = UserStatsRepository(dbManager);
    });

    tearDown(() async {
      await dbManager.close();
    });

    group('Initialization', () {
      test('should get initial user stats', () async {
        final stats = await repository.getUserStats();

        expect(stats, isNotNull);
        expect(stats.coins, equals(500));
        expect(stats.gems, equals(25));
        expect(stats.hearts, equals(3));
        expect(stats.highScore, equals(0));
        expect(stats.bestStreak, equals(0));
        expect(stats.totalGamesPlayed, equals(0));
      });

      test('should cache user stats', () async {
        final stats1 = await repository.getUserStats();
        final stats2 = await repository.getUserStats();

        expect(identical(stats1, stats2), isTrue); // Same cached instance
      });
    });

    group('User ID', () {
      test('should set user ID', () async {
        await repository.setUserId('user_test123_1699459200');
        
        final stats = await repository.getUserStats();
        expect(stats.userId, equals('user_test123_1699459200'));
      });

      test('should update user ID', () async {
        await repository.setUserId('user_old_123');
        await repository.setUserId('user_new_456');
        
        final stats = await repository.getUserStats();
        expect(stats.userId, equals('user_new_456'));
      });
    });

    group('Nickname', () {
      test('should set nickname', () async {
        await repository.setNickname('TestPlayer');
        
        final stats = await repository.getUserStats();
        expect(stats.nickname, equals('TestPlayer'));
      });

      test('should update nickname', () async {
        await repository.setNickname('OldName');
        await repository.setNickname('NewName');
        
        final stats = await repository.getUserStats();
        expect(stats.nickname, equals('NewName'));
      });
    });

    group('High Score', () {
      test('should update high score when new score is higher', () async {
        final wasNew = await repository.updateHighScore(100);
        
        expect(wasNew, isTrue);
        
        final stats = await repository.getUserStats();
        expect(stats.highScore, equals(100));
      });

      test('should not update high score when new score is lower', () async {
        await repository.updateHighScore(100);
        final wasNew = await repository.updateHighScore(50);
        
        expect(wasNew, isFalse);
        
        final stats = await repository.getUserStats();
        expect(stats.highScore, equals(100));
      });

      test('should not update high score when equal', () async {
        await repository.updateHighScore(100);
        final wasNew = await repository.updateHighScore(100);
        
        expect(wasNew, isFalse);
      });

      test('should update high score multiple times correctly', () async {
        await repository.updateHighScore(50);
        await repository.updateHighScore(100);
        await repository.updateHighScore(75); // Should not update
        await repository.updateHighScore(150);
        
        final stats = await repository.getUserStats();
        expect(stats.highScore, equals(150));
      });
    });

    group('Best Streak', () {
      test('should update best streak when new streak is better', () async {
        final wasNew = await repository.updateBestStreak(10);
        
        expect(wasNew, isTrue);
        
        final stats = await repository.getUserStats();
        expect(stats.bestStreak, equals(10));
      });

      test('should not update best streak when new streak is lower', () async {
        await repository.updateBestStreak(10);
        final wasNew = await repository.updateBestStreak(5);
        
        expect(wasNew, isFalse);
        
        final stats = await repository.getUserStats();
        expect(stats.bestStreak, equals(10));
      });
    });

    group('Games Played', () {
      test('should increment games played', () async {
        await repository.incrementGamesPlayed();
        
        final stats = await repository.getUserStats();
        expect(stats.totalGamesPlayed, equals(1));
      });

      test('should increment multiple times', () async {
        for (int i = 0; i < 10; i++) {
          await repository.incrementGamesPlayed();
        }
        
        final stats = await repository.getUserStats();
        expect(stats.totalGamesPlayed, equals(10));
      });
    });

    group('Total Score', () {
      test('should add to total score', () async {
        await repository.addToTotalScore(100);
        
        final stats = await repository.getUserStats();
        expect(stats.totalScore, equals(100));
      });

      test('should accumulate total score', () async {
        await repository.addToTotalScore(100);
        await repository.addToTotalScore(50);
        await repository.addToTotalScore(25);
        
        final stats = await repository.getUserStats();
        expect(stats.totalScore, equals(175));
      });
    });

    group('Coins', () {
      test('should add coins', () async {
        await repository.addCoins(100);
        
        final stats = await repository.getUserStats();
        expect(stats.coins, equals(600)); // 500 initial + 100
      });

      test('should spend coins', () async {
        final success = await repository.spendCoins(100);
        
        expect(success, isTrue);
        
        final stats = await repository.getUserStats();
        expect(stats.coins, equals(400)); // 500 initial - 100
      });

      test('should not spend more coins than available', () async {
        final success = await repository.spendCoins(1000);
        
        expect(success, isFalse);
        
        final stats = await repository.getUserStats();
        expect(stats.coins, equals(500)); // Unchanged
      });

      test('should handle coin transactions correctly', () async {
        await repository.addCoins(500); // 1000 total
        await repository.spendCoins(300); // 700
        await repository.addCoins(100); // 800
        await repository.spendCoins(50); // 750
        
        final stats = await repository.getUserStats();
        expect(stats.coins, equals(750));
      });
    });

    group('Gems', () {
      test('should add gems', () async {
        await repository.addGems(10);
        
        final stats = await repository.getUserStats();
        expect(stats.gems, equals(35)); // 25 initial + 10
      });

      test('should spend gems', () async {
        final success = await repository.spendGems(10);
        
        expect(success, isTrue);
        
        final stats = await repository.getUserStats();
        expect(stats.gems, equals(15)); // 25 initial - 10
      });

      test('should not spend more gems than available', () async {
        final success = await repository.spendGems(100);
        
        expect(success, isFalse);
        
        final stats = await repository.getUserStats();
        expect(stats.gems, equals(25)); // Unchanged
      });
    });

    group('Hearts', () {
      test('should set hearts', () async {
        await repository.setHearts(5);
        
        final stats = await repository.getUserStats();
        expect(stats.hearts, equals(5));
      });

      test('should use heart', () async {
        final success = await repository.useHeart();
        
        expect(success, isTrue);
        
        final stats = await repository.getUserStats();
        expect(stats.hearts, equals(2)); // 3 initial - 1
      });

      test('should not use heart when none available', () async {
        await repository.setHearts(0);
        final success = await repository.useHeart();
        
        expect(success, isFalse);
        
        final stats = await repository.getUserStats();
        expect(stats.hearts, equals(0));
      });

      test('should clamp hearts to max 5', () async {
        await repository.setHearts(10);
        
        final stats = await repository.getUserStats();
        expect(stats.hearts, equals(5)); // Clamped to max
      });

      test('should clamp hearts to min 0', () async {
        await repository.setHearts(-5);
        
        final stats = await repository.getUserStats();
        expect(stats.hearts, equals(0)); // Clamped to min
      });
    });

    group('Average Score', () {
      test('should calculate average score correctly', () async {
        await repository.incrementGamesPlayed();
        await repository.addToTotalScore(100);
        
        final avg = await repository.getAverageScore();
        expect(avg, equals(100.0));
      });

      test('should calculate average with multiple games', () async {
        await repository.incrementGamesPlayed();
        await repository.addToTotalScore(100);
        await repository.incrementGamesPlayed();
        await repository.addToTotalScore(50);
        await repository.incrementGamesPlayed();
        await repository.addToTotalScore(150);
        
        final avg = await repository.getAverageScore();
        expect(avg, equals(100.0)); // (100 + 50 + 150) / 3
      });

      test('should return 0 when no games played', () async {
        final avg = await repository.getAverageScore();
        expect(avg, equals(0.0));
      });
    });

    group('Cache Management', () {
      test('should clear cache', () async {
        await repository.getUserStats(); // Load cache
        repository.clearCache();
        
        // Next call should reload from database
        final stats = await repository.getUserStats();
        expect(stats, isNotNull);
      });

      test('should invalidate cache on updates', () async {
        final stats1 = await repository.getUserStats();
        await repository.addCoins(100);
        final stats2 = await repository.getUserStats();

        expect(stats1.coins, equals(500));
        expect(stats2.coins, equals(600));
        expect(identical(stats1, stats2), isFalse); // Different instances
      });
    });

    group('UserStats Model', () {
      test('should create from map', () {
        final map = {
          'user_id': 'user_123',
          'nickname': 'TestPlayer',
          'high_score': 100,
          'best_streak': 10,
          'total_games_played': 5,
          'total_score': 500,
          'coins': 1000,
          'gems': 50,
          'hearts': 3,
          'last_heart_regen': null,
          'created_at': 1699459200000,
          'updated_at': 1699459200000,
        };

        final stats = UserStats.fromMap(map);

        expect(stats.userId, equals('user_123'));
        expect(stats.nickname, equals('TestPlayer'));
        expect(stats.highScore, equals(100));
        expect(stats.coins, equals(1000));
      });

      test('should convert to map', () {
        final stats = UserStats(
          userId: 'user_123',
          nickname: 'TestPlayer',
          highScore: 100,
          bestStreak: 10,
          totalGamesPlayed: 5,
          totalScore: 500,
          coins: 1000,
          gems: 50,
          hearts: 3,
          lastHeartRegen: null,
          createdAt: DateTime.fromMillisecondsSinceEpoch(1699459200000),
          updatedAt: DateTime.fromMillisecondsSinceEpoch(1699459200000),
        );

        final map = stats.toMap();

        expect(map['user_id'], equals('user_123'));
        expect(map['high_score'], equals(100));
        expect(map['coins'], equals(1000));
      });

      test('should handle copyWith', () {
        final stats1 = UserStats(
          userId: 'user_123',
          nickname: null,
          highScore: 100,
          bestStreak: 10,
          totalGamesPlayed: 5,
          totalScore: 500,
          coins: 1000,
          gems: 50,
          hearts: 3,
          lastHeartRegen: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final stats2 = stats1.copyWith(coins: 2000, gems: 100);

        expect(stats2.userId, equals(stats1.userId));
        expect(stats2.coins, equals(2000)); // Updated
        expect(stats2.gems, equals(100)); // Updated
        expect(stats2.highScore, equals(100)); // Unchanged
      });

      test('should provide string representation', () {
        final stats = UserStats(
          userId: 'user_test123_1699459200',
          nickname: null,
          highScore: 100,
          bestStreak: 10,
          totalGamesPlayed: 5,
          totalScore: 500,
          coins: 1000,
          gems: 50,
          hearts: 3,
          lastHeartRegen: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final str = stats.toString();

        expect(str, contains('user_test1')); // Truncated user ID
        expect(str, contains('coins: 1000'));
        expect(str, contains('gems: 50'));
      });
    });
  });
}


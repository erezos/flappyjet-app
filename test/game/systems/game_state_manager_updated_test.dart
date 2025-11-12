import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/game/systems/game_state_manager.dart';
import 'package:flappy_jet_pro/core/repositories/user_stats_repository.dart';
import 'package:flappy_jet_pro/core/database/local_database_manager.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Initialize FFI for testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late LocalDatabaseManager dbManager;
  late UserStatsRepository userStats;
  late GameStateManager manager;

  setUp(() async {
    dbManager = LocalDatabaseManager();
    await dbManager.initialize();
    await dbManager.clearAllData();
    
    userStats = UserStatsRepository(dbManager);
    await userStats.setUserId('test_user_123');
    
    manager = GameStateManager(userStats: userStats);
    
    // Wait for async constructor to complete
    await Future.delayed(const Duration(milliseconds: 100));
  });

  tearDown(() async {
    await dbManager.clearAllData();
    await dbManager.close();
  });

  group('GameStateManager - SQLite Persistence', () {
    test('should load persisted best score/streak from repository', () async {
      // Set initial scores
      await userStats.updateHighScore(42);
      await userStats.updateBestStreak(30);
      
      // Create new manager instance (should load from DB)
      final newManager = GameStateManager(userStats: userStats);
      await Future.delayed(const Duration(milliseconds: 100));
      
      expect(newManager.bestScore, equals(42));
      expect(newManager.bestStreak, equals(30));
    });

    test('should save new best score to repository', () async {
      manager.startGame();
      
      await manager.saveBestScore(50);
      
      // Verify it was saved to database
      final stats = await userStats.getUserStats();
      expect(stats.highScore, equals(50));
      expect(manager.bestScore, equals(50));
    });

    test('should not update best score if new score is lower', () async {
      await userStats.updateHighScore(100);
      manager.setBestScore(100);
      
      manager.startGame();
      await manager.saveBestScore(50);
      
      // Should still be 100
      final stats = await userStats.getUserStats();
      expect(stats.highScore, equals(100));
      expect(manager.bestScore, equals(100));
    });

    test('should save new best streak to repository (clean run)', () async {
      manager.startGame();
      manager.updateScore(35);
      
      // Clean run (no continues used)
      await manager.saveBestStreak(35);
      
      // Verify it was saved to database
      final stats = await userStats.getUserStats();
      expect(stats.bestStreak, equals(35));
      expect(manager.bestStreak, equals(35));
    });

    test('should not save streak if continues were used', () async {
      manager.startGame();
      manager.setLives(0);
      manager.setGameOver();
      manager.continueGame(); // Use a continue
      
      manager.updateScore(50);
      await manager.saveBestStreak(50);
      
      // Should not be saved
      final stats = await userStats.getUserStats();
      expect(stats.bestStreak, equals(0));
      expect(manager.bestStreak, equals(0));
    });

    test('should handle repository unavailable gracefully', () async {
      // Create manager without repository
      final managerWithoutRepo = GameStateManager();
      
      managerWithoutRepo.startGame();
      
      // Should not throw
      expect(() async => await managerWithoutRepo.saveBestScore(100), returnsNormally);
      expect(() async => await managerWithoutRepo.saveBestStreak(100), returnsNormally);
    });
  });

  group('GameStateManager - Game Flow Integration', () {
    test('should persist scores across game sessions', () async {
      // First game session
      manager.startGame();
      manager.updateScore(75);
      await manager.saveBestScore(75);
      await manager.saveBestStreak(75);
      
      // Simulate app restart - create new manager
      final newManager = GameStateManager(userStats: userStats);
      await Future.delayed(const Duration(milliseconds: 100));
      
      expect(newManager.bestScore, equals(75));
      expect(newManager.bestStreak, equals(75));
    });

    test('should update scores during active game', () async {
      manager.startGame();
      
      manager.updateScore(10);
      await manager.saveBestScore(10);
      
      manager.updateScore(25);
      await manager.saveBestScore(25);
      
      manager.updateScore(50);
      await manager.saveBestScore(50);
      
      expect(manager.score, equals(50));
      expect(manager.bestScore, equals(50));
      
      final stats = await userStats.getUserStats();
      expect(stats.highScore, equals(50));
    });
  });
}


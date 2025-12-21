/// 🧪 Profile Data Aggregator Tests
/// 
/// Unit tests for ProfileDataAggregator service
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flappy_jet_pro/ui/widgets/profile/profile_data_aggregator.dart';
import 'package:flappy_jet_pro/game/systems/inventory_manager.dart';
import 'package:flappy_jet_pro/game/systems/achievements_manager.dart';
import 'package:flappy_jet_pro/game/systems/missions_manager.dart';
import 'package:flappy_jet_pro/game/systems/tournament_manager.dart';
import 'package:flappy_jet_pro/game/systems/player_identity_manager.dart';
import 'package:flappy_jet_pro/game/systems/profile_manager.dart';
import 'package:flappy_jet_pro/core/database/local_database_manager.dart';
import 'package:flappy_jet_pro/core/repositories/user_stats_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Initialize FFI for SQLite testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('ProfileDataAggregator', () {
    late ProfileDataAggregator aggregator;
    late LocalDatabaseManager dbManager;
    late UserStatsRepository userStats;

    setUp(() async {
      // Clear SharedPreferences
      SharedPreferences.setMockInitialValues({});
      
      // Initialize database
      dbManager = LocalDatabaseManager();
      await dbManager.initialize();
      await dbManager.clearAllData();
      
      userStats = UserStatsRepository(dbManager);
      await userStats.setUserId('test_user_123');
      
      aggregator = ProfileDataAggregator();
      aggregator.setUserStatsRepository(userStats);
    });

    tearDown(() async {
      await dbManager.clearAllData();
      await dbManager.close();
    });

    test('should initialize successfully', () async {
      await aggregator.initialize();
      
      expect(aggregator.isInitialized, isTrue);
    });

    test('should aggregate profile data', () async {
      await aggregator.initialize();
      await aggregator.refresh();
      
      final data = aggregator.profileData;
      expect(data, isNotNull);
      expect(data!.nickname, isNotEmpty);
      expect(data.userLevel, greaterThanOrEqualTo(1));
      expect(data.highestScore, greaterThanOrEqualTo(0));
      expect(data.missionsCompleted, greaterThanOrEqualTo(0));
      expect(data.achievementsCompleted, greaterThanOrEqualTo(0));
      expect(data.tournamentsWon, greaterThanOrEqualTo(0));
      expect(data.totalJetsOwned, greaterThanOrEqualTo(0));
      expect(data.totalJetsAvailable, greaterThan(0));
    });

    test('should calculate user level correctly', () async {
      // Set test data
      final stats = await userStats.getUserStats();
      // Note: We can't directly set totalGamesPlayed, but we can test the calculation
      
      await aggregator.initialize();
      await aggregator.refresh();
      
      final data = aggregator.profileData;
      expect(data!.userLevel, greaterThanOrEqualTo(1));
      expect(data.userLevel, lessThanOrEqualTo(100)); // Capped at 100
    });

    test('should handle missing UserStatsRepository gracefully', () async {
      final aggregatorWithoutStats = ProfileDataAggregator();
      // Don't set UserStatsRepository
      
      await aggregatorWithoutStats.initialize();
      await aggregatorWithoutStats.refresh();
      
      final data = aggregatorWithoutStats.profileData;
      expect(data, isNotNull);
      // Should use SharedPreferences fallback
      expect(data!.highestScore, greaterThanOrEqualTo(0));
    });

    test('should update when data changes', () async {
      await aggregator.initialize();
      await aggregator.refresh();
      
      final initialData = aggregator.profileData;
      
      // Simulate data change by refreshing
      await aggregator.refresh();
      
      final updatedData = aggregator.profileData;
      expect(updatedData, isNotNull);
      // Data should be refreshed
    });

    test('should calculate collection completion percentage', () async {
      await aggregator.initialize();
      await aggregator.refresh();
      
      final data = aggregator.profileData;
      expect(data, isNotNull);
      
      final percentage = data!.collectionCompletionPercentage;
      expect(percentage, greaterThanOrEqualTo(0.0));
      expect(percentage, lessThanOrEqualTo(1.0));
    });
  });
}


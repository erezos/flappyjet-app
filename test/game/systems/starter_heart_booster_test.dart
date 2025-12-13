import 'package:flappy_jet_pro/core/database/local_database_manager.dart';
import 'package:flappy_jet_pro/core/events/event_bus.dart';
import 'package:flappy_jet_pro/core/repositories/inventory_repository.dart';
import 'package:flappy_jet_pro/core/repositories/user_stats_repository.dart';
import 'package:flappy_jet_pro/game/systems/inventory_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Starter heart booster', () {
    late LocalDatabaseManager dbManager;
    late UserStatsRepository userStats;
    late InventoryRepository inventoryRepo;
    late InventoryManager inventoryManager;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await InventoryManager().resetForTesting();
      databaseFactory = databaseFactoryFfi;
      dbManager = LocalDatabaseManager();
      await dbManager.initialize();
      await dbManager.clearAllData();

      userStats = UserStatsRepository(dbManager);
      inventoryRepo = InventoryRepository(dbManager);
      await userStats.setUserId('tester');
      await userStats.setHeartBoosterExpiry(null);

      inventoryManager = InventoryManager();
      await inventoryManager.initialize(
        userStats: userStats,
        inventory: inventoryRepo,
        eventBus: EventBus(),
      );
    });

    tearDown(() async {
      await dbManager.close();
    });

    test('grants booster once for first-time users', () async {
      final applied = await inventoryManager.grantStarterHeartBoosterIfEligible(
        isFirstTimeUser: true,
      );
      expect(applied, isTrue);
      expect(inventoryManager.isHeartBoosterActive, isTrue);

      final expiry = inventoryManager.heartBoosterExpiry!;
      expect(
        expiry.isAfter(DateTime.now().add(const Duration(hours: 23))),
        isTrue,
      );

      // Second call should not re-apply
      final reapplied = await inventoryManager.grantStarterHeartBoosterIfEligible(
        isFirstTimeUser: true,
      );
      expect(reapplied, isFalse);
    });

    test('does not grant for non-first-time users', () async {
      final applied = await inventoryManager.grantStarterHeartBoosterIfEligible(
        isFirstTimeUser: false,
      );
      expect(applied, isFalse);
      expect(inventoryManager.isHeartBoosterActive, isFalse);
    });
  });
}


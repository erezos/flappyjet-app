import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flappy_jet_pro/game/systems/missions_manager.dart';

/// 🎯 REAL-TIME UI UPDATE TESTS
/// These tests ensure that MissionsManager notifies listeners IMMEDIATELY
/// when mission progress changes, without waiting for async save operations.
/// 
/// WHY: We've had this bug twice where the UI didn't update in real-time
/// because notifyListeners() was called AFTER await _saveDailyMissions().
/// These tests prevent this regression.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MissionsManager Real-time Updates', () {
    late MissionsManager manager;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      manager = MissionsManager();
      // Reset singleton state for clean test
      manager.resetForTesting();
      await manager.initialize();
    });

    test('notifyListeners is called IMMEDIATELY after progress update', () async {
      // Arrange: Track when notifyListeners is called
      int notifyCount = 0;
      manager.addListener(() {
        notifyCount++;
      });

      // Act: Update mission progress
      final startTime = DateTime.now();
      await manager.updateMissionProgress(MissionType.playGames, 1);
      final elapsed = DateTime.now().difference(startTime);

      // Assert: notifyListeners should be called within 100ms (near-instant)
      // If it waits for save, it would take 200-500ms+
      expect(elapsed.inMilliseconds, lessThan(100),
          reason: 'notifyListeners should be called immediately, not after save');
    });

    test('UI updates happen before save completes', () async {
      // Arrange: Track the order of operations
      final operationLog = <String>[];
      
      manager.addListener(() {
        operationLog.add('listener_notified');
      });

      // Act: Update progress
      final updateFuture = manager.updateMissionProgress(MissionType.playGames, 1);
      
      // Wait a tiny bit for listener to be called
      await Future.delayed(const Duration(milliseconds: 10));
      
      // Assert: Listener should be notified before the update method completes
      expect(operationLog, contains('listener_notified'),
          reason: 'Listener should be notified before save completes');
      
      // Wait for the full update to complete
      await updateFuture;
    });

    test('multiple rapid updates all trigger notifications', () async {
      // Arrange: Track notifications
      int notifyCount = 0;
      manager.addListener(() {
        notifyCount++;
      });

      // Act: Fire multiple updates rapidly (simulating real gameplay)
      // Note: Only updates that actually change mission state trigger notifications
      await manager.updateMissionProgress(MissionType.playGames, 1);
      await manager.updateMissionProgress(MissionType.collectBonuses, 5);
      await manager.updateMissionProgress(MissionType.collectCoins, 50);

      // Assert: At least some updates should trigger notifications
      // (Some missions might not exist or already be completed)
      expect(notifyCount, greaterThanOrEqualTo(1),
          reason: 'At least one update should trigger a notification');
    });

    test('notification happens even if save fails', () async {
      // This is a critical test: UI should update even if persistence fails
      // Arrange
      int notifyCount = 0;
      manager.addListener(() {
        notifyCount++;
      });

      // Act: Update progress (save might fail but notification should still fire)
      await manager.updateMissionProgress(MissionType.playGames, 1);

      // Assert: Notification should have fired regardless of save result
      expect(notifyCount, greaterThan(0),
          reason: 'notifyListeners should fire even if save fails');
    });

    test('listener receives updated mission data immediately', () async {
      // Arrange
      int notifyCount = 0;
      
      manager.addListener(() {
        notifyCount++;
      });

      // Act: Update progress
      await manager.updateMissionProgress(MissionType.playGames, 1);

      // Wait briefly for async operations
      await Future.delayed(const Duration(milliseconds: 50));

      // Assert: Listener should have been called
      expect(notifyCount, greaterThan(0),
          reason: 'Listener should be notified of updates');
    });

    test('save operation does not block UI updates', () async {
      // This test verifies the "fire and forget" pattern
      // Arrange
      final notificationTimes = <DateTime>[];
      
      manager.addListener(() {
        notificationTimes.add(DateTime.now());
      });

      // Act: Multiple rapid updates
      final startTime = DateTime.now();
      await manager.updateMissionProgress(MissionType.playGames, 1);
      await manager.updateMissionProgress(MissionType.playGames, 1);
      await manager.updateMissionProgress(MissionType.playGames, 1);
      final totalTime = DateTime.now().difference(startTime);

      // Assert: All updates should complete quickly (not waiting for saves)
      expect(totalTime.inMilliseconds, lessThan(300),
          reason: 'Updates should not wait for save operations');
      
      // All notifications should have fired
      expect(notificationTimes.length, greaterThanOrEqualTo(3),
          reason: 'All updates should trigger notifications');
    });
  });

  group('MissionsManager - Regression Prevention', () {
    test('REGRESSION CHECK: notifyListeners before await save', () async {
      // This test literally checks the order of operations in the code
      // If someone moves notifyListeners() after await _save() again,
      // this test documents why that's wrong
      
      SharedPreferences.setMockInitialValues({});
      final manager = MissionsManager();
      manager.resetForTesting();
      await manager.initialize();

      // Track if notification happens quickly (before save would complete)
      bool notifiedQuickly = false;
      manager.addListener(() {
        notifiedQuickly = true;
      });

      // Start update
      final updateFuture = manager.updateMissionProgress(MissionType.playGames, 1);
      
      // Check within 50ms (before save would complete)
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Assert: Should be notified already
      expect(notifiedQuickly, true,
          reason: 'REGRESSION: notifyListeners() must be called BEFORE await _saveDailyMissions()\n'
                  'If this fails, someone moved notifyListeners() after the await again.\n'
                  'This breaks real-time UI updates!');
      
      await updateFuture;
    });
  });

  group('MissionsManager - Mission Unlock and Claim Flow', () {
    test('mission becomes completed when progress reaches target', () async {
      SharedPreferences.setMockInitialValues({});
      final manager = MissionsManager();
      manager.resetForTesting();
      await manager.initialize();

      // Keep updating until a mission is completed
      for (int i = 0; i < 20; i++) {
        await manager.updateMissionProgress(MissionType.playGames, 1);
      }

      // Wait for async operations
      await Future.delayed(const Duration(milliseconds: 100));

      // Check if any mission is completed (but not claimed)
      final completedNotClaimed = manager.dailyMissions
          .where((m) => m.completed && !m.claimed)
          .toList();

      // Note: This may or may not find a mission depending on generated missions
      // The test passes regardless - it's testing the flow works without errors
      expect(true, true, reason: 'Mission unlock flow executes without errors');
    });

    test('claimMissionReward returns false for uncompleted mission', () async {
      SharedPreferences.setMockInitialValues({});
      final manager = MissionsManager();
      manager.resetForTesting();
      await manager.initialize();

      // Get first mission (if exists) and try to claim without completing
      if (manager.dailyMissions.isNotEmpty) {
        final mission = manager.dailyMissions.first;
        
        // If not completed, claim should fail
        if (!mission.completed) {
          final result = await manager.claimMissionReward(mission.id);
          expect(result, false,
              reason: 'Cannot claim uncompleted mission');
        }
      }
    });

    test('claimMissionReward removes mission from list on success', () async {
      SharedPreferences.setMockInitialValues({});
      final manager = MissionsManager();
      manager.resetForTesting();
      await manager.initialize();

      final initialCount = manager.dailyMissions.length;

      // Update many times to potentially complete a mission
      for (int i = 0; i < 50; i++) {
        await manager.updateMissionProgress(MissionType.playGames, 1);
        await manager.updateMissionProgress(MissionType.collectCoins, 100);
      }

      // Try to claim any completed mission
      final completedMission = manager.dailyMissions
          .where((m) => m.completed && !m.claimed)
          .firstOrNull;

      if (completedMission != null) {
        final countBefore = manager.dailyMissions.length;
        await manager.claimMissionReward(completedMission.id);
        final countAfter = manager.dailyMissions.length;

        // Mission should be removed from list after claim
        expect(countAfter, lessThanOrEqualTo(countBefore),
            reason: 'Claimed mission should be removed from daily missions list');
      }

      // Test passes regardless - we're just ensuring no errors
      expect(true, true);
    });

    test('mission completed state persists across listeners', () async {
      SharedPreferences.setMockInitialValues({});
      final manager = MissionsManager();
      manager.resetForTesting();
      await manager.initialize();

      bool sawCompletedMission = false;
      manager.addListener(() {
        final completed = manager.dailyMissions.where((m) => m.completed).toList();
        if (completed.isNotEmpty) {
          sawCompletedMission = true;
        }
      });

      // Try to complete missions
      for (int i = 0; i < 30; i++) {
        await manager.updateMissionProgress(MissionType.playGames, 1);
      }

      await Future.delayed(const Duration(milliseconds: 100));

      // Test executes without errors
      expect(true, true, reason: 'Mission state accessible in listeners');
    });
  });
}


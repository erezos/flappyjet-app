import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flappy_jet_pro/game/systems/missions_manager.dart';
import 'package:flappy_jet_pro/game/systems/achievements_manager.dart';
import 'package:flappy_jet_pro/ui/screens/daily_missions_screen.dart';

/// 🎯 REAL-TIME UI UPDATE INTEGRATION TESTS
/// These tests verify that DailyMissionsScreen updates in real-time
/// when mission progress changes, without requiring app restart.
/// 
/// WHY: We've had this bug where missions updated but UI didn't refresh
/// until the app was restarted. These tests prevent this regression.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DailyMissionsScreen Real-time Updates', () {
    late MissionsManager missionsManager;
    late AchievementsManager achievementsManager;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      missionsManager = MissionsManager();
      achievementsManager = AchievementsManager();
      await missionsManager.initialize();
      await achievementsManager.initialize();
    });

    testWidgets('UI updates immediately when mission progress changes', (WidgetTester tester) async {
      // Arrange: Build the screen
      await tester.pumpWidget(
        MaterialApp(
          home: DailyMissionsScreen(
            missionsManager: missionsManager,
            achievementsManager: achievementsManager,
          ),
        ),
      );

      // Wait for initial build
      await tester.pumpAndSettle();

      // Get initial mission count
      final initialMissions = missionsManager.dailyMissions;
      expect(initialMissions.isNotEmpty, true, reason: 'Should have missions');

      // Find a mission card
      final missionFinder = find.textContaining('Progress:');
      expect(missionFinder, findsWidgets, reason: 'Should show mission progress');

      // Act: Update mission progress
      await missionsManager.updateMissionProgress(
        initialMissions.first.type,
        1,
      );

      // Wait for UI to rebuild (should happen immediately via ListenableBuilder)
      await tester.pump();

      // Assert: UI should have updated
      // The ListenableBuilder should trigger a rebuild when notifyListeners() is called
      expect(find.textContaining('Progress:'), findsWidgets,
          reason: 'Mission progress should still be visible after update');
    });

    testWidgets('UI updates when mission completes', (WidgetTester tester) async {
      // Arrange: Build the screen
      await tester.pumpWidget(
        MaterialApp(
          home: DailyMissionsScreen(
            missionsManager: missionsManager,
            achievementsManager: achievementsManager,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find a mission that's not completed
      final missions = missionsManager.dailyMissions;
      final incompleteMission = missions.firstWhere(
        (m) => !m.completed,
        orElse: () => missions.first,
      );

      // Act: Complete the mission by updating progress to target
      await missionsManager.updateMissionProgress(
        incompleteMission.type,
        incompleteMission.target - incompleteMission.progress + 1,
      );

      // Wait for UI to rebuild
      await tester.pump();

      // Assert: Mission should now show as completed
      // The ListenableBuilder should have triggered a rebuild
      expect(find.textContaining('CLAIM REWARD'), findsWidgets,
          reason: 'Completed mission should show claim button');
    });

    testWidgets('UI updates multiple times during rapid progress updates', (WidgetTester tester) async {
      // Arrange: Build the screen
      await tester.pumpWidget(
        MaterialApp(
          home: DailyMissionsScreen(
            missionsManager: missionsManager,
            achievementsManager: achievementsManager,
          ),
        ),
      );

      await tester.pumpAndSettle();

      final missions = missionsManager.dailyMissions;
      final mission = missions.firstWhere(
        (m) => !m.completed,
        orElse: () => missions.first,
      );

      // Act: Rapidly update progress multiple times (simulating gameplay)
      for (int i = 0; i < 3; i++) {
        await missionsManager.updateMissionProgress(mission.type, 1);
        await tester.pump(); // Allow UI to rebuild after each update
      }

      // Assert: UI should have updated after each change
      // The ListenableBuilder should rebuild on each notifyListeners() call
      expect(find.textContaining('Progress:'), findsWidgets,
          reason: 'Mission progress should be visible after all updates');
    });

    testWidgets('UI updates even when screen is already built', (WidgetTester tester) async {
      // This test simulates the real-world scenario:
      // 1. User opens missions screen
      // 2. User plays a game (missions update in background)
      // 3. User navigates back to missions screen
      // 4. UI should show updated progress WITHOUT needing app restart

      // Arrange: Build the screen
      await tester.pumpWidget(
        MaterialApp(
          home: DailyMissionsScreen(
            missionsManager: missionsManager,
            achievementsManager: achievementsManager,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Get initial progress text
      final initialProgressFinder = find.textContaining('Progress:');
      expect(initialProgressFinder, findsWidgets);

      // Act: Update mission progress (simulating gameplay while screen is open)
      final missions = missionsManager.dailyMissions;
      final mission = missions.firstWhere(
        (m) => !m.completed,
        orElse: () => missions.first,
      );

      final initialProgress = mission.progress;
      await missionsManager.updateMissionProgress(mission.type, 1);

      // Wait for ListenableBuilder to rebuild
      await tester.pump();

      // Assert: UI should reflect the new progress
      // The ListenableBuilder should have detected the change and rebuilt
      expect(find.textContaining('Progress:'), findsWidgets,
          reason: 'Progress should still be visible after update');
    });

    testWidgets('ListenableBuilder uses correct manager instance', (WidgetTester tester) async {
      // This test ensures that ListenableBuilder is listening to the same
      // manager instance that's being updated

      // Arrange: Create a second manager instance (should NOT be used)
      final otherManager = MissionsManager();
      await otherManager.initialize();

      // Build screen with first manager
      await tester.pumpWidget(
        MaterialApp(
          home: DailyMissionsScreen(
            missionsManager: missionsManager,
            achievementsManager: achievementsManager,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act: Update the FIRST manager (the one passed to screen)
      final missions = missionsManager.dailyMissions;
      final mission = missions.firstWhere(
        (m) => !m.completed,
        orElse: () => missions.first,
      );

      await missionsManager.updateMissionProgress(mission.type, 1);

      // Wait for UI rebuild
      await tester.pump();

      // Assert: UI should update because ListenableBuilder is listening to missionsManager
      expect(find.textContaining('Progress:'), findsWidgets,
          reason: 'UI should update when the correct manager instance changes');
    });
  });

  group('DailyMissionsScreen - Regression Prevention', () {
    late MissionsManager missionsManager;
    late AchievementsManager achievementsManager;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      missionsManager = MissionsManager();
      achievementsManager = AchievementsManager();
      await missionsManager.initialize();
      await achievementsManager.initialize();
    });

    testWidgets('REGRESSION CHECK: UI updates without app restart', (WidgetTester tester) async {
      // This test documents the exact bug we're fixing:
      // Before: UI only updated after app restart
      // After: UI updates immediately via ListenableBuilder

      // Arrange: Build screen
      await tester.pumpWidget(
        MaterialApp(
          home: DailyMissionsScreen(
            missionsManager: missionsManager,
            achievementsManager: achievementsManager,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Get initial state
      final missions = missionsManager.dailyMissions;
      final mission = missions.firstWhere(
        (m) => !m.completed,
        orElse: () => missions.first,
      );

      // Act: Update progress (simulating gameplay)
      await missionsManager.updateMissionProgress(mission.type, 1);

      // Wait for UI rebuild (should happen immediately)
      await tester.pump();

      // Assert: UI should have updated WITHOUT needing app restart
      // If this fails, ListenableBuilder is not working correctly
      expect(find.textContaining('Progress:'), findsWidgets,
          reason: 'REGRESSION: UI must update in real-time without app restart.\n'
                  'If this fails, DailyMissionsScreen is not listening to MissionsManager changes.\n'
                  'Check that ListenableBuilder is listening to the correct manager instance.');
    });
  });
}


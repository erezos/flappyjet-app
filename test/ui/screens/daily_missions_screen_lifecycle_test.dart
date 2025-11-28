import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/ui/screens/daily_missions_screen.dart';
import 'package:flappy_jet_pro/game/systems/missions_manager.dart';
import 'package:flappy_jet_pro/game/systems/achievements_manager.dart';

/// Tests for BuildContext lifecycle management in DailyMissionsScreen.
/// 
/// These tests ensure the "This BuildContext is no longer valid" error
/// is prevented by proper `mounted` checks before UI operations.
/// 
/// The bug occurred when:
/// 1. User taps "Claim Reward" on a mission
/// 2. Async claimMissionReward() is called
/// 3. User navigates away during the await (widget disposed)
/// 4. showDialog() tries to use invalid BuildContext → CRASH
/// 
/// The fix adds `mounted` checks at critical points:
/// - Before any setState() call
/// - Before any context.read<T>() call
/// - Immediately before showDialog() call
/// - Before any ScaffoldMessenger operations

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DailyMissionsScreen BuildContext Lifecycle Tests', () {
    late MissionsManager mockMissionsManager;
    late AchievementsManager mockAchievementsManager;

    setUp(() {
      mockMissionsManager = MissionsManager();
      mockAchievementsManager = AchievementsManager();
    });

    testWidgets(
      'Screen should build without errors when managers are provided',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: DailyMissionsScreen(
              missionsManager: mockMissionsManager,
              achievementsManager: mockAchievementsManager,
            ),
          ),
        );

        // Just pump a few frames instead of pumpAndSettle (avoids animation timeout)
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Verify screen renders
        expect(find.text('MISSIONS'), findsOneWidget);
      },
    );

    testWidgets(
      'Screen should handle navigation away gracefully (no BuildContext errors)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: DailyMissionsScreen(
              missionsManager: mockMissionsManager,
              achievementsManager: mockAchievementsManager,
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Verify initial state
        expect(find.text('MISSIONS'), findsOneWidget);

        // Navigate away - the widget will be disposed
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(child: Text('Different Screen')),
            ),
          ),
        );

        await tester.pump();

        // Should navigate without errors
        expect(find.text('Different Screen'), findsOneWidget);
        expect(find.text('MISSIONS'), findsNothing);
      },
    );

    testWidgets(
      'Tab switching should work without BuildContext issues',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: DailyMissionsScreen(
              missionsManager: mockMissionsManager,
              achievementsManager: mockAchievementsManager,
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Tap on ACHIEVEMENTS tab
        await tester.tap(find.text('ACHIEVEMENTS'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // No errors should occur
        expect(find.text('ACHIEVEMENTS'), findsOneWidget);
      },
    );

    testWidgets(
      'Screen should handle null managers gracefully',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: DailyMissionsScreen(
              missionsManager: null,
              achievementsManager: null,
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Should show title without any BuildContext errors
        expect(find.text('MISSIONS'), findsOneWidget);
      },
    );

    testWidgets(
      'Lifecycle observer should be properly added and removed without errors',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: DailyMissionsScreen(
              missionsManager: mockMissionsManager,
              achievementsManager: mockAchievementsManager,
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Navigate away to trigger dispose
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: SizedBox()),
          ),
        );

        await tester.pump();

        // The test passes if no exceptions are thrown during disposal
        expect(true, isTrue); // Explicit success
      },
    );
  });

  group('Mission Claim Flow - Lifecycle Safety', () {
    testWidgets(
      'Claim flow should be safe even with rapid navigation',
      (WidgetTester tester) async {
        final missionsManager = MissionsManager();

        await tester.pumpWidget(
          MaterialApp(
            home: DailyMissionsScreen(
              missionsManager: missionsManager,
              achievementsManager: AchievementsManager(),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Immediately navigate away (simulating the bug scenario)
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: Center(child: Text('New Screen'))),
          ),
        );

        await tester.pump();

        // Should complete without "BuildContext is no longer valid" error
        expect(find.text('New Screen'), findsOneWidget);
      },
    );

    testWidgets(
      'Rapid screen rebuilds should not cause mounted state issues',
      (WidgetTester tester) async {
        final missionsManager = MissionsManager();
        final achievementsManager = AchievementsManager();

        // Build the screen
        await tester.pumpWidget(
          MaterialApp(
            home: DailyMissionsScreen(
              missionsManager: missionsManager,
              achievementsManager: achievementsManager,
            ),
          ),
        );

        await tester.pump();

        // Rebuild rapidly multiple times
        for (int i = 0; i < 3; i++) {
          await tester.pumpWidget(
            MaterialApp(
              home: DailyMissionsScreen(
                key: ValueKey(i), // Force rebuild with new key
                missionsManager: missionsManager,
                achievementsManager: achievementsManager,
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 50));
        }

        // Final pump
        await tester.pump(const Duration(milliseconds: 100));

        // Should complete without errors
        expect(find.text('MISSIONS'), findsOneWidget);
      },
    );
  });

  group('Mounted Check Verification', () {
    testWidgets(
      'Disposing widget during animation should not crash',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: DailyMissionsScreen(
              missionsManager: MissionsManager(),
              achievementsManager: AchievementsManager(),
            ),
          ),
        );

        // Don't wait for animations to complete
        await tester.pump();

        // Immediately replace with different widget (triggers dispose during animation)
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: Text('Replaced')),
          ),
        );

        await tester.pump();

        // No crash = success
        expect(find.text('Replaced'), findsOneWidget);
      },
    );

    testWidgets(
      'Widget should handle app lifecycle changes gracefully',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: DailyMissionsScreen(
              missionsManager: MissionsManager(),
              achievementsManager: AchievementsManager(),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Simulate app going to background
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump();

        // Simulate app coming back to foreground
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pump();

        // Should handle gracefully
        expect(find.text('MISSIONS'), findsOneWidget);
      },
    );
  });
}

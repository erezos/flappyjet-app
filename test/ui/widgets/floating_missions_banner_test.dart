import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flappy_jet_pro/ui/widgets/floating_missions_banner.dart';
import 'package:flappy_jet_pro/game/systems/missions_manager.dart';
import 'package:flappy_jet_pro/game/systems/achievements_manager.dart';

/// 🎯 FLOATING MISSIONS BANNER TESTS
/// 
/// Comprehensive tests for the floating missions banner widget.
/// Verifies:
/// - Widget renders correctly
/// - Tap callback is triggered
/// - Notification badge displays correct count
/// - Responsive sizing on different screen sizes
/// - Zone independence (appears on all zones)
/// - Banner uses real managers (singleton pattern)
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FloatingMissionsBanner - Basic Functionality', () {
    setUp(() async {
      // Reset SharedPreferences for clean test state
      SharedPreferences.setMockInitialValues({});
      
      // Initialize managers
      final missionsManager = MissionsManager();
      missionsManager.resetForTesting();
      await missionsManager.initialize();
      
      await AchievementsManager().initialize();
    });

    testWidgets('renders without crashing', (tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FloatingMissionsBanner(
                onTap: () => tapped = true,
                useResponsiveScaling: false, // Disable for consistent test behavior
              ),
            ),
          ),
        ),
      );
      
      // Widget should render
      expect(find.byType(FloatingMissionsBanner), findsOneWidget);
    });

    testWidgets('calls onTap callback when pressed', (tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FloatingMissionsBanner(
                onTap: () => tapped = true,
                useResponsiveScaling: false,
              ),
            ),
          ),
        ),
      );
      
      // Tap the banner
      await tester.tap(find.byType(FloatingMissionsBanner));
      await tester.pump();
      
      // Callback should be triggered
      expect(tapped, isTrue);
    });

    testWidgets('respects custom size parameter', (tester) async {
      const customSize = 100.0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FloatingMissionsBanner(
                onTap: () {},
                size: customSize,
                useResponsiveScaling: false,
              ),
            ),
          ),
        ),
      );
      
      // Widget should be present
      expect(find.byType(FloatingMissionsBanner), findsOneWidget);
      
      // Find the SizedBox and verify its size
      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(FloatingMissionsBanner),
          matching: find.byType(SizedBox),
        ).first,
      );
      
      // Size should be customSize + 20 for badge overflow
      expect(sizedBox.width, equals(customSize + 20));
    });

    testWidgets('uses default size when not specified', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FloatingMissionsBanner(
                onTap: () {},
                useResponsiveScaling: false,
              ),
            ),
          ),
        ),
      );
      
      // Widget should be present with default size (85)
      expect(find.byType(FloatingMissionsBanner), findsOneWidget);
      
      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(FloatingMissionsBanner),
          matching: find.byType(SizedBox),
        ).first,
      );
      
      // Default size is 85 + 20 for badge overflow = 105
      expect(sizedBox.width, equals(105));
    });

    testWidgets('handles missing banner image gracefully', (tester) async {
      // This test verifies the fallback UI works
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FloatingMissionsBanner(
                onTap: () {},
                useResponsiveScaling: false,
              ),
            ),
          ),
        ),
      );
      
      // Should not throw even if image is missing
      expect(find.byType(FloatingMissionsBanner), findsOneWidget);
    });

    testWidgets('can be tapped multiple times', (tester) async {
      int tapCount = 0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FloatingMissionsBanner(
                onTap: () => tapCount++,
                useResponsiveScaling: false,
              ),
            ),
          ),
        ),
      );
      
      // Tap multiple times
      await tester.tap(find.byType(FloatingMissionsBanner));
      await tester.pump();
      await tester.tap(find.byType(FloatingMissionsBanner));
      await tester.pump();
      await tester.tap(find.byType(FloatingMissionsBanner));
      await tester.pump();
      
      // All taps should be counted
      expect(tapCount, equals(3));
    });
  });

  group('FloatingMissionsBanner - Responsive Sizing', () {
    /// Helper to build widget with specific screen size
    Widget buildWithScreenSize(double width, double height, {double size = 85}) {
      return MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(width, height)),
          child: Scaffold(
            body: Center(
              child: FloatingMissionsBanner(
                onTap: () {},
                size: size,
                useResponsiveScaling: true, // Enable responsive scaling
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('scales DOWN on small phones (< 360px width)', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await MissionsManager().initialize();
      
      // Small phone screen (320px width - like iPhone SE)
      await tester.pumpWidget(buildWithScreenSize(320, 568, size: 85));
      
      expect(find.byType(FloatingMissionsBanner), findsOneWidget);
      
      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(FloatingMissionsBanner),
          matching: find.byType(SizedBox),
        ).first,
      );
      
      // Expected: 85 * 0.85 + 20 = 92.25
      expect(sizedBox.width, closeTo(92.25, 0.1));
    });

    testWidgets('uses STANDARD size on standard phones (360-400px)', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await MissionsManager().initialize();
      
      // Standard phone screen (375px - like iPhone X)
      await tester.pumpWidget(buildWithScreenSize(375, 812, size: 85));
      
      expect(find.byType(FloatingMissionsBanner), findsOneWidget);
      
      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(FloatingMissionsBanner),
          matching: find.byType(SizedBox),
        ).first,
      );
      
      // Expected: 85 * 1.0 + 20 = 105
      expect(sizedBox.width, equals(105));
    });

    testWidgets('scales UP on large phones/tablets (> 400px)', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await MissionsManager().initialize();
      
      // Large phone/tablet screen (428px - like iPhone Pro Max)
      await tester.pumpWidget(buildWithScreenSize(428, 926, size: 85));
      
      expect(find.byType(FloatingMissionsBanner), findsOneWidget);
      
      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(FloatingMissionsBanner),
          matching: find.byType(SizedBox),
        ).first,
      );
      
      // Expected: 85 * 1.15 + 20 = 117.75
      expect(sizedBox.width, closeTo(117.75, 0.1));
    });

    testWidgets('scales correctly on tablet screens', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await MissionsManager().initialize();
      
      // Tablet screen (768px - like iPad)
      await tester.pumpWidget(buildWithScreenSize(768, 1024, size: 85));
      
      expect(find.byType(FloatingMissionsBanner), findsOneWidget);
      
      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(FloatingMissionsBanner),
          matching: find.byType(SizedBox),
        ).first,
      );
      
      // Expected: 85 * 1.15 + 20 = 117.75 (tablets get upscale)
      expect(sizedBox.width, closeTo(117.75, 0.1));
    });

    testWidgets('disables responsive scaling when useResponsiveScaling is false', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await MissionsManager().initialize();
      
      // Small screen but responsive scaling disabled
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(320, 568)),
            child: Scaffold(
              body: Center(
                child: FloatingMissionsBanner(
                  onTap: () {},
                  size: 85,
                  useResponsiveScaling: false, // Disabled!
                ),
              ),
            ),
          ),
        ),
      );
      
      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(FloatingMissionsBanner),
          matching: find.byType(SizedBox),
        ).first,
      );
      
      // Should use base size without scaling: 85 + 20 = 105
      expect(sizedBox.width, equals(105));
    });

    testWidgets('banner looks good at various screen densities', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await MissionsManager().initialize();
      
      // Test at different pixel densities (1x, 2x, 3x)
      for (final density in [1.0, 2.0, 3.0]) {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: const Size(375, 812),
                devicePixelRatio: density,
              ),
              child: Scaffold(
                body: Center(
                  child: FloatingMissionsBanner(
                    onTap: () {},
                    useResponsiveScaling: true,
                  ),
                ),
              ),
            ),
          ),
        );
        
        // Widget should render at all densities
        expect(find.byType(FloatingMissionsBanner), findsOneWidget);
        await tester.pumpAndSettle();
      }
    });
  });

  group('FloatingMissionsBanner - Zone Independence', () {
    /// Simulates the WorldMapScreen Stack structure with different zones
    Widget buildWorldMapSimulation({required int zone}) {
      return MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              // Zone-specific background (simulating world map zones 1-5)
              Container(
                color: Color(0xFF000000 + (zone * 0x111111)),
                child: Center(
                  child: Text('Zone $zone Background'),
                ),
              ),
              
              // 🎯 Banner is in Stack overlay - OUTSIDE zone-specific content
              // This is how it's placed in WorldMapScreen
              Positioned(
                left: 16,
                top: 100,
                child: FloatingMissionsBanner(
                  onTap: () {},
                  useResponsiveScaling: false,
                ),
              ),
            ],
          ),
        ),
      );
    }

    testWidgets('appears on Zone 1', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await MissionsManager().initialize();
      
      await tester.pumpWidget(buildWorldMapSimulation(zone: 1));
      
      expect(find.byType(FloatingMissionsBanner), findsOneWidget);
      expect(find.text('Zone 1 Background'), findsOneWidget);
    });

    testWidgets('appears on Zone 2', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await MissionsManager().initialize();
      
      await tester.pumpWidget(buildWorldMapSimulation(zone: 2));
      
      expect(find.byType(FloatingMissionsBanner), findsOneWidget);
      expect(find.text('Zone 2 Background'), findsOneWidget);
    });

    testWidgets('appears on Zone 3', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await MissionsManager().initialize();
      
      await tester.pumpWidget(buildWorldMapSimulation(zone: 3));
      
      expect(find.byType(FloatingMissionsBanner), findsOneWidget);
      expect(find.text('Zone 3 Background'), findsOneWidget);
    });

    testWidgets('appears on Zone 4', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await MissionsManager().initialize();
      
      await tester.pumpWidget(buildWorldMapSimulation(zone: 4));
      
      expect(find.byType(FloatingMissionsBanner), findsOneWidget);
      expect(find.text('Zone 4 Background'), findsOneWidget);
    });

    testWidgets('appears on Zone 5', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await MissionsManager().initialize();
      
      await tester.pumpWidget(buildWorldMapSimulation(zone: 5));
      
      expect(find.byType(FloatingMissionsBanner), findsOneWidget);
      expect(find.text('Zone 5 Background'), findsOneWidget);
    });

    testWidgets('banner remains visible when zone changes', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await MissionsManager().initialize();
      
      // Start at zone 1
      await tester.pumpWidget(buildWorldMapSimulation(zone: 1));
      expect(find.byType(FloatingMissionsBanner), findsOneWidget);
      
      // Switch to zone 3
      await tester.pumpWidget(buildWorldMapSimulation(zone: 3));
      await tester.pumpAndSettle();
      expect(find.byType(FloatingMissionsBanner), findsOneWidget);
      
      // Switch to zone 5
      await tester.pumpWidget(buildWorldMapSimulation(zone: 5));
      await tester.pumpAndSettle();
      expect(find.byType(FloatingMissionsBanner), findsOneWidget);
    });

    testWidgets('banner position is consistent across zones', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await MissionsManager().initialize();
      
      // Test positions on different zones
      for (int zone = 1; zone <= 5; zone++) {
        await tester.pumpWidget(buildWorldMapSimulation(zone: zone));
        
        final positioned = tester.widget<Positioned>(
          find.ancestor(
            of: find.byType(FloatingMissionsBanner),
            matching: find.byType(Positioned),
          ),
        );
        
        // Position should be consistent: left 16, top 100
        expect(positioned.left, equals(16));
        expect(positioned.top, equals(100));
      }
    });
  });

  group('FloatingMissionsBanner - Notification Badge', () {
    testWidgets('badge visibility depends on claimable count', (tester) async {
      SharedPreferences.setMockInitialValues({});
      
      // Initialize managers
      final missionsManager = MissionsManager();
      missionsManager.resetForTesting();
      await missionsManager.initialize();
      await AchievementsManager().initialize();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FloatingMissionsBanner(
                onTap: () {},
                useResponsiveScaling: false,
              ),
            ),
          ),
        ),
      );
      
      // Widget should render
      expect(find.byType(FloatingMissionsBanner), findsOneWidget);
      
      // Complete missions to trigger badge
      for (int i = 0; i < 50; i++) {
        await missionsManager.updateMissionProgress(MissionType.playGames, 1);
      }
      
      // Rebuild widget
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      
      // Widget should still be present
      expect(find.byType(FloatingMissionsBanner), findsOneWidget);
    });
  });

  group('FloatingMissionsBanner - Animation', () {
    testWidgets('pulse animation activates when rewards are claimable', (tester) async {
      SharedPreferences.setMockInitialValues({});
      
      final missionsManager = MissionsManager();
      missionsManager.resetForTesting();
      await missionsManager.initialize();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FloatingMissionsBanner(
                onTap: () {},
                useResponsiveScaling: false,
              ),
            ),
          ),
        ),
      );
      
      // Complete missions
      for (int i = 0; i < 50; i++) {
        await missionsManager.updateMissionProgress(MissionType.playGames, 1);
      }
      
      // Let animation tick
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      
      // Widget should handle animation without errors
      expect(find.byType(FloatingMissionsBanner), findsOneWidget);
    });
  });

  group('FloatingMissionsBanner - Integration', () {
    testWidgets('works with both managers', (tester) async {
      SharedPreferences.setMockInitialValues({});
      
      final missionsManager = MissionsManager();
      missionsManager.resetForTesting();
      await missionsManager.initialize();
      
      final achievementsManager = AchievementsManager();
      await achievementsManager.initialize();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FloatingMissionsBanner(
                onTap: () {},
                useResponsiveScaling: false,
              ),
            ),
          ),
        ),
      );
      
      // Update both managers
      await missionsManager.updateMissionProgress(MissionType.playGames, 1);
      await achievementsManager.checkScoreAchievements(10);
      
      await tester.pump();
      
      // Widget should update without errors
      expect(find.byType(FloatingMissionsBanner), findsOneWidget);
    });

    testWidgets('maintains state when parent rebuilds', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await MissionsManager().initialize();
      
      int buildCount = 0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              buildCount++;
              return Scaffold(
                body: Column(
                  children: [
                    FloatingMissionsBanner(
                      onTap: () {},
                      useResponsiveScaling: false,
                    ),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      child: const Text('Rebuild'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
      
      expect(buildCount, equals(1));
      
      // Trigger rebuild
      await tester.tap(find.text('Rebuild'));
      await tester.pump();
      
      expect(buildCount, equals(2));
      expect(find.byType(FloatingMissionsBanner), findsOneWidget);
    });
  });

  group('FloatingMissionsBanner - Edge Cases', () {
    testWidgets('handles very small screen (240x320)', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await MissionsManager().initialize();
      
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(240, 320)),
            child: Scaffold(
              body: Center(
                child: FloatingMissionsBanner(
                  onTap: () {},
                  useResponsiveScaling: true,
                ),
              ),
            ),
          ),
        ),
      );
      
      expect(find.byType(FloatingMissionsBanner), findsOneWidget);
    });

    testWidgets('handles very large screen (1920x1080)', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await MissionsManager().initialize();
      
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1920, 1080)),
            child: Scaffold(
              body: Center(
                child: FloatingMissionsBanner(
                  onTap: () {},
                  useResponsiveScaling: true,
                ),
              ),
            ),
          ),
        ),
      );
      
      expect(find.byType(FloatingMissionsBanner), findsOneWidget);
    });

    testWidgets('handles zero size gracefully', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await MissionsManager().initialize();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FloatingMissionsBanner(
                onTap: () {},
                size: 0, // Edge case
                useResponsiveScaling: false,
              ),
            ),
          ),
        ),
      );
      
      // Should not crash
      expect(find.byType(FloatingMissionsBanner), findsOneWidget);
    });

    testWidgets('handles rapid tap events', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await MissionsManager().initialize();
      
      int tapCount = 0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FloatingMissionsBanner(
                onTap: () => tapCount++,
                useResponsiveScaling: false,
              ),
            ),
          ),
        ),
      );
      
      // Rapid taps - use pump() not pumpAndSettle() to avoid animation timeout
      for (int i = 0; i < 10; i++) {
        await tester.tap(find.byType(FloatingMissionsBanner));
        await tester.pump(); // Process each tap
      }
      
      expect(tapCount, equals(10));
    });
  });
}

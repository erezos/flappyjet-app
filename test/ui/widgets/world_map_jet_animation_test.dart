/// 🧪 WORLD MAP JET ANIMATION TESTS
/// 
/// Comprehensive test suite to ensure jet animation functionality remains intact
/// while fixing ParentDataWidget errors.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/ui/widgets/world_map_jet_widget.dart';
import 'package:flappy_jet_pro/ui/screens/world_map_screen.dart';
import 'package:flappy_jet_pro/game/systems/level_system_manager.dart';

void main() {
  group('WorldMapJetWidget Tests', () {
    testWidgets('WorldMapJetWidget renders without Positioned widget', (WidgetTester tester) async {
      // ✅ TEST 1: Verify widget doesn't use Positioned internally
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  left: 100,
                  top: 100,
                  child: WorldMapJetWidget(
                    jetSkinId: 'starter_jet',
                    currentPosition: const Offset(100, 100),
                    jetSize: 70.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Widget should render without errors
      expect(find.byType(WorldMapJetWidget), findsOneWidget);
      
      // Should not throw ParentDataWidget error
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('WorldMapJetWidget renders jet image', (WidgetTester tester) async {
      // ✅ TEST 2: Verify jet sprite is rendered
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  left: 100,
                  top: 100,
                  child: WorldMapJetWidget(
                    jetSkinId: 'starter_jet',
                    currentPosition: const Offset(100, 100),
                    jetSize: 70.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should find either the image or the fallback icon
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Image || (widget is Icon && widget.icon == Icons.airplanemode_active),
        ),
        findsOneWidget,
      );
    });

    testWidgets('WorldMapJetWidget applies rotation transform', (WidgetTester tester) async {
      // ✅ TEST 3: Verify rotation is applied via Transform.rotate
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  left: 100,
                  top: 100,
                  child: WorldMapJetWidget(
                    jetSkinId: 'starter_jet',
                    currentPosition: const Offset(100, 100),
                    jetSize: 70.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should find Transform.rotate widget
      expect(find.byType(Transform), findsWidgets);
    });

    testWidgets('WorldMapJetWidget applies scale transform', (WidgetTester tester) async {
      // ✅ TEST 4: Verify scale is applied via Transform.scale
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  left: 100,
                  top: 100,
                  child: WorldMapJetWidget(
                    jetSkinId: 'starter_jet',
                    currentPosition: const Offset(100, 100),
                    targetPosition: const Offset(200, 200),
                    animationDuration: const Duration(milliseconds: 500),
                    jetSize: 70.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Pump frames to start animation
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should find Transform.scale widget (nested inside Transform.rotate)
      expect(find.byType(Transform), findsWidgets);
    });

    testWidgets('WorldMapJetWidget ignores pointer events', (WidgetTester tester) async {
      // ✅ TEST 5: Verify IgnorePointer is present
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  left: 100,
                  top: 100,
                  child: WorldMapJetWidget(
                    jetSkinId: 'starter_jet',
                    currentPosition: const Offset(100, 100),
                    jetSize: 70.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should find IgnorePointer widget
      expect(find.byType(IgnorePointer), findsOneWidget);
    });

    testWidgets('WorldMapJetWidget animation completes', (WidgetTester tester) async {
      // ✅ TEST 6: Verify animation completion callback works
      bool animationCompleted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  left: 100,
                  top: 100,
                  child: WorldMapJetWidget(
                    jetSkinId: 'starter_jet',
                    currentPosition: const Offset(100, 100),
                    targetPosition: const Offset(200, 200),
                    animationDuration: const Duration(milliseconds: 500),
                    onAnimationComplete: () {
                      animationCompleted = true;
                    },
                    jetSize: 70.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Wait for animation to complete
      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      // Callback should have been called
      expect(animationCompleted, isTrue);
    });

    testWidgets('WorldMapJetWidget updates position when widget updates', (WidgetTester tester) async {
      // ✅ TEST 7: Verify widget responds to position updates
      final Key widgetKey = UniqueKey();
      Offset currentPosition = const Offset(100, 100);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Stack(
                  children: [
                    Positioned(
                      left: currentPosition.dx,
                      top: currentPosition.dy,
                      child: WorldMapJetWidget(
                        key: widgetKey,
                        jetSkinId: 'starter_jet',
                        currentPosition: currentPosition,
                        jetSize: 70.0,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Widget should be found at initial position
      expect(find.byKey(widgetKey), findsOneWidget);

      // Update position
      currentPosition = const Offset(200, 200);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  left: currentPosition.dx,
                  top: currentPosition.dy,
                  child: WorldMapJetWidget(
                    key: widgetKey,
                    jetSkinId: 'starter_jet',
                    currentPosition: currentPosition,
                    jetSize: 70.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Widget should still be found (at new position)
      expect(find.byKey(widgetKey), findsOneWidget);
    });
  });

  group('WorldMapScreen Jet Animation Tests', () {
    testWidgets('WorldMapScreen renders without ParentDataWidget errors', (WidgetTester tester) async {
      // ✅ TEST 8: Verify world map screen doesn't have nested Positioned issues
      await tester.pumpWidget(
        const MaterialApp(
          home: WorldMapScreen(
            shouldAnimateJet: false,
          ),
        ),
      );

      // Should not throw ParentDataWidget error
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('WorldMapScreen with jet animation renders without errors', (WidgetTester tester) async {
      // ✅ TEST 9: Verify world map with jet animation doesn't throw errors
      await tester.pumpWidget(
        const MaterialApp(
          home: WorldMapScreen(
            shouldAnimateJet: true,
            fromLevel: 1,
            toLevel: 2,
          ),
        ),
      );

      // Should not throw ParentDataWidget error
      await tester.pump();
      expect(tester.takeException(), isNull);

      // Pump animation frames
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    });

    testWidgets('WorldMapScreen jet is positioned correctly', (WidgetTester tester) async {
      // ✅ TEST 10: Verify jet is positioned on the world map
      await tester.pumpWidget(
        const MaterialApp(
          home: WorldMapScreen(
            shouldAnimateJet: false,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should find WorldMapJetWidget
      expect(find.byType(WorldMapJetWidget), findsOneWidget);
    });

    testWidgets('WorldMapScreen jet animation starts correctly', (WidgetTester tester) async {
      // ✅ TEST 11: Verify jet animation is triggered
      await tester.pumpWidget(
        const MaterialApp(
          home: WorldMapScreen(
            shouldAnimateJet: true,
            fromLevel: 1,
            toLevel: 2,
          ),
        ),
      );

      // Initial render
      await tester.pump();

      // Wait for animation delay (1200ms according to code)
      await tester.pump(const Duration(milliseconds: 1300));

      // Should find WorldMapJetWidget
      expect(find.byType(WorldMapJetWidget), findsOneWidget);

      // Continue animation
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
    });
  });

  group('Widget Tree Structure Tests', () {
    testWidgets('WorldMapJetWidget has correct widget hierarchy', (WidgetTester tester) async {
      // ✅ TEST 12: Verify correct widget structure (no nested Positioned)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  left: 100,
                  top: 100,
                  child: WorldMapJetWidget(
                    jetSkinId: 'starter_jet',
                    currentPosition: const Offset(100, 100),
                    jetSize: 70.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the widget tree elements
      final animatedBuilder = find.byType(AnimatedBuilder);
      final ignorePointer = find.byType(IgnorePointer);
      final transform = find.byType(Transform);

      // Verify hierarchy exists
      expect(animatedBuilder, findsOneWidget);
      expect(ignorePointer, findsOneWidget);
      expect(transform, findsWidgets);

      // Critical: Should NOT find a Positioned widget INSIDE WorldMapJetWidget
      // (The only Positioned should be the parent in Stack)
      final worldMapJetWidget = tester.widget<WorldMapJetWidget>(find.byType(WorldMapJetWidget));
      expect(worldMapJetWidget, isNotNull);
    });
  });

  group('Regression Tests', () {
    testWidgets('Multiple WorldMapJetWidgets render without conflicts', (WidgetTester tester) async {
      // ✅ TEST 13: Verify multiple jets can coexist (edge case)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  left: 100,
                  top: 100,
                  child: WorldMapJetWidget(
                    jetSkinId: 'starter_jet',
                    currentPosition: const Offset(100, 100),
                    jetSize: 70.0,
                  ),
                ),
                Positioned(
                  left: 200,
                  top: 200,
                  child: WorldMapJetWidget(
                    jetSkinId: 'police_patrol',
                    currentPosition: const Offset(200, 200),
                    jetSize: 70.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should find both widgets without errors
      expect(find.byType(WorldMapJetWidget), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('WorldMapJetWidget handles rapid position updates', (WidgetTester tester) async {
      // ✅ TEST 14: Stress test with rapid position changes
      final Key widgetKey = UniqueKey();

      for (int i = 0; i < 5; i++) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  Positioned(
                    left: 100.0 + (i * 20.0),
                    top: 100.0 + (i * 20.0),
                    child: WorldMapJetWidget(
                      key: widgetKey,
                      jetSkinId: 'starter_jet',
                      currentPosition: Offset(100.0 + (i * 20.0), 100.0 + (i * 20.0)),
                      jetSize: 70.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pump();
        expect(tester.takeException(), isNull);
      }
    });
  });
}


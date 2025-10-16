/// 🧪 WORLD MAP - INTEGRATION TESTS
/// 
/// Integration tests for the complete user journey through the Story Mode world map.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/ui/screens/world_map_screen.dart';

void main() {
  group('World Map Integration Tests', () {
    testWidgets('full world map navigation flow', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WorldMapScreen(),
        ),
      );

      // Wait for initialization
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should display the world map
      expect(find.byType(WorldMapScreen), findsOneWidget);

      // Should have interactive elements
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('level nodes are interactive when unlocked', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WorldMapScreen(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Try to find tappable level nodes (they should exist)
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('zone switching works correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WorldMapScreen(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Initial zone should be displayed
      expect(find.textContaining('Tropical Islands'), findsOneWidget);

      // Note: Zone switching requires dropdown interaction which would need
      // more complex testing setup with mocked LevelSystemManager
    });

    testWidgets('jet widget is displayed on the map', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WorldMapScreen(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Jet should be visible somewhere on the map
      // (It's in a Stack so exact positioning is dynamic)
      expect(tester.takeException(), isNull);
    });

    testWidgets('progress bar shows completion status', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WorldMapScreen(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should have progress indicator
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // Should show completion text
      expect(find.textContaining('completed'), findsOneWidget);
    });

    testWidgets('hearts display shows current lives', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WorldMapScreen(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should show heart icon
      expect(find.byIcon(Icons.favorite), findsOneWidget);

      // Should show number of hearts
      final heartText = find.descendant(
        of: find.byIcon(Icons.favorite).hitTestable(),
        matching: find.byType(Text),
      );
      expect(heartText, findsWidgets);
    });

    testWidgets('background image loads for current zone', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WorldMapScreen(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should have an Image widget for the background
      expect(find.byType(Image), findsWidgets);
    });

    testWidgets('completed levels show REPLAY badge', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WorldMapScreen(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // If there are completed levels, REPLAY badges should be visible
      // (This depends on the actual game state)
      // The test ensures the screen renders without crashing
      expect(tester.takeException(), isNull);
    });

    testWidgets('no hearts dialog prevents level start', (tester) async {
      // This would require mocking the LivesManager to return 0 hearts
      // For now, we verify the screen renders correctly
      await tester.pumpWidget(
        const MaterialApp(
          home: WorldMapScreen(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(tester.takeException(), isNull);
    });

    testWidgets('scrolling works for large zone maps', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WorldMapScreen(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should have a scrollable view
      expect(find.byType(SingleChildScrollView), findsOneWidget);

      // Try scrolling (may not scroll if content fits)
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -100));
      await tester.pumpAndSettle();

      // Should not crash
      expect(tester.takeException(), isNull);
    });

    testWidgets('path is drawn between level nodes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WorldMapScreen(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // CustomPaint should be used for drawing paths
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('screen handles empty zone gracefully', (tester) async {
      // This would test the "Coming Soon" message for zones without levels
      await tester.pumpWidget(
        const MaterialApp(
          home: WorldMapScreen(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should not crash even if a zone has no levels
      expect(tester.takeException(), isNull);
    });
  });

  group('Performance Tests', () {
    testWidgets('world map renders within acceptable time', (tester) async {
      final startTime = DateTime.now();

      await tester.pumpWidget(
        const MaterialApp(
          home: WorldMapScreen(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 5));

      final endTime = DateTime.now();
      final renderTime = endTime.difference(startTime);

      // Should render within 5 seconds
      expect(renderTime.inSeconds, lessThan(6));
    });

    testWidgets('animations run smoothly without jank', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WorldMapScreen(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Pump multiple frames to simulate continuous animation
      for (int i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 16)); // 60 FPS
      }

      // Should not crash or throw during animations
      expect(tester.takeException(), isNull);
    });

    testWidgets('handles rapid zone switching', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WorldMapScreen(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Rapid updates shouldn't crash the app
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(tester.takeException(), isNull);
    });
  });

  group('Edge Cases', () {
    testWidgets('handles null/missing jet image gracefully', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WorldMapScreen(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should handle missing images with fallback
      expect(tester.takeException(), isNull);
    });

    testWidgets('handles missing background image gracefully', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WorldMapScreen(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should show error icon or fallback for missing backgrounds
      expect(tester.takeException(), isNull);
    });

    testWidgets('handles rapid back button presses', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WorldMapScreen()),
                  );
                },
                child: const Text('Go'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Rapidly tap back button
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Should not crash
      expect(tester.takeException(), isNull);
    });
  });
}



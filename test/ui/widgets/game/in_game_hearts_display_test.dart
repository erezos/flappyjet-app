/// ❤️ IN-GAME HEARTS DISPLAY TESTS
/// 
/// Comprehensive tests for the InGameHeartsDisplay widget.
/// Verifies:
/// - Both LivesManager and custom hearts modes
/// - Responsive sizing for different screen sizes
/// - Dynamic sizing for 3-6 hearts (Heart Booster support)
/// - Visual consistency across game modes
/// - Background container option
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flappy_jet_pro/ui/widgets/game/in_game_hearts_display.dart';
import 'package:flappy_jet_pro/game/systems/lives_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InGameHeartsDisplay - LivesManager Mode', () {
    setUp(() async {
      // Reset SharedPreferences for clean test state
      SharedPreferences.setMockInitialValues({});
      await LivesManager().initialize();
    });

    testWidgets('renders correctly with LivesManager', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InGameHeartsDisplay(),
            ),
          ),
        ),
      );

      // Should render heart icons
      expect(find.byIcon(Icons.favorite), findsWidgets);
    });

    testWidgets('shows correct number of hearts from LivesManager', (tester) async {
      final livesManager = LivesManager();
      final maxHearts = livesManager.maxLives;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InGameHeartsDisplay(),
            ),
          ),
        ),
      );

      // Should show maxHearts number of heart icons
      expect(find.byIcon(Icons.favorite), findsNWidgets(maxHearts));
    });

    testWidgets('updates when LivesManager changes', (tester) async {
      final livesManager = LivesManager();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InGameHeartsDisplay(),
            ),
          ),
        ),
      );

      // Initial state
      final initialHearts = livesManager.currentLives;
      expect(find.byIcon(Icons.favorite), findsNWidgets(livesManager.maxLives));

      // Consume a life
      if (initialHearts > 0) {
        await livesManager.consumeLife();
        await tester.pump();
        
        // Should still show same number of icons (some will be faded)
        expect(find.byIcon(Icons.favorite), findsNWidgets(livesManager.maxLives));
      }
    });
  });

  group('InGameHeartsDisplay - Custom Hearts Mode', () {
    testWidgets('renders correctly with custom values', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InGameHeartsDisplay.custom(
                currentHearts: 2,
                maxHearts: 3,
              ),
            ),
          ),
        ),
      );

      // Should render 3 heart icons (max)
      expect(find.byIcon(Icons.favorite), findsNWidgets(3));
    });

    testWidgets('shows all hearts filled when currentHearts equals maxHearts', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InGameHeartsDisplay.custom(
                currentHearts: 3,
                maxHearts: 3,
              ),
            ),
          ),
        ),
      );

      // All 3 hearts should be filled (redAccent color)
      final heartIcons = tester.widgetList<Icon>(find.byIcon(Icons.favorite));
      for (final icon in heartIcons) {
        expect(icon.color, equals(Colors.redAccent));
      }
    });

    testWidgets('shows some hearts empty when currentHearts less than maxHearts', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InGameHeartsDisplay.custom(
                currentHearts: 1,
                maxHearts: 3,
              ),
            ),
          ),
        ),
      );

      // Should have 3 heart icons total
      final heartIcons = tester.widgetList<Icon>(find.byIcon(Icons.favorite)).toList();
      expect(heartIcons.length, equals(3));

      // First heart should be filled (red)
      expect(heartIcons[0].color, equals(Colors.redAccent));

      // Other hearts should be faded (alpha 0.25)
      expect(heartIcons[1].color, equals(Colors.redAccent.withValues(alpha: 0.25)));
      expect(heartIcons[2].color, equals(Colors.redAccent.withValues(alpha: 0.25)));
    });

    testWidgets('shows all hearts empty when currentHearts is 0', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InGameHeartsDisplay.custom(
                currentHearts: 0,
                maxHearts: 3,
              ),
            ),
          ),
        ),
      );

      // All hearts should be faded
      final heartIcons = tester.widgetList<Icon>(find.byIcon(Icons.favorite));
      for (final icon in heartIcons) {
        expect(icon.color, equals(Colors.redAccent.withValues(alpha: 0.25)));
      }
    });
  });

  group('InGameHeartsDisplay - Heart Booster Support (6 Hearts)', () {
    testWidgets('renders 6 hearts correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InGameHeartsDisplay.custom(
                currentHearts: 4,
                maxHearts: 6,
              ),
            ),
          ),
        ),
      );

      // Should render 6 heart icons
      expect(find.byIcon(Icons.favorite), findsNWidgets(6));
    });

    testWidgets('6 hearts have smaller size for better fit', (tester) async {
      // Build with 3 hearts first
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(375, 812)),
            child: Scaffold(
              body: Center(
                child: InGameHeartsDisplay.custom(
                  currentHearts: 3,
                  maxHearts: 3,
                ),
              ),
            ),
          ),
        ),
      );

      final threeHeartIcons = tester.widgetList<Icon>(find.byIcon(Icons.favorite)).toList();
      final threeHeartSize = threeHeartIcons.first.size ?? 0;

      // Build with 6 hearts
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(375, 812)),
            child: Scaffold(
              body: Center(
                child: InGameHeartsDisplay.custom(
                  currentHearts: 4,
                  maxHearts: 6,
                ),
              ),
            ),
          ),
        ),
      );

      final sixHeartIcons = tester.widgetList<Icon>(find.byIcon(Icons.favorite)).toList();
      final sixHeartSize = sixHeartIcons.first.size ?? 0;

      // 6 hearts should be smaller than 3 hearts
      expect(sixHeartSize, lessThan(threeHeartSize));
    });

    testWidgets('handles 4 and 5 hearts (intermediate sizes)', (tester) async {
      // Test 4 hearts
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InGameHeartsDisplay.custom(
                currentHearts: 2,
                maxHearts: 4,
              ),
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.favorite), findsNWidgets(4));

      // Test 5 hearts
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InGameHeartsDisplay.custom(
                currentHearts: 3,
                maxHearts: 5,
              ),
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.favorite), findsNWidgets(5));
    });
  });

  group('InGameHeartsDisplay - Responsive Sizing', () {
    /// Helper to build widget with specific screen size
    Widget buildWithScreenSize(double width, double height, {int currentHearts = 2, int maxHearts = 3}) {
      return MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(width, height)),
          child: Scaffold(
            body: Center(
              child: InGameHeartsDisplay.custom(
                currentHearts: currentHearts,
                maxHearts: maxHearts,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('scales correctly on small phone (320px width)', (tester) async {
      await tester.pumpWidget(buildWithScreenSize(320, 568));
      expect(find.byType(InGameHeartsDisplay), findsOneWidget);
      
      final heartIcons = tester.widgetList<Icon>(find.byIcon(Icons.favorite)).toList();
      final heartSize = heartIcons.first.size;
      
      // Hearts should be smaller on small screens (scale factor < 1)
      expect(heartSize, lessThanOrEqualTo(26.0)); // Base size or smaller
    });

    testWidgets('scales correctly on standard phone (375px width)', (tester) async {
      await tester.pumpWidget(buildWithScreenSize(375, 812));
      expect(find.byType(InGameHeartsDisplay), findsOneWidget);
      
      final heartIcons = tester.widgetList<Icon>(find.byIcon(Icons.favorite)).toList();
      final heartSize = heartIcons.first.size;
      
      // Hearts should be at base size on reference screen
      expect(heartSize, equals(26.0)); // Base size for 3 hearts
    });

    testWidgets('scales correctly on large phone (428px width)', (tester) async {
      await tester.pumpWidget(buildWithScreenSize(428, 926));
      expect(find.byType(InGameHeartsDisplay), findsOneWidget);
      
      final heartIcons = tester.widgetList<Icon>(find.byIcon(Icons.favorite)).toList();
      final heartSize = heartIcons.first.size;
      
      // Hearts should be larger on large screens (scale factor > 1)
      expect(heartSize, greaterThanOrEqualTo(26.0));
    });

    testWidgets('scales correctly on tablet (768px width)', (tester) async {
      await tester.pumpWidget(buildWithScreenSize(768, 1024));
      expect(find.byType(InGameHeartsDisplay), findsOneWidget);
      
      final heartIcons = tester.widgetList<Icon>(find.byIcon(Icons.favorite)).toList();
      final heartSize = heartIcons.first.size;
      
      // Hearts should be capped at max size on very large screens
      expect(heartSize, lessThanOrEqualTo(32.0)); // Max clamp value
    });
  });

  group('InGameHeartsDisplay - Background Container', () {
    testWidgets('no background container by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InGameHeartsDisplay.custom(
                currentHearts: 2,
                maxHearts: 3,
              ),
            ),
          ),
        ),
      );

      // Should not have a Container with decoration (background)
      expect(
        find.byWidgetPredicate((widget) =>
            widget is Container && widget.decoration != null),
        findsNothing,
      );
    });

    testWidgets('shows background container when showBackground is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InGameHeartsDisplay.custom(
                currentHearts: 2,
                maxHearts: 3,
                showBackground: true,
              ),
            ),
          ),
        ),
      );

      // Should have a Container with decoration (background)
      expect(
        find.byWidgetPredicate((widget) =>
            widget is Container && widget.decoration != null),
        findsOneWidget,
      );
    });

    testWidgets('background has semi-transparent black color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InGameHeartsDisplay.custom(
                currentHearts: 2,
                maxHearts: 3,
                showBackground: true,
              ),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.byWidgetPredicate((widget) =>
            widget is Container && widget.decoration != null),
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, isNotNull);
      expect(decoration.color!.alpha, lessThan(255)); // Semi-transparent
    });
  });

  group('InGameHeartsDisplay - Visual Consistency', () {
    testWidgets('hearts have shadow for better visibility', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InGameHeartsDisplay.custom(
                currentHearts: 2,
                maxHearts: 3,
              ),
            ),
          ),
        ),
      );

      final heartIcons = tester.widgetList<Icon>(find.byIcon(Icons.favorite)).toList();
      
      // All hearts should have shadows
      for (final icon in heartIcons) {
        expect(icon.shadows, isNotNull);
        expect(icon.shadows!.length, greaterThan(0));
      }
    });

    testWidgets('filled hearts use redAccent color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InGameHeartsDisplay.custom(
                currentHearts: 3,
                maxHearts: 3,
              ),
            ),
          ),
        ),
      );

      final heartIcons = tester.widgetList<Icon>(find.byIcon(Icons.favorite)).toList();
      
      for (final icon in heartIcons) {
        expect(icon.color, equals(Colors.redAccent));
      }
    });

    testWidgets('empty hearts use faded redAccent (0.25 alpha)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InGameHeartsDisplay.custom(
                currentHearts: 0,
                maxHearts: 3,
              ),
            ),
          ),
        ),
      );

      final heartIcons = tester.widgetList<Icon>(find.byIcon(Icons.favorite)).toList();
      
      for (final icon in heartIcons) {
        expect(icon.color, equals(Colors.redAccent.withValues(alpha: 0.25)));
      }
    });
  });

  group('InGameHeartsDisplay - Edge Cases', () {
    testWidgets('handles 1 heart max', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InGameHeartsDisplay.custom(
                currentHearts: 1,
                maxHearts: 1,
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.favorite), findsNWidgets(1));
    });

    testWidgets('handles currentHearts greater than maxHearts gracefully', (tester) async {
      // This shouldn't happen in practice, but the widget should handle it
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InGameHeartsDisplay.custom(
                currentHearts: 5, // More than max
                maxHearts: 3,
              ),
            ),
          ),
        ),
      );

      // Should still only show maxHearts icons
      expect(find.byIcon(Icons.favorite), findsNWidgets(3));
      
      // All should be filled since currentHearts > maxHearts
      final heartIcons = tester.widgetList<Icon>(find.byIcon(Icons.favorite));
      for (final icon in heartIcons) {
        expect(icon.color, equals(Colors.redAccent)); // All filled
      }
    });

    testWidgets('handles very small screen (240x320)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(240, 320)),
            child: Scaffold(
              body: Center(
                child: InGameHeartsDisplay.custom(
                  currentHearts: 2,
                  maxHearts: 3,
                ),
              ),
            ),
          ),
        ),
      );

      // Should render without errors
      expect(find.byType(InGameHeartsDisplay), findsOneWidget);
      
      final heartIcons = tester.widgetList<Icon>(find.byIcon(Icons.favorite)).toList();
      final heartSize = heartIcons.first.size;
      
      // Hearts should be clamped to minimum size
      expect(heartSize, greaterThanOrEqualTo(16.0)); // Min clamp value
    });

    testWidgets('handles very large screen (1920x1080)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1920, 1080)),
            child: Scaffold(
              body: Center(
                child: InGameHeartsDisplay.custom(
                  currentHearts: 2,
                  maxHearts: 3,
                ),
              ),
            ),
          ),
        ),
      );

      // Should render without errors
      expect(find.byType(InGameHeartsDisplay), findsOneWidget);
      
      final heartIcons = tester.widgetList<Icon>(find.byIcon(Icons.favorite)).toList();
      final heartSize = heartIcons.first.size;
      
      // Hearts should be clamped to maximum size
      expect(heartSize, lessThanOrEqualTo(32.0)); // Max clamp value
    });
  });

  group('InGameHeartsDisplay - Integration Scenarios', () {
    testWidgets('stunt tournament scenario: 3 hearts, 1 remaining', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InGameHeartsDisplay.custom(
                currentHearts: 1,
                maxHearts: 3,
                showBackground: true,
              ),
            ),
          ),
        ),
      );

      final heartIcons = tester.widgetList<Icon>(find.byIcon(Icons.favorite)).toList();
      expect(heartIcons.length, equals(3));
      
      // First heart filled, others faded
      expect(heartIcons[0].color, equals(Colors.redAccent));
      expect(heartIcons[1].color, equals(Colors.redAccent.withValues(alpha: 0.25)));
      expect(heartIcons[2].color, equals(Colors.redAccent.withValues(alpha: 0.25)));
    });

    testWidgets('story mode scenario: 6 hearts (booster), 4 remaining', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InGameHeartsDisplay.custom(
                currentHearts: 4,
                maxHearts: 6,
                showBackground: false,
              ),
            ),
          ),
        ),
      );

      final heartIcons = tester.widgetList<Icon>(find.byIcon(Icons.favorite)).toList();
      expect(heartIcons.length, equals(6));
      
      // First 4 hearts filled, last 2 faded
      for (int i = 0; i < 4; i++) {
        expect(heartIcons[i].color, equals(Colors.redAccent));
      }
      for (int i = 4; i < 6; i++) {
        expect(heartIcons[i].color, equals(Colors.redAccent.withValues(alpha: 0.25)));
      }
    });
  });
}


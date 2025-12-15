import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flappy_jet_pro/ui/screens/level_objective_popup.dart';
import '../../helpers/test_level_data.dart';

class _FakeAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final buffer = Uint8List.fromList(_transparentPng);
    return ByteData.sublistView(buffer);
  }

  @override
  Future<T> loadStructuredBinaryData<T>(
    String key,
    FutureOr<T> Function(ByteData data) parser,
  ) async {
    // Provide an empty manifest for AssetManifest.bin/JSON lookups.
    final encoded =
        const StandardMessageCodec().encodeMessage(<String, dynamic>{}) ??
            ByteData(0);
    return parser(encoded);
  }
}

const List<int> _transparentPng = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82,
];

void main() {
  group('LevelObjectivePopup - objective header', () {
    testWidgets('shows VS badge image for bot battle objectives', (tester) async {
      final level = TestLevelData.botBattleLevel;

      await tester.pumpWidget(
        DefaultAssetBundle(
          bundle: _FakeAssetBundle(),
          child: MaterialApp(
            home: Scaffold(
              body: LevelObjectivePopup(level: level),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName ==
                  'assets/images/ui/vs_battle_node_completed.png',
        ),
        findsOneWidget,
      );
      expect(find.text('OBJECTIVE'), findsNothing);
      expect(find.text(level.objective.description), findsOneWidget);
    });

    testWidgets('shows obstacle badge and hides OBJECTIVE for obstacle objectives', (tester) async {
      final level = TestLevelData.simpleObstacleLevel;

      await tester.pumpWidget(
        DefaultAssetBundle(
          bundle: _FakeAssetBundle(),
          child: MaterialApp(
            home: Scaffold(
              body: LevelObjectivePopup(level: level),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('OBJECTIVE'), findsNothing);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName ==
                  'assets/images/ui/pass_obstacle_objective.png',
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName ==
                  'assets/images/ui/vs_battle_node_completed.png',
        ),
        findsNothing,
      );
    });

    testWidgets('uses gold timer badge for survive time objectives', (tester) async {
      final level = TestLevelData.surviveTimeLevel;

      await tester.pumpWidget(
        DefaultAssetBundle(
          bundle: _FakeAssetBundle(),
          child: MaterialApp(
            home: Scaffold(
              body: LevelObjectivePopup(level: level),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName ==
                  'assets/images/icons/missions/gold_timer_icon.png',
        ),
        findsOneWidget,
      );
      expect(find.text('OBJECTIVE'), findsNothing);
    });
  });

  group('LevelObjectivePopup - START button', () {
    testWidgets('START button uses image asset and has button gestures', (tester) async {
      final level = TestLevelData.simpleObstacleLevel;
      bool buttonPressed = false;

      await tester.pumpWidget(
        DefaultAssetBundle(
          bundle: _FakeAssetBundle(),
          child: MaterialApp(
            home: Scaffold(
              body: LevelObjectivePopup(
                level: level,
                key: const ValueKey('test_popup'),
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // Verify START button image is present
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName ==
                  'assets/images/ui/start_button.png',
        ),
        findsOneWidget,
      );

      // Verify button has GestureDetector (for button gestures)
      expect(find.byType(GestureDetector), findsWidgets);
      
      // Verify AnimatedScale is present (for press feedback)
      expect(find.byType(AnimatedScale), findsOneWidget);
    });

    testWidgets('START button scales down when pressed', (tester) async {
      final level = TestLevelData.simpleObstacleLevel;

      await tester.pumpWidget(
        DefaultAssetBundle(
          bundle: _FakeAssetBundle(),
          child: MaterialApp(
            home: Scaffold(
              body: LevelObjectivePopup(level: level),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // Find the START button image
      final buttonFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/ui/start_button.png',
      );

      expect(buttonFinder, findsOneWidget);

      // Get initial scale
      final animatedScale = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
      expect(animatedScale.scale, 1.0);

      // Simulate button press (tap down)
      final gesture = await tester.startGesture(
        tester.getCenter(buttonFinder),
      );
      await tester.pump(const Duration(milliseconds: 50));

      // Verify scale changed (button pressed state)
      final pressedScale = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
      expect(pressedScale.scale, lessThan(1.0));

      // Release tap
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 150));

      // Verify scale returned to normal
      final releasedScale = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
      expect(releasedScale.scale, 1.0);
    });
  });
}


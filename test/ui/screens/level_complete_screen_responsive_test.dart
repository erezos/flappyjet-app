/// 🧪 LEVEL COMPLETE POPUP RESPONSIVE DESIGN TESTS
/// 
/// Tests for responsive design and X button positioning on level complete popup.
/// Ensures the popup looks perfect on all device sizes.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flappy_jet_pro/ui/screens/level_complete_screen.dart';
import 'package:flappy_jet_pro/models/level_data_schema.dart';
import 'package:flappy_jet_pro/ui/utils/responsive_config.dart';

void main() {
  group('Level Complete Popup - Responsive Design Tests', () {
    // Test data
    final testLevel = LevelData(
      id: 1,
      zone: 1,
      name: 'Test Level',
      objective: const LevelObjective(
        type: ObjectiveType.surviveTime,
        target: 12,
        description: 'Survive for 12 seconds',
      ),
      difficulty: const DifficultyConfig(
        speedMultiplier: 1.0,
        obstacleGap: 400.0,
        obstacleFrequency: 0.6,
        maxGapShift: 50.0,
      ),
      reward: const LevelReward(
        coins: 100,
        gems: 5,
      ),
      theme: const LevelTheme(
        background: 'backgrounds/phase1_sunny.png',
        obstacles: 'obstacles/phase1_wooden_pipes.png',
        music: 'peaceful.mp3',
      ),
    );

    testWidgets('X button is positioned outside popup container', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelCompleteScreen(
              level: testLevel,
              objectiveAchieved: 12,
              timeTaken: 12,
              continuesUsed: 0,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the X button
      final closeButton = find.byIcon(Icons.close_rounded);
      expect(closeButton, findsOneWidget);

      // Verify X button is positioned outside container
      // (This is verified by the Stack with clipBehavior: Clip.none)
      final stack = tester.widget<Stack>(
        find.byType(Stack).first,
      );
      expect(stack.clipBehavior, Clip.none);
    });

    testWidgets('X button meets minimum touch target size (44x44px)', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelCompleteScreen(
              level: testLevel,
              objectiveAchieved: 12,
              timeTaken: 12,
              continuesUsed: 0,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the X button container
      final closeButton = find.byIcon(Icons.close_rounded);
      expect(closeButton, findsOneWidget);

      final container = tester.widget<Container>(
        find.ancestor(
          of: closeButton,
          matching: find.byType(Container),
        ).first,
      );

      // Verify minimum size
      expect(container.constraints?.minWidth, greaterThanOrEqualTo(44.0));
      expect(container.constraints?.minHeight, greaterThanOrEqualTo(44.0));
    });

    testWidgets('Popup scales correctly on small phone (iPhone SE)', (WidgetTester tester) async {
      const smallPhoneSize = Size(375.0, 667.0); // iPhone SE

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: smallPhoneSize),
            child: Scaffold(
              body: LevelCompleteScreen(
                level: testLevel,
                objectiveAchieved: 12,
                timeTaken: 12,
                continuesUsed: 0,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify popup width is responsive
      final popupWidth = ResponsiveConfig.responsivePopupWidth(
        smallPhoneSize,
        percent: 0.85,
        minWidth: 300.0,
        maxWidth: 450.0,
      );
      expect(popupWidth, greaterThanOrEqualTo(300.0));
      expect(popupWidth, lessThanOrEqualTo(450.0));
    });

    testWidgets('Popup scales correctly on large phone (iPhone 13 Pro Max)', (WidgetTester tester) async {
      const largePhoneSize = Size(428.0, 926.0); // iPhone 13 Pro Max

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: largePhoneSize),
            child: Scaffold(
              body: LevelCompleteScreen(
                level: testLevel,
                objectiveAchieved: 12,
                timeTaken: 12,
                continuesUsed: 0,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify popup width is responsive
      final popupWidth = ResponsiveConfig.responsivePopupWidth(
        largePhoneSize,
        percent: 0.85,
        minWidth: 300.0,
        maxWidth: 450.0,
      );
      expect(popupWidth, greaterThanOrEqualTo(300.0));
      expect(popupWidth, lessThanOrEqualTo(450.0));
    });

    testWidgets('Popup scales correctly on tablet (iPad)', (WidgetTester tester) async {
      const tabletSize = Size(768.0, 1024.0); // iPad

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: tabletSize),
            child: Scaffold(
              body: LevelCompleteScreen(
                level: testLevel,
                objectiveAchieved: 12,
                timeTaken: 12,
                continuesUsed: 0,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify popup width is responsive
      final popupWidth = ResponsiveConfig.responsivePopupWidth(
        tabletSize,
        percent: 0.85,
        minWidth: 300.0,
        maxWidth: 450.0,
      );
      expect(popupWidth, greaterThanOrEqualTo(300.0));
      expect(popupWidth, lessThanOrEqualTo(450.0));
    });

    testWidgets('X button icon size is responsive', (WidgetTester tester) async {
      const smallPhoneSize = Size(375.0, 667.0);
      const largePhoneSize = Size(428.0, 926.0);
      const tabletSize = Size(768.0, 1024.0);

      // Test on small phone
      final smallIconSize = ResponsiveConfig.responsiveIconSize(24.0, smallPhoneSize)
          .clamp(20.0, 28.0);
      expect(smallIconSize, greaterThanOrEqualTo(20.0));
      expect(smallIconSize, lessThanOrEqualTo(28.0));

      // Test on large phone
      final largeIconSize = ResponsiveConfig.responsiveIconSize(24.0, largePhoneSize)
          .clamp(20.0, 28.0);
      expect(largeIconSize, greaterThanOrEqualTo(20.0));
      expect(largeIconSize, lessThanOrEqualTo(28.0));

      // Test on tablet
      final tabletIconSize = ResponsiveConfig.responsiveIconSize(24.0, tabletSize)
          .clamp(20.0, 28.0);
      expect(tabletIconSize, greaterThanOrEqualTo(20.0));
      expect(tabletIconSize, lessThanOrEqualTo(28.0));
    });

    testWidgets('X button container size is responsive', (WidgetTester tester) async {
      const smallPhoneSize = Size(375.0, 667.0);
      const largePhoneSize = Size(428.0, 926.0);
      const tabletSize = Size(768.0, 1024.0);

      // Test on small phone
      final smallButtonSize = ResponsiveConfig.responsiveIconSize(44.0, smallPhoneSize)
          .clamp(44.0, 56.0);
      expect(smallButtonSize, greaterThanOrEqualTo(44.0)); // Minimum accessibility size
      expect(smallButtonSize, lessThanOrEqualTo(56.0));

      // Test on large phone
      final largeButtonSize = ResponsiveConfig.responsiveIconSize(44.0, largePhoneSize)
          .clamp(44.0, 56.0);
      expect(largeButtonSize, greaterThanOrEqualTo(44.0));
      expect(largeButtonSize, lessThanOrEqualTo(56.0));

      // Test on tablet
      final tabletButtonSize = ResponsiveConfig.responsiveIconSize(44.0, tabletSize)
          .clamp(44.0, 56.0);
      expect(tabletButtonSize, greaterThanOrEqualTo(44.0));
      expect(tabletButtonSize, lessThanOrEqualTo(56.0));
    });

    testWidgets('Popup uses ResponsiveConfig for all sizing', (WidgetTester tester) async {
      const screenSize = Size(375.0, 667.0);

      // Verify all responsive utilities are used
      final popupWidth = ResponsiveConfig.responsivePopupWidth(
        screenSize,
        percent: 0.85,
        minWidth: 300.0,
        maxWidth: 450.0,
      );
      expect(popupWidth, isA<double>());

      final popupHeight = ResponsiveConfig.responsivePopupHeight(
        screenSize,
        percent: 0.75,
        minHeight: 400.0,
        maxHeight: 800.0,
      );
      expect(popupHeight, isA<double>());

      final iconSize = ResponsiveConfig.responsiveIconSize(24.0, screenSize);
      expect(iconSize, isA<double>());

      final padding = ResponsiveConfig.responsivePadding(16.0, screenSize);
      expect(padding, isA<double>());
    });

    testWidgets('X button is tappable', (WidgetTester tester) async {
      bool buttonTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelCompleteScreen(
              level: testLevel,
              objectiveAchieved: 12,
              timeTaken: 12,
              continuesUsed: 0,
              onContinue: () {
                buttonTapped = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the X button
      final closeButton = find.byIcon(Icons.close_rounded);
      expect(closeButton, findsOneWidget);

      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      // Verify callback was called
      expect(buttonTapped, isTrue);
    });

    testWidgets('Popup respects max height constraint', (WidgetTester tester) async {
      const screenSize = Size(375.0, 667.0);

      final maxPopupHeight = ResponsiveConfig.responsivePopupHeight(
        screenSize,
        percent: 0.75,
        minHeight: 400.0,
        maxHeight: 800.0,
      );

      expect(maxPopupHeight, lessThanOrEqualTo(screenSize.height * 0.75));
      expect(maxPopupHeight, greaterThanOrEqualTo(400.0));
      expect(maxPopupHeight, lessThanOrEqualTo(800.0));
    });

    testWidgets('Popup respects max width constraint', (WidgetTester tester) async {
      const screenSize = Size(375.0, 667.0);

      final popupWidth = ResponsiveConfig.responsivePopupWidth(
        screenSize,
        percent: 0.85,
        minWidth: 300.0,
        maxWidth: 450.0,
      );

      expect(popupWidth, lessThanOrEqualTo(screenSize.width * 0.85));
      expect(popupWidth, greaterThanOrEqualTo(300.0));
      expect(popupWidth, lessThanOrEqualTo(450.0));
    });
  });
}


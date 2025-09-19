/// Tests for Global Leaderboard Tab Widget
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flappy_jet_pro/ui/widgets/tournaments/global_leaderboard_tab.dart';

void main() {
  group('GlobalLeaderboardTab Widget Tests', () {
    testWidgets('should create widget without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlobalLeaderboardTab(),
          ),
        ),
      );

      // Should create the widget without crashing
      expect(find.byType(GlobalLeaderboardTab), findsOneWidget);
    });

    testWidgets('should display loading state initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlobalLeaderboardTab(),
          ),
        ),
      );

      // Should show loading indicator initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should have proper widget structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlobalLeaderboardTab(),
          ),
        ),
      );

      // Should have a container with gradient background
      expect(find.byType(Container), findsWidgets);
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('should handle widget lifecycle correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlobalLeaderboardTab(),
          ),
        ),
      );

      // Widget should be created
      expect(find.byType(GlobalLeaderboardTab), findsOneWidget);

      // Navigate away to test dispose
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Text('Other Screen'),
          ),
        ),
      );

      // Should properly dispose without errors
      expect(find.text('Other Screen'), findsOneWidget);
    });

    testWidgets('should be responsive to different screen sizes', (WidgetTester tester) async {
      // Test with small screen
      tester.binding.window.physicalSizeTestValue = const Size(400, 600);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlobalLeaderboardTab(),
          ),
        ),
      );

      expect(find.byType(GlobalLeaderboardTab), findsOneWidget);

      // Test with large screen
      tester.binding.window.physicalSizeTestValue = const Size(800, 1200);
      await tester.pumpAndSettle();

      expect(find.byType(GlobalLeaderboardTab), findsOneWidget);

      // Reset window size
      tester.binding.window.clearPhysicalSizeTestValue();
      tester.binding.window.clearDevicePixelRatioTestValue();
    });
  });
}
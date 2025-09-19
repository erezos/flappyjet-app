/// Tests for Weekly Championship Tab Widget
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flappy_jet_pro/ui/widgets/tournaments/weekly_contest_tab.dart';

void main() {
  group('WeeklyContestTab Widget Tests', () {
    testWidgets('should create widget without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WeeklyContestTab(),
          ),
        ),
      );

      // Should create the widget without crashing
      expect(find.byType(WeeklyContestTab), findsOneWidget);
    });

    testWidgets('should display loading state initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WeeklyContestTab(),
          ),
        ),
      );

      // Should show loading indicator initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display weekly contest header', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WeeklyContestTab(),
          ),
        ),
      );

      // Should display the header text
      expect(find.text('🏆 Weekly Contest'), findsOneWidget);
    });

    testWidgets('should have refresh button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WeeklyContestTab(),
          ),
        ),
      );

      // Should have a refresh button
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('should handle refresh button tap', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WeeklyContestTab(),
          ),
        ),
      );

      // Find and tap refresh button
      final refreshButton = find.byIcon(Icons.refresh);
      expect(refreshButton, findsOneWidget);
      
      await tester.tap(refreshButton);
      await tester.pump();

      // Should not crash when tapping refresh
      expect(find.byType(WeeklyContestTab), findsOneWidget);
    });

    testWidgets('should have proper gradient background', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WeeklyContestTab(),
          ),
        ),
      );

      // Should have a container with gradient decoration
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasGradient = containers.any((container) {
        final decoration = container.decoration;
        return decoration is BoxDecoration && decoration.gradient != null;
      });
      
      expect(hasGradient, true);
    });

    testWidgets('should handle widget lifecycle correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WeeklyContestTab(),
          ),
        ),
      );

      // Widget should be created
      expect(find.byType(WeeklyContestTab), findsOneWidget);

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
            body: WeeklyContestTab(),
          ),
        ),
      );

      expect(find.byType(WeeklyContestTab), findsOneWidget);

      // Test with large screen
      tester.binding.window.physicalSizeTestValue = const Size(800, 1200);
      await tester.pumpAndSettle();

      expect(find.byType(WeeklyContestTab), findsOneWidget);

      // Reset window size
      tester.binding.window.clearPhysicalSizeTestValue();
      tester.binding.window.clearDevicePixelRatioTestValue();
    });
  });
}
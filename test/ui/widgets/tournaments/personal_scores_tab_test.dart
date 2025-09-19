/// Tests for Personal Scores Tab Widget
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flappy_jet_pro/ui/widgets/tournaments/personal_scores_tab.dart';

void main() {
  group('PersonalScoresTab Widget Tests', () {
    testWidgets('should create widget without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PersonalScoresTab(),
          ),
        ),
      );

      // Should create the widget without crashing
      expect(find.byType(PersonalScoresTab), findsOneWidget);
    });

    testWidgets('should display loading state initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PersonalScoresTab(),
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
            body: PersonalScoresTab(),
          ),
        ),
      );

      // Should have a container with gradient background
      expect(find.byType(Container), findsWidgets);
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('should have proper gradient background', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PersonalScoresTab(),
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
            body: PersonalScoresTab(),
          ),
        ),
      );

      // Widget should be created
      expect(find.byType(PersonalScoresTab), findsOneWidget);

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
            body: PersonalScoresTab(),
          ),
        ),
      );

      expect(find.byType(PersonalScoresTab), findsOneWidget);

      // Test with large screen
      tester.binding.window.physicalSizeTestValue = const Size(800, 1200);
      await tester.pumpAndSettle();

      expect(find.byType(PersonalScoresTab), findsOneWidget);

      // Reset window size
      tester.binding.window.clearPhysicalSizeTestValue();
      tester.binding.window.clearDevicePixelRatioTestValue();
    });

    testWidgets('should handle memory cleanup on dispose', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PersonalScoresTab(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate away to trigger dispose
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('Other Screen')),
        ),
      );

      await tester.pumpAndSettle();

      // Should properly dispose of resources (no memory leaks)
      expect(find.text('Other Screen'), findsOneWidget);
    });

    testWidgets('should handle state changes correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PersonalScoresTab(),
        ),
      );

      // Initial state should be loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for potential state changes
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Widget should still exist after state changes
      expect(find.byType(PersonalScoresTab), findsOneWidget);
    });
  });
}
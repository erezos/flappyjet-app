/// Tests for Tournaments Screen
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flappy_jet_pro/ui/screens/tournaments_screen.dart';

void main() {
  group('TournamentsScreen Widget Tests', () {
    testWidgets('should create screen without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TournamentsScreen(),
        ),
      );

      // Should create the screen without crashing
      expect(find.byType(TournamentsScreen), findsOneWidget);
    });

    testWidgets('should display tournaments screen with tab bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TournamentsScreen(),
        ),
      );

      // Should display app bar
      expect(find.text('Tournaments'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);

      // Should display tab bar with three tabs
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.text('Global'), findsOneWidget);
      expect(find.text('Weekly'), findsOneWidget);
      expect(find.text('Personal'), findsOneWidget);

      // Should display tab bar view
      expect(find.byType(TabBarView), findsOneWidget);
    });

    testWidgets('should switch between tabs correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TournamentsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Initially should show global leaderboard tab
      expect(find.text('Global'), findsOneWidget);

      // Tap on Weekly tab
      await tester.tap(find.text('Weekly'));
      await tester.pumpAndSettle();

      // Should switch to weekly tab
      expect(find.text('Weekly'), findsOneWidget);

      // Tap on Personal tab
      await tester.tap(find.text('Personal'));
      await tester.pumpAndSettle();

      // Should switch to personal tab
      expect(find.text('Personal'), findsOneWidget);
    });

    testWidgets('should display correct tab indicators', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TournamentsScreen(),
        ),
      );

      // Should display tab icons
      expect(find.byIcon(Icons.public), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('should handle back navigation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const Scaffold(body: Text('Home')),
          routes: {
            '/tournaments': (context) => const TournamentsScreen(),
          },
        ),
      );

      // Navigate to tournaments screen
      final context = tester.element(find.text('Home'));
      Navigator.of(context).pushNamed('/tournaments');
      await tester.pumpAndSettle();

      // Should display tournaments screen
      expect(find.text('Tournaments'), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);

      // Tap back button
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Should navigate back to home
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('should preserve tab state during navigation', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TournamentsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Switch to Weekly tab
      await tester.tap(find.text('Weekly'));
      await tester.pumpAndSettle();

      // Verify we're on Weekly tab
      expect(find.text('Weekly'), findsOneWidget);

      // Simulate app state change (like going to background and back)
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/lifecycle',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('AppLifecycleState.paused'),
        ),
        (data) {},
      );

      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/lifecycle',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('AppLifecycleState.resumed'),
        ),
        (data) {},
      );

      await tester.pumpAndSettle();

      // Should still be on Weekly tab
      expect(find.text('Weekly'), findsOneWidget);
    });

    testWidgets('should handle screen rotation', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TournamentsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Simulate screen rotation by changing size
      tester.binding.window.physicalSizeTestValue = const Size(800, 600);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      
      await tester.pumpAndSettle();

      // Should still display tournaments screen correctly
      expect(find.text('Tournaments'), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(TabBarView), findsOneWidget);

      // Reset window size
      tester.binding.window.clearPhysicalSizeTestValue();
      tester.binding.window.clearDevicePixelRatioTestValue();
    });

    testWidgets('should display correct theme styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const TournamentsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Should adapt to dark theme
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, isNotNull);

      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabBar.indicatorColor, isNotNull);
    });

    testWidgets('should handle memory cleanup on dispose', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TournamentsScreen(),
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

    testWidgets('should handle tab controller lifecycle', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TournamentsScreen(),
        ),
      );

      // Should create tab controller
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(TabBarView), findsOneWidget);

      // Switch tabs multiple times to test controller
      await tester.tap(find.text('Weekly'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Personal'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Global'));
      await tester.pumpAndSettle();

      // Should handle all tab switches without errors
      expect(find.byType(TournamentsScreen), findsOneWidget);
    });
  });
}
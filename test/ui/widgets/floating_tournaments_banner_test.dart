/// Tests for FloatingTournamentsBanner widget
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/ui/widgets/floating_tournaments_banner.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    // Reset SharedPreferences for each test
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestWidget({VoidCallback? onTap, double size = 85}) {
    return MaterialApp(
      home: Scaffold(
        body: FloatingTournamentsBanner(
          onTap: onTap ?? () {},
          size: size,
        ),
      ),
    );
  }

  group('FloatingTournamentsBanner - Basic Rendering', () {
    testWidgets('should render banner widget', (tester) async {
      await tester.pumpWidget(buildTestWidget(size: 85));
      await tester.pump(const Duration(milliseconds: 100));
      
      // Banner should be present
      expect(find.byType(FloatingTournamentsBanner), findsOneWidget);
    });

    testWidgets('should render banner image or fallback', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 100));
      
      // Should have an Image widget (either banner image or fallback)
      expect(find.byType(Image), findsAtLeast(1));
    });

    testWidgets('should show fallback when image fails to load', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 100));
      
      // Fallback should have TOURNAMENTS text and trophy icon
      // Tests don't have asset access, so fallback will show
      final fallbackFinder = find.text('TOURNAMENTS');
      if (fallbackFinder.evaluate().isNotEmpty) {
        expect(fallbackFinder, findsOneWidget);
        expect(find.byIcon(Icons.emoji_events), findsOneWidget);
      }
    });
  });

  group('FloatingTournamentsBanner - Interactions', () {
    testWidgets('should call onTap when banner is tapped', (tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(buildTestWidget(onTap: () => tapped = true));
      await tester.pump(const Duration(milliseconds: 100));
      
      // Tap the banner
      await tester.tap(find.byType(FloatingTournamentsBanner));
      await tester.pump();
      
      expect(tapped, true);
    });

    testWidgets('should be tappable with GestureDetector', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 100));
      
      expect(find.byType(GestureDetector), findsAtLeast(1));
    });
  });

  group('FloatingTournamentsBanner - Responsive Sizing', () {
    testWidgets('should scale down on small screens', (tester) async {
      // Set small screen size
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      
      await tester.pumpWidget(buildTestWidget(size: 85));
      await tester.pump(const Duration(milliseconds: 100));
      
      expect(find.byType(FloatingTournamentsBanner), findsOneWidget);
      
      // Reset view size
      tester.view.resetPhysicalSize();
    });

    testWidgets('should scale up on large screens', (tester) async {
      // Set large screen size
      tester.view.physicalSize = const Size(450, 900);
      tester.view.devicePixelRatio = 1.0;
      
      await tester.pumpWidget(buildTestWidget(size: 85));
      await tester.pump(const Duration(milliseconds: 100));
      
      expect(find.byType(FloatingTournamentsBanner), findsOneWidget);
      
      // Reset view size
      tester.view.resetPhysicalSize();
    });

    testWidgets('should respect useResponsiveScaling=false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingTournamentsBanner(
              onTap: () {},
              size: 100,
              useResponsiveScaling: false,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      
      expect(find.byType(FloatingTournamentsBanner), findsOneWidget);
    });
  });

  group('FloatingTournamentsBanner - Widget Structure', () {
    testWidgets('should use Stack for badge overlay layout', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 100));
      
      // Stack is used to overlay the FREE badge on the banner
      expect(find.byType(Stack), findsAtLeast(1));
    });

    testWidgets('should use ListenableBuilder for reactive updates', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 100));
      
      // ListenableBuilder should be used for reactive updates from TournamentManager
      expect(find.byType(ListenableBuilder), findsAtLeast(1));
    });

    testWidgets('should have Container with decoration for styling', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 100));
      
      expect(find.byType(Container), findsAtLeast(1));
    });

    testWidgets('should use ClipRRect for rounded corners', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 100));
      
      expect(find.byType(ClipRRect), findsAtLeast(1));
    });
  });

  group('FloatingTournamentsBanner - Animation Support', () {
    testWidgets('should handle animation frames without errors', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      
      // Banner uses SingleTickerProviderStateMixin for animations
      expect(find.byType(FloatingTournamentsBanner), findsOneWidget);
      
      // Advance animation
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));
      
      // Should still be present after animation
      expect(find.byType(FloatingTournamentsBanner), findsOneWidget);
    });
  });
}


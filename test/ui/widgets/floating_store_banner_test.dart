import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/ui/widgets/floating_store_banner.dart';

/// Tests for FloatingStoreBanner widget
/// 
/// Verifies:
/// - Widget renders correctly
/// - Tap triggers callback
/// - Responsive sizing works
/// - NEW badge shows/hides correctly
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('FloatingStoreBanner', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingStoreBanner(
              onTap: () {},
            ),
          ),
        ),
      );
      
      // Should render without throwing
      expect(find.byType(FloatingStoreBanner), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingStoreBanner(
              onTap: () => tapped = true,
            ),
          ),
        ),
      );
      
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();
      
      expect(tapped, isTrue, reason: 'onTap callback should be triggered');
    });

    testWidgets('respects custom size parameter', (tester) async {
      const customSize = 100.0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingStoreBanner(
              onTap: () {},
              size: customSize,
              useResponsiveScaling: false, // Disable scaling for exact test
            ),
          ),
        ),
      );
      
      // Banner height should be 70% of size
      final expectedHeight = customSize * 0.7;
      
      // Find the SizedBox that wraps the banner
      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.height, equals(expectedHeight));
    });

    testWidgets('does not show NEW badge by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingStoreBanner(
              onTap: () {},
              showNewBadge: false,
            ),
          ),
        ),
      );
      
      // NEW badge should not be visible
      expect(find.text('NEW'), findsNothing);
    });

    testWidgets('shows NEW badge when showNewBadge is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingStoreBanner(
              onTap: () {},
              showNewBadge: true,
            ),
          ),
        ),
      );
      
      // NEW badge should be visible
      expect(find.text('NEW'), findsOneWidget);
    });

    testWidgets('uses RepaintBoundary for performance', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingStoreBanner(
              onTap: () {},
            ),
          ),
        ),
      );
      
      // Should use RepaintBoundary for performance optimization
      // Note: Flutter may add multiple RepaintBoundaries internally
      expect(find.byType(RepaintBoundary), findsWidgets);
    });

    testWidgets('uses Image.asset for banner', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingStoreBanner(
              onTap: () {},
            ),
          ),
        ),
      );
      
      // Should attempt to load the banner image
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('has correct aspect ratio (199:76)', (tester) async {
      const double size = 100.0;
      const double expectedAspectRatio = 199.0 / 76.0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingStoreBanner(
              onTap: () {},
              size: size,
              useResponsiveScaling: false,
            ),
          ),
        ),
      );
      
      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      final actualAspectRatio = sizedBox.width! / sizedBox.height!;
      
      // Allow small tolerance for rounding
      expect(actualAspectRatio, closeTo(expectedAspectRatio, 0.01));
    });
  });

  group('FloatingStoreBanner visual styling', () {
    testWidgets('has rounded corners via ClipRRect', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingStoreBanner(
              onTap: () {},
            ),
          ),
        ),
      );
      
      // Should have ClipRRect for rounded corners
      expect(find.byType(ClipRRect), findsOneWidget);
    });

    testWidgets('has Container with BoxDecoration', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingStoreBanner(
              onTap: () {},
            ),
          ),
        ),
      );
      
      // Find container with BoxDecoration
      final containers = tester.widgetList<Container>(find.byType(Container));
      bool hasDecoration = false;
      
      for (final container in containers) {
        if (container.decoration is BoxDecoration) {
          hasDecoration = true;
          break;
        }
      }
      
      expect(hasDecoration, isTrue, reason: 'Banner should have BoxDecoration');
    });
  });

  group('FloatingStoreBanner responsiveness', () {
    testWidgets('scales down on small screens', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 2.0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingStoreBanner(
              onTap: () {},
              size: 85,
              useResponsiveScaling: true,
            ),
          ),
        ),
      );
      
      // Should render without overflow
      expect(tester.takeException(), isNull);
      expect(find.byType(FloatingStoreBanner), findsOneWidget);
      
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('scales up on large screens', (tester) async {
      tester.view.physicalSize = const Size(1024, 1366);
      tester.view.devicePixelRatio = 2.0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingStoreBanner(
              onTap: () {},
              size: 85,
              useResponsiveScaling: true,
            ),
          ),
        ),
      );
      
      // Should render without overflow
      expect(tester.takeException(), isNull);
      expect(find.byType(FloatingStoreBanner), findsOneWidget);
      
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('disables scaling when useResponsiveScaling is false', (tester) async {
      const baseSize = 85.0;
      
      // Test on different screen sizes
      for (final screenWidth in [320.0, 400.0, 600.0]) {
        tester.view.physicalSize = Size(screenWidth, 800);
        tester.view.devicePixelRatio = 1.0;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FloatingStoreBanner(
                onTap: () {},
                size: baseSize,
                useResponsiveScaling: false,
              ),
            ),
          ),
        );
        
        final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
        // Height should be 70% of base size regardless of screen
        expect(sizedBox.height, equals(baseSize * 0.7));
        
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      }
    });
  });
}

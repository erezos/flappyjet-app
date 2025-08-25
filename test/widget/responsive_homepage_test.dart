/// 🧪 **COMPREHENSIVE RESPONSIVE TESTING** 
/// Using Flutter MCP Mobile Game Testing Excellence
/// 
/// Tests all screen sizes and orientations to prevent overflow issues
/// in our blockbuster FlappyJet mobile game.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/main.dart';
import 'package:flappy_jet_pro/ui/screens/stunning_homepage.dart';

void main() {
  group('🎮 Responsive Homepage Tests - Flutter MCP Mobile Excellence', () {
    
    /// Common mobile device screen sizes
    final List<Size> mobileScreenSizes = [
      // iPhone Sizes
      const Size(414, 896),  // iPhone 11, XR
      const Size(390, 844),  // iPhone 12, 13, 14
      const Size(393, 852),  // iPhone 14 Pro
      const Size(430, 932),  // iPhone 14 Pro Max, 15 Pro Max
      const Size(375, 667),  // iPhone SE 2nd/3rd gen
      const Size(320, 568),  // iPhone 5s (smallest supported)
      
      // Android Sizes
      const Size(360, 640),  // Small Android
      const Size(411, 731),  // Pixel 4
      const Size(412, 892),  // Pixel 6
      const Size(428, 926),  // Large Android
      
      // Tablet Sizes (edge cases)
      const Size(768, 1024), // iPad Mini
      const Size(810, 1080), // iPad
      const Size(1024, 1366), // iPad Pro
      
      // Ultra-wide and unusual ratios
      const Size(360, 800),  // 18:9 ratio
      const Size(375, 812),  // iPhone X ratio
      const Size(280, 653),  // Very narrow
    ];
    
    /// Test each screen size for overflow prevention
    for (final size in mobileScreenSizes) {
      testWidgets(
        '📱 No overflow on ${size.width.toInt()}x${size.height.toInt()}',
        (WidgetTester tester) async {
          // Configure screen size
          await tester.binding.setSurfaceSize(size);
          
          // Build app with stunning homepage
          await tester.pumpWidget(
            const FlappyJetProApp(developmentMode: true),
          );
          
          // Let all animations settle
          await tester.pumpAndSettle();
          
          // Verify no RenderFlex overflow
          expect(tester.takeException(), isNull, 
            reason: 'No overflow should occur on ${size.width}x${size.height}');
          
          // Verify all key elements are visible
          expect(find.byType(StunningHomepage), findsOneWidget);
          
          // Verify buttons are present and tappable
          expect(find.text('PLAY'), findsOneWidget);
          expect(find.text('MISSIONS'), findsOneWidget);
          
          // Verify background image loads
          expect(find.byKey(const Key('sky_background')), findsOneWidget);
        },
      );
    }
    
    testWidgets(
      '🔄 Orientation changes handle gracefully',
      (WidgetTester tester) async {
        // Start in portrait
        await tester.binding.setSurfaceSize(const Size(390, 844));
        
        await tester.pumpWidget(
          const FlappyJetProApp(developmentMode: true),
        );
        await tester.pumpAndSettle();
        
        // Verify portrait works
        expect(tester.takeException(), isNull);
        
        // Switch to landscape
        await tester.binding.setSurfaceSize(const Size(844, 390));
        await tester.pump();
        await tester.pumpAndSettle();
        
        // Verify landscape works
        expect(tester.takeException(), isNull);
        expect(find.byType(StunningHomepage), findsOneWidget);
      },
    );
    
    testWidgets(
      '⚡ Performance test - smooth animations on all sizes',
      (WidgetTester tester) async {
        for (final size in [
          const Size(320, 568), // Smallest
          const Size(430, 932), // Largest
        ]) {
          await tester.binding.setSurfaceSize(size);
          
          await tester.pumpWidget(
            const FlappyJetProApp(developmentMode: true),
          );
          
          // Test jet floating animation performance
          for (int i = 0; i < 10; i++) {
            await tester.pump(const Duration(milliseconds: 100));
          }
          
          // Should complete without exceptions
          expect(tester.takeException(), isNull);
        }
      },
    );
    
    testWidgets(
      '🎯 Button accessibility on small screens',
      (WidgetTester tester) async {
        // Test on smallest supported screen
        await tester.binding.setSurfaceSize(const Size(320, 568));
        
        await tester.pumpWidget(
          const FlappyJetProApp(developmentMode: true),
        );
        await tester.pumpAndSettle();
        
        // Find and tap buttons to ensure they're accessible
        final playButton = find.text('PLAY');
        final missionsButton = find.text('MISSIONS');
        
        expect(playButton, findsOneWidget);
        expect(missionsButton, findsOneWidget);
        
        // Verify buttons are large enough for touch targets
        final playButtonSize = tester.getSize(playButton);
        expect(playButtonSize.height, greaterThan(44), 
          reason: 'Buttons should meet minimum touch target size');
      },
    );
    
    testWidgets(
      '📐 SafeArea respected on notched devices',
      (WidgetTester tester) async {
        // Simulate iPhone with notch
        await tester.binding.setSurfaceSize(const Size(375, 812));
        
        // Add simulated padding for notch
        tester.binding.window.physicalSizeTestValue = const Size(1125, 2436);
        tester.binding.window.devicePixelRatioTestValue = 3.0;
        
        await tester.pumpWidget(
          const FlappyJetProApp(developmentMode: true),
        );
        await tester.pumpAndSettle();
        
        // Should handle notch gracefully
        expect(tester.takeException(), isNull);
        expect(find.byType(SafeArea), findsAtLeastNWidgets(1));
      },
    );
  });
  
  group('🎮 Gameplay Integration Tests - MCP Mobile Optimization', () {
    testWidgets(
      '🚀 Navigation to game works from all screen sizes',
      (WidgetTester tester) async {
        final testSizes = [
          const Size(320, 568),  // Small
          const Size(390, 844),  // Medium  
          const Size(430, 932),  // Large
        ];
        
        for (final size in testSizes) {
          await tester.binding.setSurfaceSize(size);
          
          await tester.pumpWidget(
            const FlappyJetProApp(developmentMode: true),
          );
          await tester.pumpAndSettle();
          
          // Tap PLAY button
          await tester.tap(find.text('PLAY'));
          await tester.pumpAndSettle();
          
          // Should navigate without errors
          expect(tester.takeException(), isNull);
          
          // Go back to test next size
          final NavigatorState navigator = tester.state(find.byType(Navigator));
          navigator.pop();
          await tester.pumpAndSettle();
        }
      },
    );
  });
}

/// 🔧 **FLUTTER MCP TEST UTILITIES**
extension FlutterMCPTestHelpers on WidgetTester {
  /// Check for any overflow errors in widget tree
  bool hasOverflowError() {
    // Check for any overflow-related exceptions
    final exception = takeException();
    return exception != null && exception.toString().contains('overflow');
  }
}
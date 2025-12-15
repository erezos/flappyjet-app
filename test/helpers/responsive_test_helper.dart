/// 📱 Responsive Test Helper - Utilities for testing responsive design
/// 
/// Provides helper functions to test widgets at different screen sizes,
/// verify responsive behavior, and ensure no overflow issues.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/ui/utils/responsive_config.dart';

/// Common device sizes for testing
class DeviceSizes {
  // Small phones (iPhone SE, older Android phones)
  static const Size smallPhone = Size(320.0, 568.0);
  
  // Reference device (iPhone 13 mini / iPhone SE baseline)
  static const Size reference = Size(375.0, 667.0);
  
  // Medium phones (iPhone 14, most Android phones)
  static const Size mediumPhone = Size(390.0, 844.0);
  
  // Large phones (iPhone 14 Pro Max, large Android phones)
  static const Size largePhone = Size(428.0, 926.0);
  
  // Small tablets (iPad Mini)
  static const Size smallTablet = Size(768.0, 1024.0);
  
  // Large tablets (iPad Pro)
  static const Size largeTablet = Size(1024.0, 1366.0);
  
  /// Get all device sizes for comprehensive testing
  static List<Size> getAll() => [
    smallPhone,
    reference,
    mediumPhone,
    largePhone,
    smallTablet,
    largeTablet,
  ];
  
  /// Get mobile device sizes only
  static List<Size> getMobile() => [
    smallPhone,
    reference,
    mediumPhone,
    largePhone,
  ];
  
  /// Get tablet device sizes only
  static List<Size> getTablets() => [
    smallTablet,
    largeTablet,
  ];
}

/// Responsive test helper utilities
class ResponsiveTestHelper {
  /// Test a widget at multiple screen sizes
  /// 
  /// [widget] - The widget to test
  /// [sizes] - List of screen sizes to test (default: all device sizes)
  /// [testCallback] - Callback function that receives tester and screen size
  /// 
  /// Example:
  /// ```dart
  /// ResponsiveTestHelper.testAtSizes(
  ///   widget: MyWidget(),
  ///   testCallback: (tester, size) {
  ///     expect(find.text('Hello'), findsOneWidget);
  ///     expect(tester.takeException(), isNull);
  ///   },
  /// );
  /// ```
  static Future<void> testAtSizes({
    required Widget widget,
    List<Size>? sizes,
    required Future<void> Function(WidgetTester tester, Size screenSize) testCallback,
  }) async {
    final testSizes = sizes ?? DeviceSizes.getAll();
    
    for (final size in testSizes) {
      testWidgets(
        'Test at ${size.width}x${size.height}',
        (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(size: size),
                child: widget,
              ),
            ),
          );
          
          await tester.pumpAndSettle();
          
          await testCallback(tester, size);
        },
      );
    }
  }
  
  /// Test that a widget has no overflow errors at different screen sizes
  /// 
  /// [widget] - The widget to test
  /// [sizes] - List of screen sizes to test (default: all device sizes)
  static void testNoOverflow({
    required Widget widget,
    List<Size>? sizes,
  }) {
    final testSizes = sizes ?? DeviceSizes.getAll();
    
    for (final size in testSizes) {
      testWidgets(
        'No overflow at ${size.width}x${size.height}',
        (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(size: size),
                child: widget,
              ),
            ),
          );
          
          await tester.pumpAndSettle();
          
          // Check for overflow errors
          final exception = tester.takeException();
          if (exception != null) {
            // Check if it's an overflow exception
            final exceptionString = exception.toString();
            if (exceptionString.contains('overflowed') ||
                exceptionString.contains('RenderFlex') ||
                exceptionString.contains('RenderBox')) {
              fail(
                'Overflow error at ${size.width}x${size.height}: $exception',
              );
            }
          }
          
          // Verify no overflow errors in the console
          expect(tester.takeException(), isNull,
            reason: 'Widget should not overflow at ${size.width}x${size.height}',
          );
        },
      );
    }
  }
  
  /// Test that a widget scales proportionally across screen sizes
  /// 
  /// [widget] - The widget to test
  /// [finder] - Finder to locate the widget
  /// [propertyGetter] - Function to get a size property from the widget
  /// [baseSize] - Expected size at reference device
  /// [sizes] - List of screen sizes to test (default: all device sizes)
  /// [tolerance] - Allowed tolerance for size differences (default: 0.1)
  static void testProportionalScaling({
    required Widget widget,
    required Finder finder,
    required double Function(RenderBox box) propertyGetter,
    required double baseSize,
    List<Size>? sizes,
    double tolerance = 0.1,
  }) {
    final testSizes = sizes ?? DeviceSizes.getAll();
    
    for (final size in testSizes) {
      testWidgets(
        'Test proportional scaling at ${size.width}x${size.height}',
        (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(size: size),
                child: widget,
              ),
            ),
          );
          
          await tester.pumpAndSettle();
          
          final renderBox = tester.renderObject<RenderBox>(finder);
          final actualSize = propertyGetter(renderBox);
          
          // Calculate expected size using ResponsiveConfig
          final expectedSize = ResponsiveConfig.responsiveSize(
            baseSize,
            size,
          );
          
          expect(
            actualSize,
            closeTo(expectedSize, expectedSize * tolerance),
            reason: 'Size should scale proportionally at ${size.width}x${size.height}',
          );
        },
      );
    }
  }
  
  /// Test that touch targets meet accessibility standards (minimum 44x44)
  /// 
  /// [widget] - The widget to test
  /// [buttonFinder] - Finder to locate buttons/touch targets
  /// [sizes] - List of screen sizes to test (default: all device sizes)
  static void testAccessibleTouchTargets({
    required Widget widget,
    required Finder buttonFinder,
    List<Size>? sizes,
  }) {
    final testSizes = sizes ?? DeviceSizes.getAll();
    
    for (final size in testSizes) {
      testWidgets(
        'Test accessible touch targets at ${size.width}x${size.height}',
        (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(size: size),
                child: widget,
              ),
            ),
          );
          
          await tester.pumpAndSettle();
          
          final buttons = buttonFinder.evaluate();
          
          for (final element in buttons) {
            final renderBox = element.renderObject as RenderBox;
            final buttonSize = renderBox.size;
            
            // Check minimum touch target size (44x44 points)
            expect(
              buttonSize.width,
              greaterThanOrEqualTo(44.0),
              reason: 'Touch target width should be at least 44px',
            );
            
            expect(
              buttonSize.height,
              greaterThanOrEqualTo(44.0),
              reason: 'Touch target height should be at least 44px',
            );
          }
        },
      );
    }
  }
  
  /// Test that text scales appropriately with screen size
  /// 
  /// [widget] - The widget to test
  /// [textFinder] - Finder to locate text widgets
  /// [sizes] - List of screen sizes to test (default: all device sizes)
  static void testTextScaling({
    required Widget widget,
    required Finder textFinder,
    List<Size>? sizes,
  }) {
    final testSizes = sizes ?? DeviceSizes.getAll();
    
    for (final size in testSizes) {
      testWidgets(
        'Test text scaling at ${size.width}x${size.height}',
        (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(size: size),
                child: widget,
              ),
            ),
          );
          
          await tester.pumpAndSettle();
          
          final textWidget = tester.widget<Text>(textFinder);
          final fontSize = textWidget.style?.fontSize ?? 14.0;
          
          // Calculate expected font size using ResponsiveConfig
          final expectedFontSize = ResponsiveConfig.responsiveFontSize(
            14.0,
            size,
            tester.element(textFinder),
          );
          
          // Allow some tolerance for clamping
          expect(
            fontSize,
            closeTo(expectedFontSize, expectedFontSize * 0.2),
            reason: 'Font size should scale proportionally at ${size.width}x${size.height}',
          );
        },
      );
    }
  }
  
  /// Test that a widget maintains aspect ratio across screen sizes
  /// 
  /// [widget] - The widget to test
  /// [finder] - Finder to locate the widget
  /// [expectedAspectRatio] - Expected aspect ratio
  /// [sizes] - List of screen sizes to test (default: all device sizes)
  /// [tolerance] - Allowed tolerance for aspect ratio differences (default: 0.05)
  static void testAspectRatio({
    required Widget widget,
    required Finder finder,
    required double expectedAspectRatio,
    List<Size>? sizes,
    double tolerance = 0.05,
  }) {
    final testSizes = sizes ?? DeviceSizes.getAll();
    
    for (final size in testSizes) {
      testWidgets(
        'Test aspect ratio at ${size.width}x${size.height}',
        (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(size: size),
                child: widget,
              ),
            ),
          );
          
          await tester.pumpAndSettle();
          
          final renderBox = tester.renderObject<RenderBox>(finder);
          final actualAspectRatio = renderBox.size.width / renderBox.size.height;
          
          expect(
            actualAspectRatio,
            closeTo(expectedAspectRatio, tolerance),
            reason: 'Aspect ratio should be maintained at ${size.width}x${size.height}',
          );
        },
      );
    }
  }
  
  /// Test that a widget is visible and not clipped at different screen sizes
  /// 
  /// [widget] - The widget to test
  /// [finder] - Finder to locate the widget
  /// [sizes] - List of screen sizes to test (default: all device sizes)
  static void testVisibility({
    required Widget widget,
    required Finder finder,
    List<Size>? sizes,
  }) {
    final testSizes = sizes ?? DeviceSizes.getAll();
    
    for (final size in testSizes) {
      testWidgets(
        'Test visibility at ${size.width}x${size.height}',
        (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(size: size),
                child: widget,
              ),
            ),
          );
          
          await tester.pumpAndSettle();
          
          expect(
            finder,
            findsOneWidget,
            reason: 'Widget should be visible at ${size.width}x${size.height}',
          );
          
          final renderBox = tester.renderObject<RenderBox>(finder);
          final position = renderBox.localToGlobal(Offset.zero);
          
          // Check that widget is within screen bounds
          expect(
            position.dx,
            greaterThanOrEqualTo(0.0),
            reason: 'Widget should not be clipped horizontally at ${size.width}x${size.height}',
          );
          
          expect(
            position.dy,
            greaterThanOrEqualTo(0.0),
            reason: 'Widget should not be clipped vertically at ${size.width}x${size.height}',
          );
        },
      );
    }
  }
  
  /// Create a MediaQuery widget with specific screen size
  /// 
  /// [child] - Child widget
  /// [size] - Screen size
  /// [textScaleFactor] - Text scale factor (default: 1.0)
  static Widget withScreenSize({
    required Widget child,
    required Size size,
    double textScaleFactor = 1.0,
  }) {
    return MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaleFactor: textScaleFactor,
      ),
      child: child,
    );
  }
  
  /// Create a MaterialApp with specific screen size
  /// 
  /// [home] - Home widget
  /// [size] - Screen size
  /// [textScaleFactor] - Text scale factor (default: 1.0)
  static Widget materialAppWithSize({
    required Widget home,
    required Size size,
    double textScaleFactor = 1.0,
  }) {
    return MaterialApp(
      home: withScreenSize(
        child: home,
        size: size,
        textScaleFactor: textScaleFactor,
      ),
    );
  }
}


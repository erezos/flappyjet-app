/// Tests for ResponsiveConfig utility class
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flappy_jet_pro/ui/utils/responsive_config.dart';

void main() {
  group('ResponsiveConfig', () {
    // Reference device size
    final referenceSize = const Size(375.0, 667.0);
    
    // Small phone (iPhone SE)
    final smallPhone = const Size(320.0, 568.0);
    
    // Medium phone (iPhone 14)
    final mediumPhone = const Size(390.0, 844.0);
    
    // Large phone (iPhone 14 Pro Max)
    final largePhone = const Size(428.0, 926.0);
    
    // Tablet (iPad)
    final tablet = const Size(768.0, 1024.0);
    
    // Large tablet (iPad Pro)
    final largeTablet = const Size(1024.0, 1366.0);

    group('Device Category Detection', () {
      test('isMobile returns true for phones', () {
        expect(ResponsiveConfig.isMobile(smallPhone), true);
        expect(ResponsiveConfig.isMobile(mediumPhone), true);
        expect(ResponsiveConfig.isMobile(largePhone), true);
      });

      test('isMobile returns false for tablets', () {
        expect(ResponsiveConfig.isMobile(tablet), false);
        expect(ResponsiveConfig.isMobile(largeTablet), false);
      });

      test('isTablet returns true for tablets', () {
        expect(ResponsiveConfig.isTablet(tablet), true);
      });

      test('isTablet returns false for phones and large tablets', () {
        expect(ResponsiveConfig.isTablet(smallPhone), false);
        expect(ResponsiveConfig.isTablet(largeTablet), false);
      });

      test('isLargeTablet returns true for large tablets', () {
        expect(ResponsiveConfig.isLargeTablet(largeTablet), true);
      });

      test('isLargeTablet returns false for phones and regular tablets', () {
        expect(ResponsiveConfig.isLargeTablet(smallPhone), false);
        expect(ResponsiveConfig.isLargeTablet(tablet), false);
      });
    });

    group('Responsive Sizing', () {
      test('responsiveSize scales proportionally', () {
        final baseSize = 100.0;
        
        // Reference device should return base size
        final referenceResult = ResponsiveConfig.responsiveSize(baseSize, referenceSize);
        expect(referenceResult, closeTo(baseSize, 0.1));
        
        // Larger device should scale up
        final largeResult = ResponsiveConfig.responsiveSize(baseSize, largePhone);
        expect(largeResult, greaterThan(baseSize));
        
        // Smaller device should scale down (but clamped)
        final smallResult = ResponsiveConfig.responsiveSize(baseSize, smallPhone);
        expect(smallResult, lessThanOrEqualTo(baseSize * 1.5)); // Max scale
        expect(smallResult, greaterThanOrEqualTo(baseSize * 0.8)); // Min scale
      });

      test('responsiveSize respects min/max scale', () {
        final baseSize = 100.0;
        
        // Test min scale
        final minResult = ResponsiveConfig.responsiveSize(
          baseSize,
          smallPhone,
          minScale: 0.5,
          maxScale: 2.0,
        );
        expect(minResult, greaterThanOrEqualTo(baseSize * 0.5));
        
        // Test max scale
        final maxResult = ResponsiveConfig.responsiveSize(
          baseSize,
          largeTablet,
          minScale: 0.5,
          maxScale: 2.0,
        );
        expect(maxResult, lessThanOrEqualTo(baseSize * 2.0));
      });
    });

    group('Responsive Font Size', () {
      testWidgets('responsiveFontSize accounts for text scale factor', (tester) async {
        final baseSize = 16.0;
        
        // Test with normal text scale
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(textScaleFactor: 1.0),
              child: Builder(
                builder: (context) {
                  final fontSize = ResponsiveConfig.responsiveFontSize(
                    baseSize,
                    referenceSize,
                    context,
                  );
                  expect(fontSize, closeTo(baseSize, 0.1));
                  return Container();
                },
              ),
            ),
          ),
        );
        
        // Test with larger text scale
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(textScaleFactor: 1.5),
              child: Builder(
                builder: (context) {
                  final fontSize = ResponsiveConfig.responsiveFontSize(
                    baseSize,
                    referenceSize,
                    context,
                  );
                  // Should be clamped to max 1.2
                  expect(fontSize, lessThanOrEqualTo(baseSize * 1.2));
                  return Container();
              },
              ),
            ),
          ),
        );
      });
    });

    group('Responsive Spacing', () {
      test('responsivePadding scales proportionally', () {
        final basePadding = 16.0;
        
        final referenceResult = ResponsiveConfig.responsivePadding(basePadding, referenceSize);
        expect(referenceResult, closeTo(basePadding, 0.1));
        
        final largeResult = ResponsiveConfig.responsivePadding(basePadding, largePhone);
        expect(largeResult, greaterThan(basePadding * 0.9)); // Min scale
      });

      test('responsiveEdgeInsets creates correct EdgeInsets', () {
        final basePadding = 16.0;
        final edgeInsets = ResponsiveConfig.responsiveEdgeInsets(basePadding, referenceSize);
        
        expect(edgeInsets.left, closeTo(basePadding, 0.1));
        expect(edgeInsets.right, closeTo(basePadding, 0.1));
        expect(edgeInsets.top, closeTo(basePadding, 0.1));
        expect(edgeInsets.bottom, closeTo(basePadding, 0.1));
      });

      test('responsiveEdgeInsetsSymmetric creates symmetric EdgeInsets', () {
        final horizontal = 20.0;
        final vertical = 16.0;
        final edgeInsets = ResponsiveConfig.responsiveEdgeInsetsSymmetric(
          horizontal: horizontal,
          vertical: vertical,
          screenSize: referenceSize,
        );
        
        expect(edgeInsets.left, closeTo(horizontal, 0.1));
        expect(edgeInsets.right, closeTo(horizontal, 0.1));
        expect(edgeInsets.top, closeTo(vertical, 0.1));
        expect(edgeInsets.bottom, closeTo(vertical, 0.1));
      });
    });

    group('Responsive Popup Sizing', () {
      test('responsivePopupWidth returns correct width for mobile', () {
        final width = ResponsiveConfig.responsivePopupWidth(smallPhone);
        expect(width, greaterThanOrEqualTo(300.0));
        expect(width, lessThanOrEqualTo(500.0));
        // Small phone: 320 * 0.9 = 288, but clamped to min 300
        expect(width, equals(300.0));
      });

      test('responsivePopupWidth returns correct width for tablet', () {
        final width = ResponsiveConfig.responsivePopupWidth(tablet);
        expect(width, greaterThanOrEqualTo(300.0));
        expect(width, lessThanOrEqualTo(500.0));
        // Tablet: 768 * 0.85 = 652.8, but clamped to max 500
        expect(width, equals(500.0));
      });

      test('responsivePopupWidth returns correct width for large tablet', () {
        final width = ResponsiveConfig.responsivePopupWidth(largeTablet);
        expect(width, greaterThanOrEqualTo(300.0));
        expect(width, lessThanOrEqualTo(500.0));
        // Large tablet: 1024 * 0.8 = 819.2, but clamped to max 500
        expect(width, equals(500.0));
      });
      
      test('responsivePopupWidth respects custom parameters', () {
        final width = ResponsiveConfig.responsivePopupWidth(
          mediumPhone,
          percent: 0.95,
          minWidth: 350.0,
          maxWidth: 450.0,
        );
        expect(width, greaterThanOrEqualTo(350.0));
        expect(width, lessThanOrEqualTo(450.0));
      });

      test('responsivePopupHeight respects min/max constraints', () {
        final height = ResponsiveConfig.responsivePopupHeight(smallPhone);
        expect(height, greaterThanOrEqualTo(400.0));
        expect(height, lessThanOrEqualTo(800.0));
      });
    });

    group('Responsive Icon Sizing', () {
      test('responsiveIconSize scales proportionally', () {
        final baseSize = 24.0;
        
        final referenceResult = ResponsiveConfig.responsiveIconSize(baseSize, referenceSize);
        expect(referenceResult, closeTo(baseSize, 0.1));
        
        final largeResult = ResponsiveConfig.responsiveIconSize(baseSize, largePhone);
        expect(largeResult, greaterThan(baseSize * 0.9));
      });
    });

    group('Responsive Button Sizing', () {
      test('responsiveButtonHeight scales proportionally', () {
        final baseHeight = 48.0;
        
        final referenceResult = ResponsiveConfig.responsiveButtonHeight(baseHeight, referenceSize);
        expect(referenceResult, closeTo(baseHeight, 0.1));
        
        final largeResult = ResponsiveConfig.responsiveButtonHeight(baseHeight, largePhone);
        expect(largeResult, greaterThan(baseHeight * 0.9));
      });
    });

    group('Aspect Ratio Helpers', () {
      test('responsiveAspectRatio adjusts for device type', () {
        final baseAspectRatio = 0.9;
        
        final mobileRatio = ResponsiveConfig.responsiveAspectRatio(
          smallPhone,
          baseAspectRatio,
          2,
        );
        expect(mobileRatio, closeTo(baseAspectRatio * 0.9, 0.01));
        
        final tabletRatio = ResponsiveConfig.responsiveAspectRatio(
          tablet,
          baseAspectRatio,
          2,
        );
        expect(tabletRatio, closeTo(baseAspectRatio * 1.0, 0.01));
        
        final largeTabletRatio = ResponsiveConfig.responsiveAspectRatio(
          largeTablet,
          baseAspectRatio,
          2,
        );
        expect(largeTabletRatio, closeTo(baseAspectRatio * 1.1, 0.01));
      });
    });

    group('Scaling Factors', () {
      test('getScaleFactor returns correct scale', () {
        final referenceScale = ResponsiveConfig.getScaleFactor(referenceSize);
        expect(referenceScale, closeTo(1.0, 0.1));
        
        final largeScale = ResponsiveConfig.getScaleFactor(largePhone);
        expect(largeScale, greaterThan(1.0));
        expect(largeScale, lessThanOrEqualTo(1.5)); // Max scale
      });

      test('getDeviceScaleFactor returns device-specific scale', () {
        expect(ResponsiveConfig.getDeviceScaleFactor(smallPhone), 1.0);
        expect(ResponsiveConfig.getDeviceScaleFactor(tablet), 1.2);
        expect(ResponsiveConfig.getDeviceScaleFactor(largeTablet), 1.4);
      });
    });
  });
}


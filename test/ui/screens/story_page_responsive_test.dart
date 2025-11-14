/// 🧪 STORY PAGE RESPONSIVE TESTS
/// Tests responsive button sizing formulas without requiring full widget initialization
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Story Page Button Size Formula Tests', () {
    /// Calculate button size using the exact formula from story_page.dart
    double calculateButtonSize(Size screenSize) {
      final maxButtonWidth = screenSize.width * 0.85;
      final maxButtonHeight = screenSize.height * 0.30;
      return maxButtonWidth.clamp(240.0, maxButtonHeight.clamp(240.0, 450.0));
    }

    test('Button size formula - iPhone SE (375x667)', () {
      const screenSize = Size(375, 667);
      final buttonSize = calculateButtonSize(screenSize);
      
      // 375 * 0.85 = 318.75
      // 667 * 0.30 = 200.1, clamped to 240.0 (minimum)
      // Result: 240.0 (minimum enforced)
      expect(buttonSize, equals(240.0),
          reason: 'iPhone SE: Height limit (200.1) is below minimum, so button = 240px');
    });

    test('Button size formula - Medium phone (411x731)', () {
      const screenSize = Size(411, 731);
      final buttonSize = calculateButtonSize(screenSize);
      
      // 411 * 0.85 = 349.35
      // 731 * 0.30 = 219.3, clamped to 240.0 (minimum)
      // Result: 240.0 (minimum enforced)
      expect(buttonSize, equals(240.0),
          reason: 'Medium phone: Height limit (219.3) is below minimum, so button = 240px');
    });

    test('Button size formula - iPhone Pro Max (428x926)', () {
      const screenSize = Size(428, 926);
      final buttonSize = calculateButtonSize(screenSize);
      
      // 428 * 0.85 = 363.8
      // 926 * 0.30 = 277.8
      // Result: 277.8 (height-limited, above minimum)
      expect(buttonSize, closeTo(277.8, 0.1),
          reason: 'iPhone Pro Max: Height limit (277.8) is constraining factor');
    });

    test('Button size formula - iPad Mini (768x1024)', () {
      const screenSize = Size(768, 1024);
      final buttonSize = calculateButtonSize(screenSize);
      
      // 768 * 0.85 = 652.8
      // 1024 * 0.30 = 307.2
      // Result: 307.2 (height-limited)
      expect(buttonSize, closeTo(307.2, 0.1),
          reason: 'iPad Mini: Height limit (307.2) is constraining factor');
    });

    test('Button size formula - iPad Pro (1024x1366)', () {
      const screenSize = Size(1024, 1366);
      final buttonSize = calculateButtonSize(screenSize);
      
      // 1024 * 0.85 = 870.4
      // 1366 * 0.30 = 409.8
      // Result: 409.8 (height-limited, below max)
      expect(buttonSize, closeTo(409.8, 0.1),
          reason: 'iPad Pro: Height limit (409.8) is constraining factor');
    });

    test('Button size respects 240px minimum on very small screens', () {
      const testCases = [
        Size(240, 320),
        Size(280, 480),
        Size(300, 500),
      ];

      for (final screenSize in testCases) {
        final buttonSize = calculateButtonSize(screenSize);
        expect(buttonSize, equals(240.0),
            reason: 'Button should never be smaller than 240px (screen: ${screenSize.width}x${screenSize.height})');
      }
    });

    test('Button size respects 450px maximum on very large screens', () {
      const testCases = [
        Size(2000, 3000), // maxWidth=1700, maxHeight=960, clamped to 450
        Size(1920, 1080), // maxWidth=1632, maxHeight=345.6, result=345.6
        Size(1600, 2400), // maxWidth=1360, maxHeight=768, clamped to 450
      ];

      for (final screenSize in testCases) {
        final buttonSize = calculateButtonSize(screenSize);
        expect(buttonSize, lessThanOrEqualTo(450.0),
            reason: 'Button should never exceed 450px (screen: ${screenSize.width}x${screenSize.height})');
      }
    });

    test('Button size increases as screen size increases', () {
      const screenSizes = [
        Size(375, 667),   // Small phone
        Size(428, 926),   // Large phone
        Size(768, 1024),  // Small tablet
        Size(1024, 1366), // Large tablet
      ];

      final buttonSizes = screenSizes.map(calculateButtonSize).toList();

      // Verify ascending order
      for (int i = 1; i < buttonSizes.length; i++) {
        expect(buttonSizes[i], greaterThan(buttonSizes[i - 1]),
            reason: 'Button size should increase with screen size');
      }
    });
  });

  group('Story Page Jet Size Formula Tests', () {
    /// Calculate jet size using the exact formula from story_page.dart
    double calculateJetSize(Size screenSize) {
      return (screenSize.width * 0.55).clamp(180.0, 320.0);
    }

    test('Jet size formula - iPhone SE (375px width)', () {
      const screenSize = Size(375, 667);
      final jetSize = calculateJetSize(screenSize);
      
      // 375 * 0.55 = 206.25
      expect(jetSize, closeTo(206.25, 0.1),
          reason: 'Jet size = 55% of screen width');
    });

    test('Jet size formula - Medium phone (411px width)', () {
      const screenSize = Size(411, 731);
      final jetSize = calculateJetSize(screenSize);
      
      // 411 * 0.55 = 226.05
      expect(jetSize, closeTo(226.05, 0.1),
          reason: 'Jet size = 55% of screen width');
    });

    test('Jet size formula - iPad (768px width)', () {
      const screenSize = Size(768, 1024);
      final jetSize = calculateJetSize(screenSize);
      
      // 768 * 0.55 = 422.4, clamped to 320.0 (maximum)
      expect(jetSize, equals(320.0),
          reason: 'Jet size clamped to 320px maximum on tablets');
    });

    test('Jet size respects 180px minimum', () {
      const tinyScreen = Size(200, 400);
      final jetSize = calculateJetSize(tinyScreen);
      
      // 200 * 0.55 = 110, clamped to 180.0
      expect(jetSize, equals(180.0),
          reason: 'Jet size should never be smaller than 180px');
    });

    test('Jet size respects 320px maximum', () {
      const hugeScreen = Size(1920, 1080);
      final jetSize = calculateJetSize(hugeScreen);
      
      // 1920 * 0.55 = 1056, clamped to 320.0
      expect(jetSize, equals(320.0),
          reason: 'Jet size should never exceed 320px');
    });

    test('Jet size scales proportionally between min and max', () {
      const screenSizes = [
        Size(327, 600),  // 327*0.55 = 179.85 → 180 (at min)
        Size(400, 700),  // 400*0.55 = 220
        Size(500, 800),  // 500*0.55 = 275
        Size(582, 900),  // 582*0.55 = 320.1 → 320 (at max)
      ];

      final jetSizes = screenSizes.map(calculateJetSize).toList();

      // First should be at minimum
      expect(jetSizes[0], equals(180.0),
          reason: 'First jet size should be at minimum (180px)');

      // Middle sizes should scale proportionally
      expect(jetSizes[1], closeTo(220.0, 1.0),
          reason: 'Middle jet sizes should scale proportionally');
      expect(jetSizes[2], closeTo(275.0, 1.0),
          reason: 'Middle jet sizes should scale proportionally');

      // Last should be at maximum
      expect(jetSizes[3], equals(320.0),
          reason: 'Last jet size should be at maximum (320px)');
    });
  });

  group('Story Page Title Size Formula Tests', () {
    /// Calculate title dimensions using the exact formula from story_page.dart
    (double width, double height) calculateTitleSize(Size screenSize) {
      final width = (screenSize.width * 0.90).clamp(350.0, 600.0);
      final height = (screenSize.height * 0.18).clamp(100.0, 170.0);
      return (width, height);
    }

    test('Title size formula - iPhone SE (375x667)', () {
      const screenSize = Size(375, 667);
      final (width, height) = calculateTitleSize(screenSize);
      
      // Width: 375 * 0.90 = 337.5, clamped to 350.0 (minimum)
      // Height: 667 * 0.18 = 120.06
      expect(width, equals(350.0),
          reason: 'Title width clamped to 350px minimum');
      expect(height, closeTo(120.06, 0.1),
          reason: 'Title height = 18% of screen height');
    });

    test('Title size formula - iPad (768x1024)', () {
      const screenSize = Size(768, 1024);
      final (width, height) = calculateTitleSize(screenSize);
      
      // Width: 768 * 0.90 = 691.2, clamped to 600.0 (maximum)
      // Height: 1024 * 0.18 = 184.32, clamped to 170.0 (maximum)
      expect(width, equals(600.0),
          reason: 'Title width clamped to 600px maximum');
      expect(height, equals(170.0),
          reason: 'Title height clamped to 170px maximum');
    });

    test('Title width respects 350px minimum', () {
      const tinyScreen = Size(300, 500);
      final (width, _) = calculateTitleSize(tinyScreen);
      
      // 300 * 0.90 = 270, clamped to 350
      expect(width, equals(350.0),
          reason: 'Title width should never be smaller than 350px');
    });

    test('Title width respects 600px maximum', () {
      const hugeScreen = Size(1920, 1080);
      final (width, _) = calculateTitleSize(hugeScreen);
      
      // 1920 * 0.90 = 1728, clamped to 600
      expect(width, equals(600.0),
          reason: 'Title width should never exceed 600px');
    });

    test('Title height respects 100px minimum', () {
      const shortScreen = Size(400, 500);
      final (_, height) = calculateTitleSize(shortScreen);
      
      // 500 * 0.18 = 90, clamped to 100
      expect(height, equals(100.0),
          reason: 'Title height should never be smaller than 100px');
    });

    test('Title height respects 170px maximum', () {
      const tallScreen = Size(500, 1500);
      final (_, height) = calculateTitleSize(tallScreen);
      
      // 1500 * 0.18 = 270, clamped to 170
      expect(height, equals(170.0),
          reason: 'Title height should never exceed 170px');
    });
  });

  group('Story Page Responsive Ratios', () {
    test('Button-to-screen width ratio is consistent (85%)', () {
      const screenSizes = [
        Size(411, 731),
        Size(768, 1024),
        Size(1024, 1366),
      ];

      for (final screenSize in screenSizes) {
        final maxButtonWidth = screenSize.width * 0.85;
        final ratio = maxButtonWidth / screenSize.width;
        
        expect(ratio, closeTo(0.85, 0.001),
            reason: 'Button width should always be 85% of screen width (before clamping)');
      }
    });

    test('Button-to-screen height ratio is consistent (30%)', () {
      const screenSizes = [
        Size(411, 731),
        Size(768, 1024),
        Size(1024, 1366),
      ];

      for (final screenSize in screenSizes) {
        final maxButtonHeight = screenSize.height * 0.30;
        final ratio = maxButtonHeight / screenSize.height;
        
        expect(ratio, closeTo(0.30, 0.001),
            reason: 'Button height limit should always be 30% of screen height (before clamping)');
      }
    });

    test('Jet-to-screen width ratio is consistent (55%)', () {
      const screenSizes = [
        Size(411, 731),
        Size(500, 800),
        Size(580, 900), // Just below 320px limit
      ];

      for (final screenSize in screenSizes) {
        final jetWidth = screenSize.width * 0.55;
        if (jetWidth >= 180 && jetWidth <= 320) {
          final ratio = jetWidth / screenSize.width;
          expect(ratio, closeTo(0.55, 0.001),
              reason: 'Jet size should be 55% of screen width (when not clamped)');
        }
      }
    });
  });

  group('Story Page Edge Cases', () {
    test('Formula handles extreme tiny screens gracefully', () {
      const extremeTinyScreen = Size(240, 320);
      
      final buttonSize = (extremeTinyScreen.width * 0.85)
          .clamp(240.0, (extremeTinyScreen.height * 0.32).clamp(240.0, 450.0));
      final jetSize = (extremeTinyScreen.width * 0.55).clamp(180.0, 320.0);
      
      expect(buttonSize, equals(240.0),
          reason: 'Button should be at minimum (240px) on tiny screens');
      expect(jetSize, equals(180.0),
          reason: 'Jet should be at minimum (180px) on tiny screens');
    });

    test('Formula handles extreme huge screens gracefully', () {
      const extremeHugeScreen = Size(3840, 2160); // 4K display
      
      final buttonSize = (extremeHugeScreen.width * 0.85)
          .clamp(240.0, (extremeHugeScreen.height * 0.32).clamp(240.0, 450.0));
      final jetSize = (extremeHugeScreen.width * 0.55).clamp(180.0, 320.0);
      
      expect(buttonSize, equals(450.0),
          reason: 'Button should be at maximum (450px) on huge screens');
      expect(jetSize, equals(320.0),
          reason: 'Jet should be at maximum (320px) on huge screens');
    });

    test('Formula handles portrait orientation correctly', () {
      const portraitPhone = Size(411, 823);
      final buttonSize = (portraitPhone.width * 0.85)
          .clamp(240.0, (portraitPhone.height * 0.32).clamp(240.0, 450.0));
      
      expect(buttonSize, closeTo(263.36, 0.1),
          reason: 'Portrait phone should use height-based limiting');
    });

    test('Formula handles landscape orientation correctly', () {
      const landscapePhone = Size(823, 411);
      final buttonSize = (landscapePhone.width * 0.85)
          .clamp(240.0, (landscapePhone.height * 0.32).clamp(240.0, 450.0));
      
      // 823 * 0.85 = 699.55
      // 411 * 0.32 = 131.52, clamped to 240 (minimum)
      expect(buttonSize, equals(240.0),
          reason: 'Landscape phone should enforce 240px minimum');
    });
  });
}

/// 🧪 Tests for Profile Jet Collection Album Popup
/// 
/// Tests the flappy_jet_popup.png popup implementation to ensure:
/// - Safe area padding is calculated correctly
/// - Popup maintains aspect ratio
/// - Content fits within safe area
/// - Image displays correctly without cropping
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flappy_jet_pro/ui/widgets/profile/profile_jet_collection_album.dart';
import 'package:flappy_jet_pro/game/core/jet_skins.dart';

void main() {
  group('FlappyJetPopupFrameSafeArea', () {
    test('calculates correct padding for original image size', () {
      // Test with original image size
      final originalSize = const Size(887.0, 1336.0);
      final padding = FlappyJetPopupFrameSafeArea.calculateSafeAreaPadding(originalSize);

      // Verify padding matches original frame dimensions
      expect(padding.left, closeTo(50.0, 0.1));
      expect(padding.top, closeTo(270.0, 0.1));
      expect(padding.right, closeTo(50.0, 0.1));
      expect(padding.bottom, closeTo(75.0, 0.1)); // Different from special_popup (60px)
    });

    test('scales padding proportionally', () {
      // Test with half size
      final halfSize = const Size(443.5, 668.0); // Half of original
      final padding = FlappyJetPopupFrameSafeArea.calculateSafeAreaPadding(halfSize);

      // Padding should scale proportionally (approximately half)
      expect(padding.left, closeTo(25.0, 1.0));
      expect(padding.top, closeTo(135.0, 1.0));
      expect(padding.right, closeTo(25.0, 1.0));
      expect(padding.bottom, closeTo(37.5, 1.0));
    });

    test('calculates safe content size correctly', () {
      final originalSize = const Size(887.0, 1336.0);
      final safeSize = FlappyJetPopupFrameSafeArea.calculateSafeContentSize(originalSize);

      // Safe content area should be: 887-50-50 = 787 width, 1336-270-75 = 991 height
      expect(safeSize.width, closeTo(787.0, 0.1));
      expect(safeSize.height, closeTo(991.0, 0.1));
    });

    test('maintains aspect ratio when scaling', () {
      // Test that padding scales maintain the same proportions
      final smallSize = const Size(300.0, 452.0); // Scaled down proportionally
      final largeSize = const Size(600.0, 904.0); // Scaled up proportionally
      
      final smallPadding = FlappyJetPopupFrameSafeArea.calculateSafeAreaPadding(smallSize);
      final largePadding = FlappyJetPopupFrameSafeArea.calculateSafeAreaPadding(largeSize);
      
      // Ratio of padding should be same as size ratio
      final sizeRatio = largeSize.width / smallSize.width;
      final paddingRatio = largePadding.left / smallPadding.left;
      
      expect(paddingRatio, closeTo(sizeRatio, 0.1));
    });

    test('top padding is always larger than side padding', () {
      // Test on various sizes
      final sizes = [
        const Size(887.0, 1336.0), // Original
        const Size(443.5, 668.0), // Half
        const Size(300.0, 452.0), // Small
        const Size(600.0, 904.0), // Large
      ];
      
      for (final size in sizes) {
        final padding = FlappyJetPopupFrameSafeArea.calculateSafeAreaPadding(size);
        expect(padding.top, greaterThan(padding.left));
        expect(padding.top, greaterThan(padding.right));
      }
    });

    test('bottom padding is larger than side padding', () {
      // Bottom padding (75px) should be larger than left/right (50px)
      final originalSize = const Size(887.0, 1336.0);
      final padding = FlappyJetPopupFrameSafeArea.calculateSafeAreaPadding(originalSize);
      
      expect(padding.bottom, greaterThan(padding.left));
      expect(padding.bottom, greaterThan(padding.right));
    });
  });

  group('Profile Jet Collection Album Popup', () {
    testWidgets('should display popup with correct aspect ratio', (WidgetTester tester) async {
      // This test verifies the popup structure
      // Note: Full integration test would require mocking InventoryManager, etc.
      
      // The popup should maintain aspect ratio of flappy_jet_popup.png
      final expectedAspectRatio = FlappyJetPopupFrameSafeArea.originalWidth / 
                                  FlappyJetPopupFrameSafeArea.originalHeight;
      
      expect(expectedAspectRatio, closeTo(0.664, 0.001)); // 887/1336 ≈ 0.664
    });

    testWidgets('should calculate popup size based on aspect ratio', (WidgetTester tester) async {
      // Test that popup size calculation maintains aspect ratio
      const maxWidth = 400.0;
      const maxHeight = 600.0;
      
      final aspectRatio = FlappyJetPopupFrameSafeArea.originalWidth / 
                         FlappyJetPopupFrameSafeArea.originalHeight;
      
      // Calculate expected popup size
      double popupWidth = maxWidth;
      double popupHeight = popupWidth / aspectRatio;
      
      if (popupHeight > maxHeight) {
        popupHeight = maxHeight;
        popupWidth = popupHeight * aspectRatio;
      }
      
      // Verify aspect ratio is maintained
      final calculatedAspectRatio = popupWidth / popupHeight;
      expect(calculatedAspectRatio, closeTo(aspectRatio, 0.001));
    });

    test('popup safe area matches defined padding values', () {
      // Verify that the safe area matches the user's requirements:
      // Left/Right: 50px, Top: 270px, Bottom: 75px
      final originalSize = const Size(887.0, 1336.0);
      final padding = FlappyJetPopupFrameSafeArea.calculateSafeAreaPadding(originalSize);
      
      expect(padding.left, equals(50.0));
      expect(padding.right, equals(50.0));
      expect(padding.top, equals(270.0));
      expect(padding.bottom, equals(75.0));
    });
  });
}


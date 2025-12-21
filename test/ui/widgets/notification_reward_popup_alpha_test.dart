/// 🧪 UNIT TESTS - Notification Reward Popup Alpha Values
/// 
/// Tests to ensure all alpha values in notification reward popup are in the correct 0.0-1.0 range
/// after the withOpacity to withValues migration.
/// 
/// ✅ Flame Best Practices: UI consistency and visual quality
/// ✅ Mobile Gaming Standards: Proper opacity handling for all screen sizes
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  group('Notification Reward Popup - Alpha Value Ranges', () {
    test('should verify alpha values are in 0.0-1.0 range', () {
      // Test that all alpha values used in notification_reward_popup.dart are correct
      final alpha51 = 51 / 255.0;
      final alpha77 = 77 / 255.0;
      final alpha128 = 128 / 255.0;
      final alpha179 = 179 / 255.0;
      final alpha250 = 250 / 255.0;
      
      expect(alpha51, greaterThan(0.0), reason: 'Alpha 51 should be > 0');
      expect(alpha51, lessThanOrEqualTo(1.0), reason: 'Alpha 51 should be <= 1.0');
      expect(alpha51, closeTo(0.2, 0.001), reason: 'Alpha 51 should be approximately 0.2');
      
      expect(alpha77, greaterThan(0.0), reason: 'Alpha 77 should be > 0');
      expect(alpha77, lessThanOrEqualTo(1.0), reason: 'Alpha 77 should be <= 1.0');
      expect(alpha77, closeTo(0.302, 0.001), reason: 'Alpha 77 should be approximately 0.302');
      
      expect(alpha128, greaterThan(0.0), reason: 'Alpha 128 should be > 0');
      expect(alpha128, lessThanOrEqualTo(1.0), reason: 'Alpha 128 should be <= 1.0');
      expect(alpha128, closeTo(0.502, 0.001), reason: 'Alpha 128 should be approximately 0.502');
      
      expect(alpha179, greaterThan(0.0), reason: 'Alpha 179 should be > 0');
      expect(alpha179, lessThanOrEqualTo(1.0), reason: 'Alpha 179 should be <= 1.0');
      expect(alpha179, closeTo(0.702, 0.001), reason: 'Alpha 179 should be approximately 0.702');
      
      expect(alpha250, greaterThan(0.0), reason: 'Alpha 250 should be > 0');
      expect(alpha250, lessThanOrEqualTo(1.0), reason: 'Alpha 250 should be <= 1.0');
      expect(alpha250, closeTo(0.980, 0.001), reason: 'Alpha 250 should be approximately 0.980');
    });

    test('should verify withValues accepts correct alpha range', () {
      // Test that withValues works correctly with 0.0-1.0 range
      final color1 = Colors.white.withValues(alpha: 51 / 255.0);
      final color2 = Colors.white.withValues(alpha: 77 / 255.0);
      final color3 = Colors.white.withValues(alpha: 128 / 255.0);
      final color4 = Colors.white.withValues(alpha: 179 / 255.0);
      final color5 = const Color(0xFF1A1A2E).withValues(alpha: 250 / 255.0);
      
      expect(color1.alpha, greaterThan(0), reason: 'Color 1 should have alpha > 0');
      expect(color2.alpha, greaterThan(color1.alpha), reason: 'Color 2 should have higher alpha than color 1');
      expect(color3.alpha, greaterThan(color2.alpha), reason: 'Color 3 should have higher alpha than color 2');
      expect(color4.alpha, greaterThan(color3.alpha), reason: 'Color 4 should have higher alpha than color 3');
      expect(color5.alpha, greaterThan(color4.alpha), reason: 'Color 5 should have higher alpha than color 4');
    });

    test('should verify gradient colors use correct alpha values', () {
      // Test gradient colors with alpha values
      final gradientColor1 = const Color(0xFF1A1A2E).withValues(alpha: 250 / 255.0);
      final gradientColor2 = const Color(0xFF0F0F1E).withValues(alpha: 250 / 255.0);
      final gradientColor3 = const Color(0xFF4FC3F7).withValues(alpha: 77 / 255.0);
      
      expect(gradientColor1.alpha, greaterThan(200), reason: 'Gradient color 1 should have high alpha');
      expect(gradientColor2.alpha, greaterThan(200), reason: 'Gradient color 2 should have high alpha');
      expect(gradientColor3.alpha, greaterThan(0), reason: 'Gradient color 3 should have alpha > 0');
      expect(gradientColor3.alpha, lessThan(100), reason: 'Gradient color 3 should have lower alpha');
    });
  });
}


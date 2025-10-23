/// 🎨 BUTTON COLOR SYSTEM - Modern Casual Style
/// 
/// Centralized color schemes for all game buttons.
/// Primary: Light blue (requested style)
library;

import 'package:flutter/material.dart';

/// Button style variants
enum ModernButtonStyle {
  /// Light blue - Primary action buttons
  primary,
  
  /// Lighter blue - Secondary actions
  secondary,
  
  /// Green - Success states (level complete)
  success,
  
  /// Red - Danger states (level failed, destructive actions)
  danger,
  
  /// Gold - Special actions, premium features
  gold,
}

/// Centralized button color schemes
class ButtonColorScheme {
  /// Get gradient colors for a button style
  static List<Color> getGradient(ModernButtonStyle style) {
    return _gradients[style] ?? _gradients[ModernButtonStyle.primary]!;
  }
  
  /// Get shadow color for a button style
  static Color getShadowColor(ModernButtonStyle style) {
    return _shadowColors[style] ?? _shadowColors[ModernButtonStyle.primary]!;
  }
  
  /// Get border color for a button style
  static Color getBorderColor(ModernButtonStyle style, {bool pressed = false}) {
    return pressed ? Colors.black38 : Colors.black26;
  }
  
  /// Gradient definitions - Top to Bottom
  static const Map<ModernButtonStyle, List<Color>> _gradients = {
    // Light green - Modern casual style (testing new color)
    ModernButtonStyle.primary: [
      Color(0xFF4CAF50), // Light green top
      Color(0xFF388E3C), // Darker green bottom
    ],
    
    // Lighter blue - Secondary actions
    ModernButtonStyle.secondary: [
      Color(0xFF87CEEB), // Sky blue top
      Color(0xFF5EB3FF), // Light blue bottom
    ],
    
    // Green - Success/Complete
    ModernButtonStyle.success: [
      Color(0xFF4CAF50), // Green top
      Color(0xFF388E3C), // Dark green bottom
    ],
    
    // Red - Danger/Failed
    ModernButtonStyle.danger: [
      Color(0xFFF44336), // Red top
      Color(0xFFD32F2F), // Dark red bottom
    ],
    
    // Gold - Special/Premium
    ModernButtonStyle.gold: [
      Color(0xFFFFD700), // Gold top
      Color(0xFFFFA500), // Orange bottom
    ],
  };
  
  /// Shadow color definitions
  static const Map<ModernButtonStyle, Color> _shadowColors = {
    ModernButtonStyle.primary: Color(0x66388E3C), // Green shadow
    ModernButtonStyle.secondary: Color(0x665EB3FF), // Light blue shadow
    ModernButtonStyle.success: Color(0x66388E3C), // Green shadow
    ModernButtonStyle.danger: Color(0x66D32F2F), // Red shadow
    ModernButtonStyle.gold: Color(0x66FFA500), // Gold shadow
  };
}


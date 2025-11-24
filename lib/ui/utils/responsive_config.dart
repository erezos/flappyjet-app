/// 📱 RESPONSIVE CONFIG - Centralized responsive design utilities
/// 
/// Provides consistent responsive sizing, spacing, and scaling across all components.
/// Follows Flutter best practices for mobile game responsive design.
library;

import 'package:flutter/material.dart';

/// Responsive design configuration and utilities
class ResponsiveConfig {
  // ========================================
  // BREAKPOINTS
  // ========================================
  
  /// Mobile breakpoint (phones)
  static const double mobileBreakpoint = 600;
  
  /// Tablet breakpoint (large tablets)
  static const double tabletBreakpoint = 900;
  
  // ========================================
  // REFERENCE DEVICE (Baseline)
  // = 13 mini / iPhone SE (baseline for scaling)
  // ========================================
  
  static const double referenceWidth = 375.0;
  static const double referenceHeight = 667.0;
  
  // ========================================
  // DEVICE CATEGORY DETECTION
  // ========================================
  
  /// Check if device is mobile (phone)
  static bool isMobile(Size screenSize) => screenSize.width < mobileBreakpoint;
  
  /// Check if device is tablet
  static bool isTablet(Size screenSize) => 
      screenSize.width >= mobileBreakpoint && screenSize.width < tabletBreakpoint;
  
  /// Check if device is large tablet
  static bool isLargeTablet(Size screenSize) => screenSize.width >= tabletBreakpoint;
  
  // ========================================
  // RESPONSIVE SIZING
  // ========================================
  
  /// Get responsive size based on screen width
  /// Scales proportionally from reference device
  /// 
  /// [baseSize] - Base size for reference device (375px width)
  /// [screenSize] - Current screen size
  /// [minScale] - Minimum scale factor (default 0.8)
  /// [maxScale] - Maximum scale factor (default 1.5)
  static double responsiveSize(
    double baseSize,
    Size screenSize, {
    double minScale = 0.8,
    double maxScale = 1.5,
  }) {
    final scaleFactor = screenSize.width / referenceWidth;
    final clampedScale = scaleFactor.clamp(minScale, maxScale);
    return baseSize * clampedScale;
  }
  
  /// Get responsive font size with text scale factor support
  /// 
  /// [baseSize] - Base font size for reference device
  /// [screenSize] - Current screen size
  /// [context] - BuildContext for MediaQuery
  /// [minScale] - Minimum scale factor (default 0.8)
  /// [maxScale] - Maximum scale factor (default 1.5)
  /// [textScaleMin] - Minimum text scale factor (default 0.8)
  /// [textScaleMax] - Maximum text scale factor (default 1.2)
  static double responsiveFontSize(
    double baseSize,
    Size screenSize,
    BuildContext context, {
    double minScale = 0.8,
    double maxScale = 1.5,
    double textScaleMin = 0.8,
    double textScaleMax = 1.2,
  }) {
    final scaleFactor = screenSize.width / referenceWidth;
    final clampedScale = scaleFactor.clamp(minScale, maxScale);
    final textScale = MediaQuery.of(context).textScaleFactor;
    final clampedTextScale = textScale.clamp(textScaleMin, textScaleMax);
    return (baseSize * clampedScale * clampedTextScale)
        .clamp(baseSize * minScale * textScaleMin, baseSize * maxScale * textScaleMax);
  }
  
  // ========================================
  // RESPONSIVE SPACING
  // ========================================
  
  /// Get responsive padding based on screen width
  /// 
  /// [basePadding] - Base padding for reference device
  /// [screenSize] - Current screen size
  static double responsivePadding(double basePadding, Size screenSize) {
    return responsiveSize(basePadding, screenSize, minScale: 0.9, maxScale: 1.3);
  }
  
  /// Get responsive EdgeInsets
  /// 
  /// [basePadding] - Base padding for reference device
  /// [screenSize] - Current screen size
  static EdgeInsets responsiveEdgeInsets(double basePadding, Size screenSize) {
    final padding = responsivePadding(basePadding, screenSize);
    return EdgeInsets.all(padding);
  }
  
  /// Get responsive EdgeInsets with different horizontal/vertical
  static EdgeInsets responsiveEdgeInsetsSymmetric({
    required double horizontal,
    required double vertical,
    required Size screenSize,
  }) {
    return EdgeInsets.symmetric(
      horizontal: responsivePadding(horizontal, screenSize),
      vertical: responsivePadding(vertical, screenSize),
    );
  }
  
  // ========================================
  // RESPONSIVE POPUP SIZING
  // ========================================
  
  /// Get responsive popup max width
  /// 
  /// [screenSize] - Current screen size
  /// [percent] - Percentage of screen width (default 0.9)
  /// [minWidth] - Minimum width (default 300)
  /// [maxWidth] - Maximum width (default 500)
  static double responsivePopupWidth(
    Size screenSize, {
    double percent = 0.9,
    double minWidth = 300.0,
    double maxWidth = 500.0,
  }) {
    if (isLargeTablet(screenSize)) {
      return (screenSize.width * 0.8).clamp(minWidth, maxWidth);
    } else if (isTablet(screenSize)) {
      return (screenSize.width * 0.85).clamp(minWidth, maxWidth);
    } else {
      return (screenSize.width * percent).clamp(minWidth, maxWidth);
    }
  }
  
  /// Get responsive popup max height
  /// 
  /// [screenSize] - Current screen size
  /// [percent] - Percentage of screen height (default 0.8)
  /// [minHeight] - Minimum height (default 400)
  /// [maxHeight] - Maximum height (default 800)
  static double responsivePopupHeight(
    Size screenSize, {
    double percent = 0.8,
    double minHeight = 400.0,
    double maxHeight = 800.0,
  }) {
    // Account for safe area
    final availableHeight = screenSize.height;
    return (availableHeight * percent).clamp(minHeight, maxHeight);
  }
  
  // ========================================
  // RESPONSIVE ICON SIZING
  // ========================================
  
  /// Get responsive icon size
  /// 
  /// [baseSize] - Base icon size for reference device
  /// [screenSize] - Current screen size
  static double responsiveIconSize(double baseSize, Size screenSize) {
    return responsiveSize(baseSize, screenSize, minScale: 0.9, maxScale: 1.4);
  }
  
  // ========================================
  // RESPONSIVE BUTTON SIZING
  // ========================================
  
  /// Get responsive button height
  /// 
  /// [baseHeight] - Base button height for reference device
  /// [screenSize] - Current screen size
  static double responsiveButtonHeight(double baseHeight, Size screenSize) {
    return responsiveSize(baseHeight, screenSize, minScale: 0.9, maxScale: 1.2);
  }
  
  // ========================================
  // ASPECT RATIO HELPERS
  // ========================================
  
  /// Calculate responsive aspect ratio for grid items
  /// 
  /// [screenSize] - Current screen size
  /// [baseAspectRatio] - Base aspect ratio for reference device
  /// [columns] - Number of columns in grid
  static double responsiveAspectRatio(
    Size screenSize,
    double baseAspectRatio,
    int columns,
  ) {
    if (isLargeTablet(screenSize)) {
      return baseAspectRatio * 1.1; // Slightly wider on large tablets
    } else if (isTablet(screenSize)) {
      return baseAspectRatio * 1.0; // Same on tablets
    } else {
      return baseAspectRatio * 0.9; // Slightly taller on mobile
    }
  }
  
  // ========================================
  // SCALING FACTORS
  // ========================================
  
  /// Get scaling factor for current device
  /// 
  /// [screenSize] - Current screen size
  static double getScaleFactor(Size screenSize) {
    return (screenSize.width / referenceWidth).clamp(0.8, 1.5);
  }
  
  /// Get device-specific scaling factor
  /// 
  /// [screenSize] - Current screen size
  static double getDeviceScaleFactor(Size screenSize) {
    if (isLargeTablet(screenSize)) {
      return 1.4;
    } else if (isTablet(screenSize)) {
      return 1.2;
    } else {
      return 1.0;
    }
  }
}


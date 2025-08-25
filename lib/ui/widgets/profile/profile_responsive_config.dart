/// 📱 Profile Responsive Configuration - Easy design changes and screen adaptation
import 'package:flutter/material.dart';

/// Responsive configuration for profile screen layout
class ProfileResponsiveConfig {
  final Size screenSize;
  final Orientation orientation;
  
  ProfileResponsiveConfig({
    required this.screenSize,
    required this.orientation,
  });
  
  /// Factory constructor from BuildContext
  factory ProfileResponsiveConfig.fromContext(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return ProfileResponsiveConfig(
      screenSize: mediaQuery.size,
      orientation: mediaQuery.orientation,
    );
  }
  
  // ========================================
  // BREAKPOINTS - Easy to adjust for different devices
  // ========================================
  
  bool get isMobile => screenSize.width < 600;
  bool get isTablet => screenSize.width >= 600 && screenSize.width < 1200;
  bool get isDesktop => screenSize.width >= 1200;
  bool get isLandscape => orientation == Orientation.landscape;
  
  // ========================================
  // SPACING CONFIGURATION - Change these to adjust layout
  // ========================================
  
  /// Top spacing from SafeArea
  double get topSpacing => screenSize.height * (isMobile ? 0.02 : 0.03);
  
    /// Spacing after profile header - MOVED HIGHER!
  double get headerBottomSpacing => screenSize.height * 0.005; // Minimal spacing to keep nickname banner close to PROFILE
  
  /// Spacing after nickname banner
  double get nicknameBottomSpacing => screenSize.height * (isMobile ? 0.04 : 0.06);
  
  /// Spacing after stats row
  double get statsBottomSpacing => screenSize.height * (isMobile ? 0.04 : 0.06);
  
  /// Spacing before action buttons
  double get jetPreviewBottomSpacing => screenSize.height * 0.02;
  
  /// Bottom spacing
  double get bottomSpacing => screenSize.height * 0.02;
  
  // ========================================
  // COMPONENT SIZING - Easy to adjust individual components
  // ========================================
  
  /// Profile header height (PROFILE text)
  double get profileHeaderHeight => screenSize.height * (isMobile ? 0.16 : 0.14);
  
  /// Nickname banner height - Increased to show full jets when banner is moved up
  double get nicknameBannerHeight => isMobile ? 250 : 280;
  
  /// Stats widget height
  double get statsWidgetHeight => isMobile ? 120 : 140;
  
  /// Jet preview width percentage
  double get jetPreviewWidthRatio => isMobile ? 0.7 : 0.6;
  
  /// Jet preview height percentage
  double get jetPreviewHeightRatio => isMobile ? 0.2 : 0.25;
  
  // ========================================
  // HORIZONTAL SPACING - Control horizontal layout
  // ========================================
  
  /// Main content horizontal padding
  EdgeInsets get contentPadding => EdgeInsets.symmetric(
    horizontal: isMobile ? 16.0 : 32.0,
  );
  
  /// Nickname banner extension (how far it extends beyond container)
  double get nicknameBannerExtension => isMobile ? 40 : 60;
  
  // ========================================
  // ADAPTIVE LAYOUT HELPERS
  // ========================================
  
  /// Get responsive font size
  double getResponsiveFontSize(double baseMobile) {
    if (isMobile) return baseMobile;
    if (isTablet) return baseMobile * 1.2;
    return baseMobile * 1.4;
  }
  
  /// Get responsive icon size
  double getResponsiveIconSize(double baseMobile) {
    if (isMobile) return baseMobile;
    if (isTablet) return baseMobile * 1.1;
    return baseMobile * 1.3;
  }
  
  /// Get responsive padding
  EdgeInsets getResponsivePadding(EdgeInsets baseMobile) {
    final multiplier = isMobile ? 1.0 : (isTablet ? 1.5 : 2.0);
    return EdgeInsets.only(
      left: baseMobile.left * multiplier,
      top: baseMobile.top * multiplier,
      right: baseMobile.right * multiplier,
      bottom: baseMobile.bottom * multiplier,
    );
  }
}

/// Quick access to common responsive values
extension ProfileResponsiveExtension on BuildContext {
  ProfileResponsiveConfig get profileConfig => ProfileResponsiveConfig.fromContext(this);
}

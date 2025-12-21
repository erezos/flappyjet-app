/// 🗺️ WORLD MAP LAYOUT SYSTEM
/// 
/// Defines all UI element positions on the world map and calculates exclusion zones
/// for node placement. Ensures nodes don't overlap with banners or overlays.
/// 
/// ✅ Responsive Design: All positions scale based on screen size
/// ✅ Flame Best Practices: Efficient calculations, clear separation of concerns
library;

import 'package:flutter/material.dart';
import '../utils/responsive_config.dart';

/// Represents a UI element zone (banner, overlay, etc.) on the world map
class UIElementZone {
  final String id;
  final Alignment alignment;
  final Size size;
  final EdgeInsets margin;
  final EdgeInsets exclusionPadding; // Extra space around element to avoid nodes
  
  const UIElementZone({
    required this.id,
    required this.alignment,
    required this.size,
    this.margin = EdgeInsets.zero,
    this.exclusionPadding = const EdgeInsets.all(20.0),
  });
  
  /// Calculate the actual position of this element on screen
  Rect getBounds(Size screenSize) {
    final double x, y;
    
    // Calculate position based on alignment
    switch (alignment) {
      case Alignment.topLeft:
        x = margin.left;
        y = margin.top;
        break;
      case Alignment.topRight:
        x = screenSize.width - size.width - margin.right;
        y = margin.top;
        break;
      case Alignment.topCenter:
        x = (screenSize.width - size.width) / 2 + margin.left - margin.right;
        y = margin.top;
        break;
      case Alignment.bottomLeft:
        x = margin.left;
        y = screenSize.height - size.height - margin.bottom;
        break;
      case Alignment.bottomRight:
        x = screenSize.width - size.width - margin.right;
        y = screenSize.height - size.height - margin.bottom;
        break;
      case Alignment.bottomCenter:
        x = (screenSize.width - size.width) / 2 + margin.left - margin.right;
        y = screenSize.height - size.height - margin.bottom;
        break;
      case Alignment.centerLeft:
        x = margin.left;
        y = (screenSize.height - size.height) / 2 + margin.top - margin.bottom;
        break;
      case Alignment.centerRight:
        x = screenSize.width - size.width - margin.right;
        y = (screenSize.height - size.height) / 2 + margin.top - margin.bottom;
        break;
      default:
        x = (screenSize.width - size.width) / 2 + margin.left - margin.right;
        y = (screenSize.height - size.height) / 2 + margin.top - margin.bottom;
    }
    
    return Rect.fromLTWH(
      x,
      y,
      size.width,
      size.height,
    );
  }
  
  /// Get exclusion zone (element bounds + padding) where nodes should not be placed
  Rect getExclusionZone(Size screenSize) {
    final bounds = getBounds(screenSize);
    return Rect.fromLTWH(
      bounds.left - exclusionPadding.left,
      bounds.top - exclusionPadding.top,
      bounds.width + exclusionPadding.left + exclusionPadding.right,
      bounds.height + exclusionPadding.top + exclusionPadding.bottom,
    );
  }
}

/// World Map Layout System
/// 
/// Defines all UI element positions and calculates exclusion zones for node placement.
/// Ensures responsive design and prevents visual conflicts.
class WorldMapLayout {
  final Size screenSize;
  final List<UIElementZone> _uiElements = [];
  
  WorldMapLayout(this.screenSize) {
    _initializeLayout();
  }
  
  /// Initialize all UI element positions (responsive)
  void _initializeLayout() {
    // ✅ NEW: Responsive sizing for homepage banners
    final bannerSize = ResponsiveConfig.responsiveSize(60.0, screenSize, minScale: 0.85, maxScale: 1.3);
    final bannerGap = ResponsiveConfig.responsivePadding(8.0, screenSize);
    
    // Top overlay heights (for balance, hearts)
    // Balance/Hearts are ~50-60px height, plus 12px top margin = ~70px
    // Add extra padding for visual spacing = ~90px
    final topOverlayHeight = ResponsiveConfig.responsivePadding(90.0, screenSize);
    
    // ✅ NEW: Bottom overlay height includes footer navigator only
    // Footer navigator: original 1490x391, aspect ratio ~0.262
    // Footer height = screenWidth * 0.262
    final footerHeight = screenSize.width * (391.0 / 1490.0);
    final bottomOverlayHeight = footerHeight + ResponsiveConfig.responsivePadding(16.0, screenSize);
    
    // Horizontal margins
    final horizontalMargin = ResponsiveConfig.responsivePadding(12.0, screenSize);
    
    // ✅ NEW: Calculate banner positions
    // Balance/Hearts are positioned at top: 12px, so banners start below them
    // Balance height ~50px, so banners start at ~12 + 50 + 8 (gap) = ~70px
    final balanceHeartsHeight = ResponsiveConfig.responsivePadding(50.0, screenSize);
    final topMargin = ResponsiveConfig.responsivePadding(12.0, screenSize);
    final balanceToBannerGap = ResponsiveConfig.responsivePadding(8.0, screenSize);
    
    // Top-left banners (under balance)
    final leftBanner1Top = topMargin + balanceHeartsHeight + balanceToBannerGap;
    final leftBanner2Top = leftBanner1Top + bannerSize + bannerGap;
    
    // Top-right banners (under hearts)
    final rightBanner1Top = topMargin + balanceHeartsHeight + balanceToBannerGap;
    final rightBanner2Top = rightBanner1Top + bannerSize + bannerGap;
    
    _uiElements.addAll([
      // ✅ NEW: Homepage Banner 1 (top-left, under balance)
      UIElementZone(
        id: 'homepage_banner_1_left',
        alignment: Alignment.topLeft,
        size: Size(bannerSize, bannerSize),
        margin: EdgeInsets.only(
          left: horizontalMargin,
          top: leftBanner1Top,
        ),
        exclusionPadding: EdgeInsets.all(ResponsiveConfig.responsivePadding(15.0, screenSize)),
      ),
      
      // ✅ NEW: Homepage Banner 2 (top-left, below banner 1)
      UIElementZone(
        id: 'homepage_banner_2_left',
        alignment: Alignment.topLeft,
        size: Size(bannerSize, bannerSize),
        margin: EdgeInsets.only(
          left: horizontalMargin,
          top: leftBanner2Top,
        ),
        exclusionPadding: EdgeInsets.all(ResponsiveConfig.responsivePadding(15.0, screenSize)),
      ),
      
      // ✅ NEW: Homepage Banner 3 (top-right, under hearts)
      UIElementZone(
        id: 'homepage_banner_3_right',
        alignment: Alignment.topRight,
        size: Size(bannerSize, bannerSize),
        margin: EdgeInsets.only(
          right: horizontalMargin,
          top: rightBanner1Top,
        ),
        exclusionPadding: EdgeInsets.all(ResponsiveConfig.responsivePadding(15.0, screenSize)),
      ),
      
      // ✅ NEW: Homepage Banner 4 (top-right, below banner 3)
      UIElementZone(
        id: 'homepage_banner_4_right',
        alignment: Alignment.topRight,
        size: Size(bannerSize, bannerSize),
        margin: EdgeInsets.only(
          right: horizontalMargin,
          top: rightBanner2Top,
        ),
        exclusionPadding: EdgeInsets.all(ResponsiveConfig.responsivePadding(15.0, screenSize)),
      ),
      
      // Top overlay zone (balance, hearts)
      UIElementZone(
        id: 'top_overlay',
        alignment: Alignment.topCenter,
        size: Size(screenSize.width, topOverlayHeight),
        margin: EdgeInsets.zero,
        exclusionPadding: EdgeInsets.zero, // Nodes already respect topPadding
      ),
      
      // Bottom overlay zone (footer navigator only)
      UIElementZone(
        id: 'bottom_overlay',
        alignment: Alignment.bottomCenter,
        size: Size(screenSize.width, bottomOverlayHeight),
        margin: EdgeInsets.zero,
        exclusionPadding: EdgeInsets.zero, // Nodes already respect bottomPadding
      ),
    ]);
  }
  
  /// Get all exclusion zones where nodes should not be placed
  List<Rect> getExclusionZones() {
    return _uiElements
        .where((element) => element.exclusionPadding != EdgeInsets.zero)
        .map((element) => element.getExclusionZone(screenSize))
        .toList();
  }
  
  /// Get top padding (for top overlay zone only - banners removed)
  /// 
  /// Calculates the total height needed at the top to accommodate:
  /// - Top margin for safe area (~12px)
  /// - Balance/Hearts display (~50px)
  /// - Extra padding for visual spacing (~20px)
  /// 
  /// ✅ FIXED: Removed banner calculations since banners were removed from UI
  double getTopPadding() {
    final balanceHeartsHeight = ResponsiveConfig.responsivePadding(50.0, screenSize);
    final topMargin = ResponsiveConfig.responsivePadding(12.0, screenSize);
    final extraPadding = ResponsiveConfig.responsivePadding(20.0, screenSize);
    
    // Calculate total height: top margin + balance/hearts + extra padding
    // This should be ~82px on a reference device, not 239px!
    return topMargin + balanceHeartsHeight + extraPadding;
  }
  
  /// Get bottom padding (for footer navigator only)
  double getBottomPadding() {
    // Footer navigator: original 1490x391, aspect ratio ~0.262
    // Footer height = screenWidth * 0.262
    final footerHeight = screenSize.width * (391.0 / 1490.0);
    return footerHeight + ResponsiveConfig.responsivePadding(16.0, screenSize);
  }
  
  /// Check if a point is within any exclusion zone
  bool isPointInExclusionZone(Offset point) {
    final exclusionZones = getExclusionZones();
    return exclusionZones.any((zone) => zone.contains(point));
  }
  
  /// Get a specific UI element by ID
  UIElementZone? getElement(String id) {
    try {
      return _uiElements.firstWhere((element) => element.id == id);
    } catch (e) {
      return null;
    }
  }
  
  /// Get all UI elements (for debugging/testing)
  List<UIElementZone> getAllElements() => List.unmodifiable(_uiElements);
}


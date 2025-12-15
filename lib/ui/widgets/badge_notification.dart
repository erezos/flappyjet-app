/// 🎯 Badge Notification Widget
/// 
/// A modern, responsive badge widget for displaying notification counts.
/// Used in tabs, buttons, and other UI elements to show claimable items.
/// 
/// Features:
/// - Red circular badge with white text
/// - Smooth fade-in/fade-out animations
/// - Responsive sizing for all screen sizes
/// - Handles counts > 99 with "99+" display
/// - Follows modern gaming UI standards
library;

import 'package:flutter/material.dart';
import '../utils/responsive_config.dart';

class BadgeNotification extends StatelessWidget {
  /// The count to display. Badge is hidden when count is 0 or negative.
  final int count;
  
  /// Screen size for responsive calculations
  final Size screenSize;
  
  /// Optional custom badge color (default: bright red for gaming)
  final Color? badgeColor;
  
  /// Optional custom text color (default: white)
  final Color? textColor;
  
  /// Optional minimum badge size (default: 18px)
  final double? minSize;
  
  /// Optional maximum badge size (default: 28px)
  final double? maxSize;

  const BadgeNotification({
    super.key,
    required this.count,
    required this.screenSize,
    this.badgeColor,
    this.textColor,
    this.minSize,
    this.maxSize,
  });

  @override
  Widget build(BuildContext context) {
    // Hide badge if count is 0 or negative
    if (count <= 0) {
      return const SizedBox.shrink();
    }

    // Calculate responsive badge size
    final baseSize = minSize ?? 18.0;
    final maxBadgeSize = maxSize ?? 28.0;
    final badgeSize = ResponsiveConfig.responsiveSize(
      baseSize,
      screenSize,
      minScale: 0.9,
      maxScale: 1.3,
    ).clamp(baseSize, maxBadgeSize);

    // Calculate responsive font size
    final baseFontSize = 10.0;
    final maxFontSize = 14.0;
    final fontSize = ResponsiveConfig.responsiveFontSize(
      baseFontSize,
      screenSize,
      context,
      minScale: 0.8,
      maxScale: 1.2,
    ).clamp(baseFontSize, maxFontSize);

    // Display text: count or "99+" for counts > 99
    final displayText = count > 99 ? '99+' : count.toString();

    // Use bright red for gaming UI (similar to iOS/Material Design)
    final redColor = badgeColor ?? const Color(0xFFEF4444); // Bright red
    final whiteColor = textColor ?? Colors.white;

    return AnimatedOpacity(
      opacity: count > 0 ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: badgeSize,
        height: badgeSize,
        decoration: BoxDecoration(
          // Red gradient for depth and modern look
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              redColor,
              redColor.withValues(alpha: 0.8),
            ],
          ),
          shape: BoxShape.circle,
          // Shadow for depth (modern gaming UI standard)
          boxShadow: [
            BoxShadow(
              color: redColor.withValues(alpha: 0.4),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Text(
            displayText,
            style: TextStyle(
              color: whiteColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w900, // Extra bold for visibility
              height: 1.0, // Tight line height for circular badge
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}


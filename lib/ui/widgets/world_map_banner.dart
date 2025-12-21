/// 🎯 WORLD MAP BANNER WIDGET
/// 
/// Reusable banner widget for the world map homepage.
/// Features press animations, haptic feedback, and responsive design.
/// 
/// ✅ Flame Best Practices: Efficient animations, clear separation of concerns
/// ✅ Mobile Gaming Standards: Haptic feedback, visual press feedback
/// ✅ Responsive Design: Scales properly on all screen sizes
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/responsive_config.dart';

/// World Map Banner Widget
/// 
/// A clickable banner that can be placed on the world map.
/// Supports custom images, press animations, and navigation callbacks.
class WorldMapBanner extends StatefulWidget {
  /// Image asset path for the banner
  final String imageAsset;
  
  /// Callback when banner is tapped
  final VoidCallback onTap;
  
  /// Banner size (width and height will be equal for square banners)
  final double size;
  
  /// Whether to use responsive scaling
  final bool useResponsiveScaling;
  
  /// Optional badge widget to display on the banner
  final Widget? badge;
  
  const WorldMapBanner({
    super.key,
    required this.imageAsset,
    required this.onTap,
    this.size = 60.0,
    this.useResponsiveScaling = true,
    this.badge,
  });

  @override
  State<WorldMapBanner> createState() => _WorldMapBannerState();
}

class _WorldMapBannerState extends State<WorldMapBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // ✅ Press animation controller
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    
    // ✅ Scale animation for press feedback
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9, // Slight scale down on press
    ).animate(CurvedAnimation(
      parent: _pressController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  /// Get responsive size for the banner
  double _getResponsiveSize(BuildContext context) {
    if (!widget.useResponsiveScaling) {
      return widget.size;
    }
    
    final screenSize = MediaQuery.of(context).size;
    return ResponsiveConfig.responsiveSize(
      widget.size,
      screenSize,
      minScale: 0.85,
      maxScale: 1.3,
    );
  }

  void _handleTapDown(TapDownDetails details) {
    _pressController.forward();
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails details) {
    _pressController.reverse();
  }

  void _handleTapCancel() {
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final bannerSize = _getResponsiveSize(context);
    
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: bannerSize,
              height: bannerSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Banner image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      widget.imageAsset,
                      width: bannerSize,
                      height: bannerSize,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback to colored container if image fails
                        return Container(
                          color: Colors.blue.shade300,
                          child: Icon(
                            Icons.image_not_supported,
                            size: bannerSize * 0.4,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // Badge overlay (if provided)
                  if (widget.badge != null)
                    Positioned(
                      top: -8,
                      right: -8,
                      child: widget.badge!,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}


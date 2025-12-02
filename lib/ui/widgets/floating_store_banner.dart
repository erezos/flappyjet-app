/// 🛒 Floating Store Banner - World Map overlay for store access
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Floating banner widget for the World Map
/// Opens the store when tapped - positioned below the missions banner
class FloatingStoreBanner extends StatefulWidget {
  final VoidCallback onTap;
  final double size;
  final bool useResponsiveScaling;
  final bool showNewBadge;
  
  const FloatingStoreBanner({
    super.key,
    required this.onTap,
    this.size = 85,
    this.useResponsiveScaling = true,
    this.showNewBadge = false,
  });

  @override
  State<FloatingStoreBanner> createState() => _FloatingStoreBannerState();
}

class _FloatingStoreBannerState extends State<FloatingStoreBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  // ignore: unused_field - kept for future shimmer animation
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    
    // Subtle shimmer animation for store appeal (disabled for now - static banner)
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _shimmerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
    
    // Animation disabled for cleaner look - uncomment to enable shimmer
    // _startDelayedAnimation();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  double _getResponsiveSize(BuildContext context) {
    if (!widget.useResponsiveScaling) return widget.size;
    
    final screenWidth = MediaQuery.of(context).size.width;
    double scaleFactor = screenWidth < 360 ? 0.85 : (screenWidth > 400 ? 1.15 : 1.0);
    return widget.size * scaleFactor;
  }

  @override
  Widget build(BuildContext context) {
    final bannerSize = _getResponsiveSize(context);
    
    return RepaintBoundary(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        child: _buildBannerWithBadge(bannerSize),
      ),
    );
  }
  
  /// Store banner with optional "NEW" badge
  /// 
  /// Banner image is 199x76 pixels (2.618:1 aspect ratio - golden ratio!)
  Widget _buildBannerWithBadge(double bannerSize) {
    // Store banner image is 199x76 = 2.618 aspect ratio
    const double imageAspectRatio = 199.0 / 76.0;
    
    // Calculate dimensions to match missions banner width
    final bannerHeight = bannerSize * 0.7;
    final bannerWidth = bannerHeight * imageAspectRatio;
    
    // Badge sizing
    final badgeSize = (bannerHeight * 0.35).clamp(18.0, 24.0);
    final rightOffset = badgeSize * 0.2;
    final topOffset = -badgeSize * 0.3;
    
    return SizedBox(
      width: bannerWidth,
      height: bannerHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Banner with shimmer effect
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _shimmerAnimation,
              builder: (context, child) {
                return _buildBannerRectangle(bannerWidth, bannerHeight);
              },
            ),
          ),
          
          // Optional "NEW" badge at top-right corner
          if (widget.showNewBadge)
            Positioned(
              right: rightOffset,
              top: topOffset,
              child: _NewBadge(size: badgeSize),
            ),
        ],
      ),
    );
  }
  
  /// Build store banner with correct rectangular aspect ratio (199x76)
  Widget _buildBannerRectangle(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          'assets/images/ui/store/banner_store.png',
          width: width,
          height: height,
          fit: BoxFit.fill,
          errorBuilder: (context, error, stackTrace) => _buildFallbackBannerRect(width, height),
        ),
      ),
    );
  }
  
  /// Fallback for rectangular banner when image fails to load
  Widget _buildFallbackBannerRect(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF6B35), Color(0xFFE53935)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD700), width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store, color: const Color(0xFFFFD700), size: height * 0.5),
          const SizedBox(width: 8),
          Text(
            'STORE',
            style: TextStyle(
              color: Colors.white,
              fontSize: height * 0.3,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// "NEW" badge for store banner
class _NewBadge extends StatelessWidget {
  final double size;
  
  const _NewBadge({required this.size});

  @override
  Widget build(BuildContext context) {
    final fontSize = (size * 0.5).clamp(8.0, 12.0);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
        ),
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.5),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Text(
        'NEW',
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          height: 1.0,
        ),
      ),
    );
  }
}


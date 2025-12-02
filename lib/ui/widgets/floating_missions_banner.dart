/// 🎯 Floating Missions Banner - World Map overlay for mission engagement
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../game/systems/missions_manager.dart';
import '../../game/systems/achievements_manager.dart';

/// Floating banner widget for the World Map
/// Shows notification badge when missions/achievements are ready to claim
class FloatingMissionsBanner extends StatefulWidget {
  final VoidCallback onTap;
  final double size;
  final bool useResponsiveScaling;
  
  const FloatingMissionsBanner({
    super.key,
    required this.onTap,
    this.size = 85,
    this.useResponsiveScaling = true,
  });

  @override
  State<FloatingMissionsBanner> createState() => _FloatingMissionsBannerState();
}

class _FloatingMissionsBannerState extends State<FloatingMissionsBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  final MissionsManager _missionsManager = MissionsManager();
  final AchievementsManager _achievementsManager = AchievementsManager();

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _checkAndStartPulse();
    _missionsManager.addListener(_checkAndStartPulse);
    _achievementsManager.addListener(_checkAndStartPulse);
  }

  @override
  void dispose() {
    _missionsManager.removeListener(_checkAndStartPulse);
    _achievementsManager.removeListener(_checkAndStartPulse);
    _pulseController.dispose();
    super.dispose();
  }
  
  void _checkAndStartPulse() {
    final hasClaimable = _getTotalClaimableCount() > 0;
    if (hasClaimable && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!hasClaimable && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }
  
  int _getTotalClaimableCount() {
    return _missionsManager.claimableMissionsCount + 
           _achievementsManager.claimableAchievementsCount;
  }

  double _getResponsiveSize(BuildContext context) {
    if (!widget.useResponsiveScaling) return widget.size;
    
    final screenWidth = MediaQuery.of(context).size.width;
    double scaleFactor = screenWidth < 360 ? 0.85 : (screenWidth > 400 ? 1.15 : 1.0);
    return widget.size * scaleFactor;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_missionsManager, _achievementsManager]),
      builder: (context, _) {
        final claimableCount = _getTotalClaimableCount();
        final bannerSize = _getResponsiveSize(context);
        
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onTap();
          },
          // Animation disabled for testing - use static banner
          child: _buildBannerWithBadge(bannerSize, claimableCount),
        );
      },
    );
  }
  
  /// Classic mobile game notification badge pattern:
  /// Badge sits at top-right corner OVERLAPPING the banner
  /// 
  /// IMPORTANT: The banner image is 222x80 pixels (2.77:1 aspect ratio)
  /// We must use the correct aspect ratio, not a square!
  Widget _buildBannerWithBadge(double bannerSize, int claimableCount) {
    // Banner image is 222x80 = 2.775 aspect ratio (wide rectangle)
    const double imageAspectRatio = 222.0 / 80.0; // ≈ 2.775
    
    // Calculate dimensions based on the SIZE parameter as the HEIGHT
    final bannerHeight = bannerSize * 0.7; // Use 70% of size as height
    final bannerWidth = bannerHeight * imageAspectRatio;
    
    // Badge is ~30% of banner HEIGHT for good visibility on the short edge
    final badgeSize = (bannerHeight * 0.35).clamp(20.0, 28.0);
    // Offset for right edge (inside banner)
    final rightOffset = badgeSize * 0.2;
    // Negative top offset to position badge higher (overlapping top edge)
    final topOffset = -badgeSize * 0.3;
    
    return SizedBox(
      width: bannerWidth,
      height: bannerHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Banner fills the entire Stack (now correctly sized as rectangle)
          Positioned.fill(
            child: _buildBannerRectangle(bannerWidth, bannerHeight),
          ),
          
          // Badge at top-right corner - positioned higher with negative top
          if (claimableCount > 0)
            Positioned(
              right: rightOffset,
              top: topOffset,
              child: _NotificationBadge(count: claimableCount, size: badgeSize),
            ),
        ],
      ),
    );
  }
  
  /// Build banner with CORRECT rectangular aspect ratio (222x80)
  Widget _buildBannerRectangle(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          'assets/images/ui/missions/banner_missions.png',
          width: width,
          height: height,
          fit: BoxFit.fill, // Fill exactly - image matches container aspect ratio
          errorBuilder: (context, error, stackTrace) => _buildFallbackBannerRect(width, height),
        ),
      ),
    );
  }
  
  /// Fallback for rectangular banner
  Widget _buildFallbackBannerRect(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD700), width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment, color: const Color(0xFFFFD700), size: height * 0.5),
          const SizedBox(width: 8),
          Text(
            'MISSIONS',
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

/// Notification badge showing claimable count
class _NotificationBadge extends StatelessWidget {
  final int count;
  final double size;
  
  const _NotificationBadge({required this.count, required this.size});

  @override
  Widget build(BuildContext context) {
    final isLargeNumber = count >= 10;
    final badgeWidth = isLargeNumber ? size * 1.3 : size;
    final fontSize = (size * 0.6).clamp(10.0, 14.0);
    
    return Container(
      constraints: BoxConstraints(minWidth: badgeWidth, minHeight: size),
      padding: EdgeInsets.symmetric(horizontal: isLargeNumber ? 5 : 3, vertical: 1),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFF4444), Color(0xFFCC0000)],
        ),
        shape: isLargeNumber ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: isLargeNumber ? BorderRadius.circular(size / 2) : null,
        border: Border.all(color: Colors.white, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF0000).withValues(alpha: 0.5),
            blurRadius: 6,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          count > 99 ? '99+' : '$count',
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

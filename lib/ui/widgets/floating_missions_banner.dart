/// 🎯 Floating Missions Banner - World Map overlay for mission engagement
/// 
/// A compact banner that floats on the World Map screen, showing a notification
/// badge when missions/achievements are ready to claim. Tapping opens the
/// missions popup.
/// 
/// Best Practices:
/// - Uses ListenableBuilder for real-time updates without rebuilding parent
/// - Minimal footprint - doesn't clutter the gameplay area
/// - Pulse animation draws attention when rewards are claimable
/// - Follows Flame/Flutter mobile game UI patterns
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../game/systems/missions_manager.dart';
import '../../game/systems/achievements_manager.dart';

/// Floating banner widget for the World Map
/// Shows notification badge when missions/achievements are ready to claim
/// 
/// Responsive Design:
/// - Scales proportionally on all screen sizes using MediaQuery
/// - Uses BoxFit.cover to ensure image always fills the banner area
/// - Badge position is relative to banner size
/// 
/// Zone Independence:
/// - Widget is placed in Stack overlay outside zone-specific content
/// - Appears on all world map zones consistently
class FloatingMissionsBanner extends StatefulWidget {
  /// Callback when banner is tapped
  final VoidCallback onTap;
  
  /// Base size (will be scaled based on screen size)
  /// Default is 85 for good visibility on standard phones
  final double size;
  
  /// Whether to use responsive scaling based on screen width
  /// Set to false for fixed-size behavior (useful in tests)
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
  
  // Managers (singletons)
  final MissionsManager _missionsManager = MissionsManager();
  final AchievementsManager _achievementsManager = AchievementsManager();

  @override
  void initState() {
    super.initState();
    
    // Pulse animation for when rewards are claimable
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Start pulsing if there are claimable rewards
    _checkAndStartPulse();
    
    // Listen for changes
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

  /// Calculate responsive size based on screen width
  /// - Small phones (< 360px): 0.85x scale
  /// - Standard phones (360-400px): 1.0x scale  
  /// - Large phones/tablets (> 400px): 1.15x scale
  double _getResponsiveSize(BuildContext context) {
    if (!widget.useResponsiveScaling) {
      return widget.size;
    }
    
    final screenWidth = MediaQuery.of(context).size.width;
    double scaleFactor;
    
    if (screenWidth < 360) {
      scaleFactor = 0.85;
    } else if (screenWidth > 400) {
      scaleFactor = 1.15;
    } else {
      scaleFactor = 1.0;
    }
    
    return widget.size * scaleFactor;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_missionsManager, _achievementsManager]),
      builder: (context, _) {
        final claimableCount = _getTotalClaimableCount();
        final responsiveSize = _getResponsiveSize(context);
        
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onTap();
          },
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              final scale = claimableCount > 0 ? _pulseAnimation.value : 1.0;
              
              return Transform.scale(
                scale: scale,
                child: SizedBox(
                  width: responsiveSize + 20, // Extra space for badge overflow
                  height: responsiveSize + 10,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Banner image with shadow
                      Positioned(
                        left: 10,
                        top: 5,
                        child: Container(
                          width: responsiveSize,
                          height: responsiveSize,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              // Glow effect when claimable
                              if (claimableCount > 0)
                                BoxShadow(
                                  color: const Color(0xFFFFD700).withValues(alpha: 0.6),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              // Standard shadow
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              'assets/images/ui/missions/banner_missions.png',
                              width: responsiveSize,
                              height: responsiveSize,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback if image not found
                                return _buildFallbackBanner(responsiveSize);
                              },
                            ),
                          ),
                        ),
                      ),
                      
                      // Notification badge (top-right corner)
                      if (claimableCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: _NotificationBadge(count: claimableCount),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
  
  /// Fallback banner if asset is missing
  Widget _buildFallbackBanner(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3A8A),
            Color(0xFF0F172A),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD700),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment,
            color: const Color(0xFFFFD700),
            size: size * 0.35, // Scale icon with banner
          ),
          const SizedBox(height: 2),
          Text(
            'MISSIONS',
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.1, // Scale text with banner
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
  
  const _NotificationBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    // Adjust size based on number of digits
    final isLargeNumber = count >= 10;
    final badgeSize = isLargeNumber ? 28.0 : 24.0;
    
    return Container(
      constraints: BoxConstraints(
        minWidth: badgeSize,
        minHeight: badgeSize,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isLargeNumber ? 6 : 4,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFF4444), // Bright red
            Color(0xFFCC0000), // Dark red
          ],
        ),
        shape: isLargeNumber ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: isLargeNumber ? BorderRadius.circular(12) : null,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF0000).withValues(alpha: 0.5),
            blurRadius: 6,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          count > 99 ? '99+' : '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}


/// 🎯 MISSIONS & ACHIEVEMENTS CLAIM BANNER - Modern floating banner for homepage
/// Shows a floating banner when missions or achievements have rewards to claim
library;

import 'package:flutter/material.dart';
import '../../core/debug_logger.dart';
import '../utils/responsive_config.dart';
import '../../game/systems/missions_manager.dart';
import '../../game/systems/achievements_manager.dart';
import '../screens/daily_missions_screen.dart';
import '../widgets/daily_streak/daily_streak_integration.dart';
import '../layouts/homepage_layout.dart';
import '../widgets/homepage_footer_navigator.dart';

/// Floating banner widget that appears when missions or achievements have claimable rewards
/// 
/// Features:
/// - Responsive sizing for all devices
/// - Smooth animations
/// - Tappable to navigate to missions/achievements screen
/// - Auto-hides when no rewards available
/// - Positions below daily streak banner if both are visible
/// - Follows Flame game engine and mobile gaming best practices
class MissionsAchievementsClaimBanner extends StatefulWidget {
  const MissionsAchievementsClaimBanner({super.key});

  @override
  State<MissionsAchievementsClaimBanner> createState() => _MissionsAchievementsClaimBannerState();
}

class _MissionsAchievementsClaimBannerState extends State<MissionsAchievementsClaimBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  final MissionsManager _missionsManager = MissionsManager();
  final AchievementsManager _achievementsManager = AchievementsManager();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Check if there are any claimable rewards
  bool _hasClaimableRewards() {
    final hasMissions = _missionsManager.hasClaimableRewards;
    final hasAchievements = _achievementsManager.hasClaimableAchievements;
    final missionsCount = _missionsManager.claimableMissionsCount;
    final achievementsCount = _achievementsManager.claimableAchievementsCount;
    
    // Debug logging to help diagnose state issues
    if (hasMissions || hasAchievements) {
      safePrint('🎯 Claim Banner: hasClaimableRewards = $hasMissions (missions: $missionsCount) || $hasAchievements (achievements: $achievementsCount)');
    }
    
    return hasMissions || hasAchievements;
  }

  /// Navigate to missions/achievements screen
  /// Uses the same navigation pattern as footer navigator to show footer
  Future<void> _navigateToMissionsScreen(BuildContext context) async {
    try {
      // Navigate to DailyMissionsScreen wrapped in HomepageLayout (same as footer navigator)
      // If achievements are claimable, open achievements tab; otherwise missions tab
      final hasClaimableAchievements = _achievementsManager.hasClaimableAchievements;
      final missionsCount = _missionsManager.claimableMissionsCount;
      final achievementsCount = _achievementsManager.claimableAchievementsCount;
      final initialTabIndex = hasClaimableAchievements ? 1 : 0; // 0 = Missions, 1 = Achievements
      
      safePrint('🎯 Claim Banner: Navigating to missions screen - missions: $missionsCount, achievements: $achievementsCount, tab: $initialTabIndex');
      
      if (!context.mounted) return;
      
      // ✅ FIX: Use same navigation pattern as footer navigator (HomepageLayout with footer)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => HomepageLayout(
            activeSection: FooterNavigatorSection.missions,
            child: DailyMissionsScreen(
              missionsManager: _missionsManager,
              achievementsManager: _achievementsManager,
              initialTabIndex: initialTabIndex,
            ),
          ),
        ),
      );
    } catch (e) {
      safePrint('Error navigating to missions screen: $e');
    }
  }

  /// Calculate top position based on whether daily streak banner is visible
  double _calculateTopPosition(BuildContext context, Size screenSize) {
    final isTablet = ResponsiveConfig.isTablet(screenSize);
    final isLargeTablet = ResponsiveConfig.isLargeTablet(screenSize);
    
    // Calculate CoinsGemsDisplay height (matches the widget's internal sizing)
    final iconSize = isLargeTablet ? 28.0 : isTablet ? 26.0 : 22.0;
    final verticalPadding = isLargeTablet ? 12.0 : isTablet ? 10.0 : 8.0;
    final balanceHeight = iconSize + (verticalPadding * 2);
    
    // Base top position: SafeArea top + top padding + balance height
    final topPadding = ResponsiveConfig.responsivePadding(12.0, screenSize);
    final spacing = ResponsiveConfig.responsivePadding(8.0, screenSize);
    double topPosition = MediaQuery.of(context).padding.top + 
                        topPadding + 
                        balanceHeight;
    
    // Check if daily streak banner is visible
    final hasDailyStreakNotification = DailyStreakIntegration.hasNotification;
    
    if (hasDailyStreakNotification) {
      // Position below daily streak banner
      // Daily streak banner dimensions (from DailyStreakFloatingBanner) - same size as claim banner
      final baseWidth = isLargeTablet ? 201.6 : isTablet ? 172.8 : 144.0;
      final bannerWidth = ResponsiveConfig.responsiveSize(baseWidth, screenSize);
      final dailyStreakBannerHeight = bannerWidth / 2.035; // 346:170 aspect ratio
      
      topPosition += spacing + dailyStreakBannerHeight + spacing;
    } else {
      // Position directly below balance with spacing
      topPosition += spacing;
    }
    
    return topPosition;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = ResponsiveConfig.isTablet(screenSize);
    final isLargeTablet = ResponsiveConfig.isLargeTablet(screenSize);
    
    return ListenableBuilder(
      listenable: Listenable.merge([_missionsManager, _achievementsManager]),
      builder: (context, child) {
        final hasClaimable = _hasClaimableRewards();
        
        // Hide if no claimable rewards
        if (!hasClaimable) {
          return const SizedBox.shrink();
        }
        
        // ✅ Image aspect ratio: missions_claim_banner.png is 346x166 = ~2.084:1
        // Using responsive banner sizing - 20% bigger than double the daily streak banner size
        final baseWidth = isLargeTablet ? 201.6 : isTablet ? 172.8 : 144.0; // 20% bigger than previous size
        final bannerWidth = ResponsiveConfig.responsiveSize(baseWidth, screenSize);
        final bannerHeight = bannerWidth / 2.084; // Maintain 346:166 aspect ratio
        
        // Calculate top position (below daily streak banner if visible, otherwise below balance)
        final topPosition = _calculateTopPosition(context, screenSize);
        
        return Positioned(
          top: topPosition,
          left: 0.0, // Start from left edge
          child: Transform.translate(
            offset: const Offset(-8.0, 0.0), // Move 8 pixels further left
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: GestureDetector(
                  onTap: () => _navigateToMissionsScreen(context),
                  child: Container(
                  width: bannerWidth,
                  height: bannerHeight,
                  decoration: BoxDecoration(
                    image: const DecorationImage(
                      image: AssetImage('assets/images/homepage/missions_claim_banner.png'),
                      fit: BoxFit.contain, // ✅ Use contain to preserve aspect ratio and show full image
                    ),
                    borderRadius: BorderRadius.circular(
                      ResponsiveConfig.responsiveSize(12.0, screenSize),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(
                        ResponsiveConfig.responsiveSize(12.0, screenSize),
                      ),
                      onTap: () => _navigateToMissionsScreen(context),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            ResponsiveConfig.responsiveSize(12.0, screenSize),
                          ),
                        ),
                      ),
                    ),
                  ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}


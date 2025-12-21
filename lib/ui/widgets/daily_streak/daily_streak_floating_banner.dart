/// 📅 DAILY STREAK FLOATING BANNER - Modern floating banner for homepage
/// Shows a floating banner under the user balance when daily streak reward is available
library;

import 'package:flutter/material.dart';
import '../../../core/debug_logger.dart';
import '../../utils/responsive_config.dart';
import 'daily_streak_integration.dart';
import 'daily_streak_popup_stable.dart';

/// Floating banner widget that appears under the user balance
/// when a daily streak reward is available
/// 
/// Features:
/// - Responsive sizing for all devices
/// - Smooth animations
/// - Tappable to open daily streak popup
/// - Auto-hides when no reward available
/// - Follows Flame game engine and mobile gaming best practices
class DailyStreakFloatingBanner extends StatefulWidget {
  const DailyStreakFloatingBanner({super.key});

  @override
  State<DailyStreakFloatingBanner> createState() => _DailyStreakFloatingBannerState();
}

class _DailyStreakFloatingBannerState extends State<DailyStreakFloatingBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

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

  /// Show daily streak popup
  Future<void> _showDailyStreakPopup(BuildContext context) async {
    try {
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) => DailyStreakPopupStable(
          streakManager: DailyStreakIntegration.streakManager,
          onClaim: () async {
            if (dialogContext.mounted && Navigator.canPop(dialogContext)) {
              Navigator.of(dialogContext).pop();
            }
          },
          onClose: () {
            if (dialogContext.mounted && Navigator.canPop(dialogContext)) {
              Navigator.of(dialogContext).pop();
            }
          },
        ),
      );
    } catch (e) {
      safePrint('Error showing daily streak popup: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = ResponsiveConfig.isTablet(screenSize);
    final isLargeTablet = ResponsiveConfig.isLargeTablet(screenSize);
    
    return ListenableBuilder(
      listenable: DailyStreakIntegration.streakManager,
      builder: (context, child) {
        final hasNotification = DailyStreakIntegration.hasNotification;
        
        // Hide if no notification
        if (!hasNotification) {
          return const SizedBox.shrink();
        }
        
        // Calculate CoinsGemsDisplay height (matches the widget's internal sizing)
        final iconSize = isLargeTablet ? 28.0 : isTablet ? 26.0 : 22.0;
        final verticalPadding = isLargeTablet ? 12.0 : isTablet ? 10.0 : 8.0;
        final balanceHeight = iconSize + (verticalPadding * 2);
        
        // ✅ Image aspect ratio: 346x170 = ~2.035:1
        // Responsive banner sizing - same size as claim banner for consistency
        final baseWidth = isLargeTablet ? 201.6 : isTablet ? 172.8 : 144.0; // Same as claim banner
        final bannerWidth = ResponsiveConfig.responsiveSize(baseWidth, screenSize);
        final bannerHeight = bannerWidth / 2.035; // Maintain 346:170 aspect ratio
        
        // Calculate top position: SafeArea top + top padding + balance height + spacing
        final topPadding = ResponsiveConfig.responsivePadding(12.0, screenSize);
        final spacing = ResponsiveConfig.responsivePadding(8.0, screenSize);
        final topPosition = MediaQuery.of(context).padding.top + 
                           topPadding + 
                           balanceHeight + 
                           spacing;
        
        return Positioned(
          top: topPosition,
          left: 0.0, // Aligned to left edge, same as claim banner
          child: Transform.translate(
            offset: const Offset(-8.0, 0.0), // Move 8 pixels further left, same as claim banner
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: GestureDetector(
                onTap: () => _showDailyStreakPopup(context),
                child: Container(
                  width: bannerWidth,
                  height: bannerHeight,
                  decoration: BoxDecoration(
                    image: const DecorationImage(
                      image: AssetImage('assets/images/homepage/daily_streak_bonus_calendar.png'),
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
                      onTap: () => _showDailyStreakPopup(context),
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


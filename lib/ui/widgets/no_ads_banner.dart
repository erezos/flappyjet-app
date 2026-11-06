/// 🚫 NO ADS BANNER
/// 
/// Floating banner in top-right corner that shows no-ads offer.
/// Appears after completing levels 5, 8, 12, 16.
/// 
/// ✅ Flame Best Practices & Mobile Gaming Standards:
/// - Responsive design with proper scaling
/// - Smooth animations and haptic feedback
/// - Non-intrusive placement (top-right corner)
/// - Proper state management with ChangeNotifier
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../game/systems/no_ads_banner_manager.dart';
import '../../game/systems/no_ads_manager.dart';
import '../../core/debug_logger.dart';
import '../utils/responsive_config.dart';
import 'no_ads_offer_popup.dart';

/// No-ads banner widget
class NoAdsBanner extends StatefulWidget {
  const NoAdsBanner({super.key});

  @override
  State<NoAdsBanner> createState() => NoAdsBannerState();
}

class NoAdsBannerState extends State<NoAdsBanner>
    with SingleTickerProviderStateMixin {
  final NoAdsBannerManager _bannerManager = NoAdsBannerManager();
  final NoAdsManager _noAdsManager = NoAdsManager();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  bool _isVisible = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    // Listen to banner manager changes
    _bannerManager.addListener(_onBannerStateChanged);
    _noAdsManager.addListener(_onNoAdsChanged);

    // Check initial visibility
    _checkVisibility();
  }

  @override
  void dispose() {
    _bannerManager.removeListener(_onBannerStateChanged);
    _noAdsManager.removeListener(_onNoAdsChanged);
    _animationController.dispose();
    super.dispose();
  }

  void _onBannerStateChanged() {
    _checkVisibility();
  }

  void _onNoAdsChanged() {
    // Hide banner if user has no-ads
    if (_noAdsManager.hasNoAds) {
      _hideBanner();
    } else {
      _checkVisibility();
    }
  }

  void _checkVisibility() {
    // Don't show if user already has no-ads
    if (_noAdsManager.hasNoAds) {
      _hideBanner();
      return;
    }

    // Don't show if banner is dismissed
    if (_bannerManager.isDismissed) {
      _hideBanner();
      return;
    }

    // Check if we should show based on completed levels
    // Show if any trigger level has been marked as shown
    final shouldShow = !_bannerManager.isDismissed &&
        _bannerManager.bannerShownLevels.isNotEmpty;

    if (shouldShow && !_isVisible) {
      safePrint('🚫 No-ads banner: _checkVisibility says should show (levels: ${_bannerManager.bannerShownLevels})');
      _showBanner();
    } else if (!shouldShow && _isVisible) {
      safePrint('🚫 No-ads banner: _checkVisibility says should hide');
      _hideBanner();
    }
  }

  void _showBanner() {
    if (!mounted) {
      safePrint('🚫 No-ads banner: Cannot show - widget not mounted');
      return;
    }
    safePrint('🚫 No-ads banner: Showing banner (was visible: $_isVisible)');
    setState(() {
      _isVisible = true;
    });
    _animationController.forward();
  }

  void _hideBanner() {
    if (!mounted) return;
    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isVisible = false;
        });
      }
    });
  }

  /// Show banner for a specific level (called from WorldMapScreen)
  void showForLevel(int level) {
    safePrint('🚫 No-ads banner: showForLevel called for level $level');
    
    // Don't show if user already has no-ads
    if (_noAdsManager.hasNoAds) {
      safePrint('🚫 No-ads banner: User already has no-ads, skipping');
      return;
    }
    
    // Don't show if banner is dismissed
    if (_bannerManager.isDismissed) {
      safePrint('🚫 No-ads banner: Banner already dismissed, skipping');
      return;
    }
    
    if (_bannerManager.shouldShowBanner(level)) {
      safePrint('🚫 No-ads banner: Should show for level $level, marking as shown');
      _bannerManager.markBannerShown(level).then((_) {
        safePrint('🚫 No-ads banner: Level $level marked as shown, showing banner');
        if (mounted) {
          _showBanner();
        }
      });
    } else {
      safePrint('🚫 No-ads banner: Should not show for level $level (already shown or not a trigger level)');
      // If banner should show but manager says no, check visibility anyway
      _checkVisibility();
    }
  }

  Future<void> _onBannerTapped() async {
    if (!mounted) return;

    HapticFeedback.mediumImpact();

    // Show no-ads offer popup
    final purchased = await showNoAdsOfferPopup(context: context);

    // Dismiss banner after user interacts (purchase or close)
    await _bannerManager.dismissBanner();
    _hideBanner();

    if (purchased == true) {
      safePrint('🚫 No-ads purchased from banner');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) {
      return const SizedBox.shrink();
    }

    final screenSize = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;
    
    // Position banner below hearts display
    // Hearts are at: topPadding + 12.0, estimated height ~60px
    final heartsTop = topPadding + ResponsiveConfig.responsivePadding(12.0, screenSize);
    final heartsHeight = ResponsiveConfig.responsiveSize(60.0, screenSize); // Approximate hearts height
    final bannerTop = heartsTop + heartsHeight + ResponsiveConfig.responsivePadding(8.0, screenSize);

    return Positioned(
      top: bannerTop,
      right: ResponsiveConfig.responsivePadding(16.0, screenSize),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: GestureDetector(
            onTap: _onBannerTapped,
            child: Container(
              width: ResponsiveConfig.responsiveSize(80.0, screenSize),
              height: ResponsiveConfig.responsiveSize(80.0, screenSize),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  ResponsiveConfig.responsivePadding(16.0, screenSize),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  ResponsiveConfig.responsivePadding(16.0, screenSize),
                ),
                child: Image.asset(
                  'assets/images/ui/no_ads_icon.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback if image not found
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFFFFD700),
                            const Color(0xFFFFA500),
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.block,
                        color: Colors.white,
                        size: 40,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


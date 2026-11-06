/// 🚫 NO ADS OFFER POPUP
/// 
/// Beautiful popup showing no-ads purchase options using flappy_jet_popup frame.
/// Displays 3 options: 24 hours, 1 week, lifetime.
/// 
/// ✅ Flame Best Practices & Mobile Gaming Standards:
/// - Uses flappy_jet_popup.png frame for brand consistency
/// - Responsive design with proper safe area calculations
/// - Smooth animations and haptic feedback
/// - Clear pricing and value proposition
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../game/core/economy_config.dart';
import '../../game/systems/monetization_manager.dart';
import '../../game/systems/no_ads_manager.dart';
import '../utils/responsive_config.dart';
import '../../core/debug_logger.dart';
import 'profile/profile_jet_collection_album.dart'; // For FlappyJetPopupFrameSafeArea

/// Show the no-ads offer popup
/// 
/// Returns true if user purchased, false if dismissed
Future<bool?> showNoAdsOfferPopup({
  required BuildContext context,
}) async {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    builder: (context) => const NoAdsOfferPopupWidget(),
  );
}

/// No-ads offer popup widget
class NoAdsOfferPopupWidget extends StatefulWidget {
  const NoAdsOfferPopupWidget({super.key});

  @override
  State<NoAdsOfferPopupWidget> createState() => _NoAdsOfferPopupWidgetState();
}

class _NoAdsOfferPopupWidgetState extends State<NoAdsOfferPopupWidget>
    with SingleTickerProviderStateMixin {
  final MonetizationManager _monetization = MonetizationManager();
  final NoAdsManager _noAdsManager = NoAdsManager();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  bool _isPurchasing = false;

  @override
  void initState() {
    super.initState();

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

    _animationController.forward();
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _purchaseNoAds(NoAdsProduct product) async {
    if (_isPurchasing) return;

    setState(() {
      _isPurchasing = true;
    });

    HapticFeedback.mediumImpact();

    try {
      final result = await _monetization.purchaseIAPProduct(product.id);

      if (result.isSuccess) {
        // Activate No Ads based on product type
        if (product.type == NoAdsProductType.lifetime) {
          await _noAdsManager.activateLifetime();
        } else if (product.type == NoAdsProductType.monthly) {
          await _noAdsManager.activateMonthly();
        } else if (product.type == NoAdsProductType.hours24) {
          await _noAdsManager.activate24Hours();
        } else if (product.type == NoAdsProductType.week) {
          await _noAdsManager.activate1Week();
        }

        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else if (result.isCancelled) {
        // User cancelled - no error message needed
        setState(() {
          _isPurchasing = false;
        });
      } else {
        // Purchase failed
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ?? 'Purchase failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isPurchasing = false;
        });
      }
    } catch (e) {
      safePrint('⚠️ Error purchasing no-ads: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isPurchasing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: ResponsiveConfig.responsivePadding(20.0, screenSize),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Calculate popup size maintaining aspect ratio of flappy_jet_popup.png
              final popupAspectRatio =
                  FlappyJetPopupFrameSafeArea.originalWidth /
                      FlappyJetPopupFrameSafeArea.originalHeight;
              final maxPopupWidth = constraints.maxWidth.clamp(280.0, 400.0);
              final maxPopupHeight = constraints.maxHeight.clamp(500.0, 700.0);

              double popupWidth = maxPopupWidth;
              double popupHeight = popupWidth / popupAspectRatio;

              // If height exceeds max, scale down
              if (popupHeight > maxPopupHeight) {
                popupHeight = maxPopupHeight;
                popupWidth = popupHeight * popupAspectRatio;
              }

              final popupSize = Size(popupWidth, popupHeight);
              final safeAreaPadding =
                  FlappyJetPopupFrameSafeArea.calculateSafeAreaPadding(
                      popupSize);

              return Container(
                width: popupWidth,
                height: popupHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    ResponsiveConfig.responsivePadding(24.0, screenSize),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                      spreadRadius: 5,
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    // Popup background image
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/ui/flappy_jet_popup.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFF1A237E),
                                  const Color(0xFF283593),
                                  const Color(0xFF3949AB),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          );
                        },
                      ),
                    ),

                    // Semi-transparent overlay for better text readability
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15), // Light overlay for contrast
                          borderRadius: BorderRadius.circular(
                            ResponsiveConfig.responsivePadding(24.0, screenSize),
                          ),
                        ),
                      ),
                    ),

                    // Close button (X) - positioned in top-right corner
                    Positioned(
                      top: ResponsiveConfig.responsivePadding(16.0, screenSize),
                      right: ResponsiveConfig.responsivePadding(16.0, screenSize),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.of(context).pop(false);
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: ResponsiveConfig.responsiveSize(36.0, screenSize),
                            height: ResponsiveConfig.responsiveSize(36.0, screenSize),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.8),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: ResponsiveConfig.responsiveSize(20.0, screenSize),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Content overlay
                    Positioned.fill(
                      child: Padding(
                        padding: safeAreaPadding,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // No-ads icon
                            Image.asset(
                              'assets/images/ui/no_ads_icon.png',
                              width: ResponsiveConfig.responsiveSize(60.0, screenSize),
                              height: ResponsiveConfig.responsiveSize(60.0, screenSize),
                              errorBuilder: (context, error, stackTrace) {
                                return const SizedBox.shrink();
                              },
                            ),

                            SizedBox(
                                height: ResponsiveConfig.responsivePadding(
                                    4.0, screenSize)),

                            // Title
                            Text(
                              'NO ADS',
                              style: TextStyle(
                                fontSize: ResponsiveConfig.responsiveFontSize(
                                    24.0, screenSize, context),
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1A237E), // Dark blue for readability
                                shadows: [
                                  Shadow(
                                    offset: const Offset(0, 2),
                                    blurRadius: 4,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                  Shadow(
                                    offset: const Offset(0, -1),
                                    blurRadius: 2,
                                    color: Colors.black.withValues(alpha: 0.3),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),

                            SizedBox(
                                height: ResponsiveConfig.responsivePadding(
                                    2.0, screenSize)),

                            // Subtitle
                            Text(
                              'Enjoy uninterrupted gameplay!',
                              style: TextStyle(
                                fontSize: ResponsiveConfig.responsiveFontSize(
                                    14.0, screenSize, context),
                                color: const Color(0xFF1A237E), // Dark blue for readability
                                fontWeight: FontWeight.w600,
                                shadows: [
                                  Shadow(
                                    offset: const Offset(0, 1),
                                    blurRadius: 2,
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),

                            SizedBox(
                                height: ResponsiveConfig.responsivePadding(
                                    8.0, screenSize)),

                            // No-ads options
                            ...EconomyConfig.noAdsProducts.values
                                .map((product) => Padding(
                                      padding: EdgeInsets.only(
                                        bottom: ResponsiveConfig
                                            .responsivePadding(6.0, screenSize),
                                      ),
                                      child: _buildProductCard(
                                          context, screenSize, product),
                                    ))
                                .toList(),

                            SizedBox(
                                height: ResponsiveConfig.responsivePadding(
                                    4.0, screenSize)),

                            // Close button
                            TextButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                Navigator.of(context).pop(false);
                              },
                              child: Text(
                                'Maybe Later',
                                style: TextStyle(
                                  fontSize: ResponsiveConfig.responsiveFontSize(
                                      12.0, screenSize, context),
                                  color: const Color(0xFF1A237E), // Dark blue for readability
                                  fontWeight: FontWeight.w600,
                                  shadows: [
                                    Shadow(
                                      offset: const Offset(0, 1),
                                      blurRadius: 2,
                                      color: Colors.white.withValues(alpha: 0.6),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(
      BuildContext context, Size screenSize, NoAdsProduct product) {
    final isBestValue = product.isBestValue;

    return GestureDetector(
      onTap: _isPurchasing ? null : () => _purchaseNoAds(product),
      child: Container(
        padding: ResponsiveConfig.responsiveEdgeInsetsSymmetric(
          horizontal: 12.0,
          vertical: 8.0,
          screenSize: screenSize,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isBestValue
                ? [
                    const Color(0xFFFFD700),
                    const Color(0xFFFFA000),
                  ]
                : [
                    const Color(0xFF42A5F5),
                    const Color(0xFF1976D2),
                  ],
          ),
          borderRadius: BorderRadius.circular(
            ResponsiveConfig.responsivePadding(12.0, screenSize),
          ),
          border: isBestValue
              ? Border.all(color: const Color(0xFFFFD700), width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: (isBestValue
                      ? const Color(0xFFFFD700)
                      : const Color(0xFF42A5F5))
                  .withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // No-ads icon
            Image.asset(
              'assets/images/ui/no_ads_icon.png',
              width: ResponsiveConfig.responsiveSize(32.0, screenSize),
              height: ResponsiveConfig.responsiveSize(32.0, screenSize),
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox.shrink();
              },
            ),

            SizedBox(width: ResponsiveConfig.responsivePadding(8.0, screenSize)),

            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.displayName,
                    style: TextStyle(
                      fontSize: ResponsiveConfig.responsiveFontSize(
                          16.0, screenSize, context),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 1),
                          blurRadius: 2,
                          color: Colors.black.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ),
                  if (product.description.isNotEmpty) ...[
                    SizedBox(
                        height: ResponsiveConfig.responsivePadding(
                            2.0, screenSize)),
                    Text(
                      product.description,
                      style: TextStyle(
                        fontSize: ResponsiveConfig.responsiveFontSize(
                            11.0, screenSize, context),
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: const Offset(0, 1),
                            blurRadius: 2,
                            color: Colors.black.withValues(alpha: 0.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(width: ResponsiveConfig.responsivePadding(4.0, screenSize)),

            // Price
            Text(
              '\$${product.usdPrice.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize:
                    ResponsiveConfig.responsiveFontSize(18.0, screenSize, context),
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// 🚫 NO ADS SECTION
/// 
/// Displays No Ads products (Lifetime and Monthly)
/// Beautiful, engaging UI following mobile gaming standards
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../game/core/economy_config.dart';
import '../../../game/systems/no_ads_manager.dart';
import '../../../game/systems/monetization_manager.dart';
import '../../utils/responsive_config.dart';

class NoAdsSection extends StatefulWidget {
  final Function(NoAdsProduct) onPurchaseNoAds;
  final MonetizationManager monetization;

  const NoAdsSection({
    super.key,
    required this.onPurchaseNoAds,
    required this.monetization,
  });

  @override
  State<NoAdsSection> createState() => _NoAdsSectionState();
}

class _NoAdsSectionState extends State<NoAdsSection> {
  final noAdsManager = NoAdsManager();

  @override
  void initState() {
    super.initState();
    noAdsManager.addListener(_onNoAdsChanged);
  }

  @override
  void dispose() {
    noAdsManager.removeListener(_onNoAdsChanged);
    super.dispose();
  }

  void _onNoAdsChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final hasNoAds = noAdsManager.hasNoAds;
    final products = EconomyConfig.noAdsProducts.values.toList();

    // If user already has No Ads, show status instead
    if (hasNoAds) {
      return _buildNoAdsActiveStatus(context, screenSize);
    }

    return Padding(
      padding: ResponsiveConfig.responsiveEdgeInsetsSymmetric(
        horizontal: 16.0,
        vertical: 12.0,
        screenSize: screenSize,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          _buildSectionHeader(context, screenSize),
          SizedBox(height: ResponsiveConfig.responsivePadding(16.0, screenSize)),
          
          // Products Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              final crossAxisSpacing = ResponsiveConfig.responsivePadding(12.0, screenSize);
              final cardWidth = (availableWidth - crossAxisSpacing) / 2;
              
              // Improved aspect ratio calculation - ensures cards fit content on all devices
              // Base card height accounts for: badge (24) + icon (64) + title (24) + description (32) + savings (24) + price (28) + padding (24) = ~220
              final baseCardHeight = ResponsiveConfig.responsiveSize(220.0, screenSize, minScale: 0.85, maxScale: 1.2);
              final aspectRatio = cardWidth / baseCardHeight.clamp(180.0, 280.0);
              
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: aspectRatio,
                  crossAxisSpacing: crossAxisSpacing,
                  mainAxisSpacing: ResponsiveConfig.responsivePadding(12.0, screenSize),
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return _buildNoAdsProductCard(context, screenSize, product);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, Size screenSize) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Much bigger image - engaging and prominent
              Image.asset(
                'assets/images/ui/no_ads_icon.png',
                width: ResponsiveConfig.responsiveSize(64.0, screenSize, minScale: 0.7, maxScale: 1.2).clamp(40.0, 80.0),
                height: ResponsiveConfig.responsiveSize(64.0, screenSize, minScale: 0.7, maxScale: 1.2).clamp(40.0, 80.0),
                errorBuilder: (_, __, ___) => Icon(
                  Icons.block,
                  color: Colors.red,
                  size: ResponsiveConfig.responsiveSize(64.0, screenSize, minScale: 0.7, maxScale: 1.2).clamp(40.0, 80.0),
                ),
              ),
              SizedBox(width: ResponsiveConfig.responsivePadding(12.0, screenSize).clamp(4.0, 16.0)),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Remove Ads',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: ResponsiveConfig.responsiveFontSize(20.0, screenSize, context),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Enjoy uninterrupted gameplay',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: ResponsiveConfig.responsiveFontSize(12.0, screenSize, context),
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoAdsProductCard(
    BuildContext context,
    Size screenSize,
    NoAdsProduct product,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onPurchaseNoAds(product);
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: product.isBestValue
                ? [
                    const Color(0xFFFFD700),
                    const Color(0xFFFFA000),
                  ]
                : [
                    const Color(0xFF42A5F5),
                    const Color(0xFF1976D2),
                  ],
          ),
          borderRadius: BorderRadius.circular(ResponsiveConfig.responsivePadding(20.0, screenSize)),
          border: product.isBestValue
              ? Border.all(color: const Color(0xFFFFD700), width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: (product.isBestValue ? const Color(0xFFFFD700) : const Color(0xFF42A5F5))
                  .withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: constraints.maxHeight,
                  maxWidth: constraints.maxWidth,
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    top: ResponsiveConfig.responsivePadding(6.0, screenSize),
                    left: ResponsiveConfig.responsivePadding(12.0, screenSize),
                    right: ResponsiveConfig.responsivePadding(12.0, screenSize),
                    bottom: ResponsiveConfig.responsivePadding(12.0, screenSize),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Badge
                      SizedBox(
                        height: ResponsiveConfig.responsiveSize(24.0, screenSize, minScale: 0.8, maxScale: 1.2).clamp(20.0, 30.0),
                        child: Center(
                          child: product.isBestValue
                              ? FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Container(
                                    padding: ResponsiveConfig.responsiveEdgeInsetsSymmetric(
                                      horizontal: 8.0,
                                      vertical: 4.0,
                                      screenSize: screenSize,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(ResponsiveConfig.responsivePadding(8.0, screenSize)),
                                    ),
                                    child: Text(
                                      'BEST VALUE',
                                      style: TextStyle(
                                        fontSize: ResponsiveConfig.responsiveFontSize(10.0, screenSize, context),
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),

                      SizedBox(height: ResponsiveConfig.responsivePadding(4.0, screenSize)),

                      // Icon - Responsive and constrained
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Image.asset(
                          'assets/images/ui/no_ads_icon.png',
                          width: ResponsiveConfig.responsiveSize(64.0, screenSize, minScale: 0.8, maxScale: 1.2).clamp(48.0, 80.0),
                          height: ResponsiveConfig.responsiveSize(64.0, screenSize, minScale: 0.8, maxScale: 1.2).clamp(48.0, 80.0),
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.block,
                            color: Colors.white,
                            size: ResponsiveConfig.responsiveSize(64.0, screenSize, minScale: 0.8, maxScale: 1.2).clamp(48.0, 80.0),
                          ),
                        ),
                      ),

                      SizedBox(height: ResponsiveConfig.responsivePadding(4.0, screenSize)),

                      // Title - Responsive
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          product.type == NoAdsProductType.lifetime
                              ? 'Lifetime'
                              : product.type == NoAdsProductType.week
                                  ? '1 Week'
                                  : product.type == NoAdsProductType.hours24
                                      ? '24 Hours'
                                      : 'Monthly',
                          style: TextStyle(
                            fontSize: ResponsiveConfig.responsiveFontSize(18.0, screenSize, context),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      SizedBox(height: ResponsiveConfig.responsivePadding(2.0, screenSize)),

                      // Description - Responsive with constraints
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            product.description,
                            style: TextStyle(
                              fontSize: ResponsiveConfig.responsiveFontSize(13.0, screenSize, context),
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),

                      SizedBox(height: ResponsiveConfig.responsivePadding(4.0, screenSize)),

                      // Savings text
                      if (product.savingsText != null)
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Container(
                            padding: ResponsiveConfig.responsiveEdgeInsetsSymmetric(
                              horizontal: 6.0,
                              vertical: 2.0,
                              screenSize: screenSize,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(ResponsiveConfig.responsivePadding(6.0, screenSize)),
                            ),
                            child: Text(
                              product.savingsText!,
                              style: TextStyle(
                                fontSize: ResponsiveConfig.responsiveFontSize(9.0, screenSize, context),
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      else
                        SizedBox(height: ResponsiveConfig.responsivePadding(8.0, screenSize)),

                      // Spacer to push price to bottom
                      const Spacer(),

                      // Price - Always at bottom
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '\$${product.usdPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: ResponsiveConfig.responsiveFontSize(20.0, screenSize, context),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNoAdsActiveStatus(BuildContext context, Size screenSize) {
    return Padding(
      padding: ResponsiveConfig.responsiveEdgeInsetsSymmetric(
        horizontal: 16.0,
        vertical: 12.0,
        screenSize: screenSize,
      ),
      child: Container(
        padding: ResponsiveConfig.responsiveEdgeInsets(20.0, screenSize),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
          ),
          borderRadius: BorderRadius.circular(ResponsiveConfig.responsivePadding(16.0, screenSize)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.white,
              size: ResponsiveConfig.responsiveSize(32.0, screenSize),
            ),
            SizedBox(width: ResponsiveConfig.responsivePadding(12.0, screenSize)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No Ads Active!',
                    style: TextStyle(
                      fontSize: ResponsiveConfig.responsiveFontSize(18.0, screenSize, context),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    noAdsManager.getStatusDescription(),
                    style: TextStyle(
                      fontSize: ResponsiveConfig.responsiveFontSize(14.0, screenSize, context),
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
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


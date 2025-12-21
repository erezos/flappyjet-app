/// 💰 INSUFFICIENT CURRENCY POPUP
/// 
/// Smart popup that shows when user lacks currency for a purchase
/// Shows best-value pack that covers the need + bonus
/// Follows mobile gaming best practices and Flame standards
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../game/core/economy_config.dart';
import '../../../game/core/special_offer_config.dart';
import '../../utils/responsive_config.dart';
import '../buttons/modern_game_button.dart';
import '../buttons/button_styles.dart';
import '../gem_3d_icon.dart';
import '../../../core/debug_logger.dart';

/// 🖼️ SPECIAL POPUP FRAME SAFE AREA
/// 
/// The special_popup.png image is 887x1336 pixels, but has a decorative frame
/// that takes up space. The safe content area is:
/// - Left: 50px
/// - Top: 270px  
/// - Right: 50px
/// - Bottom: 60px
/// 
/// This helper calculates responsive padding to keep content within the safe area.
class SpecialPopupFrameSafeArea {
  // Original image dimensions
  static const double originalWidth = 887.0;
  static const double originalHeight = 1336.0;
  
  // Frame padding in original image pixels
  static const double framePaddingLeft = 50.0;
  static const double framePaddingTop = 270.0;
  static const double framePaddingRight = 50.0;
  static const double framePaddingBottom = 60.0;
  
  /// Calculate safe area padding for a given popup size
  /// Returns EdgeInsets with padding that scales proportionally
  static EdgeInsets calculateSafeAreaPadding(Size popupSize) {
    // Calculate scale factor based on width (maintain aspect ratio)
    final widthScale = popupSize.width / originalWidth;
    final heightScale = popupSize.height / originalHeight;
    
    // Use the larger scale to ensure content fits
    final scale = widthScale > heightScale ? widthScale : heightScale;
    
    return EdgeInsets.only(
      left: framePaddingLeft * scale,
      top: framePaddingTop * scale,
      right: framePaddingRight * scale,
      bottom: framePaddingBottom * scale,
    );
  }
  
  /// Calculate safe content area size (popup size minus frame padding)
  static Size calculateSafeContentSize(Size popupSize) {
    final padding = calculateSafeAreaPadding(popupSize);
    return Size(
      popupSize.width - padding.left - padding.right,
      popupSize.height - padding.top - padding.bottom,
    );
  }
}

/// Show insufficient currency popup
/// 
/// Returns true if user purchased, false if dismissed
Future<bool?> showInsufficientCurrencyPopup({
  required BuildContext context,
  required OfferCurrencyType neededCurrency,
  required int neededAmount,
  required int currentAmount,
  required VoidCallback onPurchase,
  VoidCallback? onDismiss,
  InsufficientCurrencyConfig? config,
}) async {
  final effectiveConfig = config ?? const InsufficientCurrencyConfig();
  
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    builder: (context) => InsufficientCurrencyPopupWidget(
      neededCurrency: neededCurrency,
      neededAmount: neededAmount,
      currentAmount: currentAmount,
      config: effectiveConfig,
      onPurchase: () {
        Navigator.of(context).pop(true);
        onPurchase();
      },
      onDismiss: () {
        Navigator.of(context).pop(false);
        onDismiss?.call();
      },
    ),
  );
}

/// Insufficient currency popup widget
class InsufficientCurrencyPopupWidget extends StatefulWidget {
  final OfferCurrencyType neededCurrency;
  final int neededAmount;
  final int currentAmount;
  final InsufficientCurrencyConfig config;
  final VoidCallback onPurchase;
  final VoidCallback onDismiss;

  const InsufficientCurrencyPopupWidget({
    super.key,
    required this.neededCurrency,
    required this.neededAmount,
    required this.currentAmount,
    required this.config,
    required this.onPurchase,
    required this.onDismiss,
  });

  @override
  State<InsufficientCurrencyPopupWidget> createState() => _InsufficientCurrencyPopupWidgetState();
}

class _InsufficientCurrencyPopupWidgetState extends State<InsufficientCurrencyPopupWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  
  // Expose recommendation calculation for external use
  _PackRecommendation _calculateRecommendedPack() {
    final shortfall = widget.neededAmount - widget.currentAmount;
    final targetAmount = (shortfall * (1.0 + widget.config.bonusPercentage)).ceil();

    switch (widget.neededCurrency) {
      case OfferCurrencyType.coins:
        // For coins, recommend currency bundle that covers the need
        return _findBestCurrencyBundle(targetAmount, OfferCurrencyType.coins);
      case OfferCurrencyType.gems:
        // For gems: use gem packs if specified, otherwise currency bundles
        if (!widget.config.useCurrencyBundles && widget.config.recommendedGemPackId != null) {
          // Use specific recommended gem pack (for continue flows)
          final gemPack = EconomyConfig.gemPacks[widget.config.recommendedGemPackId!];
          if (gemPack != null) {
            return _PackRecommendation(
              packId: gemPack.id,
              displayName: gemPack.displayName,
              description: gemPack.description,
              price: gemPack.usdPrice,
              currencyType: OfferCurrencyType.usd,
              amount: gemPack.totalGems,
              isBestValue: gemPack.id == 'gems_pack_mega',
            );
          }
        }
        // Default: use currency bundles for better value (jet purchases)
        return _findBestCurrencyBundle(targetAmount, OfferCurrencyType.gems);
      case OfferCurrencyType.usd:
        return _findBestGemPackForUSD(targetAmount);
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }


  _PackRecommendation _findBestGemPack(int targetAmount) {
    // Sort packs by price (cheapest first) to find the cheapest that covers the need
    final packs = EconomyConfig.gemPacks.values.toList()
      ..sort((a, b) => a.usdPrice.compareTo(b.usdPrice));
    
    // If always show best value, return mega pack
    if (widget.config.alwaysShowBestValue) {
      final megaPack = packs.firstWhere((p) => p.id == 'gems_pack_mega');
      return _PackRecommendation(
        packId: megaPack.id,
        displayName: megaPack.displayName,
        description: megaPack.description,
        price: megaPack.usdPrice,
        currencyType: OfferCurrencyType.usd,
        amount: megaPack.totalGems,
        isBestValue: true,
      );
    }

    // Find cheapest pack that covers the need (sorted by price, so first match is cheapest)
    for (final pack in packs) {
      if (pack.totalGems >= targetAmount) {
        return _PackRecommendation(
          packId: pack.id,
          displayName: pack.displayName,
          description: pack.description,
          price: pack.usdPrice,
          currencyType: OfferCurrencyType.usd,
          amount: pack.totalGems,
          isBestValue: pack.id == 'gems_pack_mega',
        );
      }
    }

    // Fallback to mega pack (if no pack covers the need, show the largest)
    final megaPack = packs.firstWhere((p) => p.id == 'gems_pack_mega');
    return _PackRecommendation(
      packId: megaPack.id,
      displayName: megaPack.displayName,
      description: megaPack.description,
      price: megaPack.usdPrice,
      currencyType: OfferCurrencyType.usd,
      amount: megaPack.totalGems,
      isBestValue: true,
    );
  }

  _PackRecommendation _findBestGemPackForUSD(int targetGems) {
    // For USD purchases, recommend gem packs
    return _findBestGemPack(targetGems);
  }

  /// Find cheapest currency bundle (gems + coins) that covers the need
  /// This is the preferred recommendation for jet purchases
  _PackRecommendation _findBestCurrencyBundle(int targetAmount, OfferCurrencyType neededCurrency) {
    // Get all currency bundles and sort by price (cheapest first)
    final bundles = EconomyConfig.currencyBundles.values.toList()
      ..sort((a, b) => a.usdPrice.compareTo(b.usdPrice));
    
    // Find the cheapest bundle that covers the need
    for (final bundle in bundles) {
      // Check if bundle covers the need based on currency type
      final bundleAmount = neededCurrency == OfferCurrencyType.gems 
          ? bundle.totalGems 
          : bundle.totalCoins;
      
      if (bundleAmount >= targetAmount) {
        return _PackRecommendation(
          packId: bundle.id,
          displayName: bundle.displayName,
          description: bundle.description,
          price: bundle.usdPrice,
          currencyType: OfferCurrencyType.usd,
          amount: bundleAmount,
          isBestValue: bundle.isBestValue,
          // Store bundle reference for purchase
          bundle: bundle,
        );
      }
    }
    
    // Fallback to largest bundle if none covers the need
    final megaBundle = bundles.last;
    final bundleAmount = neededCurrency == OfferCurrencyType.gems 
        ? megaBundle.totalGems 
        : megaBundle.totalCoins;
    
    return _PackRecommendation(
      packId: megaBundle.id,
      displayName: megaBundle.displayName,
      description: megaBundle.description,
      price: megaBundle.usdPrice,
      currencyType: OfferCurrencyType.usd,
      amount: bundleAmount,
      isBestValue: megaBundle.isBestValue,
      bundle: megaBundle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final recommendation = _calculateRecommendedPack();
    final shortfall = widget.neededAmount - widget.currentAmount;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: ResponsiveConfig.responsiveEdgeInsetsSymmetric(
            horizontal: 16.0,
            vertical: 24.0,
            screenSize: screenSize,
          ),
          child: _buildPopupContent(screenSize, recommendation, shortfall),
        ),
      ),
    );
  }

  Widget _buildPopupContent(Size screenSize, _PackRecommendation recommendation, int shortfall) {
    // Calculate popup size (responsive, maintaining aspect ratio of special_popup.png)
    final popupAspectRatio = SpecialPopupFrameSafeArea.originalWidth / SpecialPopupFrameSafeArea.originalHeight;
    final maxPopupWidth = screenSize.width * 0.9;
    final maxPopupHeight = screenSize.height * 0.85;
    
    double popupWidth = maxPopupWidth;
    double popupHeight = popupWidth / popupAspectRatio;
    
    // If height exceeds max, scale down
    if (popupHeight > maxPopupHeight) {
      popupHeight = maxPopupHeight;
      popupWidth = popupHeight * popupAspectRatio;
    }
    
    final popupSize = Size(popupWidth, popupHeight);
    
    // Calculate safe area padding based on frame dimensions
    final safeAreaPadding = SpecialPopupFrameSafeArea.calculateSafeAreaPadding(popupSize);
    
    return Container(
      width: popupWidth,
      height: popupHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ResponsiveConfig.responsivePadding(24.0, screenSize)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Special popup frame background
          Positioned.fill(
            child: Image.asset(
              'assets/images/ui/special_popup.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                safePrint('⚠️ Failed to load special_popup.png: $error');
                // Fallback gradient background if image fails to load
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFE65100),
                        const Color(0xFFFF6F00),
                        const Color(0xFFFFA726),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Content overlay for text readability - stronger overlay for better contrast
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(ResponsiveConfig.responsivePadding(24.0, screenSize)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.5), // Stronger darkening for better text readability
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.4),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // Close button - positioned at top right, outside safe area (on frame edge)
          Positioned(
            top: ResponsiveConfig.responsivePadding(8.0, screenSize),
            right: ResponsiveConfig.responsivePadding(8.0, screenSize),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onDismiss();
              },
              child: Container(
                padding: EdgeInsets.all(ResponsiveConfig.responsivePadding(8.0, screenSize)),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7), // Dark background for visibility
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.8),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: ResponsiveConfig.responsiveSize(20.0, screenSize),
                ),
              ),
            ),
          ),

          // Content - using safe area padding to avoid frame overlap
          Padding(
            padding: safeAreaPadding,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                // Title - high contrast white text with strong shadows
                Text(
                  'Need More ${_getCurrencyName(widget.neededCurrency)}?',
                  style: TextStyle(
                    fontSize: ResponsiveConfig.responsiveFontSize(26.0 * 0.95, screenSize, context),
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                    shadows: [
                      // Multiple shadows for better readability on colorful backgrounds
                      Shadow(
                        offset: const Offset(0, 3),
                        blurRadius: 8,
                        color: Colors.black.withValues(alpha: 0.9),
                      ),
                      Shadow(
                        offset: const Offset(0, 1),
                        blurRadius: 3,
                        color: Colors.black.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: ResponsiveConfig.responsivePadding(20.0, screenSize)),

                // Recommended pack
                _buildRecommendedPack(screenSize, recommendation),

                SizedBox(height: ResponsiveConfig.responsivePadding(20.0, screenSize)),

                // Purchase button
                SizedBox(
                  width: double.infinity,
                  child: ModernGameButton(
                    label: 'GET IT NOW!',
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      widget.onPurchase();
                    },
                    style: ModernButtonStyle.success,
                  ),
                ),

                SizedBox(height: ResponsiveConfig.responsivePadding(8.0, screenSize)),

                // Dismiss button - improved contrast
                TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    widget.onDismiss();
                  },
                  child: Text(
                    'Maybe Later',
                    style: TextStyle(
                      fontSize: ResponsiveConfig.responsiveFontSize(16.0 * 0.95, screenSize, context),
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 1),
                          blurRadius: 3,
                          color: Colors.black.withValues(alpha: 0.8),
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
  }

  Widget _buildRecommendedPack(Size screenSize, _PackRecommendation recommendation) {
    return Container(
      padding: ResponsiveConfig.responsiveEdgeInsets(18.0, screenSize),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7), // Darker background for better contrast
        borderRadius: BorderRadius.circular(ResponsiveConfig.responsivePadding(16.0, screenSize)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5), // Brighter border for visibility
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (recommendation.isBestValue)
            Container(
              padding: ResponsiveConfig.responsiveEdgeInsetsSymmetric(
                horizontal: 8.0,
                vertical: 4.0,
                screenSize: screenSize,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(ResponsiveConfig.responsivePadding(8.0, screenSize)),
              ),
              child: Text(
                '💎 BEST VALUE',
                style: TextStyle(
                  fontSize: ResponsiveConfig.responsiveFontSize(12.0 * 0.95, screenSize, context),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          if (recommendation.isBestValue)
            SizedBox(height: ResponsiveConfig.responsivePadding(8.0, screenSize)),
          Text(
            recommendation.displayName,
            style: TextStyle(
              fontSize: ResponsiveConfig.responsiveFontSize(22.0 * 0.95, screenSize, context),
              fontWeight: FontWeight.w900,
              color: Colors.white,
              shadows: [
                Shadow(
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                  color: Colors.black.withValues(alpha: 0.9),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ResponsiveConfig.responsivePadding(8.0, screenSize)),
          Text(
            recommendation.description,
            style: TextStyle(
              fontSize: ResponsiveConfig.responsiveFontSize(15.0 * 0.95, screenSize, context),
              color: Colors.white,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                  offset: const Offset(0, 1),
                  blurRadius: 3,
                  color: Colors.black.withValues(alpha: 0.8),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ResponsiveConfig.responsivePadding(12.0, screenSize)),
          // Show bundle contents if it's a currency bundle
          if (recommendation.bundle != null) ...[
            // Show gems + coins for currency bundles
            Wrap(
              alignment: WrapAlignment.center,
              spacing: ResponsiveConfig.responsivePadding(8.0, screenSize),
              runSpacing: ResponsiveConfig.responsivePadding(8.0, screenSize),
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/bonuses/gem_bonus.png',
                      width: ResponsiveConfig.responsiveSize(20.0, screenSize).clamp(18.0, 24.0),
                      height: ResponsiveConfig.responsiveSize(20.0, screenSize).clamp(18.0, 24.0),
                      errorBuilder: (_, __, ___) => Gem3DIcon(size: ResponsiveConfig.responsiveSize(20.0, screenSize).clamp(18.0, 24.0)),
                    ),
                    SizedBox(width: ResponsiveConfig.responsivePadding(4.0, screenSize)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${recommendation.bundle!.totalGems}',
                        style: TextStyle(
                          fontSize: ResponsiveConfig.responsiveFontSize(20.0 * 0.95, screenSize, context),
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                              color: Colors.black.withValues(alpha: 0.9),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/bonuses/coin_bonus.png',
                      width: ResponsiveConfig.responsiveSize(20.0, screenSize).clamp(18.0, 24.0),
                      height: ResponsiveConfig.responsiveSize(20.0, screenSize).clamp(18.0, 24.0),
                      errorBuilder: (_, __, ___) => Icon(Icons.monetization_on, size: ResponsiveConfig.responsiveSize(20.0, screenSize).clamp(18.0, 24.0), color: Colors.amber),
                    ),
                    SizedBox(width: ResponsiveConfig.responsivePadding(4.0, screenSize)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${recommendation.bundle!.totalCoins}',
                        style: TextStyle(
                          fontSize: ResponsiveConfig.responsiveFontSize(20.0 * 0.95, screenSize, context),
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                              color: Colors.black.withValues(alpha: 0.9),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: ResponsiveConfig.responsivePadding(8.0, screenSize)),
          ],
          // Show price - prominent gold/yellow with strong dark outline
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _formatPrice(recommendation.price, recommendation.currencyType),
              style: TextStyle(
                fontSize: ResponsiveConfig.responsiveFontSize(28.0 * 0.95, screenSize, context),
                fontWeight: FontWeight.w900,
                color: const Color(0xFFFFD700), // Gold color
                letterSpacing: 1.0,
                shadows: [
                  // Multiple shadows for maximum readability
                  Shadow(
                    offset: const Offset(0, 3),
                    blurRadius: 6,
                    color: Colors.black.withValues(alpha: 1.0), // Strong black outline
                  ),
                  Shadow(
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                    color: Colors.black.withValues(alpha: 0.9),
                  ),
                  Shadow(
                    offset: const Offset(0, -1),
                    blurRadius: 2,
                    color: Colors.black.withValues(alpha: 0.7),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  String _getCurrencyName(OfferCurrencyType type) {
    switch (type) {
      case OfferCurrencyType.coins:
        return 'Coins';
      case OfferCurrencyType.gems:
        return 'Gems';
      case OfferCurrencyType.usd:
        return 'Gems'; // USD purchases typically need gems
    }
  }

  String _formatPrice(double amount, OfferCurrencyType type) {
    switch (type) {
      case OfferCurrencyType.coins:
        return '${amount.toInt()} Coins';
      case OfferCurrencyType.gems:
        return '${amount.toInt()} Gems';
      case OfferCurrencyType.usd:
        return '\$${amount.toStringAsFixed(2)}';
    }
  }
}

/// Pack recommendation data
class _PackRecommendation {
  final String packId;
  final String displayName;
  final String description;
  final double price;
  final OfferCurrencyType currencyType;
  final int amount;
  final bool isBestValue;
  final CurrencyBundle? bundle; // For currency bundle recommendations

  _PackRecommendation({
    required this.packId,
    required this.displayName,
    required this.description,
    required this.price,
    required this.currencyType,
    required this.amount,
    this.isBestValue = false,
    this.bundle,
  });
}


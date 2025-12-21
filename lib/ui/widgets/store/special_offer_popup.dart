/// 🎁 SPECIAL OFFER POPUP
/// 
/// Beautiful, engaging popup for special offers
/// Follows mobile gaming best practices and Flame standards
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../game/core/special_offer_config.dart';
import '../../../game/systems/special_offer_manager.dart';
import '../../utils/responsive_config.dart';
import '../buttons/modern_game_button.dart';
import '../buttons/button_styles.dart';

/// Show a special offer popup
/// 
/// Returns true if user purchased, false if dismissed
Future<bool?> showSpecialOfferPopup({
  required BuildContext context,
  required SpecialOffer offer,
  required VoidCallback onPurchase,
  VoidCallback? onDismiss,
}) async {
  return showDialog<bool>(
    context: context,
    barrierDismissible: offer.isDismissible,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    builder: (context) => SpecialOfferPopupWidget(
      offer: offer,
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

/// Special offer popup widget
class SpecialOfferPopupWidget extends StatefulWidget {
  final SpecialOffer offer;
  final VoidCallback onPurchase;
  final VoidCallback onDismiss;

  const SpecialOfferPopupWidget({
    super.key,
    required this.offer,
    required this.onPurchase,
    required this.onDismiss,
  });

  @override
  State<SpecialOfferPopupWidget> createState() => _SpecialOfferPopupWidgetState();
}

class _SpecialOfferPopupWidgetState extends State<SpecialOfferPopupWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

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

    // Record that offer was shown
    SpecialOfferManager().recordOfferShown(widget.offer.id);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final offer = widget.offer;

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
          child: _buildPopupContent(screenSize, offer),
        ),
      ),
    );
  }

  Widget _buildPopupContent(Size screenSize, SpecialOffer offer) {
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
        borderRadius: BorderRadius.circular(ResponsiveConfig.responsivePadding(24.0, screenSize)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(ResponsiveConfig.responsivePadding(24.0, screenSize)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Content
          Padding(
            padding: ResponsiveConfig.responsiveEdgeInsets(
              20.0,
              screenSize,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Close button (if dismissible)
                if (offer.isDismissible)
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        SpecialOfferManager().recordOfferDismissed(offer.id);
                        widget.onDismiss();
                      },
                    ),
                  ),

                // Title
                Text(
                  offer.title,
                  style: TextStyle(
                    fontSize: ResponsiveConfig.responsiveFontSize(28.0, screenSize, context),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: ResponsiveConfig.responsivePadding(12.0, screenSize)),

                // Description
                Text(
                  offer.description,
                  style: TextStyle(
                    fontSize: ResponsiveConfig.responsiveFontSize(16.0, screenSize, context),
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: ResponsiveConfig.responsivePadding(20.0, screenSize)),

                // Reward display
                _buildRewardDisplay(screenSize, offer),

                SizedBox(height: ResponsiveConfig.responsivePadding(20.0, screenSize)),

                // Price and purchase button
                _buildPriceAndButton(screenSize, offer),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardDisplay(Size screenSize, SpecialOffer offer) {
    final reward = offer.reward;

    return Container(
      padding: ResponsiveConfig.responsiveEdgeInsets(16.0, screenSize),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(ResponsiveConfig.responsivePadding(16.0, screenSize)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            'YOU GET',
            style: TextStyle(
              fontSize: ResponsiveConfig.responsiveFontSize(14.0, screenSize, context),
              color: Colors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: ResponsiveConfig.responsivePadding(8.0, screenSize)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCurrencyIcon(reward.currencyType, screenSize),
              SizedBox(width: ResponsiveConfig.responsivePadding(8.0, screenSize)),
              Text(
                _formatCurrencyAmount(reward.amount, reward.currencyType),
                style: TextStyle(
                  fontSize: ResponsiveConfig.responsiveFontSize(32.0, screenSize, context),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          if (reward.hasBonus) ...[
            SizedBox(height: ResponsiveConfig.responsivePadding(4.0, screenSize)),
            Container(
              padding: ResponsiveConfig.responsiveEdgeInsetsSymmetric(
                horizontal: 12.0,
                vertical: 4.0,
                screenSize: screenSize,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700),
                borderRadius: BorderRadius.circular(ResponsiveConfig.responsivePadding(12.0, screenSize)),
              ),
              child: Text(
                '+${_formatCurrencyAmount(reward.bonusAmount!, reward.currencyType)} BONUS!',
                style: TextStyle(
                  fontSize: ResponsiveConfig.responsiveFontSize(14.0, screenSize, context),
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceAndButton(Size screenSize, SpecialOffer offer) {
    final price = offer.price;

    return Column(
      children: [
        // Price display
        if (price.isDiscounted && price.originalPrice != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatPrice(price.originalPrice!, price.currencyType),
                style: TextStyle(
                  fontSize: ResponsiveConfig.responsiveFontSize(18.0, screenSize, context),
                  color: Colors.white.withValues(alpha: 0.6),
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              SizedBox(width: ResponsiveConfig.responsivePadding(8.0, screenSize)),
              Container(
                padding: ResponsiveConfig.responsiveEdgeInsetsSymmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                  screenSize: screenSize,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(ResponsiveConfig.responsivePadding(8.0, screenSize)),
                ),
                child: Text(
                  '${price.discountPercentage!.toStringAsFixed(0)}% OFF',
                  style: TextStyle(
                    fontSize: ResponsiveConfig.responsiveFontSize(12.0, screenSize, context),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveConfig.responsivePadding(4.0, screenSize)),
        ],
        Text(
          _formatPrice(price.amount, price.currencyType),
          style: TextStyle(
            fontSize: ResponsiveConfig.responsiveFontSize(24.0, screenSize, context),
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFFD700),
          ),
        ),
        SizedBox(height: ResponsiveConfig.responsivePadding(16.0, screenSize)),
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
        if (offer.isDismissible) ...[
          SizedBox(height: ResponsiveConfig.responsivePadding(8.0, screenSize)),
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              SpecialOfferManager().recordOfferDismissed(offer.id);
              widget.onDismiss();
            },
            child: Text(
              'Maybe Later',
              style: TextStyle(
                fontSize: ResponsiveConfig.responsiveFontSize(14.0, screenSize, context),
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCurrencyIcon(OfferCurrencyType type, Size screenSize) {
    final iconSize = ResponsiveConfig.responsiveSize(32.0, screenSize);
    
    switch (type) {
      case OfferCurrencyType.coins:
        return Image.asset(
          'assets/images/icons/coin.png',
          width: iconSize,
          height: iconSize,
          errorBuilder: (_, __, ___) => Icon(Icons.monetization_on, size: iconSize, color: Colors.amber),
        );
      case OfferCurrencyType.gems:
        return Image.asset(
          'assets/images/icons/gem.png',
          width: iconSize,
          height: iconSize,
          errorBuilder: (_, __, ___) => Icon(Icons.diamond, size: iconSize, color: Colors.cyan),
        );
      case OfferCurrencyType.usd:
        return Icon(Icons.attach_money, size: iconSize, color: Colors.green);
    }
  }

  String _formatCurrencyAmount(int amount, OfferCurrencyType type) {
    return amount.toString();
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


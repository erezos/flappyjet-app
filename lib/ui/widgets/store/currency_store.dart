/// 🛒 CURRENCY STORE - Combined Gems and Coins
/// 
/// Shows both gem packs (IAP) and coin packs (gem exchange) in one view
/// Follows mobile gaming best practices
library;

import 'package:flutter/material.dart';
import '../../../game/core/economy_config.dart';
import '../../../game/systems/inventory_manager.dart';
import '../../utils/responsive_config.dart';
import 'gems_store.dart';
import 'coins_store.dart';
import 'currency_bundles_store.dart';

class CurrencyStore extends StatelessWidget {
  final Function(GemPack) onPurchaseGemPack;
  final Function(CoinPack) onPurchaseCoinPack;
  final Function(CurrencyBundle) onPurchaseCurrencyBundle;
  final InventoryManager inventory;
  final EconomyConfig economy;

  const CurrencyStore({
    super.key,
    required this.onPurchaseGemPack,
    required this.onPurchaseCoinPack,
    required this.onPurchaseCurrencyBundle,
    required this.inventory,
    required this.economy,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Padding(
      padding: ResponsiveConfig.responsiveEdgeInsetsSymmetric(
        horizontal: 16.0,
        vertical: 12.0,
        screenSize: screenSize,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gems Section
          _buildSectionHeader(
            context,
            screenSize,
            'Gems',
            '', // No subtitle
            'assets/images/bonuses/gem_bonus.png',
            Colors.cyan,
          ),
          SizedBox(height: ResponsiveConfig.responsivePadding(12.0, screenSize)),
          GemsStore(onPurchaseGemPack: onPurchaseGemPack),
          
          SizedBox(height: ResponsiveConfig.responsivePadding(24.0, screenSize)),
          
          // Divider
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          
          SizedBox(height: ResponsiveConfig.responsivePadding(24.0, screenSize)),
          
          // Coins Section
          _buildSectionHeader(
            context,
            screenSize,
            'Coins',
            '', // No subtitle
            'assets/images/bonuses/coin_bonus.png',
            Colors.amber,
          ),
          SizedBox(height: ResponsiveConfig.responsivePadding(12.0, screenSize)),
          CoinsStore(
            inventory: inventory,
            economy: economy,
            onPurchaseCoinPack: onPurchaseCoinPack,
          ),

          SizedBox(height: ResponsiveConfig.responsivePadding(24.0, screenSize)),
          
          // Divider
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          
          SizedBox(height: ResponsiveConfig.responsivePadding(24.0, screenSize)),

          // Currency Bundles Section
          _buildSectionHeader(
            context,
            screenSize,
            'Special Bundles',
            'Best Value - Save up to 12%',
            'assets/images/icons/gift.png',
            Colors.purple,
          ),
          SizedBox(height: ResponsiveConfig.responsivePadding(12.0, screenSize)),
          CurrencyBundlesStore(
            onPurchaseBundle: onPurchaseCurrencyBundle,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    Size screenSize,
    String title,
    String subtitle,
    String imagePath,
    Color color,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Much bigger image - engaging and prominent
        Image.asset(
          imagePath,
          width: ResponsiveConfig.responsiveSize(64.0, screenSize), // Much bigger - was 24.0
          height: ResponsiveConfig.responsiveSize(64.0, screenSize), // Much bigger - was 24.0
          errorBuilder: (_, __, ___) => Icon(
            title == 'Gems' ? Icons.diamond : Icons.monetization_on,
            color: color,
            size: ResponsiveConfig.responsiveSize(64.0, screenSize),
          ),
        ),
        SizedBox(width: ResponsiveConfig.responsivePadding(16.0, screenSize)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ResponsiveConfig.responsiveFontSize(20.0, screenSize, context),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (subtitle.isNotEmpty)
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: ResponsiveConfig.responsiveFontSize(12.0, screenSize, context),
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
          ],
        ),
      ],
    );
  }
}


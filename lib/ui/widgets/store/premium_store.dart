/// 🛒 PREMIUM STORE - No Ads + Heart Boosters
/// 
/// Combines No Ads products and Heart Booster options
/// Follows mobile gaming best practices
library;

import 'package:flutter/material.dart';
import '../../../game/core/economy_config.dart';
import '../../../game/systems/monetization_manager.dart';
import '../../../game/systems/inventory_manager.dart';
import '../../utils/responsive_config.dart';
import 'no_ads_section.dart';
import 'heart_booster_store.dart';
import 'bundles_section.dart';

class PremiumStore extends StatelessWidget {
  final Function(NoAdsProduct) onPurchaseNoAds;
  final Function(BoosterDuration) onPurchaseBooster;
  final Function(BundleProduct) onPurchaseBundle;
  final MonetizationManager monetization;
  final InventoryManager inventory;

  const PremiumStore({
    super.key,
    required this.onPurchaseNoAds,
    required this.onPurchaseBooster,
    required this.onPurchaseBundle,
    required this.monetization,
    required this.inventory,
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
          // No Ads Section
          NoAdsSection(
            onPurchaseNoAds: onPurchaseNoAds,
            monetization: monetization,
          ),
          
          SizedBox(height: ResponsiveConfig.responsivePadding(32.0, screenSize)),
          
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
          
          SizedBox(height: ResponsiveConfig.responsivePadding(32.0, screenSize)),
          
          // Bundles Section
          BundlesSection(
            onPurchaseBundle: onPurchaseBundle,
          ),
          
          SizedBox(height: ResponsiveConfig.responsivePadding(32.0, screenSize)),
          
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
          
          SizedBox(height: ResponsiveConfig.responsivePadding(32.0, screenSize)),
          
          // Heart Booster Section
          HeartBoosterStore(
            inventory: inventory,
            onPurchaseBooster: onPurchaseBooster,
          ),
        ],
      ),
    );
  }

}


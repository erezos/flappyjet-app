/// 🎮 Continue with Insufficient Currency Helper
/// 
/// Handles continue game flow when user lacks gems
/// Shows smart gem pack recommendation based on purchase history
/// Ensures continue option remains valid after purchase
library;

import 'package:flutter/material.dart';
import '../../game/systems/inventory_manager.dart';
import '../../game/systems/monetization_manager.dart';
import '../../game/systems/purchase_history_manager.dart';
import '../../game/core/special_offer_config.dart';
import 'store/insufficient_currency_popup.dart';

/// Handle continue game with insufficient currency
/// 
/// Shows popup with smart gem pack recommendation:
/// - New users: 100 gems pack ($0.99)
/// - Returning users: Last purchased gem pack
/// 
/// After purchase, automatically retries the continue action
/// 
/// Returns true if continue was successful, false otherwise
Future<bool> handleContinueWithInsufficientCurrency({
  required BuildContext context,
  required int gemCost,
  required Future<void> Function() onContinueAction,
  String? continueContext, // e.g., 'story_mode', 'tournament', 'endless'
}) async {
  final inventory = InventoryManager();
  final currentGems = inventory.gems;
  
  // Check if user has enough gems
  if (currentGems >= gemCost) {
    // User has enough - proceed with continue
    await onContinueAction();
    return true;
  }
  
  // User doesn't have enough gems - show insufficient currency popup with smart gem pack recommendation
  final purchaseHistory = PurchaseHistoryManager();
  final recommendedPack = await purchaseHistory.getRecommendedGemPack();
  
  // Show insufficient currency popup with gem pack recommendation
  // The popup will use gem packs (not currency bundles) for continue flows
  final purchased = await showInsufficientCurrencyPopup(
    context: context,
    neededCurrency: OfferCurrencyType.gems,
    neededAmount: gemCost,
    currentAmount: currentGems,
    config: InsufficientCurrencyConfig(
      // Use gem packs for continue (not currency bundles)
      useCurrencyBundles: false,
      recommendedGemPackId: recommendedPack.id,
    ),
    onPurchase: () async {
      // Purchase the recommended gem pack
      final monetization = MonetizationManager();
      final result = await monetization.purchaseIAPProduct(recommendedPack.id);
      
      if (result.isSuccess && context.mounted) {
        // Wait for gems to be granted by IAP system
        await Future.delayed(const Duration(milliseconds: 800));
        
        // Retry the continue action - user now has gems
        await onContinueAction();
      } else if (result.isCancelled) {
        // User cancelled - no action needed
        return;
      } else if (result.isPending) {
        // Purchase pending - show message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Purchase is being processed...'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        // Purchase failed
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ?? 'Purchase failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    },
    onDismiss: () {
      // User dismissed - stay on current screen
    },
  );
  
  return purchased == true;
}

/// Helper class for continue with insufficient currency
class ContinueWithInsufficientCurrency {
  /// Handle continue with smart gem pack recommendation
  Future<bool> handleContinue({
    required BuildContext context,
    required int gemCost,
    required Future<void> Function() onContinueAction,
    String? continueContext,
  }) {
    return handleContinueWithInsufficientCurrency(
      context: context,
      gemCost: gemCost,
      onContinueAction: onContinueAction,
      continueContext: continueContext,
    );
  }
}


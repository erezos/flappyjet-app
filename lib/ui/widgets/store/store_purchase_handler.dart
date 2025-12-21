/// 🛒 Store Purchase Handler - Centralized purchase logic with error handling
library;

import 'package:flutter/material.dart';
import '../../../game/core/economy_config.dart';
import '../../../game/core/jet_skins.dart';
import '../../../game/core/special_offer_config.dart';
import '../../../game/systems/inventory_manager.dart';
import '../../../game/systems/monetization_manager.dart';
import '../../../game/systems/lives_manager.dart';
import '../../../game/systems/game_events_tracker.dart';
import '../../../core/events/event_bus.dart'; // ✅ ANALYTICS FIX
import '../../../game/systems/no_ads_manager.dart';
import 'heart_booster_store.dart';
import 'insufficient_currency_popup.dart';

class StorePurchaseHandler {
  final BuildContext context;
  final InventoryManager inventory;
  final MonetizationManager monetization;
  final EconomyConfig economy;
  final LivesManager livesManager;

  StorePurchaseHandler({
    required this.context,
    required this.inventory,
    required this.monetization,
    required this.economy,
    required this.livesManager,
  });

  /// Purchase a gem pack via Enhanced IAP
  Future<void> purchaseGemPack(GemPack pack) async {
    try {
      // Use enhanced IAP system for real purchases
      final result = await monetization.purchaseIAPProduct(pack.id);
      
      if (result.isSuccess) {
        // Gems are automatically granted by the enhanced IAP system
        if (context.mounted) {
          _showSuccessSnackBar('Purchased ${pack.totalGems} gems!');
        }
      } else if (result.isCancelled) {
        // User cancelled - no error message needed
        return;
      } else if (result.isPending) {
        if (context.mounted) {
          _showInfoSnackBar('Purchase is being processed...');
        }
      } else {
        // Purchase failed
        if (context.mounted) {
          _showErrorSnackBar(result.message ?? 'Purchase failed');
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar('Purchase error: $e');
      }
    }
  }

  /// Purchase a coin pack with gems
  Future<void> purchaseCoinPack(CoinPack pack) async {
    // Check if player has enough gems
    if (inventory.gems < pack.gemPrice) {
      // Show insufficient currency popup to offer gem packs
      if (context.mounted) {
        final shortfall = pack.gemPrice - inventory.gems;
        // Find best gem pack that covers the need (with 20% bonus)
        final targetGems = (shortfall * 1.2).ceil();
        final gemPacks = EconomyConfig.gemPacks.values.toList();
        GemPack? recommendedPack;
        
        // Find smallest pack that covers the need
        for (final gemPack in gemPacks) {
          if (gemPack.totalGems >= targetGems) {
            recommendedPack = gemPack;
            break;
          }
        }
        
        // Fallback to largest pack if none found
        recommendedPack ??= gemPacks.last;
        
        await showInsufficientCurrencyPopup(
          context: context,
          neededCurrency: OfferCurrencyType.gems,
          neededAmount: pack.gemPrice,
          currentAmount: inventory.gems,
          onPurchase: () async {
            // Purchase the recommended gem pack
            if (recommendedPack != null) {
              await purchaseGemPack(recommendedPack);
              // After purchasing gems, user can try purchasing coins again
              // The gems will be granted by the IAP system
            }
          },
          onDismiss: () {
            // User dismissed - optionally navigate to gem store
            // For now, just dismiss
          },
        );
      }
      return;
    }

    // Show confirmation dialog
    final bool? confirm = await _showConfirmDialog(
      'Purchase ${pack.displayName}?',
      'Exchange ${pack.gemPrice} gems for ${pack.totalCoins} coins?\n\n'
          '💰 ${pack.description}',
    );

    if (confirm == true) {
      try {
        // Spend gems
        final success = await inventory.spendGems(pack.gemPrice);
        if (success) {
          // Grant coins
          await inventory.grantSoftCurrency(pack.totalCoins);

          if (context.mounted) {
            _showSuccessSnackBar('💰 Received ${pack.totalCoins} coins!');
          }
        } else {
          if (context.mounted) {
            _showErrorSnackBar('💎 Not enough gems!');
          }
        }
      } catch (e) {
        if (context.mounted) {
          _showErrorSnackBar('Purchase failed: $e');
        }
      }
    }
  }

  /// Purchase a jet skin (handles both coin and gem purchases)
  Future<void> purchaseJetSkin(JetSkin skin) async {
    if (skin.isGemExclusive) {
      // Handle mythic skins with gems
      await _purchaseJetSkinWithGems(skin);
    } else {
      // Handle regular skins with coins
      await _purchaseJetSkinWithCoins(skin);
    }
  }

  /// Purchase a jet skin with coins
  Future<void> _purchaseJetSkinWithCoins(JetSkin skin) async {
    final price = economy.getSkinCoinPrice(skin);

    if (await inventory.spendSoftCurrency(price)) {
      await inventory.unlockSkin(skin.id);
      await inventory.equipSkin(skin.id);

      // 🏆 Track jet purchase for collection achievements
      final gameEvents = GameEventsTracker();
      await gameEvents.onSkinPurchased(
        skinId: skin.id,
        coinCost: price,
        rarity: skin.rarity.name,
      );

      if (context.mounted) {
        _showSuccessSnackBar('Purchased ${skin.displayName}');
      }
    } else {
      if (context.mounted) {
        _showErrorSnackBar('Not enough coins. Visit the coin shop!');
      }
    }
  }

  /// Purchase a mythic jet skin with gems
  Future<void> _purchaseJetSkinWithGems(JetSkin skin) async {
    final gemPrice = economy.getSkinGemPrice(skin);

    // Check if player has enough gems
    if (inventory.gems < gemPrice) {
      if (context.mounted) {
        _showErrorSnackBar('Not enough gems! Need $gemPrice gems.');
      }
      return;
    }

    // Show confirmation dialog for premium purchase
    final bool? confirm = await _showConfirmDialog(
      'Purchase ${skin.displayName}?',
      'Spend $gemPrice gems for this exclusive mythic jet?\n\n'
          '✨ ${skin.description}',
    );

    if (confirm == true) {
      try {
        // Spend gems
        final success = await inventory.spendGems(gemPrice);
        if (success) {
          await inventory.unlockSkin(skin.id);
          await inventory.equipSkin(skin.id);

          // 🏆 Track mythic jet purchase for collection achievements
          final gameEvents = GameEventsTracker();
          await gameEvents.onSkinPurchased(
            skinId: skin.id,
            coinCost: 0, // No coins spent
            rarity: skin.rarity.name,
          );

          // ✅ ANALYTICS FIX: Fire EventBus event for backend
          EventBus().fire('skin_purchased', {
            'jet_id': skin.id,
            'jet_name': skin.displayName,
            'purchase_type': 'gems',
            'cost_coins': 0,
            'cost_gems': gemPrice,
            'rarity': skin.rarity.name,
          });

          if (context.mounted) {
            _showSuccessSnackBar('🎉 Purchased exclusive ${skin.displayName}!');
          }
        } else {
          if (context.mounted) {
            _showErrorSnackBar('💎 Not enough gems!');
          }
        }
      } catch (e) {
        if (context.mounted) {
          _showErrorSnackBar('Purchase failed: $e');
        }
      }
    }
  }

  /// Equip a jet skin
  Future<void> equipJetSkin(JetSkin skin) async {
    await inventory.equipSkin(skin.id);

    if (context.mounted) {
      _showSuccessSnackBar('Equipped ${skin.displayName}');
    }
  }

  /// Purchase heart booster with gems
  Future<void> purchaseHeartBoosterWithGems() async {
    final pack = EconomyConfig.heartBoosterPack;

    if (inventory.gems >= pack.gemPrice) {
      // Purchase immediately without confirmation (user can see the cost before clicking)
      await inventory.spendGems(pack.gemPrice);
      await inventory.activateHeartBooster(pack.duration);

      // 🔥 FIX: Refill hearts to new maximum (6) when booster is activated
      await livesManager.refillToMax();

      if (context.mounted) {
        _showSuccessSnackBar(
          'Heart Booster activated! Hearts refilled to 6!',
        );
      }
    } else {
      if (context.mounted) {
        _showErrorSnackBar('Not enough gems!');
      }
    }
  }

  /// Purchase heart booster with specific duration via Enhanced IAP
  Future<void> purchaseHeartBooster(BoosterDuration duration) async {
    try {
      // Map duration to IAP product ID
      String productId;
      switch (duration.hours) {
        case 24:
          productId = 'heart_booster_24h';
          break;
        case 48:
          productId = 'heart_booster_48h';
          break;
        case 72:
          productId = 'heart_booster_72h';
          break;
        default:
          productId = 'heart_booster_24h'; // Default fallback
      }

      // Use enhanced IAP system for real purchases
      final result = await monetization.purchaseIAPProduct(productId);
      
      if (result.isSuccess) {
        // Heart booster is automatically activated by the enhanced IAP system
        if (context.mounted) {
          _showSuccessSnackBar(
            '${duration.displayName} activated! Hearts refilled to 6!',
          );
        }
      } else if (result.isCancelled) {
        // User cancelled - no error message needed
        return;
      } else if (result.isPending) {
        if (context.mounted) {
          _showInfoSnackBar('Purchase is being processed...');
        }
      } else {
        // Purchase failed
        if (context.mounted) {
          _showErrorSnackBar(result.message ?? 'Purchase failed');
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar('Purchase failed: $e');
      }
    }
  }

  /// Purchase heart booster with USD via Enhanced IAP
  Future<void> purchaseHeartBoosterWithUSD() async {
    try {
      // Use enhanced IAP system for real 24h booster purchase
      final result = await monetization.purchaseIAPProduct('heart_booster_24h');
      
      if (result.isSuccess) {
        // Heart booster is automatically activated by the enhanced IAP system
        if (context.mounted) {
          _showSuccessSnackBar('Heart Booster activated! Hearts refilled to 6!');
        }
      } else if (result.isCancelled) {
        // User cancelled - no error message needed
        return;
      } else if (result.isPending) {
        if (context.mounted) {
          _showInfoSnackBar('Purchase is being processed...');
        }
      } else {
        // Purchase failed
        if (context.mounted) {
          _showErrorSnackBar(result.message ?? 'Purchase failed');
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar('Purchase failed: $e');
      }
    }
  }

  /// Purchase full hearts refill with gems
  Future<void> purchaseFullHeartsRefill() async {
    final refillPrice = economy.fullHeartsRefillGemCost;
    final currentHearts = livesManager.currentLives;
    final maxHearts = livesManager.maxLives;
    final heartsToRefill = maxHearts - currentHearts;

    // Check if already at max
    if (currentHearts >= maxHearts) {
      if (context.mounted) {
        _showInfoSnackBar('💖 Hearts are already full!');
      }
      return;
    }

    // Check if player has enough gems
    if (inventory.gems < refillPrice) {
      if (context.mounted) {
        _showErrorSnackBar('💎 Need $refillPrice gems to refill all hearts');
      }
      return;
    }

    // Purchase immediately without confirmation (user can see the cost before clicking)
    try {
      // Spend gems
      final success = await inventory.spendGems(refillPrice);
      if (success) {
        // Refill all hearts
        await livesManager.refillToMax();

        if (context.mounted) {
          _showSuccessSnackBar(
            '💖 All hearts refilled! (+$heartsToRefill heart${heartsToRefill != 1 ? 's' : ''})',
          );
        }
      } else {
        if (context.mounted) {
          _showErrorSnackBar('💎 Not enough gems!');
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar('Purchase failed: $e');
      }
    }
  }

  /// Show confirmation dialog
  Future<bool?> _showConfirmDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Buy'),
          ),
        ],
      ),
    );
  }

  /// Show success snackbar
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show info snackbar
  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Purchase No Ads product
  Future<void> purchaseNoAds(NoAdsProduct product) async {
    try {
      // Use enhanced IAP system for real purchases
      final result = await monetization.purchaseIAPProduct(product.id);
      
      if (result.isSuccess) {
        // Activate No Ads based on product type
        final noAdsManager = NoAdsManager();
        if (product.type == NoAdsProductType.lifetime) {
          await noAdsManager.activateLifetime();
        } else if (product.type == NoAdsProductType.monthly) {
          await noAdsManager.activateMonthly();
        } else if (product.type == NoAdsProductType.hours24) {
          await noAdsManager.activate24Hours();
        } else if (product.type == NoAdsProductType.week) {
          await noAdsManager.activate1Week();
        }

        // 📊 Track analytics
        EventBus().fire('no_ads_purchased', {
          'product_id': product.id,
          'product_type': product.type.name,
          'price_usd': product.usdPrice,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });

        // 📊 Firebase Analytics
        final gameEvents = GameEventsTracker();
        await gameEvents.onNoAdsPurchased(
          productType: product.type.name,
          priceUSD: product.usdPrice,
        );

        if (context.mounted) {
          _showSuccessSnackBar('🚫 No Ads activated! Enjoy uninterrupted gameplay!');
        }
      } else if (result.isCancelled) {
        // User cancelled - no error message needed
        return;
      } else if (result.isPending) {
        if (context.mounted) {
          _showInfoSnackBar('Purchase is being processed...');
        }
      } else {
        // Purchase failed
        if (context.mounted) {
          _showErrorSnackBar(result.message ?? 'Purchase failed');
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar('Purchase error: $e');
      }
    }
  }

  /// Purchase bundle product (Heart Booster + No Ads)
  Future<void> purchaseBundle(BundleProduct bundle) async {
    try {
      // Use enhanced IAP system for real purchases
      final result = await monetization.purchaseIAPProduct(bundle.id);
      
      if (result.isSuccess) {
        // Activate Heart Booster
        final heartBoosterPack = EconomyConfig.heartBoosterPacks.values.firstWhere(
          (pack) => pack.durationHours == bundle.heartBoosterHours,
          orElse: () => EconomyConfig.heartBoosterPacks['heart_booster_24h']!,
        );
        await inventory.activateHeartBooster(heartBoosterPack.duration);
        
        // Activate No Ads for the bundle duration
        final noAdsManager = NoAdsManager();
        await noAdsManager.extendNoAds(Duration(hours: bundle.noAdsHours));
        
        // 📊 Track analytics
        EventBus().fire('bundle_purchased', {
          'bundle_id': bundle.id,
          'heart_booster_hours': bundle.heartBoosterHours,
          'no_ads_hours': bundle.noAdsHours,
          'price_usd': bundle.usdPrice,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });

        if (context.mounted) {
          _showSuccessSnackBar('🎁 Bundle activated! Enjoy your boosters!');
        }
      } else if (result.isCancelled) {
        return;
      } else if (result.isPending) {
        if (context.mounted) {
          _showInfoSnackBar('Purchase is being processed...');
        }
      } else {
        if (context.mounted) {
          _showErrorSnackBar(result.message ?? 'Purchase failed');
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar('Purchase error: $e');
      }
    }
  }

  /// Purchase currency bundle (Gems + Coins)
  Future<void> purchaseCurrencyBundle(CurrencyBundle bundle) async {
    try {
      // Use enhanced IAP system for real purchases
      final result = await monetization.purchaseIAPProduct(bundle.id);
      
      if (result.isSuccess) {
        // Gems and coins are automatically granted by the enhanced IAP system
        // But we can also manually grant them as a backup
        await inventory.grantGems(bundle.totalGems);
        await inventory.grantSoftCurrency(bundle.totalCoins);
        
        // 📊 Track analytics
        EventBus().fire('currency_bundle_purchased', {
          'bundle_id': bundle.id,
          'gems': bundle.totalGems,
          'coins': bundle.totalCoins,
          'price_usd': bundle.usdPrice,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });

        // 📊 Firebase Analytics
        final gameEvents = GameEventsTracker();
        await gameEvents.onCurrencyBundlePurchased(
          bundleId: bundle.id,
          gems: bundle.totalGems,
          coins: bundle.totalCoins,
          priceUSD: bundle.usdPrice,
        );

        if (context.mounted) {
          _showSuccessSnackBar('🎁 Bundle purchased! ${bundle.totalGems} Gems + ${bundle.totalCoins} Coins added!');
        }
      } else if (result.isCancelled) {
        return;
      } else if (result.isPending) {
        if (context.mounted) {
          _showInfoSnackBar('Purchase is being processed...');
        }
      } else {
        if (context.mounted) {
          _showErrorSnackBar(result.message ?? 'Purchase failed');
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar('Purchase error: $e');
      }
    }
  }
}

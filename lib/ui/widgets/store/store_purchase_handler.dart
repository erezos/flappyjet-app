/// 🛒 Store Purchase Handler - Centralized purchase logic with error handling
library;

import 'package:flutter/material.dart';
import '../../../game/core/economy_config.dart';
import '../../../game/core/jet_skins.dart';
import '../../../game/systems/inventory_manager.dart';
import '../../../game/systems/monetization_manager.dart';
import '../../../game/systems/lives_manager.dart';
import '../../../game/systems/game_events_tracker.dart';
import 'heart_booster_store.dart';

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
      if (context.mounted) {
        _showErrorSnackBar('Not enough gems! Need ${pack.gemPrice} gems.');
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
      final bool? confirm = await _showConfirmDialog(
        'Purchase Heart Booster?',
        'Spend ${pack.gemPrice} gems for 24h Heart Booster?',
      );

      if (confirm == true) {
        await inventory.spendGems(pack.gemPrice);
        await inventory.activateHeartBooster(pack.duration);

        // 🔥 FIX: Refill hearts to new maximum (6) when booster is activated
        await livesManager.refillToMax();

        if (context.mounted) {
          _showSuccessSnackBar(
            'Heart Booster activated! Hearts refilled to 6!',
          );
        }
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

    // Show confirmation dialog
    final bool? confirm = await _showConfirmDialog(
      'Full Hearts Refill?',
      'Spend $refillPrice gems to fill all $heartsToRefill missing heart${heartsToRefill != 1 ? 's' : ''}?',
    );

    if (confirm == true) {
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
}

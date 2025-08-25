/// 🛒 Store Purchase Handler - Centralized purchase logic with error handling
import 'package:flutter/material.dart';
import '../../../game/core/economy_config.dart';
import '../../../game/core/jet_skins.dart';
import '../../../game/systems/inventory_manager.dart';
import '../../../game/systems/monetization_manager.dart';
import '../../../game/systems/lives_manager.dart';

class StorePurchaseHandler {
  final BuildContext context;
  final InventoryManager inventory;
  final MonetizationManager monetization;
  final EconomyConfig economy;

  StorePurchaseHandler({
    required this.context,
    required this.inventory,
    required this.monetization,
    required this.economy,
  });

  /// Purchase a gem pack via IAP
  Future<void> purchaseGemPack(GemPack pack) async {
    try {
      // Simulate IAP purchase
      await monetization.purchaseProduct(pack.id);
      
      // Grant gems on successful purchase
      await inventory.grantGems(pack.totalGems);
      
      if (context.mounted) {
        _showSuccessSnackBar('Purchased ${pack.totalGems} gems!');
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar('Purchase failed: $e');
      }
    }
  }

  /// Purchase a jet skin with soft currency
  Future<void> purchaseJetSkin(JetSkin skin) async {
    final price = economy.getSkinCoinPrice(skin);
    
    if (await inventory.spendSoftCurrency(price)) {
      await inventory.unlockSkin(skin.id);
      await inventory.equipSkin(skin.id);
      
      if (context.mounted) {
        _showSuccessSnackBar('Purchased ${skin.displayName}');
      }
    } else {
      if (context.mounted) {
        _showErrorSnackBar('Not enough coins. Visit the coin shop!');
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
        final livesManager = LivesManager();
        await livesManager.refillToMax();
        
        if (context.mounted) {
          _showSuccessSnackBar('Heart Booster activated! Hearts refilled to 6!');
        }
      }
    } else {
      if (context.mounted) {
        _showErrorSnackBar('Not enough gems!');
      }
    }
  }

  /// Purchase heart booster with USD
  Future<void> purchaseHeartBoosterWithUSD() async {
    try {
      // Simulate IAP purchase
      await monetization.purchaseProduct('heart_booster_24h');
      
      // Activate booster on successful purchase
      final pack = EconomyConfig.heartBoosterPack;
      await inventory.activateHeartBooster(pack.duration);
      
      // 🔥 FIX: Refill hearts to new maximum (6) when booster is activated
      final livesManager = LivesManager();
      await livesManager.refillToMax();
      
      if (context.mounted) {
        _showSuccessSnackBar('Heart Booster activated! Hearts refilled to 6!');
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar('Purchase failed: $e');
      }
    }
  }

  /// Purchase full hearts refill with gems
  Future<void> purchaseFullHeartsRefill() async {
    final livesManager = LivesManager();
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
              '💖 All hearts refilled! (+$heartsToRefill heart${heartsToRefill != 1 ? 's' : ''})'
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
            child: const Text('Cancel')
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Buy')
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

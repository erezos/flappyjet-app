/// 🛒 Jets Store Component - Jet skins with purchase and equip functionality
library;

import 'package:flutter/material.dart';
import '../../../game/core/jet_skins.dart';
import '../../../game/core/economy_config.dart';
import '../../../game/systems/inventory_manager.dart';
import '../gem_3d_icon.dart';

class JetsStore extends StatelessWidget {
  final InventoryManager inventory;
  final EconomyConfig economy;
  final Function(JetSkin) onPurchaseJet;
  final Function(JetSkin) onEquipJet;

  const JetsStore({
    super.key,
    required this.inventory,
    required this.economy,
    required this.onPurchaseJet,
    required this.onEquipJet,
  });

  @override
  Widget build(BuildContext context) {
    final allSkins = [
      JetSkinCatalog.starterJet,
      ...JetSkinCatalog.premiumSkins,
    ];
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 16,
        vertical: 12,
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isTablet ? 3 : 2,
          childAspectRatio: isTablet ? 0.85 : 0.75,
          crossAxisSpacing: isTablet ? 20 : 12,
          mainAxisSpacing: isTablet ? 20 : 12,
        ),
        itemCount: allSkins.length,
        itemBuilder: (context, index) {
          final skin = allSkins[index];
          return ModernJetCard(
            skin: skin,
            inventory: inventory,
            economy: economy,
            onPurchase: () => onPurchaseJet(skin),
            onEquip: () => onEquipJet(skin),
          );
        },
      ),
    );
  }
}

/// Modern, compact jet card with consistent design language
class ModernJetCard extends StatelessWidget {
  final JetSkin skin;
  final InventoryManager inventory;
  final EconomyConfig economy;
  final VoidCallback onPurchase;
  final VoidCallback onEquip;

  const ModernJetCard({
    super.key,
    required this.skin,
    required this.inventory,
    required this.economy,
    required this.onPurchase,
    required this.onEquip,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return AnimatedBuilder(
      animation: inventory,
      builder: (context, _) {
        final isOwned = inventory.isOwned(skin.id) || skin.isPurchased;
        final isEquipped = inventory.equippedSkinId == skin.id;
        final coinPrice = economy.getSkinCoinPrice(skin);
        final gemPrice = economy.getSkinGemPrice(skin);
        final isGemExclusive = skin.isGemExclusive;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _getCardColors(isOwned, isEquipped, skin.rarity),
            ),
            borderRadius: BorderRadius.circular(20),
            border: isEquipped
                ? Border.all(color: const Color(0xFFFFD700), width: 2)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
              if (isEquipped)
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 0),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: [
                // Header with rarity indicator
                Container(
                  height: isTablet ? 32 : 28,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        JetSkinColors.getRarityColor(
                          skin.rarity,
                        ).withValues(alpha: 0.8),
                        JetSkinColors.getRarityColor(
                          skin.rarity,
                        ).withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _getRarityText(skin.rarity),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTablet ? 11 : 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Jet preview section - much bigger, fills most of the card
                Expanded(
                  flex: 4,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isTablet ? 8 : 6),
                    child: Image.asset(
                      'assets/images/${skin.assetPath}',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.airplanemode_active,
                          color: Colors.white.withValues(alpha: 0.7),
                          size: isTablet ? 80 : 60,
                        );
                      },
                    ),
                  ),
                ),

                // Info section
                Expanded(
                  flex: 2,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 12 : 8,
                      vertical: isTablet ? 8 : 6,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Name
                        Text(
                          skin.displayName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isTablet ? 14 : 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // Action button
                        _buildActionButton(
                          isOwned,
                          isEquipped,
                          coinPrice,
                          gemPrice,
                          isGemExclusive,
                          isTablet,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Color> _getCardColors(bool isOwned, bool isEquipped, JetRarity rarity) {
    if (isEquipped) {
      // Equipped: Always green regardless of rarity
      return [const Color(0xFF4CAF50), const Color(0xFF2E7D32)];
    } else if (isOwned) {
      // Owned: Always blue regardless of rarity
      return [const Color(0xFF1976D2), const Color(0xFF0D47A1)];
    } else {
      // Unowned: Rarity-based colors
      switch (rarity) {
        case JetRarity.common:
          return [const Color(0xFF616161), const Color(0xFF424242)]; // Gray
        case JetRarity.rare:
          return [const Color(0xFF1976D2), const Color(0xFF0D47A1)]; // Blue
        case JetRarity.epic:
          return [const Color(0xFF7B1FA2), const Color(0xFF4A148C)]; // Purple
        case JetRarity.legendary:
          return [const Color(0xFFE65100), const Color(0xFFBF360C)]; // Orange
        case JetRarity.mythic:
          return [
            const Color(0xFFAD1457),
            const Color(0xFF880E4F),
          ]; // Pink/Magenta
      }
    }
  }

  String _getRarityText(JetRarity rarity) {
    switch (rarity) {
      case JetRarity.common:
        return 'COMMON';
      case JetRarity.rare:
        return 'RARE';
      case JetRarity.epic:
        return 'EPIC';
      case JetRarity.legendary:
        return 'LEGENDARY';
      case JetRarity.mythic:
        return 'MYTHIC';
    }
  }

  Widget _buildActionButton(
    bool isOwned,
    bool isEquipped,
    int coinPrice,
    int gemPrice,
    bool isGemExclusive,
    bool isTablet,
  ) {
    if (isEquipped) {
      return Container(
        width: double.infinity,
        height: isTablet ? 32 : 28,
        decoration: BoxDecoration(
          color: const Color(0xFFFFD700),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'EQUIPPED',
            style: TextStyle(
              color: Colors.black,
              fontSize: isTablet ? 11 : 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    } else if (isOwned) {
      return GestureDetector(
        onTap: onEquip,
        child: Container(
          width: double.infinity,
          height: isTablet ? 32 : 28,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              'EQUIP',
              style: TextStyle(
                color: Colors.white,
                fontSize: isTablet ? 11 : 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    } else {
      // Purchase button - different styling for gem vs coin purchases
      return GestureDetector(
        onTap: onPurchase,
        child: Container(
          width: double.infinity,
          height: isTablet ? 32 : 28,
          decoration: BoxDecoration(
            gradient: isGemExclusive
                ? const LinearGradient(
                    colors: [
                      Color(0xFFE91E63),
                      Color(0xFFC2185B),
                    ], // Pink gradient for mythic
                  )
                : const LinearGradient(
                    colors: [
                      Color(0xFFFFD700),
                      Color(0xFFFFA000),
                    ], // Gold gradient for coins
                  ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color:
                    (isGemExclusive
                            ? const Color(0xFFE91E63)
                            : const Color(0xFFFFD700))
                        .withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                isGemExclusive
                    ? Gem3DIcon(
                        size: isTablet ? 14 : 12,
                        // No primaryColor to match navigation bar appearance
                      )
                    : Icon(
                        Icons.monetization_on,
                        color: Colors.white,
                        size: isTablet ? 14 : 12,
                      ),
                SizedBox(width: isTablet ? 4 : 2),
                Text(
                  isGemExclusive ? '$gemPrice' : '$coinPrice',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 11 : 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}

// Keep the old JetSkinCard for backward compatibility
class JetSkinCard extends StatelessWidget {
  final JetSkin skin;
  final InventoryManager inventory;
  final EconomyConfig economy;
  final VoidCallback onPurchase;
  final VoidCallback onEquip;

  const JetSkinCard({
    super.key,
    required this.skin,
    required this.inventory,
    required this.economy,
    required this.onPurchase,
    required this.onEquip,
  });

  @override
  Widget build(BuildContext context) {
    return ModernJetCard(
      skin: skin,
      inventory: inventory,
      economy: economy,
      onPurchase: onPurchase,
      onEquip: onEquip,
    );
  }
}

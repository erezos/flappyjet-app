/// 🛒 Coins Store Component - Gem-to-Coins exchange with mobile game best practices
library;

import 'package:flutter/material.dart';
import '../../../game/core/economy_config.dart';
import '../../../game/systems/inventory_manager.dart';
import '../gem_3d_icon.dart';

class CoinsStore extends StatelessWidget {
  final InventoryManager inventory;
  final EconomyConfig economy;
  final Function(CoinPack) onPurchaseCoinPack;

  const CoinsStore({
    super.key,
    required this.inventory,
    required this.economy,
    required this.onPurchaseCoinPack,
  });

  @override
  Widget build(BuildContext context) {
    final coinPacks = EconomyConfig.coinPacks.values.toList();
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 16,
        vertical: 12,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate optimal aspect ratio based on available space
          final availableHeight = constraints.maxHeight;
          final cardHeight =
              (availableHeight - (isTablet ? 20 : 12)) /
              2; // 2 rows, minus spacing
          final cardWidth =
              (screenWidth - (isTablet ? 68 : 44)) /
              2; // 2 columns, minus padding/spacing
          final optimalAspectRatio = (cardWidth / cardHeight).clamp(0.7, 1.2);

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: optimalAspectRatio,
              crossAxisSpacing: isTablet ? 20 : 12,
              mainAxisSpacing: isTablet ? 20 : 12,
            ),
            itemCount: coinPacks.length,
            itemBuilder: (context, index) {
              final pack = coinPacks[index];
              final isBestValue = index == 2; // Large pack is best value
              final isPopular = index == 1; // Medium pack is most popular

              return ModernCoinPackCard(
                pack: pack,
                inventory: inventory,
                isPopular: isPopular,
                isBestValue: isBestValue,
                onTap: () => onPurchaseCoinPack(pack),
              );
            },
          );
        },
      ),
    );
  }
}

/// Modern coin pack card with gem pricing
class ModernCoinPackCard extends StatelessWidget {
  final CoinPack pack;
  final InventoryManager inventory;
  final bool isPopular;
  final bool isBestValue;
  final VoidCallback onTap;

  const ModernCoinPackCard({
    super.key,
    required this.pack,
    required this.inventory,
    required this.isPopular,
    required this.isBestValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getCoinPackColors();
    final canAfford = inventory.gems >= pack.gemPrice;

    return GestureDetector(
      onTap: canAfford ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: canAfford
                ? colors
                : [Colors.grey.shade400, Colors.grey.shade600],
          ),
          borderRadius: BorderRadius.circular(20),
          border: isPopular && canAfford
              ? Border.all(color: const Color(0xFFFFD700), width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: (canAfford ? colors[0] : Colors.grey).withValues(
                alpha: 0.3,
              ),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Main content
            Padding(
              padding: const EdgeInsets.all(6),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cardHeight = constraints.maxHeight;
                  final iconSize = (cardHeight * 0.2).clamp(20.0, 35.0);
                  final titleSize = (cardHeight * 0.08).clamp(12.0, 16.0);
                  final coinSize = (cardHeight * 0.07).clamp(11.0, 14.0);
                  final priceSize = (cardHeight * 0.09).clamp(14.0, 18.0);

                  return Column(
                    children: [
                      // Top section - Badge (fixed height)
                      SizedBox(
                        height: (cardHeight * 0.15).clamp(20.0, 30.0),
                        child: Center(
                          child: isPopular && canAfford
                              ? _buildPopularBadge()
                              : isBestValue && canAfford
                              ? _buildBestValueBadge()
                              : const SizedBox.shrink(),
                        ),
                      ),

                      // Icon section (fixed height)
                      SizedBox(
                        height: (cardHeight * 0.25).clamp(35.0, 50.0),
                        child: Center(
                          child: Icon(
                            Icons.monetization_on,
                            size: iconSize,
                            color: canAfford
                                ? const Color(0xFFFFD700)
                                : Colors.grey.shade300,
                          ),
                        ),
                      ),

                      // Title section (fixed height)
                      SizedBox(
                        height: (cardHeight * 0.15).clamp(20.0, 30.0),
                        child: Center(
                          child: Text(
                            pack.displayName,
                            style: TextStyle(
                              color: canAfford
                                  ? Colors.white
                                  : Colors.grey.shade300,
                              fontSize: titleSize,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),

                      // Coins info section (fixed height)
                      SizedBox(
                        height: (cardHeight * 0.2).clamp(30.0, 40.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${pack.coins} Coins',
                              style: TextStyle(
                                color: canAfford
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : Colors.grey.shade300,
                                fontSize: coinSize,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (pack.hasBonus) ...[
                              const SizedBox(height: 2),
                              Text(
                                '+${pack.bonusCoins} BONUS',
                                style: TextStyle(
                                  color: canAfford
                                      ? const Color(0xFFFFD700)
                                      : Colors.grey.shade400,
                                  fontSize: (coinSize * 0.85).clamp(9.0, 11.0),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Spacer to push price to bottom
                      const Spacer(),

                      // Price button section (fixed height at bottom)
                      Container(
                        width: double.infinity,
                        height: (cardHeight * 0.18).clamp(30.0, 40.0),
                        decoration: BoxDecoration(
                          color: canAfford
                              ? Colors.white.withValues(alpha: 0.2)
                              : Colors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: canAfford
                                ? Colors.white.withValues(alpha: 0.3)
                                : Colors.grey.withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Gem3DIcon(size: priceSize * 0.8),
                            const SizedBox(width: 4),
                            Text(
                              '${pack.gemPrice}',
                              style: TextStyle(
                                color: canAfford
                                    ? Colors.white
                                    : Colors.grey.shade300,
                                fontSize: priceSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Shimmer effect for popular items
            if (isPopular && canAfford) _buildShimmerEffect(),

            // "Not enough gems" overlay
            if (!canAfford) _buildNotEnoughGemsOverlay(),
          ],
        ),
      ),
    );
  }

  List<Color> _getCoinPackColors() {
    // Use pack ID to determine colors consistently
    if (pack.id.contains('small')) {
      return [const Color(0xFFFF9800), const Color(0xFFE65100)];
    } else if (pack.id.contains('medium')) {
      return [const Color(0xFF4CAF50), const Color(0xFF2E7D32)];
    } else if (pack.id.contains('large')) {
      return [const Color(0xFF9C27B0), const Color(0xFF6A1B9A)];
    } else if (pack.id.contains('mega')) {
      return [const Color(0xFFE91E63), const Color(0xFFC2185B)];
    }
    return [const Color(0xFFFF9800), const Color(0xFFE65100)];
  }

  Widget _buildPopularBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Text(
        '🔥 POPULAR',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBestValueBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Text(
        '💎 BEST VALUE',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.1),
              Colors.transparent,
              Colors.white.withValues(alpha: 0.1),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildNotEnoughGemsOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.black.withValues(alpha: 0.3),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock, color: Colors.white70, size: 24),
              SizedBox(height: 4),
              Text(
                'Need More\nGems',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

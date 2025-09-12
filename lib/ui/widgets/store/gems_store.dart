/// 🛒 Gems Store Component - IAP gem packs with responsive design
library;

import 'package:flutter/material.dart';
import '../../../game/core/economy_config.dart';
import '../gem_3d_icon.dart';

class GemsStore extends StatelessWidget {
  final Function(GemPack) onPurchaseGemPack;

  const GemsStore({super.key, required this.onPurchaseGemPack});

  @override
  Widget build(BuildContext context) {
    final gemPacks = EconomyConfig.gemPacks.values.toList();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;

    // Calculate optimal aspect ratio based on available space
    final availableHeight =
        screenHeight * 0.6; // Approximate available height for content
    final cardHeight =
        (availableHeight - 60) / 2; // 2 rows, minus padding/spacing
    final cardWidth =
        (screenWidth - (isTablet ? 68 : 44)) /
        2; // 2 columns, minus padding/spacing
    final optimalAspectRatio = (cardWidth / cardHeight).clamp(0.7, 1.2);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 16,
        vertical: 12,
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: optimalAspectRatio,
          crossAxisSpacing: isTablet ? 20 : 12,
          mainAxisSpacing: isTablet ? 20 : 12,
        ),
        itemCount: gemPacks.length,
        itemBuilder: (context, index) {
          final pack = gemPacks[index];
          final isPopular = index == 1; // Medium pack is most popular
          final isBestValue = index == 2; // Large pack is best value

          return ModernGemPackCard(
            pack: pack,
            isPopular: isPopular,
            isBestValue: isBestValue,
            onTap: () => onPurchaseGemPack(pack),
          );
        },
      ),
    );
  }
}

/// Modern gem pack card with consistent structure and price positioning
class ModernGemPackCard extends StatelessWidget {
  final GemPack pack;
  final bool isPopular;
  final bool isBestValue;
  final VoidCallback onTap;

  const ModernGemPackCard({
    super.key,
    required this.pack,
    required this.isPopular,
    required this.isBestValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getGemPackColors();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(20),
          border: isPopular
              ? Border.all(color: const Color(0xFFFFD700), width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: colors[0].withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Main content
            Padding(
              padding: const EdgeInsets.all(6), // Reduced from 8 to 6
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cardHeight = constraints.maxHeight;
                  final iconSize = (cardHeight * 0.2).clamp(20.0, 35.0);
                  final titleSize = (cardHeight * 0.08).clamp(12.0, 16.0);
                  final gemSize = (cardHeight * 0.07).clamp(11.0, 14.0);
                  final priceSize = (cardHeight * 0.09).clamp(14.0, 18.0);

                  return Column(
                    children: [
                      // Top section - Badge (fixed height)
                      SizedBox(
                        height: (cardHeight * 0.15).clamp(20.0, 30.0),
                        child: Center(
                          child: isPopular
                              ? _buildPopularBadge()
                              : isBestValue
                              ? _buildBestValueBadge()
                              : const SizedBox.shrink(),
                        ),
                      ),

                      // Icon section (fixed height)
                      SizedBox(
                        height: (cardHeight * 0.25).clamp(35.0, 50.0),
                        child: Center(child: Gem3DIcon(size: iconSize)),
                      ),

                      // Title section (fixed height)
                      SizedBox(
                        height: (cardHeight * 0.15).clamp(20.0, 30.0),
                        child: Center(
                          child: Text(
                            pack.displayName,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: titleSize,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),

                      // Gems info section (fixed height)
                      SizedBox(
                        height: (cardHeight * 0.2).clamp(30.0, 40.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${pack.gems} Gems',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: gemSize,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (pack.hasBonus) ...[
                              const SizedBox(height: 2),
                              Text(
                                '+${pack.bonusGems} BONUS',
                                style: TextStyle(
                                  color: const Color(0xFFFFD700),
                                  fontSize: (gemSize * 0.85).clamp(9.0, 11.0),
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
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '\$${pack.usdPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: priceSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Shimmer effect for popular items
            if (isPopular) _buildShimmerEffect(),
          ],
        ),
      ),
    );
  }

  List<Color> _getGemPackColors() {
    // Use pack ID to determine colors consistently
    if (pack.id.contains('small')) {
      return [const Color(0xFF42A5F5), const Color(0xFF1976D2)];
    } else if (pack.id.contains('medium')) {
      return [const Color(0xFF9C27B0), const Color(0xFF6A1B9A)];
    } else if (pack.id.contains('large')) {
      return [const Color(0xFFFF9800), const Color(0xFFE65100)];
    } else if (pack.id.contains('mega')) {
      return [const Color(0xFF4CAF50), const Color(0xFF2E7D32)];
    }
    return [const Color(0xFF42A5F5), const Color(0xFF1976D2)];
  }

  // Removed _getGemIconColor() - no longer needed with asset image

  Widget _buildPopularBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ), // More compact
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
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ), // More compact
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
}

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
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargeTablet = screenSize.width > 900;

    // Dynamic aspect ratio - more compact cards to reduce empty space
    double aspectRatio;
    if (isLargeTablet) {
      aspectRatio = 1.1; // More compact on large tablets
    } else if (isTablet) {
      aspectRatio = 1.0; // Square-ish on regular tablets
    } else {
      aspectRatio = 0.9; // Slightly taller on mobile
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 16,
        vertical: 12,
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(), // Parent SingleChildScrollView handles scrolling
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: aspectRatio,
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
            // Main content - Truly responsive design
            Padding(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width > 600 ? 12 : 8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = constraints.maxWidth;
                  final isTablet = MediaQuery.of(context).size.width > 600;
                  final isLargeTablet = MediaQuery.of(context).size.width > 900;
                  
                  // Responsive sizing based on actual card dimensions
                  final iconSize = isLargeTablet 
                      ? (cardWidth * 0.35).clamp(45.0, 70.0)
                      : isTablet 
                          ? (cardWidth * 0.3).clamp(35.0, 55.0)
                          : (cardWidth * 0.25).clamp(25.0, 40.0);
                          
                  final titleSize = isLargeTablet 
                      ? (cardWidth * 0.08).clamp(18.0, 24.0)
                      : isTablet 
                          ? (cardWidth * 0.07).clamp(16.0, 20.0)
                          : (cardWidth * 0.06).clamp(12.0, 16.0);
                          
                  final gemSize = isLargeTablet 
                      ? (cardWidth * 0.07).clamp(16.0, 20.0)
                      : isTablet 
                          ? (cardWidth * 0.06).clamp(14.0, 18.0)
                          : (cardWidth * 0.055).clamp(11.0, 14.0);
                          
                  final bonusSize = gemSize * 0.8;
                  
                  final priceSize = isLargeTablet 
                      ? (cardWidth * 0.08).clamp(20.0, 26.0)
                      : isTablet 
                          ? (cardWidth * 0.07).clamp(18.0, 22.0)
                          : (cardWidth * 0.065).clamp(14.0, 18.0);

                  return Column(
                    children: [
                      // Top section - Badge (compact height)
                      SizedBox(
                        height: isLargeTablet ? 32 : isTablet ? 28 : 22,
                        child: Center(
                          child: isPopular
                              ? _buildPopularBadge(isTablet)
                              : isBestValue
                              ? _buildBestValueBadge(isTablet)
                              : const SizedBox.shrink(),
                        ),
                      ),

                      // Icon section (compact height)
                      SizedBox(
                        height: isLargeTablet ? 70 : isTablet ? 60 : 45,
                        child: Center(child: Gem3DIcon(size: iconSize)),
                      ),

                      SizedBox(height: isTablet ? 6 : 3),

                      // Title section (responsive)
                      Text(
                        pack.displayName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: titleSize,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      SizedBox(height: isTablet ? 8 : 6),

                      // Gems info section (compact)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${pack.gems} Gems',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.95),
                              fontSize: gemSize,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                          if (pack.hasBonus) ...[
                            SizedBox(height: isTablet ? 3 : 2),
                            Text(
                              '+${pack.bonusGems} BONUS',
                              style: TextStyle(
                                color: const Color(0xFFFFD700),
                                fontSize: bonusSize,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ],
                      ),

                      // Spacer to push price to bottom (restored)
                      const Spacer(),

                      // Price button section (responsive height and styling)
                      Container(
                        width: double.infinity,
                        height: isLargeTablet ? 48 : isTablet ? 42 : 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: isTablet ? 1.5 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '\$${pack.usdPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: priceSize,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
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

  Widget _buildPopularBadge(bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 14 : 10,
        vertical: isTablet ? 6 : 4,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
        ),
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.4),
            blurRadius: isTablet ? 10 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '🔥 POPULAR',
        style: TextStyle(
          color: Colors.white,
          fontSize: isTablet ? 14 : 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildBestValueBadge(bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 14 : 10,
        vertical: isTablet ? 6 : 4,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
        ),
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
            blurRadius: isTablet ? 10 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '💎 BEST VALUE',
        style: TextStyle(
          color: Colors.white,
          fontSize: isTablet ? 14 : 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
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

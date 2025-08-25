/// 🛒 Gems Store Component - IAP gem packs with responsive design
import 'package:flutter/material.dart';
import '../../../game/core/economy_config.dart';
import '../gem_3d_icon.dart';

class GemsStore extends StatelessWidget {
  final Function(GemPack) onPurchaseGemPack;

  const GemsStore({
    super.key,
    required this.onPurchaseGemPack,
  });

  @override
  Widget build(BuildContext context) {
    final gemPacks = EconomyConfig.gemPacks.values.toList();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate exact dimensions to fill the entire available space
        final totalHeight = constraints.maxHeight;
        final totalWidth = constraints.maxWidth;
        
        // Account for padding and spacing - optimized for single page
        final horizontalPadding = 16.0; // 8px on each side (reduced)
        final verticalPadding = 16.0; // 8px on top and bottom (reduced)
        final spacing = 8.0; // Reduced spacing
        
        // Calculate item dimensions to fill the screen
        final availableWidth = totalWidth - horizontalPadding - spacing;
        final availableHeight = totalHeight - verticalPadding - spacing;
        
        final itemWidth = availableWidth / 2;
        final itemHeight = availableHeight / 2;
        final aspectRatio = itemWidth / itemHeight;
        
        return Padding(
          padding: const EdgeInsets.all(8), // Reduced padding for more space
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: aspectRatio.clamp(0.8, 1.1), // Tighter aspect ratio for better fit
              crossAxisSpacing: 8, // Reduced spacing
              mainAxisSpacing: 8, // Reduced spacing
            ),
            itemCount: gemPacks.length,
            itemBuilder: (context, index) {
              final pack = gemPacks[index];
              final isPopular = index == 1; // Medium pack is most popular
              final isBestValue = index == 2; // Large pack is best value
              
              return GemPackCard(
                pack: pack,
                isPopular: isPopular,
                isBestValue: isBestValue,
                onTap: () => onPurchaseGemPack(pack),
              );
            },
          ),
        );
      },
    );
  }
}

class GemPackCard extends StatelessWidget {
  final GemPack pack;
  final bool isPopular;
  final bool isBestValue;
  final VoidCallback onTap;

  const GemPackCard({
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
          border: isPopular ? Border.all(
            color: const Color(0xFFFFD700),
            width: 2,
          ) : null,
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top section with badges
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Badge - More compact
                          if (isPopular) _buildPopularBadge()
                          else if (isBestValue) _buildBestValueBadge()
                          else SizedBox(height: (cardHeight * 0.03).clamp(6.0, 12.0)), // Reduced height
                          
                          SizedBox(height: (cardHeight * 0.03).clamp(4.0, 8.0)),
                          
                          // Gem icon - Now using beautiful asset
                          Gem3DIcon(
                            size: iconSize,
                            // No color parameters needed - using asset image
                          ),
                        ],
                      ),
                      
                      // Middle section
                      Flexible(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
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
                            SizedBox(height: (cardHeight * 0.02).clamp(2.0, 6.0)),
                            Text(
                              '${pack.gems} Gems',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: gemSize,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (pack.hasBonus) ...[
                              SizedBox(height: (cardHeight * 0.01).clamp(1.0, 4.0)),
                              Text(
                                '+${pack.bonusGems} BONUS',
                                style: TextStyle(
                                  color: const Color(0xFFFFD700),
                                  fontSize: (gemSize * 0.9).clamp(10.0, 12.0),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      // Bottom section - Price button
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          vertical: (cardHeight * 0.04).clamp(6.0, 12.0),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '\$${pack.usdPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: priceSize,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), // More compact
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), // More compact
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

/// 🛒 Gems Store Component - IAP gem packs with responsive design
library;

import 'package:flutter/material.dart';
import '../../../game/core/economy_config.dart';
import '../gem_3d_icon.dart';
import '../../utils/responsive_config.dart';

class GemsStore extends StatelessWidget {
  final Function(GemPack) onPurchaseGemPack;

  const GemsStore({super.key, required this.onPurchaseGemPack});

  @override
  Widget build(BuildContext context) {
    final gemPacks = EconomyConfig.gemPacks.values.toList();
    final screenSize = MediaQuery.of(context).size;

    return Padding(
      padding: ResponsiveConfig.responsiveEdgeInsetsSymmetric(
        horizontal: 16.0,
        vertical: 12.0,
        screenSize: screenSize,
      ),
      // Use LayoutBuilder to calculate available space and make grid truly responsive
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate available width for grid (accounting for padding and spacing)
          final horizontalPadding = ResponsiveConfig.responsivePadding(16.0, screenSize) * 2;
          final crossAxisSpacing = ResponsiveConfig.responsivePadding(12.0, screenSize);
          final availableWidth = constraints.maxWidth - horizontalPadding;
          
          // Calculate card width (2 columns with spacing)
          final cardWidth = (availableWidth - crossAxisSpacing) / 2;
          
          // Estimate card height based on content (badge + icon + title + gems + price + padding)
          // This ensures cards fit without scrolling on most screens
          final estimatedCardHeight = ResponsiveConfig.responsiveSize(180.0, screenSize, minScale: 0.85, maxScale: 1.2);
          
          // Calculate dynamic aspect ratio based on available space
          // Ensure cards are tall enough to fit content but not too tall
          final aspectRatio = cardWidth / estimatedCardHeight.clamp(160.0, 220.0);
          
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(), // Parent SingleChildScrollView handles scrolling
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: aspectRatio,
              crossAxisSpacing: crossAxisSpacing,
              mainAxisSpacing: ResponsiveConfig.responsivePadding(12.0, screenSize),
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
              padding: ResponsiveConfig.responsiveEdgeInsets(8.0, MediaQuery.of(context).size),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = constraints.maxWidth;
                  final layoutScreenSize = MediaQuery.of(context).size;
                  
                  // Responsive sizing using ResponsiveConfig
                  final iconSize = ResponsiveConfig.responsiveSize(
                    cardWidth * 0.3,
                    layoutScreenSize,
                    minScale: 0.9,
                    maxScale: 1.2,
                  ).clamp(35.0, 70.0);
                          
                  final titleSize = ResponsiveConfig.responsiveFontSize(
                    cardWidth * 0.07,
                    layoutScreenSize,
                    context,
                  ).clamp(12.0, 24.0);
                          
                  final gemSize = ResponsiveConfig.responsiveFontSize(
                    cardWidth * 0.06,
                    layoutScreenSize,
                    context,
                  ).clamp(11.0, 20.0);
                          
                  final bonusSize = gemSize * 0.8;
                  
                  final priceSize = ResponsiveConfig.responsiveFontSize(
                    cardWidth * 0.07,
                    layoutScreenSize,
                    context,
                  ).clamp(14.0, 26.0);

                  return Column(
                    children: [
                      // Top section - Badge (responsive height)
                      SizedBox(
                        height: ResponsiveConfig.responsiveSize(22.0, layoutScreenSize, minScale: 0.9, maxScale: 1.4).clamp(22.0, 32.0),
                        child: Center(
                          child: isPopular
                              ? _buildPopularBadge(layoutScreenSize)
                              : isBestValue
                              ? _buildBestValueBadge(layoutScreenSize)
                              : const SizedBox.shrink(),
                        ),
                      ),

                      // Icon section (responsive height)
                      SizedBox(
                        height: ResponsiveConfig.responsiveSize(45.0, layoutScreenSize, minScale: 0.9, maxScale: 1.5).clamp(45.0, 70.0),
                        child: Center(child: Gem3DIcon(size: iconSize)),
                      ),

                      SizedBox(height: ResponsiveConfig.responsivePadding(3.0, layoutScreenSize)),

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

                      SizedBox(height: ResponsiveConfig.responsivePadding(6.0, layoutScreenSize)),

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
                            SizedBox(height: ResponsiveConfig.responsivePadding(2.0, layoutScreenSize)),
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
                        height: ResponsiveConfig.responsiveButtonHeight(36.0, layoutScreenSize).clamp(36.0, 48.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(ResponsiveConfig.responsivePadding(12.0, layoutScreenSize)),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: ResponsiveConfig.responsivePadding(1.0, layoutScreenSize).clamp(1.0, 1.5),
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

  Widget _buildPopularBadge(Size screenSize) {
    return Builder(
      builder: (context) {
        final horizontalPadding = ResponsiveConfig.responsivePadding(10.0, screenSize);
        final verticalPadding = ResponsiveConfig.responsivePadding(4.0, screenSize);
        final fontSize = ResponsiveConfig.responsiveFontSize(12.0, screenSize, context);
        final borderRadius = ResponsiveConfig.responsivePadding(12.0, screenSize);
        
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                blurRadius: ResponsiveConfig.responsivePadding(8.0, screenSize),
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            '🔥 POPULAR',
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBestValueBadge(Size screenSize) {
    return Builder(
      builder: (context) {
        final horizontalPadding = ResponsiveConfig.responsivePadding(10.0, screenSize);
        final verticalPadding = ResponsiveConfig.responsivePadding(4.0, screenSize);
        final fontSize = ResponsiveConfig.responsiveFontSize(12.0, screenSize, context);
        final borderRadius = ResponsiveConfig.responsivePadding(12.0, screenSize);
        
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
                blurRadius: ResponsiveConfig.responsivePadding(8.0, screenSize),
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            '💎 BEST VALUE',
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        );
      },
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

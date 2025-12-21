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
                  final titleSize = ResponsiveConfig.responsiveFontSize(
                    cardWidth * 0.06, // Smaller name text
                    layoutScreenSize,
                    context,
                  ).clamp(12.0, 16.0);
                          
                  // Based on mobile gaming best practices: Amount should be prominent but balanced
                  // Reduced size as per user feedback - still visible but not overwhelming
                  final gemSize = ResponsiveConfig.responsiveFontSize(
                    cardWidth * 0.28, // Reduced from 0.36 - smaller but still prominent
                    layoutScreenSize,
                    context,
                  ).clamp(28.0, 48.0); // Reduced range from 38-64px to 28-48px
                          
                  // Bonus text should be 20-30px for clear readability - well-balanced with amount
                  final bonusSize = ResponsiveConfig.responsiveFontSize(
                    cardWidth * 0.16, // Well-proportioned bonus text
                    layoutScreenSize,
                    context,
                  ).clamp(20.0, 30.0); // Balanced range for bonus visibility
                  
                  final priceSize = ResponsiveConfig.responsiveFontSize(
                    cardWidth * 0.07, // Smaller price text
                    layoutScreenSize,
                    context,
                  ).clamp(14.0, 22.0);

                  return FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: constraints.maxHeight,
                        maxWidth: constraints.maxWidth,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Top section - Badge (responsive height) - Properly centered and scaled
                          SizedBox(
                            height: ResponsiveConfig.responsiveSize(24.0, layoutScreenSize, minScale: 0.8, maxScale: 1.2).clamp(22.0, 32.0),
                            child: Center(
                              child: isPopular
                                  ? _buildPopularBadge(layoutScreenSize, context)
                                  : isBestValue
                                  ? _buildBestValueBadge(layoutScreenSize, context)
                                  : const SizedBox.shrink(),
                            ),
                          ),

                          SizedBox(height: ResponsiveConfig.responsivePadding(4.0, layoutScreenSize)),

                          // Title section (responsive) - No icon, just title
                          Text(
                            pack.displayName,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: titleSize,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          SizedBox(height: ResponsiveConfig.responsivePadding(4.0, layoutScreenSize)),

                          // Gems info section - DOMINANT - Takes most of the card space for maximum visibility
                          Expanded(
                            flex: 4, // Increased from 2 to 4 to give MUCH more space to amount
                            child: LayoutBuilder(
                              builder: (context, innerConstraints) {
                                return FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Amount with icon - DOMINANT - Takes center stage
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          // Amount text - Prominent and balanced
                                          Text(
                                            '${pack.gems}',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: gemSize,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1.2, // Slightly reduced for better readability
                                              height: 1.0,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black.withValues(alpha: 0.6),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 3),
                                                ),
                                                Shadow(
                                                  color: Colors.black.withValues(alpha: 0.3),
                                                  blurRadius: 12,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          SizedBox(width: ResponsiveConfig.responsivePadding(8.0, layoutScreenSize)),
                                          // Icon next to amount - properly sized for visual balance
                                          Image.asset(
                                            'assets/images/bonuses/gem_bonus.png',
                                            width: gemSize * 0.55, // Slightly larger for better visual balance
                                            height: gemSize * 0.55,
                                            errorBuilder: (_, __, ___) => Gem3DIcon(size: gemSize * 0.55),
                                          ),
                                        ],
                                      ),
                                      if (pack.hasBonus) ...[
                                        SizedBox(height: ResponsiveConfig.responsivePadding(6.0, layoutScreenSize)), // More space before bonus
                                        // Bonus - Integrated with amount, very prominent
                                        Container(
                                          padding: ResponsiveConfig.responsiveEdgeInsetsSymmetric(
                                            horizontal: 12.0, // Increased padding
                                            vertical: 8.0, // Increased vertical padding
                                            screenSize: layoutScreenSize,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                const Color(0xFFFFD700).withValues(alpha: 0.5), // More visible
                                                const Color(0xFFFFA000).withValues(alpha: 0.4),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(ResponsiveConfig.responsivePadding(10.0, layoutScreenSize)),
                                            border: Border.all(
                                              color: const Color(0xFFFFD700),
                                              width: 2.5, // Thicker border
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFFFFD700).withValues(alpha: 0.6),
                                                blurRadius: 12,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                '+${pack.bonusGems}',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: bonusSize,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 1.0, // Balanced letter spacing
                                                  shadows: [
                                                    Shadow(
                                                      color: Colors.black.withValues(alpha: 0.8),
                                                      blurRadius: 4,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(width: ResponsiveConfig.responsivePadding(4.0, layoutScreenSize)),
                                              Text(
                                                'BONUS',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: bonusSize * 0.75, // Slightly smaller than bonus amount
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 1.0, // Balanced letter spacing
                                                  shadows: [
                                                    Shadow(
                                                      color: Colors.black.withValues(alpha: 0.8),
                                                      blurRadius: 4,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),

                          // Spacer to push price to bottom
                          const Spacer(flex: 1),

                      // Price button section (responsive height and styling)
                      Container(
                        width: double.infinity,
                        height: ResponsiveConfig.responsiveButtonHeight(32.0, layoutScreenSize).clamp(32.0, 42.0), // Slightly reduced
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(ResponsiveConfig.responsivePadding(10.0, layoutScreenSize)),
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
                      ),
                    ),
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
    // High-contrast color scheme: Dark, rich colors that pop against light blue background
    // Mobile gaming best practice: Cards must stand out clearly from background
    if (pack.id.contains('small')) {
      // Small: Rich purple-pink (vibrant, engaging)
      return [const Color(0xFF8E24AA), const Color(0xFFE91E63)];
    } else if (pack.id.contains('medium')) {
      // Medium: Deep purple-blue (balanced, premium)
      return [const Color(0xFF6A1B9A), const Color(0xFF3F51B5)];
    } else if (pack.id.contains('large')) {
      // Large: Dark purple-indigo (premium feel, high contrast)
      return [const Color(0xFF4A148C), const Color(0xFF1A237E)];
    } else if (pack.id.contains('mega')) {
      // Mega: Deep indigo-navy (most premium, maximum contrast)
      return [const Color(0xFF1A237E), const Color(0xFF0D47A1)];
    }
    // Default: Deep purple-blue
    return [const Color(0xFF6A1B9A), const Color(0xFF3F51B5)];
  }

  // Removed _getGemIconColor() - no longer needed with asset image

  Widget _buildPopularBadge(Size screenSize, BuildContext context) {
    final horizontalPadding = ResponsiveConfig.responsivePadding(8.0, screenSize).clamp(6.0, 12.0);
    final verticalPadding = ResponsiveConfig.responsivePadding(3.0, screenSize).clamp(2.0, 5.0);
    final fontSize = ResponsiveConfig.responsiveFontSize(10.0, screenSize, context).clamp(9.0, 14.0);
    final borderRadius = ResponsiveConfig.responsivePadding(10.0, screenSize).clamp(8.0, 14.0);
    
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
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
              blurRadius: ResponsiveConfig.responsivePadding(6.0, screenSize).clamp(4.0, 10.0),
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
      ),
    );
  }

  Widget _buildBestValueBadge(Size screenSize, BuildContext context) {
    final horizontalPadding = ResponsiveConfig.responsivePadding(8.0, screenSize).clamp(6.0, 12.0);
    final verticalPadding = ResponsiveConfig.responsivePadding(3.0, screenSize).clamp(2.0, 5.0);
    final fontSize = ResponsiveConfig.responsiveFontSize(10.0, screenSize, context).clamp(9.0, 14.0);
    final borderRadius = ResponsiveConfig.responsivePadding(10.0, screenSize).clamp(8.0, 14.0);
    
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
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
              blurRadius: ResponsiveConfig.responsivePadding(6.0, screenSize).clamp(4.0, 10.0),
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

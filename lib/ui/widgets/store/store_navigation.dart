/// 🛒 Store Navigation Component - Category tabs with modern gaming design
library;

import 'package:flutter/material.dart';
import '../../utils/responsive_config.dart';
import '../gem_3d_icon.dart';
import '../coin_3d_icon.dart';

class StoreNavigation extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final Function(String) onCategorySelected;

  const StoreNavigation({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    
    // Responsive sizing using ResponsiveConfig
    final containerMargin = ResponsiveConfig.responsivePadding(12.0, screenSize);
    final containerPadding = ResponsiveConfig.responsivePadding(4.0, screenSize);
    final borderRadius = ResponsiveConfig.responsiveSize(35.0, screenSize);
    final verticalPadding = ResponsiveConfig.responsivePadding(12.0, screenSize);
    final horizontalPadding = ResponsiveConfig.responsivePadding(8.0, screenSize);
    final iconSpacing = ResponsiveConfig.responsivePadding(2.0, screenSize);
    
    // Calculate available width per tab to prevent text wrapping
    final availableWidth = screenSize.width - (containerMargin * 2) - (containerPadding * 2);
    final tabWidth = availableWidth / categories.length;
    // Use responsive font size with min/max constraints
    final baseTextSize = tabWidth > 80 ? 11.0 : tabWidth > 60 ? 10.0 : 8.0;
    final textSize = ResponsiveConfig.responsiveFontSize(
      baseTextSize,
      screenSize,
      context,
      minScale: 0.8,
      maxScale: 1.3,
    );
    
    return Container(
      margin: EdgeInsets.fromLTRB(
        containerMargin,
        ResponsiveConfig.responsivePadding(8.0, screenSize),
        containerMargin,
        0,
      ),
      padding: EdgeInsets.all(containerPadding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFF3949AB).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: categories.map((category) {
          final isSelected = selectedCategory == category;
          final categoryIcon = _getCategoryIcon(category);
          
          // Responsive icon sizing
          final baseIconSize = isSelected ? 20.0 : 16.0;
          final iconSize = ResponsiveConfig.responsiveIconSize(baseIconSize, screenSize);
          
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: GestureDetector(
                onTap: () => onCategorySelected(category),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: verticalPadding,
                    horizontal: horizontalPadding,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          )
                        : null,
                    borderRadius: BorderRadius.circular(ResponsiveConfig.responsiveSize(30.0, screenSize)),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Use icon widgets for Gems and Coins, emoji for others
                      Center(
                        child: category == 'Gems'
                            ? Gem3DIcon(size: iconSize)
                            : category == 'Coins'
                                ? Coin3DIcon(size: iconSize)
                                : Text(
                                    categoryIcon,
                                    style: TextStyle(
                                      fontSize: iconSize,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                      ),
                      SizedBox(height: iconSpacing),
                      Text(
                        category == 'Heart Booster'
                            ? 'BOOST'
                            : category.toUpperCase(),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: textSize,
                          letterSpacing: 0.5,
                          height: 1.2, // Ensure consistent line height
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getCategoryIcon(String category) {
    switch (category) {
      case 'Jets':
        return '🛩️';
      case 'Gems':
        return '💎';
      case 'Coins':
        return '🪙';
      case 'Hearts':
        return '❤️';
      case 'Heart Booster':
        return '⚡';
      default:
        return '🎮';
    }
  }
}

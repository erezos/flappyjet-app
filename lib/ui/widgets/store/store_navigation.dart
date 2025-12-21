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
    
    // Responsive sizing using ResponsiveConfig - Reduced padding to give more space to content
    final containerMargin = ResponsiveConfig.responsivePadding(12.0, screenSize);
    final containerPadding = ResponsiveConfig.responsivePadding(2.0, screenSize); // Reduced from 4.0
    final borderRadius = ResponsiveConfig.responsiveSize(35.0, screenSize);
    final verticalPadding = ResponsiveConfig.responsivePadding(8.0, screenSize); // Reduced from 12.0
    final horizontalPadding = ResponsiveConfig.responsivePadding(4.0, screenSize); // Reduced from 8.0
    final iconSpacing = ResponsiveConfig.responsivePadding(4.0, screenSize); // Increased from 2.0 for better spacing
    
    // Calculate available width per tab to prevent text wrapping
    final availableWidth = screenSize.width - (containerMargin * 2) - (containerPadding * 2);
    final tabWidth = availableWidth / categories.length;
    // Use responsive font size with min/max constraints - Much bigger text
    final baseTextSize = tabWidth > 80 ? 16.0 : tabWidth > 60 ? 14.0 : 12.0; // Increased from 11/10/8
    final textSize = ResponsiveConfig.responsiveFontSize(
      baseTextSize,
      screenSize,
      context,
      minScale: 0.9,
      maxScale: 1.5, // Increased max scale
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
          
          // Responsive icon sizing - Much bigger icons
          final baseIconSize = isSelected ? 40.0 : 32.0; // Doubled from 20/16
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
                      // Use icon widgets for Currency, images for Special and Jets, emoji fallback
                      Center(
                        child: category == 'Currency'
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Gem3DIcon(size: iconSize * 0.8), // Increased from 0.7
                                  SizedBox(width: iconSpacing * 0.5),
                                  Coin3DIcon(size: iconSize * 0.8), // Increased from 0.7
                                ],
                              )
                            : category == 'Special'
                                ? Image.asset(
                                    'assets/images/ui/no_ads_icon.png',
                                    width: iconSize,
                                    height: iconSize,
                                    errorBuilder: (_, __, ___) => Text(
                                      categoryIcon,
                                      style: TextStyle(
                                        fontSize: iconSize,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                : category == 'Jets'
                                    ? Image.asset(
                                        'assets/images/jets/Crimson_viper.png',
                                        width: iconSize,
                                        height: iconSize,
                                        errorBuilder: (_, __, ___) => Text(
                                          categoryIcon,
                                          style: TextStyle(
                                            fontSize: iconSize,
                                            color: Colors.white,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      )
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
                        category.toUpperCase(),
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
      case 'Currency':
        return '💰';
      case 'Special':
        return '⭐';
      case 'Jets':
        return '🛩️';
      default:
        return '🎮';
    }
  }
}

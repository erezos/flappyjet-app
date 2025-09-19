/// 🛒 Store Navigation Component - Category tabs with modern gaming design
library;

import 'package:flutter/material.dart';
import '../gem_3d_icon.dart';

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
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLargeTablet = screenWidth > 900;
    
    // Responsive sizing
    final containerMargin = isLargeTablet ? 24.0 : isTablet ? 18.0 : 12.0;
    final containerPadding = isLargeTablet ? 6.0 : isTablet ? 5.0 : 4.0;
    final borderRadius = isLargeTablet ? 42.0 : isTablet ? 38.0 : 35.0;
    final verticalPadding = isLargeTablet ? 16.0 : isTablet ? 14.0 : 12.0;
    final horizontalPadding = isLargeTablet ? 12.0 : isTablet ? 10.0 : 8.0;
    final iconSpacing = isLargeTablet ? 4.0 : isTablet ? 3.0 : 2.0;
    
    return Container(
      margin: EdgeInsets.fromLTRB(containerMargin, 8, containerMargin, 0),
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
            blurRadius: isTablet ? 18 : 15,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFF3949AB).withValues(alpha: 0.3),
            blurRadius: isTablet ? 24 : 20,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: categories.map((category) {
          final isSelected = selectedCategory == category;
          final categoryIcon = _getCategoryIcon(category);
          
          // Responsive icon and text sizing
          final iconSize = isSelected 
              ? (isLargeTablet ? 28.0 : isTablet ? 24.0 : 20.0)
              : (isLargeTablet ? 22.0 : isTablet ? 20.0 : 16.0);
          final textSize = isLargeTablet ? 16.0 : isTablet ? 14.0 : 13.0;
          
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
                    borderRadius: BorderRadius.circular(isTablet ? 34 : 30),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                              blurRadius: isTablet ? 15 : 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Use gem icon widget for Gems category, emoji for others
                      category == 'Gems'
                          ? Gem3DIcon(
                              size: iconSize,
                              // Beautiful asset gem icon
                            )
                          : Text(
                              categoryIcon,
                              style: TextStyle(
                                fontSize: iconSize,
                                color: Colors.white,
                              ),
                            ),
                      SizedBox(height: iconSpacing),
                      Text(
                        category == 'Heart Booster'
                            ? 'BOOST'
                            : category.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: textSize,
                          letterSpacing: isTablet ? 0.8 : 0.5,
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

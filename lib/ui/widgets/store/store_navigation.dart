/// 🛒 Store Navigation Component - Category tabs with modern gaming design
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
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1A237E),
            Color(0xFF3949AB),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(35),
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
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: GestureDetector(
                onTap: () => onCategorySelected(category),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    gradient: isSelected ? const LinearGradient(
                      colors: [
                        Color(0xFFFFD700),
                        Color(0xFFFFA000),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ) : null,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ] : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Use gem icon widget for Gems category, emoji for others
                      category == 'Gems' 
                        ? Gem3DIcon(
                            size: isSelected ? 20 : 16,
                            // Beautiful asset gem icon
                          )
                        : Text(
                            categoryIcon,
                            style: TextStyle(
                              fontSize: isSelected ? 20 : 16,
                              color: Colors.white,
                            ),
                          ),
                      const SizedBox(height: 2),
                      Text(
                        category == 'Heart Booster' ? 'BOOST' : category.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1,
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
      case 'Hearts':
        return '❤️';
      case 'Heart Booster':
        return '⚡';
      default:
        return '🎮';
    }
  }
}

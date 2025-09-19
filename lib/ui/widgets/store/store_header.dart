/// 🛒 Store Header Component - Reusable header with title and currency display
library;

import 'package:flutter/material.dart';
import '../../../game/systems/inventory_manager.dart';
import '../gem_3d_icon.dart';

class StoreHeader extends StatelessWidget {
  final VoidCallback onBackPressed;
  final InventoryManager inventory;

  const StoreHeader({
    super.key,
    required this.onBackPressed,
    required this.inventory,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLargeTablet = screenWidth > 900;
    
    // Responsive sizing
    final padding = isLargeTablet ? 24.0 : isTablet ? 20.0 : 16.0;
    final backButtonSize = isLargeTablet ? 32.0 : isTablet ? 28.0 : 24.0;
    final titleFontSize = isLargeTablet ? 90.0 : isTablet ? 80.0 : 72.0;
    
    return Padding(
      padding: EdgeInsets.all(padding),
      child: Row(
        children: [
          // Back button with circular background - responsive
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white, size: backButtonSize),
              onPressed: onBackPressed,
            ),
          ),

          const Spacer(),

          // STORE title - Responsive and prominent
          Expanded(
            flex: 12,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Image.asset(
                'assets/images/text/store_text.png',
                width: double.infinity,
                fit: BoxFit.fitWidth,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Text(
                      'STORE',
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w900,
                        color: Colors.yellow[700],
                        shadows: [
                          Shadow(
                            offset: const Offset(2, 2),
                            blurRadius: 4,
                            color: Colors.black.withValues(alpha: 0.5),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const Spacer(),

          // Currency display - responsive
          _buildCurrencyDisplay(isTablet, isLargeTablet),
        ],
      ),
    );
  }

  Widget _buildCurrencyDisplay(bool isTablet, bool isLargeTablet) {
    // Responsive sizing
    final maxWidth = isLargeTablet ? 140.0 : isTablet ? 120.0 : 100.0;
    final horizontalPadding = isLargeTablet ? 8.0 : isTablet ? 6.0 : 4.0;
    final verticalPadding = isLargeTablet ? 4.0 : isTablet ? 3.0 : 2.0;
    final borderRadius = isLargeTablet ? 20.0 : isTablet ? 18.0 : 15.0;
    final coinIconPadding = isLargeTablet ? 4.0 : isTablet ? 3.0 : 2.0;
    final coinIconFontSize = isLargeTablet ? 14.0 : isTablet ? 12.0 : 10.0;
    final textFontSize = isLargeTablet ? 18.0 : isTablet ? 16.0 : 14.0;
    final iconSize = isLargeTablet ? 22.0 : isTablet ? 20.0 : 16.0;
    final spacing = isLargeTablet ? 6.0 : isTablet ? 5.0 : 4.0;
    final gemSpacing = isLargeTablet ? 8.0 : isTablet ? 7.0 : 6.0;
    
    return IntrinsicWidth(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
        decoration: BoxDecoration(
          color: const Color(0xFF1565C0),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Coins
              Container(
                padding: EdgeInsets.all(coinIconPadding),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFC107),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '\$',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: coinIconFontSize,
                  ),
                ),
              ),
              SizedBox(width: spacing),
              AnimatedBuilder(
                animation: inventory,
                builder: (context, _) => Text(
                  '${inventory.softCurrency}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: textFontSize,
                  ),
                ),
              ),

              SizedBox(width: gemSpacing),

              // Gems - Beautiful asset icon
              Gem3DIcon(
                size: iconSize,
                // Using asset image - no color parameters needed
              ),
              SizedBox(width: spacing),
              AnimatedBuilder(
                animation: inventory,
                builder: (context, _) => Text(
                  '${inventory.gems}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: textFontSize,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

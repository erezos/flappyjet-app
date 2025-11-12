/// 🛒 Store Header Component - Reusable header with title and currency display
library;

import 'package:flutter/material.dart';
import '../../../game/systems/inventory_manager.dart';
import '../status_bar/coins_gems_display.dart';
import '../status_bar/hearts_display.dart';

class StoreHeader extends StatelessWidget {
  final VoidCallback? onBackPressed; // Made optional
  final InventoryManager inventory;

  const StoreHeader({
    super.key,
    this.onBackPressed, // Now optional
    required this.inventory,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLargeTablet = screenWidth > 900;
    
    // Responsive sizing
    final padding = isLargeTablet ? 16.0 : isTablet ? 14.0 : 12.0;
    
    return Padding(
      padding: EdgeInsets.all(padding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ✅ LEFT: Coins & Gems display
          CoinsGemsDisplay(),

          // ✅ RIGHT: Hearts display
          HeartsDisplay(),
        ],
      ),
    );
  }
}

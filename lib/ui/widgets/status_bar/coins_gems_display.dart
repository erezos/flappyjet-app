/// 💰 COINS + GEMS DISPLAY - Reusable status bar component
/// Shows coins and gems in one chip with divider
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../game/systems/inventory_manager.dart';
import '../gem_3d_icon.dart';
import '../coin_3d_icon.dart';

/// Reusable widget that displays coins and gems in a single chip
/// 
/// Features:
/// - Auto-wires to InventoryManager singleton
/// - Number formatting (e.g., "23,236")
/// - ValueListenableBuilder for live updates
/// - Responsive sizing based on screen size
/// - Optional tap callback
/// 
/// Usage:
/// ```dart
/// CoinsGemsDisplay(
///   onTap: () => Navigator.push(...), // Optional
/// )
/// ```
class CoinsGemsDisplay extends StatelessWidget {
  final VoidCallback? onTap;
  /// Optional GlobalKey for coin icon (for animation position tracking)
  final GlobalKey? coinIconKey;
  /// Optional GlobalKey for gem icon (for animation position tracking)
  final GlobalKey? gemIconKey;
  final NumberFormat _numFmt = NumberFormat.decimalPattern();
  final InventoryManager _inventory = InventoryManager();

  CoinsGemsDisplay({
    super.key,
    this.onTap,
    this.coinIconKey,
    this.gemIconKey,
  });

  @override
  Widget build(BuildContext context) {
    // Auto-detect screen size for responsive sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLargeTablet = screenWidth > 900;
    
    // 🎯 BIGGER SIZES: Increased all dimensions for better visibility
    final iconSize = isLargeTablet ? 28.0 : isTablet ? 26.0 : 22.0; // ✅ Increased from 22/20/16
    final fontSize = isLargeTablet ? 22.0 : isTablet ? 20.0 : 17.0; // ✅ Increased from 18/16/13
    final padding = isLargeTablet ? 18.0 : isTablet ? 16.0 : 14.0; // ✅ Increased from 16/14/10
    final verticalPadding = isLargeTablet ? 12.0 : isTablet ? 10.0 : 8.0; // ✅ Increased from 10/8/6
    final borderRadius = isLargeTablet ? 26.0 : isTablet ? 24.0 : 20.0; // ✅ Increased from 24/22/18
    final spacing = isLargeTablet ? 12.0 : isTablet ? 10.0 : 8.0; // ✅ Increased from 10/8/6
    final dividerSpacing = isLargeTablet ? 18.0 : isTablet ? 16.0 : 14.0; // ✅ Increased from 16/14/12
    final dividerHeight = isLargeTablet ? 24.0 : isTablet ? 22.0 : 18.0; // ✅ Increased from 20/18/16
    
    final content = Container(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: verticalPadding),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: IntrinsicWidth(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Coins - using consistent coin asset with optional key
            coinIconKey != null
                ? Container(
                    key: coinIconKey,
                    child: Coin3DIcon(size: iconSize),
                  )
                : Coin3DIcon(size: iconSize),
            SizedBox(width: spacing),
            Flexible(
              child: ValueListenableBuilder<int>(
                valueListenable: _inventory.softCurrencyNotifier,
                builder: (context, _, __) {
                  return FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _numFmt.format(_inventory.softCurrency),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: fontSize,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                    ),
                  );
                },
              ),
            ),

            // Divider
            SizedBox(width: dividerSpacing),
            Container(
              width: 1,
              height: dividerHeight,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            SizedBox(width: dividerSpacing),

            // Gems with optional key
            gemIconKey != null
                ? Container(
                    key: gemIconKey,
                    child: Gem3DIcon(size: iconSize),
                  )
                : Gem3DIcon(size: iconSize),
            SizedBox(width: spacing),
            Flexible(
              child: ValueListenableBuilder<int>(
                valueListenable: _inventory.gemsNotifier,
                builder: (context, _, __) {
                  return FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _numFmt.format(_inventory.gems),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: fontSize,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    
    // Wrap with GestureDetector if onTap provided
    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }
    
    return content;
  }
}


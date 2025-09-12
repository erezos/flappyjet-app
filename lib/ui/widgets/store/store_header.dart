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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Back button with circular background
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              onPressed: onBackPressed,
            ),
          ),

          const Spacer(),

          // STORE title - Even bigger and more prominent
          Expanded(
            flex: 12, // Increased from 10 to 12 for more space
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 2,
              ), // Reduced padding for more space
              child: Image.asset(
                'assets/images/text/store_text.png',
                width: double.infinity,
                fit: BoxFit.fitWidth,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Text(
                      'STORE',
                      style: TextStyle(
                        fontSize: 72, // Increased from 64 to 72
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

          // Currency display
          _buildCurrencyDisplay(),
        ],
      ),
    );
  }

  Widget _buildCurrencyDisplay() {
    return IntrinsicWidth(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 100),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF1565C0),
          borderRadius: BorderRadius.circular(15),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Coins
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFC107),
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  '\$',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              AnimatedBuilder(
                animation: inventory,
                builder: (context, _) => Text(
                  '${inventory.softCurrency}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // Gems - Beautiful asset icon
              const Gem3DIcon(
                size: 16,
                // Using asset image - no color parameters needed
              ),
              const SizedBox(width: 4),
              AnimatedBuilder(
                animation: inventory,
                builder: (context, _) => Text(
                  '${inventory.gems}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
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

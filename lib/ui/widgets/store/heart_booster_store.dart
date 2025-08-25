/// 🛒 Heart Booster Store Component - Premium heart booster with timer
import 'package:flutter/material.dart';
import '../../../game/core/economy_config.dart';
import '../../../game/systems/inventory_manager.dart';
import '../gem_3d_icon.dart';

class HeartBoosterStore extends StatelessWidget {
  final InventoryManager inventory;
  final VoidCallback onPurchaseWithGems;
  final VoidCallback onPurchaseWithUSD;

  const HeartBoosterStore({
    super.key,
    required this.inventory,
    required this.onPurchaseWithGems,
    required this.onPurchaseWithUSD,
  });

  @override
  Widget build(BuildContext context) {
    final pack = EconomyConfig.heartBoosterPack;
    
    return AnimatedBuilder(
      animation: inventory,
      builder: (context, _) {
        final isActive = inventory.isHeartBoosterActive;
        
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header
              Text(
                'HEART BOOSTER',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Status indicator
              if (isActive) ...[
                _buildActiveStatus(),
                const SizedBox(height: 16),
              ],
              
              // Heart Booster card
              _buildBoosterCard(pack, isActive),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActiveStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Text(
            'ACTIVE',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoosterCard(HeartBoosterPack pack, bool isActive) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isActive 
              ? [const Color(0xFF4CAF50), const Color(0xFF388E3C)]
              : [const Color(0xFFE91E63), const Color(0xFFAD1457)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isActive ? Colors.green : Colors.pink).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Heart icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.favorite,
                color: Colors.white,
                size: 40,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              pack.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              pack.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Benefits list
            _buildBenefitsList(),
            
            const SizedBox(height: 20),
            
            // Timer display (if active)
            if (isActive) ...[
              _buildTimerDisplay(),
              const SizedBox(height: 20),
            ],
            
            // Purchase buttons
            _buildPurchaseButtons(pack),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitsList() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildBenefitRow('6 Maximum Hearts', '(instead of 3)'),
          const SizedBox(height: 8),
          _buildBenefitRow('Faster Regeneration', '(8 min instead of 10 min)'),
          const SizedBox(height: 8),
          _buildBenefitRow('24 Hour Duration', '(stackable)'),
        ],
      ),
    );
  }

  Widget _buildBenefitRow(String title, String subtitle) {
    return Row(
      children: [
        const Icon(Icons.check, color: Colors.white, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              text: title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              children: [
                TextSpan(
                  text: ' $subtitle',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimerDisplay() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.timer,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          StreamBuilder<int>(
            stream: Stream.periodic(const Duration(seconds: 1), (i) => i),
            builder: (context, snapshot) {
              final timeRemaining = inventory.heartBoosterTimeRemaining;
              if (timeRemaining == null) {
                return const Text(
                  'Expired',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }
              
              final hours = timeRemaining.inHours;
              final minutes = timeRemaining.inMinutes.remainder(60);
              final seconds = timeRemaining.inSeconds.remainder(60);
              
              return Text(
                hours > 0 
                    ? '${hours}h ${minutes}m ${seconds}s remaining'
                    : '${minutes}m ${seconds}s remaining',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseButtons(HeartBoosterPack pack) {
    return Row(
      children: [
        // Gem purchase
        Expanded(
          child: GestureDetector(
            onTap: onPurchaseWithGems,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blue.shade600,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Gem3DIcon(
                    size: 20,
                    // Using beautiful asset image
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${pack.gemPrice}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // USD purchase
        Expanded(
          child: GestureDetector(
            onTap: onPurchaseWithUSD,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '\$${pack.usdPrice.toStringAsFixed(2)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 🛒 Hearts Store Component - Heart refill functionality
import 'package:flutter/material.dart';
import '../../../game/core/economy_config.dart';
import '../../../game/systems/lives_manager.dart';
import '../gem_3d_icon.dart';

class HeartsStore extends StatelessWidget {
  final LivesManager livesManager;
  final EconomyConfig economy;
  final VoidCallback onPurchaseFullHeartsRefill;

  const HeartsStore({
    super.key,
    required this.livesManager,
    required this.economy,
    required this.onPurchaseFullHeartsRefill,
  });

  @override
  Widget build(BuildContext context) {
    final currentHearts = livesManager.currentLives;
    final maxHearts = livesManager.maxLives;
    final isAtMax = currentHearts >= maxHearts;
    
    return Padding(
      padding: const EdgeInsets.all(8), // Reduced from 16 to 8
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Better distribution
        mainAxisSize: MainAxisSize.max, // Use available space
        children: [
          // Header - More compact
          Text(
            'BUY HEARTS',
            style: TextStyle(
              fontSize: 20, // Reduced from 24 to 20
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
          Text(
            'Get an extra heart instantly!',
            style: TextStyle(
              fontSize: 14, // Reduced from 16 to 14
              color: Colors.white.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
          
          // Current Hearts Status
          _buildHeartsStatus(currentHearts, maxHearts),
          
          // Full Hearts Refill Card
          _buildRefillCard(isAtMax),
          
          // Info text - More compact
          Text(
            isAtMax 
                ? 'Your hearts are already at maximum!'
                : 'Instantly refill all hearts for just ${economy.fullHeartsRefillGemCost} gems!',
            style: TextStyle(
              fontSize: 12, // Reduced from 14 to 12
              color: Colors.white.withValues(alpha: 0.7),
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHeartsStatus(int currentHearts, int maxHearts) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12), // Reduced from 16 to 12
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Current Hearts',
            style: TextStyle(
              fontSize: 14, // Reduced from 16 to 14
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 6), // Reduced from 8 to 6
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(maxHearts, (index) {
              final filled = index < currentHearts;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3), // Reduced from 4 to 3
                child: Icon(
                  Icons.favorite,
                  size: 28, // Reduced from 32 to 28
                  color: filled ? Colors.red : Colors.red.withValues(alpha: 0.3),
                ),
              );
            }),
          ),
          const SizedBox(height: 6), // Reduced from 8 to 6
          Text(
            '$currentHearts / $maxHearts Hearts',
            style: const TextStyle(
              fontSize: 16, // Reduced from 18 to 16
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefillCard(bool isAtMax) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isAtMax 
              ? [Colors.grey.shade600, Colors.grey.shade800]
              : [const Color(0xFF4CAF50), const Color(0xFF388E3C)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isAtMax ? null : onPurchaseFullHeartsRefill,
          child: Padding(
            padding: const EdgeInsets.all(16), // Reduced from 20 to 16
            child: Column(
              children: [
                // Hearts Icon - More compact
                Container(
                  width: 60, // Reduced from 80 to 60
                  height: 60, // Reduced from 80 to 60
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.favorite_border,
                    size: 30, // Reduced from 40 to 30
                    color: isAtMax ? Colors.grey.shade400 : Colors.white,
                  ),
                ),
                const SizedBox(height: 12), // Reduced from 16 to 12
                
                // Title
                Text(
                  'Full Hearts Refill',
                  style: TextStyle(
                    fontSize: 18, // Reduced from 20 to 18
                    fontWeight: FontWeight.bold,
                    color: isAtMax ? Colors.grey.shade400 : Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6), // Reduced from 8 to 6
                
                // Description
                Text(
                  isAtMax 
                      ? 'Hearts are already full!'
                      : 'Fill all hearts to maximum instantly',
                  style: TextStyle(
                    fontSize: 14,
                    color: isAtMax 
                        ? Colors.grey.shade500 
                        : Colors.white.withValues(alpha: 0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12), // Reduced from 16 to 12
                
                // Price
                if (!isAtMax) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // Reduced padding
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Gem3DIcon(
                          size: 18, // Reduced from 20 to 18
                          // Using beautiful asset image
                        ),
                        const SizedBox(width: 6), // Reduced from 8 to 6
                        Text(
                          '${economy.fullHeartsRefillGemCost} Gems',
                          style: TextStyle(
                            fontSize: 14, // Reduced from 16 to 14
                            fontWeight: FontWeight.bold,
                            color: Colors.cyan.shade300,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 🏆 Tournament Failed Screen - Mobile-Optimized
/// 
/// Shows when player exhausts all tries.
/// Designed to fit perfectly on mobile screens without scrolling.
library;

import 'package:flutter/material.dart';
import '../../../models/tournament_config.dart';
import '../../../models/tournament_entry.dart';
import '../../../game/systems/inventory_manager.dart';
import '../../../game/systems/tournament_manager.dart';
import '../../utils/responsive_config.dart';
import '../coin_3d_icon.dart';
import '../gem_3d_icon.dart';

class TournamentFailedScreen extends StatelessWidget {
  final TournamentConfig tournament;
  final TournamentEntry entry;
  /// Optional callback for testing - if not provided, screen handles navigation itself
  final VoidCallback? onReturnToHub;
  final VoidCallback? onPurchaseExtraTries;

  const TournamentFailedScreen({
    super.key,
    required this.tournament,
    required this.entry,
    this.onReturnToHub,
    this.onPurchaseExtraTries,
  });

  void _handleReturnToHub(BuildContext context) {
    if (onReturnToHub != null) {
      onReturnToHub!();
    } else {
      TournamentManager().clearActiveEntry();
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final specialDeal = tournament.loseAllTriesOffer;
    final inventory = InventoryManager();

    // Responsive sizing
    final iconSize = ResponsiveConfig.responsiveSize(70, screenSize, minScale: 0.85, maxScale: 1.1);
    final titleSize = ResponsiveConfig.responsiveSize(22, screenSize, minScale: 0.85, maxScale: 1.1);
    final subtitleSize = ResponsiveConfig.responsiveSize(15, screenSize, minScale: 0.9, maxScale: 1.1);
    final bodySize = ResponsiveConfig.responsiveSize(13, screenSize, minScale: 0.9, maxScale: 1.1);
    final padding = ResponsiveConfig.responsiveSize(16, screenSize, minScale: 0.9, maxScale: 1.1);
    final spacing = ResponsiveConfig.responsiveSize(14, screenSize, minScale: 0.9, maxScale: 1.1);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4E1B1B),
              Color(0xFF1A1A2E),
              Color(0xFF0F0F1A),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: padding),
            child: Column(
              children: [
                SizedBox(height: spacing),

                // Failed icon
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withOpacity(0.2),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.sentiment_dissatisfied,
                    color: Colors.red,
                    size: iconSize * 0.5,
                  ),
                ),

                SizedBox(height: spacing),

                // Title
                Text(
                  'TOURNAMENT OVER',
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),

                SizedBox(height: spacing * 0.4),

                Text(
                  tournament.name,
                  style: TextStyle(
                    fontSize: subtitleSize,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: spacing),

                // Progress summary
                _buildProgressSummary(screenSize, bodySize),

                SizedBox(height: spacing),

                // Rewards kept (if any)
                if (entry.coinsEarned > 0 || entry.gemsEarned > 0)
                  _buildRewardsKept(screenSize, bodySize),

                if (entry.coinsEarned > 0 || entry.gemsEarned > 0)
                  SizedBox(height: spacing),

                // Special deal offer (compact, no flex)
                if (specialDeal != null && specialDeal.enabled && onPurchaseExtraTries != null)
                  _buildSpecialDeal(specialDeal, inventory, screenSize, bodySize),

                // Spacer to push button to bottom when no special deal
                if (specialDeal == null || !specialDeal.enabled || onPurchaseExtraTries == null)
                  SizedBox(height: spacing),

                // Return button
                _buildReturnButton(context, screenSize, subtitleSize),

                SizedBox(height: spacing),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSummary(Size screenSize, double fontSize) {
    return Container(
      padding: EdgeInsets.all(ResponsiveConfig.responsiveSize(14, screenSize)),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Text(
            'YOUR PROGRESS',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: fontSize - 2,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: ResponsiveConfig.responsiveSize(12, screenSize)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.flag,
                value: '${entry.highestRoundReached}/${tournament.totalRounds}',
                label: 'Highest',
                fontSize: fontSize,
              ),
              _buildStatItem(
                icon: Icons.favorite,
                value: '${entry.totalTries}',
                label: 'Tries',
                fontSize: fontSize,
              ),
              _buildStatItem(
                icon: Icons.replay,
                value: '${entry.totalContinuesUsed}',
                label: 'Continues',
                fontSize: fontSize,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required double fontSize,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white54, size: fontSize + 4),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: fontSize + 2,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: fontSize - 2,
          ),
        ),
      ],
    );
  }

  Widget _buildRewardsKept(Size screenSize, double fontSize) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveConfig.responsiveSize(14, screenSize),
        vertical: ResponsiveConfig.responsiveSize(10, screenSize),
      ),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.amber.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Coin3DIcon(size: fontSize + 4),
          const SizedBox(width: 6),
          Text(
            'Kept: ${entry.coinsEarned}',
            style: TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.w500,
              fontSize: fontSize,
            ),
          ),
          if (entry.gemsEarned > 0) ...[
            const SizedBox(width: 12),
            Gem3DIcon(size: fontSize + 4),
            const SizedBox(width: 4),
            Text(
              '${entry.gemsEarned}',
              style: TextStyle(
                color: Colors.cyan,
                fontWeight: FontWeight.w500,
                fontSize: fontSize,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSpecialDeal(
    TournamentSpecialDeal deal,
    InventoryManager inventory,
    Size screenSize,
    double fontSize,
  ) {
    final canAfford = inventory.gems >= deal.discountedGemCost;
    final compactPadding = ResponsiveConfig.responsiveSize(10, screenSize);

    return GestureDetector(
      onTap: canAfford ? onPurchaseExtraTries : null,
      child: Container(
        padding: EdgeInsets.all(compactPadding),
        margin: EdgeInsets.only(bottom: compactPadding * 0.5),
        decoration: BoxDecoration(
          gradient: canAfford
              ? LinearGradient(
                  colors: [
                    Colors.purple.withOpacity(0.35),
                    Colors.purple.withOpacity(0.15),
                  ],
                )
              : null,
          color: canAfford ? null : Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: canAfford
                ? Colors.purple.withOpacity(0.5)
                : Colors.grey.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // Left: Deal info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${deal.discountPercent}% OFF',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: fontSize - 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'SECOND CHANCE!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: fontSize,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Get ${deal.extraTries} more tries',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: fontSize - 1,
                    ),
                  ),
                ],
              ),
            ),
            
            // Right: Price button
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${deal.baseGemCost}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: fontSize - 1,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: canAfford ? Colors.purple : Colors.grey,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('💎', style: TextStyle(fontSize: fontSize)),
                      const SizedBox(width: 4),
                      Text(
                        '${deal.discountedGemCost}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: fontSize + 2,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!canAfford) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Not enough',
                    style: TextStyle(
                      color: Colors.red.shade300,
                      fontSize: fontSize - 3,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReturnButton(BuildContext context, Size screenSize, double fontSize) {
    return GestureDetector(
      onTap: () => _handleReturnToHub(context),
      child: Container(
        width: double.infinity,
        height: ResponsiveConfig.responsiveSize(48, screenSize, minScale: 0.9, maxScale: 1.1),
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home, color: Colors.white70, size: fontSize + 4),
            const SizedBox(width: 10),
            Text(
              'RETURN TO HUB',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: fontSize,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

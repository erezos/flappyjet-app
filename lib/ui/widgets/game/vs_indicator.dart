/// 🆚 VS INDICATOR - Reusable game HUD component
/// 
/// Displays player vs opponent indicator during 1v1 battles.
/// Shows jet skins, names, and optional score comparison.
/// 
/// ✅ FLAME ENGINE BEST PRACTICES:
/// - Responsive sizing for all screen sizes
/// - Efficient image loading with error handling
/// - Consistent visual style across all game modes
/// 
/// USAGE:
/// ```dart
/// VSIndicator(
///   playerSkinId: 'sky_rookie',
///   opponentSkinId: 'storm_ace',
///   opponentName: 'Storm Ace',
///   playerScore: 5,
///   opponentScore: 3,
/// )
/// ```
library;

import 'package:flutter/material.dart';
import '../../../game/core/jet_skins.dart';
import '../../../game/systems/inventory_manager.dart';

/// Reusable widget that displays VS indicator during 1v1 battles
/// 
/// Features:
/// - Player and opponent jet skins
/// - Names with color-coded labels
/// - Optional score display
/// - Animated VS badge
/// - Responsive sizing
class VSIndicator extends StatelessWidget {
  /// Player's jet skin ID (defaults to equipped skin)
  final String? playerSkinId;
  
  /// Opponent's jet skin ID
  final String opponentSkinId;
  
  /// Opponent's display name
  final String opponentName;
  
  /// Optional player score (for score-based comparison)
  final int? playerScore;
  
  /// Optional opponent score
  final int? opponentScore;
  
  /// Whether opponent is still active (not crashed)
  final bool opponentIsActive;

  /// Whether to show numeric scores under the jets
  final bool showScores;
  
  /// Size variant
  final VSIndicatorSize size;

  const VSIndicator({
    super.key,
    this.playerSkinId,
    required this.opponentSkinId,
    required this.opponentName,
    this.playerScore,
    this.opponentScore,
    this.opponentIsActive = true,
    this.showScores = true,
    this.size = VSIndicatorSize.normal,
  });

  @override
  Widget build(BuildContext context) {
    final playerSkin = JetSkinCatalog.getSkinById(
      playerSkinId ?? InventoryManager().equippedSkinId,
    ) ?? JetSkinCatalog.starterJet;
    final opponentSkin = JetSkinCatalog.getSkinById(opponentSkinId);
    
    final jetSize = size.jetSize;
    final fontSize = size.fontSize;
    final badgePadding = size.badgePadding;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Player jet
          _buildJetDisplay(
            skin: playerSkin,
            label: 'YOU',
            color: const Color(0xFF00D4FF),
            size: jetSize,
            fontSize: fontSize,
            score: showScores ? playerScore : null,
            isActive: true,
          ),
          
          // VS badge
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: EdgeInsets.symmetric(
              horizontal: badgePadding,
              vertical: badgePadding * 0.5,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF5722), Color(0xFFFF9800)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.5),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Text(
              'VS',
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          
          // Opponent jet
          _buildJetDisplay(
            skin: opponentSkin,
            label: opponentName,
            color: const Color(0xFFFF5722),
            size: jetSize,
            fontSize: fontSize,
            score: showScores ? opponentScore : null,
            isActive: opponentIsActive,
          ),
        ],
      ),
    );
  }

  Widget _buildJetDisplay({
    required JetSkin? skin,
    required String label,
    required Color color,
    required double size,
    required double fontSize,
    int? score,
    required bool isActive,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Jet image with glow
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: isActive 
                        ? color.withValues(alpha: 0.5) 
                        : Colors.grey.withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: skin != null
                  ? Opacity(
                      opacity: isActive ? 1.0 : 0.5,
                      child: Image.asset(
                        'assets/images/${skin.assetPath}',
                        width: size,
                        height: size,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.airplanemode_active,
                          color: isActive ? color : Colors.grey,
                          size: size * 0.6,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.airplanemode_active,
                      color: isActive ? color : Colors.grey,
                      size: size * 0.6,
                    ),
            ),
            // Crashed indicator
            if (!isActive)
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.4),
                ),
                child: Icon(
                  Icons.close,
                  color: Colors.red,
                  size: size * 0.5,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        // Name label
        Text(
          label,
          style: TextStyle(
            color: isActive ? color : Colors.grey,
            fontSize: fontSize * 0.6,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        // Score (if provided)
        if (score != null)
          Text(
            '$score',
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize * 0.8,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Size variants for VSIndicator
enum VSIndicatorSize {
  /// Small size for compact displays
  small,
  /// Normal size for standard HUD
  normal,
  /// Large size for bracket screens
  large;
  
  double get jetSize {
    switch (this) {
      case VSIndicatorSize.small:
        return 32;
      case VSIndicatorSize.normal:
        return 40;
      case VSIndicatorSize.large:
        return 56;
    }
  }
  
  double get fontSize {
    switch (this) {
      case VSIndicatorSize.small:
        return 12;
      case VSIndicatorSize.normal:
        return 14;
      case VSIndicatorSize.large:
        return 18;
    }
  }
  
  double get badgePadding {
    switch (this) {
      case VSIndicatorSize.small:
        return 8;
      case VSIndicatorSize.normal:
        return 12;
      case VSIndicatorSize.large:
        return 16;
    }
  }
}

/// Compact VS badge without jet images (for minimal HUD)
class VSBadgeCompact extends StatelessWidget {
  final int playerScore;
  final int opponentScore;
  final bool opponentIsActive;
  
  const VSBadgeCompact({
    super.key,
    required this.playerScore,
    required this.opponentScore,
    this.opponentIsActive = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF2D1B4E)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Player score
          Text(
            '$playerScore',
            style: const TextStyle(
              color: Color(0xFF00D4FF),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          // VS separator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'vs',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Opponent score (with crash indicator)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$opponentScore',
                style: TextStyle(
                  color: opponentIsActive 
                      ? const Color(0xFFFF5722) 
                      : Colors.grey,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (!opponentIsActive) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.cancel,
                  color: Colors.red,
                  size: 14,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}


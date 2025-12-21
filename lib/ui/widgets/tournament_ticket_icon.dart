/// 🎫 Tournament Ticket Icon Widget
/// 
/// Displays the appropriate ticket image based on tournament tier.
/// Supports silver, gold, and diamond tiers.
library;

import 'package:flutter/material.dart';
import '../../models/tournament_config.dart';

class TournamentTicketIcon extends StatelessWidget {
  final TournamentTier tier;
  final double size;
  final BoxFit fit;

  const TournamentTicketIcon({
    super.key,
    required this.tier,
    this.size = 24,
    this.fit = BoxFit.contain,
  });

  /// Get the asset path for a given tier
  static String getAssetPath(TournamentTier tier) {
    switch (tier) {
      case TournamentTier.bronze:
        // Bronze tournaments are always free, no ticket needed
        // But if requested, use silver as fallback
        return 'assets/images/bonuses/tournament_ticket_silver.png';
      case TournamentTier.silver:
        return 'assets/images/bonuses/tournament_ticket_silver.png';
      case TournamentTier.gold:
        return 'assets/images/bonuses/tournament_ticket_gold.png';
      case TournamentTier.platinum:
      case TournamentTier.special:
        // Platinum and special use diamond ticket
        return 'assets/images/bonuses/tournament_ticket_diamond.png';
    }
  }

  /// Get the glow color for a given tier
  static Color getGlowColor(TournamentTier tier) {
    switch (tier) {
      case TournamentTier.bronze:
      case TournamentTier.silver:
        return const Color(0xFF4FC3F7); // Light blue
      case TournamentTier.gold:
        return const Color(0xFFFFD700); // Gold
      case TournamentTier.platinum:
      case TournamentTier.special:
        return const Color(0xFF00BCD4); // Cyan/Diamond
    }
  }

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      getAssetPath(tier),
      width: size,
      height: size,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to emoji if image fails to load
        return Text(
          '🎫',
          style: TextStyle(fontSize: size * 0.8),
        );
      },
    );
  }
}

/// A ticket icon with glow effect for premium display
class TournamentTicketIconGlow extends StatelessWidget {
  final TournamentTier tier;
  final double size;

  const TournamentTicketIconGlow({
    super.key,
    required this.tier,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: TournamentTicketIcon.getGlowColor(tier).withValues(alpha: 0.4),
            blurRadius: size * 0.3,
            spreadRadius: size * 0.1,
          ),
        ],
      ),
      child: TournamentTicketIcon(
        tier: tier,
        size: size,
      ),
    );
  }
}


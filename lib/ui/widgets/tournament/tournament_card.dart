/// 🏆 Tournament Card Widget - Mobile-Optimized
/// 
/// Displays a single tournament in a horizontal card layout.
/// Shows: Full Name, Tournament Type, Prizes, and Entry Fee.
/// Designed for mobile-first with responsive scaling.
library;

import 'package:flutter/material.dart';
import '../../../models/tournament_config.dart';
import '../../../game/systems/tournament_manager.dart';
import '../../../game/core/jet_skins.dart';
import '../../utils/responsive_config.dart';
import '../coin_3d_icon.dart';
import '../gem_3d_icon.dart';
import '../tournament_ticket_icon.dart';

/// Tournament card for the hub screen - horizontal layout with banner image
class TournamentCard extends StatelessWidget {
  final TournamentConfig tournament;
  final int playerCoins;
  final int playerGems;
  final bool hasFreeTicket;
  final bool hasActiveEntry;
  final VoidCallback onTap;

  const TournamentCard({
    super.key,
    required this.tournament,
    required this.playerCoins,
    required this.playerGems,
    required this.hasFreeTicket,
    required this.hasActiveEntry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final canEnterResult = TournamentManager().canEnterTournament(
      tournament,
      playerCoins: playerCoins,
      playerGems: playerGems,
    );

    // Responsive sizing
    final isUltraNarrow = screenSize.width < 340;
    final cardHeight = ResponsiveConfig.responsiveSize(170, screenSize, minScale: 0.9, maxScale: 1.15);
    final imageWidth = isUltraNarrow
        ? ResponsiveConfig.responsiveSize(88, screenSize, minScale: 0.7, maxScale: 1.0)
        : ResponsiveConfig.responsiveSize(110, screenSize, minScale: 0.82, maxScale: 1.05);
    final padding = ResponsiveConfig.responsiveSize(isUltraNarrow ? 8 : 12, screenSize);
    final borderRadius = ResponsiveConfig.responsiveSize(16, screenSize, minScale: 0.9, maxScale: 1.1);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: padding, vertical: padding * 0.5),
        constraints: BoxConstraints(minHeight: cardHeight),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          // Glowing cyan/blue border
          border: Border.all(
            color: const Color(0xFF4FC3F7).withOpacity(0.6),
            width: 2,
          ),
          // Outer glow effect
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4FC3F7).withOpacity(0.3),
              blurRadius: 16,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius - 2),
          child: Container(
            // Dark navy background
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A2744), // Dark navy
                  Color(0xFF0D1B2A), // Darker navy
                ],
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Tournament Banner Image
                _buildBannerImage(imageWidth, cardHeight, borderRadius),
                
                // Right: Tournament Info
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Top: Full Name & Type (kept compact)
                        _buildTitleSection(screenSize),

                        SizedBox(height: ResponsiveConfig.responsiveSize(6, screenSize, minScale: 0.6, maxScale: 1.0)),

                        // Middle: Prizes Preview gets extra priority; wrap to avoid overflows
                        _buildPrizesRow(screenSize),

                        SizedBox(height: ResponsiveConfig.responsiveSize(6, screenSize, minScale: 0.6, maxScale: 1.0)),

                        // Bottom: Entry Button
                        _buildEntryButton(canEnterResult, screenSize),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build title section with full name and tournament type
  Widget _buildTitleSection(Size screenSize) {
    final titleSize = ResponsiveConfig.responsiveSize(15, screenSize, minScale: 0.9, maxScale: 1.1);
    final typeSize = ResponsiveConfig.responsiveSize(12, screenSize, minScale: 0.9, maxScale: 1.1);
    
    // Get clean name without emoji (we'll show emoji in type)
    final cleanName = tournament.name.replaceAll(RegExp(r'[^\w\s]'), '').trim();
    
    // Build tournament type string based on progression type
    String tournamentType;
    if (tournament.isPlayoff) {
      // Playoff tournaments show "1vs1 Playoff · X rounds"
      tournamentType = '1vs1 Playoff · ${tournament.totalRounds} rounds';
    } else {
      // Linear tournaments (like Stunt Tournament) show "1 World Map · X Levels"
      tournamentType = '1 World Map · ${tournament.totalRounds} Levels';
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tournament name - up to 2 lines, will wrap naturally
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                cleanName,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Status badge (if active or has free ticket)
            _buildStatusBadge(typeSize),
          ],
        ),
        
        const SizedBox(height: 4),
        
        // Tournament type
        Text(
          tournamentType,
          style: TextStyle(
            fontSize: typeSize,
            color: tournament.isPlayoff 
                ? const Color(0xFFFFB74D) // Orange for playoff
                : const Color(0xFF81D4FA), // Light blue for linear
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildBannerImage(double width, double height, double borderRadius) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(borderRadius - 2),
          bottomLeft: Radius.circular(borderRadius - 2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(borderRadius - 2),
          bottomLeft: Radius.circular(borderRadius - 2),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Try to load actual tournament image
            Image.asset(
              'assets/images/tournaments/${tournament.id}.png',
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback: Gradient with icon
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _getTypeColor().withOpacity(0.8),
                        _getTypeColor().withOpacity(0.4),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          tournament.isPlayoff 
                              ? Icons.emoji_events
                              : Icons.route,
                          size: 40,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tournament.isPlayoff ? '1vs1' : '${tournament.totalRounds}R',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            // Subtle vignette overlay
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.2),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(double fontSize) {
    if (hasActiveEntry) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.5),
              blurRadius: 6,
            ),
          ],
        ),
        child: Text(
          'PLAYING',
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize - 1,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    
    if (hasFreeTicket) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.amber,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.5),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TournamentTicketIcon(tier: tournament.tier, size: fontSize + 2),
            const SizedBox(width: 4),
            Text(
              'FREE',
              style: TextStyle(
                color: Colors.black87,
                fontSize: fontSize - 1,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  /// Build prizes section - BIGGER and more prominent!
  Widget _buildPrizesRow(Size screenSize) {
    // Much bigger sizes for prizes section (but allow smaller on ultra-narrow)
    final isUltraNarrow = screenSize.width < 340;
    final fontSize = ResponsiveConfig.responsiveSize(
      isUltraNarrow ? 16 : 19,
      screenSize,
      minScale: 0.8,
      maxScale: 1.2,
    );
    final iconSize = ResponsiveConfig.responsiveSize(
      isUltraNarrow ? 22 : 28,
      screenSize,
      minScale: 0.8,
      maxScale: 1.2,
    );
    final trophySize = ResponsiveConfig.responsiveSize(
      isUltraNarrow ? 20 : 24,
      screenSize,
      minScale: 0.8,
      maxScale: 1.2,
    );
    
    final totalCoins = tournament.completionReward.coins + tournament.totalCoinsFromRounds;
    final totalGems = tournament.completionReward.gems + tournament.totalGemsFromRounds;
    final skinId = tournament.completionReward.skinId;
    final hasTicket = tournament.completionReward.freeTicketTier != null;
    final hasBooster = tournament.completionReward.booster != null;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: SizedBox(
        width: double.infinity,
        child: FittedBox(
          alignment: Alignment.centerLeft,
          fit: BoxFit.scaleDown,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tournament-specific trophy image (kept compact)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.asset(
                  'assets/images/tournaments/trophy_${tournament.id}.png',
                  width: trophySize + 8,
                  height: trophySize + 8,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to emoji if image not found
                    return Text('🏆', style: TextStyle(fontSize: trophySize));
                  },
                ),
              ),
              const SizedBox(width: 8),
              
              // Coins
              Coin3DIcon(size: iconSize),
              const SizedBox(width: 4),
              Text(
                '$totalCoins',
                style: TextStyle(
                  color: const Color(0xFFFFD54F),
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),

              if (totalGems > 0) ...[
                const SizedBox(width: 10),
                Gem3DIcon(size: iconSize),
                const SizedBox(width: 4),
                Text(
                  '$totalGems',
                  style: TextStyle(
                    color: const Color(0xFF4FC3F7),
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
              ],

              if (skinId != null) ...[
                const SizedBox(width: 10),
                _buildSkinThumbnail(skinId, iconSize + 6),
              ],

              if (hasTicket) ...[
                const SizedBox(width: 8),
                TournamentTicketIcon(
                  tier: tournament.completionReward.freeTicketTier ?? TournamentTier.silver,
                  size: iconSize + 2,
                ),
              ],

              if (hasBooster) ...[
                const SizedBox(width: 8),
                Text('⚡', style: TextStyle(fontSize: iconSize - 4)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Build a small thumbnail of the jet skin reward (no box/border)
  Widget _buildSkinThumbnail(String skinId, double size) {
    // Look up the skin in the catalog
    final jetSkin = JetSkinCatalog.getAllSkins().firstWhere(
      (skin) => skin.id == skinId,
      orElse: () => JetSkinCatalog.starterJet,
    );
    
    // Just the image, no container/box around it
    return Image.asset(
      'assets/images/${jetSkin.assetPath}',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to sparkle emoji if image fails
        return SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Text('✨', style: TextStyle(fontSize: size * 0.6)),
          ),
        );
      },
    );
  }

  Widget _buildEntryButton(CanEnterResult canEnterResult, Size screenSize) {
    // Larger CTA for better readability
    final buttonHeight = ResponsiveConfig.responsiveSize(36, screenSize, minScale: 0.95, maxScale: 1.15);
    final buttonFontSize = ResponsiveConfig.responsiveSize(13, screenSize, minScale: 0.95, maxScale: 1.15);
    
    if (hasActiveEntry) {
      return _buildPremiumButton(
        text: 'CONTINUE',
        primaryColor: const Color(0xFF4CAF50),
        secondaryColor: const Color(0xFF2E7D32),
        textColor: Colors.white,
        icon: Icons.play_arrow,
        fontSize: buttonFontSize,
        height: buttonHeight,
        enabled: true,
      );
    }

    if (hasFreeTicket) {
      return _buildPremiumButton(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TournamentTicketIcon(tier: tournament.tier, size: buttonFontSize + 4),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'USE FREE TICKET',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: buttonFontSize,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        primaryColor: const Color(0xFFFFD700),
        secondaryColor: const Color(0xFFFFA500),
        textColor: Colors.black87,
        fontSize: buttonFontSize,
        height: buttonHeight,
        enabled: true,
      );
    }

    final canAfford = canEnterResult.canEnter;
    final isFree = tournament.entry.amount == 0;
    
    return _buildPremiumButton(
      child: _buildEntryContent(buttonFontSize, canAfford ? Colors.black87 : Colors.white60),
      primaryColor: canAfford 
          ? (isFree ? const Color(0xFF4CAF50) : const Color(0xFFFFD700))
          : const Color(0xFF5C6370),
      secondaryColor: canAfford 
          ? (isFree ? const Color(0xFF2E7D32) : const Color(0xFFE6B800))
          : const Color(0xFF3E4451),
      textColor: canAfford ? Colors.black87 : Colors.white60,
      icon: null,
      fontSize: buttonFontSize,
      height: buttonHeight,
      enabled: canAfford,
    );
  }

  Widget _buildEntryContent(double fontSize, Color textColor) {
    if (tournament.entry.amount == 0) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'FREE',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
            ),
          ),
        ],
      );
    }
    
    switch (tournament.entry.type) {
      case EntryFeeType.coins:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${tournament.entry.amount}',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: fontSize,
              ),
            ),
            const SizedBox(width: 4),
            Coin3DIcon(size: fontSize + 2),
          ],
        );
      case EntryFeeType.gems:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${tournament.entry.amount}',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: fontSize,
              ),
            ),
            const SizedBox(width: 4),
            Gem3DIcon(size: fontSize + 2),
          ],
        );
      case EntryFeeType.freeTicket:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TournamentTicketIcon(
              tier: tournament.tier,
              size: fontSize + 4,
            ),
            const SizedBox(width: 6),
            Text(
              'TICKET',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: fontSize,
              ),
            ),
          ],
        );
    }
  }

  Widget _buildPremiumButton({
    String? text,
    Widget? child,
    required Color primaryColor,
    required Color secondaryColor,
    required Color textColor,
    IconData? icon,
    required double fontSize,
    required double height,
    required bool enabled,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            primaryColor,
            secondaryColor,
          ],
        ),
        // Smaller border radius for compact button
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: enabled ? Colors.white.withOpacity(0.25) : Colors.transparent,
          width: 1,
        ),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: primaryColor.withOpacity(0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: child ?? Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: textColor, size: fontSize + 3),
            const SizedBox(width: 4),
          ],
          Text(
            text ?? '',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
              letterSpacing: 0.3,
              shadows: enabled
                  ? [
                      Shadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 1,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  /// Get color based on tournament type
  Color _getTypeColor() {
    if (tournament.isPlayoff) {
      return const Color(0xFFFF6B35); // Orange for playoff
    }
    return const Color(0xFF2196F3); // Blue for linear
  }
}

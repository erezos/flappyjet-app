/// 🏆 Floating Tournaments Banner - World Map overlay for tournament engagement
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../game/systems/tournament_manager.dart';

/// Floating banner widget for the World Map
/// Shows "FREE" notification badge when free tournaments or tickets are available
class FloatingTournamentsBanner extends StatefulWidget {
  final VoidCallback onTap;
  final double size;
  final bool useResponsiveScaling;
  
  const FloatingTournamentsBanner({
    super.key,
    required this.onTap,
    this.size = 85,
    this.useResponsiveScaling = true,
  });

  @override
  State<FloatingTournamentsBanner> createState() => _FloatingTournamentsBannerState();
}

class _FloatingTournamentsBannerState extends State<FloatingTournamentsBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  
  final TournamentManager _tournamentManager = TournamentManager();

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _initializeAndCheck();
  }
  
  Future<void> _initializeAndCheck() async {
    // Ensure tournament manager is initialized
    if (!_tournamentManager.isInitialized) {
      await _tournamentManager.initialize();
    }
    _tournamentManager.addListener(_checkAndStartPulse);
    _checkAndStartPulse();
  }

  @override
  void dispose() {
    _tournamentManager.removeListener(_checkAndStartPulse);
    _pulseController.dispose();
    super.dispose();
  }
  
  void _checkAndStartPulse() {
    final hasFree = _hasFreeTournamentOrTicket();
    if (hasFree && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!hasFree && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.value = 0;
    }
    if (mounted) setState(() {});
  }
  
  /// Check if any tournament is free or player has a free ticket for any tournament
  bool _hasFreeTournamentOrTicket() {
    final tournaments = _tournamentManager.availableTournaments;
    
    for (final tournament in tournaments) {
      // Check if tournament is completely free (entry amount = 0)
      if (tournament.entry.amount == 0) {
        return true;
      }
      
      // Check if player has a free ticket for this tournament's tier
      if (_tournamentManager.hasFreeTicketFor(tournament)) {
        return true;
      }
    }
    
    return false;
  }

  double _getResponsiveSize(BuildContext context) {
    if (!widget.useResponsiveScaling) return widget.size;
    
    final screenWidth = MediaQuery.of(context).size.width;
    double scaleFactor = screenWidth < 360 ? 0.85 : (screenWidth > 400 ? 1.15 : 1.0);
    return widget.size * scaleFactor;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _tournamentManager,
      builder: (context, _) {
        final hasFree = _hasFreeTournamentOrTicket();
        final bannerSize = _getResponsiveSize(context);
        
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onTap();
          },
          child: _buildBannerWithBadge(bannerSize, hasFree),
        );
      },
    );
  }
  
  /// Classic mobile game notification badge pattern:
  /// Badge sits at top-right corner OVERLAPPING the banner edge
  /// Shows "FREE" text instead of a count
  /// 
  /// NOTE: Image is 220x147 pixels (1.497:1 aspect ratio)
  /// MATCHED to Missions banner positioning pattern for consistent overlapping badges.
  Widget _buildBannerWithBadge(double bannerSize, bool showFreeBadge) {
    // Banner image is 220x147 = 1.497 aspect ratio (rectangle)
    const double imageAspectRatio = 220.0 / 147.0; // ≈ 1.497
    
    // Match Missions banner height calculation: bannerSize * 0.7
    final bannerHeight = bannerSize * 0.7;
    // Width based on aspect ratio
    final bannerWidth = bannerHeight * imageAspectRatio;
    
    // Badge sizing - match Missions badge style EXACTLY
    final badgeSize = (bannerHeight * 0.35).clamp(20.0, 28.0);
    final badgeWidth = badgeSize * 1.6; // Pill shape for "FREE" text
    final badgeHeight = badgeSize;
    
    // ✅ BADGE OVERLAP: Position badge so it SITS ON the corner
    // - Small positive rightOffset = badge near right edge but inside
    // - Very small negative topOffset = badge almost entirely ON banner
    // Key: badge should be ~90% ON the banner, ~10% extending above
    final rightOffset = badgeSize * 0.1;   // Near right edge  
    final topOffset = -badgeHeight * 0.10; // ~10% above top edge = 90% ON the banner
    
    return SizedBox(
      width: bannerWidth,
      height: bannerHeight,
      child: Stack(
        clipBehavior: Clip.none, // Critical: allow badge to overflow
        children: [
          // Banner fills the entire Stack
          Positioned.fill(
            child: _buildBannerImage(bannerWidth, bannerHeight),
          ),
          
          // "FREE" Badge at top-right corner - OVERLAPPING the top edge
          if (showFreeBadge)
            Positioned(
              right: rightOffset,
              top: topOffset,
              child: _FreeBadge(width: badgeWidth, height: badgeHeight),
            ),
        ],
      ),
    );
  }
  
  /// Build banner image - NO shadow to ensure clean badge positioning
  /// The banner image itself contains all styling (borders, glow, etc.)
  Widget _buildBannerImage(double width, double height) {
    // No Container wrapper with shadow - just the image directly
    // This ensures badge positioning is relative to the actual image bounds
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        'assets/images/ui/banner_tournaments.png',
        width: width,
        height: height,
        fit: BoxFit.fill, // Fill exactly - image matches container aspect ratio
        errorBuilder: (context, error, stackTrace) => _buildFallbackBanner(width, height),
      ),
    );
  }
  
  /// Fallback banner if image fails to load (rectangle layout)
  Widget _buildFallbackBanner(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF6B35), Color(0xFFF7931E)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD700), width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events, color: const Color(0xFFFFD700), size: height * 0.5),
          const SizedBox(width: 4),
          Text(
            'EVENTS',
            style: TextStyle(
              color: Colors.white,
              fontSize: height * 0.28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// "FREE" badge widget - gaming industry standard notification style
/// Compact pill shape to match Missions badge proportions
class _FreeBadge extends StatelessWidget {
  final double width;
  final double height;
  
  const _FreeBadge({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    final fontSize = (height * 0.50).clamp(8.0, 11.0);
    
    return Container(
      constraints: BoxConstraints(minWidth: width, minHeight: height),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)], // Green gradient for "FREE"
        ),
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
            blurRadius: 4,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'FREE',
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}


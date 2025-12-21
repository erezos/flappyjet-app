/// 🎄 Christmas Tournament Banner
/// 
/// Displays a banner for the Christmas tournament on the world map
/// with a timer showing time remaining until the tournament ends.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../game/systems/tournament_manager.dart';
import '../../../game/systems/missions_manager.dart';
import '../../../game/systems/monetization_manager.dart';
import '../../utils/responsive_config.dart';
import '../../layouts/homepage_layout.dart';
import '../../screens/tournament_hub_screen.dart';
import '../../widgets/homepage_footer_navigator.dart';
import '../../../core/debug_logger.dart';

class ChristmasTournamentBanner extends StatefulWidget {
  const ChristmasTournamentBanner({super.key});

  @override
  State<ChristmasTournamentBanner> createState() => _ChristmasTournamentBannerState();
}

class _ChristmasTournamentBannerState extends State<ChristmasTournamentBanner> {
  final TournamentManager _tournamentManager = TournamentManager();
  Timer? _timer;
  Duration? _timeRemaining;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAndCheck();
    // Update timer every second
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        _updateTimeRemaining();
      }
    });
  }

  @override
  void dispose() {
    _tournamentManager.removeListener(_onTournamentManagerChanged);
    _timer?.cancel();
    super.dispose();
  }

  /// Initialize TournamentManager and listen for changes
  Future<void> _initializeAndCheck() async {
    // Ensure tournament manager is initialized
    if (!_tournamentManager.isInitialized) {
      await _tournamentManager.initialize();
    }
    // Listen to tournament manager changes (when tournaments are loaded)
    _tournamentManager.addListener(_onTournamentManagerChanged);
    _onTournamentManagerChanged();
  }

  /// Called when TournamentManager state changes (tournaments loaded/updated)
  void _onTournamentManagerChanged() {
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
      _updateTimeRemaining();
    }
  }

  void _updateTimeRemaining() {
    try {
      final christmasTournament = _tournamentManager.displayableTournaments
          .where((t) => t.id == 'christmas_tournament')
          .firstOrNull;

      if (christmasTournament == null || 
          !christmasTournament.isAvailable || 
          christmasTournament.endDate == null) {
        if (mounted) {
          setState(() => _timeRemaining = null);
        }
        return;
      }

      final now = DateTime.now();
      final endDate = christmasTournament.endDate!;
      final remaining = endDate.difference(now);

      if (remaining.isNegative) {
        if (mounted) {
          setState(() => _timeRemaining = null);
        }
        return;
      }

      if (mounted) {
        setState(() => _timeRemaining = remaining);
      }
    } catch (e) {
      safePrint('⚠️ Error updating Christmas tournament timer: $e');
      if (mounted) {
        setState(() => _timeRemaining = null);
      }
    }
  }

  bool _shouldShowBanner() {
    try {
      final christmasTournament = _tournamentManager.displayableTournaments
          .where((t) => t.id == 'christmas_tournament')
          .firstOrNull;
      return christmasTournament != null && 
             christmasTournament.isAvailable && 
             _timeRemaining != null;
    } catch (e) {
      return false;
    }
  }

  void _onBannerTap(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomepageLayout(
          activeSection: FooterNavigatorSection.tournaments,
          child: TournamentHubScreen(
            monetization: MonetizationManager(),
            missions: MissionsManager(),
          ),
        ),
      ),
    );
  }

  String _formatTimeRemaining() {
    if (_timeRemaining == null) return '';

    final days = _timeRemaining!.inDays;
    if (days > 0) {
      return '$days ${days == 1 ? 'Day' : 'Days'} to go';
    }

    final hours = _timeRemaining!.inHours;
    final minutes = _timeRemaining!.inMinutes.remainder(60);
    final seconds = _timeRemaining!.inSeconds.remainder(60);

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // Don't show banner until TournamentManager is initialized
    if (!_isInitialized || !_shouldShowBanner()) {
      return const SizedBox.shrink();
    }

    final screenSize = MediaQuery.of(context).size;
    // Make banner 25% smaller: 120.0 * 0.75 = 90.0
    final bannerSize = ResponsiveConfig.responsiveSize(90.0, screenSize, minScale: 0.8, maxScale: 1.3);
    final badgeSize = ResponsiveConfig.responsiveSize(16.0, screenSize, minScale: 0.7, maxScale: 1.2);
    final badgeFontSize = ResponsiveConfig.responsiveFontSize(10.0, screenSize, context);

    // Calculate footer height (same as world_map_screen.dart)
    final footerHeight = screenSize.width * (391.0 / 1490.0);
    final systemNavBarHeight = ResponsiveConfig.getSystemNavigationBarHeight(context);
    // Position banner above footer with some padding
    final bannerBottom = footerHeight + systemNavBarHeight + ResponsiveConfig.responsivePadding(12.0, screenSize);

    return Positioned(
      bottom: bannerBottom, // Above footer + system nav bar
      left: ResponsiveConfig.responsivePadding(12.0, screenSize),
      child: GestureDetector(
        onTap: () => _onBannerTap(context),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Banner image
            Image.asset(
              'assets/images/tournaments/Christmas/christmas_banner.png',
              width: bannerSize,
              height: bannerSize,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                safePrint('⚠️ Failed to load Christmas banner: $error');
                return Container(
                  width: bannerSize,
                  height: bannerSize,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.error, color: Colors.white),
                );
              },
            ),
            
            // Timer badge on top center
            if (_timeRemaining != null)
              Positioned(
                top: -badgeSize * 0.5,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveConfig.responsivePadding(6.0, screenSize),
                    vertical: ResponsiveConfig.responsivePadding(3.0, screenSize),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(badgeSize),
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: bannerSize * 0.9, // Constrain to 90% of banner width
                      ),
                      child: Text(
                        _formatTimeRemaining(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: badgeFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


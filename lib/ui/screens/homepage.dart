/// 🎨 HOMEPAGE - Main application homepage
/// Game launcher and navigation hub
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async' as async;
import '../../core/debug_logger.dart';
import '../../game/systems/monetization_manager.dart';
import '../../game/systems/missions_manager.dart';
import '../../game/systems/achievements_manager.dart';

import '../widgets/no_hearts_dialog.dart';
import 'game_screen.dart';
// Removed unused import
import 'daily_missions_screen.dart';
import '../../game/systems/inventory_manager.dart';
import '../../game/systems/lives_manager.dart';
import 'package:intl/intl.dart';
import 'store_screen.dart';
import '../widgets/gem_3d_icon.dart';
import 'profile_screen.dart';
import 'tournaments_screen.dart';
import '../widgets/homepage/homepage_audio_manager.dart';
import '../widgets/daily_streak/daily_streak_integration.dart';
import '../widgets/daily_streak/daily_streak_popup_stable.dart';
import '../widgets/daily_streak/duplicate_jet_popup.dart';
import '../widgets/rate_us_integration.dart';
import '../../game/systems/daily_streak_manager.dart';
import '../../integrations/ftue_integration.dart';

class Homepage extends StatefulWidget {
  final bool firebaseEnabled;
  final MonetizationManager monetization;
  final MissionsManager missions;
  final AchievementsManager achievements;

  const Homepage({
    super.key,
    required this.firebaseEnabled,
    required this.monetization,
    required this.missions,
    required this.achievements,
  });

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _jetController;
  late Animation<double> _jetFloat;
  // 🎵 AUDIO: Managed by HomepageAudioManager
  late HomepageAudioManager _audioManager;
  bool _disposed = false;
  final InventoryManager _inventory = InventoryManager();
  late final NumberFormat _numFmt = NumberFormat.decimalPattern();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupAnimations();
    _startAnimations();

    // 🎵 Initialize audio manager
    _audioManager = HomepageAudioManager();
    Future.microtask(() => _audioManager.initializeAudio());

    // 🎯 Initialize daily streak system
    _initializeDailyStreak();
    
    // 🎮 Initialize FTUE system
    _initializeFTUE();

    // Initialize inventory for live coin counter
    _inventory.addListener(_onInventoryChanged);
    _inventory.initialize().then((_) {
      if (mounted && !_disposed) setState(() {});
    });
  }

  // old top status removed in favor of overlay coins/hearts widgets

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // App came back to foreground - resume audio
        _audioManager.handleAppLifecycleChange(true);
        // Check auto-refill when app resumes
        _checkAutoRefill();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // App went to background - pause audio immediately
        _audioManager.handleAppLifecycleChange(false);
        break;
      case AppLifecycleState.hidden:
        // App is hidden - pause audio
        _audioManager.handleAppLifecycleChange(false);
        break;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This is called when returning from another screen
    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent) {
      // CRITICAL FIX: Mark returned FIRST, then handle route change
      _audioManager.markReturnedToHomepage();
      _audioManager.handleRouteChange(true);
      
      // 🔄 Check auto-refill first (immediate hearts refill)
      _checkAutoRefill();
      
      // 🎮 Check for FTUE popups when returning from game
      _checkFTUEPopups();
    }
  }

  void _setupAnimations() {
    // Gentle jet floating animation
    _jetController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _jetFloat = Tween<double>(
      begin: -5.0,
      end: 5.0,
    ).animate(CurvedAnimation(parent: _jetController, curve: Curves.easeInOut));
  }

  void _startAnimations() {
    // Start jet floating animation for production
    _jetController.repeat(reverse: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _jetController.dispose();
    _disposed = true;
    _inventory.removeListener(_onInventoryChanged);

    // 🎵 AUDIO: Dispose audio manager
    _audioManager.dispose();

    super.dispose();
  }

  void _onInventoryChanged() {
    if (mounted && !_disposed) setState(() {});
  }

  /// Initialize daily streak system and show popup if needed
  Future<void> _initializeDailyStreak() async {
    try {
      await DailyStreakIntegration.initialize();
      
      // Set up duplicate jet popup callback
      DailyStreakManager.setDuplicateJetCallback(_showDuplicateJetPopup);
      
      // Show popup after a short delay if needed
      if (mounted && DailyStreakIntegration.shouldShowPopup()) {
        await Future.delayed(const Duration(milliseconds: 2000));
        if (mounted) {
          await DailyStreakIntegration.showDailyStreakPopup(context);
        }
      }
      
      // Check for rate us popup after daily streak (if no daily streak shown)
      if (mounted && !DailyStreakIntegration.shouldShowPopup()) {
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) {
          await RateUsIntegration.showOnAppLaunch(context);
        }
      }
    } catch (e) {
      safePrint('Failed to initialize daily streak: $e');
    }
  }

  /// Initialize FTUE system for new players
  Future<void> _initializeFTUE() async {
    try {
      await FTUEIntegration.initialize();
    } catch (e) {
      safePrint('Failed to initialize FTUE: $e');
    }
  }

  /// Check for FTUE popups when returning from game
  Future<void> _checkFTUEPopups() async {
    if (!mounted) return;
    
    try {
      // Small delay to ensure navigation is complete
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted && FTUEIntegration.shouldShowPopup()) {
        await FTUEIntegration.showFTUEPopup(context);
      }
    } catch (e) {
      safePrint('Error checking FTUE popups: $e');
    }
  }

  /// Check and trigger auto-refill when returning to homepage
  Future<void> _checkAutoRefill() async {
    if (!mounted) return;
    
    try {
      final inventory = InventoryManager();
      final wasTriggered = await inventory.checkAndTriggerAutoRefill();
      
      if (wasTriggered && mounted) {
        // Show subtle animation or notification that hearts were refilled
        safePrint('🔄 Auto-refill triggered - hearts refilled!');
        // Could add a subtle UI animation here in the future
      }
    } catch (e) {
      safePrint('Error checking auto-refill: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // === BACKGROUND LAYER ===
            _buildSkyBackground(),
            // Clouds now part of background image - no need for extra layer
            // === OVERLAY STATUS (top-left coins, top-right hearts) - RESPONSIVE ===
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = constraints.maxWidth;
                  final isTablet = screenWidth > 600;
                  final isLargeTablet = screenWidth > 900;
                  
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isLargeTablet ? 24 : isTablet ? 18 : 12,
                      vertical: isTablet ? 12 : 6,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left side: Coins + Daily Streak (progression indicators)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildCoinsChipTopLeft(isTablet, isLargeTablet),
                            SizedBox(width: isTablet ? 12 : 8),
                            _buildDailyStreakNotification(isTablet, isLargeTablet),
                          ],
                        ),
                        // Right side: Hearts (lives)
                        _buildHeartsTopRight(isTablet, isLargeTablet)
                      ],
                    ),
                  );
                },
              ),
            ),

            // === CONTENT LAYER - RESPONSIVE ===
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = constraints.maxWidth;
                  final isTablet = screenWidth > 600;
                  final isLargeTablet = screenWidth > 900;
                  
                  return Column(
                    children: [
                      SizedBox(height: isLargeTablet ? 60 : isTablet ? 50 : 40),

                      // === FLAPPY JET TITLE - RESPONSIVE ===
                      _buildGameTitle(isTablet, isLargeTablet),

                      SizedBox(height: isLargeTablet ? 60 : isTablet ? 50 : 40),

                      // === CUTE JET CHARACTER - RESPONSIVE ===
                      Expanded(flex: 2, child: _buildJetCharacter(isTablet, isLargeTablet)),

                      // === BUTTON SECTION - RESPONSIVE ===
                      Expanded(flex: 5, child: _buildButtonSection()),
                    ],
                  );
                },
              ),
            ),

            // DEBUG RESET BUTTON REMOVED FOR SCREENSHOTS
          ],
        ),
      ),
    );
  }

  Widget _buildSkyBackground() {
    return Container(
      key: const Key('sky_background'),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/backgrounds/sky_with_clouds.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  // Cloud layer removed - clouds now part of background image

  Widget _buildGameTitle(bool isTablet, bool isLargeTablet) {
    final titleWidth = isLargeTablet ? 600.0 : isTablet ? 550.0 : 450.0;
    final titleHeight = isLargeTablet ? 170.0 : isTablet ? 150.0 : 130.0;
    final containerHeight = isLargeTablet ? 200.0 : isTablet ? 180.0 : 140.0;
    
    return SizedBox(
      width: double.infinity,
      height: containerHeight,
      child: Center(
        child: Image.asset(
          'assets/images/homepage/flappy_jet_title.png',
          width: titleWidth,
          height: titleHeight,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildJetCharacter(bool isTablet, bool isLargeTablet) {
    final jetWidth = isLargeTablet ? 350.0 : isTablet ? 320.0 : 250.0;
    final jetHeight = isLargeTablet ? 250.0 : isTablet ? 220.0 : 180.0;
    final containerWidth = isLargeTablet ? 400.0 : isTablet ? 360.0 : 280.0;
    final containerHeight = isLargeTablet ? 280.0 : isTablet ? 250.0 : 200.0;
    
    return AnimatedBuilder(
      animation: _jetFloat,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _jetFloat.value),
          child: SizedBox(
            width: containerWidth,
            height: containerHeight,
            child: Center(
              child: Image.asset(
                'assets/images/homepage/cute_jet_character.png',
                width: jetWidth,
                height: jetHeight,
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildButtonSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Fit 5 buttons + coin row without scrolling.
        final availableHeight = constraints.maxHeight;
        final spacing = (availableHeight * 0.03).clamp(8.0, 12.0);
        final totalSpacing = spacing * 4; // between 5 buttons
        final coinCounterHeight = (availableHeight * 0.1).clamp(32.0, 44.0);
        // Ensure all buttons fit: do not force a minimum higher than possible
        final buttonHeight =
            (availableHeight - totalSpacing - coinCounterHeight) / 5;
        final adaptiveHeight = buttonHeight.clamp(44.0, 60.0);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // PLAY Button - Primary Action
              _buildNineSliceButton(
                label: 'PLAY',
                iconAsset: 'assets/images/icons/icon_play.png',
                onPressed: _navigateToGame,
                height: adaptiveHeight,
              ),

              SizedBox(height: spacing),

              _buildNineSliceButton(
                label: 'PROFILE',
                iconAsset: 'assets/images/icons/icon_profile.png',
                onPressed: _navigateToProfile,
                height: adaptiveHeight,
              ),

              SizedBox(height: spacing),

              _buildNineSliceButton(
                label: 'MISSIONS',
                iconAsset: 'assets/images/icons/icon_missions.png',
                onPressed: _navigateToMissions,
                height: adaptiveHeight,
              ),

              SizedBox(height: spacing),

              _buildNineSliceButton(
                label: 'TOURNAMENTS',
                iconAsset: 'assets/images/icons/icon_leaderboard.png',
                onPressed: _navigateToTournaments,
                height: adaptiveHeight,
              ),

              SizedBox(height: spacing),

              _buildNineSliceButton(
                label: 'STORE',
                iconAsset: 'assets/images/icons/icon_store.png',
                onPressed: _navigateToStore,
                height: adaptiveHeight,
              ),

              // Coin Counter - Shows current balance
              // Removed bottom coin bar to save space
            ],
          ),
        );
      },
    );
  }

  Widget _buildNineSliceButton({
    required String label,
    required String iconAsset,
    required VoidCallback onPressed,
    required double height,
  }) {
    return _NineSliceButton(
      label: label,
      iconAsset: iconAsset,
      height: height,
      onPressed: onPressed,
    );
  }

  /// Build daily streak notification with badge
  Widget _buildDailyStreakNotification(bool isTablet, bool isLargeTablet) {
    final iconSize = isLargeTablet ? 24.0 : isTablet ? 22.0 : 18.0;
    final fontSize = isLargeTablet ? 16.0 : isTablet ? 14.0 : 12.0;
    final padding = isLargeTablet ? 14.0 : isTablet ? 12.0 : 10.0;
    final verticalPadding = isLargeTablet ? 10.0 : isTablet ? 8.0 : 6.0;
    final borderRadius = isLargeTablet ? 20.0 : isTablet ? 18.0 : 16.0;
    final spacing = isLargeTablet ? 6.0 : isTablet ? 5.0 : 4.0;
    final notificationDotSize = isLargeTablet ? 8.0 : isTablet ? 7.0 : 6.0;
    // borderWidth will be calculated inside the builder where hasNotification is available
    
    return ListenableBuilder(
      listenable: DailyStreakIntegration.streakManager,
      builder: (context, child) {
        final hasNotification = DailyStreakIntegration.hasNotification;
        final currentStreak = DailyStreakIntegration.streakManager.currentStreak;
        final borderWidth = hasNotification ? (isTablet ? 2.5 : 2.0) : 1.0;
        
        if (!hasNotification && currentStreak == 0) {
          return const SizedBox.shrink();
        }
        
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(borderRadius),
            onTap: () => _showDailyStreakPopupAlways(context),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: padding, vertical: verticalPadding),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: hasNotification
                      ? [
                          Colors.amber.withValues(alpha: 0.3),
                          Colors.orange.withValues(alpha: 0.2),
                        ]
                      : [
                          Colors.blue.withValues(alpha: 0.2),
                          Colors.blue.withValues(alpha: 0.1),
                        ],
                ),
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: hasNotification
                      ? Colors.amber.withValues(alpha: 0.8)
                      : Colors.blue.withValues(alpha: 0.5),
                  width: borderWidth,
                ),
                boxShadow: [
                  BoxShadow(
                    color: hasNotification
                        ? Colors.amber.withValues(alpha: 0.4)
                        : Colors.blue.withValues(alpha: 0.2),
                    blurRadius: hasNotification ? (isTablet ? 10 : 8) : 4,
                    spreadRadius: hasNotification ? 1 : 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      Image.asset(
                        'assets/images/icons/calendar.png',
                        width: iconSize,
                        height: iconSize,
                      ),
                      if (hasNotification)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: notificationDotSize,
                            height: notificationDotSize,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (currentStreak > 0) ...[
                    SizedBox(width: spacing),
                    Text(
                      '$currentStreak',
                      style: TextStyle(
                        color: hasNotification ? Colors.amber : Colors.white70,
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Bottom coin counter removed (replaced with top status bar)
  Widget _buildHeartsTopRight(bool isTablet, bool isLargeTablet) {
    final heartSize = isLargeTablet ? 26.0 : isTablet ? 22.0 : 18.0;
    final heartSpacing = isLargeTablet ? 10.0 : isTablet ? 8.0 : 6.0;
    final timerSpacing = isLargeTablet ? 6.0 : isTablet ? 4.0 : 2.0;
    
    return ValueListenableBuilder<int>(
      valueListenable: LivesManager().livesListenable,
      builder: (context, count, _) {
        final livesManager = LivesManager();
        final maxLives = livesManager.maxLives;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Hearts display
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(maxLives, (i) {
                final filled = i < count;
                return Padding(
                  padding: EdgeInsets.only(left: heartSpacing),
                  child: Icon(
                    Icons.favorite,
                    size: heartSize,
                    color: filled
                        ? Colors.redAccent
                        : Colors.redAccent.withValues(alpha: 0.25),
                  ),
                );
              }),
            ),

            // Regeneration timer (only show if not at max hearts)
            if (count < maxLives) ...[
              SizedBox(height: timerSpacing),
              _HeartRegenTimer(),
            ],
          ],
        );
      },
    );
  }

  Widget _buildCoinsChipTopLeft(bool isTablet, bool isLargeTablet) {
    final iconSize = isLargeTablet ? 22.0 : isTablet ? 20.0 : 16.0;
    final fontSize = isLargeTablet ? 18.0 : isTablet ? 16.0 : 13.0;
    final padding = isLargeTablet ? 16.0 : isTablet ? 14.0 : 10.0;
    final verticalPadding = isLargeTablet ? 10.0 : isTablet ? 8.0 : 6.0;
    final borderRadius = isLargeTablet ? 24.0 : isTablet ? 22.0 : 18.0;
    final spacing = isLargeTablet ? 10.0 : isTablet ? 8.0 : 6.0;
    final dividerSpacing = isLargeTablet ? 16.0 : isTablet ? 14.0 : 12.0;
    final dividerHeight = isLargeTablet ? 20.0 : isTablet ? 18.0 : 16.0;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: verticalPadding),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Coins
          Icon(Icons.monetization_on, color: Colors.amber, size: iconSize),
          SizedBox(width: spacing),
          ValueListenableBuilder<int>(
            valueListenable: _inventory.softCurrencyNotifier,
            builder: (context, _, __) {
              return Text(
                _numFmt.format(_inventory.softCurrency),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: fontSize,
                ),
              );
            },
          ),

          // Divider
          SizedBox(width: dividerSpacing),
          Container(
            width: 1,
            height: dividerHeight,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          SizedBox(width: dividerSpacing),

          // Gems - Beautiful asset gem icon
          Gem3DIcon(
            size: iconSize,
            // Using beautiful asset image
          ),
          SizedBox(width: spacing),
          ValueListenableBuilder<int>(
            valueListenable: _inventory.gemsNotifier,
            builder: (context, _, __) {
              return Text(
                _numFmt.format(_inventory.gems),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: fontSize,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Show daily streak popup regardless of claim status
  Future<void> _showDailyStreakPopupAlways(BuildContext context) async {
    try {
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) => DailyStreakPopupStable(
          streakManager: DailyStreakIntegration.streakManager,
          onClaim: () async {
            // Handle successful claim
            if (mounted) {
              setState(() {}); // Refresh UI
            }
            
            // Close the dialog
            if (dialogContext.mounted && Navigator.canPop(dialogContext)) {
              Navigator.of(dialogContext).pop();
            }
          },
          onClose: () {
            // Handle close button
            if (dialogContext.mounted && Navigator.canPop(dialogContext)) {
              Navigator.of(dialogContext).pop();
            }
          },
        ),
      );
    } catch (e) {
      safePrint('Error showing daily streak popup: $e');
    }
  }

  /// Show beautiful duplicate jet popup
  void _showDuplicateJetPopup(String jetSkinId, int coinsAwarded) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DuplicateJetPopup(
        jetSkinId: jetSkinId,
        coinsAwarded: coinsAwarded,
      ),
    );
  }

  void _navigateToGame() async {
    // Check if player has hearts available
    final livesManager = LivesManager();
    if (livesManager.currentLives <= 0) {
      // Show no hearts dialog
      _showNoHeartsDialog();
      return;
    }

    // 🎵 AUDIO FIX: Stop menu music before going to game
    await _audioManager.stopMenuMusic();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GameScreen(
          monetization: widget.monetization,
          missions: widget.missions,
        ),
      ),
    );
  }

  void _showNoHeartsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => NoHeartsDialog(
        monetization: widget.monetization,
        onClose: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _navigateToMissions() {
    // Keep menu music playing when navigating to missions (don't stop audio)
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DailyMissionsScreen(
          missionsManager: widget.missions,
          achievementsManager: widget.achievements,
        ),
      ),
    );
  }

  void _navigateToStore() {
    // Keep menu music playing when navigating to store
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const StoreScreen()));
  }

  void _navigateToProfile() {
    // Keep menu music playing when navigating to profile
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const ProfileScreen()));
  }

  void _navigateToTournaments() {
    // Keep menu music playing when navigating to tournaments
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const TournamentsScreen()));
  }
}

// CloudsPainter removed - clouds now part of background image

class _NineSliceButton extends StatefulWidget {
  final String label;
  final String iconAsset;
  final double height;
  final VoidCallback onPressed;
  const _NineSliceButton({
    required this.label,
    required this.iconAsset,
    required this.height,
    required this.onPressed,
  });

  @override
  State<_NineSliceButton> createState() => _NineSliceButtonState();
}

/// Live updating heart regeneration timer widget
class _HeartRegenTimer extends StatefulWidget {
  @override
  State<_HeartRegenTimer> createState() => _HeartRegenTimerState();
}

class _HeartRegenTimerState extends State<_HeartRegenTimer> {
  async.Timer? _timer;
  int _secondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    _updateTimer();
    _timer = async.Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateTimer(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTimer() async {
    final livesManager = LivesManager();
    final seconds = await livesManager.getSecondsUntilNextRegen();
    if (mounted) {
      setState(() {
        _secondsRemaining = seconds ?? 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_secondsRemaining <= 0) {
      return const SizedBox.shrink();
    }

    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    final timeStr =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2196F3).withValues(alpha: 0.9),
            const Color(0xFF1976D2).withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2196F3).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Heart icon with pulse animation
          _PulsingHeart(),

          const SizedBox(width: 4),

          // Timer text with modern styling
          Text(
            timeStr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pulsing heart animation for timer
class _PulsingHeart extends StatefulWidget {
  @override
  State<_PulsingHeart> createState() => _PulsingHeartState();
}

class _PulsingHeartState extends State<_PulsingHeart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Icon(Icons.favorite, size: 12, color: Colors.red.shade300),
        );
      },
    );
  }
}

class _NineSliceButtonState extends State<_NineSliceButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final height = widget.height;
    final radius = BorderRadius.circular(height * 0.48);
    // Button gradient varies by label to create a green->gold progression
    List<Color> baseColors(String label) {
      switch (label) {
        case 'PLAY':
          return const [Color(0xFF3CCB7C), Color(0xFF27B267)];
        case 'PROFILE':
          return const [Color(0xFF55D07D), Color(0xFF2FBA69)];
        case 'MISSIONS':
          return const [Color(0xFF7DDC7A), Color(0xFF46C36A)];
        case 'LEADER BOARD':
          return const [Color(0xFFF4C04E), Color(0xFFE19A19)];
        case 'STORE':
          return const [Color(0xFFFFD256), Color(0xFFF5A623)];
        default:
          return const [Color(0xFFFFD256), Color(0xFFF5A623)];
      }
    }

    final normal = baseColors(widget.label);
    final pressed = normal
        .map((c) => Color.alphaBlend(Colors.black12, c))
        .toList();
    final Gradient gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: _pressed ? pressed : normal,
    );
    final Color borderColor = _pressed ? Colors.black26 : Colors.black26;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.lightImpact();
        widget.onPressed();
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        scale: _pressed ? 0.98 : 1.0,
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.76,
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Capsule gradient background with shadow and border
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: radius,
                  border: Border.all(color: borderColor, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x66C57D0B),
                      blurRadius: 14,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
              ),
              // Subtle top highlight
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.center,
                      colors: [
                        Colors.white.withValues(alpha: 0.18),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              // Content: centered group with text first, then icon
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        fontSize: (height * 0.34).clamp(14.0, 20.0),
                        shadows: [
                          Shadow(
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                            color: Colors.black.withValues(alpha: 0.35),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Image.asset(
                      widget.iconAsset,
                      width: (height * 0.58).clamp(22.0, 32.0),
                      height: (height * 0.58).clamp(22.0, 32.0),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../game/systems/missions_manager.dart';
import '../../game/systems/achievements_manager.dart';
import '../widgets/gem_3d_icon.dart';
import '../widgets/coin_3d_icon.dart';
import '../widgets/mission_achievement_icons.dart';
import '../widgets/rewards/unified_reward_card.dart';
import '../widgets/rate_us_integration.dart';
import '../widgets/badge_notification.dart';
import '../widgets/status_bar/coins_gems_display.dart';
import '../widgets/animations/reward_flying_animation.dart';
import '../utils/responsive_config.dart';

class DailyMissionsScreen extends StatefulWidget {
  final MissionsManager? missionsManager;
  final AchievementsManager? achievementsManager;

  const DailyMissionsScreen({
    super.key,
    this.missionsManager,
    this.achievementsManager,
  });

  @override
  State<DailyMissionsScreen> createState() => _DailyMissionsScreenState();
}

class _DailyMissionsScreenState extends State<DailyMissionsScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  late AnimationController _animationController;
  bool _isRefreshing = false;
  final Set<String> _claimingMissions = {}; // Track missions being claimed
  
  // GlobalKeys for position tracking
  final GlobalKey _coinBalanceKey = GlobalKey();
  final GlobalKey _gemBalanceKey = GlobalKey();
  
  // Track reward icon keys per mission/achievement
  final Map<String, GlobalKey> _missionCoinKeys = {};
  final Map<String, GlobalKey> _achievementCoinKeys = {};
  final Map<String, GlobalKey> _achievementGemKeys = {};
  
  // Track active animations
  final List<Widget> _activeAnimations = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh when app comes back to foreground to show updated progress
    if (state == AppLifecycleState.resumed) {
      _refreshData();
    }
  }

  /// Refresh missions and achievements data
  Future<void> _refreshData() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      // Get managers and refresh their data
      try {
        context.read<MissionsManager>();
        context.read<AchievementsManager>();
      } catch (e) {
        // Fallback to widget managers if context read fails
        // Using widget.missionsManager and widget.achievementsManager as fallback
      }

      // Force refresh by triggering setState
      if (mounted) {
        setState(() {
          // Trigger rebuild to refresh mission and achievement states
        });
      }

      // Restart animation to show updates
      _animationController.reset();
      _animationController.forward();
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  /// Get widget position from GlobalKey
  Offset? _getWidgetPosition(GlobalKey? key) {
    if (key?.currentContext == null) return null;
    final RenderBox? renderBox = key!.currentContext!.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    // Return center of widget
    return Offset(position.dx + size.width / 2, position.dy + size.height / 2);
  }

  /// Trigger reward flying animation
  void _triggerRewardAnimation({
    required Offset? startPosition,
    required Offset? endPosition,
    required RewardType type,
    required int amount,
  }) {
    if (startPosition == null || endPosition == null) {
      // Fallback: if positions not available, skip animation
      return;
    }

    final animationKey = GlobalKey();
    final animation = RewardFlyingAnimation(
      key: animationKey,
      startPosition: startPosition,
      endPosition: endPosition,
      type: type,
      amount: amount,
      onComplete: () {
        if (mounted) {
          setState(() {
            _activeAnimations.removeWhere((anim) => anim.key == animationKey);
          });
        }
      },
    );

    setState(() {
      _activeAnimations.add(animation);
    });
  }

  /// Claim mission reward with flying animation
  /// 
  /// ✅ CRITICAL FIX: Uses proper BuildContext lifecycle management to prevent
  /// "This BuildContext is no longer valid" errors. The context can become
  /// invalid during async operations (like claiming rewards), so we must
  /// check `mounted` immediately before using the context for UI operations.
  /// 
  /// ✅ NEW: Uses flying animation instead of popup dialog
  Future<void> _claimReward(BuildContext context, String missionId) async {
    // Prevent double-clicking
    if (_claimingMissions.contains(missionId)) {
      return;
    }

    // ✅ FIX: Early mounted check before any state changes
    if (!mounted) return;

    setState(() {
      _claimingMissions.add(missionId);
    });

    // Try to get MissionsManager from Provider first, fallback to passed parameter
    MissionsManager? missionsManager;
    try {
      // ✅ FIX: Check mounted before using context
      if (!mounted) return;
      missionsManager = context.read<MissionsManager>();
    } catch (e) {
      missionsManager = widget.missionsManager;
    }

    if (missionsManager == null) {
      if (!mounted) return; // ✅ FIX: Check before setState
      setState(() {
        _claimingMissions.remove(missionId);
      });
      if (!mounted) return; // ✅ FIX: Check before using context
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missions not available')),
      );
      return;
    }

    // Get mission details before claiming
    final mission = missionsManager.dailyMissions.firstWhere(
      (m) => m.id == missionId,
      orElse: () => throw Exception('Mission not found'),
    );
    
    // Get positions before claiming (widgets might be removed after claim)
    final coinKey = _missionCoinKeys[missionId];
    final startPosition = coinKey != null
        ? _getWidgetPosition(coinKey)
        : null;
    final endPosition = _getWidgetPosition(_coinBalanceKey);
    
    // Wait for layout if positions not ready
    if (startPosition == null || endPosition == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _claimReward(context, missionId); // Retry after layout
        }
      });
      return;
    }
    
    final success = await missionsManager.claimMissionReward(missionId);
    
    // ✅ CRITICAL FIX: Check mounted AGAIN after the async operation
    // The widget could have been disposed during the await
    if (!mounted) return;
    
    if (success) {
      setState(() {
        _claimingMissions.remove(missionId);
      });
      
      // ✅ NEW: Trigger flying animation instead of popup
      // Events are already fired by MissionsManager.claimMissionReward() ✅
      _triggerRewardAnimation(
        startPosition: startPosition,
        endPosition: endPosition,
        type: RewardType.coin,
        amount: mission.reward,
      );
      
      // Clean up keys after animation starts
      _missionCoinKeys.remove(missionId);
    } else {
      setState(() {
        _claimingMissions.remove(missionId);
      });
      // ✅ FIX: Check mounted before showing snackbar
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to claim reward'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Claim achievement reward with flying animation
  /// 
  /// ✅ CRITICAL FIX: Uses proper BuildContext lifecycle management to prevent
  /// "This BuildContext is no longer valid" errors. Same fix as _claimReward.
  /// 
  /// ✅ NEW: Uses flying animation instead of popup dialog
  Future<void> _claimAchievementReward(
    BuildContext context,
    String achievementId,
  ) async {
    // ✅ FIX: Early mounted check before any operations
    if (!mounted) return;
    
    // Try to get AchievementsManager from Provider first, fallback to passed parameter
    AchievementsManager? achievementsManager;
    try {
      // ✅ FIX: Check mounted before using context
      if (!mounted) return;
      achievementsManager = context.read<AchievementsManager>();
    } catch (e) {
      achievementsManager = widget.achievementsManager;
    }

    if (achievementsManager == null) {
      // ✅ FIX: Check mounted before using context for snackbar
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Achievements not available')),
      );
      return;
    }

    // Get achievement details before claiming for reward display
    final achievement = achievementsManager.achievements[achievementId];
    
    if (achievement == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Achievement not found')),
      );
      return;
    }

    // Get positions before claiming (widgets might be removed after claim)
    final coinKey = _achievementCoinKeys[achievementId];
    final gemKey = achievement.gemReward > 0 ? _achievementGemKeys[achievementId] : null;
    
    final coinStartPosition = coinKey != null ? _getWidgetPosition(coinKey) : null;
    final gemStartPosition = gemKey != null ? _getWidgetPosition(gemKey) : null;
    final coinEndPosition = _getWidgetPosition(_coinBalanceKey);
    final gemEndPosition = _getWidgetPosition(_gemBalanceKey);
    
    // Wait for layout if positions not ready
    if ((coinStartPosition == null && achievement.coinReward > 0) ||
        (gemStartPosition == null && achievement.gemReward > 0) ||
        (coinEndPosition == null && achievement.coinReward > 0) ||
        (gemEndPosition == null && achievement.gemReward > 0)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _claimAchievementReward(context, achievementId); // Retry after layout
        }
      });
      return;
    }

    final success = await achievementsManager.claimAchievementReward(
      achievementId,
    );
    
    // ✅ CRITICAL FIX: Check mounted AGAIN after the async operation
    // The widget could have been disposed during the await
    if (!mounted) return;
    
    if (success) {
      // ✅ NEW: Trigger flying animations instead of popup
      // Events are already fired by AchievementsManager.claimAchievementReward() ✅
      
      // Animate coin if present
      if (achievement.coinReward > 0 && coinStartPosition != null && coinEndPosition != null) {
        _triggerRewardAnimation(
          startPosition: coinStartPosition,
          endPosition: coinEndPosition,
          type: RewardType.coin,
          amount: achievement.coinReward,
        );
      }
      
      // Animate gem if present (with slight delay for visual effect)
      if (achievement.gemReward > 0 && gemStartPosition != null && gemEndPosition != null) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) {
            _triggerRewardAnimation(
              startPosition: gemStartPosition,
              endPosition: gemEndPosition,
              type: RewardType.gem,
              amount: achievement.gemReward,
            );
          }
        });
      }
      
      // Clean up keys after animations start
      _achievementCoinKeys.remove(achievementId);
      _achievementGemKeys.remove(achievementId);
      
      // ⭐ Show Rate Us popup after achievement claim (positive experience)
      // Delay to let animation complete
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          RateUsIntegration.showAfterPositiveExperience(context);
        }
      });
    } else {
      // ✅ FIX: Check mounted before showing snackbar
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to claim achievement reward'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background image (same as profile screen)
          Positioned.fill(
            child: Image.asset(
              'assets/images/backgrounds/sky_with_clouds.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF87CEEB), Color(0xFF98D8E8)],
                    ),
                  ),
                );
              },
            ),
          ),

          // Main content with animation overlay
          SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    // Header with back button, title, and refresh
                    _buildHeader(context, screenSize),

                    // Tab selector (Daily Missions / Achievements)
                    _buildTabSelector(context, screenSize),

                    // Mission cards content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildDailyMissions(context, screenSize),
                          _buildAchievements(context, screenSize),
                        ],
                      ),
                    ),
                  ],
                ),
                // Animation overlay - shows flying coins/gems
                ..._activeAnimations,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Size screenSize) {
    final isTablet = screenSize.width > 600;

    return Padding(
      padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
      child: Row(
        children: [
          // Balance component (coins and gems) on top left
          CoinsGemsDisplay(
            coinIconKey: _coinBalanceKey,
            gemIconKey: _gemBalanceKey,
          ),

          const Spacer(),

          // MISSIONS title with 3D effect
          Text(
            'MISSIONS',
            style: TextStyle(
              fontSize: isTablet ? 36 : 28,
              fontWeight: FontWeight.w900,
              foreground: Paint()
                ..shader = const LinearGradient(
                  colors: [Color(0xFFffd700), Color(0xFFffb300)],
                ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
              shadows: [
                Shadow(
                  offset: const Offset(0, 4),
                  blurRadius: 8,
                  color: Colors.black.withValues(alpha: 0.5),
                ),
                Shadow(
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                  color: const Color(0xFF1565c0).withValues(alpha: 0.3),
                ),
              ],
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildTabSelector(BuildContext context, Size screenSize) {
    // ✅ RESPONSIVE: Use ResponsiveConfig for consistent sizing
    final isTablet = ResponsiveConfig.isTablet(screenSize);
    final isLargeTablet = ResponsiveConfig.isLargeTablet(screenSize);
    
    // Calculate tab height - modern and compact
    final tabHeight = ResponsiveConfig.responsiveSize(
      isTablet ? 56.0 : 48.0,
      screenSize,
      minScale: 0.85,
      maxScale: 1.15,
    );

    // Get managers for badge counts
    final missionsManager = widget.missionsManager;
    final achievementsManager = widget.achievementsManager;

    // Create listenable list for real-time updates
    final listenables = <Listenable>[];
    if (missionsManager != null) listenables.add(missionsManager);
    if (achievementsManager != null) listenables.add(achievementsManager);

    return Container(
      margin: ResponsiveConfig.responsiveEdgeInsetsSymmetric(
        horizontal: isTablet ? 24.0 : 16.0,
        vertical: isTablet ? 16.0 : 12.0,
        screenSize: screenSize,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ResponsiveConfig.responsiveSize(20.0, screenSize)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: ResponsiveConfig.responsiveSize(12.0, screenSize),
            offset: Offset(0, ResponsiveConfig.responsiveSize(4.0, screenSize)),
          ),
        ],
      ),
      // ✅ FIX: Remove ClipRRect to allow badges to overflow, apply borderRadius to inner container
      child: Container(
        height: tabHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ResponsiveConfig.responsiveSize(20.0, screenSize)),
          gradient: const LinearGradient(
            colors: [Color(0xFF1e3c72), Color(0xFF2a5298)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        // ✅ BADGE: Use ListenableBuilder for real-time badge updates
        child: listenables.isEmpty
            ? _buildTabBar(context, screenSize, tabHeight, null, null)
            : ListenableBuilder(
                listenable: Listenable.merge(listenables),
                builder: (context, _) {
                  final missionsCount = missionsManager?.claimableMissionsCount ?? 0;
                  final achievementsCount = achievementsManager?.claimableAchievementsCount ?? 0;
                  return _buildTabBar(
                    context,
                    screenSize,
                    tabHeight,
                    missionsCount,
                    achievementsCount,
                  );
                },
              ),
      ),
    );
  }

  /// Build TabBar with badges - Modern design with text taking 80-90% of tab space
  /// ✅ MOBILE GAME BEST PRACTICES: Uses FittedBox to ensure text always fits without truncation
  Widget _buildTabBar(
    BuildContext context,
    Size screenSize,
    double tabHeight,
    int? missionsCount,
    int? achievementsCount,
  ) {
    // Calculate font size - more conservative to ensure text fits
    // Use tab height as base, with responsive scaling
    final isTablet = ResponsiveConfig.isTablet(screenSize);
    
    // Font size should be ~50-55% of tab height for optimal fit
    // This ensures text is large enough but will scale down if needed
    final baseFontSize = tabHeight * 0.55; // 55% of tab height (more conservative)
    final responsiveFontSize = ResponsiveConfig.responsiveFontSize(
      baseFontSize,
      screenSize,
      context,
      minScale: 0.75,
      maxScale: 1.1,
    ).clamp(12.0, 22.0); // Clamp for readability (lowered max from 24 to 22)

    // Minimal padding (5-10% on each side) to maximize text space
    final horizontalPadding = ResponsiveConfig.responsivePadding(
      isTablet ? 8.0 : 6.0,
      screenSize,
    );

    return TabBar(
      controller: _tabController,
      indicator: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFffc107), Color(0xFFff8f00)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(ResponsiveConfig.responsiveSize(20.0, screenSize)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFff8f00).withValues(alpha: 0.4),
            blurRadius: ResponsiveConfig.responsiveSize(8.0, screenSize),
            offset: Offset(0, ResponsiveConfig.responsiveSize(2.0, screenSize)),
          ),
        ],
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Colors.transparent,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white70,
      // ✅ MOBILE GAME BEST PRACTICES: Use FittedBox to auto-scale text to fit
      // This ensures text is always fully visible without truncation
      tabs: [
        Tab(
          child: Stack(
            clipBehavior: Clip.none, // Allow badge to overflow slightly
            children: [
              // ✅ FITTEDBOX: Auto-scales text to fit available space
              // This is the mobile game best practice - text scales down if needed but never truncates
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: FittedBox(
                    fit: BoxFit.scaleDown, // Scale down to fit, never scale up
                    alignment: Alignment.center,
                    child: Text(
                      'DAILY MISSIONS',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      // ✅ NO ELLIPSIS: Text will scale down to fit instead of truncating
                      style: TextStyle(
                        fontSize: responsiveFontSize,
                        fontWeight: FontWeight.w900,
                        letterSpacing: ResponsiveConfig.responsiveSize(0.5, screenSize),
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
              // ✅ BADGE: Position badge at top-right of tab component
              if (missionsCount != null && missionsCount > 0)
                Positioned(
                  top: ResponsiveConfig.responsiveSize(-6.0, screenSize),
                  right: ResponsiveConfig.responsiveSize(-6.0, screenSize),
                  child: BadgeNotification(
                    count: missionsCount,
                    screenSize: screenSize,
                  ),
                ),
            ],
          ),
        ),
        Tab(
          child: Stack(
            clipBehavior: Clip.none, // Allow badge to overflow slightly
            children: [
              // ✅ FITTEDBOX: Auto-scales text to fit available space
              // This is the mobile game best practice - text scales down if needed but never truncates
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: FittedBox(
                    fit: BoxFit.scaleDown, // Scale down to fit, never scale up
                    alignment: Alignment.center,
                    child: Text(
                      'ACHIEVEMENTS',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      // ✅ NO ELLIPSIS: Text will scale down to fit instead of truncating
                      style: TextStyle(
                        fontSize: responsiveFontSize,
                        fontWeight: FontWeight.w900,
                        letterSpacing: ResponsiveConfig.responsiveSize(0.5, screenSize),
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
              // ✅ BADGE: Position badge at top-right of tab component
              if (achievementsCount != null && achievementsCount > 0)
                Positioned(
                  top: ResponsiveConfig.responsiveSize(-6.0, screenSize),
                  right: ResponsiveConfig.responsiveSize(-6.0, screenSize),
                  child: BadgeNotification(
                    count: achievementsCount,
                    screenSize: screenSize,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDailyMissions(BuildContext context, Size screenSize) {
    // ✅ FIX: Use widget.missionsManager directly (it's the same instance being updated during gameplay)
    // This ensures we're listening to the same instance that's being updated
    final missionsManager = widget.missionsManager;

    // Check if missions manager is available
    if (missionsManager == null) {
      return Center(
        child: Builder(
          builder: (context) {
            return Text(
              'Missions not available',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF1A237E), // Dark blue for better readability
                fontSize: ResponsiveConfig.responsiveFontSize(18.0, screenSize, context),
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(
                    color: Colors.white.withValues(alpha: 0.8),
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                  ),
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    offset: const Offset(0, 1),
                    blurRadius: 3,
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    // ✅ FIX: Use ListenableBuilder to listen to MissionsManager changes in real-time
    // This ensures UI updates immediately when mission progress changes during gameplay
    // IMPORTANT: This will rebuild whenever MissionsManager calls notifyListeners()
    return ListenableBuilder(
      listenable: missionsManager,
      builder: (context, _) {
        // missionsManager is guaranteed non-null here (checked above)
        final manager = missionsManager;

        if (!manager.isInitialized) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFffc107)),
            ),
          );
        }

        final missions = manager.dailyMissions;

        // Sort missions: completed (ready to claim) first, then in progress, then not started
        missions.sort((a, b) {
          if (a.completed && !a.claimed && (!b.completed || b.claimed)) {
            return -1; // Completed missions ready to claim go to top
          }
          if (b.completed && !b.claimed && (!a.completed || a.claimed)) {
            return 1; // Completed missions ready to claim go to top
          }
          if (a.progress > 0 && b.progress == 0) {
            return -1; // In progress missions come before not started
          }
          if (b.progress > 0 && a.progress == 0) {
            return 1; // In progress missions come before not started
          }
          return a.createdAt.compareTo(
            b.createdAt,
          ); // Otherwise by creation time
        });

        if (missions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: ResponsiveConfig.responsiveIconSize(screenSize.width > 600 ? 80.0 : 60.0, screenSize),
                  color: const Color(0xFF1A237E), // Dark blue for better contrast
                ),
                SizedBox(height: ResponsiveConfig.responsivePadding(16.0, screenSize)),
                Builder(
                  builder: (context) {
                    return Text(
                      'No missions available\nCheck back tomorrow!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF1A237E), // Dark blue for better readability
                        fontSize: ResponsiveConfig.responsiveFontSize(
                          screenSize.width > 600 ? 20.0 : 18.0,
                          screenSize,
                          context,
                        ),
                        fontWeight: FontWeight.w600, // Semi-bold for better visibility
                        height: 1.4,
                        shadows: [
                          // Text shadow for better contrast against light backgrounds
                          Shadow(
                            color: Colors.white.withValues(alpha: 0.8),
                            offset: const Offset(0, 1),
                            blurRadius: 2,
                          ),
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            offset: const Offset(0, 1),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        }

        return FadeTransition(
          opacity: _animationController,
          child: ListView.builder(
            padding: EdgeInsets.all(screenSize.width > 600 ? 24.0 : 16.0),
            itemCount: missions.length,
            itemBuilder: (context, index) {
              final mission = missions[index];
              return SlideTransition(
                position:
                    Tween<Offset>(
                      begin: Offset(0, 0.5 + (index * 0.1)),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _animationController,
                        curve: Interval(
                          index * 0.1,
                          1.0,
                          curve: Curves.easeOutBack,
                        ),
                      ),
                    ),
                child: _buildMissionCard(context, mission, screenSize),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAchievements(BuildContext context, Size screenSize) {
    // ✅ FIX: Use widget.achievementsManager directly (it's the same instance being updated during gameplay)
    // This ensures we're listening to the same instance that's being updated
    final achievementsManager = widget.achievementsManager;

    // Check if achievements manager is available
    if (achievementsManager == null) {
      return Center(
        child: Builder(
          builder: (context) {
            return Text(
              'Achievements not available',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF1A237E), // Dark blue for better readability
                fontSize: ResponsiveConfig.responsiveFontSize(18.0, screenSize, context),
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(
                    color: Colors.white.withValues(alpha: 0.8),
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                  ),
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    offset: const Offset(0, 1),
                    blurRadius: 3,
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    // ✅ FIX: Use ListenableBuilder to listen to AchievementsManager changes in real-time
    // This ensures UI updates immediately when achievement progress changes during gameplay
    // IMPORTANT: This will rebuild whenever AchievementsManager calls notifyListeners()
    return ListenableBuilder(
      listenable: achievementsManager,
      builder: (context, _) {
        // achievementsManager is guaranteed non-null here (checked above)
        final manager = achievementsManager;

        if (!manager.isInitialized) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFffc107)),
            ),
          );
        }

        final achievements = manager.visibleAchievements;
        if (achievements.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events,
                  size: ResponsiveConfig.responsiveIconSize(screenSize.width > 600 ? 80.0 : 60.0, screenSize),
                  color: const Color(0xFF1A237E), // Dark blue for better contrast
                ),
                SizedBox(height: ResponsiveConfig.responsivePadding(16.0, screenSize)),
                Builder(
                  builder: (context) {
                    return Text(
                      'No achievements available\nCheck back later!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF1A237E), // Dark blue for better readability
                        fontSize: ResponsiveConfig.responsiveFontSize(
                          screenSize.width > 600 ? 20.0 : 18.0,
                          screenSize,
                          context,
                        ),
                        fontWeight: FontWeight.w600, // Semi-bold for better visibility
                        height: 1.4,
                        shadows: [
                          // Text shadow for better contrast against light backgrounds
                          Shadow(
                            color: Colors.white.withValues(alpha: 0.8),
                            offset: const Offset(0, 1),
                            blurRadius: 2,
                          ),
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            offset: const Offset(0, 1),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        }

        return FadeTransition(
          opacity: _animationController,
          child: Column(
            children: [
              // Achievement categories
              Expanded(
                child: _buildAchievementCategories(achievements, screenSize),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAchievementCategories(
    List<Achievement> achievements,
    Size screenSize,
  ) {
    final isTablet = screenSize.width > 600;

    // Group achievements by category
    final categories = <AchievementCategory, List<Achievement>>{};
    for (final achievement in achievements) {
      categories.putIfAbsent(achievement.category, () => []).add(achievement);
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 24.0 : 16.0),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories.keys.elementAt(index);
        final categoryAchievements = categories[category]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category header
            Padding(
              padding: EdgeInsets.symmetric(vertical: isTablet ? 16.0 : 12.0),
              child: Text(
                _getCategoryName(category),
                style: TextStyle(
                  color: const Color(0xFFffc107),
                  fontSize: isTablet ? 20 : 18,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),

            // Achievement cards for this category
            ...categoryAchievements.map(
              (achievement) => Builder(
                builder: (context) => SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: Curves.easeOutBack,
                        ),
                      ),
                  child: _buildAchievementCard(context, achievement, screenSize),
                ),
              ),
            ),

            SizedBox(height: isTablet ? 20 : 16),
          ],
        );
      },
    );
  }

  String _getCategoryName(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.score:
        return '🎯 Score Achievements';
      case AchievementCategory.streak:
        return '🔥 Streak Achievements';
      case AchievementCategory.collection:
        return '✈️ Collection Achievements';
      case AchievementCategory.survival:
        return '⏱️ Survival Achievements';
      case AchievementCategory.special:
        return '⭐ Special Achievements';
      case AchievementCategory.mastery:
        return '👑 Mastery Achievements';
    }
  }

  /// Build mission card using unified reward card
  Widget _buildMissionCard(BuildContext context, Mission mission, Size screenSize) {
    final missionStyle = _getMissionStyle(mission.type);
    final status = mission.claimed
        ? RewardCardStatus.claimed
        : (mission.completed
            ? RewardCardStatus.completed
            : RewardCardStatus.locked);

    // Get or create GlobalKey for coin reward icon
    if (!_missionCoinKeys.containsKey(mission.id)) {
      _missionCoinKeys[mission.id] = GlobalKey();
    }

    return UnifiedRewardCard(
      title: mission.title,
      description: mission.description,
      coinReward: mission.reward,
      gemReward: null, // Missions don't have gem rewards
      progress: mission.progress,
      target: mission.target,
      status: status,
      icon: Mission3DIcon(
        iconType: MissionIconMapper.getIconForMissionType(
          mission.type.toString().split('.').last,
        ),
        size: 50, // Size will be adjusted by card
      ),
      iconStyle: RewardCardIconStyle.floating,
      cardGradient: missionStyle.gradient,
      shadowColor: missionStyle.shadowColor,
      onClaimReward: () => _claimReward(context, mission.id),
      isClaiming: _claimingMissions.contains(mission.id),
      screenSize: screenSize,
      coinRewardIconKey: _missionCoinKeys[mission.id],
    );
  }

  /// Build achievement card using unified reward card
  Widget _buildAchievementCard(BuildContext context, Achievement achievement, Size screenSize) {
    final achievementStyle = _getAchievementStyle(achievement.rarity);
    final status = achievement.claimed
        ? RewardCardStatus.claimed
        : (achievement.unlocked
            ? RewardCardStatus.completed
            : RewardCardStatus.locked);

    // Get or create GlobalKeys for reward icons
    if (!_achievementCoinKeys.containsKey(achievement.id)) {
      _achievementCoinKeys[achievement.id] = GlobalKey();
    }
    if (achievement.gemReward > 0 && !_achievementGemKeys.containsKey(achievement.id)) {
      _achievementGemKeys[achievement.id] = GlobalKey();
    }

    return UnifiedRewardCard(
      title: achievement.title,
      description: achievement.description,
      coinReward: achievement.coinReward,
      gemReward: achievement.gemReward > 0 ? achievement.gemReward : null,
      progress: achievement.progress,
      target: achievement.target,
      status: status,
      icon: Achievement3DIcon(
        iconType: AchievementIconMapper.getIconForAchievement(
          achievement.category.toString().split('.').last,
          achievement.rarity.toString().split('.').last,
        ),
        size: 30, // Size will be adjusted by card
      ),
      iconStyle: RewardCardIconStyle.floating,
      cardGradient: achievementStyle.gradient,
      shadowColor: achievementStyle.shadowColor,
      onClaimReward: () => _claimAchievementReward(context, achievement.id),
      isClaiming: false, // Achievements don't have loading state yet
      coinRewardIconKey: _achievementCoinKeys[achievement.id],
      gemRewardIconKey: achievement.gemReward > 0 ? _achievementGemKeys[achievement.id] : null,
      screenSize: screenSize,
    );
  }

  /// Get mission style based on mission type
  MissionStyle _getMissionStyle(dynamic missionType) {
    // Handle both MissionType enum and String
    String typeString;
    if (missionType is String) {
      typeString = missionType.toLowerCase();
    } else {
      // It's a MissionType enum, extract name from toString()
      typeString = missionType.toString().split('.').last.toLowerCase();
    }

    switch (typeString) {
      case 'playgames':
        return MissionStyle(
          gradient: const LinearGradient(
            colors: [Color(0xFF00bcd4), Color(0xFF0097a7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shadowColor: const Color(0xFF00bcd4).withValues(alpha: 0.3),
          icon: Icons.play_arrow,
          iconBackgroundColor: const Color(0xFF4caf50),
        );
      case 'reachscore':
        return MissionStyle(
          gradient: const LinearGradient(
            colors: [Color(0xFF1976d2), Color(0xFF1565c0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shadowColor: const Color(0xFF1976d2).withValues(alpha: 0.3),
          icon: Icons.trending_up,
          iconBackgroundColor: const Color(0xFF2196f3),
        );
      case 'maintainstreak':
        return MissionStyle(
          gradient: const LinearGradient(
            colors: [Color(0xFFff5722), Color(0xFFe64a19)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shadowColor: const Color(0xFFff5722).withValues(alpha: 0.3),
          icon: Icons.local_fire_department,
          iconBackgroundColor: const Color(0xFFff5722),
        );
      case 'usecontinue':
        return MissionStyle(
          gradient: const LinearGradient(
            colors: [Color(0xFF9c27b0), Color(0xFF7b1fa2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shadowColor: const Color(0xFF9c27b0).withValues(alpha: 0.3),
          icon: Icons.refresh,
          iconBackgroundColor: const Color(0xFF9c27b0),
        );
      case 'collectcoins':
        return MissionStyle(
          gradient: const LinearGradient(
            colors: [Color(0xFFffc107), Color(0xFFff8f00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shadowColor: const Color(0xFFffc107).withValues(alpha: 0.3),
          icon: Icons.paid,
          iconBackgroundColor: const Color(0xFFffc107),
        );
      case 'survivetime':
        return MissionStyle(
          gradient: const LinearGradient(
            colors: [Color(0xFF4caf50), Color(0xFF388e3c)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shadowColor: const Color(0xFF4caf50).withValues(alpha: 0.3),
          icon: Icons.timer,
          iconBackgroundColor: const Color(0xFF4caf50),
        );
      case 'changenickname':
        return MissionStyle(
          gradient: const LinearGradient(
            colors: [Color(0xFF673ab7), Color(0xFF512da8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shadowColor: const Color(0xFF673ab7).withValues(alpha: 0.3),
          icon: Icons.edit,
          iconBackgroundColor: const Color(0xFF673ab7),
        );
      default:
        return MissionStyle(
          gradient: const LinearGradient(
            colors: [Color(0xFF607d8b), Color(0xFF455a64)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shadowColor: const Color(0xFF607d8b).withValues(alpha: 0.3),
          icon: Icons.assignment,
          iconBackgroundColor: const Color(0xFF607d8b),
        );
    }
  }

  /// Get achievement style based on rarity
  AchievementStyle _getAchievementStyle(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.bronze:
        return AchievementStyle(
          gradient: const LinearGradient(
            colors: [Color(0xFF8d6e63), Color(0xFF5d4037)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shadowColor: const Color(0xFF8d6e63).withValues(alpha: 0.3),
          rarityColor: const Color(0xFFcd7f32),
        );
      case AchievementRarity.silver:
        return AchievementStyle(
          gradient: const LinearGradient(
            colors: [Color(0xFF90a4ae), Color(0xFF607d8b)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shadowColor: const Color(0xFF90a4ae).withValues(alpha: 0.3),
          rarityColor: const Color(0xFFc0c0c0),
        );
      case AchievementRarity.gold:
        return AchievementStyle(
          gradient: const LinearGradient(
            colors: [Color(0xFFffc107), Color(0xFFff8f00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shadowColor: const Color(0xFFffc107).withValues(alpha: 0.3),
          rarityColor: const Color(0xFFffd700),
        );
      case AchievementRarity.platinum:
        return AchievementStyle(
          gradient: const LinearGradient(
            colors: [Color(0xFF9c27b0), Color(0xFF673ab7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shadowColor: const Color(0xFF9c27b0).withValues(alpha: 0.3),
          rarityColor: const Color(0xFFe1bee7),
        );
      case AchievementRarity.diamond:
        return AchievementStyle(
          gradient: const LinearGradient(
            colors: [Color(0xFF00bcd4), Color(0xFF0097a7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shadowColor: const Color(0xFF00bcd4).withValues(alpha: 0.3),
          rarityColor: const Color(0xFF80deea),
        );
    }
  }

  // Removed unused _buildPremiumButton and _refreshMissions methods
}

class PremiumMissionCard extends StatelessWidget {
  final dynamic mission;
  final VoidCallback onClaimReward;
  final Size screenSize;
  final bool isClaiming;

  const PremiumMissionCard({
    super.key,
    required this.mission,
    required this.onClaimReward,
    required this.screenSize,
    this.isClaiming = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = this.screenSize;
    // Use ResponsiveConfig for consistent sizing
    // Card height based on aspect ratio (~3.5:1 width:height)
    final cardHeight = ResponsiveConfig.responsiveSize(
      screenSize.width / 3.2,
      screenSize,
      minScale: 0.95,
      maxScale: 1.2,
    ).clamp(120.0, 170.0);

    // Get mission-specific styling
    final missionStyle = _getMissionStyle(mission.type);

    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveConfig.responsivePadding(16.0, screenSize)),
      height: cardHeight,
      decoration: BoxDecoration(
        gradient: missionStyle.gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: missionStyle.shadowColor,
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Subtle highlight effect
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: cardHeight * 0.3,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Main content
            Padding(
              padding: ResponsiveConfig.responsiveEdgeInsets(16.0, screenSize),
              child: Column(
                children: [
                  // Top row with icon, details, and rewards
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        // Mission icon - Responsive size (35-40% of card height) - Floating without square background
                        Builder(
                          builder: (context) {
                            final iconSize = ResponsiveConfig.responsiveSize(
                              cardHeight * 0.38,
                              screenSize,
                              minScale: 0.9,
                              maxScale: 1.1,
                            ).clamp(48.0, 70.0);
                            
                            return Container(
                              width: iconSize,
                              height: iconSize,
                              // ✅ FIX: Removed square background decoration - icon now floats on card
                              child: Center(
                                child: Mission3DIcon(
                                  iconType: MissionIconMapper.getIconForMissionType(
                                    mission.type.toString().split('.').last,
                                  ),
                                  size: iconSize * 0.85, // Increased size since no background container
                                  // Remove tintColor to show original icon colors
                                ),
                              ),
                            );
                          },
                        ),

                        SizedBox(width: ResponsiveConfig.responsivePadding(14.0, screenSize)),

                        // Mission details - Responsive text with FittedBox to prevent overflow
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              final titleFontSize = ResponsiveConfig.responsiveFontSize(16.0, screenSize, context);
                              final descFontSize = ResponsiveConfig.responsiveFontSize(12.0, screenSize, context);
                              
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      mission.title,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: titleFontSize,
                                        fontWeight: FontWeight.w900, // Extra bold
                                        height: 1.2, // ✅ FIX: Consistent line height
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.6,
                                            ),
                                            offset: const Offset(0, 1),
                                            blurRadius: 3,
                                          ),
                                        ],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(height: ResponsiveConfig.responsivePadding(3.0, screenSize)),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      mission.description,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.9),
                                        fontSize: descFontSize,
                                        fontWeight: FontWeight.w600, // Bolder
                                        height: 1.2, // ✅ FIX: Consistent line height
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),

                        // Coin reward - Responsive sizing with FittedBox
                        Builder(
                          builder: (context) {
                            final horizontalPadding = ResponsiveConfig.responsivePadding(12.0, screenSize);
                            final verticalPadding = ResponsiveConfig.responsivePadding(7.0, screenSize);
                            final iconSize = ResponsiveConfig.responsiveIconSize(18.0, screenSize);
                            final fontSize = ResponsiveConfig.responsiveFontSize(14.0, screenSize, context);
                            
                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding,
                                vertical: verticalPadding,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFffd700), Color(0xFFffb300)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFff8f00,
                                    ).withValues(alpha: 0.4),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown, // ✅ FIX: Scale down if needed
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Coin3DIcon(size: iconSize),
                                    SizedBox(width: ResponsiveConfig.responsivePadding(4.0, screenSize)),
                                    Text(
                                      '${mission.reward}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: fontSize,
                                        fontWeight: FontWeight.w900, // Extra bold
                                        height: 1.0, // ✅ FIX: Consistent line height
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.4,
                                            ),
                                            offset: const Offset(0, 1),
                                            blurRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Bottom row with progress or claim button (centered)
                  Expanded(
                    flex: 2,
                    child: Container(
                      width: double.infinity, // ✅ FIX: Ensure full width for proper centering
                      alignment: Alignment.center,
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveConfig.responsivePadding(8.0, screenSize),
                      ),
                      child: mission.completed && !mission.claimed
                          ?
                            // Claim button for completed missions
                            Builder(
                              builder: (context) {
                                final buttonHeight = ResponsiveConfig.responsiveButtonHeight(40.0, screenSize);
                                final horizontalPadding = ResponsiveConfig.responsivePadding(16.0, screenSize);
                                final verticalPadding = ResponsiveConfig.responsivePadding(8.0, screenSize);
                                
                                return ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: buttonHeight,
                                    maxWidth: double.infinity, // ✅ FIX: Allow button to use available width
                                  ),
                                  child: ElevatedButton(
                                    onPressed: isClaiming ? null : onClaimReward,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isClaiming
                                          ? Colors.grey
                                          : const Color(0xFF4caf50),
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: horizontalPadding,
                                        vertical: verticalPadding,
                                      ),
                                      minimumSize: Size(double.infinity, buttonHeight), // ✅ FIX: Full width button
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      elevation: isClaiming ? 2 : 6,
                                    ),
                                    child: Builder(
                                      builder: (context) {
                                        final iconSize = ResponsiveConfig.responsiveIconSize(16.0, screenSize);
                                        final fontSize = ResponsiveConfig.responsiveFontSize(12.0, screenSize, context);
                                        
                                        return FittedBox(
                                          fit: BoxFit.scaleDown, // ✅ FIX: Scale down text if needed
                                          alignment: Alignment.center,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              if (isClaiming)
                                                SizedBox(
                                                  width: iconSize,
                                                  height: iconSize,
                                                  child: const CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<Color>(
                                                          Colors.white,
                                                        ),
                                                  ),
                                                )
                                              else
                                                Icon(
                                                  Icons.card_giftcard,
                                                  size: iconSize,
                                                ),
                                              SizedBox(width: ResponsiveConfig.responsivePadding(8.0, screenSize)),
                                              Text(
                                                isClaiming ? 'CLAIMING...' : 'CLAIM REWARD',
                                                style: TextStyle(
                                                  fontSize: fontSize,
                                                  fontWeight: FontWeight.w900, // Extra bold
                                                  height: 1.0, // ✅ FIX: Consistent line height
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            )
                          :
                            // Progress indicator for incomplete missions
                            Builder(
                              builder: (context) {
                                final horizontalPadding = ResponsiveConfig.responsivePadding(16.0, screenSize);
                                final verticalPadding = ResponsiveConfig.responsivePadding(6.0, screenSize);
                                final fontSize = ResponsiveConfig.responsiveFontSize(12.0, screenSize, context);
                                
                                return Container(
                                  width: double.infinity, // ✅ FIX: Full width for proper centering
                                  padding: EdgeInsets.symmetric(
                                    horizontal: horizontalPadding,
                                    vertical: verticalPadding,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.4),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown, // ✅ FIX: Scale down if needed
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Progress: ${mission.progress}/${mission.target}',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: fontSize,
                                        fontWeight: FontWeight.w700, // Bolder
                                        height: 1.0, // ✅ FIX: Consistent line height
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  MissionStyle _getMissionStyle(dynamic missionType) {
    // Handle both MissionType enum and String
    String typeString;
    if (missionType is String) {
      typeString = missionType.toLowerCase();
    } else {
      // It's a MissionType enum, extract name from toString()
      typeString = missionType.toString().split('.').last.toLowerCase();
    }

    switch (typeString) {
      case 'playgames':
        return MissionStyle(
          gradient: const LinearGradient(
            colors: [Color(0xFF00bcd4), Color(0xFF0097a7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shadowColor: const Color(0xFF00bcd4).withValues(alpha: 0.3),
          icon: Icons.play_arrow,
          iconBackgroundColor: const Color(0xFF4caf50),
        );
      case 'reachscore':
        return MissionStyle(
          gradient: const LinearGradient(
            colors: [Color(0xFF1976d2), Color(0xFF1565c0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shadowColor: const Color(0xFF1976d2).withValues(alpha: 0.3),
          icon: Icons.trending_up,
          iconBackgroundColor: const Color(0xFF2196f3),
        );
      case 'maintainstreak':
        return MissionStyle(
          gradient: const LinearGradient(
            colors: [Color(0xFFff5722), Color(0xFFe64a19)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shadowColor: const Color(0xFFff5722).withValues(alpha: 0.3),
          icon: Icons.local_fire_department,
          iconBackgroundColor: const Color(0xFFff5722),
        );
      case 'usecontinue':
        return MissionStyle(
          gradient: const LinearGradient(
            colors: [Color(0xFF9c27b0), Color(0xFF7b1fa2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shadowColor: const Color(0xFF9c27b0).withValues(alpha: 0.3),
          icon: Icons.refresh,
          iconBackgroundColor: const Color(0xFF9c27b0),
        );
      case 'collectcoins':
        return MissionStyle(
          gradient: const LinearGradient(
            colors: [Color(0xFFffc107), Color(0xFFff8f00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shadowColor: const Color(0xFFffc107).withValues(alpha: 0.3),
          icon: Icons.paid, // Changed from monetization_on - we use Coin3DIcon for display
          iconBackgroundColor: const Color(0xFFffc107),
        );
      case 'survivetime':
        return MissionStyle(
          gradient: const LinearGradient(
            colors: [Color(0xFF4caf50), Color(0xFF388e3c)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shadowColor: const Color(0xFF4caf50).withValues(alpha: 0.3),
          icon: Icons.timer,
          iconBackgroundColor: const Color(0xFF4caf50),
        );
      case 'changenickname':
        return MissionStyle(
          gradient: const LinearGradient(
            colors: [Color(0xFF673ab7), Color(0xFF512da8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shadowColor: const Color(0xFF673ab7).withValues(alpha: 0.3),
          icon: Icons.edit,
          iconBackgroundColor: const Color(0xFF673ab7),
        );
      default:
        return MissionStyle(
          gradient: const LinearGradient(
            colors: [Color(0xFF607d8b), Color(0xFF455a64)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shadowColor: const Color(0xFF607d8b).withValues(alpha: 0.3),
          icon: Icons.assignment,
          iconBackgroundColor: const Color(0xFF607d8b),
        );
    }
  }
}

class MissionStyle {
  final Gradient gradient;
  final Color shadowColor;
  final IconData icon;
  final Color iconBackgroundColor;

  MissionStyle({
    required this.gradient,
    required this.shadowColor,
    required this.icon,
    required this.iconBackgroundColor,
  });
}

class PremiumAchievementCard extends StatelessWidget {
  final Achievement achievement;
  final VoidCallback onClaimReward;
  final Size screenSize;

  const PremiumAchievementCard({
    super.key,
    required this.achievement,
    required this.onClaimReward,
    required this.screenSize,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = screenSize.width > 600;
    final isLargePhone = screenSize.width > 400;
    final isSmallPhone = screenSize.width < 360;
    // Align height/feel with daily mission cards (responsive, compact, no stripe)
    final cardHeight = ResponsiveConfig.responsiveSize(
      screenSize.width / 3.5,
      screenSize,
      minScale: 0.9,
      maxScale: 1.2,
    ).clamp(120.0, 160.0);

    // Get achievement-specific styling based on rarity
    final achievementStyle = _getAchievementStyle(achievement.rarity);

    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 20 : 16),
      height: cardHeight,
      decoration: BoxDecoration(
        gradient: achievementStyle.gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: achievementStyle.shadowColor,
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Main content
            Padding(
              padding: EdgeInsets.all(isTablet ? 18 : (isLargePhone ? 14 : 12)),
              child: Column(
                children: [
                  // Top row with icon, details, and rewards
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        // Achievement icon - Larger and more engaging
                        Container(
                          width: isTablet ? 68 : (isLargePhone ? 62 : 56),
                          height: isTablet ? 68 : (isLargePhone ? 62 : 56),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                achievementStyle.rarityColor.withValues(alpha: 0.9),
                                achievementStyle.rarityColor.withValues(alpha: 0.7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: achievementStyle.rarityColor.withValues(
                                  alpha: 0.5,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Achievement3DIcon(
                            iconType:
                                AchievementIconMapper.getIconForAchievement(
                                  achievement.category
                                      .toString()
                                      .split('.')
                                      .last,
                                  achievement.rarity.toString().split('.').last,
                                ),
                            size: isTablet ? 34 : (isLargePhone ? 30 : 28),
                            // Remove tintColor to show original icon colors
                          ),
                        ),

                        SizedBox(width: isTablet ? 16 : 12),

                        // Achievement details - Bigger and bolder text
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                achievement.title,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isTablet
                                      ? 18
                                      : (isLargePhone ? 16 : 15),
                                  fontWeight: FontWeight.w900, // Extra bold
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.6,
                                      ),
                                      offset: const Offset(0, 1),
                                      blurRadius: 3,
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: isTablet ? 3 : 2),
                              Text(
                                achievement.description,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: isTablet
                                      ? 14
                                      : (isLargePhone ? 13 : 12),
                                  fontWeight: FontWeight.w600, // Bolder
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Rewards - Larger and more prominent
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Coin reward
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet
                                    ? 18
                                    : (isLargePhone ? 16 : 14),
                                vertical: isTablet ? 9 : (isLargePhone ? 8 : 7),
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFffd700),
                                    Color(0xFFffb300),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFff8f00,
                                    ).withValues(alpha: 0.4),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Coin3DIcon(
                                    size: isTablet
                                        ? 18
                                        : (isLargePhone ? 16 : 15),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${achievement.coinReward}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isTablet
                                          ? 15
                                          : (isLargePhone ? 14 : 13),
                                      fontWeight: FontWeight.w900, // Extra bold
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            if (achievement.gemReward > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 12 : 10,
                                  vertical: isTablet ? 7 : 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF9c27b0),
                                      Color(0xFF673ab7),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Gem3DIcon(
                                      size: isTablet
                                          ? 16
                                          : (isLargePhone ? 14 : 13),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${achievement.gemReward}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isTablet
                                            ? 15
                                            : (isLargePhone ? 14 : 13),
                                        fontWeight:
                                            FontWeight.w900, // Extra bold
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Bottom row with progress and status (centered)
                  Expanded(
                    flex: 2,
                    child: Container(
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Progress indicator (centered)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 16 : 14,
                              vertical: isTablet ? 7 : 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              'Progress: ${achievement.progress}/${achievement.target}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isTablet
                                    ? 14
                                    : (isLargePhone ? 13 : 12),
                                fontWeight: FontWeight.w700, // Bolder
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Status indicator (right of progress)
                          _buildStatusIndicator(
                            achievement,
                            isTablet,
                            isLargePhone,
                            isSmallPhone,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(
    Achievement achievement,
    bool isTablet,
    bool isLargePhone,
    bool isSmallPhone,
  ) {
    if (achievement.claimed) {
      // Claimed achievement - show completed indicator
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 12 : (isLargePhone ? 10 : 8),
          vertical: isTablet ? 6 : (isLargePhone ? 5 : 4),
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4caf50), Color(0xFF2e7d32)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4caf50).withValues(alpha: 0.3),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.white,
              size: isTablet ? 12 : 10,
            ),
            const SizedBox(width: 3),
            Text(
              'DONE',
              style: TextStyle(
                color: Colors.white,
                fontSize: isTablet ? 9 : 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else if (achievement.unlocked && !achievement.claimed) {
      // Unlocked achievement - show claim button
      return ElevatedButton(
        onPressed: onClaimReward,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFff9800),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 10 : (isLargePhone ? 8 : 6),
            vertical: isTablet ? 5 : (isLargePhone ? 4 : 3),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 3,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.card_giftcard, size: isTablet ? 12 : 10),
            const SizedBox(width: 3),
            Text(
              'CLAIM',
              style: TextStyle(
                fontSize: isTablet ? 9 : 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else {
      // Locked achievement - show progress percentage
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 10 : (isLargePhone ? 8 : 6),
          vertical: isTablet ? 5 : (isLargePhone ? 4 : 3),
        ),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '${(achievement.progressPercentage * 100).toInt()}%',
          style: TextStyle(
            color: Colors.white70,
            fontSize: isTablet ? 9 : 8,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
  }

  AchievementStyle _getAchievementStyle(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.bronze:
        return AchievementStyle(
          gradient: const LinearGradient(
            colors: [Color(0xFF8d6e63), Color(0xFF5d4037)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shadowColor: const Color(0xFF8d6e63).withValues(alpha: 0.3),
          rarityColor: const Color(0xFFcd7f32),
        );
      case AchievementRarity.silver:
        return AchievementStyle(
          gradient: const LinearGradient(
            colors: [Color(0xFF90a4ae), Color(0xFF607d8b)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shadowColor: const Color(0xFF90a4ae).withValues(alpha: 0.3),
          rarityColor: const Color(0xFFc0c0c0),
        );
      case AchievementRarity.gold:
        return AchievementStyle(
          gradient: const LinearGradient(
            colors: [Color(0xFFffc107), Color(0xFFff8f00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shadowColor: const Color(0xFFffc107).withValues(alpha: 0.3),
          rarityColor: const Color(0xFFffd700),
        );
      case AchievementRarity.platinum:
        return AchievementStyle(
          gradient: const LinearGradient(
            colors: [Color(0xFF9c27b0), Color(0xFF673ab7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shadowColor: const Color(0xFF9c27b0).withValues(alpha: 0.3),
          rarityColor: const Color(0xFFe1bee7),
        );
      case AchievementRarity.diamond:
        return AchievementStyle(
          gradient: const LinearGradient(
            colors: [Color(0xFF00bcd4), Color(0xFF0097a7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shadowColor: const Color(0xFF00bcd4).withValues(alpha: 0.3),
          rarityColor: const Color(0xFF80deea),
        );
    }
  }
}

class AchievementStyle {
  final Gradient gradient;
  final Color shadowColor;
  final Color rarityColor;

  AchievementStyle({
    required this.gradient,
    required this.shadowColor,
    required this.rarityColor,
  });
}

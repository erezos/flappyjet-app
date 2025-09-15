import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../game/systems/missions_manager.dart';
import '../../game/systems/achievements_manager.dart';
import '../widgets/gem_3d_icon.dart';
import '../widgets/mission_achievement_icons.dart';

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

  /// Claim mission reward with fade-out animation
  Future<void> _claimReward(BuildContext context, String missionId) async {
    // Prevent double-clicking
    if (_claimingMissions.contains(missionId)) {
      return;
    }

    setState(() {
      _claimingMissions.add(missionId);
    });

    // Try to get MissionsManager from Provider first, fallback to passed parameter
    MissionsManager? missionsManager;
    try {
      missionsManager = context.read<MissionsManager>();
    } catch (e) {
      missionsManager = widget.missionsManager;
    }

    if (missionsManager == null) {
      setState(() {
        _claimingMissions.remove(missionId);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Missions not available')));
      return;
    }

    final success = await missionsManager.claimMissionReward(missionId);
    if (success) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              const Text('Mission reward claimed!'),
            ],
          ),
          backgroundColor: const Color(0xFF4caf50),
          duration: const Duration(seconds: 2),
        ),
      );

      // Force UI refresh to ensure mission is removed
      setState(() {
        _claimingMissions.remove(missionId);
      });
    } else {
      setState(() {
        _claimingMissions.remove(missionId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to claim reward'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Claim achievement reward with animation
  Future<void> _claimAchievementReward(
    BuildContext context,
    String achievementId,
  ) async {
    // Try to get AchievementsManager from Provider first, fallback to passed parameter
    AchievementsManager? achievementsManager;
    try {
      achievementsManager = context.read<AchievementsManager>();
    } catch (e) {
      achievementsManager = widget.achievementsManager;
    }

    if (achievementsManager == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Achievements not available')),
      );
      return;
    }

    // Get achievement details before claiming for reward display
    final achievement = achievementsManager.achievements[achievementId];

    final success = await achievementsManager.claimAchievementReward(
      achievementId,
    );
    if (success && achievement != null) {
      // Show animated reward message with actual reward amounts
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Achievement claimed! +${achievement.coinReward} coins${achievement.gemReward > 0 ? ' +${achievement.gemReward} gems' : ''}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              if (achievement.coinReward > 0) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.monetization_on,
                  color: Colors.yellow,
                  size: 20,
                ),
                Text(
                  '${achievement.coinReward}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
              if (achievement.gemReward > 0) ...[
                const SizedBox(width: 8),
                const Icon(Icons.diamond, color: Colors.cyan, size: 20),
                Text(
                  '${achievement.gemReward}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
          backgroundColor: const Color(0xFF4caf50),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      // Force a complete UI refresh to ensure the claim button disappears
      setState(() {});

      // Trigger a rebuild animation to show the achievement moving to the bottom
      _animationController.reset();
      _animationController.forward();
    } else {
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

          // Main content
          SafeArea(
            child: Column(
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
          // Back button with premium styling
          _buildPremiumButton(
            onTap: () => Navigator.of(context).pop(),
            child: Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: isTablet ? 28 : 24,
            ),
            gradient: const LinearGradient(
              colors: [Color(0xFF00bcd4), Color(0xFF0097a7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
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

          // Refresh button
          _buildPremiumButton(
            onTap: _refreshData,
            child: _isRefreshing
                ? SizedBox(
                    width: isTablet ? 20 : 16,
                    height: isTablet ? 20 : 16,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: isTablet ? 28 : 24,
                  ),
            gradient: const LinearGradient(
              colors: [Color(0xFFff9800), Color(0xFFe65100)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector(BuildContext context, Size screenSize) {
    final isTablet = screenSize.width > 600;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 24.0 : 16.0,
        vertical: isTablet ? 16.0 : 12.0,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Container(
          height: isTablet ? 60 : 50,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1e3c72), Color(0xFF2a5298)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFffc107), Color(0xFFff8f00)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: TextStyle(
              fontSize: isTablet ? 18 : 16,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: isTablet ? 18 : 16,
              fontWeight: FontWeight.w500,
            ),
            tabs: const [
              Tab(text: 'DAILY MISSIONS'),
              Tab(text: 'ACHIEVEMENTS'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyMissions(BuildContext context, Size screenSize) {
    return Builder(
      builder: (context) {
        // Try to get MissionsManager from Provider first, fallback to passed parameter
        MissionsManager? missionsManager;
        try {
          missionsManager = context.watch<MissionsManager>();
        } catch (e) {
          missionsManager = widget.missionsManager;
        }

        if (missionsManager == null) {
          return const Center(
            child: Text(
              'Missions not available',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          );
        }

        if (!missionsManager.isInitialized) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFffc107)),
            ),
          );
        }

        final missions = missionsManager.dailyMissions;

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
                  size: screenSize.width > 600 ? 80 : 60,
                  color: Colors.white54,
                ),
                const SizedBox(height: 16),
                Text(
                  'No missions available\nCheck back tomorrow!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: screenSize.width > 600 ? 20 : 16,
                  ),
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
                child: PremiumMissionCard(
                  mission: mission,
                  onClaimReward: () => _claimReward(context, mission.id),
                  screenSize: screenSize,
                  isClaiming: _claimingMissions.contains(mission.id),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAchievements(BuildContext context, Size screenSize) {
    return Builder(
      builder: (context) {
        // Try to get AchievementsManager from Provider first, fallback to passed parameter
        AchievementsManager? achievementsManager;
        try {
          achievementsManager = context.watch<AchievementsManager>();
        } catch (e) {
          achievementsManager = widget.achievementsManager;
        }

        if (achievementsManager == null) {
          return const Center(
            child: Text(
              'Achievements not available',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          );
        }

        if (!achievementsManager.isInitialized) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFffc107)),
            ),
          );
        }

        final achievements = achievementsManager.visibleAchievements;
        if (achievements.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events,
                  size: screenSize.width > 600 ? 80 : 60,
                  color: const Color(0xFFffc107),
                ),
                const SizedBox(height: 16),
                Text(
                  'No achievements available\nCheck back later!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: screenSize.width > 600 ? 20 : 16,
                  ),
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
              (achievement) => SlideTransition(
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
                child: PremiumAchievementCard(
                  achievement: achievement,
                  onClaimReward: () =>
                      _claimAchievementReward(context, achievement.id),
                  screenSize: screenSize,
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

  Widget _buildPremiumButton({
    required VoidCallback onTap,
    required Widget child,
    required Gradient gradient,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }

  // Removed unused _refreshMissions method
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
    final isTablet = screenSize.width > 600;
    final isLargePhone = screenSize.width > 400;
    final isSmallPhone = screenSize.width < 360;
    // Increased card heights for better content fit and engagement
    final cardHeight = isTablet
        ? 150.0
        : (isLargePhone ? 135.0 : (isSmallPhone ? 125.0 : 120.0));

    // Get mission-specific styling
    final missionStyle = _getMissionStyle(mission.type);

    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 20 : 16),
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
              padding: EdgeInsets.all(isTablet ? 20 : (isLargePhone ? 16 : 14)),
              child: Column(
                children: [
                  // Top row with icon, details, and rewards
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        // Mission icon - Larger and more engaging
                        Container(
                          width: isTablet ? 60 : (isLargePhone ? 52 : 48),
                          height: isTablet ? 60 : (isLargePhone ? 52 : 48),
                          decoration: BoxDecoration(
                            color: missionStyle.iconBackgroundColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Mission3DIcon(
                            iconType: MissionIconMapper.getIconForMissionType(
                              mission.type.toString().split('.').last,
                            ),
                            size: isTablet ? 32 : (isLargePhone ? 28 : 26),
                            // Remove tintColor to show original icon colors
                          ),
                        ),

                        SizedBox(width: isTablet ? 18 : 14),

                        // Mission details - Bigger and bolder text
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                mission.title,
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
                              SizedBox(height: isTablet ? 4 : 3),
                              Text(
                                mission.description,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: isTablet
                                      ? 13
                                      : (isLargePhone ? 12 : 11),
                                  fontWeight: FontWeight.w600, // Bolder
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Coin reward - Larger and more prominent
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 14 : 12,
                            vertical: isTablet ? 8 : 7,
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.monetization_on,
                                color: Colors.white,
                                size: isTablet
                                    ? 20
                                    : (isLargePhone ? 18 : 16), // Larger icon
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${mission.reward}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isTablet
                                      ? 16
                                      : (isLargePhone ? 14 : 13), // Larger text
                                  fontWeight: FontWeight.w900, // Extra bold
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
                      ],
                    ),
                  ),

                  // Bottom row with progress or claim button (centered)
                  Expanded(
                    flex: 2,
                    child: Container(
                      alignment: Alignment.center,
                      child: mission.completed && !mission.claimed
                          ?
                            // Claim button for completed missions
                            ElevatedButton(
                              onPressed: isClaiming ? null : onClaimReward,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isClaiming
                                    ? Colors.grey
                                    : const Color(0xFF4caf50),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 24 : 20,
                                  vertical: isTablet ? 10 : 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                elevation: isClaiming ? 2 : 6,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isClaiming)
                                    SizedBox(
                                      width: isTablet ? 18 : 16,
                                      height: isTablet ? 18 : 16,
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
                                      size: isTablet ? 18 : 16,
                                    ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isClaiming ? 'CLAIMING...' : 'CLAIM REWARD',
                                    style: TextStyle(
                                      fontSize: isTablet ? 14 : 12,
                                      fontWeight: FontWeight.w900, // Extra bold
                                    ),
                                  ),
                                ],
                              ),
                            )
                          :
                            // Progress indicator for incomplete missions
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet
                                    ? 18
                                    : (isLargePhone ? 16 : 14),
                                vertical: isTablet ? 8 : (isLargePhone ? 6 : 5),
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                'Progress: ${mission.progress}/${mission.target}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isTablet
                                      ? 13
                                      : (isLargePhone ? 12 : 11),
                                  fontWeight: FontWeight.w700, // Bolder
                                ),
                              ),
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
          icon: Icons.monetization_on,
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
    // Increased card heights for better content fit and engagement
    final cardHeight = isTablet
        ? 140.0
        : (isLargePhone ? 125.0 : (isSmallPhone ? 115.0 : 110.0));

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
            // Rarity indicator stripe
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 6,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      achievementStyle.rarityColor,
                      achievementStyle.rarityColor.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
            ),

            // Subtle highlight effect
            Positioned(
              top: 0,
              left: 6,
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
              padding: EdgeInsets.all(isTablet ? 20 : (isLargePhone ? 16 : 14)),
              child: Column(
                children: [
                  // Top row with icon, details, and rewards
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        // Achievement icon - Larger and more engaging
                        Container(
                          width: isTablet ? 55 : (isLargePhone ? 48 : 44),
                          height: isTablet ? 55 : (isLargePhone ? 48 : 44),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                achievementStyle.rarityColor,
                                achievementStyle.rarityColor.withValues(
                                  alpha: 0.8,
                                ),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
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
                            size: isTablet ? 28 : (isLargePhone ? 25 : 23),
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
                                      ? 16
                                      : (isLargePhone ? 14 : 13),
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
                                      ? 12
                                      : (isLargePhone ? 11 : 10),
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
                                    ? 16
                                    : (isLargePhone ? 14 : 12),
                                vertical: isTablet ? 8 : (isLargePhone ? 7 : 6),
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
                                  Icon(
                                    Icons.monetization_on,
                                    color: Colors.white,
                                    size: isTablet
                                        ? 16
                                        : (isLargePhone ? 14 : 13),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${achievement.coinReward}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isTablet
                                          ? 13
                                          : (isLargePhone ? 12 : 11),
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
                                  horizontal: isTablet ? 10 : 8,
                                  vertical: isTablet ? 6 : 5,
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
                                          ? 14
                                          : (isLargePhone ? 12 : 11),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${achievement.gemReward}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isTablet
                                            ? 13
                                            : (isLargePhone ? 12 : 11),
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
                              horizontal: isTablet ? 14 : 12,
                              vertical: isTablet ? 6 : 5,
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
                                    ? 12
                                    : (isLargePhone ? 11 : 10),
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
          horizontal: isTablet ? 10 : (isLargePhone ? 8 : 6),
          vertical: isTablet ? 5 : (isLargePhone ? 4 : 3),
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

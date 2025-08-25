/// 🎯 Daily Missions Screen - Now with adaptive missions and achievements
library;
import 'package:flutter/material.dart';
import '../../game/systems/missions_manager.dart';
import '../../game/systems/achievements_manager.dart';
import '../../game/systems/inventory_manager.dart';

class DailyMissionsScreen extends StatefulWidget {
  const DailyMissionsScreen({super.key});

  @override
  State<DailyMissionsScreen> createState() => _DailyMissionsScreenState();
}

class _DailyMissionsScreenState extends State<DailyMissionsScreen> with TickerProviderStateMixin {
  final MissionsManager _missionsManager = MissionsManager();
  final AchievementsManager _achievementsManager = AchievementsManager();
  final InventoryManager _inventory = InventoryManager();
  late TabController _tabController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeManagers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeManagers() async {
    await _missionsManager.initialize();
    await _achievementsManager.initialize();
    await _inventory.initialize();
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A237E), // Deep blue
              Color(0xFF3949AB), // Lighter blue
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with tabs
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Expanded(
                          child: Text(
                            'MISSIONS & ACHIEVEMENTS',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: _refreshMissions,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Tab bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white70,
                        tabs: const [
                          Tab(text: 'Daily Missions'),
                          Tab(text: 'Achievements'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMissionsTab(),
                    _buildAchievementsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build daily missions tab
  Widget _buildMissionsTab() {
    return ListenableBuilder(
      listenable: _missionsManager,
      builder: (context, child) {
        final missions = _missionsManager.dailyMissions;
        
        if (missions.isEmpty) {
          return const Center(
            child: Text(
              'No missions available',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          );
        }

        return Column(
          children: [
            // Progress summary
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'Completed',
                    '${missions.where((m) => m.completed).length}/${missions.length}',
                    Icons.check_circle,
                  ),
                  _buildStatItem(
                    'Progress',
                    '${(_missionsManager.dailyCompletionPercentage * 100).toInt()}%',
                    Icons.trending_up,
                  ),
                  _buildStatItem(
                    'Rewards',
                    '${_missionsManager.totalRewardsEarnedToday}',
                    Icons.monetization_on,
                  ),
                ],
              ),
            ),
            
            // Missions list
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ListView.builder(
                  itemCount: missions.length,
                  itemBuilder: (context, index) {
                    return _buildMissionCard(missions[index]);
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Build achievements tab
  Widget _buildAchievementsTab() {
    return ListenableBuilder(
      listenable: _achievementsManager,
      builder: (context, child) {
        final achievements = _achievementsManager.visibleAchievements;
        
        return Column(
          children: [
            // Achievement summary
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'Unlocked',
                    '${_achievementsManager.totalUnlocked}/${_achievementsManager.totalAchievements}',
                    Icons.emoji_events,
                  ),
                  _buildStatItem(
                    'Progress',
                    '${(_achievementsManager.completionPercentage * 100).toInt()}%',
                    Icons.bar_chart,
                  ),
                  _buildStatItem(
                    'Recent',
                    '${_achievementsManager.recentlyUnlocked.length}',
                    Icons.new_releases,
                  ),
                ],
              ),
            ),
            
            // Achievements list
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ListView.builder(
                  itemCount: achievements.length,
                  itemBuilder: (context, index) {
                    return _buildAchievementCard(achievements[index]);
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Build stat item for summaries
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  /// Refresh missions manually
  Future<void> _refreshMissions() async {
    await _missionsManager.forceRefreshMissions();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Missions refreshed!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Build mission card with adaptive design
  Widget _buildMissionCard(Mission mission) {
    final progressPercent = (mission.progress / mission.target).clamp(0.0, 1.0);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: mission.completed
            ? Border.all(color: const Color(0xFF32CD32), width: 2)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Mission type icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getMissionTypeColor(mission.type).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getMissionTypeIcon(mission.type),
                    color: _getMissionTypeColor(mission.type),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mission.title,
                        style: TextStyle(
                          color: mission.completed ? const Color(0xFF32CD32) : Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mission.description,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Reward
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${mission.reward}',
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress: ${mission.progress}/${mission.target}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${(progressPercent * 100).toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: progressPercent,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: mission.completed
                              ? [const Color(0xFF32CD32), const Color(0xFF228B22)]
                              : [const Color(0xFF4A90E2), const Color(0xFF357ABD)],
                        ),
                        borderRadius: BorderRadius.circular(3),
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

  /// Build achievement card
  Widget _buildAchievementCard(Achievement achievement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: achievement.unlocked
            ? Border.all(color: _getAchievementRarityColor(achievement.rarity), width: 2)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Achievement icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _getAchievementRarityColor(achievement.rarity).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getAchievementCategoryIcon(achievement.category),
                color: _getAchievementRarityColor(achievement.rarity),
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          achievement.title,
                          style: TextStyle(
                            color: achievement.unlocked ? Colors.white : Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getAchievementRarityColor(achievement.rarity).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          achievement.rarity.name.toUpperCase(),
                          style: TextStyle(
                            color: _getAchievementRarityColor(achievement.rarity),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    achievement.description,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Progress bar for achievements
                  if (!achievement.unlocked) ...[
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: achievement.progressPercentage,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            valueColor: AlwaysStoppedAnimation(
                              _getAchievementRarityColor(achievement.rarity),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${achievement.progress}/${achievement.target}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFF32CD32), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Unlocked ${_formatDate(achievement.unlockedAt!)}',
                          style: const TextStyle(
                            color: Color(0xFF32CD32),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  // Rewards
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (achievement.coinReward > 0) ...[
                        const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${achievement.coinReward}',
                          style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                      if (achievement.gemReward > 0) ...[
                        const SizedBox(width: 12),
                        const Icon(Icons.diamond, color: Color(0xFF64B5F6), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${achievement.gemReward}',
                          style: const TextStyle(
                            color: Color(0xFF64B5F6),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get mission type icon
  IconData _getMissionTypeIcon(MissionType type) {
    switch (type) {
      case MissionType.playGames:
        return Icons.play_arrow;
      case MissionType.reachScore:
        return Icons.trending_up;
      case MissionType.maintainStreak:
        return Icons.whatshot;
      case MissionType.useContinue:
        return Icons.refresh;
      case MissionType.changeNickname:
        return Icons.edit;
      case MissionType.collectCoins:
        return Icons.monetization_on;
      case MissionType.surviveTime:
        return Icons.timer;
    }
  }

  /// Get mission type color
  Color _getMissionTypeColor(MissionType type) {
    switch (type) {
      case MissionType.playGames:
        return const Color(0xFF4CAF50);
      case MissionType.reachScore:
        return const Color(0xFF2196F3);
      case MissionType.maintainStreak:
        return const Color(0xFFFF5722);
      case MissionType.useContinue:
        return const Color(0xFF9C27B0);
      case MissionType.changeNickname:
        return const Color(0xFF607D8B);
      case MissionType.collectCoins:
        return const Color(0xFFFFD700);
      case MissionType.surviveTime:
        return const Color(0xFF795548);
    }
  }

  /// Get achievement category icon
  IconData _getAchievementCategoryIcon(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.score:
        return Icons.emoji_events;
      case AchievementCategory.streak:
        return Icons.whatshot;
      case AchievementCategory.collection:
        return Icons.collections;
      case AchievementCategory.survival:
        return Icons.timer;
      case AchievementCategory.special:
        return Icons.star;
      case AchievementCategory.mastery:
        return Icons.military_tech;
    }
  }

  /// Get achievement rarity color
  Color _getAchievementRarityColor(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.bronze:
        return const Color(0xFFCD7F32);
      case AchievementRarity.silver:
        return const Color(0xFFC0C0C0);
      case AchievementRarity.gold:
        return const Color(0xFFFFD700);
      case AchievementRarity.platinum:
        return const Color(0xFFE5E4E2);
      case AchievementRarity.diamond:
        return const Color(0xFF64B5F6);
    }
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }
}
/// 📊 Profile Stats Grid
/// 
/// 2x2 grid displaying key player statistics.
/// Each stat is displayed in a card with icon, label, and value.
library;

import 'package:flutter/material.dart';
import '../../utils/responsive_config.dart';
import 'profile_data_aggregator.dart';
import '../../layouts/homepage_layout.dart';
import '../../widgets/homepage_footer_navigator.dart';
import '../../screens/daily_missions_screen.dart';
import '../../screens/tournament_hub_screen.dart';
import '../../../game/systems/missions_manager.dart';
import '../../../game/systems/achievements_manager.dart';
import '../../../game/systems/monetization_manager.dart';

/// Stats Grid Component
/// 
/// Displays 4 key statistics in a 2x2 grid:
/// - High Score
/// - Missions Completed
/// - Achievements Completed
/// - Tournaments Won
class ProfileStatsGrid extends StatelessWidget {
  final ProfileData? profileData;
  
  const ProfileStatsGrid({
    super.key,
    this.profileData,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final isTablet = ResponsiveConfig.isTablet(screenSize);
    final isLargeTablet = ResponsiveConfig.isLargeTablet(screenSize);
    
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: ResponsiveConfig.responsivePadding(12.0, screenSize),
      crossAxisSpacing: ResponsiveConfig.responsivePadding(12.0, screenSize),
      childAspectRatio: isLargeTablet ? 1.3 : isTablet ? 1.2 : 1.1,
      children: [
        _StatCard(
          iconPath: 'assets/images/icons/missions/parachut_icon.png', // ✅ Custom icon
          label: 'High Score',
          value: _formatNumber(profileData?.highestScore ?? 0),
          color: Colors.amber,
          screenSize: screenSize,
          onTap: () => _navigateToTournaments(context),
        ),
        _StatCard(
          iconPath: 'assets/images/icons/missions/target_icon.png', // ✅ Custom icon
          label: 'Missions',
          value: '${profileData?.missionsCompleted ?? 0}',
          color: Colors.blue,
          screenSize: screenSize,
          onTap: () => _navigateToMissions(context),
        ),
        _StatCard(
          iconPath: 'assets/images/icons/missions/gold_star_badge_icon.png', // ✅ Custom icon
          label: 'Achievements',
          value: '${profileData?.achievementsCompleted ?? 0}',
          color: Colors.purple,
          screenSize: screenSize,
          onTap: () => _navigateToAchievements(context),
        ),
        _StatCard(
          iconPath: 'assets/images/icons/missions/gold_trophy.png', // ✅ Custom icon
          label: 'Tournaments',
          value: '${profileData?.tournamentsWon ?? 0}',
          color: Colors.red,
          screenSize: screenSize,
          onTap: () => _navigateToTournaments(context),
        ),
      ],
    );
  }
  
  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
  
  void _navigateToMissions(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomepageLayout(
          activeSection: FooterNavigatorSection.missions,
          child: DailyMissionsScreen(
            missionsManager: MissionsManager(),
            achievementsManager: AchievementsManager(),
          ),
        ),
      ),
    );
  }
  
  void _navigateToAchievements(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomepageLayout(
          activeSection: FooterNavigatorSection.missions,
          child: DailyMissionsScreen(
            missionsManager: MissionsManager(),
            achievementsManager: AchievementsManager(),
            initialTabIndex: 1, // Achievements tab
          ),
        ),
      ),
    );
  }
  
  void _navigateToTournaments(BuildContext context) {
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
}

/// Individual Stat Card
class _StatCard extends StatelessWidget {
  final String? iconPath; // ✅ Custom icon image path
  final String label;
  final String value;
  final Color color;
  final Size screenSize;
  final VoidCallback? onTap;
  
  const _StatCard({
    this.iconPath, // ✅ Custom icon image path
    required this.label,
    required this.value,
    required this.color,
    required this.screenSize,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveConfig.isTablet(screenSize);
    final isLargeTablet = ResponsiveConfig.isLargeTablet(screenSize);
    
    Widget content = Container(
      decoration: BoxDecoration(
        color: Colors.transparent, // ✅ Transparent background
        borderRadius: BorderRadius.circular(ResponsiveConfig.responsiveSize(12.0, screenSize)),
        border: Border.all(
          color: Colors.transparent, // ✅ Transparent frame
          width: 0, // No border
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ✅ Removed blur circle container - icons now directly displayed
          iconPath != null
              ? Image.asset(
                  iconPath!,
                  width: ResponsiveConfig.responsiveIconSize(
                    isLargeTablet ? 80.0 : isTablet ? 72.0 : 64.0, // ✅ Even bigger icons
                    screenSize,
                  ),
                  height: ResponsiveConfig.responsiveIconSize(
                    isLargeTablet ? 80.0 : isTablet ? 72.0 : 64.0, // ✅ Even bigger icons
                    screenSize,
                  ),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to icon if image fails to load
                    return Icon(
                      Icons.star,
                      color: color,
                      size: ResponsiveConfig.responsiveIconSize(
                        isLargeTablet ? 80.0 : isTablet ? 72.0 : 64.0, // ✅ Even bigger icons
                        screenSize,
                      ),
                    );
                  },
                )
              : Icon(
                  Icons.star,
                  color: color,
                  size: ResponsiveConfig.responsiveIconSize(
                    isLargeTablet ? 80.0 : isTablet ? 72.0 : 64.0, // ✅ Even bigger icons
                    screenSize,
                  ),
                ),
          SizedBox(height: ResponsiveConfig.responsivePadding(8.0, screenSize)),
          Text(
            value,
            style: TextStyle(
              fontSize: ResponsiveConfig.responsiveFontSize(
                isLargeTablet ? 24.0 : isTablet ? 20.0 : 18.0,
                screenSize,
                context,
              ),
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade900,
            ),
          ),
          SizedBox(height: ResponsiveConfig.responsivePadding(4.0, screenSize)),
          Text(
            label,
            style: TextStyle(
              fontSize: ResponsiveConfig.responsiveFontSize(
                isLargeTablet ? 22.0 : isTablet ? 20.0 : 18.0, // ✅ Even bigger labels
                screenSize,
                context,
              ),
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
    
    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }
    
    return content;
  }
}


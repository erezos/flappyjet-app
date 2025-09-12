/// 📊 Profile Stats Row Component - High Score + Hottest Streak display
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_responsive_config.dart';

class ProfileStatsRow extends StatelessWidget {
  const ProfileStatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // High Score Widget
        HighScoreWidget(),
        // Hottest Streak Widget
        HottestStreakWidget(),
      ],
    );
  }
}

/// High Score Widget using the retro gaming device icon
class HighScoreWidget extends StatelessWidget {
  const HighScoreWidget({super.key});

  Future<int> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('best_score') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final config = context.profileConfig;

    return FutureBuilder<int>(
      future: _loadHighScore(),
      builder: (context, snapshot) {
        final value = snapshot.data ?? 0;
        return SizedBox(
          height: config.statsWidgetHeight,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background icon
              Image.asset(
                'assets/images/icons/high_score.png',
                height: config.statsWidgetHeight,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to old design if image fails to load
                  return _buildFallbackHighScore(context, config, value);
                },
              ),
              // Score number positioned on the dark display area
              Positioned(
                top:
                    45, // Adjust this to position the number in the dark display area
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  child: Text(
                    '$value',
                    style: TextStyle(
                      color: Colors.white, // White color for better visibility
                      fontSize: config.getResponsiveFontSize(18),
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace', // Retro monospace font
                      shadows: const [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFallbackHighScore(
    BuildContext context,
    ProfileResponsiveConfig config,
    int value,
  ) {
    return Container(
      padding: config.getResponsivePadding(const EdgeInsets.all(16)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.2),
            Colors.white.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.emoji_events,
            color: Colors.white,
            size: config.getResponsiveIconSize(24),
          ),
          const SizedBox(height: 8),
          Text(
            'HIGH SCORE',
            style: TextStyle(
              color: Colors.white70,
              fontSize: config.getResponsiveFontSize(10),
            ),
          ),
          Text(
            '$value',
            style: TextStyle(
              color: Colors.white,
              fontSize: config.getResponsiveFontSize(24),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Hottest Streak Widget using the radar device icon
class HottestStreakWidget extends StatelessWidget {
  const HottestStreakWidget({super.key});

  Future<int> _loadHottestStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('best_streak') ?? (prefs.getInt('best_score') ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    final config = context.profileConfig;

    return FutureBuilder<int>(
      future: _loadHottestStreak(),
      builder: (context, snapshot) {
        final value = snapshot.data ?? 0;
        return SizedBox(
          height:
              config.statsWidgetHeight +
              10, // Slightly taller for the hottest streak
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background icon
              Image.asset(
                'assets/images/icons/hottest_streak.png',
                height: config.statsWidgetHeight + 10,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to old design if image fails to load
                  return _buildFallbackHottestStreak(context, config, value);
                },
              ),
              // Streak number positioned on the radar display
              Positioned(
                top: 45, // Aligned with high score number
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(
                      alpha: 0.3,
                    ), // Semi-transparent background
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$value',
                    style: TextStyle(
                      color: Colors.white, // White color for better visibility
                      fontSize: config.getResponsiveFontSize(18),
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace', // Retro monospace font
                      shadows: const [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFallbackHottestStreak(
    BuildContext context,
    ProfileResponsiveConfig config,
    int value,
  ) {
    return Container(
      padding: config.getResponsivePadding(const EdgeInsets.all(16)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.2),
            Colors.white.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department,
            color: Colors.white,
            size: config.getResponsiveIconSize(24),
          ),
          const SizedBox(height: 8),
          Text(
            'HOTTEST STREAK',
            style: TextStyle(
              color: Colors.white70,
              fontSize: config.getResponsiveFontSize(10),
            ),
          ),
          Text(
            '$value',
            style: TextStyle(
              color: Colors.white,
              fontSize: config.getResponsiveFontSize(24),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

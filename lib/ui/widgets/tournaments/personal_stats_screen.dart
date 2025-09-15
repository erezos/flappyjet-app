/// 👤 Personal Tournament Stats Screen
/// Shows player's tournament history, achievements, and statistics
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PersonalStatsScreen extends StatefulWidget {
  const PersonalStatsScreen({super.key});

  @override
  State<PersonalStatsScreen> createState() => _PersonalStatsScreenState();
}

class _PersonalStatsScreenState extends State<PersonalStatsScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Player Stats Overview
            _buildStatsOverview(),

            const SizedBox(height: 20),

            // Tournament History
            _buildTournamentHistory(),

            const SizedBox(height: 20),

            // Achievements
            _buildAchievements(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF2D1B69), Color(0xFF11998E)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                  ),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Your Tournament Stats',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.3, end: 0),

          const SizedBox(height: 20),

          // Stats grid
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.emoji_events,
                  label: 'Tournaments\nJoined',
                  value: '3',
                  color: const Color(0xFFFFD700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.workspace_premium,
                  label: 'Best\nRank',
                  value: '2nd',
                  color: const Color(0xFFC0C0C0),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.monetization_on,
                  label: 'Total Coins\nWon',
                  value: '750',
                  color: const Color(0xFF4ECDC4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.trending_up,
                  label: 'Win\nRate',
                  value: '67%',
                  color: const Color(0xFF95E1D3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Color.fromRGBO(255, 255, 255, 0.1),
            border: Border.all(
              color: Color.fromRGBO((color.r * 255.0).round() & 0xff, (color.g * 255.0).round() & 0xff, (color.b * 255.0).round() & 0xff, 0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Color.fromRGBO(
                    (color.r * 255.0).round() & 0xff,
                    (color.g * 255.0).round() & 0xff,
                    (color.b * 255.0).round() & 0xff,
                    0.2,
                  ),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Color.fromRGBO(255, 255, 255, 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 800.ms, delay: 400.ms)
        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0));
  }

  Widget _buildTournamentHistory() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF2C3E50), Color(0xFF3498DB)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3498DB), Color(0xFF2980B9)],
                  ),
                ),
                child: const Icon(Icons.history, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Recent Tournaments',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.3, end: 0),

          const SizedBox(height: 16),

          // Tournament history list
          _buildTournamentHistoryItem(
            name: 'Weekly Championship Dec 16-22',
            rank: 2,
            prize: 500,
            participants: 127,
          ),
          const SizedBox(height: 12),
          _buildTournamentHistoryItem(
            name: 'Weekly Championship Dec 9-15',
            rank: 5,
            prize: 0,
            participants: 98,
          ),
          const SizedBox(height: 12),
          _buildTournamentHistoryItem(
            name: 'Weekly Championship Dec 2-8',
            rank: 3,
            prize: 250,
            participants: 156,
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentHistoryItem({
    required String name,
    required int rank,
    required int prize,
    required int participants,
  }) {
    Color rankColor;
    String rankEmoji;

    switch (rank) {
      case 1:
        rankColor = const Color(0xFFFFD700);
        rankEmoji = '🥇';
        break;
      case 2:
        rankColor = const Color(0xFFC0C0C0);
        rankEmoji = '🥈';
        break;
      case 3:
        rankColor = const Color(0xFFCD7F32);
        rankEmoji = '🥉';
        break;
      default:
        rankColor = const Color(0xFF95E1D3);
        rankEmoji = '🏅';
    }

    return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Color.fromRGBO(255, 255, 255, 0.1),
            border: Border.all(
              color: Color.fromRGBO(
                (rankColor.r * 255.0).round() & 0xff,
                (rankColor.g * 255.0).round() & 0xff,
                (rankColor.b * 255.0).round() & 0xff,
                0.3,
              ),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Rank
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Color.fromRGBO(
                    (rankColor.r * 255.0).round() & 0xff,
                    (rankColor.g * 255.0).round() & 0xff,
                    (rankColor.b * 255.0).round() & 0xff,
                    0.2,
                  ),
                ),
                child: Center(
                  child: Text(rankEmoji, style: const TextStyle(fontSize: 20)),
                ),
              ),

              const SizedBox(width: 12),

              // Tournament info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rank $rank of $participants players',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color.fromRGBO(255, 255, 255, 0.7),
                      ),
                    ),
                  ],
                ),
              ),

              // Prize
              if (prize > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Color.fromRGBO(78, 205, 196, 0.2),
                  ),
                  child: Text(
                    '+$prize coins',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4ECDC4),
                    ),
                  ),
                ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 600.ms, delay: 200.ms)
        .slideX(begin: 0.3, end: 0);
  }

  Widget _buildAchievements() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF8E44AD), Color(0xFF9B59B6)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9B59B6), Color(0xFF8E44AD)],
                  ),
                ),
                child: const Icon(
                  Icons.military_tech,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Tournament Achievements',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.3, end: 0),

          const SizedBox(height: 16),

          // Achievement grid
          Row(
            children: [
              Expanded(
                child: _buildAchievementCard(
                  icon: '🏆',
                  title: 'First Victory',
                  description: 'Win your first tournament',
                  unlocked: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAchievementCard(
                  icon: '💰',
                  title: 'Coin Collector',
                  description: 'Earn 1000 coins from tournaments',
                  unlocked: false,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildAchievementCard(
                  icon: '🔥',
                  title: 'Hot Streak',
                  description: 'Place top 3 in 3 consecutive tournaments',
                  unlocked: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAchievementCard(
                  icon: '👑',
                  title: 'Champion',
                  description: 'Win 5 tournaments',
                  unlocked: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard({
    required String icon,
    required String title,
    required String description,
    required bool unlocked,
  }) {
    return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: unlocked
                ? Color.fromRGBO(255, 255, 255, 0.2)
                : Color.fromRGBO(255, 255, 255, 0.05),
            border: Border.all(
              color: unlocked
                  ? Color.fromRGBO(255, 215, 0, 0.5)
                  : Color.fromRGBO(255, 255, 255, 0.1),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                icon,
                style: TextStyle(
                  fontSize: 24,
                  color: unlocked ? null : Color.fromRGBO(255, 255, 255, 0.3),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: unlocked
                      ? Colors.white
                      : Color.fromRGBO(255, 255, 255, 0.5),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 9,
                  color: unlocked
                      ? Color.fromRGBO(255, 255, 255, 0.7)
                      : Color.fromRGBO(255, 255, 255, 0.3),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 800.ms, delay: 600.ms)
        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0));
  }
}

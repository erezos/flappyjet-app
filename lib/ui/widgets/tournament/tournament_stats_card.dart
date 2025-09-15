import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../models/tournament.dart';

/// Tournament statistics display card
class TournamentStatsCard extends StatelessWidget {
  final Tournament? tournament;

  const TournamentStatsCard({super.key, required this.tournament});

  @override
  Widget build(BuildContext context) {
    if (tournament == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C3E50), Color(0xFF3498DB)],
        ),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(52, 152, 219, 0.3),
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
                child: const Icon(
                  Icons.analytics,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Tournament Stats',
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
                child: _buildStatItem(
                  icon: Icons.people,
                  label: 'Participants',
                  value: '${tournament!.participantCount}',
                  color: const Color(0xFFE74C3C),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.emoji_events,
                  label: 'Prize Positions',
                  value: '${tournament!.prizePositions}',
                  color: const Color(0xFFF39C12),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.schedule,
                  label: 'Duration',
                  value: _getTournamentDuration(),
                  color: const Color(0xFF27AE60),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.trending_up,
                  label: 'Status',
                  value: _getStatusText(),
                  color: const Color(0xFF9B59B6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
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
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Color.fromRGBO(255, 255, 255, 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 800.ms, delay: 400.ms)
        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0))
        .shimmer(duration: 2000.ms, delay: 1200.ms);
  }

  String _getTournamentDuration() {
    final duration = tournament!.endDate.difference(tournament!.startDate);
    if (duration.inDays > 0) {
      return '${duration.inDays}d';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  String _getStatusText() {
    switch (tournament!.status) {
      case TournamentStatus.active:
        return 'Live';
      case TournamentStatus.upcoming:
        return 'Soon';
      case TournamentStatus.registration:
        return 'Open';
      case TournamentStatus.ended:
        return 'Ended';
      default:
        return 'Unknown';
    }
  }
}

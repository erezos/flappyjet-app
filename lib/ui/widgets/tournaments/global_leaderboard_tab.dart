/// 🌍 Global Leaderboard Tab - Shows worldwide rankings
/// Replaces the old "Global" section from lower navigation
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../game/systems/global_leaderboard_service.dart';
import '../../../game/systems/leaderboard_manager.dart';

class GlobalLeaderboardTab extends StatefulWidget {
  const GlobalLeaderboardTab({super.key});

  @override
  State<GlobalLeaderboardTab> createState() => _GlobalLeaderboardTabState();
}

class _GlobalLeaderboardTabState extends State<GlobalLeaderboardTab> {
  final GlobalLeaderboardService _globalService = GlobalLeaderboardService();
  final LeaderboardManager _leaderboardManager = LeaderboardManager();
  bool _isLoading = true;
  List<Map<String, dynamic>> _globalScores = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGlobalLeaderboard();
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _loadGlobalLeaderboard() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Initialize services if needed
      if (!_globalService.isInitialized) {
        await _globalService.initialize();
      }
      if (!_leaderboardManager.isInitialized) {
        await _leaderboardManager.initialize();
      }

      // Load global scores
      final entries = _globalService.globalScores;
      final scores = entries
          .take(50)
          .map(
            (entry) => {
              'playerName': entry.playerName,
              'score': entry.score,
              'theme': entry.theme,
              'jetSkin': entry.jetSkin,
              'timeAgo': _formatTimeAgo(entry.achievedAt),
            },
          )
          .toList();

      if (mounted) {
        setState(() {
          _globalScores = scores;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load global leaderboard: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
        ),
      ),
      child: Column(
        children: [
          // Header with refresh button
          _buildHeader(),

          // Content
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _error != null
                ? _buildErrorState()
                : _buildLeaderboardContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '🌍 Global Rankings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: _loadGlobalLeaderboard,
            icon: const Icon(Icons.refresh, color: Colors.white70),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.3);
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
          ),
          SizedBox(height: 16),
          Text(
            'Loading global rankings...',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadGlobalLeaderboard,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4ECDC4),
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardContent() {
    if (_globalScores.isEmpty) {
      return const Center(
        child: Text(
          'No global scores yet.\nBe the first to set a record!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 18),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _globalScores.length,
      itemBuilder: (context, index) {
        final score = _globalScores[index];
        return _buildLeaderboardItem(score, index + 1);
      },
    );
  }

  Widget _buildLeaderboardItem(Map<String, dynamic> score, int rank) {
    final playerName = score['playerName'] ?? 'Anonymous';
    final playerScore = score['score'] ?? 0;
    final theme = score['theme'] ?? 'Unknown';
    final jetSkin = score['jetSkin'] ?? 'jets/green_lightning.png';
    final timeAgo = score['timeAgo'] ?? 'Unknown';

    // Determine rank styling
    Color rankColor;
    Color backgroundColor;
    IconData? rankIcon;

    if (rank == 1) {
      rankColor = const Color(0xFFFFD700); // Gold
      backgroundColor = const Color(0xFF2D1B69);
      rankIcon = Icons.emoji_events;
    } else if (rank == 2) {
      rankColor = const Color(0xFFC0C0C0); // Silver
      backgroundColor = const Color(0xFF1A1A2E);
      rankIcon = Icons.workspace_premium;
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32); // Bronze
      backgroundColor = const Color(0xFF16213E);
      rankIcon = Icons.military_tech;
    } else {
      rankColor = Colors.white70;
      backgroundColor = const Color(0xFF0F3460);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: rank <= 3 ? Border.all(color: rankColor, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: rankIcon != null
                  ? Icon(rankIcon, color: rankColor, size: 20)
                  : Text(
                      '$rank',
                      style: TextStyle(
                        color: rankColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // Player avatar (jet skin)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white30, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                'assets/images/$jetSkin',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.blue.shade300,
                    child: const Icon(
                      Icons.flight,
                      color: Colors.white,
                      size: 20,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Player info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  playerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '$theme • $timeAgo',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),

          // Score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF4ECDC4).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$playerScore',
              style: const TextStyle(
                color: Color(0xFF4ECDC4),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (rank * 100).ms).slideX(begin: 0.3);
  }
}

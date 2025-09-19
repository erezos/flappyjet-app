/// 📱 Personal Scores Tab - Shows recent tournament scores from backend
/// Displays player's recent game sessions and tournament scores
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../game/systems/leaderboard_manager.dart';
import '../../../game/systems/player_identity_manager.dart';
import '../../../core/network/network_manager.dart';

class PersonalScoresTab extends StatefulWidget {
  const PersonalScoresTab({super.key});

  @override
  State<PersonalScoresTab> createState() => _PersonalScoresTabState();
}

class _PersonalScoresTabState extends State<PersonalScoresTab> {
  late final LeaderboardManager _leaderboardManager;
  late final PlayerIdentityManager _playerIdentityManager;
  bool _isLoading = true;
  List<LeaderboardEntry> _personalScores = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _playerIdentityManager = PlayerIdentityManager();
    _leaderboardManager = LeaderboardManager();
    _loadPersonalScores();
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

  Future<void> _loadPersonalScores() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Initialize player identity manager if needed
      if (!_playerIdentityManager.isInitialized) {
        await _playerIdentityManager.initialize();
      }

      // Initialize leaderboard manager if needed
      if (!_leaderboardManager.isInitialized) {
        await _leaderboardManager.initialize();
      }

      // Get local scores and filter to current player's scores only
      final currentPlayerName = _playerIdentityManager.playerName;
      final allLocalScores = _leaderboardManager.localScores;
      
      // Filter to current player's scores and limit to top 10
      final playerScores = allLocalScores
          .where((entry) => entry.playerName == currentPlayerName)
          .take(10)
          .toList();

      if (mounted) {
        setState(() {
          _personalScores = playerScores;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load personal scores: $e';
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
          colors: [Color(0xFF0F3460), Color(0xFF16213E), Color(0xFF1A1A2E)],
        ),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(),

          // Content
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _error != null
                ? _buildErrorState()
                : _buildPersonalContent(),
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
            '📱 Recent Scores',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: _loadPersonalScores,
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
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF44A08D)),
          ),
          SizedBox(height: 16),
          Text(
            'Loading your scores...',
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
            onPressed: _loadPersonalScores,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF44A08D),
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalContent() {
    if (_personalScores.isEmpty) {
      return _buildNoScoresState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // Personal scores list only
          _buildScoresList(),
        ],
      ),
    );
  }

  Widget _buildNoScoresState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.flight_takeoff, color: Colors.white70, size: 64),
          const SizedBox(height: 16),
          const Text(
            'No Scores Yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start playing to see your personal scores here!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildScoresList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Top 10 Scores',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(_personalScores.length, (index) {
          final score = _personalScores[index];
          return _buildScoreItem(score, index);
        }),
      ],
    );
  }

  Widget _buildScoreItem(LeaderboardEntry score, int index) {
    final playerScore = score.score;
    final theme = score.theme;
    final timestamp = _formatTimeAgo(score.achievedAt);
    final jetSkin = 'jets/sky_jet.png'; // Default jet skin for local scores
    final isPersonalBest = index == 0; // First score is the personal best

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: isPersonalBest
            ? Border.all(color: const Color(0xFFFFD700), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank indicator
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isPersonalBest 
                  ? const Color(0xFFFFD700).withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: isPersonalBest 
                      ? const Color(0xFFFFD700)
                      : Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Jet skin avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isPersonalBest
                    ? const Color(0xFFFFD700)
                    : Colors.white30,
                width: 2,
              ),
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

          // Score info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Score: $playerScore',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (isPersonalBest) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.emoji_events,
                        color: Color(0xFFFFD700),
                        size: 16,
                      ),
                    ],
                  ],
                ),
                Text(
                  '$theme • $timestamp',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),

          // Rank indicator
          Text(
            '#${index + 1}',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.3);
  }
}

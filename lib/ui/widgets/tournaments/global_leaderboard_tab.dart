/// 🌍 Global Leaderboard Tab - Shows worldwide rankings
/// Replaces the old "Global" section from lower navigation
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../services/railway_leaderboard_service.dart';
import '../../../game/systems/player_identity_manager.dart';

class GlobalLeaderboardTab extends StatefulWidget {
  const GlobalLeaderboardTab({super.key});

  @override
  State<GlobalLeaderboardTab> createState() => _GlobalLeaderboardTabState();
}

class _GlobalLeaderboardTabState extends State<GlobalLeaderboardTab> {
  late final RailwayLeaderboardService _leaderboardService;
  late final PlayerIdentityManager _playerIdentityManager;
  bool _isLoading = true;
  List<LeaderboardEntry> _leaderboard = [];
  LeaderboardEntry? _userPosition;
  String? _error;

  @override
  void initState() {
    super.initState();
    _playerIdentityManager = PlayerIdentityManager();
    _leaderboardService = RailwayLeaderboardService(
      playerIdentityManager: _playerIdentityManager,
    );
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
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _leaderboardService.getGlobalLeaderboard(
        limit: 15,
        includeUserPosition: true,
      );

      if (mounted) {
        if (result.success) {
          debugPrint('🏆 Global Leaderboard: Loaded ${result.leaderboard.length} entries');
          debugPrint('🏆 Global Leaderboard: User position = ${result.userPosition?.rank ?? "null"}');
          setState(() {
            _leaderboard = result.leaderboard;
            _userPosition = result.userPosition;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = result.error ?? 'Failed to load leaderboard';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Network error: $e';
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
            '🏆 Leaderboard',
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
    if (_leaderboard.isEmpty && _userPosition == null) {
      return const Center(
        child: Text(
          'No global scores yet.\nBe the first to set a record!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 18),
        ),
      );
    }

    // Combine top 15 + user position (if not in top 15)
    final displayItems = <LeaderboardEntry>[];
    displayItems.addAll(_leaderboard);
    
    // Add user position if they're not in the top 15
    if (_userPosition != null && 
        !_leaderboard.any((entry) => entry.playerId == _userPosition!.playerId)) {
      debugPrint('🏆 Global Leaderboard: Adding user position card - Rank ${_userPosition!.rank}');
      displayItems.add(_userPosition!);
    } else if (_userPosition != null) {
      debugPrint('🏆 Global Leaderboard: User is in top 15 - Rank ${_userPosition!.rank}');
    } else {
      debugPrint('🏆 Global Leaderboard: No user position data');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: displayItems.length,
      itemBuilder: (context, index) {
        final entry = displayItems[index];
        final isUserEntry = _userPosition != null && 
                           entry.playerId == _userPosition!.playerId;
        final isUserNotInTop15 = isUserEntry && entry.rank > 15;
        
        return Column(
          children: [
            // Add separator before user's position if they're not in top 15
            if (isUserNotInTop15 && index > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Expanded(child: Divider(color: Colors.white30)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Your Position',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: Colors.white30)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            _buildLeaderboardItem(entry, isUserEntry),
          ],
        );
      },
    );
  }

  Widget _buildLeaderboardItem(LeaderboardEntry entry, bool isUserEntry) {
    final rank = entry.rank;
    final playerName = entry.playerName;
    final playerScore = entry.score;
    final theme = entry.theme;
    final jetSkin = entry.jetSkin;
    final timeAgo = _formatTimeAgo(entry.achievedAt);

    // Determine rank styling
    Color rankColor;
    Color backgroundColor;
    IconData? rankIcon;
    Color? borderColor;

    if (isUserEntry) {
      // Highlight user's entry
      borderColor = const Color(0xFF4ECDC4);
      backgroundColor = const Color(0xFF1A2332);
    }

    if (entry.rank == 1) {
      rankColor = const Color(0xFFFFD700); // Gold
      backgroundColor = isUserEntry ? const Color(0xFF3D2B69) : const Color(0xFF2D1B69);
      rankIcon = Icons.emoji_events;
    } else if (entry.rank == 2) {
      rankColor = const Color(0xFFC0C0C0); // Silver
      backgroundColor = isUserEntry ? const Color(0xFF2A2A3E) : const Color(0xFF1A1A2E);
      rankIcon = Icons.workspace_premium;
    } else if (entry.rank == 3) {
      rankColor = const Color(0xFFCD7F32); // Bronze
      backgroundColor = isUserEntry ? const Color(0xFF26314E) : const Color(0xFF16213E);
      rankIcon = Icons.military_tech;
    } else {
      rankColor = Colors.white70;
      backgroundColor = isUserEntry ? const Color(0xFF1F3470) : const Color(0xFF0F3460);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: borderColor != null 
            ? Border.all(color: borderColor, width: 2)
            : (entry.rank <= 3 ? Border.all(color: rankColor, width: 2) : null),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
          if (isUserEntry)
            BoxShadow(
              color: const Color(0xFF4ECDC4).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 0),
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
                      '${entry.rank}',
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
            ).animate().fadeIn(delay: (entry.rank * 100).ms).slideX(begin: 0.3);
  }
}

/// 🏆 Leaderboard Screen
library;
import '../../core/debug_logger.dart';

import 'package:flutter/material.dart';
import '../../game/systems/leaderboard_manager.dart';
import '../../game/systems/global_leaderboard_service.dart';
import '../../services/tournament_service.dart';

class LeaderboardScreen extends StatefulWidget {
  final bool showBackButton;
  final String? customTitle;
  
  const LeaderboardScreen({
    super.key,
    this.showBackButton = true,
    this.customTitle,
  });

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String selectedTab = 'Global';
  final List<String> tabs = ['Global', 'Weekly', 'Local'];
  final LeaderboardManager _leaderboardManager = LeaderboardManager();
  final GlobalLeaderboardService _globalService = GlobalLeaderboardService();
  final TournamentService _tournamentService = TournamentService(
    baseUrl: 'https://flappyjet-backend-production.up.railway.app',
  );
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeLeaderboard();
  }

  Future<void> _initializeLeaderboard() async {
    if (!_leaderboardManager.isInitialized) {
      await _leaderboardManager.initialize();
    }
    if (!_globalService.isInitialized) {
      await _globalService.initialize();
    }
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _tournamentService.dispose();
    super.dispose();
  }

  /// Load weekly tournament leaderboard
  Future<List<Map<String, dynamic>>?> _loadWeeklyTournamentLeaderboard() async {
    try {
      // Get current tournament
      final tournamentResult = await _tournamentService.getCurrentTournament();
      if (!tournamentResult.isSuccess || tournamentResult.data == null) {
        return null;
      }

      final tournament = tournamentResult.data!;
      
      // Get tournament leaderboard
      final leaderboardResult = await _tournamentService.getTournamentLeaderboard(
        tournamentId: tournament.id,
        limit: 50,
      );

      if (leaderboardResult.isSuccess && leaderboardResult.data != null) {
        return leaderboardResult.data!.entries.map((entry) => {
          'playerName': entry.playerName,
          'score': entry.score,
          'rank': entry.rank,
          'totalGames': entry.totalGames,
        }).toList();
      }

      return null;
    } catch (e) {
      safePrint('Error loading tournament leaderboard: $e');
      return null;
    }
  }

  /// Build tournament leaderboard item
  Widget _buildTournamentLeaderboardItem(Map<String, dynamic> entry, int rank) {
    final isCurrentPlayer = entry['playerName'] == 'Erezos'; // You can make this dynamic
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCurrentPlayer 
            ? [Colors.blue.withValues(alpha: 0.3), Colors.blue.withValues(alpha: 0.1)]
            : [Colors.white.withValues(alpha: 0.2), Colors.white.withValues(alpha: 0.05)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: isCurrentPlayer 
          ? Border.all(color: Colors.blue, width: 2)
          : null,
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getRankColor(rank),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Player info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry['playerName'] ?? 'Anonymous',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: isCurrentPlayer ? FontWeight.bold : FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${entry['totalGames'] ?? 0} games played',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry['score']}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                'best score',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber; // Gold
      case 2:
        return Colors.grey[400]!; // Silver
      case 3:
        return Colors.brown[400]!; // Bronze
      default:
        return Colors.blue[600]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with back button and title
              if (widget.showBackButton)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      Expanded(
                        child: Text(
                          widget.customTitle ?? 'Leaderboard',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _refreshGlobalLeaderboard(),
                        icon: const Icon(Icons.refresh, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              
              // Tab selector
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: tabs.map((tab) {
                    final isSelected = selectedTab == tab;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => selectedTab = tab),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Text(
                            tab,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isSelected ? Colors.orange : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Content area
              Expanded(
                child: _isInitialized ? _buildLeaderboardContent() : _buildLoadingIndicator(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }

  Widget _buildLeaderboardContent() {
    switch (selectedTab) {
      case 'Global':
        return _buildGlobalLeaderboard();
      case 'Weekly':
        return _buildWeeklyLeaderboard();
      case 'Local':
        return _buildLocalLeaderboard();
      default:
        return _buildGlobalLeaderboard();
    }
  }

  Widget _buildGlobalLeaderboard() {
    return Column(
      children: [
        // Player's global rank and score section
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.person, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Best: ${_globalService.bestGlobalScore}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Global Rank: ${_globalService.globalRank}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Global leaderboard list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _globalService.globalScores.length,
            itemBuilder: (context, index) {
              final entry = _globalService.globalScores[index];
              return _buildGlobalLeaderboardItem(entry);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyLeaderboard() {
    return FutureBuilder<List<Map<String, dynamic>>?>(
      future: _loadWeeklyTournamentLeaderboard(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Failed to load tournament',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        final leaderboard = snapshot.data;
        if (leaderboard == null || leaderboard.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, size: 64, color: Colors.white70),
                const SizedBox(height: 16),
                Text(
                  'Weekly Tournament',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'No scores yet this week',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: leaderboard.length,
          itemBuilder: (context, index) {
            final entry = leaderboard[index];
            return _buildTournamentLeaderboardItem(entry, index + 1);
          },
        );
      },
    );
  }

  Widget _buildLocalLeaderboard() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _leaderboardManager.localScores.length,
      itemBuilder: (context, index) {
        final entry = _leaderboardManager.localScores[index];
        return _buildLocalLeaderboardItem(entry, _globalService.playerName);
      },
    );
  }

  Widget _buildLocalLeaderboardItem(LeaderboardEntry entry, String playerName) {
    // Force display "Erezos" for player entries
    final displayName = (entry.playerName == 'You' || entry.playerName == playerName) ? 'Erezos' : entry.playerName;
    final isPlayer = entry.playerName == playerName || entry.playerName == 'You';
    
    Color rankColor;
    if (entry.rank == 1) {
      rankColor = const Color(0xFFFFD700); // Gold
    } else if (entry.rank == 2) {
      rankColor = const Color(0xFFC0C0C0); // Silver
    } else if (entry.rank == 3) {
      rankColor = const Color(0xFFCD7F32); // Bronze
    } else {
      rankColor = Colors.grey.shade600; // Darker for better contrast on light backgrounds
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPlayer ? Colors.blue.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: isPlayer ? Border.all(color: Colors.blue, width: 2) : null,
      ),
      child: Row(
        children: [
          // Rank circle
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rankColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${entry.rank}',
                style: TextStyle(
                  color: entry.rank <= 3 ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Jet avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                _getJetSkinForScore(entry.score),
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  safePrint('Error loading jet image: $error');
                  return Icon(
                    Icons.flight,
                    color: Colors.grey.shade600,
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
                  displayName,
                  style: TextStyle(
                    color: isPlayer ? Colors.blue.shade200 : Colors.white,
                    fontSize: 16,
                    fontWeight: isPlayer ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                Text(
                  'Score: ${entry.score}',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Score highlight
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade300, Colors.orange.shade600],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${entry.score}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getThemeForScore(entry.score),
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalLeaderboardItem(GlobalLeaderboardEntry entry) {
    final isPlayer = entry.playerId == _globalService.playerId;
    // Force display "Erezos" for player entries
    final displayName = isPlayer ? 'Erezos' : entry.playerName;
    
    Color rankColor;
    if (entry.rank == 1) {
      rankColor = const Color(0xFFFFD700); // Gold
    } else if (entry.rank == 2) {
      rankColor = const Color(0xFFC0C0C0); // Silver
    } else if (entry.rank == 3) {
      rankColor = const Color(0xFFCD7F32); // Bronze
    } else {
      rankColor = Colors.grey.shade600; // Darker for better contrast on light backgrounds
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPlayer ? Colors.blue.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: isPlayer ? Border.all(color: Colors.blue, width: 2) : null,
      ),
      child: Row(
        children: [
          // Rank circle
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rankColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${entry.rank}',
                style: TextStyle(
                  color: entry.rank <= 3 ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Jet avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                entry.jetSkin.startsWith('assets/') 
                    ? entry.jetSkin 
                    : 'assets/images/${entry.jetSkin}',
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  safePrint('Error loading jet image: $error');
                  return Icon(
                    Icons.flight,
                    color: Colors.grey.shade600,
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
                  displayName,
                  style: TextStyle(
                    color: isPlayer ? Colors.blue.shade200 : Colors.white,
                    fontSize: 16,
                    fontWeight: isPlayer ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                Text(
                  '${entry.theme} • ${_formatTimeAgo(entry.achievedAt)}',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Score highlight
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade300, Colors.orange.shade600],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${entry.score}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                entry.theme,
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getJetSkinForScore(int score) {
    if (score >= 300) return 'assets/images/jets/supreme_jet.png';
    if (score >= 200) return 'assets/images/jets/stealth_bomber.png';
    if (score >= 150) return 'assets/images/jets/destroyer.png';
    if (score >= 100) return 'assets/images/jets/red_alert.png';
    if (score >= 75) return 'assets/images/jets/green_lightning.png';
    if (score >= 50) return 'assets/images/jets/diamond_jet.png';
    if (score >= 25) return 'assets/images/jets/flames.png';
    return 'assets/images/jets/sky_jet.png';
  }

  String _getThemeForScore(int score) {
    if (score >= 200) return 'Cosmic Explorer';
    if (score >= 150) return 'Stratosphere Master';
    if (score >= 100) return 'High Altitude';
    if (score >= 75) return 'Lightning Storm';
    if (score >= 50) return 'Storm Chaser';
    if (score >= 25) return 'Afternoon Flyer';
    if (score >= 10) return 'Sunny Skies';
    return 'Sky Rookie';
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

  Future<void> _refreshGlobalLeaderboard() async {
    await _globalService.refreshLeaderboards();
    if (mounted) {
      setState(() {});
    }
  }
}

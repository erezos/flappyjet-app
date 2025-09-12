/// 🏆 Weekly Contest Tab - Shows tournament system from Railway backend
/// This is the new tournament feature we implemented
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../services/tournament_service.dart';
import '../../../models/tournament.dart';
import '../../../models/tournament_leaderboard_entry.dart';
import '../../../core/debug_logger.dart';

class WeeklyContestTab extends StatefulWidget {
  const WeeklyContestTab({super.key});

  @override
  State<WeeklyContestTab> createState() => _WeeklyContestTabState();
}

class _WeeklyContestTabState extends State<WeeklyContestTab> 
    with AutomaticKeepAliveClientMixin {
  final TournamentService _tournamentService = TournamentService(
    baseUrl: 'https://flappyjet-backend-production.up.railway.app',
  );
  bool _isLoading = true;
  Tournament? _currentTournament;
  List<TournamentLeaderboardEntry> _tournamentLeaderboard = [];
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadTournamentData();
  }

  @override
  void dispose() {
    _tournamentService.dispose();
    super.dispose();
  }

  Future<void> _loadTournamentData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      safePrint('🏆 WeeklyContestTab: Loading tournament data...');

      // Load current tournament
      final tournamentResult = await _tournamentService.getCurrentTournament();
      
      safePrint('🏆 WeeklyContestTab: Tournament result - success: ${tournamentResult.isSuccess}, error: ${tournamentResult.error}');
      
      Tournament? tournament;
      List<TournamentLeaderboardEntry> leaderboard = [];
      
      if (tournamentResult.isSuccess) {
        tournament = tournamentResult.data;
        safePrint('🏆 WeeklyContestTab: Tournament found - ${tournament?.name} (${tournament?.id})');
        
        // Load tournament leaderboard if tournament exists
        if (tournament != null) {
          final leaderboardResult = await _tournamentService.getTournamentLeaderboard(
            tournamentId: tournament.id,
          );
          safePrint('🏆 WeeklyContestTab: Leaderboard result - success: ${leaderboardResult.isSuccess}, entries: ${leaderboardResult.data?.entries.length ?? 0}');
          
          if (leaderboardResult.isSuccess && leaderboardResult.data != null) {
            leaderboard = leaderboardResult.data!.entries;
            safePrint('🏆 WeeklyContestTab: Leaderboard entries:');
            for (int i = 0; i < leaderboard.length; i++) {
              final entry = leaderboard[i];
              safePrint('  ${i + 1}. ${entry.playerName}: ${entry.score} (rank: ${entry.rank})');
            }
          } else {
            safePrint('🏆 WeeklyContestTab: Failed to load leaderboard - ${leaderboardResult.error}');
          }
        }
      } else {
        safePrint('🏆 WeeklyContestTab: Failed to load tournament - ${tournamentResult.error}');
      }

      if (mounted) {
        setState(() {
          _currentTournament = tournament;
          _tournamentLeaderboard = leaderboard;
          _isLoading = false;
        });
      }
    } catch (e) {
      safePrint('🏆 WeeklyContestTab: Exception loading tournament data: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load tournament data: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF2D1B69),
            Color(0xFF11998E),
            Color(0xFF0F3460),
          ],
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
                    : _buildTournamentContent(),
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
            '🏆 Weekly Contest',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: () {
              safePrint('🏆 WeeklyContestTab: Manual refresh triggered');
              _loadTournamentData();
            },
            icon: const Icon(
              Icons.refresh,
              color: Colors.white70,
            ),
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
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
          ),
          SizedBox(height: 16),
          Text(
            'Loading weekly contest...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
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
          const Icon(
            Icons.wifi_off,
            color: Colors.orangeAccent,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'Tournament system temporarily unavailable',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadTournamentData,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
            ),
            child: const Text('Retry Connection'),
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentContent() {
    if (_currentTournament == null) {
      return _buildNoTournamentState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tournament info card
          _buildTournamentInfoCard(),
          const SizedBox(height: 20),
          
          // Prize pool
          _buildPrizePoolCard(),
          const SizedBox(height: 20),
          
          // Leaderboard
          _buildTournamentLeaderboard(),
        ],
      ),
    );
  }

  Widget _buildNoTournamentState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.schedule,
            color: Colors.white70,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Active Tournament',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Weekly contests start every Monday!\nCheck back soon for the next competition.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentInfoCard() {
    final tournament = _currentTournament!;
    final name = tournament.name;
    final startTime = _formatDate(tournament.startDate);
    final endTime = _formatDate(tournament.endDate);
    final status = tournament.status;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.emoji_events,
                color: Colors.black,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: status == TournamentStatus.active ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Duration: $startTime - $endTime',
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.8, 0.8));
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    // Check if it's today, tomorrow, or yesterday
    final difference = dateOnly.difference(today).inDays;
    
    if (difference == 0) {
      // Today - show time only
      return 'Today ${_formatTime(date)}';
    } else if (difference == 1) {
      // Tomorrow
      return 'Tomorrow ${_formatTime(date)}';
    } else if (difference == -1) {
      // Yesterday
      return 'Yesterday ${_formatTime(date)}';
    } else {
      // Other dates - show month/day and time
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day} ${_formatTime(date)}';
    }
  }
  
  String _formatTime(DateTime date) {
    final hour = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Widget _buildPrizePoolCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.monetization_on,
                color: Colors.white,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'Prize Pool',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPrizeItem('🥇', '1st Place', '1000 Coins'),
              _buildPrizeItem('🥈', '2nd Place', '500 Coins'),
              _buildPrizeItem('🥉', '3rd Place', '250 Coins'),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 800.ms).slideY(begin: 0.3);
  }

  Widget _buildPrizeItem(String emoji, String place, String prize) {
    return Column(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(height: 4),
        Text(
          place,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          prize,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildTournamentLeaderboard() {
    if (_tournamentLeaderboard.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'No participants yet.\nBe the first to join!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tournament Leaderboard',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(_tournamentLeaderboard.length, (index) {
          final entry = _tournamentLeaderboard[index];
          return _buildTournamentLeaderboardItem(entry, index + 1);
        }),
      ],
    );
  }

  Widget _buildTournamentLeaderboardItem(TournamentLeaderboardEntry entry, int rank) {
    final playerName = entry.playerName;
    final score = entry.score;
    final submittedAt = 'Rank ${entry.rank}';

    Color rankColor = rank <= 3 ? const Color(0xFFFFD700) : Colors.white70;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: rank <= 3 ? Border.all(color: rankColor, width: 1) : null,
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  color: rankColor,
                  fontWeight: FontWeight.bold,
                ),
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
                  ),
                ),
                Text(
                  submittedAt,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Score
          Text(
            '$score',
            style: TextStyle(
              color: rankColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (rank * 100).ms);
  }
}
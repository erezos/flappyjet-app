/// 🏆 Weekly Contest Tab - Shows tournament system from Railway backend
/// This is the new tournament feature we implemented
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../services/tournament_service.dart';
import '../../../models/tournament.dart';
import '../../../models/tournament_leaderboard_entry.dart';
import '../../../core/debug_logger.dart';
import '../../../game/systems/player_identity_manager.dart';

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
  late final PlayerIdentityManager _playerIdentityManager;
  bool _isLoading = true;
  Tournament? _currentTournament;
  List<TournamentLeaderboardEntry> _tournamentLeaderboard = [];
  TournamentLeaderboardEntry? _userPosition;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _playerIdentityManager = PlayerIdentityManager();
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
          // Load top 15 entries
          final leaderboardResult = await _tournamentService.getTournamentLeaderboard(
            tournamentId: tournament.id,
            limit: 15,
          );
          safePrint('🏆 WeeklyContestTab: Leaderboard result - success: ${leaderboardResult.isSuccess}, entries: ${leaderboardResult.data?.entries.length ?? 0}');
          
          if (leaderboardResult.isSuccess && leaderboardResult.data != null) {
            leaderboard = leaderboardResult.data!.entries;
            safePrint('🏆 WeeklyContestTab: Top 15 leaderboard entries loaded');
            
            // Check if current user is in top 15
            final currentPlayerId = _playerIdentityManager.playerId;
            final userInTop15 = leaderboard.any((entry) => entry.playerId == currentPlayerId);
            
            // If user is not in top 15, try to get their position
            if (!userInTop15 && currentPlayerId.isNotEmpty) {
              // Load all entries to find user position (this could be optimized with a separate API call)
              final fullLeaderboardResult = await _tournamentService.getTournamentLeaderboard(
                tournamentId: tournament.id,
                limit: 100, // Get more entries to find user
              );
              
              if (fullLeaderboardResult.isSuccess && fullLeaderboardResult.data != null) {
                final allEntries = fullLeaderboardResult.data!.entries;
                final userEntry = allEntries.where((entry) => entry.playerId == currentPlayerId).firstOrNull;
                
                if (userEntry != null) {
                  _userPosition = userEntry;
                  safePrint('🏆 WeeklyContestTab: User position found - rank ${userEntry.rank}');
                }
              }
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
      padding: const EdgeInsets.all(24),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFF4ECDC4).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PRIZE POOL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'Compete for amazing rewards!',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: _buildPrizeItem('🥇', '1st Place', '1000 Coins'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPrizeItem('🥈', '2nd Place', '500 Coins'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPrizeItem('🥉', '3rd Place', '250 Coins'),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 800.ms).slideY(begin: 0.3);
  }

  Widget _buildPrizeItem(String emoji, String place, String prize) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              place,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              prize,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
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
          final isUserEntry = entry.playerId == _playerIdentityManager.playerId;
          return _buildTournamentLeaderboardItem(entry, index + 1, isUserEntry);
        }),
        // Add user position if they're not in top 15
        if (_userPosition != null && 
            !_tournamentLeaderboard.any((entry) => entry.playerId == _userPosition!.playerId)) ...[
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
          _buildTournamentLeaderboardItem(_userPosition!, _userPosition!.rank, true),
        ],
      ],
    );
  }

  Widget _buildTournamentLeaderboardItem(TournamentLeaderboardEntry entry, int rank, bool isUserEntry) {
    final playerName = entry.playerName;
    final score = entry.score;
    final submittedAt = 'Rank ${entry.rank}';

    Color rankColor;
    Color backgroundColor;
    Color? borderColor;

    if (isUserEntry) {
      // Highlight user's entry
      borderColor = const Color(0xFF4ECDC4);
      backgroundColor = const Color(0xFF1A2332);
    }

    if (rank == 1) {
      rankColor = const Color(0xFFFFD700); // Gold
      backgroundColor = isUserEntry ? const Color(0xFF3D2B69) : const Color(0xFF2D1B69);
    } else if (rank == 2) {
      rankColor = const Color(0xFFC0C0C0); // Silver
      backgroundColor = isUserEntry ? const Color(0xFF2A2A3E) : const Color(0xFF1A1A2E);
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32); // Bronze
      backgroundColor = isUserEntry ? const Color(0xFF26314E) : const Color(0xFF16213E);
    } else {
      rankColor = Colors.white70;
      backgroundColor = isUserEntry ? const Color(0xFF1F3470) : Colors.white.withValues(alpha: 0.1);
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: borderColor != null 
            ? Border.all(color: borderColor, width: 2)
            : (rank <= 3 ? Border.all(color: rankColor, width: 1) : null),
        boxShadow: [
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
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: (isUserEntry && rank > 15)
                  ? Icon(Icons.person, color: rankColor, size: 18)
                  : Text(
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
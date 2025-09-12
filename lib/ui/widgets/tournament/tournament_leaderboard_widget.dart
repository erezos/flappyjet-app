import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../models/tournament.dart';
import '../../../models/tournament_leaderboard_entry.dart';
import '../../../services/tournament_service.dart';

/// Modern tournament leaderboard with animated entries
class TournamentLeaderboardWidget extends StatefulWidget {
  final Tournament? tournament;

  const TournamentLeaderboardWidget({super.key, required this.tournament});

  @override
  State<TournamentLeaderboardWidget> createState() =>
      _TournamentLeaderboardWidgetState();
}

class _TournamentLeaderboardWidgetState
    extends State<TournamentLeaderboardWidget> {
  late final TournamentService _tournamentService;
  List<TournamentLeaderboardEntry> _leaderboard = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tournamentService = TournamentService(
      baseUrl: 'https://flappyjet-backend-production.up.railway.app',
    );

    if (widget.tournament != null) {
      _loadLeaderboard();
    }
  }

  @override
  void dispose() {
    _tournamentService.dispose();
    super.dispose();
  }

  Future<void> _loadLeaderboard() async {
    if (widget.tournament == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _tournamentService.getTournamentLeaderboard(
        tournamentId: widget.tournament!.id,
        limit: 10,
      );

      if (result.isSuccess && result.data != null) {
        setState(() {
          _leaderboard = result.data!.entries;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result.error ?? 'Failed to load leaderboard';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tournament == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
        ),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.3),
            blurRadius: 15,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              gradient: LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Color.fromRGBO(255, 255, 255, 0.2),
                  ),
                  child: const Icon(
                    Icons.leaderboard,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Leaderboard',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _loadLeaderboard,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.3, end: 0),

          // Content
          _buildLeaderboardContent(),
        ],
      ),
    );
  }

  Widget _buildLeaderboardContent() {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
          ),
        ),
      );
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFFF6B6B), size: 40),
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(
                color: Color.fromRGBO(255, 255, 255, 0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadLeaderboard,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4ECDC4),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_leaderboard.isEmpty) {
      return Container(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                const Icon(
                  Icons.emoji_events_outlined,
                  color: Color.fromRGBO(255, 255, 255, 0.6),
                  size: 60,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No players yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Be the first to join and claim the top spot!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color.fromRGBO(255, 255, 255, 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
          .animate()
          .fadeIn(duration: 800.ms)
          .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _leaderboard.length,
      itemBuilder: (context, index) {
        final entry = _leaderboard[index];
        return _buildLeaderboardEntry(entry, index);
      },
    );
  }

  Widget _buildLeaderboardEntry(TournamentLeaderboardEntry entry, int index) {
    Color rankColor;
    IconData rankIcon;

    switch (entry.rank) {
      case 1:
        rankColor = const Color(0xFFFFD700); // Gold
        rankIcon = Icons.workspace_premium;
        break;
      case 2:
        rankColor = const Color(0xFFC0C0C0); // Silver
        rankIcon = Icons.workspace_premium;
        break;
      case 3:
        rankColor = const Color(0xFFCD7F32); // Bronze
        rankIcon = Icons.workspace_premium;
        break;
      default:
        rankColor = const Color(0xFF95E1D3);
        rankIcon = Icons.person;
    }

    return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                entry.isCurrentPlayer
                    ? Color.fromRGBO(78, 205, 196, 0.2)
                    : Color.fromRGBO(255, 255, 255, 0.05),
                Colors.transparent,
              ],
            ),
            border: Border.all(
              color: entry.isCurrentPlayer
                  ? Color.fromRGBO(78, 205, 196, 0.5)
                  : Color.fromRGBO(255, 255, 255, 0.1),
              width: entry.isCurrentPlayer ? 2 : 1,
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
                  gradient: LinearGradient(
                    colors: [
                      rankColor,
                      Color.fromRGBO(
                        rankColor.red,
                        rankColor.green,
                        rankColor.blue,
                        0.7,
                      ),
                    ],
                  ),
                ),
                child: Center(
                  child: entry.rank <= 3
                      ? Icon(rankIcon, color: Colors.white, size: 20)
                      : Text(
                          '${entry.rank}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.playerName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: entry.isCurrentPlayer
                                  ? const Color(0xFF4ECDC4)
                                  : Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (entry.isCurrentPlayer)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: const Color(0xFF4ECDC4),
                            ),
                            child: const Text(
                              'YOU',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${entry.totalGames} games played',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color.fromRGBO(255, 255, 255, 0.6),
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
                    '${entry.score}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: entry.isCurrentPlayer
                          ? const Color(0xFF4ECDC4)
                          : Colors.white,
                    ),
                  ),
                  Text(
                    'points',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color.fromRGBO(255, 255, 255, 0.6),
                    ),
                  ),
                ],
              ),

              // Prize indicator
              if (entry.wonPrize) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Color.fromRGBO(255, 215, 0, 0.2),
                  ),
                  child: const Icon(
                    Icons.diamond,
                    color: Color(0xFFFFD700),
                    size: 16,
                  ),
                ),
              ],
            ],
          ),
        )
        .animate()
        .fadeIn(
          duration: 600.ms,
          delay: Duration(milliseconds: index * 100),
        )
        .slideX(begin: 0.3, end: 0)
        .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.0, 1.0));
  }
}

/// 🏆 TOURNAMENTS PAGE - Endless Mode Entry + Competitions
/// Part of the new tab navigation system
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import '../../game/systems/monetization_manager.dart';
import '../../game/systems/missions_manager.dart';
import '../../game/systems/lives_manager.dart';
import '../../services/tournament_service.dart';
import '../../models/tournament.dart';
import '../widgets/tournaments/global_leaderboard_tab.dart';
import '../widgets/tournaments/weekly_contest_tab.dart';
import '../widgets/no_hearts_dialog.dart';
import 'game_screen.dart';
import 'package:intl/intl.dart';

class TournamentsPage extends StatefulWidget {
  final MonetizationManager monetization;
  final MissionsManager missions;

  const TournamentsPage({
    super.key,
    required this.monetization,
    required this.missions,
  });

  @override
  State<TournamentsPage> createState() => _TournamentsPageState();
}

class _TournamentsPageState extends State<TournamentsPage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final TabController _tabController;
  late final AnimationController _backgroundController;
  
  final TournamentService _tournamentService = TournamentService(
    baseUrl: 'https://flappyjet-backend-production.up.railway.app',
  );
  Tournament? _currentTournament;
  bool _loadingTournament = true;

  final List<String> _tabs = ['Weekly', 'Leaderboard'];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0); // Start on Weekly tab (index 0 now)
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    
    // Load tournament data
    _loadTournamentData();
  }
  
  Future<void> _loadTournamentData() async {
    final result = await _tournamentService.getCurrentTournament();
    if (mounted) {
      setState(() {
        _currentTournament = result.data;
        _loadingTournament = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _backgroundController.dispose();
    _tournamentService.dispose();
    super.dispose();
  }

  void _launchEndlessMode() {
    // Check if player has hearts available
    final livesManager = LivesManager();
    if (livesManager.currentLives <= 0) {
      // Show no hearts dialog
      _showNoHeartsDialog();
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GameScreen(
          monetization: widget.monetization,
          missions: widget.missions,
        ),
      ),
    );
  }

  void _showNoHeartsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => NoHeartsDialog(
        monetization: widget.monetization,
        onClose: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final size = MediaQuery.of(context).size;
    
    // Responsive sizing
    final isSmallScreen = size.height < 700;
    final playButtonSize = isSmallScreen ? 180.0 : 220.0;
    final playButtonGlow = isSmallScreen ? 30.0 : 40.0;
    final playTextSize = isSmallScreen ? 44.0 : 54.0;

    return WillPopScope(
      onWillPop: () async => false, // Disable back button for bottom nav screen
      child: AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        return Container(
          decoration: _buildAnimatedBackground(),
          child: SafeArea(
            child: Column(
              children: [
                // Centered Title
                _buildCenteredHeader(),

                const SizedBox(height: 12),

                // Tab bar (Weekly / Leaderboard)
                _buildTabBar(),

                const SizedBox(height: 8),

                // All content in one scrollable TabBarView
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Weekly Tab - Everything scrollable together
                      _buildWeeklyTabWithPlayButton(playButtonSize, playButtonGlow, playTextSize),

                      // Leaderboard Tab - Global rankings (scrollable)
                      const GlobalLeaderboardTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      ),
    );
  }

  Widget _buildWeeklyTabWithPlayButton(double playButtonSize, double playButtonGlow, double playTextSize) {
    // Play button sizing - BIGGER and more prominent
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Everything in one scrollable area
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // Tournament details (dynamic from tournament data)
            _buildTournamentInfo(),

            const SizedBox(height: 20),

            // ✅ NEW LAYOUT: Play button + Prizes side by side
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ✅ LEFT: Prize badges
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 18),
                          const SizedBox(width: 6),
                          const Text(
                            'PRIZES',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildPrizeBadges(),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // ✅ RIGHT: BIGGER Play button (no background, no shadow)
                Expanded(
                  flex: 6,
                  child: GestureDetector(
                    onTap: _launchEndlessMode,
                    child: Image.asset(
                      'assets/images/buttons/tournament_play_button.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ✅ Weekly Ranking Section
            Row(
              children: [
                const Icon(Icons.leaderboard, color: Color(0xFF4ECDC4), size: 18),
                const SizedBox(width: 6),
                const Text(
                  'WEEKLY RANKING',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ✅ Leaderboard (Clean, no boxes)
            _buildCompactLeaderboard(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTournamentInfo() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    if (_loadingTournament) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
          ),
        ),
      );
    }

    if (_currentTournament == null) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
        child: Text(
          'No active tournament',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      );
    }

    // Format dates
    final startDate = _currentTournament!.startDate;
    final endDate = _currentTournament!.endDate;
    final dateFormat = DateFormat('MMM d, h:mm a');
    final dateString = '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
        vertical: 8,
      ),
      child: Column(
        children: [
          // Compact tournament name with trophy icon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.emoji_events,
                color: const Color(0xFFFFD700),
                size: isSmallScreen ? 18 : 20,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _currentTournament!.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 6),
          
          // Compact status badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF44A08D).withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF4ECDC4).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              _currentTournament!.status.name.toUpperCase(),
              style: TextStyle(
                fontSize: isSmallScreen ? 10 : 11,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF4ECDC4),
                letterSpacing: 1,
              ),
            ),
          ),
          
          const SizedBox(height: 6),
          
          // Date range - compact with icon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today,
                size: isSmallScreen ? 12 : 14,
                color: Colors.white.withOpacity(0.6),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  dateString,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Creates an animated gradient background
  BoxDecoration _buildAnimatedBackground() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(
            const Color(0xFF1A1A2E),
            const Color(0xFF16213E),
            (math.sin(_backgroundController.value * 2 * math.pi) + 1) / 2,
          )!,
          Color.lerp(
            const Color(0xFF0F3460),
            const Color(0xFF533483),
            (math.cos(_backgroundController.value * 2 * math.pi) + 1) / 2,
          )!,
          Color.lerp(
            const Color(0xFF533483),
            const Color(0xFFE94560),
            (math.sin(_backgroundController.value * 4 * math.pi) + 1) / 4,
          )!,
        ],
        stops: const [0.0, 0.6, 1.0],
      ),
    );
  }

  Widget _buildCenteredHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: Colors.white,
                    size: 22,
                  ),
                )
                .animate()
                .fadeIn(duration: 600.ms)
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0))
                .shimmer(duration: 2000.ms, delay: 1000.ms),
            const SizedBox(width: 12),
            Text(
                  'TOURNAMENTS',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                )
                .animate()
                .fadeIn(duration: 800.ms, delay: 200.ms)
                .slideX(begin: 0.3, end: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: const LinearGradient(
              colors: [Color(0xFF2D1B69), Color(0xFF11998E)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15,
                spreadRadius: 3,
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: const LinearGradient(
                colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
              ),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
            tabs: _tabs
                .map(
                  (tab) => Tab(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        tab,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        )
        .animate()
        .fadeIn(duration: 800.ms, delay: 400.ms)
        .slideY(begin: -0.3, end: 0);
  }

  /// ✅ NEW: Clean Prizes & Leaderboard Section (NO BOXES, NO BORDERS)
  /// ✅ CLEAN Prize Badges (NO SQUARES, NO BOXES)
  Widget _buildPrizeBadges() {
    final prizes = [
      {'place': '1st', 'amount': '1000', 'emoji': '🥇', 'color': Color(0xFFFFD700)},
      {'place': '2nd', 'amount': '500', 'emoji': '🥈', 'color': Color(0xFFC0C0C0)},
      {'place': '3rd', 'amount': '250', 'emoji': '🥉', 'color': Color(0xFFCD7F32)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: prizes.map((prize) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              // Medal emoji
              Text(
                prize['emoji'] as String,
                style: const TextStyle(fontSize: 28),
              ),
              
              const SizedBox(width: 10),
              
              // Amount text
              Text(
                '${prize['amount']} Coins',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: prize['color'] as Color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// ✅ Compact Leaderboard (Nickname and Score closer)
  Widget _buildCompactLeaderboard() {
    // This will be replaced with actual data from WeeklyContestTab
    // For now, using placeholder that will be populated
    return const WeeklyContestTab();
  }
}


/// 🏆 TOURNAMENTS PAGE - Endless Mode Entry + Competitions
/// Part of the new tab navigation system
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import '../../game/systems/monetization_manager.dart';
import '../../game/systems/missions_manager.dart';
import '../../services/tournament_service.dart';
import '../../models/tournament.dart';
import '../widgets/tournaments/global_leaderboard_tab.dart';
import '../widgets/tournaments/weekly_contest_tab.dart';
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
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  
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

    // Pulse animation for PLAY button
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Glow animation
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    
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
    _pulseController.dispose();
    _glowController.dispose();
    _tournamentService.dispose();
    super.dispose();
  }

  void _launchEndlessMode() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GameScreen(
          monetization: widget.monetization,
          missions: widget.missions,
        ),
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

    return AnimatedBuilder(
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
    );
  }

  Widget _buildWeeklyTabWithPlayButton(double playButtonSize, double playButtonGlow, double playTextSize) {
    // Make PLAY button smaller - 60% of original size
    final smallerPlayButtonSize = playButtonSize * 0.6;
    final smallerPlayTextSize = playTextSize * 0.7;
    final smallerGlow = playButtonGlow * 0.6;
    
    // Everything in one scrollable area
    return SingleChildScrollView(
      child: Column(
        children: [
          // Top spacing
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),

          // PLAY Button (60% of original)
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glow effect
                    AnimatedBuilder(
                      animation: _glowAnimation,
                      builder: (context, child) {
                        return Container(
                          width: smallerPlayButtonSize + smallerGlow,
                          height: smallerPlayButtonSize + smallerGlow,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4ECDC4)
                                    .withOpacity(_glowAnimation.value * 0.5),
                                blurRadius: 30,
                                spreadRadius: 15,
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // Main button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _launchEndlessMode,
                        borderRadius: BorderRadius.circular(smallerPlayButtonSize / 2),
                        child: Container(
                          width: smallerPlayButtonSize,
                          height: smallerPlayButtonSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF4ECDC4),
                                Color(0xFF44A08D),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'PLAY',
                              style: TextStyle(
                                fontSize: smallerPlayTextSize,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 2,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.5),
                                    offset: const Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          SizedBox(height: MediaQuery.of(context).size.height * 0.015),

          // Tournament details (dynamic from tournament data)
          _buildTournamentInfo(),

          SizedBox(height: MediaQuery.of(context).size.height * 0.02),

          // Tournament table (WeeklyContestTab content - without its own Expanded)
          // We need to create a custom method to get the WeeklyContestTab's content without Expanded wrapper
          const WeeklyContestTab(),
        ],
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
}

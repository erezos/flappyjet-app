/// 🏆 Tournaments Screen - Modern Competition Hub
/// Three tabs: Leaderboard, Weekly Contest, Personal
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

import '../widgets/tournaments/global_leaderboard_tab.dart';
import '../widgets/tournaments/weekly_contest_tab.dart';
import '../widgets/tournaments/personal_scores_tab.dart';

class TournamentsScreen extends StatefulWidget {
  const TournamentsScreen({super.key});

  @override
  State<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  late final AnimationController _backgroundController;

  final List<String> _tabs = ['Leaderboard', 'Weekly', 'Personal'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundController,
        builder: (context, child) {
          return Container(
            decoration: _buildAnimatedBackground(),
            child: SafeArea(
              child: Column(
                children: [
                  // Header with back button and title
                  _buildHeader(),

                  // Tab bar
                  _buildTabBar(),

                  // Tab content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: const [
                        // Leaderboard Tab - Global rankings (replaces old "Global")
                        GlobalLeaderboardTab(),

                        // Weekly Contest Tab - Tournament system from Railway backend
                        WeeklyContestTab(),

                        // Personal Tab - Local scores (replaces old "Local")
                        PersonalScoresTab(),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Back button with cool animation
          Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4ECDC4).withValues(alpha: 0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 600.ms)
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.0, 1.0),
              ),

          // Title
          Expanded(
            child:
                Text(
                      'TOURNAMENTS',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 800.ms, delay: 200.ms)
                    .slideX(begin: 0.3, end: 0),
          ),

          // Trophy icon
          Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 24,
                ),
              )
              .animate()
              .fadeIn(duration: 600.ms, delay: 400.ms)
              .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0))
              .shimmer(duration: 2000.ms, delay: 1000.ms),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: const LinearGradient(
              colors: [Color(0xFF2D1B69), Color(0xFF11998E)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
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
        .fadeIn(duration: 800.ms, delay: 600.ms)
        .slideY(begin: -0.3, end: 0);
  }
}

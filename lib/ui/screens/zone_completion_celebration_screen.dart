/// 🎉 STORY MODE - ZONE COMPLETION CELEBRATION SCREEN
/// 
/// Beautiful celebration screen shown when a player completes all levels in a zone.
/// Features: Animated gradient background, confetti, zone stats, and auto-advance to next zone.
library;

import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../../models/level_data_schema.dart';
import '../../core/debug_logger.dart';
import '../widgets/text_3d_widget.dart';
import 'world_map_screen.dart';

class ZoneCompletionCelebrationScreen extends StatefulWidget {
  final ZoneData completedZone;
  final int totalCoins;
  final int totalGems;
  final int botWins;

  const ZoneCompletionCelebrationScreen({
    super.key,
    required this.completedZone,
    required this.totalCoins,
    required this.totalGems,
    required this.botWins,
  });

  @override
  State<ZoneCompletionCelebrationScreen> createState() =>
      _ZoneCompletionCelebrationScreenState();
}

class _ZoneCompletionCelebrationScreenState
    extends State<ZoneCompletionCelebrationScreen>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Color?> _backgroundAnimation;

  @override
  void initState() {
    super.initState();

    // Setup confetti (longer duration for zone completion)
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 5),
    );

    // Setup animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _backgroundAnimation = ColorTween(
      begin: const Color(0xFF1A237E),
      end: const Color(0xFF283593),
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Start animations
    _animationController.forward();
    _animationController.repeat(reverse: true);
    _confettiController.play();

    safePrint('🎉 Zone ${widget.completedZone.id} completed!');
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String _getZoneEmoji(int zoneId) {
    switch (zoneId) {
      case 1:
        return '🌊';
      case 2:
        return '🏜️';
      case 3:
        return '🌋';
      case 4:
        return '❄️';
      case 5:
        return '🌌';
      default:
        return '🗺️';
    }
  }

  Future<void> _onContinueToNextZone() async {
    safePrint('🗺️ Advancing to next zone...');

    // Navigate to world map (which will automatically show the next zone)
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const WorldMapScreen(),
        ),
        (route) => false, // Remove all previous routes
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _backgroundAnimation.value ?? const Color(0xFF1A237E),
                  const Color(0xFF283593),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Confetti
                Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    shouldLoop: false,
                    colors: const [
                      Colors.amber,
                      Colors.red,
                      Colors.blue,
                      Colors.green,
                      Colors.purple,
                      Colors.pink,
                    ],
                    numberOfParticles: 30,
                    gravity: 0.3,
                  ),
                ),

                // Main content
                SafeArea(
                  child: Center(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: _buildCelebrationCard(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCelebrationCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1A237E).withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.amber,
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.5),
            blurRadius: 40,
            spreadRadius: 10,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Trophy emoji
            const Text(
              '🏆',
              style: TextStyle(fontSize: 70),
            ),

            const SizedBox(height: 12),

            // Zone emoji and title
            Text(
              '${_getZoneEmoji(widget.completedZone.id)} ZONE ${widget.completedZone.id}',
              style: const TextStyle(
                color: Colors.amber,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 8),

            // "COMPLETE!" text with 3D effect
            Text3DStyles.header('COMPLETE!'),

            const SizedBox(height: 8),

            // Zone name
            Text(
              widget.completedZone.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Container(
              height: 4,
              width: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.amber, Colors.orange],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'CONQUERED!',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 24),

            // Stats
            _buildStatsGrid(),

            const SizedBox(height: 24),

            // Continue button
            _buildContinueButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildStatRow('🌟', 'Levels Completed', '10/10'),
          const SizedBox(height: 12),
          _buildStatRow('💰', 'Total Coins', widget.totalCoins.toString()),
          const SizedBox(height: 12),
          _buildStatRow('💎', 'Total Gems', widget.totalGems.toString()),
          if (widget.botWins > 0) ...[
            const SizedBox(height: 12),
            _buildStatRow('🤖', 'Bot Battles Won', widget.botWins.toString()),
          ],
        ],
      ),
    );
  }

  Widget _buildStatRow(String emoji, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.amber,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
    final nextZone = widget.completedZone.id + 1;
    final hasNextZone = nextZone <= 5; // Assuming 5 zones total

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_animationController.value * 0.05), // Subtle pulse
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _onContinueToNextZone,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 8,
                shadowColor: Colors.amber.withOpacity(0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (hasNextZone) ...[
                    Text(
                      'CONTINUE TO ZONE $nextZone',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 24),
                  ] else ...[
                    const Text(
                      'BACK TO MAP',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}


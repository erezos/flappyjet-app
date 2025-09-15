import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

import '../../../models/tournament.dart';

/// Colorful prize pool display with animated gems and distribution
class TournamentPrizePoolWidget extends StatefulWidget {
  final Tournament? tournament;

  const TournamentPrizePoolWidget({super.key, required this.tournament});

  @override
  State<TournamentPrizePoolWidget> createState() =>
      _TournamentPrizePoolWidgetState();
}

class _TournamentPrizePoolWidgetState extends State<TournamentPrizePoolWidget>
    with TickerProviderStateMixin {
  late final AnimationController _gemController;
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _gemController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _gemController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tournament == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Stack(
        children: [
          // Background with animated shimmer
          _buildShimmerBackground(),

          // Main content
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFD700), // Gold
                  Color(0xFFFFA500), // Orange
                  Color(0xFFFF6347), // Tomato
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(255, 215, 0, 0.4),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                // Prize pool header
                Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildAnimatedGem(),
                        const SizedBox(width: 12),
                        const Text(
                          'PRIZE POOL',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildAnimatedGem(),
                      ],
                    )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: -0.3, end: 0),

                const SizedBox(height: 16),

                // Total prize amount
                Text(
                      '${widget.tournament!.prizePool}',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 800.ms, delay: 200.ms)
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1.0, 1.0),
                    )
                    .shimmer(duration: 2000.ms, delay: 1000.ms),

                const Text(
                      'COINS',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                        letterSpacing: 3,
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 400.ms)
                    .slideY(begin: 0.3, end: 0),

                const SizedBox(height: 24),

                // Prize distribution
                _buildPrizeDistribution(),
              ],
            ),
          ),

          // Floating gems
          ..._buildFloatingGems(),
        ],
      ),
    );
  }

  Widget _buildShimmerBackground() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + (_shimmerController.value * 2), -1.0),
              end: Alignment(1.0 + (_shimmerController.value * 2), 1.0),
              colors: [
                Colors.transparent,
                Color.fromRGBO(255, 255, 255, 0.1),
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedGem() {
    return AnimatedBuilder(
      animation: _gemController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _gemController.value * 2 * math.pi,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  Color.lerp(
                    const Color(0xFF4ECDC4),
                    const Color(0xFF44A08D),
                    _gemController.value,
                  )!,
                  Color.lerp(
                    const Color(0xFF44A08D),
                    const Color(0xFF093637),
                    _gemController.value,
                  )!,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(78, 205, 196, 0.6),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.diamond, color: Colors.white, size: 12),
          ),
        );
      },
    );
  }

  Widget _buildPrizeDistribution() {
    final distribution = widget.tournament!.prizeDistribution;
    final sortedEntries = distribution.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Column(
      children: [
        const Text(
              'PRIZE DISTRIBUTION',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
                letterSpacing: 1,
              ),
            )
            .animate()
            .fadeIn(duration: 600.ms, delay: 600.ms)
            .slideY(begin: 0.3, end: 0),

        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: sortedEntries.map((entry) {
            final rank = entry.key;
            final percentage = entry.value;
            final amount = (widget.tournament!.prizePool * percentage).round();

            return _buildPrizeCard(
              rank: rank,
              amount: amount,
              percentage: percentage,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPrizeCard({
    required int rank,
    required int amount,
    required double percentage,
  }) {
    Color cardColor;
    String rankEmoji;

    switch (rank) {
      case 1:
        cardColor = const Color(0xFFFFD700); // Gold
        rankEmoji = '🥇';
        break;
      case 2:
        cardColor = const Color(0xFFC0C0C0); // Silver
        rankEmoji = '🥈';
        break;
      case 3:
        cardColor = const Color(0xFFCD7F32); // Bronze
        rankEmoji = '🥉';
        break;
      default:
        cardColor = const Color(0xFF95E1D3);
        rankEmoji = '🏅';
    }

    return Expanded(
      child:
          Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Color.fromRGBO(255, 255, 255, 0.2),
                  border: Border.all(
                    color: Color.fromRGBO(
                      (cardColor.r * 255.0).round() & 0xff,
                      (cardColor.g * 255.0).round() & 0xff,
                      (cardColor.b * 255.0).round() & 0xff,
                      0.5,
                    ),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(rankEmoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 4),
                    Text(
                      '${(percentage * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '$amount',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'coins',
                      style: TextStyle(fontSize: 10, color: Colors.white70),
                    ),
                  ],
                ),
              )
              .animate()
              .fadeIn(
                duration: 800.ms,
                delay: Duration(milliseconds: 800 + (rank * 200)),
              )
              .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0))
              .shimmer(
                duration: 2000.ms,
                delay: Duration(milliseconds: 1500 + (rank * 200)),
              ),
    );
  }

  List<Widget> _buildFloatingGems() {
    return List.generate(8, (index) {
      return Positioned(
        top: 10 + (index * 8.0),
        left: 10 + (index * 25.0),
        child: AnimatedBuilder(
          animation: _gemController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                math.sin(_gemController.value * 2 * math.pi + index) * 10,
                math.cos(_gemController.value * 2 * math.pi + index) * 5,
              ),
              child: Opacity(
                opacity:
                    0.3 +
                    (0.4 *
                        math.sin(_gemController.value * 2 * math.pi + index)),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: [
                      const Color(0xFF4ECDC4),
                      const Color(0xFFFFE66D),
                      const Color(0xFFFF6B6B),
                    ][index % 3],
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }
}

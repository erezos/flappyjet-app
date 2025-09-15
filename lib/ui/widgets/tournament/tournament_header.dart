import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

import '../../../models/tournament.dart';

/// Stunning tournament header with animated elements and countdown
class TournamentHeader extends StatefulWidget {
  final Tournament? tournament;

  const TournamentHeader({super.key, required this.tournament});

  @override
  State<TournamentHeader> createState() => _TournamentHeaderState();
}

class _TournamentHeaderState extends State<TournamentHeader>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _rotateController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tournament == null) {
      return _buildNoTournamentState();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: Stack(
        children: [
          // Background glow effect
          _buildBackgroundGlow(),

          // Main content
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2D1B69), Color(0xFF11998E)],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(78, 205, 196, 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tournament title and status
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                                widget.tournament!.name,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )
                              .animate()
                              .fadeIn(duration: 600.ms)
                              .slideX(begin: -0.3, end: 0),
                          const SizedBox(height: 8),
                          Text(
                                widget.tournament!.description,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              )
                              .animate()
                              .fadeIn(duration: 800.ms, delay: 200.ms)
                              .slideX(begin: -0.3, end: 0),
                        ],
                      ),
                    ),
                    // Status badge
                    _buildStatusBadge(),
                  ],
                ),

                const SizedBox(height: 24),

                // Tournament info cards
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.people,
                        label: 'Players',
                        value: '${widget.tournament!.participantCount}',
                        color: const Color(0xFFFF6B6B),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.timer,
                        label: 'Time Left',
                        value: widget.tournament!.formattedTimeRemaining,
                        color: const Color(0xFF4ECDC4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.emoji_events,
                        label: 'Type',
                        value: _getTournamentTypeDisplay(),
                        color: const Color(0xFFFFE66D),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Floating particles
          ..._buildFloatingParticles(),
        ],
      ),
    );
  }

  Widget _buildNoTournamentState() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.2),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  color: Color.fromRGBO(255, 255, 255, 0.2),
                ),
                child: const Icon(
                  Icons.schedule,
                  color: Colors.white,
                  size: 40,
                ),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.2, 1.2),
                duration: 2000.ms,
              )
              .then()
              .scale(
                begin: const Offset(1.2, 1.2),
                end: const Offset(0.8, 0.8),
                duration: 2000.ms,
              ),
          const SizedBox(height: 16),
          const Text(
            'No Active Tournament',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3, end: 0),
          const SizedBox(height: 8),
          Text(
                'Check back soon for the next epic battle!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              )
              .animate()
              .fadeIn(duration: 800.ms, delay: 200.ms)
              .slideY(begin: 0.3, end: 0),
        ],
      ),
    );
  }

  Widget _buildBackgroundGlow() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(
                  78,
                  205,
                  196,
                  0.1 + (0.2 * _pulseController.value),
                ),
                blurRadius: 30 + (20 * _pulseController.value),
                spreadRadius: 10 + (10 * _pulseController.value),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge() {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (widget.tournament!.status) {
      case TournamentStatus.active:
        statusColor = const Color(0xFF4ECDC4);
        statusText = 'LIVE';
        statusIcon = Icons.play_circle_filled;
        break;
      case TournamentStatus.upcoming:
        statusColor = const Color(0xFFFFE66D);
        statusText = 'SOON';
        statusIcon = Icons.schedule;
        break;
      case TournamentStatus.registration:
        statusColor = const Color(0xFF95E1D3);
        statusText = 'OPEN';
        statusIcon = Icons.how_to_reg;
        break;
      default:
        statusColor = const Color(0xFFFF6B6B);
        statusText = 'ENDED';
        statusIcon = Icons.stop_circle;
    }

    return AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Color.fromRGBO(
                  (statusColor.r * 255.0).round() & 0xff,
                  (statusColor.g * 255.0).round() & 0xff,
                  (statusColor.b * 255.0).round() & 0xff,
                  0.8 + (0.2 * _pulseController.value),
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(
                      (statusColor.r * 255.0).round() & 0xff,
                      (statusColor.g * 255.0).round() & 0xff,
                      (statusColor.b * 255.0).round() & 0xff,
                      0.4,
                    ),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          },
        )
        .animate()
        .fadeIn(duration: 600.ms, delay: 400.ms)
        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0));
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Color.fromRGBO(255, 255, 255, 0.1),
            border: Border.all(
              color: Color.fromRGBO((color.r * 255.0).round() & 0xff, (color.g * 255.0).round() & 0xff, (color.b * 255.0).round() & 0xff, 0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Color.fromRGBO(
                    (color.r * 255.0).round() & 0xff,
                    (color.g * 255.0).round() & 0xff,
                    (color.b * 255.0).round() & 0xff,
                    0.2,
                  ),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 800.ms, delay: 600.ms)
        .slideY(begin: 0.5, end: 0)
        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0));
  }

  List<Widget> _buildFloatingParticles() {
    return List.generate(6, (index) {
      return Positioned(
            top: 20 + (index * 15.0),
            right: 20 + (index * 10.0),
            child: AnimatedBuilder(
              animation: _rotateController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotateController.value * 2 * math.pi + (index * 0.5),
                  child: Container(
                    width: 6 + (index * 2.0),
                    height: 6 + (index * 2.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: [
                        const Color(0xFF4ECDC4),
                        const Color(0xFFFF6B6B),
                        const Color(0xFFFFE66D),
                      ][index % 3].withValues(alpha: 0.6),
                    ),
                  ),
                );
              },
            ),
          )
          .animate(onPlay: (controller) => controller.repeat())
          .fadeIn(
            duration: 1000.ms,
            delay: Duration(milliseconds: index * 200),
          )
          .moveY(begin: 0, end: -20, duration: 3000.ms, curve: Curves.easeInOut)
          .then()
          .moveY(
            begin: -20,
            end: 0,
            duration: 3000.ms,
            curve: Curves.easeInOut,
          );
    });
  }

  String _getTournamentTypeDisplay() {
    switch (widget.tournament!.tournamentType) {
      case TournamentType.weekly:
        return 'Weekly';
      case TournamentType.monthly:
        return 'Monthly';
      case TournamentType.special:
        return 'Special';
    }
  }
}

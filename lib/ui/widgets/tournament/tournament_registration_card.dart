import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../models/tournament.dart';

/// Engaging registration card with call-to-action
class TournamentRegistrationCard extends StatefulWidget {
  final Tournament tournament;
  final VoidCallback onRegister;

  const TournamentRegistrationCard({
    super.key,
    required this.tournament,
    required this.onRegister,
  });

  @override
  State<TournamentRegistrationCard> createState() =>
      _TournamentRegistrationCardState();
}

class _TournamentRegistrationCardState extends State<TournamentRegistrationCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  bool _isRegistering = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Stack(
        children: [
          // Animated background glow
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(
                        78,
                        205,
                        196,
                        0.2 + (0.3 * _pulseController.value),
                      ),
                      blurRadius: 20 + (10 * _pulseController.value),
                      spreadRadius: 5 + (5 * _pulseController.value),
                    ),
                  ],
                ),
              );
            },
          ),

          // Main card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              border: Border.all(
                color: Color.fromRGBO(255, 255, 255, 0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // Registration icon
                Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color.fromRGBO(78, 205, 196, 0.4),
                            blurRadius: 15,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.how_to_reg,
                        color: Colors.white,
                        size: 40,
                      ),
                    )
                    .animate()
                    .scale(duration: 600.ms, curve: Curves.elasticOut)
                    .shimmer(duration: 2000.ms, delay: 800.ms),

                const SizedBox(height: 20),

                // Title
                const Text(
                      'Join the Battle!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 200.ms)
                    .slideY(begin: 0.3, end: 0),

                const SizedBox(height: 12),

                // Description
                Text(
                      'Register now and compete with players worldwide for amazing prizes!',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color.fromRGBO(255, 255, 255, 0.9),
                      ),
                      textAlign: TextAlign.center,
                    )
                    .animate()
                    .fadeIn(duration: 800.ms, delay: 400.ms)
                    .slideY(begin: 0.3, end: 0),

                const SizedBox(height: 24),

                // Registration info
                _buildRegistrationInfo(),

                const SizedBox(height: 24),

                // Register button
                _buildRegisterButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Color.fromRGBO(255, 255, 255, 0.1),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildInfoItem(
              icon: Icons.attach_money,
              label: 'Entry Fee',
              value: widget.tournament.entryFee > 0
                  ? '${widget.tournament.entryFee} coins'
                  : 'FREE',
              color: const Color(0xFF95E1D3),
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Color.fromRGBO(255, 255, 255, 0.2),
          ),
          Expanded(
            child: _buildInfoItem(
              icon: Icons.people,
              label: 'Spots Left',
              value: widget.tournament.maxParticipants != null
                  ? '${widget.tournament.maxParticipants! - widget.tournament.participantCount}'
                  : 'Unlimited',
              color: const Color(0xFFFFE66D),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms, delay: 600.ms).slideY(begin: 0.5, end: 0);
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Color.fromRGBO(255, 255, 255, 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (0.05 * _pulseController.value),
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    colors: [
                      Color.lerp(
                        const Color(0xFF4ECDC4),
                        const Color(0xFF44A08D),
                        _pulseController.value,
                      )!,
                      Color.lerp(
                        const Color(0xFF44A08D),
                        const Color(0xFF093637),
                        _pulseController.value,
                      )!,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(78, 205, 196, 0.4),
                      blurRadius: 15,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: _isRegistering ? null : _handleRegister,
                    child: Center(
                      child: _isRegistering
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.rocket_launch,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'REGISTER NOW',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            );
          },
        )
        .animate()
        .fadeIn(duration: 800.ms, delay: 800.ms)
        .slideY(begin: 0.5, end: 0)
        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0));
  }

  Future<void> _handleRegister() async {
    setState(() {
      _isRegistering = true;
    });

    try {
      // Add haptic feedback
      // HapticFeedback.lightImpact();

      // Call the registration callback
      widget.onRegister();

      // Simulate registration delay
      await Future.delayed(const Duration(seconds: 1));
    } finally {
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
      }
    }
  }
}

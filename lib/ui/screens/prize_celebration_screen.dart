/// 🏆 Prize Celebration Screen - Beautiful prize claiming UI with celebrations!
/// 
/// Shows when a player has won a prize from a tournament.
/// Features confetti, trophy animations, and reward display.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/pending_prize.dart';
import '../../services/prize_service.dart';
import '../widgets/confetti_widget.dart';

class PrizeCelebrationScreen extends StatefulWidget {
  final PendingPrize prize;
  final PrizeService prizeService;

  const PrizeCelebrationScreen({
    super.key,
    required this.prize,
    required this.prizeService,
  });

  @override
  State<PrizeCelebrationScreen> createState() => _PrizeCelebrationScreenState();
}

class _PrizeCelebrationScreenState extends State<PrizeCelebrationScreen>
    with TickerProviderStateMixin {
  late AnimationController _trophyController;
  late AnimationController _prizeController;
  late AnimationController _buttonController;

  late Animation<double> _trophyScale;
  late Animation<double> _trophyRotation;
  late Animation<double> _prizeOpacity;
  late Animation<Offset> _prizeSlide;

  bool _isClaiming = false;

  @override
  void initState() {
    super.initState();

    // Trophy animation
    _trophyController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _trophyScale = CurvedAnimation(
      parent: _trophyController,
      curve: Curves.elasticOut,
    );
    _trophyRotation = Tween<double>(begin: -0.2, end: 0.0).animate(
      CurvedAnimation(parent: _trophyController, curve: Curves.easeOut),
    );

    // Prize cards animation
    _prizeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _prizeOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _prizeController, curve: Curves.easeIn),
    );
    _prizeSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _prizeController, curve: Curves.easeOut),
    );

    // Button animation
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Start animations sequentially
    _startAnimations();

    // Haptic feedback
    HapticFeedback.heavyImpact();
  }

  void _startAnimations() async {
    await _trophyController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    await _prizeController.forward();
    _buttonController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _trophyController.dispose();
    _prizeController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  Future<void> _claimPrize() async {
    if (_isClaiming) return;

    setState(() => _isClaiming = true);
    HapticFeedback.mediumImpact();

    final success = await widget.prizeService.claimPrize(widget.prize);

    if (success && mounted) {
      HapticFeedback.heavyImpact();
      // Close screen after a short delay
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate claimed
      }
    } else {
      setState(() => _isClaiming = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to claim prize. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _getGradientColors(),
              ),
            ),
          ),

          // Confetti overlay
          const Positioned.fill(
            child: ConfettiWidget(numberOfParticles: 150),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),

                // Title
                Text(
                  'CONGRATULATIONS!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Trophy with animation
                ScaleTransition(
                  scale: _trophyScale,
                  child: RotationTransition(
                    turns: _trophyRotation,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getTrophyColor(),
                        boxShadow: [
                          BoxShadow(
                            color: _getTrophyColor().withOpacity(0.5),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.emoji_events,
                        size: 70,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Rank text
                Text(
                  widget.prize.rankSuffix.toUpperCase() + ' PLACE',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Tournament name
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    widget.prize.tournamentName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.9),
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Prize cards with animation
                FadeTransition(
                  opacity: _prizeOpacity,
                  child: SlideTransition(
                    position: _prizeSlide,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.prize.coins > 0)
                          _buildPrizeCard(
                            '🪙',
                            '${widget.prize.coins}',
                            'Coins',
                            Colors.amber,
                          ),
                        if (widget.prize.coins > 0 && widget.prize.gems > 0)
                          const SizedBox(width: 20),
                        if (widget.prize.gems > 0)
                          _buildPrizeCard(
                            '💎',
                            '${widget.prize.gems}',
                            'Gems',
                            Colors.cyan,
                          ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Claim button with animation
                AnimatedBuilder(
                  animation: _buttonController,
                  builder: (context, child) {
                    final scale = 1.0 + (_buttonController.value * 0.05);
                    return Transform.scale(
                      scale: scale,
                      child: child,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _isClaiming ? null : _claimPrize,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _getTrophyColor(),
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 10,
                        ),
                        child: _isClaiming
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'CLAIM PRIZE',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrizeCard(
      String emoji, String amount, String label, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 50),
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getGradientColors() {
    switch (widget.prize.trophyColor) {
      case 'gold':
        return [const Color(0xFFFFD700), const Color(0xFFFF8C00)];
      case 'silver':
        return [const Color(0xFFC0C0C0), const Color(0xFF808080)];
      case 'bronze':
        return [const Color(0xFFCD7F32), const Color(0xFF8B4513)];
      default:
        return [const Color(0xFF4CAF50), const Color(0xFF2E7D32)];
    }
  }

  Color _getTrophyColor() {
    switch (widget.prize.trophyColor) {
      case 'gold':
        return const Color(0xFFFFD700);
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'bronze':
        return const Color(0xFFCD7F32);
      default:
        return const Color(0xFF4CAF50);
    }
  }
}


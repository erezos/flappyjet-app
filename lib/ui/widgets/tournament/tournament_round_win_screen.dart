/// 🏆 Tournament Round Win Screen - Celebration for each round win!
/// 
/// Beautiful celebration screen shown when player wins a tournament round.
/// Features confetti, animated stage name, reward showcase, and continue button.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../../../models/tournament_config.dart';
import '../coin_3d_icon.dart';
import '../gem_3d_icon.dart';

class TournamentRoundWinScreen extends StatefulWidget {
  final TournamentConfig tournament;
  final String stageName; // e.g., "Quarter Finals", "Semi Finals", "Grand Finals"
  final int roundNumber;
  final int coinsEarned;
  final int gemsEarned;
  final bool isFinalRound;
  final VoidCallback onContinue;

  const TournamentRoundWinScreen({
    super.key,
    required this.tournament,
    required this.stageName,
    required this.roundNumber,
    required this.coinsEarned,
    required this.gemsEarned,
    this.isFinalRound = false,
    required this.onContinue,
  });

  @override
  State<TournamentRoundWinScreen> createState() => _TournamentRoundWinScreenState();
}

class _TournamentRoundWinScreenState extends State<TournamentRoundWinScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late AnimationController _rewardsController;
  
  // Animations
  late Animation<double> _titleScaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rewardsSlideAnimation;
  late Animation<double> _rewardsFadeAnimation;
  
  // Confetti controller
  late ConfettiController _confettiController;
  
  // State
  bool _showRewards = false;
  bool _showButton = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startCelebrationSequence();
  }

  void _initializeAnimations() {
    // Main controller for entry animation
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Pulse controller for glow effects
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    // Shimmer for gold effects
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    // Rewards animation controller
    _rewardsController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Title entrance with bounce
    _titleScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 40,
      ),
    ]).animate(_mainController);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rewardsSlideAnimation = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(
        parent: _rewardsController,
        curve: Curves.easeOutBack,
      ),
    );

    _rewardsFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _rewardsController,
        curve: Curves.easeIn,
      ),
    );

    // Initialize confetti controller
    _confettiController = ConfettiController(duration: const Duration(seconds: 5));
  }

  void _startCelebrationSequence() async {
    // Start main animation
    _mainController.forward();
    
    // Start confetti
    await Future.delayed(const Duration(milliseconds: 200));
    _confettiController.play();
    
    // Show rewards after title animation
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() => _showRewards = true);
      _rewardsController.forward();
    }
    
    // Show button
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      setState(() => _showButton = true);
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    _rewardsController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    // Get tournament background image path
    final backgroundImagePath = 'assets/images/tournaments/${widget.tournament.id}.png';
    
    return Scaffold(
      body: Stack(
        children: [
          // Blurred tournament background
          Positioned.fill(
            child: Image.asset(
              backgroundImagePath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: const Color(0xFF0A0A1F));
              },
            ),
          ),
          
          // Dark overlay with blur effect
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0A0A1F).withOpacity(0.90),
                    _getTierColor().withOpacity(0.3),
                    const Color(0xFF0F0F1A).withOpacity(0.95),
                  ],
                ),
              ),
            ),
          ),
          
          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.08),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),
                    
                    // Victory icon with glow
                    _buildVictoryIcon(screenSize),
                    
                    SizedBox(height: screenSize.height * 0.03),
                    
                    // "YOU WON" title
                    _buildWinTitle(screenSize),
                    
                    SizedBox(height: screenSize.height * 0.015),
                    
                    // Stage name (e.g., "Quarter Finals")
                    _buildStageName(screenSize),
                    
                    SizedBox(height: screenSize.height * 0.04),
                    
                    // Rewards section
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: _showRewards ? 1.0 : 0.0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: _showRewards ? null : 0,
                        child: _showRewards 
                            ? _buildRewardsSection(screenSize)
                            : const SizedBox.shrink(),
                      ),
                    ),
                    
                    const Spacer(flex: 2),
                    
                    // Continue button
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: _showButton ? 1.0 : 0.0,
                      child: _showButton 
                          ? _buildContinueButton(screenSize)
                          : const SizedBox.shrink(),
                    ),
                    
                    SizedBox(height: screenSize.height * 0.05),
                  ],
                ),
              ),
            ),
          ),
          
          // Confetti overlay
          _buildConfettiOverlay(),
        ],
      ),
    );
  }

  Widget _buildVictoryIcon(Size screenSize) {
    final iconSize = screenSize.width * 0.25;
    
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.amber.withOpacity(0.4 * _pulseAnimation.value),
                Colors.amber.withOpacity(0.1),
                Colors.transparent,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.4 * _pulseAnimation.value),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Center(
            child: Text(
              '🎉',
              style: TextStyle(fontSize: iconSize * 0.6),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWinTitle(Size screenSize) {
    final fontSize = screenSize.width * 0.10;
    
    return AnimatedBuilder(
      animation: _titleScaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _titleScaleAnimation.value,
          child: ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                colors: const [
                  Colors.amber,
                  Colors.yellow,
                  Colors.orange,
                  Colors.amber,
                ],
              ).createShader(bounds);
            },
            child: Text(
              'YOU WON!',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 4,
                shadows: [
                  Shadow(
                    color: Colors.amber.withOpacity(0.8),
                    blurRadius: 20,
                  ),
                  const Shadow(
                    color: Colors.black,
                    blurRadius: 10,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStageName(Size screenSize) {
    final fontSize = screenSize.width * 0.055;
    
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: _getTierColor().withOpacity(0.2),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: _getTierColor().withOpacity(0.6),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: _getTierColor().withOpacity(0.3 * _pulseAnimation.value),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Text(
            widget.stageName.toUpperCase(),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        );
      },
    );
  }

  Widget _buildRewardsSection(Size screenSize) {
    final padding = screenSize.width * 0.05;
    final titleSize = screenSize.width * 0.035;
    final valueSize = screenSize.width * 0.055;
    
    return AnimatedBuilder(
      animation: Listenable.merge([_rewardsSlideAnimation, _rewardsFadeAnimation]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _rewardsSlideAnimation.value),
          child: Opacity(
            opacity: _rewardsFadeAnimation.value,
            child: Container(
              padding: EdgeInsets.all(padding),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.amber.withOpacity(0.25),
                    Colors.orange.withOpacity(0.15),
                    Colors.amber.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.amber.withOpacity(0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.stars, color: Colors.amber, size: titleSize + 4),
                      const SizedBox(width: 8),
                      Text(
                        'ROUND REWARDS',
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: titleSize,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.stars, color: Colors.amber, size: titleSize + 4),
                    ],
                  ),
                  SizedBox(height: padding * 0.8),
                  
                  // Rewards row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Coins
                      _buildRewardItem(
                        icon: Coin3DIcon(size: valueSize * 1.4),
                        value: widget.coinsEarned,
                        valueSize: valueSize,
                      ),
                      
                      // Divider
                      Container(
                        width: 2,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.amber.withOpacity(0.5),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      
                      // Gems
                      _buildRewardItem(
                        icon: Gem3DIcon(size: valueSize * 1.4),
                        value: widget.gemsEarned,
                        valueSize: valueSize,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRewardItem({
    required Widget icon,
    required int value,
    required double valueSize,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 8),
            Text(
              '+${animatedValue.toInt()}',
              style: TextStyle(
                fontSize: valueSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.amber.withOpacity(0.5),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContinueButton(Size screenSize) {
    final buttonHeight = screenSize.height * 0.065;
    final fontSize = screenSize.width * 0.04;
    
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      tween: Tween<double>(begin: 0.8, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTap: widget.onContinue,
            child: Container(
              width: double.infinity,
              height: buttonHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.amber.shade400,
                    Colors.orange.shade600,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.isFinalRound ? Icons.emoji_events : Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: fontSize + 6,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.isFinalRound ? 'CLAIM VICTORY!' : 'CONTINUE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConfettiOverlay() {
    return Stack(
      children: [
        // Center top confetti
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: math.pi / 2,
            blastDirectionality: BlastDirectionality.explosive,
            maxBlastForce: 12,
            minBlastForce: 5,
            emissionFrequency: 0.06,
            numberOfParticles: 20,
            gravity: 0.15,
            colors: [
              Colors.amber,
              Colors.orange,
              Colors.yellow,
              _getTierColor(),
              Colors.white,
            ],
          ),
        ),
        // Left side
        Align(
          alignment: Alignment.topLeft,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: -math.pi / 4,
            maxBlastForce: 15,
            minBlastForce: 6,
            emissionFrequency: 0.08,
            numberOfParticles: 10,
            gravity: 0.12,
            colors: [
              Colors.amber,
              _getTierColor(),
            ],
          ),
        ),
        // Right side
        Align(
          alignment: Alignment.topRight,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: -3 * math.pi / 4,
            maxBlastForce: 15,
            minBlastForce: 6,
            emissionFrequency: 0.08,
            numberOfParticles: 10,
            gravity: 0.12,
            colors: [
              Colors.amber,
              _getTierColor(),
            ],
          ),
        ),
      ],
    );
  }

  Color _getTierColor() {
    switch (widget.tournament.tier) {
      case TournamentTier.bronze:
        return const Color(0xFFCD7F32);
      case TournamentTier.silver:
        return const Color(0xFFC0C0C0);
      case TournamentTier.gold:
        return const Color(0xFFFFD700);
      case TournamentTier.platinum:
        return const Color(0xFF00CED1);
      case TournamentTier.special:
        return const Color(0xFF9C27B0);
    }
  }
}


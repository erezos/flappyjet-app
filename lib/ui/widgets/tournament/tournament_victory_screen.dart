/// 🏆 Tournament Victory Screen - Epic Celebration!
/// 
/// Stunning celebration screen shown when player wins a tournament.
/// Features confetti explosions, animated trophy, reward showcase, and grand finale!
library;

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../../../models/tournament_config.dart';
import '../../../models/tournament_entry.dart';
import '../../../game/systems/tournament_manager.dart';
import '../coin_3d_icon.dart';
import '../gem_3d_icon.dart';
import '../tournament_ticket_icon.dart';
import '../../../game/core/jet_skins.dart';

class TournamentVictoryScreen extends StatefulWidget {
  final TournamentConfig tournament;
  final TournamentEntry entry;
  /// Optional callback for testing - if not provided, screen handles navigation itself
  final VoidCallback? onContinue;
  /// Testing flag to skip long delays/animations to make widget tests stable.
  final bool testingFastMode;

  const TournamentVictoryScreen({
    super.key,
    required this.tournament,
    required this.entry,
    this.onContinue,
    this.testingFastMode = false,
  });

  @override
  State<TournamentVictoryScreen> createState() => _TournamentVictoryScreenState();
}

class _TournamentVictoryScreenState extends State<TournamentVictoryScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late AnimationController _rewardsController;
  late AnimationController _coinShowerController;
  
  // Animations
  late Animation<double> _trophyScaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _rewardsSlideAnimation;
  late Animation<double> _rewardsFadeAnimation;
  
  // Confetti controllers
  late ConfettiController _confettiCenter;
  late ConfettiController _confettiLeft;
  late ConfettiController _confettiRight;
  
  // State
  bool _showRewards = false;
  bool _showButton = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    if (widget.testingFastMode) {
      _startCelebrationSequenceFast();
    } else {
      _startCelebrationSequence();
    }
  }

  void _initializeAnimations() {
    // Main controller for entry animation
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Pulse controller for continuous trophy glow
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Shimmer for gold effects
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    // Rewards animation controller
    _rewardsController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Coin shower animation
    _coinShowerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Trophy entrance with bounce
    _trophyScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.3)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 40,
      ),
    ]).animate(_mainController);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
    );

    _rewardsSlideAnimation = Tween<double>(begin: 50, end: 0).animate(
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

    // Initialize confetti controllers
    _confettiCenter = ConfettiController(duration: const Duration(seconds: 10));
    _confettiLeft = ConfettiController(duration: const Duration(seconds: 10));
    _confettiRight = ConfettiController(duration: const Duration(seconds: 10));
  }

  void _startCelebrationSequenceFast() {
    // Jump animations to end states for tests to avoid pending timers.
    _mainController.value = 1.0;
    _rewardsController.value = 1.0;
    _coinShowerController.value = 1.0;
    _confettiCenter.stop();
    _confettiLeft.stop();
    _confettiRight.stop();
    _showRewards = true;
    _showButton = true;
  }

  void _startCelebrationSequence() async {
    // Start main animation
    _mainController.forward();
    
    // Start confetti immediately
    await Future.delayed(const Duration(milliseconds: 300));
    _confettiCenter.play();
    _confettiLeft.play();
    _confettiRight.play();
    
    // Show rewards after trophy animation
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) {
      setState(() => _showRewards = true);
      _rewardsController.forward();
    }
    
    // Start coin shower
    await Future.delayed(const Duration(milliseconds: 400));
    _coinShowerController.forward();
    
    // Show button
    await Future.delayed(const Duration(milliseconds: 600));
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
    _coinShowerController.dispose();
    _confettiCenter.dispose();
    _confettiLeft.dispose();
    _confettiRight.dispose();
    super.dispose();
  }

  void _handleBackToHub() {
    if (widget.onContinue != null) {
      widget.onContinue!();
    } else {
      TournamentManager().clearActiveEntry(tournamentId: widget.tournament.id);
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Stack(
        children: [
          // Animated background
          _buildAnimatedBackground(),
          
          // Main content - scrollable for small screens, fits in one screen for normal
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
      child: LayoutBuilder(
                builder: (context, constraints) {
                  final isSmallScreen = constraints.maxHeight < 500;
                  
                  return SingleChildScrollView(
                    physics: isSmallScreen 
                        ? const BouncingScrollPhysics() 
                        : const NeverScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.05),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // 🏆 CHAMPION text
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: _buildChampionHeader(screenSize),
                              ),
                              
                              // Trophy with glow - responsive size
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: SizedBox(
                                  height: constraints.maxHeight * 0.30,
                                  child: _buildTrophySectionResponsive(
                                    constraints.maxHeight * 0.25, 
                                    constraints.maxWidth * 0.80,
                                  ),
                                ),
                              ),
                              
                              // Tournament name
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: _buildTournamentName(screenSize),
                              ),
                              
                              // Rewards section - only rendered when visible
                              if (_showRewards)
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: screenSize.width * 0.9,
                                    ),
                                    child: _buildRewardsSection(screenSize),
                                  ),
                                ),
                              
                              // Button at bottom
                              if (_showButton)
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: screenSize.width * 0.9,
                                    maxHeight: 56,
                                  ),
                                  child: _buildContinueButton(screenSize),
                                ),
                              
                              const SizedBox(height: 4),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Confetti overlays
          _buildConfettiOverlays(),
        ],
      ),
    );
  }
  
  /// Responsive trophy that scales based on available space
  Widget _buildTrophySectionResponsive(double availableHeight, double availableWidth) {
    // Trophy takes 80% of available height or width (whichever is smaller)
    final trophySize = (availableHeight * 0.8).clamp(50.0, availableWidth * 0.7);
    
    // Use tournament's custom trophy if available, otherwise fallback to default
    String trophyImagePath;
    final trophyId = widget.tournament.completionReward.trophyId;
    if (trophyId != null) {
      if (trophyId == 'christmas_champion_trophy') {
        trophyImagePath = 'tournaments/Christmas/christmas_trophy.png';
      } else {
        // Try mapped path first
        final trophyPathMap = {
          'bosses_showdown_champion': 'trophy_bosses_showdown.png',
          'stunt_master_trophy': 'trophy_stunt_tournament.png',
          'chopper_champion_trophy': 'trophy_chopper_adventures.png',
        };
        final mappedPath = trophyPathMap[trophyId];
        if (mappedPath != null) {
          trophyImagePath = 'tournaments/$mappedPath';
        } else {
          trophyImagePath = 'tournaments/trophy_$trophyId.png';
        }
      }
    } else {
      trophyImagePath = 'tournaments/trophy_${widget.tournament.id}.png';
    }
    
    return AnimatedBuilder(
      animation: Listenable.merge([_trophyScaleAnimation, _pulseAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _trophyScaleAnimation.value,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glow effect behind trophy
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: trophySize * 1.2,
                    height: trophySize * 1.2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.5 * _pulseAnimation.value),
                          blurRadius: 60,
                          spreadRadius: 20,
                        ),
                        BoxShadow(
                          color: _getTierColor().withValues(alpha: 0.3 * _pulseAnimation.value),
                          blurRadius: 40,
                          spreadRadius: 15,
                        ),
                      ],
                    ),
                  );
                },
              ),
              
              // Trophy image - scales with available space
              Image.asset(
                'assets/images/$trophyImagePath',
                width: trophySize,
                height: trophySize,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Text(
                    '🏆',
                    style: TextStyle(fontSize: trophySize * 0.6),
                  );
                },
              ),
              
              // Sparkle overlay
              AnimatedBuilder(
                animation: _shimmerController,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size(trophySize + 40, trophySize + 40),
                    painter: _SparklePainter(
                      progress: _shimmerAnimation.value,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedBackground() {
    // Use tournament image for background (from display.bannerImage)
    final bannerImage = widget.tournament.display.bannerImage;
    String bannerPath;
    if (bannerImage == 'christmas_tournament_image.png') {
      bannerPath = 'assets/images/tournaments/Christmas/christmas_tournament_image.png';
    } else if (bannerImage.endsWith('.png')) {
      bannerPath = 'assets/images/$bannerImage';
    } else {
      bannerPath = 'assets/images/$bannerImage.png';
    }

    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Blurred tournament banner for thematic backdrop
            Positioned.fill(
              child: ClipRect(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.25),
                      BlendMode.darken,
                    ),
                    child: Image.asset(
                      bannerPath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),
            // Gradient overlay shimmer for depth
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1A1A2E),
                    _getTierColor().withValues(alpha: 0.25),
                    const Color(0xFF0F0F1A),
                    _getTierColor().withValues(alpha: 0.18),
                    const Color(0xFF1A1A2E),
                  ],
                  stops: [
                    0.0,
                    (_shimmerAnimation.value * 0.45).clamp(0.0, 1.0),
                    0.5,
                    (_shimmerAnimation.value * 0.45 + 0.28).clamp(0.0, 1.0),
                    1.0,
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildConfettiOverlays() {
    return Stack(
      children: [
        // Center confetti
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiCenter,
            blastDirection: math.pi / 2,
            blastDirectionality: BlastDirectionality.explosive,
            maxBlastForce: 15,
            minBlastForce: 5,
            emissionFrequency: 0.05,
            numberOfParticles: 30,
            gravity: 0.2,
            colors: [
              Colors.amber,
              Colors.orange,
              Colors.yellow,
              _getTierColor(),
              Colors.white,
              const Color(0xFFFFD700),
            ],
          ),
        ),
        // Left side confetti
        Align(
          alignment: Alignment.topLeft,
          child: ConfettiWidget(
            confettiController: _confettiLeft,
            blastDirection: -math.pi / 4,
            maxBlastForce: 20,
            minBlastForce: 8,
            emissionFrequency: 0.08,
            numberOfParticles: 15,
            gravity: 0.15,
            colors: [
              Colors.amber,
              Colors.orange,
              _getTierColor(),
            ],
          ),
        ),
        // Right side confetti
        Align(
          alignment: Alignment.topRight,
          child: ConfettiWidget(
            confettiController: _confettiRight,
            blastDirection: -3 * math.pi / 4,
            maxBlastForce: 20,
            minBlastForce: 8,
            emissionFrequency: 0.08,
            numberOfParticles: 15,
            gravity: 0.15,
            colors: [
              Colors.amber,
              Colors.orange,
              _getTierColor(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChampionHeader(Size screenSize) {
    // Scale font based on screen width for consistency across devices
    final fontSize = screenSize.width * 0.075; // 7.5% of screen width
    
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value * 0.95,
          child: ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                colors: [
                  Colors.amber,
                  Colors.yellow,
                  Colors.orange,
                  Colors.amber,
                ],
                stops: [
                  0.0,
                  _shimmerAnimation.value.clamp(0.0, 0.5),
                  (_shimmerAnimation.value + 0.3).clamp(0.0, 1.0),
                  1.0,
                ],
              ).createShader(bounds);
            },
            child: Text(
              '🏆 CHAMPION! 🏆',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 3,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTournamentName(Size screenSize) {
    // Scale font based on screen width
    final fontSize = screenSize.width * 0.05; // 5% of screen width
    
    return Text(
      widget.tournament.name,
      style: TextStyle(
        fontSize: fontSize,
        color: _getTierColor(),
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildRewardsSection(Size screenSize) {
    // Use proportional sizes for rewards section
    final padding = screenSize.width * 0.045; // 4.5% of screen width
    final titleSize = screenSize.width * 0.035; // 3.5% of screen width
    final valueSize = screenSize.width * 0.06; // 6% of screen width
    // Note: entry.coinsEarned and entry.gemsEarned already include the completion reward
    // (added in TournamentEntry.completeTournament), so we don't need to add it again
    final totalCoins = widget.entry.coinsEarned;
    final totalGems = widget.entry.gemsEarned;
    final completionReward = widget.tournament.completionReward;
    
    return AnimatedBuilder(
      animation: Listenable.merge([_rewardsSlideAnimation, _rewardsFadeAnimation]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _rewardsSlideAnimation.value),
          child: Opacity(
            opacity: _rewardsFadeAnimation.value,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(padding),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.amber.withValues(alpha: 0.3),
                    Colors.orange.withValues(alpha: 0.2),
                    Colors.amber.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.amber.withValues(alpha: 0.6),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Only take needed space
                children: [
                  // Header (wrap to avoid overflow on narrow screens)
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.amber, size: titleSize + 4),
                      Text(
                        'TOTAL REWARDS',
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: titleSize,
                          letterSpacing: 2,
                        ),
                      ),
                      Icon(Icons.auto_awesome, color: Colors.amber, size: titleSize + 4),
                    ],
                  ),
                  SizedBox(height: padding),
                  
                  // Rewards row (wrap to avoid clipping on narrow screens)
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: padding,
                    runSpacing: padding * 0.5,
                    children: [
                      _buildAnimatedReward(
                        icon: Coin3DIcon(size: valueSize * 1.5),
                        value: totalCoins,
                        label: 'COINS',
                        valueSize: valueSize,
                        delay: 0,
                      ),
                      _buildAnimatedReward(
                        icon: Gem3DIcon(size: valueSize * 1.5),
                        value: totalGems,
                        label: 'GEMS',
                        valueSize: valueSize,
                        delay: 1,
                      ),
                      if (completionReward.skinId != null)
                    _buildSkinRewardIcon(completionReward.skinId!, valueSize * 4.0), // Much bigger jet skin
                      if (completionReward.freeTicketTier != null)
                        TournamentTicketIcon(
                          tier: completionReward.freeTicketTier!,
                      size: valueSize * 1.8,
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

  Widget _buildAnimatedReward({
    required Widget icon,
    required int value,
    required String label,
    required double valueSize,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800 + (delay * 200)),
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        return Column(
          children: [
            icon,
            const SizedBox(height: 8),
            Text(
              '+${animatedValue.toInt()}',
              style: TextStyle(
                fontSize: valueSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.amber.withValues(alpha: 0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: valueSize * 0.4,
                color: Colors.white.withValues(alpha: 0.7),
                letterSpacing: 1,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSkinRewardIcon(String skinId, double desiredSize) {
    final jetSkin = JetSkinCatalog.getAllSkins().firstWhere(
      (skin) => skin.id == skinId,
      orElse: () => JetSkinCatalog.starterJet,
    );

    // Use LayoutBuilder to constrain the jet skin to prevent overflow
    return LayoutBuilder(
      builder: (context, constraints) {
        // Max 80% of available width to prevent overflow
        final maxImageWidth = constraints.maxWidth * 0.8;
        final actualSize = desiredSize.clamp(desiredSize * 0.5, maxImageWidth);

        return Image.asset(
          'assets/images/${jetSkin.assetPath}',
          width: actualSize,
          height: actualSize,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Text('✨', style: TextStyle(fontSize: actualSize * 0.6)),
        );
      },
    );
  }

  Widget _buildContinueButton(Size screenSize) {
    // Proportional button sizing
    final buttonHeight = screenSize.height * 0.065; // 6.5% of screen height
    final fontSize = screenSize.width * 0.04; // 4% of screen width
    
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      tween: Tween<double>(begin: 0.8, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTap: _handleBackToHub,
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
                    color: Colors.amber.withValues(alpha: 0.5),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.celebration, color: Colors.white, size: fontSize + 4),
                  const SizedBox(width: 12),
                  Text(
                    'CLAIM & CONTINUE',
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

/// Custom painter for sparkle effects around the trophy
class _SparklePainter extends CustomPainter {
  final double progress;
  final Color color;

  _SparklePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final random = math.Random(42); // Fixed seed for consistent sparkles

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw several sparkles around the trophy
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * math.pi + progress * math.pi;
      final sparkleRadius = radius * (0.9 + random.nextDouble() * 0.3);
      final x = center.dx + math.cos(angle) * sparkleRadius;
      final y = center.dy + math.sin(angle) * sparkleRadius;
      
      // Sparkle opacity varies with progress
      final opacity = ((math.sin(progress * math.pi * 2 + i) + 1) / 2) * 0.8;
      paint.color = color.withValues(alpha: opacity);
      
      // Draw diamond sparkle
      final sparkleSize = 4 + random.nextDouble() * 4;
      final path = Path();
      path.moveTo(x, y - sparkleSize);
      path.lineTo(x + sparkleSize * 0.5, y);
      path.lineTo(x, y + sparkleSize);
      path.lineTo(x - sparkleSize * 0.5, y);
      path.close();
      
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_SparklePainter oldDelegate) => 
      progress != oldDelegate.progress;
}

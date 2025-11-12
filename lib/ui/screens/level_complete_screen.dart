/// 🎉 STORY MODE - LEVEL COMPLETE SCREEN
/// 
/// Shows level completion with rewards and next level button.
library;

import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../../models/level_data_schema.dart';
import '../../game/systems/level_reward_manager.dart';
import '../../game/systems/level_system_manager.dart';
import '../../game/core/jet_skins.dart';
import '../../core/debug_logger.dart';
import 'world_map_screen.dart';
import 'level_objective_popup.dart';
import 'zone_completion_celebration_screen.dart';
import '../widgets/buttons/modern_game_button.dart';
import '../widgets/buttons/button_styles.dart';

/// Get bot jet sprite path from JetSkinCatalog
String _getBotJetSpritePath(String botJetSkinId) {
  // Look up the jet skin in the catalog
  final allSkins = JetSkinCatalog.getAllSkins();
  final jetSkin = allSkins.firstWhere(
    (skin) => skin.id == botJetSkinId,
    orElse: () => JetSkinCatalog.starterJet, // Fallback to starter jet
  );
  
  // Return full asset path
  return 'assets/images/${jetSkin.assetPath}';
}

class LevelCompleteScreen extends StatefulWidget {
  final LevelData level;
  final int objectiveAchieved;
  final int timeTaken;
  final int continuesUsed;
  
  /// ✅ NEW: Callback when user wants to continue (close popup and animate)
  final VoidCallback? onContinue;

  const LevelCompleteScreen({
    super.key,
    required this.level,
    required this.objectiveAchieved,
    required this.timeTaken,
    required this.continuesUsed,
    this.onContinue,
  });

  @override
  State<LevelCompleteScreen> createState() => _LevelCompleteScreenState();
}

class _LevelCompleteScreenState extends State<LevelCompleteScreen>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  
  // Smoke animation controller for VS battles
  late AnimationController _smokeController;

  final LevelRewardManager _rewardManager = LevelRewardManager();
  final LevelSystemManager _levelSystemManager = LevelSystemManager();

  bool _rewardsGranted = false;
  late bool _isReplay;

  @override
  void initState() {
    super.initState();

    // Check if this is a replay
    _isReplay = _levelSystemManager.isLevelReplay(widget.level.id);
    safePrint('🎉 Level Complete Screen: isReplay = $_isReplay');

    // Setup confetti
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    // Setup main animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
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
    
    // Setup smoke animation (one-time only - smoke rises and fades once)
    _smokeController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    
    // Start the smoke animation (runs once then stops)
    _smokeController.forward();

    // Start animations
    _animationController.forward();
    _confettiController.play();

    // Grant rewards
    _grantRewards();
  }

  Future<void> _grantRewards() async {
    if (_rewardsGranted) return;

    try {
      // Calculate rewards (different for replay)
      final reward = _rewardManager.calculateRewards(
        widget.level,
        isReplay: _isReplay,
      );

      // Grant rewards
      await _rewardManager.grantRewards(
        levelId: widget.level.id,
        reward: reward,
        isReplay: _isReplay,
      );

      _rewardsGranted = true;
      safePrint('🎉 Rewards granted for level ${widget.level.id} (replay: $_isReplay)');
    } catch (e) {
      safePrint('❌ Error granting rewards: $e');
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _animationController.dispose();
    _smokeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // ✅ NEW: Handle back button (same as Continue)
    return WillPopScope(
      onWillPop: () async {
        _handleContinue();
        return false; // Don't let system handle it
      },
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(0.7), // Semi-transparent overlay
        body: Stack(
          children: [
            // Confetti (full screen)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                colors: const [
                  Colors.red,
                  Colors.blue,
                  Colors.green,
                  Colors.yellow,
                  Colors.orange,
                  Colors.purple,
                  Color(0xFFFFD700), // Gold
                  Colors.pink,
                ],
                numberOfParticles: 40, // More confetti!
                gravity: 0.25,
                emissionFrequency: 0.05,
              ),
            ),

            // ✅ NEW: Single cohesive popup with X button inside
            SafeArea(
              child: Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: _buildModernPopup(screenWidth, screenHeight),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ NEW: Modern, colorful, engaging popup with X button integrated - COMPACT VERSION
  Widget _buildModernPopup(double screenWidth, double screenHeight) {
    final isSmallScreen = screenWidth < 375;
    final popupWidth = (screenWidth * 0.85).clamp(280.0, 420.0); // ✅ SMALLER: 90% → 85%
    
    // ✅ DYNAMIC ICON: Choose icon based on objective type
    String? trophyIconPath;
    if (widget.level.botBattle == null) {
      // Not a VS level - use mission icons
      if (widget.level.objective.type == ObjectiveType.surviveTime) {
        trophyIconPath = 'assets/images/icons/missions/gold_timer_icon.png';
      } else {
        // Obstacle/collect objectives - randomly pick star or trophy
        final random = (widget.level.id + DateTime.now().millisecond) % 2;
        trophyIconPath = random == 0 
          ? 'assets/images/icons/missions/gold_star_badge_icon.png'
          : 'assets/images/icons/missions/gold_trophy.png';
      }
    }
    // For VS battles, trophyIconPath stays null and we show the crashed jet instead
    
    return Container(
      width: popupWidth,
      margin: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: screenHeight * 0.12, // ✅ SMALLER: More vertical margin
      ),
      decoration: BoxDecoration(
        // ✅ MODERN: Vibrant gradient background
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6A11CB), // Purple
            Color(0xFF2575FC), // Blue
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.6), // Gold border
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: 5,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Main content - NO SCROLLVIEW, COMPACT LAYOUT
          Padding(
            padding: EdgeInsets.fromLTRB(
              20, // ✅ SMALLER: 24 → 20
              isSmallScreen ? 48 : 52, // Top padding for X button
              20,
              20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ DYNAMIC: Trophy icon OR crashed jet
                // ✅ RESPONSIVE: Icon size scales with screen height (Flame/Flutter best practice)
                Builder(
                  builder: (context) {
                    final iconSize = (screenHeight * 0.09).clamp(60.0, 80.0); // 9% of screen height, min 60, max 80
                    
                    if (widget.level.botBattle != null) {
                      // VS Battle: Show crashed rival jet
                      return _buildCrashedRivalJet(iconSize);
                    } else if (trophyIconPath != null) {
                      // Mission icon with bounce animation
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 1200),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Transform.rotate(
                              angle: (1.0 - value) * 0.5,
                              child: Container(
                                width: iconSize, // ✅ RESPONSIVE: Scales with screen
                                height: iconSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFFD700).withOpacity(0.6),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  trophyIconPath!, // ✅ FIX: Add null assertion since we check != null above
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    } else {
                      return const SizedBox.shrink(); // Fallback
                    }
                  },
                ),
                SizedBox(height: widget.level.botBattle != null ? 12 : 14), // ✅ SMALLER spacing

                // ✅ COLORFUL: Title with gradient text effect
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFFFFD700),
                      Color(0xFFFFF59D),
                      Color(0xFFFFD700),
                    ],
                  ).createShader(bounds),
                  child: Text(
                    _isReplay ? 'REPLAY COMPLETE!' : 'LEVEL COMPLETE!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 22 : 24, // ✅ SMALLER: 24/28 → 22/24
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5, // ✅ SMALLER: 2 → 1.5
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6), // ✅ SMALLER: 8 → 6

                // Level info - NO BOX, just text
                Text(
                  'Level ${widget.level.id}: ${widget.level.name}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: isSmallScreen ? 13 : 14, // ✅ SMALLER: 14/16 → 13/14
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14), // ✅ SMALLER: 20 → 14

                // ✅ STATS: NO BOX, just rows with divider
                if (widget.level.objective.type != ObjectiveType.beatBot) ...[
                  _buildCompactStatRow('🎯', 'Objective', '${widget.objectiveAchieved}/${widget.level.objective.target}'),
                  Divider(height: 16, color: Colors.white.withOpacity(0.2), thickness: 1), // ✅ SMALLER: 12 → divider
                ],
                _buildCompactStatRow('⏱️', 'Time', '${widget.timeTaken}s'),
                const SizedBox(height: 14), // ✅ SMALLER: 20 → 14

                // ✅ REWARDS: NO BOX, just content with subtle background
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16), // ✅ SMALLER: 20 → 12
                  decoration: BoxDecoration(
                    color: (_isReplay ? Colors.blue : Colors.amber).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _isReplay ? '🔄 REPLAY REWARD' : '🎁 REWARDS',
                        style: TextStyle(
                          color: _isReplay ? const Color(0xFF64B5F6) : const Color(0xFFFFD700),
                          fontSize: isSmallScreen ? 13 : 14, // ✅ SMALLER: 15/17 → 13/14
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2, // ✅ SMALLER: 1.5 → 1.2
                        ),
                      ),
                      const SizedBox(height: 10), // ✅ SMALLER: 14 → 10
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildRewardItem(
                            icon: Icons.monetization_on,
                            iconColor: const Color(0xFFFFD700),
                            value: _isReplay ? '+20' : '+${widget.level.reward.coins}',
                          ),
                          if (!_isReplay && widget.level.reward.gems > 0) ...[
                            const SizedBox(width: 16), // ✅ SMALLER: 20 → 16
                            _buildRewardItem(
                              assetPath: 'assets/images/icons/gem_icon.png',
                              value: '+${widget.level.reward.gems}',
                            ),
                          ],
                        ],
                      ),
                      if (_isReplay) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Original reward already earned',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 10, // ✅ SMALLER: 11 → 10
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18), // ✅ SMALLER: 24 → 18

                // ✅ MODERN: Continue button
                SizedBox(
                  width: double.infinity,
                  height: 50, // ✅ SMALLER: 56 → 50
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4CAF50).withOpacity(0.5),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _handleContinue,
                        borderRadius: BorderRadius.circular(25),
                        child: Center(
                          child: Text(
                            'CONTINUE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isSmallScreen ? 17 : 18, // ✅ SMALLER: 18/20 → 17/18
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // ✅ INTEGRATED: X button inside popup (top-right)
          Positioned(
            top: 10,
            right: 10,
            child: GestureDetector(
              onTap: _handleContinue,
              child: Container(
                width: 36, // ✅ SMALLER: 40 → 36
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.4),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 20, // ✅ SMALLER: 22 → 20
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ NEW: Compact stat row - NO BOXES
  Widget _buildCompactStatRow(String emoji, String label, String value) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }


  /// ✅ NEW: Reward item with icon/asset and value
  Widget _buildRewardItem({
    IconData? icon,
    Color? iconColor,
    String? assetPath,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null)
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.3),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          )
        else if (assetPath != null)
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.3),
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Image.asset(assetPath, fit: BoxFit.contain),
            ),
          ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(
                color: Colors.black54,
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ],
    );
  }


  /// Build modern crashed rival jet visual for VS battles with REAL ANIMATED SMOKE
  Widget _buildCrashedRivalJet(double iconSize) {
    final bot = widget.level.botBattle!;
    final jetPath = _getBotJetSpritePath(bot.botJetSkin);
    
    // ✅ RESPONSIVE: Scale badge size proportionally with icon size
    final badgePaddingH = (iconSize * 0.34).clamp(16.0, 28.0); // ~24px at 70px
    final badgePaddingV = (iconSize * 0.14).clamp(8.0, 12.0); // ~10px at 70px
    final badgeFontSize = (iconSize * 0.26).clamp(14.0, 22.0); // ~18px at 70px
    
    return Column(
      children: [
        // "VICTORY!" badge with gold/green colors
        Container(
          padding: EdgeInsets.symmetric(horizontal: badgePaddingH, vertical: badgePaddingV),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFA500)], // Gold gradient
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: Colors.amber.shade200,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withValues(alpha: 0.6),
                blurRadius: 20,
                spreadRadius: 5,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            '🏆 VICTORY! 🏆',
            style: TextStyle(
              color: const Color(0xFF1A237E), // Dark blue for contrast on gold
              fontSize: badgeFontSize,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.5,
              shadows: const [
                Shadow(
                  color: Colors.white54,
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ),
        
        SizedBox(height: iconSize * 0.14), // ✅ RESPONSIVE: Reduced from ~20px to ~10px (0.29 → 0.14)
        
        // Crashed jet with REAL ANIMATED smoke particles
        // ✅ RESPONSIVE: Size scales proportionally with iconSize (Flame/Flutter best practice)
        SizedBox(
          width: iconSize,
          height: iconSize,
          child: AnimatedBuilder(
            animation: _smokeController,
            builder: (context, child) {
              // Normalized animation value (0.0 to 1.0)
              final t = _smokeController.value;
              
              // Different particles fade at different rates for layered effect
              final smoke1Opacity = (1.0 - t).clamp(0.0, 0.9);
              final smoke2Opacity = (1.0 - t * 0.9).clamp(0.0, 0.85);
              final smoke3Opacity = (1.0 - t * 1.1).clamp(0.0, 0.8);
              final smoke4Opacity = (1.0 - t * 0.85).clamp(0.0, 0.75);
              
              // Fire sparks flicker (sine wave for natural flicker)
              final sparkFlicker1 = 0.6 + (0.3 * (1.0 - t));
              final sparkFlicker2 = 0.7 + (0.3 * (1.0 - t * 0.8));
              
              // ✅ RESPONSIVE: Scale all positions and sizes proportionally (Flame/Flutter best practice)
              // Base design was for 70px, so scale factor = iconSize / 70
              final scaleFactor = iconSize / 70.0;
              double scaled(double baseValue) => baseValue * scaleFactor;
              
              return Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Large explosion smoke (background) - rotating and expanding
                  // ✅ RESPONSIVE: All values scale proportionally with iconSize
                  Positioned(
                    top: scaled(8) - (t * scaled(4)),
                    child: Transform.rotate(
                      angle: t * 1.2,
                      child: Opacity(
                        opacity: (0.5 - t * 0.3).clamp(0.0, 0.5),
                        child: Transform.scale(
                          scale: 1.0 + (t * 0.4),
                          child: Image.asset(
                            'assets/images/effects/explosion_smoke.png',
                            width: scaled(54),
                            height: scaled(54),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Rising smoke particle 1 (left side) - drifting up and left
                  Positioned(
                    top: scaled(4) - (t * scaled(14)),
                    left: scaled(8) - (t * scaled(6)),
                    child: Transform.rotate(
                      angle: t * 2.0,
                      child: Opacity(
                        opacity: smoke1Opacity,
                        child: Transform.scale(
                          scale: 0.6 + (t * 0.6),
                          child: Image.asset(
                            'assets/images/effects/smoke_particle_2.png',
                            width: scaled(20),
                            height: scaled(20),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Rising smoke particle 2 (right side) - drifting up and right
                  Positioned(
                    top: scaled(6) - (t * scaled(16)),
                    right: scaled(6) + (t * scaled(4)),
                    child: Transform.rotate(
                      angle: -t * 1.8,
                      child: Opacity(
                        opacity: smoke2Opacity,
                        child: Transform.scale(
                          scale: 0.5 + (t * 0.7),
                          child: Image.asset(
                            'assets/images/effects/smoke_particle_1.png',
                            width: scaled(18),
                            height: scaled(18),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Middle smoke puff (center-left) - rising and expanding
                  Positioned(
                    top: scaled(12) - (t * scaled(10)),
                    left: scaled(10) - (t * scaled(3)),
                    child: Transform.rotate(
                      angle: t * 2.5,
                      child: Opacity(
                        opacity: smoke3Opacity,
                        child: Transform.scale(
                          scale: 0.4 + (t * 0.5),
                          child: Image.asset(
                            'assets/images/effects/smoke_particle_3.png',
                            width: scaled(16),
                            height: scaled(16),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Additional smoke wisp (top center) - quick dissipation
                  Positioned(
                    top: scaled(2) - (t * scaled(18)),
                    left: scaled(26) + (t * scaled(2)),
                    child: Transform.rotate(
                      angle: -t * 2.2,
                      child: Opacity(
                        opacity: smoke4Opacity,
                        child: Transform.scale(
                          scale: 0.3 + (t * 0.5),
                          child: Image.asset(
                            'assets/images/effects/smoke_particle_1.png',
                            width: scaled(14),
                            height: scaled(14),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Fire spark 1 (flickering, stays near crash site)
                  Positioned(
                    top: scaled(26) + (t * scaled(1.2)),
                    left: scaled(14),
                    child: Opacity(
                      opacity: sparkFlicker1,
                      child: Transform.scale(
                        scale: 0.8 + (0.3 * (1.0 - t)),
                        child: Image.asset(
                          'assets/images/effects/fire_spark_1.png',
                          width: scaled(11),
                          height: scaled(11),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  
                  // Fire spark 2 (flickering, stays near crash site)
                  Positioned(
                    top: scaled(28) + (t * scaled(0.8)),
                    right: scaled(12),
                    child: Opacity(
                      opacity: sparkFlicker2,
                      child: Transform.scale(
                        scale: 0.7 + (0.4 * (1.0 - t)),
                        child: Image.asset(
                          'assets/images/effects/fire_spark_2.png',
                          width: scaled(10),
                          height: scaled(10),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  
                  // Additional ember (rises up)
                  Positioned(
                    top: scaled(14) - (t * scaled(8)),
                    right: scaled(16) - (t * scaled(2)),
                    child: Opacity(
                      opacity: (1.0 - t * 1.2).clamp(0.0, 0.9),
                      child: Transform.scale(
                        scale: 0.5 + (t * 0.4),
                        child: Image.asset(
                          'assets/images/effects/fire_spark_1.png',
                          width: scaled(7),
                          height: scaled(7),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  
                  // Orange explosion glow overlay (pulsing gently)
                  Positioned(
                    child: Container(
                      width: scaled(58) + (t * scaled(4)),
                      height: scaled(58) + (t * scaled(4)),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.orange.withValues(alpha: (0.3 - t * 0.2).clamp(0.0, 0.3)),
                            Colors.red.withValues(alpha: (0.2 - t * 0.15).clamp(0.0, 0.2)),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                  
                  // Tilted crashed jet - FULL COLOR (subtle shake only at beginning)
                  Positioned(
                    top: scaled(24) + (t < 0.2 ? t * scaled(1.2) : scaled(0.24)),
                    child: Transform.rotate(
                      angle: -0.25 + (t < 0.3 ? t * 0.1 : 0.03),
                      child: Container(
                        width: scaled(37),
                        height: scaled(37),
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.6),
                              blurRadius: 25,
                              spreadRadius: 3,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          jetPath,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        
        SizedBox(height: iconSize * 0.11), // ✅ FLAME RESPONSIVE: ~8px at 70px, scales with iconSize
        
        // Bot name with defeated styling
        Text(
          bot.botName,
          style: TextStyle(
            color: Colors.red.shade300,
            fontSize: (iconSize * 0.19).clamp(11.0, 15.0), // ✅ FLAME RESPONSIVE: ~13px at 70px, scales with iconSize
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.lineThrough,
            decorationColor: Colors.red.shade300,
            decorationThickness: 2,
          ),
        ),
      ],
    );
  }

  /// ✅ NEW: Handle Continue button / X button / Back button
  /// All three actions do the same thing: trigger the onContinue callback
  void _handleContinue() {
    if (widget.onContinue != null) {
      // New flow: Callback to parent (story_mode_game_wrapper)
      widget.onContinue!();
    } else {
      // Fallback to old flow (direct navigation)
      _onBackToMap();
    }
  }

  /// Check if there's a next level available
  /// ✅ FIX: Just check if next level exists, not if it's unlocked
  /// (it will be unlocked after completing the current level)
  bool _hasNextLevel() {
    final nextLevelId = widget.level.id + 1;
    final nextLevel = _levelSystemManager.getLevelById(nextLevelId);
    return nextLevel != null;
  }

  void _onNextLevel() {
    // Check if zone was just completed
    if (!_isReplay && _levelSystemManager.wasZoneJustCompleted(widget.level.id)) {
      _navigateToZoneCompletionCelebration();
      return;
    }

    final nextLevelId = widget.level.id + 1;
    final nextLevel = _levelSystemManager.getLevelById(nextLevelId);

    if (nextLevel != null && _levelSystemManager.isLevelUnlocked(nextLevelId)) {
      // Navigate to next level
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => LevelObjectivePopup(level: nextLevel),
        ),
      );
    } else {
      // No more levels or not unlocked yet
      _onBackToMap();
    }
  }

  void _navigateToZoneCompletionCelebration() {
    final zoneData = _levelSystemManager.getZoneById(widget.level.zone);
    if (zoneData == null) {
      safePrint('❌ Zone data not found for zone ${widget.level.zone}');
      _onBackToMap();
      return;
    }

    final stats = _levelSystemManager.getZoneStats(widget.level.zone);

    safePrint('🎉 Navigating to zone completion celebration for Zone ${widget.level.zone}');
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ZoneCompletionCelebrationScreen(
          completedZone: zoneData,
          totalCoins: stats['coins'] ?? 0,
          totalGems: stats['gems'] ?? 0,
          botWins: stats['botWins'] ?? 0,
        ),
      ),
    );
  }

  void _onBackToMap() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const WorldMapScreen(),
      ),
      (route) => route.isFirst, // ✅ Keep homepage in stack so back button works
    );
  }
}

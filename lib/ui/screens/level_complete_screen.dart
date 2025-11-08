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

  const LevelCompleteScreen({
    super.key,
    required this.level,
    required this.objectiveAchieved,
    required this.timeTaken,
    required this.continuesUsed,
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
    return Scaffold(
      backgroundColor: const Color(0xFF1A237E),
      body: Stack(
        children: [
          // Confetti
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
              ],
              numberOfParticles: 30,
              gravity: 0.3,
            ),
          ),

          // Content
          SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: _buildContent(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF283593), Color(0xFF1A237E)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title (same for replay and first time)
            const Text(
              '🎉 LEVEL COMPLETE! 🎉',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.amber,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),

            // Level info
            Text(
              'Level ${widget.level.id}: ${widget.level.name}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            
            // VS Battle: Show crashed rival jet
            if (widget.level.botBattle != null) ...[
              _buildCrashedRivalJet(),
              const SizedBox(height: 12),
            ],

            // Stats - No container, just the rows
            // Hide objective for VS levels (beatBot) - it's always shown as player score vs bot score
            if (widget.level.objective.type != ObjectiveType.beatBot) ...[
              _buildStatRow(
                'Objective',
                '✅ ${widget.objectiveAchieved}/${widget.level.objective.target}',
              ),
              const SizedBox(height: 6),
            ],
            _buildStatRow(
              'Time',
              '${widget.timeTaken}s',
            ),
            const SizedBox(height: 12),

            // Rewards - No container, just content
            Text(
              _isReplay ? '🔄 REPLAY REWARD' : 'REWARDS EARNED',
              style: TextStyle(
                color: _isReplay ? Colors.lightBlue : Colors.amber,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Coins
                const Icon(Icons.monetization_on,
                    color: Colors.amber, size: 24),
                const SizedBox(width: 6),
                Text(
                  _isReplay ? '+20' : '+${widget.level.reward.coins}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Gems (only for first completion)
                if (!_isReplay && widget.level.reward.gems > 0) ...[
                  const SizedBox(width: 24),
                  Image.asset(
                    'assets/images/icons/gem_icon.png',
                    width: 24,
                    height: 24,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '+${widget.level.reward.gems}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
            if (_isReplay) ...[
              const SizedBox(height: 4),
              Text(
                'Original reward already earned',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 12),

            // Buttons
            Column(
              children: [
                // ✅ FIX: Show "Next Level" button for replays too if next level exists
                if (_hasNextLevel()) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ModernGameButton(
                      label: 'NEXT LEVEL',
                      onPressed: _onNextLevel,
                      height: 50,
                      style: ModernButtonStyle.success, // Green for success
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                // Back to Map button
                SizedBox(
                  width: double.infinity,
                  child: ModernGameButton(
                    label: 'BACK TO MAP',
                    onPressed: _onBackToMap,
                    height: 50,
                    style: ModernButtonStyle.secondary, // Secondary blue
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Build modern crashed rival jet visual for VS battles with REAL ANIMATED SMOKE
  Widget _buildCrashedRivalJet() {
    final bot = widget.level.botBattle!;
    final jetPath = _getBotJetSpritePath(bot.botJetSkin);
    
    return Column(
      children: [
        // "VICTORY!" badge with gold/green colors
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
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
          child: const Text(
            '🏆 VICTORY! 🏆',
            style: TextStyle(
              color: Color(0xFF1A237E), // Dark blue for contrast on gold
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.5,
              shadows: [
                Shadow(
                  color: Colors.white54,
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Crashed jet with REAL ANIMATED smoke particles
        SizedBox(
          width: 180,
          height: 180,
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
              
              return Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Large explosion smoke (background) - rotating and expanding
                  Positioned(
                    top: 20 - (t * 10), // Rises slightly
                    child: Transform.rotate(
                      angle: t * 1.2, // Slow rotation
                      child: Opacity(
                        opacity: (0.5 - t * 0.3).clamp(0.0, 0.5),
                        child: Transform.scale(
                          scale: 1.0 + (t * 0.4),
                          child: Image.asset(
                            'assets/images/effects/explosion_smoke.png',
                            width: 140,
                            height: 140,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Rising smoke particle 1 (left side) - drifting up and left
                  Positioned(
                    top: 10 - (t * 35), // Rises upward
                    left: 20 - (t * 15), // Drifts left
                    child: Transform.rotate(
                      angle: t * 2.0,
                      child: Opacity(
                        opacity: smoke1Opacity,
                        child: Transform.scale(
                          scale: 0.6 + (t * 0.6), // Expands
                          child: Image.asset(
                            'assets/images/effects/smoke_particle_2.png',
                            width: 50,
                            height: 50,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Rising smoke particle 2 (right side) - drifting up and right
                  Positioned(
                    top: 15 - (t * 40), // Rises upward faster
                    right: 15 + (t * 10), // Drifts right
                    child: Transform.rotate(
                      angle: -t * 1.8,
                      child: Opacity(
                        opacity: smoke2Opacity,
                        child: Transform.scale(
                          scale: 0.5 + (t * 0.7), // Expands more
                          child: Image.asset(
                            'assets/images/effects/smoke_particle_1.png',
                            width: 45,
                            height: 45,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Middle smoke puff (center-left) - rising and expanding
                  Positioned(
                    top: 30 - (t * 25), // Moderate rise
                    left: 25 - (t * 8), // Slight drift
                    child: Transform.rotate(
                      angle: t * 2.5,
                      child: Opacity(
                        opacity: smoke3Opacity,
                        child: Transform.scale(
                          scale: 0.4 + (t * 0.5),
                          child: Image.asset(
                            'assets/images/effects/smoke_particle_3.png',
                            width: 40,
                            height: 40,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Additional smoke wisp (top center) - quick dissipation
                  Positioned(
                    top: 5 - (t * 45), // Rises fastest
                    left: 65 + (t * 5),
                    child: Transform.rotate(
                      angle: -t * 2.2,
                      child: Opacity(
                        opacity: smoke4Opacity,
                        child: Transform.scale(
                          scale: 0.3 + (t * 0.5),
                          child: Image.asset(
                            'assets/images/effects/smoke_particle_1.png',
                            width: 35,
                            height: 35,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Fire spark 1 (flickering, stays near crash site)
                  Positioned(
                    top: 65 + (t * 3), // Slight movement
                    left: 35,
                    child: Opacity(
                      opacity: sparkFlicker1,
                      child: Transform.scale(
                        scale: 0.8 + (0.3 * (1.0 - t)),
                        child: Image.asset(
                          'assets/images/effects/fire_spark_1.png',
                          width: 28,
                          height: 28,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  
                  // Fire spark 2 (flickering, stays near crash site)
                  Positioned(
                    top: 70 + (t * 2),
                    right: 30,
                    child: Opacity(
                      opacity: sparkFlicker2,
                      child: Transform.scale(
                        scale: 0.7 + (0.4 * (1.0 - t)),
                        child: Image.asset(
                          'assets/images/effects/fire_spark_2.png',
                          width: 24,
                          height: 24,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  
                  // Additional ember (rises up)
                  Positioned(
                    top: 35 - (t * 20),
                    right: 40 - (t * 5),
                    child: Opacity(
                      opacity: (1.0 - t * 1.2).clamp(0.0, 0.9),
                      child: Transform.scale(
                        scale: 0.5 + (t * 0.4),
                        child: Image.asset(
                          'assets/images/effects/fire_spark_1.png',
                          width: 18,
                          height: 18,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  
                  // Orange explosion glow overlay (pulsing gently)
                  Positioned(
                    child: Container(
                      width: 150 + (t * 10),
                      height: 150 + (t * 10),
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
                    top: 60 + (t < 0.2 ? t * 3 : 0.6), // Small drop then stabilize
                    child: Transform.rotate(
                      angle: -0.25 + (t < 0.3 ? t * 0.1 : 0.03), // Shake at start then settle
                      child: Container(
                        width: 95,
                        height: 95,
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
        
        const SizedBox(height: 16),
        
        // Bot name with defeated styling
        Text(
          bot.botName,
          style: TextStyle(
            color: Colors.red.shade300,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.lineThrough,
            decorationColor: Colors.red.shade300,
            decorationThickness: 2,
          ),
        ),
      ],
    );
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

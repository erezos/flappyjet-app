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
    
    // Setup smoke animation (repeating for VS battles)
    _smokeController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

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
            _buildStatRow(
              'Objective',
              '✅ ${widget.objectiveAchieved}/${widget.level.objective.target}',
            ),
            const SizedBox(height: 6),
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

  /// Build modern crashed rival jet visual for VS battles with ANIMATED smoke
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
        
        // Crashed jet with ANIMATED smoke/explosion effects
        AnimatedBuilder(
          animation: _smokeController,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Large background explosion glow (pulsing)
                Container(
                  width: 160 + (_smokeController.value * 20),
                  height: 160 + (_smokeController.value * 20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.orange.withValues(alpha: 0.3 + (_smokeController.value * 0.2)),
                        Colors.red.withValues(alpha: 0.2 + (_smokeController.value * 0.15)),
                        Colors.grey.withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.3, 0.6, 1.0],
                    ),
                  ),
                ),
                
                // Animated smoke puff 1 (top-left, rising and fading)
                Positioned(
                  top: 5 - (_smokeController.value * 15),
                  left: 15 + (_smokeController.value * 10),
                  child: Opacity(
                    opacity: 0.8 - (_smokeController.value * 0.3),
                    child: Container(
                      width: 35 + (_smokeController.value * 10),
                      height: 35 + (_smokeController.value * 10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.grey.shade700.withValues(alpha: 0.6),
                            Colors.grey.shade600.withValues(alpha: 0.3),
                            Colors.transparent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Animated smoke puff 2 (top-right, rising differently)
                Positioned(
                  top: 10 - (_smokeController.value * 20),
                  right: 20 - (_smokeController.value * 5),
                  child: Opacity(
                    opacity: 0.7 - (_smokeController.value * 0.4),
                    child: Container(
                      width: 30 + (_smokeController.value * 12),
                      height: 30 + (_smokeController.value * 12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.grey.shade800.withValues(alpha: 0.5),
                            Colors.grey.shade700.withValues(alpha: 0.2),
                            Colors.transparent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Animated smoke puff 3 (middle-left, drifting)
                Positioned(
                  top: 40 - (_smokeController.value * 10),
                  left: 25 - (_smokeController.value * 8),
                  child: Opacity(
                    opacity: 0.6 - (_smokeController.value * 0.3),
                    child: Container(
                      width: 25 + (_smokeController.value * 8),
                      height: 25 + (_smokeController.value * 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.grey.shade600.withValues(alpha: 0.7),
                            Colors.grey.shade500.withValues(alpha: 0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Animated fire sparks (flickering orange/red)
                Positioned(
                  top: 35 + (_smokeController.value * 5),
                  left: 40,
                  child: Opacity(
                    opacity: 0.6 + (_smokeController.value * 0.4),
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.orange,
                            Colors.deepOrange.withValues(alpha: 0.8),
                            Colors.transparent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withValues(alpha: 0.8),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Animated fire spark 2
                Positioned(
                  top: 45 + (_smokeController.value * 3),
                  right: 35,
                  child: Opacity(
                    opacity: 0.7 + (_smokeController.value * 0.3),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.red,
                            Colors.deepOrange.withValues(alpha: 0.7),
                            Colors.transparent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.9),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Small flickering ember 3
                Positioned(
                  top: 30 - (_smokeController.value * 8),
                  left: 55,
                  child: Opacity(
                    opacity: 0.5 + (_smokeController.value * 0.5),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.orangeAccent,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withValues(alpha: 0.7),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Small flickering ember 4
                Positioned(
                  top: 50,
                  right: 45 + (_smokeController.value * 5),
                  child: Opacity(
                    opacity: 0.8 - (_smokeController.value * 0.4),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.redAccent,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.8),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Tilted crashed jet - FULL COLOR with slight tilt and shake
                Transform.rotate(
                  angle: -0.2 + (_smokeController.value * 0.05), // Slight shake effect
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      jetPath,
                      fit: BoxFit.contain,
                      // Keep full color - no color filter!
                    ),
                  ),
                ),
              ],
            );
          },
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

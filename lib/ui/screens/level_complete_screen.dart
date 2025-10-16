/// 🎉 STORY MODE - LEVEL COMPLETE SCREEN
/// 
/// Shows level completion with rewards and next level button.
library;

import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../../models/level_data_schema.dart';
import '../../game/systems/level_reward_manager.dart';
import '../../game/systems/level_system_manager.dart';
import '../../core/debug_logger.dart';
import 'world_map_screen.dart';
import 'level_objective_popup.dart';
import 'zone_completion_celebration_screen.dart';

/// Map bot theme names to actual jet sprite files
String _getBotJetSpritePath(String botJetSkin) {
  // Direct mapping - bot skin names now match actual jet file names
  const botToSpriteMap = {
    'green_lightning': 'green_lightning',
    'desert_storm': 'desert_storm',
    'magma_fracture': 'magma_fracture',
    'blaze': 'blaze',
    'storm': 'storm',
    'stealth_dragon': 'stealth_dragon',
    'stealth_bomber': 'stealth_bomber',
  };
  
  final spriteName = botToSpriteMap[botJetSkin] ?? botJetSkin;  // Use skin name directly if not in map
  return 'assets/images/jets/$spriteName.png';
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
    with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

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

    // Setup animations
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
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF283593), Color(0xFF1A237E)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
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
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),

            // Level info
            Text(
              'Level ${widget.level.id}: ${widget.level.name}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            
            // VS Battle: Show crashed rival jet
            if (widget.level.botBattle != null) ...[
              _buildCrashedRivalJet(),
              const SizedBox(height: 12),
            ],

            // Stats
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildStatRow(
                  'Objective',
                  '✅ ${widget.objectiveAchieved}/${widget.level.objective.target}',
                ),
                const SizedBox(height: 8),
                _buildStatRow(
                  'Time',
                  '${widget.timeTaken}s',
                ),
                const SizedBox(height: 8),
                _buildStatRow(
                  'Continues Used',
                  '${widget.continuesUsed}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Rewards
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: (_isReplay ? Colors.lightBlue : Colors.amber).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isReplay ? Colors.lightBlue : Colors.amber,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Text(
                  _isReplay ? '🔄 REPLAY REWARD' : 'REWARDS EARNED',
                  style: TextStyle(
                    color: _isReplay ? Colors.lightBlue : Colors.amber,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Coins
                    const Icon(Icons.monetization_on,
                        color: Colors.amber, size: 32),
                    const SizedBox(width: 8),
                    Text(
                      _isReplay ? '+20' : '+${widget.level.reward.coins}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Gems (only for first completion)
                    if (!_isReplay && widget.level.reward.gems > 0) ...[
                      const SizedBox(width: 32),
                      Image.asset(
                        'assets/images/icons/gem_icon.png',
                        width: 32,
                        height: 32,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '+${widget.level.reward.gems}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
                if (_isReplay) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Original reward already earned',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Buttons
          Column(
            children: [
              // ✅ FIX: Show "Next Level" button for replays too if next level exists
              if (_hasNextLevel()) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _onNextLevel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'NEXT LEVEL',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              // Back to Map button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _onBackToMap,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'BACK TO MAP',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
            fontSize: 16,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Build modern crashed rival jet visual for VS battles
  Widget _buildCrashedRivalJet() {
    final bot = widget.level.botBattle!;
    final jetPath = _getBotJetSpritePath(bot.botJetSkin);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.shade900.withOpacity(0.3),
            Colors.orange.shade900.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.red.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // "DEFEATED!" badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B6B), Color(0xFFEE5A24)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.5),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Text(
              '💥 DEFEATED! 💥',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Crashed jet with smoke effects
          Stack(
            alignment: Alignment.center,
            children: [
              // Smoke effect (background circles)
              ..._buildSmokeEffects(),
              
              // Tilted crashed jet
              Transform.rotate(
                angle: -0.3, // Tilted crash angle
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.black.withOpacity(0.4),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Image.asset(
                    jetPath,
                    width: 80,
                    height: 80,
                    color: Colors.grey.shade700, // Darkened crashed jet
                    colorBlendMode: BlendMode.modulate,
                  ),
                ),
              ),
              
              // Fire/explosion particles
              ..._buildExplosionParticles(),
            ],
          ),
          const SizedBox(height: 8),
          
          // Rival name
          Text(
            bot.botName,
            style: TextStyle(
              color: Colors.red.shade300,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Build animated smoke effects
  List<Widget> _buildSmokeEffects() {
    return [
      // Smoke cloud 1
      Positioned(
        top: 0,
        left: 20,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.grey.withOpacity(0.5),
                Colors.grey.withOpacity(0.1),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
      // Smoke cloud 2
      Positioned(
        top: 10,
        right: 30,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.grey.withOpacity(0.4),
                Colors.grey.withOpacity(0.1),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
      // Smoke cloud 3
      Positioned(
        bottom: 5,
        left: 35,
        child: Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.grey.withOpacity(0.6),
                Colors.grey.withOpacity(0.2),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    ];
  }

  /// Build fire/explosion particle effects
  List<Widget> _buildExplosionParticles() {
    return [
      // Orange spark 1
      Positioned(
        top: 15,
        left: 15,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.orange,
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.8),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ),
      // Red spark 2
      Positioned(
        top: 25,
        right: 20,
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red,
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.8),
                blurRadius: 6,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ),
      // Yellow spark 3
      Positioned(
        bottom: 20,
        left: 25,
        child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.yellow,
            boxShadow: [
              BoxShadow(
                color: Colors.yellow.withOpacity(0.8),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ),
    ];
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

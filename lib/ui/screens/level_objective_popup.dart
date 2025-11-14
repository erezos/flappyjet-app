/// 🎯 STORY MODE - LEVEL OBJECTIVE POPUP
/// 
/// Modern, beautiful popup with enemy jet display for VS battles.
library;

import 'package:flutter/material.dart';
import '../../models/level_data_schema.dart';
import '../../core/debug_logger.dart';
import '../widgets/story_mode_game_wrapper.dart';
import '../widgets/buttons/modern_game_button.dart';
import '../widgets/buttons/button_styles.dart';
import '../../game/core/jet_skins.dart';
import 'world_map_screen.dart';

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

class LevelObjectivePopup extends StatefulWidget {
  final LevelData level;

  const LevelObjectivePopup({
    super.key,
    required this.level,
  });

  @override
  State<LevelObjectivePopup> createState() => _LevelObjectivePopupState();
}

class _LevelObjectivePopupState extends State<LevelObjectivePopup>
    with TickerProviderStateMixin {
  late AnimationController _popupController;
  late AnimationController _jetController;
  late AnimationController _vsController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _jetBounceAnimation;
  late Animation<double> _vsAnimation;
  bool _isStarting = false;

  @override
  void initState() {
    super.initState();

    // Popup scale animation
    _popupController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _popupController,
        curve: Curves.easeOutBack,
      ),
    );

    // Jet bounce animation (for VS battles)
    _jetController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _jetBounceAnimation = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(
        parent: _jetController,
        curve: Curves.easeInOut,
      ),
    );

    // VS badge pulse animation
    _vsController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _vsAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _vsController,
        curve: Curves.easeInOut,
      ),
    );

    // Start animations
    _popupController.forward();
    
    if (widget.level.botBattle != null) {
      _jetController.repeat(reverse: true);
      _vsController.repeat(reverse: true);
    }
  }

  Future<void> _startLevel() async {
    safePrint('🎯 START button tapped! Level ${widget.level.id}');
    
    if (_isStarting) {
      safePrint('🎯 Already starting, ignoring duplicate tap');
      return; // Prevent double-tap
    }
    
    setState(() {
      _isStarting = true;
    });

    // 🎯 STORY MODE: Don't consume heart on level start
    // Hearts are only consumed on crashes during gameplay
    safePrint('🎯 Starting level ${widget.level.id}: ${widget.level.name} (no heart consumed)');

    // Navigate to game
    if (mounted) {
      safePrint('🎯 Navigating to StoryModeGameWrapper...');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => StoryModeGameWrapper(level: widget.level),
        ),
      );
    } else {
      safePrint('🎯 ❌ Widget not mounted, cannot navigate!');
    }
  }

  @override
  void dispose() {
    _popupController.dispose();
    _jetController.dispose();
    _vsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isVsBattle = widget.level.botBattle != null;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            // Modern gradient border
            gradient: LinearGradient(
              colors: [
                Colors.amber.shade400,
                Colors.orange.shade600,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              // Deep blue gradient background
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E3A8A),
                  Color(0xFF312E81),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              children: [
                // Main content (scrollable to handle overflow)
                  SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Level title with modern styling
                      Text(
                        'LEVEL ${widget.level.id}',
                        style: TextStyle(
                          color: Colors.amber.shade300,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 2),
                      
                      Text(
                        widget.level.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 16),

                      // Objective card (comes first for VS battles)
                      _buildObjectiveCard(),
                      
                      // VS Battle Section with Enemy Jet (comes after objective)
                      if (isVsBattle) ...[
                        const SizedBox(height: 12),
                        _buildVsBattleSection(),
                      ],
                      
                      const SizedBox(height: 12),

                      // Reward card
                      _buildRewardCard(),
                      
                      const SizedBox(height: 12),

                      // Start Button
                      _buildStartButton(),
                    ],
                  ),
                ),
                
                // Close button (top right)
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      if (!_isStarting) {
                        // ✅ FIX: Navigate to world map instead of just popping
                        // This prevents showing the old game over screen when coming from "Start Over"
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const WorldMapScreen(),
                          ),
                          (route) => route.isFirst, // Keep tab navigation in stack
                        );
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🆚 VS Battle Section with animated enemy jet - COMPACT VERSION
  Widget _buildVsBattleSection() {
    final bot = widget.level.botBattle!;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: AnimatedBuilder(
        animation: _jetBounceAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _jetBounceAnimation.value * 0.5), // Reduced bounce
            child: Column(
              children: [
                // Compact jet display with glow
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.red.withValues(alpha: 0.4),
                        Colors.orange.withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                      stops: const [0.3, 0.6, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.5),
                        blurRadius: 30,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.6),
                          Colors.black.withValues(alpha: 0.4),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.red.shade400,
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      _getBotJetSpritePath(bot.botJetSkin),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                
                const SizedBox(height: 10),
                
                // Bot name with epic styling
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.red.shade700,
                        Colors.red.shade900,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.red.shade300,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.4),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    bot.botName.toUpperCase(),
                    style: TextStyle(
                      color: Colors.yellow.shade200,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.8),
                          offset: const Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 🎯 Modern objective card
  Widget _buildObjectiveCard() {
    final objectiveType = widget.level.objective.type;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 🎯 Use obstacle image for "pass obstacles" objective
            if (objectiveType == ObjectiveType.passObstacles)
              Container(
                width: 44,
                height: 44,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/images/obstacles/${widget.level.theme.obstacles}',
                  fit: BoxFit.contain,
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getObjectiveIcon(),
                  color: Colors.amber.shade300,
                  size: 24,
                ),
              ),
            const SizedBox(width: 10),
            const Text(
              'OBJECTIVE',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          widget.level.objective.description,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  /// 💰 Modern reward card
  Widget _buildRewardCard() {
    return Column(
      children: [
        const Text(
          'REWARD',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Coins
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.amber.shade300,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.monetization_on,
                      color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.level.reward.coins}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Gems (if any)
            if (widget.level.reward.gems > 0) ...[
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.cyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.cyan,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/icons/gem_icon.png',
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.level.reward.gems}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  /// ▶️ Modern start button
  Widget _buildStartButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.shade400,
            Colors.orange.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.5),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: _isStarting
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
              child: const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
            )
          : ModernGameButton(
              label: 'START ▶',
              onPressed: _startLevel,
              height: 60,
              style: ModernButtonStyle.gold, // Gold for level start
              customGradient: const [
                Colors.transparent, // Transparent to show gradient container behind
                Colors.transparent,
              ],
            ),
    );
  }

  IconData _getObjectiveIcon() {
    switch (widget.level.objective.type) {
      case ObjectiveType.passObstacles:
        return Icons.flag_rounded;
      case ObjectiveType.surviveTime:
        return Icons.timer_outlined;
      case ObjectiveType.beatBot:
        return Icons.emoji_events_rounded; // Trophy icon for VS battles
    }
  }
}

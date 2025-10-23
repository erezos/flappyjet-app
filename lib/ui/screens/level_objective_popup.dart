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
                // Main content (scrollable)
                SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    // Level title with modern styling
                    Text(
                  'LEVEL ${widget.level.id}',
                  style: TextStyle(
                    color: Colors.amber.shade300,
                    fontSize: 28,
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
                
                const SizedBox(height: 4),
                
                Text(
                  widget.level.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 16),

                // VS Battle Section with Enemy Jet
                if (isVsBattle) ...[
                  _buildVsBattleSection(),
                  const SizedBox(height: 16),
                ],

                // Objective card
                _buildObjectiveCard(),
                
                const SizedBox(height: 12),

                // Reward card
                _buildRewardCard(),
                
                const SizedBox(height: 16),

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
                        Navigator.of(context).pop();
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

  /// 🆚 VS Battle Section with animated enemy jet
  Widget _buildVsBattleSection() {
    final bot = widget.level.botBattle!;
    
    return AnimatedBuilder(
      animation: _vsAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _vsAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(12), // ✅ FIX: Reduced from 16 to 12
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.red.shade600,
                  Colors.red.shade800,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // ✅ FIX: Changed from spaceEvenly to spaceBetween
              children: [
                // VS Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // ✅ FIX: Reduced padding
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'VS',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 24, // ✅ FIX: Reduced from 28 to 24
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5, // ✅ FIX: Reduced from 2 to 1.5
                    ),
                  ),
                ),

                const SizedBox(width: 8), // ✅ FIX: Added spacing

                // Enemy Jet with bounce animation
                Flexible( // ✅ FIX: Wrapped in Flexible to prevent overflow
                  child: AnimatedBuilder(
                    animation: _jetBounceAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _jetBounceAnimation.value),
                        child: Column(
                          mainAxisSize: MainAxisSize.min, // ✅ FIX: Added
                          children: [
                            // Enemy jet sprite - REAL jet image!
                            Container(
                              width: 90, // ✅ FIX: Reduced from 100 to 90
                              height: 90, // ✅ FIX: Reduced from 100 to 90
                              padding: const EdgeInsets.all(10), // ✅ FIX: Reduced from 12 to 10
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.white.withValues(alpha: 0.3),
                                    Colors.white.withValues(alpha: 0.1),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withValues(alpha: 0.5),
                                    blurRadius: 12,
                                    spreadRadius: 3,
                                  ),
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
                            const SizedBox(height: 10), // ✅ FIX: Reduced from 12 to 10
                            // Bot name with dramatic styling
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), // ✅ FIX: Reduced padding
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                bot.botName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14, // ✅ FIX: Reduced from 16 to 14
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5, // ✅ FIX: Reduced from 1 to 0.5
                                ),
                                textAlign: TextAlign.center, // ✅ FIX: Added center alignment
                                maxLines: 1, // ✅ FIX: Ensure single line
                                overflow: TextOverflow.ellipsis, // ✅ FIX: Handle overflow gracefully
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 🎯 Modern objective card
  Widget _buildObjectiveCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getObjectiveIcon(),
                  color: Colors.amber.shade300,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'OBJECTIVE',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.level.objective.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  /// 💰 Modern reward card
  Widget _buildRewardCard() {
    final isVsBattle = widget.level.botBattle != null;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.15),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          const Text(
            'REWARD',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Coins
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                        color: Colors.amber, size: 24),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.level.reward.coins}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
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
          // Bot battle bonus
          if (isVsBattle) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.red.shade600,
                    Colors.orange.shade600,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.flash_on, color: Colors.white, size: 20),
                  SizedBox(width: 6),
                  Text(
                    '2x COINS IF YOU WIN!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
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
        return Icons.sports_esports_rounded;
    }
  }
}

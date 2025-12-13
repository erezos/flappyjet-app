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
import '../widgets/coin_3d_icon.dart';
import '../../game/core/jet_skins.dart';
import 'world_map_screen.dart';
import '../utils/responsive_config.dart';

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

    // VS badge pulse animation (controller created but animation not currently used)
    _vsController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
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
    final screenSize = MediaQuery.of(context).size;
    
    // Responsive popup sizing
    final popupWidth = ResponsiveConfig.responsivePopupWidth(
      screenSize,
      percent: 0.9,
      minWidth: 320.0,
      maxWidth: 500.0,
    );
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              margin: ResponsiveConfig.responsiveEdgeInsets(16.0, screenSize),
              padding: ResponsiveConfig.responsiveEdgeInsets(4.0, screenSize),
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
                  maxWidth: popupWidth,
                  maxHeight: ResponsiveConfig.responsivePopupHeight(
                    screenSize,
                    percent: 0.8,
                    minHeight: 400.0,
                    maxHeight: 700.0,
                  ),
                ),
                padding: ResponsiveConfig.responsiveEdgeInsets(20.0, screenSize),
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
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Level title with modern styling
                      Builder(
                        builder: (context) {
                          final titleFontSize = ResponsiveConfig.responsiveFontSize(26.0, screenSize, context);
                          return Text(
                            'LEVEL ${widget.level.id}',
                            style: TextStyle(
                              color: Colors.amber.shade300,
                              fontSize: titleFontSize,
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
                          );
                        },
                      ),
                      
                      SizedBox(height: ResponsiveConfig.responsivePadding(2.0, screenSize)),
                      
                      Builder(
                        builder: (context) {
                          final nameFontSize = ResponsiveConfig.responsiveFontSize(16.0, screenSize, context);
                          return Text(
                            widget.level.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: nameFontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                      
                      SizedBox(height: ResponsiveConfig.responsivePadding(16.0, screenSize)),

                      // Objective card (comes first for VS battles)
                      _buildObjectiveCard(),
                      
                      // VS Battle Section with Enemy Jet (comes after objective)
                      if (isVsBattle) ...[
                        SizedBox(height: ResponsiveConfig.responsivePadding(12.0, screenSize)),
                        _buildVsBattleSection(screenSize),
                      ],
                      
                      SizedBox(height: ResponsiveConfig.responsivePadding(12.0, screenSize)),

                      // Reward card
                      _buildRewardCard(screenSize),
                      
                      SizedBox(height: ResponsiveConfig.responsivePadding(12.0, screenSize)),

                      // Start Button
                      _buildStartButton(),
                    ],
                  ),
                ),
              ),
            ),
            
            // Close button positioned at top-right of popup window (outer container)
            Positioned(
              top: ResponsiveConfig.responsivePadding(8.0, screenSize),
              right: ResponsiveConfig.responsivePadding(8.0, screenSize),
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
                  width: ResponsiveConfig.responsiveIconSize(40.0, screenSize),
                  height: ResponsiveConfig.responsiveIconSize(40.0, screenSize),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                      width: ResponsiveConfig.responsiveSize(2.0, screenSize, minScale: 0.8, maxScale: 1.2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: ResponsiveConfig.responsiveSize(8.0, screenSize),
                        offset: Offset(0, ResponsiveConfig.responsiveSize(2.0, screenSize)),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: ResponsiveConfig.responsiveIconSize(24.0, screenSize),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🆚 VS Battle Section with animated enemy jet - COMPACT VERSION
  Widget _buildVsBattleSection(Size screenSize) {
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
                // Compact jet display with glow (responsive size)
                Builder(
                  builder: (context) {
                    final jetSize = ResponsiveConfig.responsiveSize(100.0, screenSize, minScale: 0.9, maxScale: 1.2);
                    return Container(
                      width: jetSize,
                      height: jetSize,
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
                    );
                  },
                ),
                
                SizedBox(height: ResponsiveConfig.responsivePadding(10.0, screenSize)),
                
                // Bot name with epic styling
                Builder(
                  builder: (context) {
                    final padding = ResponsiveConfig.responsivePadding(18.0, screenSize);
                    final verticalPadding = ResponsiveConfig.responsivePadding(6.0, screenSize);
                    final fontSize = ResponsiveConfig.responsiveFontSize(14.0, screenSize, context);
                    
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: padding, vertical: verticalPadding),
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
                          fontSize: fontSize,
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
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
    final screenSize = MediaQuery.of(context).size;
    final objectiveType = widget.level.objective.type;
    
    final isVsBattle = objectiveType == ObjectiveType.beatBot && widget.level.botBattle != null;
    
    return Column(
      children: [
        if (isVsBattle)
          Builder(
            builder: (context) {
              final size = ResponsiveConfig.responsiveIconSize(92.0, screenSize);
              return SizedBox(
                width: size,
                height: size,
                child: Image.asset(
                  'assets/images/ui/vs_battle_node_completed.png',
                  fit: BoxFit.contain,
                ),
              );
            },
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🎯 Time objective: show dedicated gold timer badge instead of icon+label
              if (objectiveType == ObjectiveType.surviveTime)
                Builder(
                  builder: (context) {
                    final size = ResponsiveConfig.responsiveIconSize(64.0, screenSize);
                    return SizedBox(
                      width: size,
                      height: size,
                      child: Image.asset(
                        'assets/images/icons/missions/gold_timer_icon.png',
                        fit: BoxFit.contain,
                      ),
                    );
                  },
                )
              // 🎯 Obstacle objective: dedicated badge
              else if (objectiveType == ObjectiveType.passObstacles)
                Builder(
                  builder: (context) {
                    final size = ResponsiveConfig.responsiveIconSize(64.0, screenSize);
                    return SizedBox(
                      width: size,
                      height: size,
                      child: Image.asset(
                        'assets/images/ui/pass_obstacle_objective.png',
                        fit: BoxFit.contain,
                      ),
                    );
                  },
                )
              // 🎯 Default: small circular icon + label
              else
                Builder(
                  builder: (context) {
                    final padding = ResponsiveConfig.responsivePadding(6.0, screenSize);
                    final iconSize = ResponsiveConfig.responsiveIconSize(24.0, screenSize);
                    return Container(
                      padding: EdgeInsets.all(padding),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getObjectiveIcon(),
                        color: Colors.amber.shade300,
                        size: iconSize,
                      ),
                    );
                  },
                ),
              if (objectiveType != ObjectiveType.surviveTime &&
                  objectiveType != ObjectiveType.passObstacles) ...[
                SizedBox(width: ResponsiveConfig.responsivePadding(10.0, screenSize)),
                Builder(
                  builder: (context) {
                    final fontSize = ResponsiveConfig.responsiveFontSize(13.0, screenSize, context);
                    return Text(
                      'OBJECTIVE',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: fontSize,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        SizedBox(height: ResponsiveConfig.responsivePadding(8.0, screenSize)),
        Builder(
          builder: (context) {
            final fontSize = ResponsiveConfig.responsiveFontSize(16.0, screenSize, context);
            return Text(
              widget.level.objective.description,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            );
          },
        ),
      ],
    );
  }

  /// 💰 Modern reward card
  Widget _buildRewardCard(Size screenSize) {
    return Column(
      children: [
        Builder(
          builder: (context) {
            final fontSize = ResponsiveConfig.responsiveFontSize(13.0, screenSize, context);
            return Text(
              'REWARD',
              style: TextStyle(
                color: Colors.white70,
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            );
          },
        ),
        SizedBox(height: ResponsiveConfig.responsivePadding(8.0, screenSize)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Coins
            Builder(
              builder: (context) {
                final horizontalPadding = ResponsiveConfig.responsivePadding(10.0, screenSize);
                final verticalPadding = ResponsiveConfig.responsivePadding(5.0, screenSize);
                final fontSize = ResponsiveConfig.responsiveFontSize(18.0, screenSize, context);
                final iconSize = ResponsiveConfig.responsiveIconSize(20.0, screenSize);
                
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
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
                      Coin3DIcon(size: iconSize), // ✅ Using consistent coin asset
                      SizedBox(width: ResponsiveConfig.responsivePadding(4.0, screenSize)),
                      Text(
                        '${widget.level.reward.coins}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            // Gems (if any)
            if (widget.level.reward.gems > 0) ...[
              SizedBox(width: ResponsiveConfig.responsivePadding(16.0, screenSize)),
              Builder(
                builder: (context) {
                  final horizontalPadding = ResponsiveConfig.responsivePadding(12.0, screenSize);
                  final verticalPadding = ResponsiveConfig.responsivePadding(6.0, screenSize);
                  final fontSize = ResponsiveConfig.responsiveFontSize(22.0, screenSize, context);
                  final iconSize = ResponsiveConfig.responsiveIconSize(24.0, screenSize);
                  
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
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
                          width: iconSize,
                          height: iconSize,
                        ),
                        SizedBox(width: ResponsiveConfig.responsivePadding(6.0, screenSize)),
                        Text(
                          '${widget.level.reward.gems}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ],
    );
  }

  /// ▶️ Modern start button
  Widget _buildStartButton() {
    final screenSize = MediaQuery.of(context).size;
    final buttonHeight = ResponsiveConfig.responsiveButtonHeight(60.0, screenSize);
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
              height: buttonHeight,
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

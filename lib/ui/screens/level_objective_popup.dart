/// 🎯 STORY MODE - LEVEL OBJECTIVE POPUP
/// 
/// Modern, beautiful popup with enemy jet display for VS battles.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import '../../models/level_data_schema.dart';
import '../../core/debug_logger.dart';
import '../widgets/story_mode_game_wrapper.dart';
import '../widgets/coin_3d_icon.dart';
import '../widgets/gem_3d_icon.dart';
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
  final VoidCallback? onStart; // Optional callback for custom navigation (e.g., tournaments)

  const LevelObjectivePopup({
    super.key,
    required this.level,
    this.onStart,
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
  bool _buttonPressed = false; // Track button press state for gestures

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

    // Use custom callback if provided (for tournaments), otherwise use default story mode navigation
    if (widget.onStart != null) {
      safePrint('🎯 Using custom onStart callback');
      widget.onStart!();
    } else if (mounted) {
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
                padding: EdgeInsets.only(
                  top: ResponsiveConfig.responsivePadding(20.0, screenSize),
                  left: ResponsiveConfig.responsivePadding(20.0, screenSize),
                  right: ResponsiveConfig.responsivePadding(20.0, screenSize),
                  bottom: ResponsiveConfig.responsivePadding(20.0, screenSize), // Increased bottom padding for START button
                ),
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
                      
                      SizedBox(height: ResponsiveConfig.responsivePadding(16.0, screenSize)), // Increased spacing above button

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
                    // If onStart callback is provided (tournament mode), just close the dialog
                    // Otherwise (story mode), navigate back to world map
                    if (widget.onStart != null) {
                      Navigator.of(context).pop();
                    } else {
                      // ✅ FIX: Navigate to world map instead of just popping
                      // This prevents showing the old game over screen when coming from "Start Over"
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const WorldMapScreen(),
                        ),
                        (route) => route.isFirst, // Keep tab navigation in stack
                      );
                    }
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

  /// 🆚 VS Battle Section with animated enemy jet - VS image as frame
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
                // VS image as frame with bot jet centered inside
                Builder(
                  builder: (context) {
                    final vsFrameSize = ResponsiveConfig.responsiveSize(100.0, screenSize, minScale: 0.9, maxScale: 1.2);
                    final jetSize = vsFrameSize * 0.55; // Jet is 55% of frame size
                    
                    return Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        // VS image as decorative frame/border (background layer)
                        SizedBox(
                          width: vsFrameSize,
                          height: vsFrameSize,
                          child: Image.asset(
                            'assets/images/ui/vs_battle_node_completed.png',
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                        // Bot jet positioned lower inside VS frame (foreground layer)
                        Positioned(
                          bottom: vsFrameSize * 0.15, // Position jet lower (15% from bottom)
                          child: Container(
                            width: jetSize,
                            height: jetSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                _getBotJetSpritePath(bot.botJetSkin),
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.high,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey.shade800,
                                    child: const Icon(
                                      Icons.airplanemode_active,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
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
        // VS image removed from top - now used as frame around bot jet
        if (!isVsBattle)
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
              // 🎯 Obstacle objective: dedicated badge (107x134 pixels = 0.8:1 aspect ratio)
              else if (objectiveType == ObjectiveType.passObstacles)
                Builder(
                  builder: (context) {
                    // Calculate responsive width (base size similar to other icons)
                    final baseWidth = ResponsiveConfig.responsiveIconSize(64.0, screenSize);
                    // Calculate height based on aspect ratio (134/107 ≈ 1.252)
                    final aspectRatio = 134.0 / 107.0; // ≈ 1.252
                    final height = baseWidth * aspectRatio;
                    return SizedBox(
                      width: baseWidth,
                      height: height,
                      child: Image.asset(
                        'assets/images/ui/pass_obstacle_objective.png',
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
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

  /// 💰 Modern unified reward card (coins and gems in one area)
  Widget _buildRewardCard(Size screenSize) {
    final hasCoins = widget.level.reward.coins > 0;
    final hasGems = widget.level.reward.gems > 0;
    
    // If no rewards, return empty
    if (!hasCoins && !hasGems) {
      return const SizedBox.shrink();
    }
    
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
        // Unified rewards container
        Builder(
          builder: (context) {
            final horizontalPadding = ResponsiveConfig.responsivePadding(16.0, screenSize);
            final verticalPadding = ResponsiveConfig.responsivePadding(10.0, screenSize);
            final fontSize = ResponsiveConfig.responsiveFontSize(18.0, screenSize, context);
            final iconSize = ResponsiveConfig.responsiveIconSize(22.0, screenSize);
            final spacing = ResponsiveConfig.responsivePadding(16.0, screenSize);
            
            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.amber.withValues(alpha: 0.15),
                    Colors.cyan.withValues(alpha: 0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(ResponsiveConfig.responsiveSize(16.0, screenSize)),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: ResponsiveConfig.responsiveSize(2.0, screenSize),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: ResponsiveConfig.responsiveSize(8.0, screenSize),
                    offset: Offset(0, ResponsiveConfig.responsiveSize(2.0, screenSize)),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Coins
                  if (hasCoins) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Coin3DIcon(size: iconSize),
                        SizedBox(width: ResponsiveConfig.responsivePadding(6.0, screenSize)),
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
                  ],
                  // Separator if both coins and gems exist
                  if (hasCoins && hasGems) ...[
                    Container(
                      width: ResponsiveConfig.responsiveSize(1.0, screenSize),
                      height: ResponsiveConfig.responsiveSize(24.0, screenSize),
                      margin: EdgeInsets.symmetric(horizontal: spacing),
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ],
                  // Gems
                  if (hasGems) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Gem3DIcon(size: iconSize),
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
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  /// ▶️ Modern start button with image asset and button gestures
  Widget _buildStartButton() {
    final screenSize = MediaQuery.of(context).size;
    
    // Calculate responsive button size (460x210 pixels = 2.19:1 aspect ratio)
    // Use responsive width that works well in popup context (smaller for better layout)
    final buttonWidth = ResponsiveConfig.responsiveSize(
      145.0, // Base width for 460px image scaled down proportionally (slightly reduced from 160.0)
      screenSize,
      minScale: 0.7,
      maxScale: 1.1,
    );
    
    // Calculate height based on aspect ratio (460/210 ≈ 2.19)
    final aspectRatio = 460.0 / 210.0; // ≈ 2.19
    final buttonHeight = buttonWidth / aspectRatio;
    
    return _isStarting
        ? SizedBox(
            width: buttonWidth,
            height: buttonHeight,
            child: const Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
            ),
          )
        : GestureDetector(
            onTapDown: _isStarting ? null : (_) {
              setState(() => _buttonPressed = true);
            },
            onTapCancel: _isStarting ? null : () {
              setState(() => _buttonPressed = false);
            },
            onTapUp: _isStarting ? null : (_) {
              setState(() => _buttonPressed = false);
              HapticFeedback.lightImpact();
              _startLevel();
            },
            child: AnimatedScale(
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
              scale: _buttonPressed ? 0.95 : 1.0,
              child: Image.asset(
                'assets/images/ui/start_button.png',
                width: buttonWidth,
                height: buttonHeight,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to original button if image fails to load
                  safePrint('⚠️ Failed to load start_button.png, using fallback');
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.amber.shade400,
                          Colors.orange.shade600,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Center(
                      child: Text(
                        'START ▶',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: ResponsiveConfig.responsiveFontSize(18.0, screenSize, context),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  );
                },
              ),
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

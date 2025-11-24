/// 💀 STORY MODE - GAME OVER POPUP
/// 
/// 🎮 FLAME BEST PRACTICE: Responsive, non-scrollable popup
/// Shows crashed jet animation, progress, and clear action buttons.
/// Follows mobile gaming UX patterns: compact, engaging, no clutter.
library;

import 'package:flutter/material.dart';
import '../../models/level_data_schema.dart';
import '../../game/systems/lives_manager.dart';
import '../../game/systems/inventory_manager.dart';
import '../../game/core/jet_skins.dart';
import '../../core/debug_logger.dart';
import 'world_map_screen.dart';
import 'level_objective_popup.dart';
import '../widgets/buttons/modern_game_button.dart';
import '../widgets/buttons/button_styles.dart';
import '../utils/responsive_config.dart';

class LevelFailedScreen extends StatefulWidget {
  final LevelData level;
  final int objectiveAchieved;
  final int objectiveTarget;
  final int continuesUsed;
  final int continuesRemaining;
  final VoidCallback? onContinueWithAd;
  final VoidCallback? onContinueWithGems;

  const LevelFailedScreen({
    super.key,
    required this.level,
    required this.objectiveAchieved,
    required this.objectiveTarget,
    this.continuesUsed = 0,
    this.continuesRemaining = 0,
    this.onContinueWithAd,
    this.onContinueWithGems,
  });

  @override
  State<LevelFailedScreen> createState() => _LevelFailedScreenState();
}

class _LevelFailedScreenState extends State<LevelFailedScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  final LivesManager _livesManager = LivesManager();
  final InventoryManager _inventoryManager = InventoryManager();

  @override
  void initState() {
    super.initState();

    // Setup animations - more dramatic entrance
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    // Start animations
    _animationController.forward();

    safePrint('💀 STORY MODE: Game Over popup shown - ${widget.objectiveAchieved}/${widget.objectiveTarget}');
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.85),
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: AnimatedBuilder(
                animation: _slideAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: child,
                  );
                },
                child: _buildResponsivePopup(screenSize),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 🎮 FLAME BEST PRACTICE: Responsive popup - NO SCROLLING
  /// Uses ConstrainedBox + FittedBox for automatic scaling
  Widget _buildResponsivePopup(Size screenSize) {
    // 🎮 RESPONSIVE CONSTRAINTS: Use ResponsiveConfig for consistent sizing
    final popupWidth = ResponsiveConfig.responsivePopupWidth(
      screenSize,
      percent: 0.85,
      minWidth: 300.0,
      maxWidth: 450.0,
    );
    final maxPopupHeight = ResponsiveConfig.responsivePopupHeight(
      screenSize,
      percent: 0.75,
      minHeight: 400.0,
      maxHeight: 700.0,
    );
    
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: popupWidth,
        maxHeight: maxPopupHeight,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown, // ✅ Scale down if content is too big, never up
        child: IntrinsicHeight( // ✅ Content sizes naturally
          child: Container(
            width: popupWidth,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E2337),
                  Color(0xFF0F1419),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.red.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // Main content
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(screenSize),
                      _buildMainContent(screenSize),
                    ],
                  ),
                  // X button in top-right corner
                  _buildCloseButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 🚀 CLOSE BUTTON: X button in top-right corner
  Widget _buildCloseButton() {
    return Positioned(
      top: 8,
      right: 8,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _onBackToMap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.close,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  /// 🎨 HEADER: Crashed jet animation + "GAME OVER" title
  Widget _buildHeader(Size screenSize) {
    final padding = ResponsiveConfig.responsivePadding(20.0, screenSize);
    return Container(
      padding: EdgeInsets.fromLTRB(padding, padding, padding, ResponsiveConfig.responsivePadding(12.0, screenSize)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.withValues(alpha: 0.2),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        children: [
          // 🚀 CRASHED JET: Player's jet with smoke animation (responsive size)
          Builder(
            builder: (context) {
              final jetSize = ResponsiveConfig.responsiveSize(90.0, screenSize, minScale: 0.9, maxScale: 1.1);
              return _buildCrashedPlayerJet(jetSize.clamp(80.0, 110.0));
            },
          ),
          SizedBox(height: ResponsiveConfig.responsivePadding(10.0, screenSize)),
          Builder(
            builder: (context) {
              final fontSize = ResponsiveConfig.responsiveFontSize(24.0, screenSize, context);
              return Text(
                'GAME OVER',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                  shadows: const [
                    Shadow(
                      color: Colors.red,
                      blurRadius: 12,
                    ),
                  ],
                ),
              );
            },
          ),
          SizedBox(height: ResponsiveConfig.responsivePadding(4.0, screenSize)),
          Builder(
            builder: (context) {
              final fontSize = ResponsiveConfig.responsiveFontSize(14.0, screenSize, context);
              return Text(
                widget.level.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 🚀 CRASHED PLAYER JET: Show player's equipped jet with smoke animation
  /// (Reuses logic from VS level complete popup)
  Widget _buildCrashedPlayerJet(double iconSize) {
    // Get player's equipped jet skin
    final inventory = InventoryManager();
    final equippedSkinId = inventory.equippedSkinId;
    final jetSkin = JetSkinCatalog.getSkinById(equippedSkinId) ?? JetSkinCatalog.starterJet;
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // 💨 SMOKE ANIMATION: Multiple smoke particles
              ...List.generate(8, (i) {
                final distance = 35 + (i % 2) * 15; // Alternate distances
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 800 + (i * 100)),
                  curve: Curves.easeOut,
                  builder: (context, smokeValue, child) {
                    return Positioned(
                      left: iconSize / 2 + (distance * smokeValue * 0.7) * (i < 4 ? -1 : 1),
                      top: iconSize / 2 + (distance * smokeValue * 0.7) * (i % 2 == 0 ? -1 : 1),
                      child: Opacity(
                        opacity: (1 - smokeValue) * 0.6,
                        child: Container(
                          width: 12 + (smokeValue * 18),
                          height: 12 + (smokeValue * 18),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.grey.withValues(alpha: 0.8),
                                Colors.grey.withValues(alpha: 0.2),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
              // 🔥 FIRE/EXPLOSION GLOW
              Container(
                width: iconSize * 1.3,
                height: iconSize * 1.3,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.orange.withValues(alpha: 0.4),
                      Colors.red.withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              // ✈️ CRASHED JET: Player's jet (tilted and damaged look)
              Transform.rotate(
                angle: -0.3, // Slight tilt to show crashed state
                child: Image.asset(
                  'assets/images/${jetSkin.assetPath}',
                  width: iconSize,
                  height: iconSize,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.airplanemode_active,
                      size: iconSize,
                      color: Colors.white70,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 📊 MAIN CONTENT: Progress, message, continue options, action buttons
  Widget _buildMainContent(Size screenSize) {
    final progress = widget.objectiveAchieved / widget.objectiveTarget;
    final canContinue = widget.continuesRemaining > 0;

    final horizontalPadding = ResponsiveConfig.responsivePadding(20.0, screenSize);
    final verticalPadding = ResponsiveConfig.responsivePadding(16.0, screenSize);
    final spacingSmall = ResponsiveConfig.responsivePadding(12.0, screenSize);
    final spacingMedium = ResponsiveConfig.responsivePadding(14.0, screenSize);
    
    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, ResponsiveConfig.responsivePadding(8.0, screenSize), horizontalPadding, verticalPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress section - compact circular progress
          _buildCompactProgressSection(progress, screenSize),
          SizedBox(height: spacingSmall),

          // Encouragement message - motivating
          Builder(
            builder: (context) {
              final fontSize = ResponsiveConfig.responsiveFontSize(14.0, screenSize, context);
              return Text(
                _getEncouragementMessage(progress),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              );
            },
          ),
          SizedBox(height: spacingMedium),

          // Continue options - compact buttons (if continues available)
          if (canContinue) ...[
            _buildCompactContinueOptions(screenSize),
            SizedBox(height: spacingSmall),
            // Divider
            Row(
              children: [
                Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1), thickness: 1)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: spacingSmall),
                  child: Builder(
                    builder: (context) {
                      final fontSize = ResponsiveConfig.responsiveFontSize(11.0, screenSize, context);
                      return Text(
                        'OR',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1), thickness: 1)),
              ],
            ),
            SizedBox(height: spacingSmall),
          ],

          // Action button - "START OVER" (replaces "Try Again")
          _buildStartOverButton(screenSize),
        ],
      ),
    );
  }

  String _getEncouragementMessage(double progress) {
    final isVsMode = widget.level.objective.type == ObjectiveType.beatBot;
    
    if (isVsMode) {
      // VS Mode: Competitive messaging
      final obstacles = widget.objectiveAchieved;
      if (obstacles >= 10) {
        return 'So close! One more try could win it! 🏆';
      } else if (obstacles >= 5) {
        return 'You can beat the Police Patrol! Try again! 🚀';
      } else {
        return 'Race smarter, not harder! You got this! 💪';
      }
    } else {
      // Story Mode: Progress-based messaging
      if (progress > 0.7) {
        return 'Almost there! You can do this! 💪';
      } else if (progress > 0.4) {
        return 'Don\'t give up! Keep trying! 🚀';
      } else {
        return 'Learn the pattern and try again! 🎯';
      }
    }
  }

  /// 📊 COMPACT PROGRESS SECTION: Smaller circular progress (responsive size)
  Widget _buildCompactProgressSection(double progress, Size screenSize) {
    final isVsMode = widget.level.objective.type == ObjectiveType.beatBot;
    
    // 🎮 VS MODE: Show random 80-95% to create urgency
    // 🎯 STORY MODE: Show actual progress percentage (capped at 100%)
    final int percentage;
    final double displayProgress;
    
    if (isVsMode) {
      // Generate consistent random percentage (80-95%) based on achieved score
      final seed = widget.objectiveAchieved % 16; // 0-15
      percentage = 80 + seed; // 80-95%
      displayProgress = percentage / 100;
    } else {
      // Story mode: Cap at 100% max
      final cappedProgress = progress.clamp(0.0, 1.0);
      percentage = (cappedProgress * 100).toInt();
      displayProgress = cappedProgress;
    }
    
    // Responsive progress circle size
    final progressSize = ResponsiveConfig.responsiveSize(80.0, screenSize, minScale: 0.9, maxScale: 1.2);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Circular progress with percentage (responsive size)
        Stack(
          alignment: Alignment.center,
          children: [
            // Background circle
            SizedBox(
              width: progressSize,
              height: progressSize,
              child: CircularProgressIndicator(
                value: displayProgress,
                strokeWidth: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  displayProgress > 0.7 
                    ? Colors.amber 
                    : displayProgress > 0.4 
                      ? Colors.orange 
                      : Colors.red,
                ),
              ),
            ),
            // Percentage text
            Builder(
              builder: (context) {
                final percentageFontSize = ResponsiveConfig.responsiveFontSize(24.0, screenSize, context);
                final labelFontSize = ResponsiveConfig.responsiveFontSize(11.0, screenSize, context);
                
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: percentageFontSize,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: ResponsiveConfig.responsivePadding(1.0, screenSize)),
                    Text(
                      isVsMode ? 'There!' : 'Done',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: labelFontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        SizedBox(height: ResponsiveConfig.responsivePadding(10.0, screenSize)),
        // Objective details (responsive text)
        Builder(
          builder: (context) {
            final fontSize = ResponsiveConfig.responsiveFontSize(13.0, screenSize, context);
            return Text(
              isVsMode 
                ? '🏆 ${widget.objectiveAchieved} obstacles dodged!'
                : widget.level.objective.description,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
              ),
            );
          },
        ),
        // Only show X/Y for story mode
        if (!isVsMode) ...[
          SizedBox(height: ResponsiveConfig.responsivePadding(6.0, screenSize)),
          Builder(
            builder: (context) {
              final fontSize = ResponsiveConfig.responsiveFontSize(12.0, screenSize, context);
              return Text(
                '${widget.objectiveAchieved} / ${widget.objectiveTarget}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  /// 🎬 COMPACT CONTINUE OPTIONS: Smaller, more engaging buttons
  Widget _buildCompactContinueOptions(Size screenSize) {
    final playerGems = _inventoryManager.gems;
    final continuePrice = 3; // 3 gems per continue
    final canAffordGems = playerGems >= continuePrice;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Continue header (responsive)
        Builder(
          builder: (context) {
            final fontSize = ResponsiveConfig.responsiveFontSize(15.0, screenSize, context);
            return Text(
              'Continue? ${widget.continuesRemaining} left',
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
        SizedBox(height: ResponsiveConfig.responsivePadding(10.0, screenSize)),
        // Compact continue buttons row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Watch Ad button - compact
            _buildCompactAdButton(
              onPressed: widget.onContinueWithAd,
              screenSize: screenSize,
            ),
            SizedBox(width: ResponsiveConfig.responsivePadding(12.0, screenSize)),
            // Use Gems button - compact
            _buildCompactGemButton(
              gemCost: continuePrice,
              canAfford: canAffordGems,
              onPressed: canAffordGems && widget.onContinueWithGems != null
                ? widget.onContinueWithGems
                : null,
              screenSize: screenSize,
            ),
          ],
        ),
      ],
    );
  }

  /// 🎬 COMPACT AD BUTTON: Smaller, engaging design
  Widget _buildCompactAdButton({VoidCallback? onPressed, required Size screenSize}) {
    final isEnabled = onPressed != null;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onPressed : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 110,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isEnabled 
                ? [
                    Colors.green.withValues(alpha: 0.35),
                    Colors.green.withValues(alpha: 0.2),
                  ]
                : [
                    Colors.grey.withValues(alpha: 0.2),
                    Colors.grey.withValues(alpha: 0.1),
                  ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isEnabled 
                ? Colors.green.withValues(alpha: 0.6) 
                : Colors.grey.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: isEnabled ? [
              BoxShadow(
                color: Colors.green.withValues(alpha: 0.3),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ] : null,
          ),
          child: Builder(
            builder: (context) {
              final freeFontSize = ResponsiveConfig.responsiveFontSize(22.0, screenSize, context);
              final iconSize = ResponsiveConfig.responsiveIconSize(16.0, screenSize);
              final labelFontSize = ResponsiveConfig.responsiveFontSize(10.0, screenSize, context);
              
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // "FREE" text
                  Text(
                    'FREE',
                    style: TextStyle(
                      color: isEnabled ? Colors.greenAccent : Colors.grey,
                      fontSize: freeFontSize,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      shadows: isEnabled ? [
                        Shadow(
                          color: Colors.green.withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ] : null,
                    ),
                  ),
                  SizedBox(height: ResponsiveConfig.responsivePadding(4.0, screenSize)),
                  // Video icon
                  Icon(
                    Icons.play_circle_outline,
                    color: isEnabled ? Colors.white.withValues(alpha: 0.9) : Colors.grey,
                    size: iconSize,
                  ),
                  SizedBox(height: ResponsiveConfig.responsivePadding(2.0, screenSize)),
                  // "watch ad" text
                  Text(
                    'watch ad',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isEnabled ? Colors.white.withValues(alpha: 0.8) : Colors.grey,
                      fontSize: labelFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// 💎 COMPACT GEM BUTTON: Smaller, engaging design
  Widget _buildCompactGemButton({
    required int gemCost,
    required bool canAfford,
    VoidCallback? onPressed,
    required Size screenSize,
  }) {
    final isEnabled = onPressed != null && canAfford;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onPressed : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 110,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isEnabled 
                ? [
                    Colors.purple.withValues(alpha: 0.35),
                    Colors.purple.withValues(alpha: 0.2),
                  ]
                : [
                    Colors.grey.withValues(alpha: 0.2),
                    Colors.grey.withValues(alpha: 0.1),
                  ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isEnabled 
                ? Colors.purple.withValues(alpha: 0.6) 
                : Colors.grey.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: isEnabled ? [
              BoxShadow(
                color: Colors.purple.withValues(alpha: 0.3),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ] : null,
          ),
          child: Builder(
            builder: (context) {
              final gemCostFontSize = ResponsiveConfig.responsiveFontSize(22.0, screenSize, context);
              final gemsLabelFontSize = ResponsiveConfig.responsiveFontSize(12.0, screenSize, context);
              final iconSize = ResponsiveConfig.responsiveIconSize(16.0, screenSize);
              final continueFontSize = ResponsiveConfig.responsiveFontSize(10.0, screenSize, context);
              
              return Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // "3 GEMS" on same line at top
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$gemCost',
                        style: TextStyle(
                          color: isEnabled ? Colors.white : Colors.grey,
                          fontSize: gemCostFontSize,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          shadows: isEnabled ? [
                            Shadow(
                              color: Colors.purple.withValues(alpha: 0.5),
                              blurRadius: 6,
                            ),
                          ] : null,
                        ),
                      ),
                      SizedBox(width: ResponsiveConfig.responsivePadding(4.0, screenSize)),
                      Text(
                        'GEMS',
                        style: TextStyle(
                          color: isEnabled ? Colors.white.withValues(alpha: 0.9) : Colors.grey,
                          fontSize: gemsLabelFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveConfig.responsivePadding(4.0, screenSize)),
                  // Gem icon in middle
                  Image.asset(
                    'assets/images/icons/gem_icon.png',
                    width: iconSize,
                    height: iconSize,
                    color: isEnabled ? null : Colors.grey,
                    opacity: isEnabled ? const AlwaysStoppedAnimation(1.0) : const AlwaysStoppedAnimation(0.5),
                  ),
                  SizedBox(height: ResponsiveConfig.responsivePadding(2.0, screenSize)),
                  // "continue" text at bottom
                  Text(
                    'continue',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isEnabled ? Colors.white.withValues(alpha: 0.8) : Colors.grey,
                      fontSize: continueFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// 🚀 START OVER BUTTON: Replaces "Try Again", opens heart refill dialog if needed
  Widget _buildStartOverButton(Size screenSize) {
    final hasHearts = _livesManager.currentLives > 0;
    final buttonHeight = ResponsiveConfig.responsiveButtonHeight(48.0, screenSize);
    
    return SizedBox(
      width: double.infinity,
      child: ModernGameButton(
        label: hasHearts 
          ? 'START OVER (${_livesManager.currentLives} ❤️)'
          : 'START OVER',
        onPressed: _onStartOver,
        height: buttonHeight,
        style: hasHearts ? ModernButtonStyle.gold : ModernButtonStyle.secondary,
        enabled: true, // Always enabled (will show heart refill dialog if no hearts)
      ),
    );
  }

  void _onBackToMap() async {
    // ✅ NEW: Refill hearts to max when returning to world map
    await _livesManager.refillToMax();
    safePrint('🗺️ STORY MODE: Returning to world map - Hearts refilled to max');
    
    if (!mounted) return;
    
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const WorldMapScreen(),
      ),
      (route) => route.isFirst, // ✅ Keep tab navigation in stack so back button works
    );
  }

  /// 🚀 START OVER: Refills hearts and restarts level (free-to-play!)
  void _onStartOver() async {
    // ✅ ALWAYS refill hearts to max when restarting level (free-to-play!)
    await _livesManager.refillToMax();
    safePrint('🔄 STORY MODE: Try Again tapped - Hearts refilled to max');
    
    if (!mounted) return;

    // ❤️ Navigate back to level objective popup with full hearts
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => LevelObjectivePopup(level: widget.level),
      ),
    );
  }

}


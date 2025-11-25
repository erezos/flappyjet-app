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
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  
  // ✅ SMOKE ANIMATION: Controller for realistic smoke effects
  late AnimationController _smokeController;

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
    
    // ✅ SMOKE ANIMATION: Setup smoke controller (one-time animation)
    _smokeController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    
    // Start the smoke animation (runs once then stops)
    _smokeController.forward();

    // Start animations
    _animationController.forward();

    safePrint('💀 STORY MODE: Game Over popup shown - ${widget.objectiveAchieved}/${widget.objectiveTarget}');
  }

  @override
  void dispose() {
    _animationController.dispose();
    _smokeController.dispose();
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
            child: Builder(
              builder: (context) {
                // Calculate button size for positioning
                final buttonSize = ResponsiveConfig.responsiveIconSize(44.0, screenSize)
                    .clamp(44.0, 56.0);
                final buttonOffset = -buttonSize / 2; // Half outside (on border)
                
                return Stack(
                  clipBehavior: Clip.none, // ✅ Allow children to overflow (for X button on frame)
                  children: [
                // Main content (clipped to border radius)
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(), // Smooth scrolling without bouncing
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeader(screenSize),
                        _buildMainContent(screenSize),
                      ],
                    ),
                  ),
                ),
                    // ✅ X BUTTON: Positioned on popup frame (outside container, on border)
                    Positioned(
                      top: buttonOffset,
                      right: buttonOffset,
                      child: _buildCloseButton(screenSize),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// ✅ X BUTTON: Positioned on popup frame (outside container, on border)
  /// Uses ResponsiveConfig for consistent sizing across all devices
  Widget _buildCloseButton(Size screenSize) {
    // Responsive button size (minimum 44x44 for touch target accessibility)
    final buttonSize = ResponsiveConfig.responsiveIconSize(44.0, screenSize)
        .clamp(44.0, 56.0); // Min 44px (accessibility), max 56px
    
    // Responsive icon size
    final iconSize = ResponsiveConfig.responsiveIconSize(24.0, screenSize)
        .clamp(20.0, 28.0);
    
    // Responsive border width
    final borderWidth = ResponsiveConfig.responsiveSize(2.0, screenSize)
        .clamp(1.5, 3.0);

    return GestureDetector(
      onTap: _onBackToMap,
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.7), // More opaque for visibility on frame
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.9), // High contrast white border
            width: borderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: ResponsiveConfig.responsiveSize(12.0, screenSize),
              spreadRadius: ResponsiveConfig.responsiveSize(2.0, screenSize),
              offset: Offset(0, ResponsiveConfig.responsiveSize(2.0, screenSize)),
            ),
          ],
        ),
        child: Icon(
          Icons.close_rounded,
          size: iconSize,
          color: Colors.white,
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
        // ✅ NO RED GRADIENT: Removed red gradient to eliminate red square appearance
        // Using subtle dark gradient instead for depth without red
        gradient: LinearGradient(
          colors: [
            Colors.black.withValues(alpha: 0.1),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        children: [
          // 🚀 CRASHED JET: Player's jet with smoke animation (MUCH BIGGER - responsive size)
          Builder(
            builder: (context) {
              // ✅ MUCH BIGGER: Increased from 90px to 140px base, with larger range
              final jetSize = ResponsiveConfig.responsiveSize(140.0, screenSize, minScale: 0.9, maxScale: 1.2);
              return _buildCrashedPlayerJet(jetSize.clamp(120.0, 180.0));
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

  /// 🚀 CRASHED PLAYER JET: Show player's equipped jet with REAL ANIMATED SMOKE
  /// ✅ RESPONSIVE: Uses same smoke effect as level complete screen, scales proportionally
  Widget _buildCrashedPlayerJet(double iconSize) {
    // Get player's equipped jet skin
    final inventory = InventoryManager();
    final equippedSkinId = inventory.equippedSkinId;
    final jetSkin = JetSkinCatalog.getSkinById(equippedSkinId) ?? JetSkinCatalog.starterJet;
    final jetPath = 'assets/images/${jetSkin.assetPath}';
    
    // ✅ RESPONSIVE: Scale all positions and sizes proportionally (Flame/Flutter best practice)
    // Base design was for 90px, so scale factor = iconSize / 90
    final scaleFactor = iconSize / 90.0;
    double scaled(double baseValue) => baseValue * scaleFactor;
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: SizedBox(
            width: iconSize,
            height: iconSize,
            // ✅ NO BACKGROUND: SizedBox is transparent by default, no red square
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
                      top: scaled(10) - (t * scaled(5)),
                      child: Transform.rotate(
                        angle: t * 1.2,
                        child: Opacity(
                          opacity: (0.5 - t * 0.3).clamp(0.0, 0.5),
                          child: Transform.scale(
                            scale: 1.0 + (t * 0.4),
                            child: Image.asset(
                              'assets/images/effects/explosion_smoke.png',
                              width: scaled(60),
                              height: scaled(60),
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback: Use gradient circle if asset missing
                                return Container(
                                  width: scaled(60),
                                  height: scaled(60),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        Colors.grey.withValues(alpha: 0.6),
                                        Colors.grey.withValues(alpha: 0.2),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Rising smoke particle 1 (left side) - drifting up and left
                    Positioned(
                      top: scaled(5) - (t * scaled(16)),
                      left: scaled(10) - (t * scaled(7)),
                      child: Transform.rotate(
                        angle: t * 2.0,
                        child: Opacity(
                          opacity: smoke1Opacity,
                          child: Transform.scale(
                            scale: 0.6 + (t * 0.6),
                            child: Image.asset(
                              'assets/images/effects/smoke_particle_2.png',
                              width: scaled(22),
                              height: scaled(22),
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: scaled(22),
                                  height: scaled(22),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        Colors.grey.withValues(alpha: 0.7),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Rising smoke particle 2 (right side) - drifting up and right
                    Positioned(
                      top: scaled(7) - (t * scaled(18)),
                      right: scaled(8) + (t * scaled(5)),
                      child: Transform.rotate(
                        angle: -t * 1.8,
                        child: Opacity(
                          opacity: smoke2Opacity,
                          child: Transform.scale(
                            scale: 0.5 + (t * 0.7),
                            child: Image.asset(
                              'assets/images/effects/smoke_particle_1.png',
                              width: scaled(20),
                              height: scaled(20),
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: scaled(20),
                                  height: scaled(20),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        Colors.grey.withValues(alpha: 0.7),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Middle smoke puff (center-left) - rising and expanding
                    Positioned(
                      top: scaled(14) - (t * scaled(12)),
                      left: scaled(12) - (t * scaled(4)),
                      child: Transform.rotate(
                        angle: t * 2.5,
                        child: Opacity(
                          opacity: smoke3Opacity,
                          child: Transform.scale(
                            scale: 0.4 + (t * 0.5),
                            child: Image.asset(
                              'assets/images/effects/smoke_particle_3.png',
                              width: scaled(18),
                              height: scaled(18),
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: scaled(18),
                                  height: scaled(18),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        Colors.grey.withValues(alpha: 0.7),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Additional smoke wisp (top center) - quick dissipation
                    Positioned(
                      top: scaled(3) - (t * scaled(20)),
                      left: scaled(30) + (t * scaled(3)),
                      child: Transform.rotate(
                        angle: -t * 2.2,
                        child: Opacity(
                          opacity: smoke4Opacity,
                          child: Transform.scale(
                            scale: 0.3 + (t * 0.5),
                            child: Image.asset(
                              'assets/images/effects/smoke_particle_1.png',
                              width: scaled(16),
                              height: scaled(16),
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: scaled(16),
                                  height: scaled(16),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        Colors.grey.withValues(alpha: 0.7),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Fire spark 1 (flickering, stays near crash site)
                    Positioned(
                      top: scaled(30) + (t * scaled(1.5)),
                      left: scaled(16),
                      child: Opacity(
                        opacity: sparkFlicker1,
                        child: Transform.scale(
                          scale: 0.8 + (0.3 * (1.0 - t)),
                          child: Image.asset(
                            'assets/images/effects/fire_spark_1.png',
                            width: scaled(12),
                            height: scaled(12),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: scaled(12),
                                height: scaled(12),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.orange.withValues(alpha: 0.8),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    
                    // Fire spark 2 (flickering, stays near crash site)
                    Positioned(
                      top: scaled(32) + (t * scaled(1.0)),
                      right: scaled(14),
                      child: Opacity(
                        opacity: sparkFlicker2,
                        child: Transform.scale(
                          scale: 0.7 + (0.4 * (1.0 - t)),
                          child: Image.asset(
                            'assets/images/effects/fire_spark_2.png',
                            width: scaled(11),
                            height: scaled(11),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: scaled(11),
                                height: scaled(11),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.red.withValues(alpha: 0.8),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    
                    // Orange explosion glow overlay (pulsing gently)
                    Positioned(
                      child: Container(
                        width: scaled(65) + (t * scaled(5)),
                        height: scaled(65) + (t * scaled(5)),
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
                    
                    // ✈️ CRASHED JET: Player's jet (tilted and damaged look)
                    // ✅ NO RED SQUARE: Just the jet with shadow, NO container/border/background
                    Positioned(
                      top: scaled(28) + (t < 0.2 ? t * scaled(1.5) : scaled(0.3)),
                      child: Transform.rotate(
                        angle: -0.25 + (t < 0.3 ? t * 0.1 : 0.03),
                        child: Container(
                          width: scaled(42),
                          height: scaled(42),
                          // ✅ EXPLICITLY TRANSPARENT: No background, no border, no red
                          // ✅ FIX: Cannot use both color and decoration - use decoration.color instead
                          decoration: BoxDecoration(
                            // ✅ NO RED: Only black shadow for depth, transparent background
                            color: Colors.transparent, // Explicit transparent background
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
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.airplanemode_active,
                                size: scaled(42),
                                color: Colors.white70,
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


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
import '../../game/systems/monetization_manager.dart';
import '../../game/core/jet_skins.dart';
import '../../core/debug_logger.dart';
import 'world_map_screen.dart';
import 'level_objective_popup.dart';
import '../widgets/buttons/modern_game_button.dart';
import '../widgets/buttons/button_styles.dart';
import '../widgets/no_hearts_dialog.dart';

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
    // 🎮 RESPONSIVE CONSTRAINTS: Popup takes 85% width, max 75% height
    final popupWidth = (screenSize.width * 0.85).clamp(300.0, 420.0);
    final maxPopupHeight = screenSize.height * 0.75; // Maximum 75% of screen height
    
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
                      _buildHeader(screenSize.height),
                      _buildMainContent(),
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

  bool _canRetry() {
    return _livesManager.currentLives > 0;
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
  Widget _buildHeader(double screenHeight) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
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
          // 🚀 CRASHED JET: Player's jet with smoke animation (12% screen height)
          _buildCrashedPlayerJet((screenHeight * 0.12).clamp(80.0, 100.0)),
          const SizedBox(height: 10),
          const Text(
            'GAME OVER',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24, // Slightly smaller for compact design
              fontWeight: FontWeight.w900,
              letterSpacing: 2.5,
              shadows: [
                Shadow(
                  color: Colors.red,
                  blurRadius: 12,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.level.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
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
  Widget _buildMainContent() {
    final progress = widget.objectiveAchieved / widget.objectiveTarget;
    final canContinue = widget.continuesRemaining > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress section - compact circular progress
          _buildCompactProgressSection(progress),
          const SizedBox(height: 12),

          // Encouragement message - motivating
          Text(
            _getEncouragementMessage(progress),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),

          // Continue options - compact buttons (if continues available)
          if (canContinue) ...[
            _buildCompactContinueOptions(),
            const SizedBox(height: 12),
            // Divider
            Row(
              children: [
                Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1), thickness: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'OR',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1), thickness: 1)),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Action button - "START OVER" (replaces "Try Again")
          _buildStartOverButton(),
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

  /// 📊 COMPACT PROGRESS SECTION: Smaller circular progress (80px instead of 120px)
  Widget _buildCompactProgressSection(double progress) {
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
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Circular progress with percentage (COMPACT: 80px instead of 120px)
        Stack(
          alignment: Alignment.center,
          children: [
            // Background circle
            SizedBox(
              width: 80,
              height: 80,
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
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$percentage%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24, // Smaller font for compact design
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  isVsMode ? 'There!' : 'Done',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Objective details (smaller text)
        Text(
          isVsMode 
            ? '🏆 ${widget.objectiveAchieved} obstacles dodged!'
            : widget.level.objective.description,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        // Only show X/Y for story mode
        if (!isVsMode) ...[
          const SizedBox(height: 6),
          Text(
            '${widget.objectiveAchieved} / ${widget.objectiveTarget}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }

  /// 🎬 COMPACT CONTINUE OPTIONS: Smaller, more engaging buttons
  Widget _buildCompactContinueOptions() {
    final playerGems = _inventoryManager.gems;
    final continuePrice = 3; // 3 gems per continue
    final canAffordGems = playerGems >= continuePrice;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Continue header (smaller)
        Text(
          'Continue? ${widget.continuesRemaining} left',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        // Compact continue buttons row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Watch Ad button - compact
            _buildCompactAdButton(
              onPressed: widget.onContinueWithAd,
            ),
            const SizedBox(width: 12),
            // Use Gems button - compact
            _buildCompactGemButton(
              gemCost: continuePrice,
              canAfford: canAffordGems,
              onPressed: canAffordGems && widget.onContinueWithGems != null
                ? widget.onContinueWithGems
                : null,
            ),
          ],
        ),
      ],
    );
  }

  /// 🎬 COMPACT AD BUTTON: Smaller, engaging design
  Widget _buildCompactAdButton({VoidCallback? onPressed}) {
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // "FREE" text
              Text(
                'FREE',
                style: TextStyle(
                  color: isEnabled ? Colors.greenAccent : Colors.grey,
                  fontSize: 22,
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
              const SizedBox(height: 4),
              // Video icon
              Icon(
                Icons.play_circle_outline,
                color: isEnabled ? Colors.white.withValues(alpha: 0.9) : Colors.grey,
                size: 16,
              ),
              const SizedBox(height: 2),
              // "watch ad" text
              Text(
                'watch ad',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isEnabled ? Colors.white.withValues(alpha: 0.8) : Colors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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
          child: Column(
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
                      fontSize: 22,
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
                  const SizedBox(width: 4),
                  Text(
                    'GEMS',
                    style: TextStyle(
                      color: isEnabled ? Colors.white.withValues(alpha: 0.9) : Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Gem icon in middle
              Image.asset(
                'assets/images/icons/gem_icon.png',
                width: 16,
                height: 16,
                color: isEnabled ? null : Colors.grey,
                opacity: isEnabled ? const AlwaysStoppedAnimation(1.0) : const AlwaysStoppedAnimation(0.5),
              ),
              const SizedBox(height: 2),
              // "continue" text at bottom
              Text(
                'continue',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isEnabled ? Colors.white.withValues(alpha: 0.8) : Colors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🚀 START OVER BUTTON: Replaces "Try Again", opens heart refill dialog if needed
  Widget _buildStartOverButton() {
    final hasHearts = _livesManager.currentLives > 0;
    
    return SizedBox(
      width: double.infinity,
      child: ModernGameButton(
        label: hasHearts 
          ? 'START OVER (${_livesManager.currentLives} ❤️)'
          : 'START OVER',
        onPressed: _onStartOver,
        height: 48, // Compact height
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

  /// ❤️ HEART REFILL DIALOG: Show NoHeartsDialog which offers 12 gems for full refill
  Future<void> _showHeartRefillDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => NoHeartsDialog(
        onClose: () => Navigator.of(context).pop(false),
        monetization: MonetizationManager(), // Pass singleton instance
      ),
    );

    // ✅ If hearts were refilled, user can try again
    if (result == true && mounted) {
      setState(() {
        // Rebuild to update button state
      });
    }
  }
}


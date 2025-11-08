/// 💀 STORY MODE - GAME OVER POPUP
/// 
/// Beautiful unified screen for story mode game over.
/// Shows progress, continue options, and level stats.
library;

import 'package:flutter/material.dart';
import '../../models/level_data_schema.dart';
import '../../game/systems/lives_manager.dart';
import '../../game/systems/inventory_manager.dart';
import '../../core/debug_logger.dart';
import 'world_map_screen.dart';
import 'level_objective_popup.dart';
import '../widgets/buttons/modern_game_button.dart';
import '../widgets/buttons/button_styles.dart';

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
                child: _buildContent(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final progress = widget.objectiveAchieved / widget.objectiveTarget;
    final canContinue = widget.continuesRemaining > 0;

    return Container(
      constraints: const BoxConstraints(maxWidth: 420, maxHeight: 680),
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
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with game over title
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
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
                    // Skull/Game Over emoji with glow (more compact)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Text(
                        '💀',
                        style: TextStyle(fontSize: 42),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'GAME OVER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                        shadows: [
                          Shadow(
                            color: Colors.red,
                            blurRadius: 15,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.level.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Main content area (more compact padding)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  children: [
                    // Progress section - elegant circular progress
                    _buildProgressSection(progress),
                    const SizedBox(height: 18),

                    // Encouragement message - clean and motivating
                    Text(
                      progress > 0.7 
                        ? 'Almost there! You can do this! 💪'
                        : progress > 0.4
                          ? 'Don\'t give up! Keep trying! 🚀'
                          : 'Learn the pattern and try again! 🎯',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Continue options - show if continues available
                    if (canContinue) ...[
                      _buildContinueOptions(),
                      const SizedBox(height: 16),
                      // Divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Action buttons
                    _buildActionButtons(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _canRetry() {
    return _livesManager.currentLives > 0;
  }

  // Beautiful circular progress indicator (compact version)
  Widget _buildProgressSection(double progress) {
    final percentage = (progress * 100).toInt();
    
    return Column(
      children: [
        // Circular progress with percentage
        Stack(
          alignment: Alignment.center,
          children: [
            // Background circle
            SizedBox(
              width: 120,
              height: 120,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 10,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress > 0.7 
                    ? Colors.amber 
                    : progress > 0.4 
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
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Complete',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Objective details
        Text(
          widget.level.objective.description,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${widget.objectiveAchieved} / ${widget.objectiveTarget}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // Continue options - beautiful button layout
  Widget _buildContinueOptions() {
    final playerGems = _inventoryManager.gems;
    final continuePrice = 3; // 3 gems per continue
    final canAffordGems = playerGems >= continuePrice;

    return Column(
      children: [
        // Continue header
        Text(
          'Continue? ${widget.continuesRemaining} left',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        // Continue buttons row
        Row(
          children: [
            // Watch Ad button - "FREE" with video icon
            Expanded(
              child: _buildAdContinueButton(
                onPressed: widget.onContinueWithAd,
                isLoading: false, // Ad loading state managed in parent
              ),
            ),
            const SizedBox(width: 12),
            // Use Gems button - with gem icon
            Expanded(
              child: _buildGemContinueButton(
                gemCost: continuePrice,
                playerGems: playerGems,
                canAfford: canAffordGems,
                onPressed: canAffordGems && widget.onContinueWithGems != null
                  ? widget.onContinueWithGems
                  : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 🎬 Ad Continue Button - "FREE" with video icon (more inviting!)
  Widget _buildAdContinueButton({
    VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    final isEnabled = onPressed != null && !isLoading;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onPressed : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isEnabled 
                ? Colors.green.withValues(alpha: 0.6) 
                : Colors.grey.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: isEnabled ? [
              BoxShadow(
                color: Colors.green.withValues(alpha: 0.3),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ] : null,
          ),
          child: Column(
            children: [
              if (isLoading)
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else ...[
                // Big "FREE" text - most inviting!
                Text(
                  'FREE',
                  style: TextStyle(
                    color: isEnabled ? Colors.greenAccent : Colors.grey,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    shadows: isEnabled ? [
                      Shadow(
                        color: Colors.green.withValues(alpha: 0.5),
                        blurRadius: 8,
                      ),
                    ] : null,
                  ),
                ),
                const SizedBox(height: 6),
                // Small video icon
                Icon(
                  Icons.play_circle_outline,
                  color: isEnabled ? Colors.white.withValues(alpha: 0.9) : Colors.grey,
                  size: 20,
                ),
                const SizedBox(height: 2),
                // "watch ad" text
                Text(
                  'watch ad',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isEnabled ? Colors.white.withValues(alpha: 0.8) : Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // 💎 Gem Continue Button - with actual gem image
  Widget _buildGemContinueButton({
    required int gemCost,
    required int playerGems,
    required bool canAfford,
    VoidCallback? onPressed,
  }) {
    final isEnabled = onPressed != null && canAfford;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onPressed : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isEnabled 
                ? Colors.purple.withValues(alpha: 0.6) 
                : Colors.grey.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: isEnabled ? [
              BoxShadow(
                color: Colors.purple.withValues(alpha: 0.3),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ] : null,
          ),
          child: Column(
            children: [
              // Gem icon image
              Image.asset(
                'assets/images/icons/gem_icon.png',
                width: 36,
                height: 36,
                color: isEnabled ? null : Colors.grey, // Gray out if can't afford
                opacity: isEnabled ? const AlwaysStoppedAnimation(1.0) : const AlwaysStoppedAnimation(0.5),
              ),
              const SizedBox(height: 8),
              // Gem cost
              Text(
                '$gemCost',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isEnabled ? Colors.white : Colors.grey,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              // Label
              Text(
                'GEMS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isEnabled ? Colors.white.withValues(alpha: 0.8) : Colors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!canAfford) ...[
                const SizedBox(height: 4),
                Text(
                  'Need $gemCost',
                  style: TextStyle(
                    color: Colors.red.withValues(alpha: 0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Action buttons - Try Again and Back to Map
  Widget _buildActionButtons() {
    return Column(
      children: [
        // Try Again button
        SizedBox(
          width: double.infinity,
          child: ModernGameButton(
            label: _canRetry() 
              ? 'TRY AGAIN (${_livesManager.currentLives} ❤️)'
              : 'TRY AGAIN',
            onPressed: _canRetry() ? _onTryAgain : () {},
            height: 56,
            style: _canRetry() ? ModernButtonStyle.gold : ModernButtonStyle.secondary,
            enabled: _canRetry(),
          ),
        ),
        if (!_canRetry()) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.red.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.favorite_border, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'No hearts remaining. Wait for regeneration.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        // Back to Map button
        SizedBox(
          width: double.infinity,
          child: ModernGameButton(
            label: 'BACK TO MAP',
            onPressed: _onBackToMap,
            height: 56,
            style: ModernButtonStyle.secondary,
          ),
        ),
      ],
    );
  }

  void _onTryAgain() {
    if (!_canRetry()) {
      _showNoHeartsDialog();
      return;
    }

    // Navigate back to level objective popup
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => LevelObjectivePopup(level: widget.level),
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

  void _showNoHeartsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Hearts'),
        content: const Text(
          'You need at least 1 heart to retry. Hearts regenerate over time or you can purchase them in the store.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}


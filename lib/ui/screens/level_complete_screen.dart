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
import '../utils/responsive_config.dart';
import '../widgets/coin_3d_icon.dart';
import 'world_map_screen.dart';
import '../../integrations/interstitial_ad_manager.dart';

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
  
  /// ✅ NEW: Callback when user wants to continue (close popup and animate)
  final VoidCallback? onContinue;

  const LevelCompleteScreen({
    super.key,
    required this.level,
    required this.objectiveAchieved,
    required this.timeTaken,
    required this.continuesUsed,
    this.onContinue,
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
  final InterstitialAdManager _interstitialAdManager = InterstitialAdManager();

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
    
    // Setup smoke animation (one-time only - smoke rises and fades once)
    _smokeController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    
    // Start the smoke animation (runs once then stops)
    _smokeController.forward();

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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // ✅ NEW: Handle back button (same as Continue)
    return WillPopScope(
      onWillPop: () async {
        _handleContinue();
        return false; // Don't let system handle it
      },
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(0.7), // Semi-transparent overlay
        body: Stack(
          children: [
            // Confetti (full screen)
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
                  Color(0xFFFFD700), // Gold
                  Colors.pink,
                ],
                numberOfParticles: 40, // More confetti!
                gravity: 0.25,
                emissionFrequency: 0.05,
              ),
            ),

            // ✅ NEW: Single cohesive popup with X button inside
            SafeArea(
              child: Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: _buildModernPopup(screenWidth, screenHeight),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🎮 FLAME BEST PRACTICE: Fully responsive popup - NO SCROLLING
  /// Uses percentage-based sizing and FittedBox for perfect scaling on any screen
  Widget _buildModernPopup(double screenWidth, double screenHeight) {
    final screenSize = Size(screenWidth, screenHeight);
    
    // 🎮 RESPONSIVE CONSTRAINTS: Popup takes 85% width, max 75% height
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
      maxHeight: 800.0,
    );
    
    // ✅ DYNAMIC ICON: Choose icon based on objective type
    String? trophyIconPath;
    if (widget.level.botBattle == null) {
      // Not a VS level - use mission icons
      if (widget.level.objective.type == ObjectiveType.surviveTime) {
        trophyIconPath = 'assets/images/icons/missions/gold_timer_icon.png';
      } else {
        // Obstacle/collect objectives - randomly pick star or trophy
        final random = (widget.level.id + DateTime.now().millisecond) % 2;
        trophyIconPath = random == 0 
          ? 'assets/images/icons/missions/gold_star_badge_icon.png'
          : 'assets/images/icons/missions/gold_trophy.png';
      }
    }
    // For VS battles, trophyIconPath stays null and we show the crashed jet instead
    
    // Calculate responsive button size for X button positioning
    final buttonSize = ResponsiveConfig.responsiveIconSize(44.0, screenSize)
        .clamp(44.0, 56.0); // Min 44px (accessibility), max 56px
    final buttonOffset = -buttonSize / 2; // Half outside (on border)
    
    // Calculate margins for Container (responsive)
    final marginInsets = ResponsiveConfig.responsiveEdgeInsetsSymmetric(
      horizontal: 24.0,
      vertical: screenHeight * 0.125,
      screenSize: screenSize,
    );
    
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: popupWidth + marginInsets.horizontal * 2, // Account for margins
        maxHeight: maxPopupHeight + marginInsets.vertical * 2,
      ),
      child: Stack(
        clipBehavior: Clip.none, // ✅ CRITICAL: Allow X button to overflow outside container
        children: [
          // 🎮 POPUP CONTAINER: Main content container
          Container(
            width: popupWidth,
            constraints: BoxConstraints(
              maxHeight: maxPopupHeight, // 🎮 CONSTRAIN HEIGHT: Never exceed 75% of screen
            ),
            margin: marginInsets,
          decoration: BoxDecoration(
            // ✅ MODERN: Vibrant gradient background
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6A11CB), // Purple
                Color(0xFF2575FC), // Blue
              ],
            ),
            borderRadius: BorderRadius.circular(
              ResponsiveConfig.responsiveSize(30.0, screenSize).clamp(24.0, 36.0),
            ),
            border: Border.all(
              color: const Color(0xFFFFD700).withOpacity(0.6), // Gold border
              width: ResponsiveConfig.responsiveSize(3.0, screenSize).clamp(2.0, 4.0),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.3),
                blurRadius: ResponsiveConfig.responsiveSize(30.0, screenSize),
                spreadRadius: ResponsiveConfig.responsiveSize(5.0, screenSize),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: ResponsiveConfig.responsiveSize(20.0, screenSize),
                offset: Offset(0, ResponsiveConfig.responsiveSize(10.0, screenSize)),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              ResponsiveConfig.responsivePadding(16.0, screenSize),
              ResponsiveConfig.responsivePadding(50.0, screenSize), // Top padding for X button clearance
              ResponsiveConfig.responsivePadding(16.0, screenSize),
              ResponsiveConfig.responsivePadding(16.0, screenSize),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown, // 🎮 SCALE DOWN content if too big, never scroll
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: popupWidth - ResponsiveConfig.responsivePadding(32.0, screenSize), // Account for padding
                ),
                child: IntrinsicHeight( // 🎮 Size based on content, but respect FittedBox
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ✅ DYNAMIC: Trophy icon OR crashed jet - responsive sizing
                      _buildResponsiveIcon(screenHeight, trophyIconPath),
                      
                      SizedBox(height: screenHeight * 0.01), // 1% spacing

                      // ✅ COLORFUL: Title with gradient text effect
                      _buildTitle(),
                      
                      SizedBox(height: screenHeight * 0.005), // 0.5% spacing

                      // Level info - compact
                      _buildLevelInfo(),
                      
                      SizedBox(height: screenHeight * 0.015), // 1.5% spacing

                      // ✅ STATS: Compact rows
                      _buildStats(),
                      
                      SizedBox(height: screenHeight * 0.015), // 1.5% spacing

                      // ✅ REWARDS: Seamless content
                      _buildRewards(),
                      
                      SizedBox(height: screenHeight * 0.02), // 2% spacing

                      // ✅ MODERN: Continue button
                      _buildContinueButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        
          // ✅ X BUTTON: Positioned on popup frame (outside container, on border)
          // Position relative to Container's top-right corner using negative offsets
          // This ensures consistent positioning across all screen sizes
          Positioned(
            top: marginInsets.top + buttonOffset, // Top margin + negative offset (half outside)
            right: marginInsets.right + buttonOffset, // Right margin + negative offset (half outside)
            child: _buildCloseButton(screenSize),
          ),
        ],
      ),
    );
  }

  // 🎮 HELPER METHODS: Clean, modular widgets for responsive popup

  /// ✅ NEW: Build close button (X) positioned on popup frame
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
      onTap: _handleContinue,
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.7), // More opaque for visibility on frame
          border: Border.all(
            color: Colors.white.withOpacity(0.9), // High contrast white border
            width: borderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: ResponsiveConfig.responsiveSize(12.0, screenSize),
              spreadRadius: ResponsiveConfig.responsiveSize(2.0, screenSize),
              offset: Offset(0, ResponsiveConfig.responsiveSize(2.0, screenSize)),
            ),
          ],
        ),
        child: Icon(
          Icons.close_rounded,
          color: Colors.white,
          size: iconSize,
        ),
      ),
    );
  }

  /// Build responsive icon (trophy or crashed jet) - scales with screen
  Widget _buildResponsiveIcon(double screenHeight, String? trophyIconPath) {
    // 🎮 RESPONSIVE SIZING: VS battles get bigger icons (16-18% height)
    final iconSize = widget.level.botBattle != null
        ? (screenHeight * 0.17).clamp(100.0, 140.0) // 🚀 BIGGER for VS battles!
        : (screenHeight * 0.12).clamp(70.0, 110.0); // Standard for missions
    
    if (widget.level.botBattle != null) {
      // VS Battle: Show crashed rival jet
      return _buildCrashedRivalJet(iconSize);
    } else if (trophyIconPath != null) {
      // Mission icon with bounce animation
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 1200),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Transform.rotate(
              angle: (1.0 - value) * 0.5,
              child: Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withOpacity(0.6),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Image.asset(
                  trophyIconPath,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          );
        },
      );
    }
    return const SizedBox.shrink();
  }

  /// Build title with gradient text effect
  Widget _buildTitle() {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [
          Color(0xFFFFD700),
          Color(0xFFFFF59D),
          Color(0xFFFFD700),
        ],
      ).createShader(bounds),
      child: const Text(
        'LEVEL COMPLETE!', // ✅ UNIFIED: Same text for both replay and first-time
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 19, // 🎯 SMALLER: Reduced from 22 to 19
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          shadows: [
            Shadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
      ),
    );
  }

  /// Build level info text
  Widget _buildLevelInfo() {
    return Text(
      'Level ${widget.level.id}: ${widget.level.name}',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white.withOpacity(0.9),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Build stats section
  Widget _buildStats() {
    // 🎯 VS BATTLES: Compact time display (label + value together)
    if (widget.level.botBattle != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('⏱️', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Text(
            'Time: ${widget.timeTaken}s', // ✅ Combined label + value
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }
    
    // MISSIONS: Standard layout with objective + time
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCompactStatRow('🎯', 'Objective', '${widget.objectiveAchieved}/${widget.level.objective.target}'),
        Divider(height: 12, color: Colors.white.withOpacity(0.2), thickness: 1),
        _buildCompactStatRow('⏱️', 'Time', '${widget.timeTaken}s'),
      ],
    );
  }

  /// Build rewards section
  Widget _buildRewards() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _isReplay ? '🔄 REPLAY REWARD' : '🎁 REWARDS',
          style: TextStyle(
            color: _isReplay ? const Color(0xFF64B5F6) : const Color(0xFFFFD700),
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRewardItem(
              coinIcon: true, // Use Coin3DIcon instead of material icon
              iconColor: const Color(0xFFFFD700),
              value: _isReplay ? '+20' : '+${widget.level.reward.coins}',
            ),
            if (!_isReplay && widget.level.reward.gems > 0) ...[
              const SizedBox(width: 16),
              _buildRewardItem(
                assetPath: 'assets/images/icons/gem_icon.png',
                value: '+${widget.level.reward.gems}',
              ),
            ],
          ],
        ),
        if (_isReplay) ...[
          const SizedBox(height: 6),
          Text(
            'Original reward already earned',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 10,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  /// Build continue button
  Widget _buildContinueButton() {
    return SizedBox(
      width: 280, // Fixed width for button
      height: 48,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4CAF50).withOpacity(0.5),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _handleContinue,
            borderRadius: BorderRadius.circular(24),
            child: const Center(
              child: Text(
                'CONTINUE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ✅ NEW: Compact stat row - NO BOXES
  Widget _buildCompactStatRow(String emoji, String label, String value) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }


  /// ✅ NEW: Reward item with icon/asset and value
  Widget _buildRewardItem({
    bool coinIcon = false, // ✅ Use Coin3DIcon for coins
    Color? iconColor,
    String? assetPath,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (coinIcon)
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.3),
            ),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Coin3DIcon(size: 28), // ✅ Using consistent coin asset
            ),
          )
        else if (assetPath != null)
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.3),
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Image.asset(assetPath, fit: BoxFit.contain),
            ),
          ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(
                color: Colors.black54,
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ],
    );
  }


  /// Build modern crashed rival jet visual for VS battles with REAL ANIMATED SMOKE
  Widget _buildCrashedRivalJet(double iconSize) {
    final bot = widget.level.botBattle!;
    final jetPath = _getBotJetSpritePath(bot.botJetSkin);
    
    // ✅ RESPONSIVE: Scale badge size proportionally with icon size
    final badgePaddingH = (iconSize * 0.34).clamp(16.0, 28.0); // ~24px at 70px
    final badgePaddingV = (iconSize * 0.14).clamp(8.0, 12.0); // ~10px at 70px
    final badgeFontSize = (iconSize * 0.26).clamp(14.0, 22.0); // ~18px at 70px
    
    return Column(
      children: [
        // "VICTORY!" badge with gold/green colors
        Container(
          padding: EdgeInsets.symmetric(horizontal: badgePaddingH, vertical: badgePaddingV),
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
          child: Text(
            'VICTORY!', // ✅ CLEANED: Removed trophy emojis from sides
            style: TextStyle(
              color: const Color(0xFF1A237E), // Dark blue for contrast on gold
              fontSize: badgeFontSize,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.5,
              shadows: const [
                Shadow(
                  color: Colors.white54,
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ),
        
        SizedBox(height: iconSize * 0.14), // ✅ RESPONSIVE: Reduced from ~20px to ~10px (0.29 → 0.14)
        
        // Crashed jet with REAL ANIMATED smoke particles
        // ✅ RESPONSIVE: Size scales proportionally with iconSize (Flame/Flutter best practice)
        SizedBox(
          width: iconSize,
          height: iconSize,
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
              
              // ✅ RESPONSIVE: Scale all positions and sizes proportionally (Flame/Flutter best practice)
              // Base design was for 70px, so scale factor = iconSize / 70
              final scaleFactor = iconSize / 70.0;
              double scaled(double baseValue) => baseValue * scaleFactor;
              
              return Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Large explosion smoke (background) - rotating and expanding
                  // ✅ RESPONSIVE: All values scale proportionally with iconSize
                  Positioned(
                    top: scaled(8) - (t * scaled(4)),
                    child: Transform.rotate(
                      angle: t * 1.2,
                      child: Opacity(
                        opacity: (0.5 - t * 0.3).clamp(0.0, 0.5),
                        child: Transform.scale(
                          scale: 1.0 + (t * 0.4),
                          child: Image.asset(
                            'assets/images/effects/explosion_smoke.png',
                            width: scaled(54),
                            height: scaled(54),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Rising smoke particle 1 (left side) - drifting up and left
                  Positioned(
                    top: scaled(4) - (t * scaled(14)),
                    left: scaled(8) - (t * scaled(6)),
                    child: Transform.rotate(
                      angle: t * 2.0,
                      child: Opacity(
                        opacity: smoke1Opacity,
                        child: Transform.scale(
                          scale: 0.6 + (t * 0.6),
                          child: Image.asset(
                            'assets/images/effects/smoke_particle_2.png',
                            width: scaled(20),
                            height: scaled(20),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Rising smoke particle 2 (right side) - drifting up and right
                  Positioned(
                    top: scaled(6) - (t * scaled(16)),
                    right: scaled(6) + (t * scaled(4)),
                    child: Transform.rotate(
                      angle: -t * 1.8,
                      child: Opacity(
                        opacity: smoke2Opacity,
                        child: Transform.scale(
                          scale: 0.5 + (t * 0.7),
                          child: Image.asset(
                            'assets/images/effects/smoke_particle_1.png',
                            width: scaled(18),
                            height: scaled(18),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Middle smoke puff (center-left) - rising and expanding
                  Positioned(
                    top: scaled(12) - (t * scaled(10)),
                    left: scaled(10) - (t * scaled(3)),
                    child: Transform.rotate(
                      angle: t * 2.5,
                      child: Opacity(
                        opacity: smoke3Opacity,
                        child: Transform.scale(
                          scale: 0.4 + (t * 0.5),
                          child: Image.asset(
                            'assets/images/effects/smoke_particle_3.png',
                            width: scaled(16),
                            height: scaled(16),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Additional smoke wisp (top center) - quick dissipation
                  Positioned(
                    top: scaled(2) - (t * scaled(18)),
                    left: scaled(26) + (t * scaled(2)),
                    child: Transform.rotate(
                      angle: -t * 2.2,
                      child: Opacity(
                        opacity: smoke4Opacity,
                        child: Transform.scale(
                          scale: 0.3 + (t * 0.5),
                          child: Image.asset(
                            'assets/images/effects/smoke_particle_1.png',
                            width: scaled(14),
                            height: scaled(14),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Fire spark 1 (flickering, stays near crash site)
                  Positioned(
                    top: scaled(26) + (t * scaled(1.2)),
                    left: scaled(14),
                    child: Opacity(
                      opacity: sparkFlicker1,
                      child: Transform.scale(
                        scale: 0.8 + (0.3 * (1.0 - t)),
                        child: Image.asset(
                          'assets/images/effects/fire_spark_1.png',
                          width: scaled(11),
                          height: scaled(11),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  
                  // Fire spark 2 (flickering, stays near crash site)
                  Positioned(
                    top: scaled(28) + (t * scaled(0.8)),
                    right: scaled(12),
                    child: Opacity(
                      opacity: sparkFlicker2,
                      child: Transform.scale(
                        scale: 0.7 + (0.4 * (1.0 - t)),
                        child: Image.asset(
                          'assets/images/effects/fire_spark_2.png',
                          width: scaled(10),
                          height: scaled(10),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  
                  // Additional ember (rises up)
                  Positioned(
                    top: scaled(14) - (t * scaled(8)),
                    right: scaled(16) - (t * scaled(2)),
                    child: Opacity(
                      opacity: (1.0 - t * 1.2).clamp(0.0, 0.9),
                      child: Transform.scale(
                        scale: 0.5 + (t * 0.4),
                        child: Image.asset(
                          'assets/images/effects/fire_spark_1.png',
                          width: scaled(7),
                          height: scaled(7),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  
                  // Orange explosion glow overlay (pulsing gently)
                  Positioned(
                    child: Container(
                      width: scaled(58) + (t * scaled(4)),
                      height: scaled(58) + (t * scaled(4)),
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
                  
                  // Tilted crashed jet - FULL COLOR (subtle shake only at beginning)
                  Positioned(
                    top: scaled(24) + (t < 0.2 ? t * scaled(1.2) : scaled(0.24)),
                    child: Transform.rotate(
                      angle: -0.25 + (t < 0.3 ? t * 0.1 : 0.03),
                      child: Container(
                        width: scaled(37),
                        height: scaled(37),
                        decoration: BoxDecoration(
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
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        
        SizedBox(height: iconSize * 0.11), // ✅ FLAME RESPONSIVE: ~8px at 70px, scales with iconSize
        
        // Bot name with defeated styling
        Text(
          bot.botName,
          style: TextStyle(
            color: Colors.red.shade300,
            fontSize: (iconSize * 0.19).clamp(11.0, 15.0), // ✅ FLAME RESPONSIVE: ~13px at 70px, scales with iconSize
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.lineThrough,
            decorationColor: Colors.red.shade300,
            decorationThickness: 2,
          ),
        ),
      ],
    );
  }

  /// ✅ NEW: Handle Continue button / X button / Back button
  /// All three actions do the same thing: trigger the onContinue callback
  void _handleContinue() {
    if (widget.onContinue != null) {
      // New flow: Callback to parent (story_mode_game_wrapper)
      widget.onContinue!();
    } else {
      // Fallback to old flow (direct navigation)
      _onBackToMap();
    }
  }

  void _onBackToMap() async {
    // ✅ Track level win for interstitial ad frequency
    await _interstitialAdManager.onLevelWon();
    
    // ✅ Check and show interstitial ad if conditions are met
    final adShown = await _interstitialAdManager.checkAndShowAd(
      onAdClosed: () => _proceedToWorldMap(),
    );
    
    // If no ad was shown, proceed immediately
    if (!adShown) {
      _proceedToWorldMap();
    }
  }
  
  void _proceedToWorldMap() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const WorldMapScreen(),
      ),
      (route) => route.isFirst, // ✅ Keep tab navigation in stack so back button works
    );
  }
}

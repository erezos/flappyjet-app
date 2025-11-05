/// 🎁 Beautiful Daily Streak Reward Claim Popup - FlappyJet Design Language
/// Premium UI/UX showing reward details with animations and explanations
/// Migrated to use BasePopup + ModernGameButton + Gem3DIcon
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../game/systems/daily_streak_manager.dart';
import '../../../game/core/jet_skins.dart';
import '../popups/base_popup.dart';
import '../buttons/modern_game_button.dart';
import '../buttons/button_styles.dart';
import '../gem_3d_icon.dart';

class DailyStreakRewardClaimPopup extends StatefulWidget {
  final DailyStreakReward reward;
  final VoidCallback? onClose;

  const DailyStreakRewardClaimPopup({
    super.key,
    required this.reward,
    this.onClose,
  });

  @override
  State<DailyStreakRewardClaimPopup> createState() => _DailyStreakRewardClaimPopupState();
}

class _DailyStreakRewardClaimPopupState extends State<DailyStreakRewardClaimPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _rewardController;
  late Animation<double> _rewardAnimation;

  @override
  void initState() {
    super.initState();
    
    // Only keep reward bounce animation (BasePopup handles entrance)
    _rewardController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _rewardAnimation = CurvedAnimation(
      parent: _rewardController,
      curve: Curves.bounceOut,
    );

    // Start reward animation after a delay
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _rewardController.forward();
    });

    // Haptic feedback
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _rewardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;
    final isVerySmallScreen = screenSize.height < 600;

    return BasePopup(
      maxWidthPixels: 400,
      padding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: screenSize.height * 0.75,
        ),
        decoration: BoxDecoration(
          // Premium glassmorphism effect
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.15),
              Colors.white.withValues(alpha: 0.05),
            ],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with reward icon
            _buildHeader(isSmallScreen, isVerySmallScreen),
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isVerySmallScreen ? 16 : isSmallScreen ? 20 : 24,
                  vertical: isVerySmallScreen ? 12 : isSmallScreen ? 16 : 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    _buildTitle(isVerySmallScreen, isSmallScreen),
                    
                    SizedBox(height: isVerySmallScreen ? 8 : isSmallScreen ? 12 : 16),
                    
                    // Reward display
                    _buildRewardDisplay(isVerySmallScreen, isSmallScreen),
                    
                    SizedBox(height: isVerySmallScreen ? 12 : isSmallScreen ? 16 : 20),
                    
                    // Explanation text
                    _buildExplanation(isVerySmallScreen, isSmallScreen),
                    
                    SizedBox(height: isVerySmallScreen ? 20 : isSmallScreen ? 24 : 32),
                    
                    // Action button
                    _buildActionButton(context, isVerySmallScreen, isSmallScreen),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isSmallScreen, bool isVerySmallScreen) {
    final headerIconSize = (isVerySmallScreen ? 28 : isSmallScreen ? 32 : 40).toDouble();
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isVerySmallScreen ? 12 : isSmallScreen ? 16 : 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getRewardColor().withValues(alpha: 0.8),
            _getRewardColor().withValues(alpha: 0.6),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
      ),
      child: widget.reward.type == DailyStreakRewardType.jetSkin && widget.reward.jetSkinId != null
          ? _buildJetSkinHeaderIcon(headerIconSize)
          : Icon(
              _getRewardIcon(),
              size: headerIconSize,
              color: Colors.white,
            ),
    );
  }

  /// Build jet skin icon for header with larger size
  Widget _buildJetSkinHeaderIcon(double size) {
    // Find the jet skin
    final jetSkin = JetSkinCatalog.getAllSkins().firstWhere(
      (skin) => skin.id == widget.reward.jetSkinId,
      orElse: () => JetSkinCatalog.starterJet,
    );

    // Display the actual jet image (larger in header)
    return Center(
      child: Image.asset(
        'assets/images/${jetSkin.assetPath}',
        width: size * 1.5,  // Larger in header
        height: size * 1.5,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to generic icon if image fails to load
          return Icon(
            Icons.flight,
            size: size,
            color: Colors.white,
          );
        },
      ),
    );
  }

  Widget _buildTitle(bool isVerySmallScreen, bool isSmallScreen) {
    return Text(
      '🎉 Daily Reward Claimed!',
      style: TextStyle(
        fontSize: isVerySmallScreen ? 20 : isSmallScreen ? 22 : 26,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        shadows: const [
          Shadow(
            offset: Offset(0, 2),
            blurRadius: 4,
            color: Colors.black54,
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildRewardDisplay(bool isVerySmallScreen, bool isSmallScreen) {
    final iconSize = (isVerySmallScreen ? 28 : isSmallScreen ? 32 : 36).toDouble();
    
    return ScaleTransition(
      scale: _rewardAnimation,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isVerySmallScreen ? 16 : isSmallScreen ? 20 : 24,
          vertical: isVerySmallScreen ? 10 : isSmallScreen ? 12 : 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _getRewardColor().withValues(alpha: 0.8),
              _getRewardColor().withValues(alpha: 0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: _getRewardColor().withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reward icon - Use Gem3DIcon for gems, jet image for jets, regular icon for others
            if (widget.reward.type == DailyStreakRewardType.gems)
              Gem3DIcon(size: iconSize)
            else if (widget.reward.type == DailyStreakRewardType.jetSkin)
              _buildJetSkinIcon(iconSize)
            else
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getRewardColor(),
                      _getRewardColor().withValues(alpha: 0.8),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  _getRewardIcon(),
                  color: Colors.white,
                  size: isVerySmallScreen ? 16 : isSmallScreen ? 18 : 20,
                ),
              ),
            
            SizedBox(width: isVerySmallScreen ? 6 : isSmallScreen ? 8 : 12),
            
            // Reward text - wrapped in Flexible to prevent overflow
            Flexible(
              child: Text(
                _getRewardDisplayText(),
                style: TextStyle(
                  fontSize: isVerySmallScreen ? 18 : isSmallScreen ? 20 : 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: const [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 2,
                      color: Colors.black54,
                    ),
                  ],
                ),
                overflow: TextOverflow.ellipsis, // Prevent overflow with ellipsis
                maxLines: 1, // Keep it on one line
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build jet skin icon with actual jet image
  Widget _buildJetSkinIcon(double size) {
    if (widget.reward.jetSkinId == null) {
      // Fallback to generic icon if no skin ID
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _getRewardColor(),
              _getRewardColor().withValues(alpha: 0.8),
            ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.flight,
          color: Colors.white,
          size: size * 0.6,
        ),
      );
    }

    // Find the jet skin
    final jetSkin = JetSkinCatalog.getAllSkins().firstWhere(
      (skin) => skin.id == widget.reward.jetSkinId,
      orElse: () => JetSkinCatalog.starterJet,
    );

    // Display the actual jet image
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(size / 6),
        boxShadow: [
          BoxShadow(
            color: _getRewardColor().withValues(alpha: 0.4),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 6),
        child: Image.asset(
          'assets/images/${jetSkin.assetPath}',
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to generic icon if image fails to load
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getRewardColor(),
                    _getRewardColor().withValues(alpha: 0.8),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.flight,
                color: Colors.white,
                size: size * 0.6,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildExplanation(bool isVerySmallScreen, bool isSmallScreen) {
    return Text(
      _getExplanationText(),
      style: TextStyle(
        fontSize: isVerySmallScreen ? 13 : isSmallScreen ? 14 : 16,
        color: Colors.white.withValues(alpha: 0.9),
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildActionButton(BuildContext context, bool isVerySmallScreen, bool isSmallScreen) {
    return ModernGameButton(
      label: 'AWESOME!',
      onPressed: () {
        Navigator.of(context).pop();
        widget.onClose?.call();
      },
      height: isVerySmallScreen ? 44 : isSmallScreen ? 48 : 56,
      style: ModernButtonStyle.primary, // Gold
    );
  }

  /// Get reward-specific color
  Color _getRewardColor() {
    switch (widget.reward.type) {
      case DailyStreakRewardType.coins:
        return Colors.amber;
      case DailyStreakRewardType.gems:
        return Colors.purple;
      case DailyStreakRewardType.heartBooster:
        return Colors.pink;
      case DailyStreakRewardType.heart:
        return Colors.red;
      case DailyStreakRewardType.jetSkin:
        return Colors.blue;
      case DailyStreakRewardType.mysteryBox:
        return Colors.deepPurple;
    }
  }

  /// Get reward-specific icon
  IconData _getRewardIcon() {
    switch (widget.reward.type) {
      case DailyStreakRewardType.coins:
        return Icons.monetization_on;
      case DailyStreakRewardType.gems:
        return Icons.diamond;
      case DailyStreakRewardType.heartBooster:
        return Icons.favorite;
      case DailyStreakRewardType.heart:
        return Icons.favorite;
      case DailyStreakRewardType.jetSkin:
        return Icons.flight;
      case DailyStreakRewardType.mysteryBox:
        return Icons.card_giftcard;
    }
  }

  /// Get display text for the reward
  String _getRewardDisplayText() {
    switch (widget.reward.type) {
      case DailyStreakRewardType.coins:
        return '+${widget.reward.amount} Coins';
      case DailyStreakRewardType.gems:
        return '+${widget.reward.amount} Gems';
      case DailyStreakRewardType.heartBooster:
        return '${widget.reward.amount} Min Heart Booster';
      case DailyStreakRewardType.heart:
        return '+1 Heart';
      case DailyStreakRewardType.jetSkin:
        return widget.reward.displayText;
      case DailyStreakRewardType.mysteryBox:
        return 'Mystery Reward!';
    }
  }

  /// Get explanation text for the reward
  String _getExplanationText() {
    switch (widget.reward.type) {
      case DailyStreakRewardType.coins:
        return 'Use coins to unlock new jets, purchase boosters, and continue your games. Keep collecting!';
      
      case DailyStreakRewardType.gems:
        return 'Premium gems! Use them for instant heart refills, special boosters, or save up for exclusive jets.';
      
      case DailyStreakRewardType.heartBooster:
        return '🔥 Amazing! Your Heart Booster is now active for ${widget.reward.amount} minutes!\n\n'
            '✨ Benefits:\n'
            '• Max hearts increased from 3 to 6\n'
            '• Hearts refilled to 6 immediately\n'
            '• Faster heart regeneration (8 min instead of 10 min)\n\n'
            'Go play and enjoy unlimited flying!';
      
      case DailyStreakRewardType.heart:
        return 'One extra heart added! Use it wisely to extend your flight and achieve new high scores.';
      
      case DailyStreakRewardType.jetSkin:
        return 'You\'ve unlocked a new jet skin! Head to the garage to equip it and show off your style.';
      
      case DailyStreakRewardType.mysteryBox:
        return 'Surprise! You received a mystery reward. Check your inventory to see what you got!';
    }
  }
}



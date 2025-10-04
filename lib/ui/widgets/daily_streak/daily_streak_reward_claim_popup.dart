/// 🎁 Beautiful Daily Streak Reward Claim Popup - FlappyJet Design Language
/// Premium UI/UX showing reward details with animations and explanations
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../game/systems/daily_streak_manager.dart';

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
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late AnimationController _rewardController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rewardAnimation;

  @override
  void initState() {
    super.initState();
    
    // Scale animation for popup entrance
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    // Slide animation for content
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Reward animation
    _rewardController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _rewardAnimation = CurvedAnimation(
      parent: _rewardController,
      curve: Curves.bounceOut,
    );

    // Start animations
    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _slideController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _rewardController.forward();
    });

    // Haptic feedback
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _slideController.dispose();
    _rewardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;
    final isVerySmallScreen = screenSize.height < 600;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          // Glassmorphism background
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.7),
              Colors.black.withValues(alpha: 0.9),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: isVerySmallScreen ? 16 : isSmallScreen ? 20 : 32,
                    vertical: isVerySmallScreen ? 32 : isSmallScreen ? 40 : 60,
                  ),
                  constraints: BoxConstraints(
                    maxWidth: 400,
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
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: _getRewardColor().withValues(alpha: 0.1),
                        blurRadius: 40,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
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
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isSmallScreen, bool isVerySmallScreen) {
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
      child: Icon(
        _getRewardIcon(),
        size: isVerySmallScreen ? 28 : isSmallScreen ? 32 : 40,
        color: Colors.white,
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
            // Reward icon
            Container(
              width: isVerySmallScreen ? 28 : isSmallScreen ? 32 : 36,
              height: isVerySmallScreen ? 28 : isSmallScreen ? 32 : 36,
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
            
            // Reward text
            Text(
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
            ),
          ],
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
    return SizedBox(
      width: double.infinity,
      height: isVerySmallScreen ? 44 : isSmallScreen ? 48 : 56,
      child: ElevatedButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).pop();
          widget.onClose?.call();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.4),
              width: 2,
            ),
          ),
        ).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.pressed)) {
              return Colors.white.withValues(alpha: 0.2);
            }
            return Colors.white.withValues(alpha: 0.1);
          }),
        ),
        child: Text(
          'Awesome!',
          style: TextStyle(
            fontSize: isVerySmallScreen ? 15 : isSmallScreen ? 16 : 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
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



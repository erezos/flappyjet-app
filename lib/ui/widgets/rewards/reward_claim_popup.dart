import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../popups/base_popup.dart';
import '../buttons/modern_game_button.dart';
import '../buttons/button_styles.dart';
import '../gem_3d_icon.dart';

/// Generic reward claim popup for Daily Missions and Achievements
/// Displays a beautiful, animated popup when user claims rewards
class RewardClaimPopup extends StatefulWidget {
  final String title; // e.g., "Mission Complete!" or "Achievement Unlocked!"
  final String rewardName; // e.g., "Take Flight" or "First Flight"
  final String description; // Explanation of what they achieved
  final int coinReward;
  final int gemReward;
  final Color themeColor; // Primary color for the popup theme
  final VoidCallback onClose;

  const RewardClaimPopup({
    super.key,
    required this.title,
    required this.rewardName,
    required this.description,
    required this.coinReward,
    required this.gemReward,
    required this.themeColor,
    required this.onClose,
  });

  @override
  State<RewardClaimPopup> createState() => _RewardClaimPopupState();
}

class _RewardClaimPopupState extends State<RewardClaimPopup>
    with SingleTickerProviderStateMixin {
  // No entrance animation controllers needed (BasePopup handles)

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isVerySmallScreen = screenSize.height < 600;
    final isSmallScreen = screenSize.height < 700;

    return BasePopup(
      padding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 20 : 32,
          vertical: isSmallScreen ? 40 : 60,
        ),
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: screenSize.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Background sparkles
              ..._buildSparkles(),

              // Main content
              Padding(
                padding: EdgeInsets.all(isVerySmallScreen ? 16 : 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(isVerySmallScreen),
                    SizedBox(height: isVerySmallScreen ? 12 : 16),
                    _buildRewardName(isVerySmallScreen),
                    SizedBox(height: isVerySmallScreen ? 12 : 16),
                    _buildRewardIcons(isVerySmallScreen),
                    SizedBox(height: isVerySmallScreen ? 16 : 20),
                    _buildDescription(isVerySmallScreen),
                    SizedBox(height: isVerySmallScreen ? 20 : 24),
                    _buildActionButton(context, isSmallScreen),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isVerySmallScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: isVerySmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.themeColor.withValues(alpha: 0.8),
            widget.themeColor.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
      ),
      child: Text(
        widget.title,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: isVerySmallScreen ? 20 : 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [
            Shadow(offset: Offset(0, 2), blurRadius: 4, color: Colors.black54),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardName(bool isVerySmallScreen) {
    return Text(
      widget.rewardName,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: isVerySmallScreen ? 22 : 26,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        shadows: const [
          Shadow(offset: Offset(0, 1), blurRadius: 2, color: Colors.black54),
        ],
      ),
    );
  }

  Widget _buildRewardIcons(bool isVerySmallScreen) {
    final iconSize = isVerySmallScreen ? 48.0 : 60.0;
    final hasCoins = widget.coinReward > 0;
    final hasGems = widget.gemReward > 0;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (hasCoins) ...[
          Column(
            children: [
              Image.asset(
                'assets/images/icons/coin_stack.png',
                height: iconSize,
                width: iconSize,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.monetization_on,
                    size: iconSize,
                    color: Colors.amber,
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                '+${widget.coinReward}',
                style: TextStyle(
                  fontSize: isVerySmallScreen ? 18 : 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
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
        ],
        if (hasCoins && hasGems) SizedBox(width: isVerySmallScreen ? 24 : 32),
        if (hasGems) ...[
          Column(
            children: [
              Gem3DIcon(size: iconSize), // ✅ Real 3D gem image
              const SizedBox(height: 8),
              Text(
                '+${widget.gemReward}',
                style: TextStyle(
                  fontSize: isVerySmallScreen ? 18 : 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
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
        ],
      ],
    );
  }

  Widget _buildDescription(bool isVerySmallScreen) {
    return Text(
      widget.description,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: isVerySmallScreen ? 14 : 16,
        color: Colors.white.withValues(alpha: 0.9),
        height: 1.4,
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, bool isSmallScreen) {
    return ModernGameButton(
      label: 'AWESOME!',
      onPressed: () {
        HapticFeedback.lightImpact();
        widget.onClose();
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      height: isSmallScreen ? 48 : 56,
      style: ModernButtonStyle.primary, // Gold
    );
  }

  List<Widget> _buildSparkles() {
    return List.generate(12, (index) {
      final random = math.Random(index);
      final left = random.nextDouble() * 100; // 0-100%
      final top = random.nextDouble() * 100; // 0-100%
      final size = 4.0 + random.nextDouble() * 8;
      
      return Positioned(
        left: left,
        top: top,
        child: TweenAnimationBuilder<double>(
          key: ValueKey('sparkle_$index'),
          duration: Duration(milliseconds: 1500 + random.nextInt(1000)),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Opacity(
              opacity: (math.sin(value * math.pi * 2) * 0.5 + 0.5) * 0.6,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }
}


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../popups/base_popup.dart';
import '../buttons/modern_game_button.dart';
import '../buttons/button_styles.dart';
import '../gem_3d_icon.dart';
import '../coin_3d_icon.dart';
import '../../utils/responsive_config.dart';

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
    
    // Use ResponsiveConfig for popup sizing
    final popupWidth = ResponsiveConfig.responsivePopupWidth(
      screenSize,
      percent: 0.9,
      minWidth: 320.0,
      maxWidth: 500.0,
    );
    final popupHeight = ResponsiveConfig.responsivePopupHeight(
      screenSize,
      percent: 0.8,
      minHeight: 400.0,
      maxHeight: 700.0,
    );

    return BasePopup(
      padding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      maxWidthPixels: popupWidth,
      child: Container(
        margin: ResponsiveConfig.responsiveEdgeInsetsSymmetric(
          horizontal: 20.0,
          vertical: 40.0,
          screenSize: screenSize,
        ),
        constraints: BoxConstraints(
          maxWidth: popupWidth,
          maxHeight: popupHeight,
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
              LayoutBuilder(
                builder: (context, constraints) {
                  final contentPadding = ResponsiveConfig.responsivePadding(24.0, screenSize);
                  final spacingMedium = ResponsiveConfig.responsivePadding(16.0, screenSize);
                  final spacingLarge = ResponsiveConfig.responsivePadding(20.0, screenSize);
                  
                  return Padding(
                    padding: EdgeInsets.all(contentPadding),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeader(context, screenSize),
                        SizedBox(height: spacingMedium),
                        _buildRewardName(context, screenSize),
                        SizedBox(height: spacingMedium),
                        _buildRewardIcons(context, screenSize, constraints.maxWidth),
                        SizedBox(height: spacingLarge),
                        _buildDescription(context, screenSize),
                        SizedBox(height: spacingLarge),
                        _buildActionButton(context, screenSize),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Size screenSize) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = ResponsiveConfig.responsivePadding(16.0, screenSize);
        final fontSize = ResponsiveConfig.responsiveFontSize(24.0, screenSize, context);
        
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: padding),
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
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: const [
                Shadow(offset: Offset(0, 2), blurRadius: 4, color: Colors.black54),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRewardName(BuildContext context, Size screenSize) {
    final fontSize = ResponsiveConfig.responsiveFontSize(26.0, screenSize, context);
    
    return Text(
      widget.rewardName,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        shadows: const [
          Shadow(offset: Offset(0, 1), blurRadius: 2, color: Colors.black54),
        ],
      ),
    );
  }

  Widget _buildRewardIcons(BuildContext context, Size screenSize, double maxWidth) {
    // Icon size as percentage of popup width (15-18%)
    final iconSize = ResponsiveConfig.responsiveSize(
      maxWidth * 0.15,
      screenSize,
      minScale: 0.9,
      maxScale: 1.2,
    ).clamp(48.0, 80.0);
    final hasCoins = widget.coinReward > 0;
    final hasGems = widget.gemReward > 0;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (hasCoins) ...[
          Column(
            children: [
              Coin3DIcon(size: iconSize), // ✅ Using consistent coin asset
              SizedBox(height: ResponsiveConfig.responsivePadding(8.0, screenSize)),
              Text(
                '+${widget.coinReward}',
                style: TextStyle(
                  fontSize: ResponsiveConfig.responsiveFontSize(22.0, screenSize, context),
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
        if (hasCoins && hasGems) 
          SizedBox(width: ResponsiveConfig.responsivePadding(32.0, screenSize)),
        if (hasGems) ...[
          Column(
            children: [
              Gem3DIcon(size: iconSize), // ✅ Real 3D gem image
              SizedBox(height: ResponsiveConfig.responsivePadding(8.0, screenSize)),
              Text(
                '+${widget.gemReward}',
                style: TextStyle(
                  fontSize: ResponsiveConfig.responsiveFontSize(22.0, screenSize, context),
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

  Widget _buildDescription(BuildContext context, Size screenSize) {
    final fontSize = ResponsiveConfig.responsiveFontSize(16.0, screenSize, context);
    
    return Text(
      widget.description,
      textAlign: TextAlign.center,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: fontSize,
        color: Colors.white.withValues(alpha: 0.9),
        height: 1.4,
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, Size screenSize) {
    final buttonHeight = ResponsiveConfig.responsiveButtonHeight(56.0, screenSize);
    
    return ModernGameButton(
      label: 'AWESOME!',
      onPressed: () {
        HapticFeedback.lightImpact();
        widget.onClose();
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      height: buttonHeight,
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


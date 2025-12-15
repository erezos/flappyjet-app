/// 🎯 Unified Reward Card - Single component for both Missions and Achievements
/// 
/// Features:
/// - Consistent responsive design using ResponsiveConfig
/// - Supports both floating and circular icon styles
/// - Handles coins and optional gem rewards
/// - Three-state status: locked, completed, claimed
/// - Loading state for claim operations
/// - Modern design with subtle highlight effects
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../coin_3d_icon.dart';
import '../gem_3d_icon.dart';
import '../../utils/responsive_config.dart';

/// Status of the reward card
enum RewardCardStatus {
  locked,     // Not completed yet
  completed,  // Completed but not claimed
  claimed,    // Already claimed
}

/// Icon style for the card
enum RewardCardIconStyle {
  floating,  // Icon floats on card (missions)
  circular,  // Icon in circular background (achievements)
}

/// Unified reward card that works for both missions and achievements
class UnifiedRewardCard extends StatelessWidget {
  final String title;
  final String description;
  final int coinReward;
  final int? gemReward; // Optional gem reward
  final int progress;
  final int target;
  final RewardCardStatus status;
  final Widget icon; // Pre-built icon widget
  final RewardCardIconStyle iconStyle;
  final Gradient cardGradient;
  final Color shadowColor;
  final VoidCallback? onClaimReward;
  final bool isClaiming;
  final Size screenSize;
  /// Optional GlobalKey for coin reward icon (for animation position tracking)
  final GlobalKey? coinRewardIconKey;
  /// Optional GlobalKey for gem reward icon (for animation position tracking)
  final GlobalKey? gemRewardIconKey;

  const UnifiedRewardCard({
    super.key,
    required this.title,
    required this.description,
    required this.coinReward,
    this.gemReward,
    required this.progress,
    required this.target,
    required this.status,
    required this.icon,
    this.iconStyle = RewardCardIconStyle.floating,
    required this.cardGradient,
    required this.shadowColor,
    this.onClaimReward,
    this.isClaiming = false,
    required this.screenSize,
    this.coinRewardIconKey,
    this.gemRewardIconKey,
  });

  @override
  Widget build(BuildContext context) {
    // Minimum card height for consistency, but allow growth for longer text
    final minCardHeight = ResponsiveConfig.responsiveSize(
      screenSize.width / 3.2,
      screenSize,
      minScale: 0.95,
      maxScale: 1.2,
    ).clamp(120.0, 170.0);

    return Container(
      margin: EdgeInsets.only(
        bottom: ResponsiveConfig.responsivePadding(16.0, screenSize),
      ),
      constraints: BoxConstraints(
        minHeight: minCardHeight, // Minimum height for consistency
        // No max height - card can grow to accommodate text
      ),
      decoration: BoxDecoration(
        gradient: cardGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Subtle highlight effect at top - use Positioned.fill with ClipRect
            Positioned.fill(
              child: ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: 0.3, // Top 30% of card
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Main content - no Expanded, let it size naturally
            Padding(
              padding: ResponsiveConfig.responsiveEdgeInsets(12.0, screenSize),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Allow column to grow with content
                children: [
                  // Top row: icon, details, and rewards - more space for text
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon - responsive size with optional circular background
                      _buildIcon(minCardHeight, screenSize),

                      SizedBox(
                        width: ResponsiveConfig.responsivePadding(10.0, screenSize),
                      ),

                      // Title and description - now has more space, can grow
                      Expanded(
                        child: _buildDetails(context, screenSize),
                      ),

                      SizedBox(
                        width: ResponsiveConfig.responsivePadding(8.0, screenSize),
                      ),

                      // Rewards (coins + optional gems) - combined in one area
                      _buildRewards(context, screenSize),
                    ],
                  ),

                  SizedBox(
                    height: ResponsiveConfig.responsivePadding(8.0, screenSize),
                  ),

                  // Bottom row: progress (full width) or claim button (fills available space)
                  _buildBottomRow(context, screenSize),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build icon - always floating (no circular background)
  Widget _buildIcon(double cardHeight, Size screenSize) {
    final iconSize = ResponsiveConfig.responsiveSize(
      cardHeight * 0.38,
      screenSize,
      minScale: 0.9,
      maxScale: 1.1,
    ).clamp(48.0, 70.0);

    // Always use floating icon style (no circular background)
    return SizedBox(
      width: iconSize,
      height: iconSize,
      child: Center(
        child: SizedBox(
          width: iconSize * 0.85,
          height: iconSize * 0.85,
          child: icon,
        ),
      ),
    );
  }

  /// Build title and description
  /// Card grows dynamically to accommodate all text - no truncation
  Widget _buildDetails(BuildContext context, Size screenSize) {
    final titleFontSize = ResponsiveConfig.responsiveFontSize(
      18.0,
      screenSize,
      context,
    );
    final descFontSize = ResponsiveConfig.responsiveFontSize(
      13.0,
      screenSize,
      context,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // Use minimum space needed, but allow growth
      children: [
        // Title - no maxLines restriction, card will grow to show all text
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: titleFontSize,
            fontWeight: FontWeight.w900,
            height: 1.2,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.6),
                offset: const Offset(0, 1),
                blurRadius: 3,
              ),
            ],
          ),
          softWrap: true, // Enable text wrapping
        ),
        SizedBox(
          height: ResponsiveConfig.responsivePadding(4.0, screenSize),
        ),
        // Description - no maxLines restriction, card will grow to show all text
        Text(
          description,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: descFontSize,
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
          softWrap: true, // Enable text wrapping
        ),
      ],
    );
  }

  /// Build reward badges (coins + optional gems) - combined in one area
  Widget _buildRewards(BuildContext context, Size screenSize) {
    final horizontalPadding = ResponsiveConfig.responsivePadding(10.0, screenSize);
    final verticalPadding = ResponsiveConfig.responsivePadding(6.0, screenSize);
    final iconSize = ResponsiveConfig.responsiveIconSize(16.0, screenSize);
    final fontSize = ResponsiveConfig.responsiveFontSize(13.0, screenSize, context);
    final spacing = ResponsiveConfig.responsivePadding(6.0, screenSize);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFffd700), Color(0xFFffb300)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFff8f00).withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Coin reward - with optional key for position tracking
          coinRewardIconKey != null
              ? Container(
                  key: coinRewardIconKey,
                  child: Coin3DIcon(size: iconSize),
                )
              : Coin3DIcon(size: iconSize),
          SizedBox(width: spacing * 0.5),
          Text(
            '$coinReward',
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              height: 1.0,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),

          // Gem reward (if present) - in same container
          if (gemReward != null && gemReward! > 0) ...[
            SizedBox(width: spacing),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: spacing * 0.8,
                vertical: spacing * 0.3,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF9c27b0), Color(0xFF673ab7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Gem reward - with optional key for position tracking
                  gemRewardIconKey != null
                      ? Container(
                          key: gemRewardIconKey,
                          child: Gem3DIcon(size: iconSize * 0.9),
                        )
                      : Gem3DIcon(size: iconSize * 0.9),
                  SizedBox(width: spacing * 0.5),
                  Text(
                    '$gemReward',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          offset: const Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build bottom row: progress (full width for locked) or claim button (fills available space)
  Widget _buildBottomRow(BuildContext context, Size screenSize) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: ResponsiveConfig.responsivePadding(8.0, screenSize),
      ),
      child: _buildBottomContent(context, screenSize),
    );
  }

  /// Build bottom content based on status
  /// New layout: progress full width (locked), button/badge bottom right (completed/claimed)
  Widget _buildBottomContent(BuildContext context, Size screenSize) {
    switch (status) {
      case RewardCardStatus.claimed:
        // Show "DONE" badge in bottom right
        return Align(
          alignment: Alignment.centerRight,
          child: _buildDoneBadge(context, screenSize),
        );

      case RewardCardStatus.completed:
        // Show claim button - fills all available space
        return _buildClaimButton(context, screenSize);

      case RewardCardStatus.locked:
        // Show progress full width (informational, needs space)
        return _buildProgressIndicator(context, screenSize);
    }
  }

  /// Build "DONE" badge for claimed items
  Widget _buildDoneBadge(BuildContext context, Size screenSize) {
    final horizontalPadding = ResponsiveConfig.responsivePadding(12.0, screenSize);
    final verticalPadding = ResponsiveConfig.responsivePadding(6.0, screenSize);
    final iconSize = ResponsiveConfig.responsiveIconSize(12.0, screenSize);
    final fontSize = ResponsiveConfig.responsiveFontSize(9.0, screenSize, context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4caf50), Color(0xFF2e7d32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4caf50).withValues(alpha: 0.3),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.white,
            size: iconSize,
          ),
          SizedBox(
            width: ResponsiveConfig.responsivePadding(3.0, screenSize),
          ),
          Text(
            'DONE',
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Build claim button for completed items - beautiful programmatic button
  /// Follows Flappy Jet design system with gradient, shadows, and press gestures
  Widget _buildClaimButton(BuildContext context, Size screenSize) {
    // Reduced button height from 48px to 36px (25% smaller)
    final buttonHeight = ResponsiveConfig.responsiveButtonHeight(36.0, screenSize);
    final borderRadius = BorderRadius.circular(ResponsiveConfig.responsiveSize(10.0, screenSize));
    final fontSize = ResponsiveConfig.responsiveFontSize(14.0, screenSize, context);
    
    // Success gradient colors (green) - matches Flappy Jet button system
    final gradientColors = isClaiming
        ? [
            const Color(0xFF66BB6A).withValues(alpha: 0.6), // Lighter when claiming
            const Color(0xFF4CAF50).withValues(alpha: 0.6),
          ]
        : [
            const Color(0xFF66BB6A), // Lighter green top
            const Color(0xFF4CAF50), // Medium green bottom
          ];

    return SizedBox(
      width: double.infinity, // Fill all available width
      height: buttonHeight,
      child: _ButtonPressGesture(
        onTap: isClaiming ? null : onClaimReward,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: gradientColors,
            ),
            borderRadius: borderRadius,
            border: Border.all(
              color: Colors.white.withValues(alpha: isClaiming ? 0.2 : 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4CAF50).withValues(alpha: isClaiming ? 0.2 : 0.4),
                blurRadius: isClaiming ? 4 : 8,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: isClaiming ? 2 : 6,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Button text
              AnimatedOpacity(
                opacity: isClaiming ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: Text(
                  'CLAIM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        offset: const Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
              // Loading indicator when claiming
              if (isClaiming)
                SizedBox(
                  width: ResponsiveConfig.responsiveIconSize(20.0, screenSize),
                  height: ResponsiveConfig.responsiveIconSize(20.0, screenSize),
                  child: const CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build progress indicator for locked items
  Widget _buildProgressIndicator(BuildContext context, Size screenSize) {
    final horizontalPadding = ResponsiveConfig.responsivePadding(12.0, screenSize);
    final verticalPadding = ResponsiveConfig.responsivePadding(5.0, screenSize);
    final fontSize = ResponsiveConfig.responsiveFontSize(13.0, screenSize, context);
    final progressPercentage = (progress / target).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              'Progress: $progress/$target',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                height: 1.0,
              ),
            ),
          ),
          if (progressPercentage < 1.0) ...[
            SizedBox(
              width: ResponsiveConfig.responsivePadding(6.0, screenSize),
            ),
            Text(
              '${(progressPercentage * 100).toInt()}%',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: fontSize * 0.9,
                fontWeight: FontWeight.w500,
                height: 1.0,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Button with press gesture feedback (scale animation)
/// Provides tactile feedback when button is pressed
class _ButtonPressGesture extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _ButtonPressGesture({
    required this.child,
    this.onTap,
  });

  @override
  State<_ButtonPressGesture> createState() => _ButtonPressGestureState();
}

class _ButtonPressGestureState extends State<_ButtonPressGesture>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      HapticFeedback.lightImpact();
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    if (widget.onTap != null) {
      widget.onTap!();
    }
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}


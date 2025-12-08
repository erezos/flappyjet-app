import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'popups/base_popup.dart';
import 'buttons/modern_game_button.dart';
import 'buttons/button_styles.dart';
import 'gem_3d_icon.dart';
import 'coin_3d_icon.dart';
import 'rate_us_popup.dart';
import '../../core/debug_logger.dart';
import '../../game/systems/inventory_manager.dart';
import '../../game/systems/rate_us_manager.dart';
import '../../integrations/push_notification_manager.dart';

/// Notification Reward Popup
/// Displays when user opens app from push notification
/// Beautiful, animated popup with confetti for claiming coins/gems
class NotificationRewardPopup extends StatefulWidget {
  final String rewardType; // 'coins' or 'gems'
  final int rewardAmount;
  final int? eventId; // Backend notification event ID for tracking
  final VoidCallback? onClose;

  const NotificationRewardPopup({
    super.key,
    required this.rewardType,
    required this.rewardAmount,
    this.eventId,
    this.onClose,
  });

  @override
  State<NotificationRewardPopup> createState() => _NotificationRewardPopupState();
}

class _NotificationRewardPopupState extends State<NotificationRewardPopup>
    with SingleTickerProviderStateMixin {
  bool _isClaiming = false;
  bool _claimed = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
    
    // Pulse animation for reward icon
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _claimReward() async {
    if (_isClaiming || _claimed) return;
    
    setState(() {
      _isClaiming = true;
    });

    HapticFeedback.lightImpact();

    try {
      // Grant reward via InventoryManager
      final inventoryManager = InventoryManager();
      
      if (widget.rewardType == 'coins') {
        await inventoryManager.grantSoftCurrency(
          widget.rewardAmount,
          source: 'push_notification',
          sourceId: 'notification_reward',
        );
      } else if (widget.rewardType == 'gems') {
        await inventoryManager.grantGems(
          widget.rewardAmount,
          source: 'push_notification',
          sourceId: 'notification_reward',
        );
      }

      // Track claim on backend
      if (widget.eventId != null) {
        await PushNotificationManager().claimReward(widget.eventId!);
      }

      // Success!
      setState(() {
        _claimed = true;
        _isClaiming = false;
      });

      HapticFeedback.mediumImpact();

      // Close after short delay
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        Navigator.of(context).pop();
        widget.onClose?.call();
        
        // Show Rate Us popup if user hasn't rated yet
        await _showRateUsPopupIfNeeded();
      }
    } catch (e) {
      // Error handling
      setState(() {
        _isClaiming = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('Failed to claim reward: $e'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Show Rate Us popup if user hasn't rated yet
  /// Called after successfully claiming notification reward
  Future<void> _showRateUsPopupIfNeeded() async {
    try {
      final rateUsManager = RateUsManager();
      
      // Only show if user hasn't rated yet
      if (rateUsManager.hasRated) {
        return;
      }

      // Small delay before showing next popup
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => RateUsPopup(
          onRated: () {
            // User rated - great!
          },
          onDismissed: () {
            // User dismissed - that's okay
          },
        ),
      );
    } catch (e) {
      // Silent fail - don't interrupt user experience
      safePrint('Failed to show Rate Us popup: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    
    // Responsive sizing based on screen dimensions
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;
    final isNarrowScreen = screenWidth < 350;
    
    // Scale factors for responsive design
    final scaleFactor = isVerySmallScreen ? 0.85 : (isSmallScreen ? 0.9 : 1.0);
    final horizontalPadding = isNarrowScreen ? 16.0 : (isSmallScreen ? 20.0 : 32.0);
    final verticalPadding = isVerySmallScreen ? 40.0 : (isSmallScreen ? 50.0 : 80.0);
    
    // Responsive font sizes
    final titleFontSize = (24 * scaleFactor).clamp(20.0, 24.0);
    final subtitleFontSize = (14 * scaleFactor).clamp(12.0, 14.0);
    final rewardFontSize = (32 * scaleFactor).clamp(26.0, 32.0);
    final descriptionFontSize = (14 * scaleFactor).clamp(12.0, 14.0);
    
    // Responsive spacing
    final headerPadding = (24 * scaleFactor).clamp(16.0, 24.0);
    final contentPadding = (24 * scaleFactor).clamp(16.0, 24.0);
    final contentVerticalPadding = (32 * scaleFactor).clamp(20.0, 32.0);
    final iconSize = (120 * scaleFactor).clamp(90.0, 120.0);
    final gemIconSize = (64 * scaleFactor).clamp(48.0, 64.0); // Used for both coin and gem icons
    final spacingBetween = (24 * scaleFactor).clamp(16.0, 24.0);
    final spacingSmall = (12 * scaleFactor).clamp(8.0, 12.0);
    final buttonHeight = (54 * scaleFactor).clamp(48.0, 54.0);
    final buttonPadding = (24 * scaleFactor).clamp(16.0, 24.0);

    return BasePopup(
      padding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        constraints: BoxConstraints(
          maxWidth: isNarrowScreen ? screenWidth * 0.95 : 380,
          maxHeight: screenHeight * 0.75,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A1A2E).withOpacity(0.98),
              const Color(0xFF0F0F1E).withOpacity(0.98),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient background
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: headerPadding),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF4FC3F7).withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // "Welcome Back!" title
                      Text(
                        '🎮 WELCOME BACK!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8 * scaleFactor),
                      Text(
                        'Thanks for returning to FlappyJet!',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: subtitleFontSize,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Reward display
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: contentPadding,
                    vertical: contentVerticalPadding,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated reward icon
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _claimed ? 1.0 : _pulseAnimation.value,
                            child: Container(
                              width: iconSize,
                              height: iconSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    widget.rewardType == 'coins'
                                        ? const Color(0xFFFFD700).withOpacity(0.3)
                                        : const Color(0xFF4FC3F7).withOpacity(0.3),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                              child: Center(
                                child: widget.rewardType == 'coins'
                                    ? Coin3DIcon(size: gemIconSize)
                                    : Gem3DIcon(size: gemIconSize),
                              ),
                            ),
                          );
                        },
                      ),

                      SizedBox(height: spacingBetween),

                      // Reward amount
                      Text(
                        '+${widget.rewardAmount} ${widget.rewardType == 'coins' ? 'COINS' : 'GEMS'}',
                        style: TextStyle(
                          color: widget.rewardType == 'coins'
                              ? const Color(0xFFFFD700)
                              : const Color(0xFF4FC3F7),
                          fontSize: rewardFontSize,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: spacingSmall),

                      // Description
                      Text(
                        'Claim your reward for coming back!',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: descriptionFontSize,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Claim button
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    buttonPadding,
                    0,
                    buttonPadding,
                    buttonPadding,
                  ),
                  child: _claimed
                      ? ModernGameButton(
                          label: '✅ CLAIMED!',
                          onPressed: () {},
                          height: buttonHeight,
                          style: ModernButtonStyle.success,
                          enabled: false,
                        )
                      : ModernGameButton(
                          label: _isClaiming ? 'CLAIMING...' : 'CLAIM REWARD',
                          onPressed: _claimReward,
                          height: buttonHeight,
                          style: widget.rewardType == 'coins'
                              ? ModernButtonStyle.primary
                              : ModernButtonStyle.secondary,
                          enabled: !_isClaiming,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'popups/base_popup.dart';
import 'buttons/modern_game_button.dart';
import 'buttons/button_styles.dart';
import 'gem_3d_icon.dart';
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
    final isSmallScreen = screenSize.height < 700;

    return BasePopup(
      padding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 20 : 32,
          vertical: isSmallScreen ? 60 : 80,
        ),
        constraints: BoxConstraints(
          maxWidth: 380,
          maxHeight: screenSize.height * 0.7,
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with gradient background
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
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
                  children: [
                    // "Welcome Back!" title
                    const Text(
                      '🎮 WELCOME BACK!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Thanks for returning to FlappyJet!',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Reward display
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  children: [
                    // Animated reward icon
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _claimed ? 1.0 : _pulseAnimation.value,
                          child: Container(
                            width: 120,
                            height: 120,
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
                                  ? const Text(
                                      '🪙',
                                      style: TextStyle(fontSize: 64),
                                    )
                                  : const Gem3DIcon(size: 64),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Reward amount
                    Text(
                      '+${widget.rewardAmount} ${widget.rewardType == 'coins' ? 'COINS' : 'GEMS'}',
                      style: TextStyle(
                        color: widget.rewardType == 'coins'
                            ? const Color(0xFFFFD700)
                            : const Color(0xFF4FC3F7),
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    // Description
                    Text(
                      'Claim your reward for coming back!',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Claim button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: _claimed
                    ? ModernGameButton(
                        label: '✅ CLAIMED!',
                        onPressed: () {},
                        height: 54,
                        style: ModernButtonStyle.success,
                        enabled: false,
                      )
                    : ModernGameButton(
                        label: _isClaiming ? 'CLAIMING...' : 'CLAIM REWARD',
                        onPressed: _claimReward,
                        height: 54,
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
    );
  }
}


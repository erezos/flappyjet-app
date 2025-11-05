/// 💖 No Hearts Available Dialog - Heart regeneration, ads, and purchase options
/// Migrated to use BasePopup + ModernGameButton
library;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../game/systems/lives_manager.dart';
import '../../game/systems/inventory_manager.dart';
import '../../game/core/economy_config.dart';
import '../../game/systems/monetization_manager.dart';
import '../../game/systems/notification_permission_manager.dart';
import 'gem_3d_icon.dart';
import 'popups/base_popup.dart';
import 'buttons/modern_game_button.dart';
import 'buttons/button_styles.dart';

class NoHeartsDialog extends StatefulWidget {
  final VoidCallback onClose;
  final MonetizationManager monetization;

  const NoHeartsDialog({
    super.key,
    required this.onClose,
    required this.monetization,
  });

  @override
  State<NoHeartsDialog> createState() => _NoHeartsDialogState();
}

class _NoHeartsDialogState extends State<NoHeartsDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  int _secondsUntilNextHeart = 0;
  Stream<int>? _countdownStream;

  @override
  void initState() {
    super.initState();
    
    // Keep pulse animation (BasePopup handles entrance)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
    _setupCountdown();
    _maybeShowNotificationPermissionPopup();
  }

  void _setupCountdown() async {
    final livesManager = LivesManager();
    _secondsUntilNextHeart = await livesManager.getSecondsUntilNextRegen() ?? 0;
    
    if (mounted) {
      setState(() {
        _countdownStream = Stream.periodic(const Duration(seconds: 1), (count) {
          return count;
        }).asyncMap((count) async {
          final remaining = await livesManager.getSecondsUntilNextRegen() ?? 0;
          if (remaining <= 0) {
            // Heart regenerated, close dialog
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) widget.onClose();
            });
          }
          return remaining;
        }).take(3600); // Max 1 hour countdown
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// Smart notification permission popup trigger
  Future<void> _maybeShowNotificationPermissionPopup() async {
    // Wait a bit for the dialog to settle
    await Future.delayed(const Duration(milliseconds: 1000));
    
    if (!mounted) return;
    
    try {
      final permissionManager = NotificationPermissionManager();
      await permissionManager.showPermissionPopup(context);
    } catch (e) {
      // Silently handle errors to not disrupt user experience
      debugPrint('Error showing notification permission popup: $e');
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    
    // Calculate responsive sizing based on screen dimensions
    final isVerySmallScreen = screenHeight < 600;
    final isSmallScreen = screenHeight < 700;
    final isTablet = screenWidth > 600;
    final isLargeTablet = screenWidth > 900;
    
    // Responsive sizing
    final maxWidth = isLargeTablet ? 480.0 : isTablet ? 420.0 : (screenWidth * 0.9).clamp(280.0, 400.0);
    final padding = isVerySmallScreen ? 20.0 : (isSmallScreen ? 24.0 : 28.0);
    final spacing = isVerySmallScreen ? 16.0 : (isSmallScreen ? 20.0 : 24.0);
    
    return BasePopup(
      maxWidthPixels: maxWidth,
      padding: EdgeInsets.all(padding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Large broken heart icon at top
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Text(
                  '💔',
                  style: TextStyle(
                    fontSize: isVerySmallScreen ? 48 : (isSmallScreen ? 56 : 64),
                    decoration: TextDecoration.none,
                  ),
                ),
              );
            },
          ),
          
          SizedBox(height: spacing * 0.5),
          
          // Title text (no box)
          Text(
            'Out of Hearts!',
            style: TextStyle(
              fontSize: isVerySmallScreen ? 24 : (isSmallScreen ? 28 : 32),
              fontWeight: FontWeight.w900,
              color: const Color(0xFFFF6B6B),
              letterSpacing: 0.5,
              decoration: TextDecoration.none,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: spacing * 0.75),
          
          // Free heart countdown (no box, just text with icon)
          StreamBuilder<int>(
            stream: _countdownStream,
            initialData: _secondsUntilNextHeart,
            builder: (context, snapshot) {
              final seconds = snapshot.data ?? 0;
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 0.9 + (_pulseAnimation.value - 1.0) * 0.5,
                            child: Text(
                              '❤️',
                              style: TextStyle(
                                fontSize: isVerySmallScreen ? 20 : (isSmallScreen ? 24 : 28),
                                decoration: TextDecoration.none,
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(width: isVerySmallScreen ? 8 : 12),
                      Text(
                        'Free heart in',
                        style: TextStyle(
                          fontSize: isVerySmallScreen ? 14 : (isSmallScreen ? 16 : 18),
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isVerySmallScreen ? 6 : 8),
                  Text(
                    _formatTime(seconds),
                    style: TextStyle(
                      fontSize: isVerySmallScreen ? 32 : (isSmallScreen ? 36 : 42),
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF3B82F6),
                      letterSpacing: 2,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              );
            },
          ),
          
          // Divider with "OR"
          Padding(
            padding: EdgeInsets.symmetric(vertical: spacing * 0.75),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.2),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'OR',
                    style: TextStyle(
                      fontSize: isVerySmallScreen ? 12 : 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black54,
                      letterSpacing: 1.5,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Refill button with inline gem cost (no box)
          _buildRefillButton(isVerySmallScreen, isSmallScreen, isTablet),
          
          SizedBox(height: spacing * 0.5),
          
          // Back button
          ModernGameButton(
            label: 'BACK TO MENU',
            onPressed: widget.onClose,
            height: isVerySmallScreen ? 48 : (isSmallScreen ? 52 : 56),
            style: ModernButtonStyle.secondary,
          ),
        ],
      ),
    );
  }


  Widget _buildRefillButton(bool isVerySmallScreen, bool isSmallScreen, bool isTablet) {
    final inventory = InventoryManager();
    final livesManager = LivesManager();
    final economy = EconomyConfig();
    final currentHearts = livesManager.currentLives;
    final maxHearts = livesManager.maxLives;
    final isAtMax = currentHearts >= maxHearts;
    final hasEnoughGems = inventory.gems >= economy.fullHeartsRefillGemCost;
    final gemCost = economy.fullHeartsRefillGemCost;
    
    // Responsive sizing
    final fontSize = isVerySmallScreen ? 14.0 : (isSmallScreen ? 16.0 : 18.0);
    final iconSize = isVerySmallScreen ? 16.0 : (isSmallScreen ? 18.0 : 20.0);
    final buttonHeight = isVerySmallScreen ? 54.0 : (isSmallScreen ? 58.0 : 62.0);
    
    if (isAtMax) {
      // Hearts are full - show success state
      return Container(
        width: double.infinity,
        height: buttonHeight,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '✅',
                style: TextStyle(fontSize: iconSize + 4, decoration: TextDecoration.none),
              ),
              SizedBox(width: isVerySmallScreen ? 8 : 10),
              Text(
                'Hearts Full!',
                style: TextStyle(
                  fontSize: fontSize + 2,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    if (!hasEnoughGems) {
      // Not enough gems - show disabled state with current gems
      return Container(
        width: double.infinity,
        height: buttonHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.grey.shade400,
              Colors.grey.shade500,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Gem3DIcon(size: iconSize),
                  SizedBox(width: isVerySmallScreen ? 6 : 8),
                  Text(
                    'Need More Gems',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.3,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2),
              Text(
                'You have ${inventory.gems} / $gemCost gems',
                style: TextStyle(
                  fontSize: isVerySmallScreen ? 10 : 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.8),
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Enough gems - show actionable button with pulsing animation
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.98 + (_pulseAnimation.value - 1.0) * 0.04,
          child: Container(
            width: double.infinity,
            height: buttonHeight,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFFD700), // Gold
                  Color(0xFFFFA500), // Orange
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _purchaseHearts(),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '❤️ REFILL NOW - ',
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                          decoration: TextDecoration.none,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Gem3DIcon(size: iconSize),
                          );
                        },
                      ),
                      SizedBox(width: 6),
                      Text(
                        '$gemCost',
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                          decoration: TextDecoration.none,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _purchaseHearts() async {
    final inventory = InventoryManager();
    final livesManager = LivesManager();
    final economy = EconomyConfig();
    final price = economy.fullHeartsRefillGemCost;
    final currentHearts = livesManager.currentLives;
    final maxHearts = livesManager.maxLives;
    final heartsToRefill = maxHearts - currentHearts;
    
    // Check if player has enough gems
    if (inventory.gems < price) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('💎 Need $price gems to refill all hearts'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    
    // Purchase immediately without confirmation (user already sees the cost on the button)
    try {
      // Spend gems
      final success = await inventory.spendGems(price);
      if (success) {
        // Refill all hearts
        await livesManager.refillToMax();
        
        if (mounted) {
          // Close the dialog
          Navigator.of(context).pop();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('💖 All hearts refilled! (+$heartsToRefill heart${heartsToRefill != 1 ? 's' : ''})'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('💎 Not enough gems!'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
/// 💖 No Hearts Available Dialog - Heart regeneration, ads, and purchase options
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
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  
  int _secondsUntilNextHeart = 0;
  Stream<int>? _countdownStream;

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _startAnimations();
    _setupCountdown();
    _maybeShowNotificationPermissionPopup();
  }

  void _startAnimations() {
    _slideController.forward();
    _pulseController.repeat(reverse: true);
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
    _slideController.dispose();
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
    final isNarrowScreen = screenWidth < 400;
    
    return Container(
      decoration: const BoxDecoration(
        // Store background - same as store page
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF4FC3F7), // Light blue from store
            Color(0xFF29B6F6), // Darker blue from store
          ],
        ),
      ),
      child: Container(
        color: Colors.black.withValues(alpha: 0.4), // Slightly darker overlay for better glassmorphism contrast
        child: Center(
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: isNarrowScreen ? 12 : 16,
                vertical: isVerySmallScreen ? 8 : (isSmallScreen ? 16 : 24),
              ),
              constraints: BoxConstraints(
                maxHeight: screenHeight * 0.95, // Use 95% of screen height
                maxWidth: isNarrowScreen ? screenWidth * 0.95 : 380,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    padding: EdgeInsets.all(isVerySmallScreen ? 12 : (isSmallScreen ? 16 : 20)),
                    decoration: BoxDecoration(
                      // Glassmorphism effect - semi-transparent with subtle gradient
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.25), // More transparent
                          Colors.white.withValues(alpha: 0.15), // Even more transparent
                          Colors.white.withValues(alpha: 0.1),  // Most transparent
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3), // Subtle white border
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.6),
                          blurRadius: 6,
                          offset: const Offset(0, -2),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Compact header
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isVerySmallScreen ? 8 : 12, 
                        vertical: isVerySmallScreen ? 4 : 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF6B6B).withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        '💔 OUT OF HEARTS!',
                        style: TextStyle(
                          fontSize: isVerySmallScreen ? 16 : (isSmallScreen ? 18 : 20),
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.8,
                          decoration: TextDecoration.none,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    
                    SizedBox(height: isVerySmallScreen ? 12 : 16),
                    
                    // Countdown with exciting design
                    StreamBuilder<int>(
                      stream: _countdownStream,
                      initialData: _secondsUntilNextHeart,
                      builder: (context, snapshot) {
                        final seconds = snapshot.data ?? 0;
                        return Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(isVerySmallScreen ? 10 : (isSmallScreen ? 12 : 16)),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnimatedBuilder(
                                    animation: _pulseAnimation,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale: _pulseAnimation.value,
                                        child: Text(
                                          '❤️',
                                          style: TextStyle(
                                            fontSize: isVerySmallScreen ? 16 : (isSmallScreen ? 18 : 20),
                                            decoration: TextDecoration.none,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'FREE HEART IN',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isVerySmallScreen ? 10 : (isSmallScreen ? 12 : 14),
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: isVerySmallScreen ? 4 : 6),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isVerySmallScreen ? 12 : 16, 
                                  vertical: isVerySmallScreen ? 4 : 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _formatTime(seconds),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isVerySmallScreen ? 20 : (isSmallScreen ? 24 : 28),
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    
                    SizedBox(height: isVerySmallScreen ? 8 : 12),
                    
                    // Compact purchase card
                    _buildCompactPurchaseCard(isVerySmallScreen, isSmallScreen),
                    
                    SizedBox(height: isVerySmallScreen ? 8 : 10),
                    
                    // Compact close button
                    _buildCompactActionButton(
                      'BACK TO MENU',
                      Icons.home_rounded,
                      const LinearGradient(
                        colors: [Color(0xFF9CA3AF), Color(0xFF6B7280)],
                      ),
                      widget.onClose,
                      isVerySmallScreen,
                      isSmallScreen,
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


  Widget _buildCompactPurchaseCard(bool isVerySmallScreen, bool isSmallScreen) {
    final inventory = InventoryManager();
    final livesManager = LivesManager();
    final economy = EconomyConfig();
    final currentHearts = livesManager.currentLives;
    final maxHearts = livesManager.maxLives;
    final isAtMax = currentHearts >= maxHearts;
    final hasEnoughGems = inventory.gems >= economy.fullHeartsRefillGemCost;
    
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: (!isAtMax && hasEnoughGems) ? (0.98 + (_pulseAnimation.value - 1.0) * 0.02) : 1.0,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isAtMax
                    ? [const Color(0xFFE5E7EB), const Color(0xFFD1D5DB)] // Gray for full hearts
                    : !hasEnoughGems
                        ? [const Color(0xFFEF4444), const Color(0xFFDC2626)] // Red for insufficient gems
                        : [
                            const Color(0xFF10B981), // Emerald green
                            const Color(0xFF059669), // Darker emerald
                            const Color(0xFF047857), // Even darker
                          ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isAtMax
                    ? const Color(0xFFD1D5DB)
                    : !hasEnoughGems
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF34D399),
                width: 2,
              ),
              boxShadow: [
                if (!isAtMax && hasEnoughGems) ...[
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                    spreadRadius: 1,
                  ),
                ] else ...[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: (isAtMax || !hasEnoughGems) ? null : () => _purchaseHearts(),
                child: Padding(
                  padding: EdgeInsets.all(isVerySmallScreen ? 12 : (isSmallScreen ? 14 : 16)),
                  child: Column(
                    children: [
                      // Compact header
                      if (!isAtMax) ...[
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isVerySmallScreen ? 6 : 8, 
                            vertical: isVerySmallScreen ? 2 : 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '⚡ INSTANT REFILL ⚡',
                            style: TextStyle(
                              fontSize: isVerySmallScreen ? 9 : (isSmallScreen ? 10 : 11),
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        SizedBox(height: isVerySmallScreen ? 6 : 8),
                      ],
                      
                      // Compact hearts icon
                      Container(
                        width: isVerySmallScreen ? 36 : (isSmallScreen ? 42 : 48),
                        height: isVerySmallScreen ? 36 : (isSmallScreen ? 42 : 48),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            isAtMax ? '✅' : hasEnoughGems ? '💖' : '💎',
                            style: TextStyle(fontSize: isVerySmallScreen ? 20 : (isSmallScreen ? 24 : 28)),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: isVerySmallScreen ? 6 : 8),
                      
                      // Compact title
                      Text(
                        isAtMax 
                            ? '❤️ HEARTS FULL!' 
                            : hasEnoughGems 
                                ? '🚀 GET ALL HEARTS!' 
                                : '💎 NEED MORE GEMS!',
                        style: TextStyle(
                          fontSize: isVerySmallScreen ? 12 : (isSmallScreen ? 14 : 16),
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      SizedBox(height: isVerySmallScreen ? 2 : 4),
                      
                      // Compact subtitle
                      Text(
                        isAtMax 
                            ? 'You\'re ready to play!' 
                            : hasEnoughGems 
                                ? 'Refill all hearts instantly!' 
                                : 'Visit the store to get gems',
                        style: TextStyle(
                          fontSize: isVerySmallScreen ? 9 : (isSmallScreen ? 10 : 11),
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.9),
                          letterSpacing: 0.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      SizedBox(height: isVerySmallScreen ? 8 : 10),
                      
                      // Compact price section with store-style gem icon
                      if (!isAtMax) ...[
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isVerySmallScreen ? 10 : (isSmallScreen ? 12 : 14), 
                            vertical: isVerySmallScreen ? 6 : (isSmallScreen ? 7 : 8),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: hasEnoughGems ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Store-style Gem3DIcon (no color tinting like in store)
                              AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: hasEnoughGems ? _pulseAnimation.value : 1.0,
                                    child: Gem3DIcon(
                                      size: isVerySmallScreen ? 14 : (isSmallScreen ? 16 : 18),
                                      // No color tinting - use natural gem colors like in store
                                    ),
                                  );
                                },
                              ),
                              SizedBox(width: isVerySmallScreen ? 4 : 6),
                              Text(
                                '${economy.fullHeartsRefillGemCost}',
                                style: TextStyle(
                                  fontSize: isVerySmallScreen ? 14 : (isSmallScreen ? 16 : 18),
                                  fontWeight: FontWeight.w900,
                                  color: hasEnoughGems ? Colors.white : Colors.white.withValues(alpha: 0.7),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(width: isVerySmallScreen ? 3 : 4),
                              Text(
                                'GEMS',
                                style: TextStyle(
                                  fontSize: isVerySmallScreen ? 9 : (isSmallScreen ? 10 : 11),
                                  fontWeight: FontWeight.w700,
                                  color: hasEnoughGems ? Colors.white : Colors.white.withValues(alpha: 0.7),
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        if (!hasEnoughGems) ...[
                          SizedBox(height: isVerySmallScreen ? 4 : 6),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isVerySmallScreen ? 8 : 10, 
                              vertical: isVerySmallScreen ? 3 : 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'You have ${inventory.gems} gems',
                              style: TextStyle(
                                fontSize: isVerySmallScreen ? 8 : (isSmallScreen ? 9 : 10),
                                color: Colors.white.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
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

  Widget _buildCompactActionButton(
    String text,
    IconData icon,
    Gradient gradient,
    VoidCallback onTap,
    bool isVerySmallScreen,
    bool isSmallScreen,
  ) {
    return Container(
      width: double.infinity,
      height: isVerySmallScreen ? 36 : (isSmallScreen ? 40 : 44),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon, 
                color: Colors.white, 
                size: isVerySmallScreen ? 14 : (isSmallScreen ? 16 : 18),
              ),
              SizedBox(width: isVerySmallScreen ? 4 : 6),
              Text(
                text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isVerySmallScreen ? 11 : (isSmallScreen ? 12 : 14),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
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
    
    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Full Hearts Refill?'),
        content: Text(
          'Spend $price gems to fill all $heartsToRefill missing heart${heartsToRefill != 1 ? 's' : ''}?\n\nThis will give you $maxHearts hearts total.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false), 
            child: const Text('Cancel')
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Buy Hearts')
          ),
        ],
      ),
    );
    
    if (confirm == true) {
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
}
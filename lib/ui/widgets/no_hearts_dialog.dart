/// 💖 No Hearts Available Dialog - Heart regeneration, ads, and purchase options
library;
import 'package:flutter/material.dart';
import 'gem_3d_icon.dart';
import 'package:flutter/services.dart';
import '../../game/systems/lives_manager.dart';
import '../../game/systems/inventory_manager.dart';
import '../../game/core/economy_config.dart';
import '../../game/systems/monetization_manager.dart';

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

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      child: Center(
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF8B0000), Color(0xFFDC143C)], // Dark red to crimson
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Heart Icon with pulse animation
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: const Icon(
                        Icons.favorite_border,
                        color: Colors.white,
                        size: 64,
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Title
                const Text(
                  'OUT OF HEARTS!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                // Subtitle
                const Text(
                  'You need hearts to play',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Countdown
                StreamBuilder<int>(
                  stream: _countdownStream,
                  initialData: _secondsUntilNextHeart,
                  builder: (context, snapshot) {
                    final seconds = snapshot.data ?? 0;
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF2196F3).withValues(alpha: 0.8),
                            const Color(0xFF1976D2).withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2196F3).withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Pulsing heart icon
                              AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _pulseAnimation.value,
                                    child: Icon(
                                      Icons.favorite,
                                      size: 24,
                                      color: Colors.red.shade300,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'NEXT HEART IN',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _formatTime(seconds),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Options
                const Text(
                  'GET HEARTS NOW',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Watch Ad Button
                _buildOptionButton(
                  'WATCH AD',
                  '+1 HEART',
                  Icons.play_circle_fill,
                  const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ),
                  () => _watchAdForHeart(),
                ),
                
                const SizedBox(height: 12),
                
                // Purchase Hearts Button
                _buildOptionButton(
                  'BUY HEARTS',
                  'FULL REFILL',
                  Icons.shopping_cart,
                  const LinearGradient(
                    colors: [Color(0xFF32CD32), Color(0xFF228B22)],
                  ),
                  () => _purchaseHearts(),
                ),
                
                const SizedBox(height: 24),
                
                // Close Button
                _buildActionButton(
                  'BACK TO MENU',
                  Icons.home,
                  const LinearGradient(
                    colors: [Color(0xFF4A4A4A), Color(0xFF2A2A2A)],
                  ),
                  widget.onClose,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionButton(
    String title,
    String subtitle,
    IconData icon,
    Gradient gradient,
    VoidCallback onTap,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            HapticFeedback.mediumImpact();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white70,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String text,
    IconData icon,
    Gradient gradient,
    VoidCallback onTap,
  ) {
    return Container(
      width: double.infinity,
      height: 50,
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
              Icon(icon, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _watchAdForHeart() async {
    try {
      await widget.monetization.showRewardedAdForExtraLife(
        onReward: () async {
          // Grant 1 heart
          await LivesManager().addLife(1);
          
          // Show success feedback
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❤️ +1 Heart! You can now play!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
          
          // Close dialog after short delay
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) widget.onClose();
          });
        },
      );
    } catch (e) {
      debugPrint('⚠️ Error showing rewarded ad: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ad not available right now. Try again later.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
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

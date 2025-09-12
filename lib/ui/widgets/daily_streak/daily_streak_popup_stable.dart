import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../game/systems/daily_streak_manager.dart';
import '../../../game/core/jet_skins.dart';
import '../gem_3d_icon.dart';

/// Stable Daily Streak Popup - Pure Flutter UI without complex animations
class DailyStreakPopupStable extends StatefulWidget {
  final DailyStreakManager streakManager;
  final VoidCallback? onClaim;
  final VoidCallback? onClose;
  final VoidCallback? onRestore;

  const DailyStreakPopupStable({
    super.key,
    required this.streakManager,
    this.onClaim,
    this.onClose,
    this.onRestore,
  });

  @override
  State<DailyStreakPopupStable> createState() => _DailyStreakPopupStableState();
}

class _DailyStreakPopupStableState extends State<DailyStreakPopupStable>
    with SingleTickerProviderStateMixin {
  bool _isClaiming = false;
  late DailyStreakReward _currentReward;
  
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    // Capture the current reward at popup creation to prevent changes after claim
    _currentReward = widget.streakManager.todayReward;
    _initializeAnimations();
  }
  
  void _initializeAnimations() {
    // Only slide animation - no complex animations
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));
    
    // Start animation safely
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _slideController.forward();
      }
    });
  }
  
  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.7),
      body: SlideTransition(
        position: _slideAnimation,
        child: Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: math.min(screenWidth * 0.95, 800),
              maxHeight: screenHeight * 0.75, // Slightly smaller to give more space to rewards
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Background sparkles (static)
                ..._buildStaticSparkles(),
                
                // Main banner
                _buildMainBanner(context),
                
                // Static jet on the left
                _buildStaticJet(),
                
                // Close button
                _buildCloseButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildMainBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFD700), // Gold
            Color(0xFFFFC132), // Lighter gold
            Color(0xFFFFB000), // Darker gold
            Color(0xFFE09200), // Bronze
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF9B5A00),
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFFFFE06A).withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          _buildTitle(),
          
          const SizedBox(height: 20),
          
          // Reward slots
          _buildRewardSlots(),
          
          const SizedBox(height: 20),
          
          // Collect button
          _buildCollectButton(),
        ],
      ),
    );
  }
  
  Widget _buildTitle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFFE06A).withValues(alpha: 0.3),
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'DAILY STREAK BONUS',
        style: TextStyle(
          fontSize: 18, // Smaller title to give more space to rewards
          fontWeight: FontWeight.w900,
          color: const Color(0xFF283C66),
          shadows: [
            Shadow(
              color: Colors.white.withValues(alpha: 0.8),
              offset: const Offset(0, 1),
              blurRadius: 2,
            ),
            const Shadow(
              color: Color(0xFF9B5A00),
              offset: Offset(2, 2),
              blurRadius: 4,
            ),
          ],
          letterSpacing: 1.5,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
  
  Widget _buildRewardSlots() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final slotSize = math.min(70.0, (availableWidth - 28) / 7); // Optimize for space
        
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(7, (index) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 2.0),
                child: _buildRewardSlot(index, slotSize),
              );
            }),
          ),
        );
      },
    );
  }
  
  Widget _buildRewardSlot(int dayIndex, double slotSize) {
    final rewards = widget.streakManager.currentRewards;
    final reward = rewards[dayIndex];
    final isToday = dayIndex == widget.streakManager.currentStreak;
    final isClaimed = dayIndex < widget.streakManager.currentStreak;
    final isLocked = dayIndex > widget.streakManager.currentStreak;
    
    return Container(
      width: slotSize,
      height: slotSize * 1.4, // Even taller for better proportion
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isToday
              ? [
                  const Color(0xFFFFD700),
                  const Color(0xFFFFC132),
                  const Color(0xFFFFB000),
                ]
              : isClaimed
                  ? [
                      const Color(0xFF27AE60).withValues(alpha: 0.9),
                      const Color(0xFF2ECC71).withValues(alpha: 0.9),
                    ]
                  : isLocked
                      ? [
                          const Color(0xFF95A5A6),
                          const Color(0xFF7F8C8D),
                        ]
                      : [
                          const Color(0xFF1FB7C4),
                          const Color(0xFF0EA0B0),
                        ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isToday
              ? const Color(0xFFFFE06A)
              : isClaimed
                  ? const Color(0xFF27AE60)
                  : isLocked
                      ? const Color(0xFF7F8C8D)
                      : const Color(0xFF0EA0B0),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: (isToday
                    ? const Color(0xFFFFD700)
                    : isClaimed
                        ? const Color(0xFF27AE60)
                        : const Color(0xFF1FB7C4))
                .withValues(alpha: isToday ? 0.8 : 0.4),
            blurRadius: isToday ? 16 : 6,
            spreadRadius: isToday ? 4 : 1,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Main content - optimized layout
          Padding(
            padding: EdgeInsets.all(slotSize * 0.08),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Day number at top (smaller)
                Text(
                  'Day ${dayIndex + 1}',
                  style: TextStyle(
                    fontSize: math.max(8.0, slotSize * 0.12),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.7),
                        offset: const Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                
                // Reward icon (MUCH bigger - this is the star!)
                Expanded(
                  flex: 3,
                  child: Center(
                    child: _buildRewardIcon(reward, isClaimed, isLocked, slotSize),
                  ),
                ),
                
                // Amount text (bigger and bolder)
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      reward.displayText,
                      style: TextStyle(
                        fontSize: math.max(9.0, slotSize * 0.14),
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.8),
                            offset: const Offset(1, 1),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Status overlay (smaller and better positioned)
          if (isClaimed)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                width: slotSize * 0.25,
                height: slotSize * 0.25,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 4,
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: slotSize * 0.15,
                ),
              ),
            ),
          if (isLocked)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                width: slotSize * 0.25,
                height: slotSize * 0.25,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 4,
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.lock,
                  color: Colors.white70,
                  size: slotSize * 0.15,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildRewardIcon(DailyStreakReward reward, bool isClaimed, bool isLocked, double slotSize) {
    final iconSize = math.max(32.0, slotSize * 0.6); // HUGE icons - rewards are the star!
    
    switch (reward.type) {
      case DailyStreakRewardType.coins:
        // Use coin icon like in store
        return Icon(
          Icons.monetization_on,
          size: iconSize,
          color: isLocked 
              ? const Color(0xFFFFD700).withValues(alpha: 0.4)
              : isClaimed 
                  ? const Color(0xFFFFD700).withValues(alpha: 0.7)
                  : const Color(0xFFFFD700),
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.5),
              offset: const Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        );
        
      case DailyStreakRewardType.gems:
        // Use store gem icon with opacity wrapper
        return Opacity(
          opacity: isLocked 
              ? 0.4
              : isClaimed 
                  ? 0.7
                  : 1.0,
          child: Gem3DIcon(
            size: iconSize,
          ),
        );
        
      case DailyStreakRewardType.heart:
      case DailyStreakRewardType.heartBooster:
        return Icon(
          Icons.favorite,
          size: iconSize,
          color: isLocked 
              ? const Color(0xFFE74C3C).withValues(alpha: 0.4)
              : isClaimed 
                  ? const Color(0xFFE74C3C).withValues(alpha: 0.7)
                  : const Color(0xFFE74C3C),
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.5),
              offset: const Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        );
        
      case DailyStreakRewardType.jetSkin:
        // Show actual jet preview instead of generic plane icon
        if (reward.jetSkinId != null) {
          final jetSkin = JetSkinCatalog.getSkinById(reward.jetSkinId!);
          if (jetSkin != null) {
            return Opacity(
              opacity: isLocked 
                  ? 0.4
                  : isClaimed 
                      ? 0.7
                      : 1.0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      offset: const Offset(1, 1),
                      blurRadius: 3,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/${jetSkin.assetPath}',
                    width: iconSize,
                    height: iconSize,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to plane icon if image fails to load
                      return Icon(
                        Icons.flight,
                        size: iconSize,
                        color: const Color(0xFF9B59B6),
                      );
                    },
                  ),
                ),
              ),
            );
          }
        }
        // Fallback to generic plane icon
        return Icon(
          Icons.flight,
          size: iconSize,
          color: isLocked 
              ? const Color(0xFF9B59B6).withValues(alpha: 0.4)
              : isClaimed 
                  ? const Color(0xFF9B59B6).withValues(alpha: 0.7)
                  : const Color(0xFF9B59B6),
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.5),
              offset: const Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        );
        
      case DailyStreakRewardType.mysteryBox:
        return Opacity(
          opacity: isLocked 
              ? 0.4
              : isClaimed 
                  ? 0.7
                  : 1.0,
          child: Image.asset(
            'assets/images/icons/gift.png',
            width: iconSize,
            height: iconSize,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to icon if asset fails
              return Icon(
                Icons.card_giftcard,
                size: iconSize,
                color: const Color(0xFFE67E22),
              );
            },
          ),
        );
    }
  }
  
  Widget _buildStaticJet() {
    return Positioned(
      left: -40,
      top: 20,
      child: Container(
        width: 80,
        height: 40,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4A90E2),
              Color(0xFF357ABD),
              Color(0xFF2E5984),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A90E2).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Jet body
            const Positioned(
              left: 10,
              top: 8,
              child: Icon(
                Icons.flight,
                color: Colors.white,
                size: 24,
              ),
            ),
            // Engine glow
            Positioned(
              right: 5,
              top: 12,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFF00BCD4),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00BCD4).withValues(alpha: 0.6),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  List<Widget> _buildStaticSparkles() {
    return List.generate(8, (index) {
      final random = math.Random(index);
      final left = random.nextDouble() * 400;
      final top = random.nextDouble() * 200;
      
      return Positioned(
        left: left,
        top: top,
        child: Icon(
          [Icons.star, Icons.diamond, Icons.auto_awesome][index % 3],
          color: [
            const Color(0xFFFFD700),
            const Color(0xFF4A90E2),
            const Color(0xFFE74C3C),
            const Color(0xFF27AE60),
          ][index % 4],
          size: 16 + (index % 3) * 4,
        ),
      );
    });
  }
  
  Widget _buildCollectButton() {
    if (widget.streakManager.currentState != DailyStreakState.available) {
      return const SizedBox.shrink();
    }
    
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: widget.streakManager.currentState == DailyStreakState.claimed
              ? [
                  const Color(0xFF27AE60),
                  const Color(0xFF2ECC71),
                  const Color(0xFF229954),
                ]
              : _isClaiming
                  ? [
                      const Color(0xFF95A5A6),
                      const Color(0xFF7F8C8D),
                      const Color(0xFF6C7B7F),
                    ]
                  : [
                      const Color(0xFF4A90E2),
                      const Color(0xFF357ABD),
                      const Color(0xFF2E5984),
                    ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: (widget.streakManager.currentState == DailyStreakState.claimed
                    ? const Color(0xFF27AE60)
                    : _isClaiming
                        ? const Color(0xFF95A5A6)
                        : const Color(0xFF4A90E2))
                .withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: widget.streakManager.currentState == DailyStreakState.claimed || _isClaiming
              ? null
              : () async {
                  if (_isClaiming) return;
                  
                  setState(() {
                    _isClaiming = true;
                  });
                  
                  HapticFeedback.lightImpact();
                  final success = await widget.streakManager.claimTodayReward();
                  
                  if (mounted) {
                    setState(() {
                      _isClaiming = false;
                    });
                    
                    if (success) {
                      // Let the parent handle the claim and navigation
                      widget.onClaim?.call();
                    }
                  }
                },
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isClaiming) ...[
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'CLAIMING...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ] else ...[
                  Icon(
                    widget.streakManager.currentState == DailyStreakState.claimed
                        ? Icons.check_circle
                        : Icons.card_giftcard,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.streakManager.currentState == DailyStreakState.claimed 
                        ? 'CLAIMED'
                        : 'COLLECT ${_currentReward.displayText}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildCloseButton(BuildContext context) {
    return Positioned(
      top: -10,
      right: -10,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              HapticFeedback.lightImpact();
              // Let the parent handle navigation
              widget.onClose?.call();
            },
            child: const Icon(
              Icons.close,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

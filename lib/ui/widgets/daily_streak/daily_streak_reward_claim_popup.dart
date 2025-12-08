/// 🎁 Beautiful Daily Streak Reward Claim Popup - FlappyJet Design Language
/// Premium UI/UX showing reward details with animations and explanations
/// Migrated to use BasePopup + ModernGameButton + Gem3DIcon
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../game/systems/daily_streak_manager.dart';
import '../../../game/core/jet_skins.dart';
import '../../../game/systems/inventory_manager.dart';
import '../popups/base_popup.dart';
import '../buttons/modern_game_button.dart';
import '../buttons/button_styles.dart';
import '../gem_3d_icon.dart';
import '../coin_3d_icon.dart';
import '../../utils/responsive_config.dart';

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
    with SingleTickerProviderStateMixin {
  late AnimationController _rewardController;
  late Animation<double> _rewardAnimation;

  @override
  void initState() {
    super.initState();
    
    // Only keep reward bounce animation (BasePopup handles entrance)
    _rewardController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _rewardAnimation = CurvedAnimation(
      parent: _rewardController,
      curve: Curves.bounceOut,
    );

    // Start reward animation after a delay
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _rewardController.forward();
    });

    // Haptic feedback
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _rewardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isHeartBooster = widget.reward.type == DailyStreakRewardType.heartBooster;
    
    // Calculate scale factor for proportional sizing
    final scaleFactor = ResponsiveConfig.getScaleFactor(screenSize);

    // Calculate close button overflow space (half of button size)
    final closeButtonOverflow = (44.0 * scaleFactor).clamp(40.0, 56.0) / 2 + 4;

    return BasePopup(
      maxWidthPixels: ResponsiveConfig.responsivePopupWidth(
        screenSize,
        percent: 0.88,
        minWidth: 320.0,
        maxWidth: 480.0,
      ),
      padding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      // Add margin to BasePopup so the X button has room to overflow without being clipped
      child: Padding(
        padding: EdgeInsets.only(
          top: closeButtonOverflow,
          right: closeButtonOverflow,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Main popup content
            Container(
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
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            // Use IntrinsicHeight to let content determine size naturally
            child: IntrinsicHeight(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with reward icon - proportionally sized
                  _buildHeader(screenSize, scaleFactor),
                  
                  // Title - Compact
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.0 * scaleFactor,
                      vertical: 12.0 * scaleFactor,
                    ),
                    child: _buildTitle(context, screenSize, scaleFactor),
                  ),
                  
                  // Reward display - Prominent and centered
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.0 * scaleFactor,
                      vertical: 8.0 * scaleFactor,
                    ),
                    child: _buildRewardDisplay(context, screenSize, scaleFactor),
                  ),
                  
                  // Explanation text
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.0 * scaleFactor,
                      vertical: 12.0 * scaleFactor,
                    ),
                    child: _buildExplanation(context, screenSize, isHeartBooster, scaleFactor),
                  ),
                  
                  // Action button - Fixed at bottom
                  Padding(
                    padding: EdgeInsets.only(
                      left: 20.0 * scaleFactor,
                      right: 20.0 * scaleFactor,
                      top: 8.0 * scaleFactor,
                      bottom: 20.0 * scaleFactor,
                    ),
                    child: _buildActionButton(context, screenSize, scaleFactor),
                  ),
                ],
              ),
            ),
          ),
          
            // ✅ X BUTTON: Positioned on popup frame (outside container, on border)
            // With the outer Padding, the button stays inside the padded area
            Positioned(
              top: -(44.0 * scaleFactor).clamp(40.0, 56.0) / 2,
              right: -(44.0 * scaleFactor).clamp(40.0, 56.0) / 2,
              child: _buildCloseButton(screenSize, scaleFactor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Size screenSize, double scaleFactor) {
    // Scale header icon proportionally - larger for visual impact
    final headerIconSize = (48.0 * scaleFactor).clamp(40.0, 64.0);
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 0.0,
        vertical: 16.0 * scaleFactor,
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
      child: _buildHeaderIcon(headerIconSize),
    );
  }

  /// Build appropriate header icon based on reward type
  Widget _buildHeaderIcon(double iconSize) {
    switch (widget.reward.type) {
      case DailyStreakRewardType.coins:
        // ✅ Use our consistent Coin3DIcon for coins
        return Center(child: Coin3DIcon(size: iconSize * 1.2));
      
      case DailyStreakRewardType.gems:
        // Use our custom Gem3DIcon for gems
        return Center(child: Gem3DIcon(size: iconSize * 1.2));
      
      case DailyStreakRewardType.jetSkin:
        // Show actual jet image for jet skins
        if (widget.reward.jetSkinId != null) {
          return _buildJetSkinHeaderIcon(iconSize);
        }
        return Icon(_getRewardIcon(), size: iconSize, color: Colors.white);
      
      default:
        // Default icon for other reward types
        return Icon(_getRewardIcon(), size: iconSize, color: Colors.white);
    }
  }
  
  /// ✅ Build close button (X) positioned on popup frame
  /// Uses proportional scaling for consistent sizing across all devices
  Widget _buildCloseButton(Size screenSize, double scaleFactor) {
    // Responsive button size (minimum 44x44 for touch target accessibility)
    final buttonSize = (44.0 * scaleFactor).clamp(40.0, 56.0);
    
    // Responsive icon size
    final iconSize = (24.0 * scaleFactor).clamp(20.0, 30.0);
    
    // Responsive border width
    final borderWidth = (2.0 * scaleFactor).clamp(1.5, 3.0);
    
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        widget.onClose?.call();
      },
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.7),
          border: Border.all(
            color: Colors.white.withOpacity(0.9),
            width: borderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 12.0 * scaleFactor,
              spreadRadius: 2.0 * scaleFactor,
              offset: Offset(0, 2.0 * scaleFactor),
            ),
          ],
        ),
        child: Icon(
          Icons.close_rounded,
          size: iconSize,
          color: Colors.white,
        ),
      ),
    );
  }

  /// Build jet skin icon for header with larger size
  Widget _buildJetSkinHeaderIcon(double size) {
    // Handle progressive jet system (Day 6 reward)
    String? jetIdToDisplay = widget.reward.jetSkinId;
    if (widget.reward.jetSkinId == 'progressive_jet') {
      // ✅ FIX: Get the actual jet ID that was unlocked from DailyStreakManager
      final streakManager = DailyStreakManager();
      final actualUnlockedJet = streakManager.lastUnlockedJetId;
      
      if (actualUnlockedJet != null) {
        // Use the actual jet that was unlocked
        jetIdToDisplay = actualUnlockedJet;
      } else {
        // Fallback: Check inventory to find which jet was unlocked
        const jetProgression = [
          'cobra_strike',
          'storm_chaser',
          'disco_fever',
          'ruby_phantom',
          'sugar_storm',
        ];
        
        final inventory = InventoryManager();
        // Find first jet in progression that IS owned
        for (final jetId in jetProgression) {
          if (inventory.isOwned(jetId)) {
            jetIdToDisplay = jetId;
            break;
          }
        }
        
        // Final fallback
        if (jetIdToDisplay == 'progressive_jet' || jetIdToDisplay == null) {
          jetIdToDisplay = jetProgression.first;
        }
      }
    }
    
    // Find the jet skin
    final jetSkin = JetSkinCatalog.getAllSkins().firstWhere(
      (skin) => skin.id == jetIdToDisplay,
      orElse: () => JetSkinCatalog.starterJet,
    );

    // Display the actual jet image (larger in header)
    return Center(
      child: Image.asset(
        'assets/images/${jetSkin.assetPath}',
        width: size * 1.5,  // Larger in header
        height: size * 1.5,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to generic icon if image fails to load
          return Icon(
            Icons.flight,
            size: size,
            color: Colors.white,
          );
        },
      ),
    );
  }

  Widget _buildTitle(BuildContext context, Size screenSize, double scaleFactor) {
    return Text(
      '🎉 Daily Reward Claimed!',
      style: TextStyle(
        fontSize: (22.0 * scaleFactor).clamp(18.0, 28.0),
        fontWeight: FontWeight.bold,
        color: Colors.white,
        shadows: [
          Shadow(
            offset: Offset(0, 2.0 * scaleFactor),
            blurRadius: 4.0 * scaleFactor,
            color: Colors.black54,
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildRewardDisplay(BuildContext context, Size screenSize, double scaleFactor) {
    // Larger icon for visual impact
    final iconSize = (36.0 * scaleFactor).clamp(32.0, 48.0);
    
    return ScaleTransition(
      scale: _rewardAnimation,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 20.0 * scaleFactor,
          vertical: 14.0 * scaleFactor,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _getRewardColor().withValues(alpha: 0.85),
              _getRewardColor().withValues(alpha: 0.65),
            ],
          ),
          borderRadius: BorderRadius.circular(16.0 * scaleFactor),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.4),
            width: 2.0 * scaleFactor,
          ),
          boxShadow: [
            BoxShadow(
              color: _getRewardColor().withValues(alpha: 0.4),
              blurRadius: 16.0 * scaleFactor,
              offset: Offset(0, 6.0 * scaleFactor),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Reward icon - Use Coin3DIcon for coins, Gem3DIcon for gems, jet image for jets
            if (widget.reward.type == DailyStreakRewardType.coins)
              Coin3DIcon(size: iconSize) // ✅ Using consistent coin asset
            else if (widget.reward.type == DailyStreakRewardType.gems)
              Gem3DIcon(size: iconSize)
            else if (widget.reward.type == DailyStreakRewardType.jetSkin)
              _buildJetSkinIcon(iconSize)
            else
              Container(
                width: iconSize,
                height: iconSize,
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
                      blurRadius: 4.0 * scaleFactor,
                      offset: Offset(0, 2.0 * scaleFactor),
                    ),
                  ],
                ),
                child: Icon(
                  _getRewardIcon(),
                  color: Colors.white,
                  size: (22.0 * scaleFactor).clamp(18.0, 28.0),
                ),
              ),
            
            SizedBox(width: 12.0 * scaleFactor),
            
            // Reward text - wrapped in Flexible to prevent overflow
            Flexible(
              child: Text(
                _getRewardDisplayText(),
                style: TextStyle(
                  fontSize: (24.0 * scaleFactor).clamp(20.0, 32.0),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1.5 * scaleFactor),
                      blurRadius: 3.0 * scaleFactor,
                      color: Colors.black54,
                    ),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build jet skin icon with actual jet image
  Widget _buildJetSkinIcon(double size) {
    if (widget.reward.jetSkinId == null) {
      // Fallback to generic icon if no skin ID
      return Container(
        width: size,
        height: size,
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
          Icons.flight,
          color: Colors.white,
          size: size * 0.6,
        ),
      );
    }

    // Handle progressive jet system (Day 6 reward)
    String? jetIdToDisplay = widget.reward.jetSkinId;
    if (widget.reward.jetSkinId == 'progressive_jet') {
      // ✅ FIX: Get the actual jet ID that was unlocked from DailyStreakManager
      final streakManager = DailyStreakManager();
      final actualUnlockedJet = streakManager.lastUnlockedJetId;
      
      if (actualUnlockedJet != null) {
        // Use the actual jet that was unlocked
        jetIdToDisplay = actualUnlockedJet;
      } else {
        // Fallback: Check inventory to find which jet was unlocked
        const jetProgression = [
          'cobra_strike',
          'storm_chaser',
          'disco_fever',
          'ruby_phantom',
          'sugar_storm',
        ];
        
        final inventory = InventoryManager();
        // Find first jet in progression that IS owned
        for (final jetId in jetProgression) {
          if (inventory.isOwned(jetId)) {
            jetIdToDisplay = jetId;
            break;
          }
        }
        
        // Final fallback
        if (jetIdToDisplay == 'progressive_jet' || jetIdToDisplay == null) {
          jetIdToDisplay = jetProgression.first;
        }
      }
    }

    // Find the jet skin
    final jetSkin = JetSkinCatalog.getAllSkins().firstWhere(
      (skin) => skin.id == jetIdToDisplay,
      orElse: () => JetSkinCatalog.starterJet,
    );

    // Display the actual jet image
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(size / 6),
        boxShadow: [
          BoxShadow(
            color: _getRewardColor().withValues(alpha: 0.4),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 6),
        child: Image.asset(
          'assets/images/${jetSkin.assetPath}',
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to generic icon if image fails to load
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getRewardColor(),
                    _getRewardColor().withValues(alpha: 0.8),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.flight,
                color: Colors.white,
                size: size * 0.6,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildExplanation(BuildContext context, Size screenSize, bool isHeartBooster, double scaleFactor) {
    // For heart booster, use more compact text
    final explanationText = isHeartBooster 
        ? _getCompactHeartBoosterText()
        : _getExplanationText();
    
    return Center(
      child: Text(
        explanationText,
        style: TextStyle(
          fontSize: (isHeartBooster ? 13.0 : 14.0) * scaleFactor,
          color: Colors.white.withValues(alpha: 0.9),
          height: isHeartBooster ? 1.35 : 1.45,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
  
  /// Get compact heart booster text that fits better
  String _getCompactHeartBoosterText() {
    return '🔥 Your Heart Booster is active for ${widget.reward.amount} min!\n\n'
        '✨ Benefits:\n'
        '• Max hearts: 3 → 6\n'
        '• Hearts refilled to 6\n'
        '• Faster regen: 8 min\n\n'
        'Enjoy unlimited flying!';
  }

  Widget _buildActionButton(BuildContext context, Size screenSize, double scaleFactor) {
    return SizedBox(
      width: double.infinity,
      child: ModernGameButton(
        label: 'AWESOME!',
        onPressed: () {
          Navigator.of(context).pop();
          widget.onClose?.call();
        },
        height: (52.0 * scaleFactor).clamp(48.0, 64.0),
        style: ModernButtonStyle.primary, // Gold
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

  /// Get reward-specific icon (fallback only - we use Coin3DIcon/Gem3DIcon for actual display)
  IconData _getRewardIcon() {
    switch (widget.reward.type) {
      case DailyStreakRewardType.coins:
        return Icons.paid; // Fallback only - Coin3DIcon used in actual display
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



/// 🛩️ Profile Jet Collection Album
/// 
/// Scrollable grid displaying all jets in a collectible album format.
/// Shows collection progress and allows equipping jets.
library;

import 'package:flutter/material.dart';
import '../../../game/core/jet_skins.dart';
import '../../../game/systems/inventory_manager.dart';
import '../../../game/core/economy_config.dart';
import '../../../game/systems/game_events_tracker.dart';
import '../../../core/events/event_bus.dart';
import '../../utils/responsive_config.dart';
import 'profile_jet_card.dart';
import 'profile_data_aggregator.dart';
import '../../widgets/buttons/modern_game_button.dart';
import '../../widgets/buttons/button_styles.dart';
import '../../widgets/store/insufficient_currency_popup.dart';
import '../../../game/core/special_offer_config.dart';
import '../../../game/systems/monetization_manager.dart';

/// 🖼️ FLAPPY JET POPUP FRAME SAFE AREA
/// 
/// The flappy_jet_popup.png image has a decorative frame that takes up space.
/// The safe content area is:
/// - Left: 50px
/// - Top: 270px  
/// - Right: 50px
/// - Bottom: 75px
/// 
/// This helper calculates responsive padding to keep content within the safe area.
/// Assumes same aspect ratio as special_popup.png (887x1336) for consistency.
class FlappyJetPopupFrameSafeArea {
  // Original image dimensions (assumed same as special_popup.png for consistency)
  static const double originalWidth = 887.0;
  static const double originalHeight = 1336.0;
  
  // Frame padding in original image pixels
  static const double framePaddingLeft = 50.0;
  static const double framePaddingTop = 270.0;
  static const double framePaddingRight = 50.0;
  static const double framePaddingBottom = 75.0;
  
  /// Calculate safe area padding for a given popup size
  /// Returns EdgeInsets with padding that scales proportionally
  static EdgeInsets calculateSafeAreaPadding(Size popupSize) {
    // Calculate scale factor based on width and height
    final widthScale = popupSize.width / originalWidth;
    final heightScale = popupSize.height / originalHeight;
    
    // Use the larger scale to ensure content fits
    final scale = widthScale > heightScale ? widthScale : heightScale;
    
    return EdgeInsets.only(
      left: framePaddingLeft * scale,
      top: framePaddingTop * scale,
      right: framePaddingRight * scale,
      bottom: framePaddingBottom * scale,
    );
  }
  
  /// Calculate safe content area size (popup size minus frame padding)
  static Size calculateSafeContentSize(Size popupSize) {
    final padding = calculateSafeAreaPadding(popupSize);
    return Size(
      popupSize.width - padding.left - padding.right,
      popupSize.height - padding.top - padding.bottom,
    );
  }
}

/// Jet Collection Album Component
/// 
/// Displays all jets in a scrollable grid.
/// Shows collection progress and allows interaction with jets.
class ProfileJetCollectionAlbum extends StatelessWidget {
  final ProfileData? profileData;
  final Function(String jetId)? onJetTap;
  
  const ProfileJetCollectionAlbum({
    super.key,
    this.profileData,
    this.onJetTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final isTablet = ResponsiveConfig.isTablet(screenSize);
    final isLargeTablet = ResponsiveConfig.isLargeTablet(screenSize);
    
    final inventory = InventoryManager();
    final allJets = JetSkinCatalog.getAllSkins();
    final ownedJets = inventory.ownedSkinIds;
    final equippedJetId = inventory.equippedSkinId;
    
    // Calculate collection progress
    final totalOwned = profileData?.totalJetsOwned ?? ownedJets.length;
    final totalAvailable = profileData?.totalJetsAvailable ?? allJets.length;
    final progress = totalAvailable > 0 ? (totalOwned / totalAvailable) : 0.0;
    
    // FlappyJet brand colors
    const Color primaryBlue = Color(0xFF4A90E2);
    const Color secondaryBlue = Color(0xFF357ABD);
    const Color accentBlue = Color(0xFF85C1FF);
    const Color goldAccent = Color(0xFFFFD700);
    const Color darkBlue = Color(0xFF1A2F4A);
    
    return Container(
      decoration: BoxDecoration(
        // Modern gradient background
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.98),
            Color(0xFFF0F7FF).withValues(alpha: 0.95),
            Color(0xFFE8F4FF).withValues(alpha: 0.92),
          ],
        ),
        borderRadius: BorderRadius.circular(ResponsiveConfig.responsiveSize(20.0, screenSize)),
        // Modern gaming-style border with gradient
        border: Border.all(
          width: ResponsiveConfig.responsiveSize(2.5, screenSize),
          color: Colors.transparent,
        ),
        boxShadow: [
          // Outer glow effect
          BoxShadow(
            color: primaryBlue.withValues(alpha: 0.15),
            blurRadius: ResponsiveConfig.responsiveSize(20.0, screenSize),
            spreadRadius: ResponsiveConfig.responsiveSize(2.0, screenSize),
            offset: Offset(0, ResponsiveConfig.responsiveSize(4.0, screenSize)),
          ),
          // Inner shadow for depth
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: ResponsiveConfig.responsiveSize(12.0, screenSize),
            offset: Offset(0, ResponsiveConfig.responsiveSize(2.0, screenSize)),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ResponsiveConfig.responsiveSize(20.0, screenSize)),
        child: Container(
          decoration: BoxDecoration(
            // Inner border effect with gradient
            border: Border.all(
              width: ResponsiveConfig.responsiveSize(1.5, screenSize),
              color: accentBlue.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Progress - Modern Gaming Style
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryBlue.withValues(alpha: 0.1),
                      secondaryBlue.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: accentBlue.withValues(alpha: 0.2),
                      width: ResponsiveConfig.responsiveSize(1.0, screenSize),
                    ),
                  ),
                ),
                padding: EdgeInsets.all(ResponsiveConfig.responsivePadding(18.0, screenSize)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Title with modern gaming font style
                        Row(
                          children: [
                            // Decorative icon/emblem
                            Container(
                              width: ResponsiveConfig.responsiveSize(isLargeTablet ? 8.0 : isTablet ? 7.0 : 6.0, screenSize),
                              height: ResponsiveConfig.responsiveSize(isLargeTablet ? 8.0 : isTablet ? 7.0 : 6.0, screenSize),
                              decoration: BoxDecoration(
                                color: goldAccent,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: goldAccent.withValues(alpha: 0.6),
                                    blurRadius: ResponsiveConfig.responsiveSize(6.0, screenSize),
                                    spreadRadius: ResponsiveConfig.responsiveSize(1.0, screenSize),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: ResponsiveConfig.responsivePadding(10.0, screenSize)),
                            Text(
                              'JET COLLECTION',
                              style: TextStyle(
                                fontSize: ResponsiveConfig.responsiveFontSize(
                                  isLargeTablet ? 24.0 : isTablet ? 22.0 : 20.0,
                                  screenSize,
                                  context,
                                ),
                                fontWeight: FontWeight.w800,
                                letterSpacing: ResponsiveConfig.responsiveSize(1.5, screenSize),
                                foreground: Paint()
                                  ..shader = LinearGradient(
                                    colors: [primaryBlue, secondaryBlue, darkBlue],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ).createShader(
                                    Rect.fromLTWH(0, 0, 300, 50),
                                  ),
                              ),
                            ),
                          ],
                        ),
                        // Modern badge-style counter
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveConfig.responsivePadding(14.0, screenSize),
                            vertical: ResponsiveConfig.responsivePadding(8.0, screenSize),
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                primaryBlue,
                                secondaryBlue,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(ResponsiveConfig.responsiveSize(16.0, screenSize)),
                            boxShadow: [
                              BoxShadow(
                                color: primaryBlue.withValues(alpha: 0.4),
                                blurRadius: ResponsiveConfig.responsiveSize(8.0, screenSize),
                                offset: Offset(0, ResponsiveConfig.responsiveSize(2.0, screenSize)),
                              ),
                            ],
                            border: Border.all(
                              color: goldAccent.withValues(alpha: 0.5),
                              width: ResponsiveConfig.responsiveSize(1.5, screenSize),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$totalOwned',
                                style: TextStyle(
                                  fontSize: ResponsiveConfig.responsiveFontSize(
                                    isLargeTablet ? 18.0 : isTablet ? 16.0 : 14.0,
                                    screenSize,
                                    context,
                                  ),
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: ResponsiveConfig.responsiveSize(0.5, screenSize),
                                ),
                              ),
                              Text(
                                ' / ',
                                style: TextStyle(
                                  fontSize: ResponsiveConfig.responsiveFontSize(
                                    isLargeTablet ? 16.0 : isTablet ? 14.0 : 12.0,
                                    screenSize,
                                    context,
                                  ),
                                  fontWeight: FontWeight.w600,
                                  color: goldAccent,
                                ),
                              ),
                              Text(
                                '$totalAvailable',
                                style: TextStyle(
                                  fontSize: ResponsiveConfig.responsiveFontSize(
                                    isLargeTablet ? 18.0 : isTablet ? 16.0 : 14.0,
                                    screenSize,
                                    context,
                                  ),
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: ResponsiveConfig.responsivePadding(16.0, screenSize)),
                    // Modern progress bar with gradient
                    Container(
                      height: ResponsiveConfig.responsiveSize(12.0, screenSize),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(ResponsiveConfig.responsiveSize(10.0, screenSize)),
                        border: Border.all(
                          color: accentBlue.withValues(alpha: 0.3),
                          width: ResponsiveConfig.responsiveSize(1.0, screenSize),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: ResponsiveConfig.responsiveSize(4.0, screenSize),
                            offset: Offset(0, ResponsiveConfig.responsiveSize(2.0, screenSize)),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(ResponsiveConfig.responsiveSize(10.0, screenSize)),
                        child: Stack(
                          children: [
                            // Background
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.grey.shade200,
                                    Colors.grey.shade100,
                                  ],
                                ),
                              ),
                            ),
                            // Progress fill with gradient
                            FractionallySizedBox(
                              widthFactor: progress,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      primaryBlue,
                                      accentBlue,
                                      primaryBlue,
                                    ],
                                    stops: [0.0, 0.5, 1.0],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryBlue.withValues(alpha: 0.5),
                                      blurRadius: ResponsiveConfig.responsiveSize(8.0, screenSize),
                                      spreadRadius: ResponsiveConfig.responsiveSize(1.0, screenSize),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Shine effect overlay
                            if (progress > 0)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.white.withValues(alpha: 0.3),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: ResponsiveConfig.responsivePadding(8.0, screenSize)),
                    // Progress text with modern style
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(progress * 100).toStringAsFixed(0)}% Complete',
                          style: TextStyle(
                            fontSize: ResponsiveConfig.responsiveFontSize(
                              isLargeTablet ? 13.0 : isTablet ? 12.0 : 11.0,
                              screenSize,
                              context,
                            ),
                            fontWeight: FontWeight.w700,
                            color: secondaryBlue,
                            letterSpacing: ResponsiveConfig.responsiveSize(0.5, screenSize),
                          ),
                        ),
                        if (progress < 1.0)
                          Text(
                            '${totalAvailable - totalOwned} remaining',
                            style: TextStyle(
                              fontSize: ResponsiveConfig.responsiveFontSize(
                                isLargeTablet ? 12.0 : isTablet ? 11.0 : 10.0,
                                screenSize,
                                context,
                              ),
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
          
          // Jet Grid
          Padding(
            padding: EdgeInsets.all(ResponsiveConfig.responsivePadding(18.0, screenSize)),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isLargeTablet ? 4 : isTablet ? 3 : 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: ResponsiveConfig.responsivePadding(12.0, screenSize),
                mainAxisSpacing: ResponsiveConfig.responsivePadding(12.0, screenSize),
              ),
              itemCount: allJets.length,
              itemBuilder: (context, index) {
                final jet = allJets[index];
                final isOwned = ownedJets.contains(jet.id) || jet.id == 'sky_rookie';
                final isEquipped = equippedJetId == jet.id;
                
                return ProfileJetCard(
                  jet: jet,
                  isOwned: isOwned,
                  isEquipped: isEquipped,
                  onTap: () {
                    if (onJetTap != null) {
                      onJetTap!(jet.id);
                    } else {
                      _handleJetTap(context, jet, isOwned, isEquipped);
                    }
                  },
                );
              },
            ),
          ),
          
          SizedBox(height: ResponsiveConfig.responsivePadding(16.0, screenSize)),
        ],
      ),
        ),
      ),
    );
  }
  
  void _handleJetTap(
    BuildContext context,
    JetSkin jet,
    bool isOwned,
    bool isEquipped,
  ) {
    if (!isOwned) {
      // ✅ Show purchase popup for locked jet
      _showPurchaseDialog(context, jet);
    } else if (!isEquipped) {
      // Equip the jet
      final inventory = InventoryManager();
      inventory.equipSkin(jet.id).then((success) {
        if (success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Equipped ${jet.displayName}'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      });
    } else {
      // Already equipped - show info
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${jet.displayName} is already equipped'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
  
  /// Complete the jet purchase and equip it
  Future<void> _completeJetPurchase(
    BuildContext context,
    JetSkin jet,
    bool isGemExclusive,
    int coinPrice,
    int gemPrice,
  ) async {
    final inventory = InventoryManager();
    
    try {
      if (isGemExclusive) {
        final success = await inventory.spendGems(gemPrice);
        if (!success) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Not enough gems!')),
            );
          }
          return;
        }
      } else {
        final success = await inventory.spendSoftCurrency(coinPrice);
        if (!success) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Not enough coins!')),
            );
          }
          return;
        }
      }
      
      // Unlock and equip the skin
      await inventory.unlockSkin(jet.id);
      await inventory.equipSkin(jet.id);
      
      // Track purchase for achievements
      final gameEvents = GameEventsTracker();
      await gameEvents.onSkinPurchased(
        skinId: jet.id,
        coinCost: isGemExclusive ? 0 : coinPrice,
        rarity: jet.rarity.name,
      );
      
      // Fire EventBus event
      EventBus().fire('skin_purchased', {
        'jet_id': jet.id,
        'jet_name': jet.displayName,
        'purchase_type': isGemExclusive ? 'gems' : 'coins',
        'cost_coins': isGemExclusive ? 0 : coinPrice,
        'cost_gems': isGemExclusive ? gemPrice : 0,
        'rarity': jet.rarity.name,
      });
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Purchased and equipped ${jet.displayName}!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _showPurchaseDialog(BuildContext context, JetSkin jet) async {
    final inventory = InventoryManager();
    final economy = EconomyConfig();
    final coinPrice = economy.getSkinCoinPrice(jet);
    final gemPrice = economy.getSkinGemPrice(jet);
    final isGemExclusive = jet.rarity == JetRarity.mythic;
    final price = isGemExclusive ? gemPrice : coinPrice;
    final currencyName = isGemExclusive ? 'gems' : 'coins';
    final hasEnough = isGemExclusive 
        ? inventory.gems >= gemPrice 
        : inventory.softCurrency >= coinPrice;
    
    final screenSize = MediaQuery.sizeOf(context);
    final isTablet = ResponsiveConfig.isTablet(screenSize);
    final isLargeTablet = ResponsiveConfig.isLargeTablet(screenSize);
    
    // FlappyJet brand colors for text
    const Color primaryGold = Color(0xFFFFD700);
    const Color accentOrange = Color(0xFFFFA500);
    const Color textBlue = Color(0xFF4A90E2);
    
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => LayoutBuilder(
        builder: (dialogContext, constraints) {
          // Calculate popup size maintaining aspect ratio of flappy_jet_popup.png
          final popupAspectRatio = FlappyJetPopupFrameSafeArea.originalWidth / FlappyJetPopupFrameSafeArea.originalHeight;
          final maxPopupWidth = constraints.maxWidth.clamp(280.0, 400.0);
          final maxPopupHeight = constraints.maxHeight.clamp(400.0, 600.0);
          
          double popupWidth = maxPopupWidth;
          double popupHeight = popupWidth / popupAspectRatio;
          
          // If height exceeds max, scale down
          if (popupHeight > maxPopupHeight) {
            popupHeight = maxPopupHeight;
            popupWidth = popupHeight * popupAspectRatio;
          }
          
          final popupSize = Size(popupWidth, popupHeight);
          
          // Calculate safe area padding based on frame dimensions
          final safeAreaPadding = FlappyJetPopupFrameSafeArea.calculateSafeAreaPadding(popupSize);
          
          // Responsive jet image size (scaled to safe content area)
          final safeContentSize = FlappyJetPopupFrameSafeArea.calculateSafeContentSize(popupSize);
          final jetImageSize = ResponsiveConfig.responsiveSize(
            isLargeTablet ? 200.0 : isTablet ? 180.0 : 150.0,
            screenSize,
          ).clamp(80.0, safeContentSize.width * 0.6);
          
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(
              horizontal: ResponsiveConfig.responsivePadding(20.0, screenSize),
            ),
            child: Container(
              width: popupWidth,
              height: popupHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(ResponsiveConfig.responsivePadding(24.0, screenSize)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                    spreadRadius: 5,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  // Popup background image
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/ui/flappy_jet_popup.png',
                      fit: BoxFit.cover, // Cover to fill container while maintaining aspect ratio
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback to a styled container if image fails
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.shade900,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.orange, width: 3),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // Content overlay - properly constrained within popup frame safe area
                  Positioned.fill(
                    child: Padding(
                      padding: safeAreaPadding,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                      // Jet skin image (with top padding, no shadow/decoration)
                      SizedBox(
                        width: jetImageSize,
                        height: jetImageSize,
                        child: Image.asset(
                          'assets/images/${jet.assetPath}',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.flight,
                              size: jetImageSize * 0.6,
                              color: Colors.grey.shade400,
                            );
                          },
                        ),
                      ),
                      
                      SizedBox(height: ResponsiveConfig.responsivePadding(16.0, screenSize)),
                      
                      // Jet name with engaging gradient text
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [primaryGold, accentOrange],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: Text(
                          jet.displayName.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: ResponsiveConfig.responsiveFontSize(
                              isLargeTablet ? 28.0 : isTablet ? 24.0 : 22.0,
                              screenSize,
                              context,
                            ),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                offset: Offset(0, ResponsiveConfig.responsiveSize(2.0, screenSize)),
                                blurRadius: ResponsiveConfig.responsiveSize(6.0, screenSize),
                                color: Colors.black.withValues(alpha: 0.8),
                              ),
                              Shadow(
                                offset: Offset(0, ResponsiveConfig.responsiveSize(1.0, screenSize)),
                                blurRadius: ResponsiveConfig.responsiveSize(3.0, screenSize),
                                color: Colors.black.withValues(alpha: 0.6),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      SizedBox(height: ResponsiveConfig.responsivePadding(12.0, screenSize)),
                      
                      // Purchase text with engaging colors
                      Text(
                        'Purchase for $price $currencyName?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: ResponsiveConfig.responsiveFontSize(
                            isLargeTablet ? 20.0 : isTablet ? 18.0 : 16.0,
                            screenSize,
                            context,
                          ),
                          fontWeight: FontWeight.w700,
                          color: textBlue,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              offset: Offset(0, ResponsiveConfig.responsiveSize(2.0, screenSize)),
                              blurRadius: ResponsiveConfig.responsiveSize(4.0, screenSize),
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            Shadow(
                              offset: Offset(0, ResponsiveConfig.responsiveSize(1.0, screenSize)),
                              blurRadius: ResponsiveConfig.responsiveSize(2.0, screenSize),
                              color: Colors.black.withValues(alpha: 0.5),
                            ),
                          ],
                        ),
                      ),
                      
                      // Spacer to push buttons down (using fixed spacing instead of Expanded for scrollable content)
                      SizedBox(height: ResponsiveConfig.responsivePadding(20.0, screenSize)),
                      
                      // Action buttons - styled and higher, with bottom padding
                      Padding(
                        padding: EdgeInsets.only(
                          top: ResponsiveConfig.responsivePadding(20.0, screenSize),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Cancel button
                            Expanded(
                              child: ModernGameButton(
                                label: 'CANCEL',
                                onPressed: () => Navigator.of(context).pop(false),
                                height: ResponsiveConfig.responsiveButtonHeight(
                                  isLargeTablet ? 50.0 : isTablet ? 47.0 : 43.0,
                                  screenSize,
                                ),
                                style: ModernButtonStyle.danger,
                              ),
                            ),
                            
                            SizedBox(width: ResponsiveConfig.responsivePadding(16.0, screenSize)),
                            
                            // Yes button
                            Expanded(
                              child: ModernGameButton(
                                label: 'YES',
                                onPressed: () => Navigator.of(context).pop(true),
                                height: ResponsiveConfig.responsiveButtonHeight(
                                  isLargeTablet ? 50.0 : isTablet ? 47.0 : 43.0,
                                  screenSize,
                                ),
                                style: ModernButtonStyle.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
          );
        },
      ),
    );
    
    if (result == true && context.mounted) {
      if (!hasEnough) {
        // Show insufficient currency popup - recommends currency bundles (gems + coins)
        final neededCurrency = isGemExclusive 
            ? OfferCurrencyType.gems 
            : OfferCurrencyType.coins;
        final neededAmount = isGemExclusive ? gemPrice : coinPrice;
        final currentAmount = isGemExclusive 
            ? inventory.gems 
            : inventory.softCurrency;
        
        // Find cheapest currency bundle that covers the need
        final shortfall = neededAmount - currentAmount;
        final targetAmount = (shortfall * 1.2).ceil(); // 20% bonus
        final bundles = EconomyConfig.currencyBundles.values.toList()
          ..sort((a, b) => a.usdPrice.compareTo(b.usdPrice));
        
        CurrencyBundle? recommendedBundle;
        for (final bundle in bundles) {
          final bundleAmount = neededCurrency == OfferCurrencyType.gems 
              ? bundle.totalGems 
              : bundle.totalCoins;
          if (bundleAmount >= targetAmount) {
            recommendedBundle = bundle;
            break;
          }
        }
        recommendedBundle ??= bundles.last; // Fallback to largest bundle
        
        await showInsufficientCurrencyPopup(
          context: context,
          neededCurrency: neededCurrency,
          neededAmount: neededAmount,
          currentAmount: currentAmount,
          onPurchase: () async {
            // User purchased currency bundle - handle the purchase and auto-complete jet purchase
            final monetization = MonetizationManager();
            
            if (recommendedBundle != null) {
              // Purchase the recommended currency bundle
              final result = await monetization.purchaseIAPProduct(recommendedBundle.id);
              
              if (result.isSuccess && context.mounted) {
                // Currency bundle grants both gems and coins automatically via IAP system
                // Wait a moment for the IAP system to grant the currency
                await Future.delayed(const Duration(milliseconds: 800));
                
                // Automatically retry the jet purchase - user doesn't need to click again
                await _completeJetPurchase(context, jet, isGemExclusive, coinPrice, gemPrice);
              } else if (result.isCancelled) {
                // User cancelled - no action needed
                return;
              } else if (result.isPending) {
                // Purchase pending - show message
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Purchase is being processed...'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } else {
                // Purchase failed
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result.message ?? 'Purchase failed'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            }
          },
          onDismiss: () {
            // User dismissed - stay on profile page
          },
        );
        
        // If user purchased currency, the onPurchase callback handles the jet purchase
        return;
      }
      
      // User has enough currency - proceed with purchase
      await _completeJetPurchase(context, jet, isGemExclusive, coinPrice, gemPrice);
    }
  }
}


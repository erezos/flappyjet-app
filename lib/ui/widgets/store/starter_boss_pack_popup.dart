/// ⚔️ Starter Boss Pack Special Offer Popup
/// 
/// Beautiful, engaging popup for the Bosses Showdown tournament special offer
/// Shows 3 exclusive jet skins (Police Patrol, Red Alert, Green Lightning) for $0.99
/// Uses ui/special_popup.png as the popup frame
/// Follows mobile gaming best practices for maximum conversion
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../game/core/jet_skins.dart';
import '../../../game/core/iap_products.dart';
import '../../../game/systems/inventory_manager.dart';
import '../../../game/systems/monetization_manager.dart';
import '../../../game/systems/game_events_tracker.dart';
import '../../../game/systems/no_ads_manager.dart';
import '../../utils/responsive_config.dart';
import '../buttons/modern_game_button.dart';
import '../buttons/button_styles.dart';
import '../../../core/debug_logger.dart';
import '../../../core/events/event_bus.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'insufficient_currency_popup.dart'; // For SpecialPopupFrameSafeArea

/// Show the Starter Boss Pack special offer popup
/// 
/// Returns true if user purchased, false if dismissed
/// ✅ FIX: Use barrierDismissible: false to prevent accidental dismissal
/// and ensure proper navigation stack management
Future<bool?> showStarterBossPackPopup({
  required BuildContext context,
  required VoidCallback onPurchaseComplete,
  VoidCallback? onDismiss,
}) async {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false, // ✅ FIX: Prevent accidental dismissal that could cause navigation issues
    barrierColor: Colors.black.withValues(alpha: 0.85), // Darker for more focus
    builder: (dialogContext) => PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // ✅ FIX: Handle back button properly to avoid navigation stack issues
          onDismiss?.call();
        }
      },
      child: StarterBossPackPopupWidget(
        onPurchaseComplete: () {
          // ✅ FIX: Use dialogContext to ensure correct navigation
          Navigator.of(dialogContext).pop(true);
          onPurchaseComplete();
        },
        onDismiss: () {
          // ✅ FIX: Use dialogContext to ensure correct navigation
          Navigator.of(dialogContext).pop(false);
          onDismiss?.call();
        },
      ),
    ),
  );
}

/// Starter Boss Pack popup widget
class StarterBossPackPopupWidget extends StatefulWidget {
  final VoidCallback onPurchaseComplete;
  final VoidCallback onDismiss;

  const StarterBossPackPopupWidget({
    super.key,
    required this.onPurchaseComplete,
    required this.onDismiss,
  });

  @override
  State<StarterBossPackPopupWidget> createState() => _StarterBossPackPopupWidgetState();
}

class _StarterBossPackPopupWidgetState extends State<StarterBossPackPopupWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isPurchasing = false;

  // Jet skins in the bundle
  static const List<String> _jetSkinIds = ['police_patrol', 'red_alert', 'green_lightning'];
  static const String _equipSkinId = 'police_patrol';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: ResponsiveConfig.responsiveEdgeInsetsSymmetric(
            horizontal: 16.0,
            vertical: 24.0,
            screenSize: screenSize,
          ),
          child: _buildPopupContent(screenSize),
        ),
      ),
    );
  }

  Widget _buildPopupContent(Size screenSize) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate popup size maintaining aspect ratio of special_popup.png
        final popupAspectRatio = SpecialPopupFrameSafeArea.originalWidth / SpecialPopupFrameSafeArea.originalHeight;
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
        final safeAreaPadding = SpecialPopupFrameSafeArea.calculateSafeAreaPadding(popupSize);
        
        return Container(
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
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Popup frame image (ui/special_popup.png)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(ResponsiveConfig.responsivePadding(24.0, screenSize)),
                  child: Image.asset(
                    'assets/images/ui/special_popup.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      safePrint('⚠️ Failed to load special_popup.png: $error');
                      // Fallback gradient background
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF8B0000), // Dark red
                              const Color(0xFFDC143C), // Crimson
                              const Color(0xFFFF6347), // Tomato
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Content overlay - stronger overlay for better contrast
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(ResponsiveConfig.responsivePadding(24.0, screenSize)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.5), // Stronger darkening for better text readability
                        Colors.black.withValues(alpha: 0.3),
                        Colors.black.withValues(alpha: 0.4),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),

              // Close button - positioned at top right, outside safe area (on frame edge)
              Positioned(
                top: ResponsiveConfig.responsivePadding(8.0, screenSize),
                right: ResponsiveConfig.responsivePadding(8.0, screenSize),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onDismiss();
                  },
                  child: Container(
                    padding: EdgeInsets.all(ResponsiveConfig.responsivePadding(8.0, screenSize)),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7), // Dark background for visibility
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.8),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: ResponsiveConfig.responsiveSize(20.0, screenSize),
                    ),
                  ),
                ),
              ),

              // Main content - using safe area padding to avoid frame overlap
              Padding(
                padding: safeAreaPadding,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final content = Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: ResponsiveConfig.responsivePadding(6.0, screenSize)),

                        // Title - smaller to fit in one line
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'STARTER BOSS PACK',
                            style: TextStyle(
                              fontSize: ResponsiveConfig.responsiveFontSize(20.0, screenSize, context),
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.0,
                              shadows: [
                                Shadow(
                                  offset: const Offset(0, 3),
                                  blurRadius: 8,
                                  color: Colors.black.withValues(alpha: 0.8),
                                ),
                                Shadow(
                                  offset: const Offset(0, 1),
                                  blurRadius: 3,
                                  color: Colors.red.withValues(alpha: 0.9),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        SizedBox(height: ResponsiveConfig.responsivePadding(4.0, screenSize)),

                        // Subtitle
                        Text(
                          '3 Powerful Boss Jets',
                          style: TextStyle(
                            fontSize: ResponsiveConfig.responsiveFontSize(15.0, screenSize, context),
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFFFD700), // Gold
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                offset: const Offset(0, 2),
                                blurRadius: 4,
                                color: Colors.black.withValues(alpha: 0.7),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),

                        SizedBox(height: ResponsiveConfig.responsivePadding(8.0, screenSize)),

                        // No Ads Banner - 24 Hours
                        _buildNoAdsBanner(screenSize),

                        SizedBox(height: ResponsiveConfig.responsivePadding(5.0, screenSize)), // Reduced from 10.0 - between no ads and jet skins

                        // Jet skins display - floating without squares
                        _buildJetSkinsDisplay(screenSize),

                        SizedBox(height: ResponsiveConfig.responsivePadding(5.0, screenSize)), // Reduced from 8.0

                        // Price display with discount
                        _buildPriceDisplay(screenSize),

                        SizedBox(height: ResponsiveConfig.responsivePadding(6.0, screenSize)), // Reduced from 10.0

                        // Purchase button - smaller
                        _buildPurchaseButton(screenSize),
                      ],
                    );

                    // Use SingleChildScrollView but with physics that only scrolls if absolutely necessary
                    // This ensures content fits without scrolling on most devices
                    return SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: content,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildJetSkinsDisplay(Size screenSize) {
    final jetSkins = _jetSkinIds.map((id) {
      return JetSkinCatalog.getAllSkins().firstWhere(
        (skin) => skin.id == id,
        orElse: () => JetSkinCatalog.starterJet,
      );
    }).toList();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: jetSkins.map((skin) {
        return Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Jet skin image - floating without any shadow or shade
              SizedBox(
                width: ResponsiveConfig.responsiveSize(85.0, screenSize).clamp(70.0, 100.0),
                height: ResponsiveConfig.responsiveSize(85.0, screenSize).clamp(70.0, 100.0),
                child: Image.asset(
                  'assets/images/${skin.assetPath}',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.flight,
                      size: ResponsiveConfig.responsiveSize(50.0, screenSize),
                      color: Colors.white,
                    );
                  },
                ),
              ),
              SizedBox(height: ResponsiveConfig.responsivePadding(2.0, screenSize)), // Reduced from 4.0 to 2.0
              // Jet name
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  skin.displayName,
                  style: TextStyle(
                    fontSize: ResponsiveConfig.responsiveFontSize(12.0, screenSize, context),
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        offset: const Offset(0, 1),
                        blurRadius: 3,
                        color: Colors.black.withValues(alpha: 0.8),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNoAdsBanner(Size screenSize) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveConfig.responsivePadding(12.0, screenSize),
        vertical: ResponsiveConfig.responsivePadding(8.0, screenSize),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4FC3F7).withValues(alpha: 0.9),
            const Color(0xFF29B6F6).withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(ResponsiveConfig.responsivePadding(12.0, screenSize)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.8),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4FC3F7).withValues(alpha: 0.5),
            blurRadius: 8,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // No Ads Icon - bigger size for better visibility
          Image.asset(
            'assets/images/ui/no_ads_icon.png',
            width: ResponsiveConfig.responsiveSize(40.0, screenSize).clamp(36.0, 48.0),
            height: ResponsiveConfig.responsiveSize(40.0, screenSize).clamp(36.0, 48.0),
            errorBuilder: (context, error, stackTrace) {
              // Fallback if image not found
              return Icon(
                Icons.block,
                size: ResponsiveConfig.responsiveSize(40.0, screenSize).clamp(36.0, 48.0),
                color: Colors.white,
              );
            },
          ),
          SizedBox(width: ResponsiveConfig.responsivePadding(8.0, screenSize)),
          // Text
          Text(
            'NO ADS FOR 24 HOURS',
            style: TextStyle(
              fontSize: ResponsiveConfig.responsiveFontSize(13.0, screenSize, context),
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.8,
              shadows: [
                Shadow(
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                  color: Colors.black.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceDisplay(Size screenSize) {
    return Column(
      children: [
        // Original price (crossed out) - light red color
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '\$4.99',
              style: TextStyle(
                fontSize: ResponsiveConfig.responsiveFontSize(16.0 * 0.95, screenSize, context), // Reduced by 5%
                color: const Color(0xFFFF6B6B), // Light red
                decoration: TextDecoration.lineThrough,
                decorationThickness: 2.5,
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
            SizedBox(width: ResponsiveConfig.responsivePadding(10.0, screenSize)),
            // Discount badge
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveConfig.responsivePadding(8.0, screenSize),
                vertical: ResponsiveConfig.responsivePadding(3.0, screenSize),
              ),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(ResponsiveConfig.responsivePadding(10.0, screenSize)),
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.6),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '80% OFF',
                style: TextStyle(
                  fontSize: ResponsiveConfig.responsiveFontSize(12.0, screenSize, context),
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveConfig.responsivePadding(6.0, screenSize)),
        // Special price
        Text(
          'NOW ONLY',
          style: TextStyle(
            fontSize: ResponsiveConfig.responsiveFontSize(12.0 * 0.95, screenSize, context), // Reduced by 5%
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.9),
            letterSpacing: 1.0,
            shadows: [
              Shadow(
                offset: const Offset(0, 1),
                blurRadius: 2,
                color: Colors.black.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
        SizedBox(height: ResponsiveConfig.responsivePadding(4.0, screenSize)),
        Text(
          '\$0.99',
          style: TextStyle(
            fontSize: ResponsiveConfig.responsiveFontSize(32.0 * 0.95, screenSize, context), // Reduced by 5%
            fontWeight: FontWeight.w900,
            color: const Color(0xFFFFD700), // Gold
            letterSpacing: 1.0,
            shadows: [
              Shadow(
                offset: const Offset(0, 3),
                blurRadius: 8,
                color: Colors.black.withValues(alpha: 0.8),
              ),
              Shadow(
                offset: const Offset(0, 1),
                blurRadius: 3,
                color: const Color(0xFFFFD700).withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPurchaseButton(Size screenSize) {
    return SizedBox(
      width: double.infinity,
      child: ModernGameButton(
        label: _isPurchasing ? 'PURCHASING...' : 'GET IT NOW!',
        onPressed: () {
          _handlePurchase();
        },
        enabled: !_isPurchasing,
        style: ModernButtonStyle.success,
        height: ResponsiveConfig.responsiveSize(48.0, screenSize).clamp(44.0, 52.0), // Smaller button
      ),
    );
  }

  Future<void> _handlePurchase() async {
    if (_isPurchasing) return;

    setState(() => _isPurchasing = true);
    HapticFeedback.mediumImpact();

    try {
      final iapProduct = IAPProductCatalog.getProductById('starter_boss_pack');
      if (iapProduct == null) {
        safePrint('⚠️ Starter Boss Pack product not found');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product not available')),
          );
        }
        setState(() => _isPurchasing = false);
        return;
      }

      // Purchase via IAP (use product ID, not store ID)
      final monetization = MonetizationManager();
      final purchaseResult = await monetization.purchaseIAPProduct(iapProduct.id);

      if (purchaseResult.isSuccess) {
        // ✅ FIX: Unlock all 3 jet skins - ensure all are unlocked before proceeding
        final inventory = InventoryManager();
        
        // Unlock all skins sequentially and verify each one
        for (final skinId in _jetSkinIds) {
          try {
            await inventory.unlockSkin(skinId);
            safePrint('✅ Unlocked jet skin: $skinId');
          } catch (e) {
            safePrint('❌ Error unlocking skin $skinId: $e');
            // Continue with other skins even if one fails
          }
        }
        
        // Refresh inventory to ensure all changes are persisted
        await inventory.refresh();
        
        // Verify all skins were unlocked
        final allUnlocked = _jetSkinIds.every((skinId) => inventory.isOwned(skinId));
        if (!allUnlocked) {
          safePrint('⚠️ Warning: Not all skins were unlocked. Retrying...');
          // Retry unlocking any missing skins
          for (final skinId in _jetSkinIds) {
            if (!inventory.isOwned(skinId)) {
              try {
                await inventory.unlockSkin(skinId);
                safePrint('✅ Retry unlocked jet skin: $skinId');
              } catch (e) {
                safePrint('❌ Retry failed for skin $skinId: $e');
              }
            }
          }
          // Refresh again after retry
          await inventory.refresh();
        }

        // Equip police_patrol
        await inventory.equipSkin(_equipSkinId);

        // ✅ NEW: Activate 24 hours No Ads
        try {
          final noAdsManager = NoAdsManager();
          // Initialize if not already initialized (safe to call multiple times)
          try {
            await noAdsManager.initialize();
          } catch (e) {
            // Already initialized or initialization failed - continue anyway
            safePrint('🚫 NoAdsManager initialization: $e');
          }
          await noAdsManager.activate24Hours();
          safePrint('🚫 ✅ 24 Hours No Ads activated for Starter Boss Pack purchase');
        } catch (e) {
          safePrint('🚫 ⚠️ Failed to activate 24 hours No Ads: $e');
          // Continue even if no-ads activation fails - skins are more important
        }

        // ✅ NEW: Track purchase to prevent showing popup again
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('starter_boss_pack_purchased', true);
          safePrint('📦 Starter Boss Pack purchase tracked');
        } catch (e) {
          safePrint('📦 ⚠️ Failed to track Starter Boss Pack purchase: $e');
        }

        // Track purchase
        final gameEvents = GameEventsTracker();
        for (final skinId in _jetSkinIds) {
          final skin = JetSkinCatalog.getAllSkins().firstWhere(
            (s) => s.id == skinId,
            orElse: () => JetSkinCatalog.starterJet,
          );
          await gameEvents.onSkinPurchased(
            skinId: skinId,
            coinCost: 0,
            rarity: skin.rarity.name,
          );
        }

        // Fire EventBus event
        EventBus().fire('special_offer_purchased', {
          'offer_id': 'starter_boss_pack',
          'product_id': 'starter_boss_pack',
          'price_usd': 0.99,
          'skins_unlocked': _jetSkinIds,
          'skin_equipped': _equipSkinId,
        });

        HapticFeedback.heavyImpact();
        
        // ✅ FIX: Auto-close popup immediately after successful purchase
        // Close the dialog first, then show success message
        if (mounted) {
          // Close the dialog immediately
          Navigator.of(context).pop(true);
          
          // Show success message after dialog closes
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('🎉 Starter Boss Pack purchased! All 3 jets unlocked! Police Patrol equipped! 24 hours No Ads activated!'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          });
          
          // Call purchase complete callback
          widget.onPurchaseComplete();
        } else {
          widget.onPurchaseComplete();
        }
      } else if (purchaseResult.isCancelled) {
        // User cancelled - no error message needed
        setState(() => _isPurchasing = false);
      } else if (purchaseResult.isPending) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Purchase is being processed...'),
              backgroundColor: Colors.blue,
            ),
          );
        }
        // Keep purchasing state - will be updated when purchase completes
        // Note: In a real implementation, you'd listen to the purchase stream
        // For now, we'll reset after a delay
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() => _isPurchasing = false);
          }
        });
      } else {
        safePrint('⚠️ Purchase failed: ${purchaseResult.message}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(purchaseResult.message ?? 'Purchase failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isPurchasing = false);
      }
    } catch (e) {
      safePrint('⚠️ Error purchasing Starter Boss Pack: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isPurchasing = false);
    }
  }
}


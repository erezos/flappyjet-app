import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/debug_logger.dart';
import '../../services/real_admob_service.dart';
import '../../services/enhanced_iap_manager.dart';
import '../core/iap_products.dart';
import 'inventory_manager.dart';
import 'lives_manager.dart';
import 'firebase_analytics_manager.dart';

/// 🚀 PRODUCTION MONETIZATION SYSTEM - Real AdMob + IAP for Blockbuster Games
/// 
/// Features:
/// - 🛡️ Bulletproof ad system with 3-second timeout guarantee
/// - 💳 Real IAP with server-side validation
/// - 📊 Comprehensive analytics tracking
/// - 🎮 Never breaks user experience
class MonetizationManager extends ChangeNotifier {
  static final MonetizationManager _instance = MonetizationManager._internal();
  factory MonetizationManager() => _instance;
  MonetizationManager._internal();

  // Core systems
  final RealAdMobService _adMobService = RealAdMobService();
  final EnhancedIAPManager _enhancedIAP = EnhancedIAPManager();

  // Production mode settings
  bool _developmentMode = true;
  bool _adMobAvailable = true;

  // Getters
  bool get isAvailable => _enhancedIAP.isAvailable;
  bool get isPurchasing => _enhancedIAP.isPurchasing;
  bool get developmentMode => _developmentMode;
  bool get adMobAvailable => _adMobAvailable;
  bool get isRewardedAdLoaded => _adMobService.isAdLoaded;

  /// PRODUCTION initialization - Real AdMob + Enhanced IAP
  Future<void> initialize({
    InventoryManager? inventory,
    LivesManager? lives,
  }) async {
    try {
      safePrint('💰 🚀 Initializing MonetizationManager (PRODUCTION MODE - Real AdMob + Enhanced IAP)...');

      // Initialize real AdMob service
      await _adMobService.initialize();
      _adMobAvailable = _adMobService.isInitialized;

      // Initialize enhanced IAP system
      await _enhancedIAP.initialize(
        inventory: inventory,
        lives: lives,
      );

      // Set production mode based on build type
      _developmentMode = kDebugMode;

      safePrint('💰 ✅ MonetizationManager initialized successfully!');
      safePrint('💰 📊 Service Status: Dev Mode: $_developmentMode, Enhanced IAP: ${_enhancedIAP.isAvailable}, AdMob: $_adMobAvailable');
      safePrint('💰 📦 Available Products: ${_enhancedIAP.availableProducts.length}');
      
      if (_adMobAvailable) {
        final adStatus = _adMobService.getAdStatus();
        safePrint('📺 📊 AdMob Status: $adStatus');
      }
      
    } catch (e) {
      safePrint('💰 ❌ MonetizationManager initialization error: $e');
      // Set safe defaults
      _developmentMode = true;
      _adMobAvailable = false;
    }
    notifyListeners();
  }



  /// 🛡️ BULLETPROOF rewarded ad - PROPER UX FLOW
  /// 🎯 CRITICAL: Ad shows FIRST, then game continues (fixed UX issue)
  Future<void> showRewardedAdForExtraLife({
    required VoidCallback onReward,
    VoidCallback? onAdFailure, // Kept for interface compatibility but rarely used
    Function()? onAdStart, // 🎯 NEW: Called when ad starts (to pause game)
    Function()? onAdEnd, // 🎯 NEW: Called when ad ends (to resume game)
  }) async {
    try {
      safePrint('📺 🚀 BULLETPROOF: Starting ad flow - waiting for ad DISMISSAL before continuing');
      
      // 🎯 CRITICAL: Pause game BEFORE showing ad
      onAdStart?.call();
      
      // 🎯 CRITICAL FIX: Ad service now waits for ad DISMISSAL BEFORE returning
      // This ensures proper UX: Game Over → Show Ad → User Watches → User Dismisses → Continue Game
      final result = await _adMobService.showRewardedAd();
      
      // 🎯 CRITICAL: Resume game AFTER ad dismissal
      onAdEnd?.call();
      
      if (result.shouldGrantReward) {
        // Ad completed (or timed out with fallback) - now safe to continue game
        safePrint('📺 ✅ BULLETPROOF: Ad completed - now continuing game (${result.status.name})');
        safePrint('📺 ℹ️ CONTINUE AD: Only granting extra life - NO coins added (AdMob reward ignored for continue ads)');
        onReward();
        
        // NOTE: For continue ads, we ignore AdMob coin rewards and only grant extra life
        
        // Track all reward events for analytics
        trackPlayerEngagement({
          'event': 'rewarded_ad_reward_granted',
          'reward_type': result.rewardType ?? 'fallback',
          'reward_amount': result.rewardAmount ?? 1,
          'status': result.status.name,
          'was_real_ad': result.status == AdRewardStatus.success,
          'was_fallback': result.status == AdRewardStatus.timeoutFallback,
        });
        
      } else {
        // This should NEVER happen with bulletproof system, but just in case
        safePrint('📺 🚨 BULLETPROOF: Unexpected no-reward case - forcing reward');
        onReward(); // Force reward anyway for UX
        
        trackPlayerEngagement({
          'event': 'rewarded_ad_unexpected_failure',
          'reason': result.message,
          'status': result.status.name,
        });
      }
      
    } catch (e) {
      // Even if everything fails, NEVER break the user experience
      safePrint('📺 🛡️ BULLETPROOF: Exception caught - forcing reward for UX: $e');
      
      // 🎯 CRITICAL: Resume game even on exception
      onAdEnd?.call();
      
      onReward(); // Always grant reward
      
      trackPlayerEngagement({
        'event': 'rewarded_ad_system_error',
        'error': e.toString(),
        'reward_forced': true,
      });
    }
  }

  /// Track player engagement events to Firebase Analytics
  void trackPlayerEngagement(Map<String, dynamic> parameters) {
    try {
      // Extract event name from parameters
      final eventName = parameters['event'] as String? ?? 'unknown_event';
      final eventParameters = Map<String, dynamic>.from(parameters);
      eventParameters.remove('event'); // Remove event key from parameters
      
      // Send to Firebase Analytics
      FirebaseAnalyticsManager().trackEvent(eventName, eventParameters);
      
      safePrint('📊 ✅ Analytics event tracked: $eventName');
      safePrint('📊 📋 Event data: $eventParameters');
    } catch (e) {
      safePrint('📊 ❌ Failed to track analytics event: $e');
    }
  }

  // === ENHANCED IAP METHODS ===

  /// Get all available IAP products
  List<IAPProduct> getAvailableIAPProducts() {
    return _enhancedIAP.availableProducts;
  }

  /// Get IAP products by type
  List<IAPProduct> getIAPProductsByType(IAPProductType type) {
    return _enhancedIAP.availableProducts.where((p) => p.type == type).toList();
  }

  /// Purchase product using enhanced IAP system
  Future<PurchaseResult> purchaseIAPProduct(String productId) async {
    if (!_enhancedIAP.isAvailable) {
      return PurchaseResult.failed('Enhanced IAP not available');
    }

    return await _enhancedIAP.purchaseProduct(productId);
  }

  /// Get product details for display
  dynamic getIAPProductDetails(String productId) {
    return _enhancedIAP.getProductDetails(productId);
  }

  /// Check if IAP product is available
  bool isIAPProductAvailable(String productId) {
    return _enhancedIAP.isProductAvailable(productId);
  }

  /// Get popular products for featured display
  List<IAPProduct> getPopularIAPProducts() {
    return IAPProductCatalog.getPopularProducts()
        .where((p) => _enhancedIAP.isProductAvailable(p.id))
        .toList();
  }

  /// Get best value products
  List<IAPProduct> getBestValueIAPProducts() {
    return IAPProductCatalog.getBestValueProducts()
        .where((p) => _enhancedIAP.isProductAvailable(p.id))
        .toList();
  }

  /// Get impulse purchase products
  List<IAPProduct> getImpulseIAPProducts() {
    return IAPProductCatalog.getImpulseProducts()
        .where((p) => _enhancedIAP.isProductAvailable(p.id))
        .toList();
  }

  /// Restore purchases
  Future<void> restoreIAPPurchases() async {
    if (_enhancedIAP.isAvailable) {
      await _enhancedIAP.restorePurchases();
    }
  }

  /// Check if currently purchasing
  bool get isIAPPurchasing => _enhancedIAP.isPurchasing;

  @override
  void dispose() {
    _adMobService.dispose();
    _enhancedIAP.dispose();
    super.dispose();
  }
}

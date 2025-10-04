import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/debug_logger.dart';
import '../../services/unity_ads_service.dart';
import '../../services/enhanced_iap_manager.dart';
import '../core/iap_products.dart';
import 'inventory_manager.dart';
import 'lives_manager.dart';
import '../../core/analytics/unified_analytics_manager.dart';
import '../../core/analytics/comprehensive_analytics_manager.dart';

/// 🚀 PRODUCTION MONETIZATION SYSTEM - Unity Ads + AdMob Fallback + IAP
/// 
/// Features:
/// - 🎮 Unity Ads (gaming-focused, family-safe, $3-8 CPM)
/// - 📱 AdMob fallback (PG-rated only, $0.50-2 CPM)
/// - 💳 Real IAP with server-side validation
/// - 📊 Comprehensive analytics tracking
/// - 🎮 Never breaks user experience
class MonetizationManager extends ChangeNotifier {
  static final MonetizationManager _instance = MonetizationManager._internal();
  factory MonetizationManager() => _instance;
  MonetizationManager._internal();

  // Core systems
  final UnityAdsService _adService = UnityAdsService();
  final EnhancedIAPManager _enhancedIAP = EnhancedIAPManager();
  final UnifiedAnalyticsManager _analytics = UnifiedAnalyticsManager();

  // Production mode settings
  bool _developmentMode = true;
  bool _adServiceAvailable = true;
  bool _isAdLoading = false;
  
  // Context management for dialogs
  BuildContext? _currentContext;

  // Getters
  bool get isAvailable => _enhancedIAP.isAvailable;
  bool get isPurchasing => _enhancedIAP.isPurchasing;
  bool get developmentMode => _developmentMode;
  bool get adMobAvailable => _adServiceAvailable; // Keep for backward compatibility
  bool get isRewardedAdLoaded => _adService.isAdReady;
  bool get isAdLoading => _isAdLoading;
  
  /// Set ad loading state (used to prevent navigation during ad loading)
  void setAdLoading(bool loading) {
    _isAdLoading = loading;
    notifyListeners();
  }
  
  /// Set current context for dialogs
  void setContext(BuildContext context) {
    _currentContext = context;
  }

  /// PRODUCTION initialization - Unity Ads + AdMob Fallback + Enhanced IAP
  Future<void> initialize({
    InventoryManager? inventory,
    LivesManager? lives,
  }) async {
    try {
      safePrint('💰 🚀 Initializing MonetizationManager (Unity Ads + AdMob Fallback + Enhanced IAP)...');

      // Initialize Unity Ads service (includes AdMob fallback)
      await _adService.initialize();
      _adServiceAvailable = _adService.isInitialized;

      // Initialize enhanced IAP system
      await _enhancedIAP.initialize(
        inventory: inventory,
        lives: lives,
      );

      // Set production mode based on build type
      _developmentMode = kDebugMode;

      safePrint('💰 ✅ MonetizationManager initialized successfully!');
      safePrint('💰 📊 Service Status: Dev Mode: $_developmentMode, Enhanced IAP: ${_enhancedIAP.isAvailable}, Ad Service: $_adServiceAvailable');
      safePrint('💰 📦 Available Products: ${_enhancedIAP.availableProducts.length}');
      
      if (_adServiceAvailable) {
        safePrint('📺 📊 Ad Service Status: Initialized = $_adServiceAvailable');
      }
      
    } catch (e) {
      safePrint('💰 ❌ MonetizationManager initialization error: $e');
      // Set safe defaults
      _developmentMode = true;
      _adServiceAvailable = false;
    }
    notifyListeners();
  }



  /// 🛡️ BULLETPROOF rewarded ad - Unity Ads + AdMob Fallback
  /// 🎯 CRITICAL: Ad shows FIRST, then game continues (proper UX flow)
  Future<void> showRewardedAdForExtraLife({
    required VoidCallback onReward,
    VoidCallback? onAdFailure, // Kept for interface compatibility
    Function()? onAdStart, // 🎯 Called when ad starts (to pause game)
    Function()? onAdEnd, // 🎯 Called when ad ends (to resume game)
    Function()? onAdLoading, // 🎯 Called when ad is loading
  }) async {
    try {
      safePrint('📺 🚀 Starting ad flow (Unity Ads + AdMob fallback)...');
      
      // 🎯 CRITICAL: Set loading state to prevent user interaction
      _isAdLoading = true;
      notifyListeners();
      
      // 🎯 CRITICAL: Pause game BEFORE showing ad
      onAdStart?.call();
      
      // Show loading indicator if ad is not ready
      // Check if ad is pre-loaded and ready
      if (!_adService.isAdReady) {
        // 🚀 Ad should be pre-loaded from initialization or after previous ad
        // But if not (edge case), load it now
        safePrint('📺 ⚠️ Ad not pre-loaded (edge case) - loading now...');
        onAdLoading?.call();
        await _adService.loadRewardedAd();
        
        // Wait briefly for ad to load (Unity Ads usually takes 2-5s)
        int retries = 0;
        while (!_adService.isAdReady && retries < 20) {
          await Future.delayed(const Duration(milliseconds: 500));
          retries++;
          safePrint('📺 ⏳ Waiting for ad to load... (${retries * 0.5}s)');
        }
        
        if (!_adService.isAdReady) {
          safePrint('📺 ⏱️ Ad load timeout after 10s');
          onAdFailure?.call();
          _isAdLoading = false;
          notifyListeners();
          return;
        }
      } else {
        safePrint('📺 ✅ Ad is pre-loaded and ready to show!');
      }
      
      // Set up callbacks for ad events
      bool rewardGranted = false;
      bool adSkippedEarly = false;
      
      // ⚠️ CRITICAL: Use Completer to wait for ad to fully close
      final Completer<void> adClosedCompleter = Completer<void>();
      
      _adService.onAdShown = () {
        safePrint('📺 🎬 Ad showing...');
        // Track ad shown event
        ComprehensiveAnalyticsManager().trackAdShown(adType: 'rewarded');
      };
      
      _adService.onAdRewardGranted = () {
        safePrint('📺 ✅ Ad completed - Reward granted!');
        rewardGranted = true;
        
        // Track successful completion
        ComprehensiveAnalyticsManager().trackAdCompleted(
          adType: 'rewarded',
          rewardType: 'heart',
          rewardAmount: 1,
        );
        
        trackPlayerEngagement({
          'event': 'rewarded_ad_reward_granted',
          'reward_type': 'heart',
          'reward_amount': 1,
          'provider': _adService.currentProviderName ?? 'unknown',
        });
      };
      
      // ⚠️ CRITICAL: Handle early exit (user pressed back before ad completed)
      _adService.onAdSkippedEarly = () {
        safePrint('📺 ⚠️ Ad skipped early - NO REWARD');
        adSkippedEarly = true;
        
        // Track early exit
        ComprehensiveAnalyticsManager().trackAdAbandoned(
          adType: 'rewarded',
          reason: 'User exited before completion',
        );
        
        trackPlayerEngagement({
          'event': 'rewarded_ad_early_exit',
          'reason': 'User pressed back',
          'provider': _adService.currentProviderName ?? 'unknown',
        });
      };
      
      _adService.onAdClosed = () {
        safePrint('📺 Ad closed');
        // ✅ Complete when ad is fully closed
        if (!adClosedCompleter.isCompleted) {
          adClosedCompleter.complete();
        }
      };
      
      _adService.onAdFailedToLoad = (error) {
        safePrint('📺 ❌ Ad failed to load: $error');
        onAdFailure?.call();
        // Complete on failure too
        if (!adClosedCompleter.isCompleted) {
          adClosedCompleter.complete();
        }
      };
      
      // Show the ad
      await _adService.showRewardedAd();
      
      // ⚠️ CRITICAL: Wait for ad to FULLY close before checking reward status
      safePrint('📺 ⏳ Waiting for ad to close...');
      await adClosedCompleter.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          safePrint('📺 ⏱️ Ad close timeout - proceeding anyway');
        },
      );
      safePrint('📺 ✅ Ad closed - checking reward status...');
      
      // 🎯 CRITICAL: Resume game AFTER ad
      onAdEnd?.call();
      
      // 🎯 CRITICAL: Clear loading state
      _isAdLoading = false;
      notifyListeners();
      
      // Handle result
      if (rewardGranted) {
        // ✅ Ad completed successfully - grant reward
        safePrint('📺 ✅ Ad completed - granting extra life');
        onReward();
      } else if (adSkippedEarly) {
        // ⚠️ CRITICAL: User exited early - show popup explaining no reward
        safePrint('📺 ⚠️ Ad skipped early - showing explanation popup');
        await _showEarlyExitConfirmationDialog('You need to complete the ad to get your reward');
      } else {
        // Ad failed or was closed without completion
        safePrint('📺 ℹ️ Ad closed without reward');
        onAdFailure?.call();
      }
      
    } catch (e) {
      // Even if everything fails, NEVER break the user experience
      safePrint('📺 🛡️ Exception caught in ad flow: $e');
      
      // 🎯 CRITICAL: Resume game even on exception
      onAdEnd?.call();
      
      // 🎯 CRITICAL: Clear loading state even on exception
      _isAdLoading = false;
      notifyListeners();
      
      // Show error to user
      onAdFailure?.call();
      
      trackPlayerEngagement({
        'event': 'rewarded_ad_system_error',
        'error': e.toString(),
      });
    }
  }

  /// Track player engagement events to both Firebase and Railway Analytics
  void trackPlayerEngagement(Map<String, dynamic> parameters) {
    try {
      // Extract event name from parameters
      final eventName = parameters['event'] as String? ?? 'unknown_event';
      final eventParameters = Map<String, dynamic>.from(parameters);
      eventParameters.remove('event'); // Remove event key from parameters
      
      // 📊 Send to both Firebase and Railway Analytics via UnifiedAnalyticsManager
      _analytics.trackEvent(eventName, eventParameters);
      
      safePrint('📊 ✅ Analytics event tracked to Railway + Firebase: $eventName');
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
      // Track IAP unavailable
      _analytics.trackEvent('iap_unavailable', {
        'product_id': productId,
        'reason': 'enhanced_iap_not_available',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      return PurchaseResult.failed('Enhanced IAP not available');
    }

    // Track purchase attempt
    _analytics.trackEvent('iap_purchase_attempt', {
      'product_id': productId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    final result = await _enhancedIAP.purchaseProduct(productId);
    
    // Track purchase result
    if (result.isSuccess) {
      // Get product details for analytics
      final productDetails = _enhancedIAP.getProductDetails(productId);
      final price = productDetails?.price ?? 0.0;
      
      _analytics.trackPurchase(
        itemId: productId,
        itemName: productId,
        price: price is double ? price : 0.0,
        currency: 'USD',
        purchaseType: 'real_money',
      );
      
      safePrint('💰 ✅ IAP Purchase successful: $productId for \$${(price is double ? price : 0.0).toStringAsFixed(2)}');
    } else {
      _analytics.trackEvent('iap_purchase_failed', {
        'product_id': productId,
        'error': result.message ?? 'Unknown error',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      
      safePrint('💰 ❌ IAP Purchase failed: $productId - ${result.message ?? 'Unknown error'}');
    }

    return result;
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

  /// Show confirmation dialog for early ad exit
  Future<void> _showEarlyExitConfirmationDialog(String reason) async {
    try {
      // Get the current context
      final context = _currentContext;
      if (context == null) {
        safePrint('📺 ⚠️ No context available for early exit dialog');
        return;
      }

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text(
            'Ad Not Completed',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 48,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              const Text(
                'You need to watch the entire ad to get your extra heart.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Reason: $reason',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                safePrint('📺 User confirmed early exit - no reward granted');
              },
              child: const Text(
                'Continue Without Heart',
                style: TextStyle(color: Colors.red),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                safePrint('📺 User wants to watch ad again');
                // Note: The ad service will handle showing another ad
                // This is just for user feedback
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Watch Ad Again'),
            ),
          ],
        ),
      );
    } catch (e) {
      safePrint('📺 ❌ Error showing early exit dialog: $e');
    }
  }

  @override
  void dispose() {
    _adService.dispose();
    _enhancedIAP.dispose();
    super.dispose();
  }
}

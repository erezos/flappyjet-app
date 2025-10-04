/// 💳 Enhanced IAP Manager - Production-ready In-App Purchase system
/// Handles complete FlappyJet product catalog with server-side validation
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:http/http.dart' as http;
import '../core/debug_logger.dart';
import '../game/core/iap_products.dart';
import '../game/systems/inventory_manager.dart';
import '../game/systems/lives_manager.dart';
import '../game/systems/firebase_analytics_manager.dart';
import '../game/systems/player_identity_manager.dart';
import '../core/analytics/comprehensive_analytics_manager.dart';
import '../config/iap_config.dart';
import 'iap_receipt_validator.dart';
import 'inventory_sync_service.dart';

/// Purchase result enumeration
enum PurchaseResultStatus {
  success,
  cancelled,
  failed,
  pending,
  alreadyOwned,
  invalidProduct,
  networkError,
  validationFailed,
}

/// Purchase result data class
class PurchaseResult {
  final PurchaseResultStatus status;
  final String? message;
  final IAPProduct? product;
  final PurchaseDetails? purchaseDetails;
  final Map<String, dynamic>? analytics;

  const PurchaseResult({
    required this.status,
    this.message,
    this.product,
    this.purchaseDetails,
    this.analytics,
  });

  bool get isSuccess => status == PurchaseResultStatus.success;
  bool get isCancelled => status == PurchaseResultStatus.cancelled;
  bool get isPending => status == PurchaseResultStatus.pending;
  bool get isFailed => !isSuccess && !isCancelled && !isPending;

  factory PurchaseResult.success(IAPProduct product, [PurchaseDetails? details]) {
    return PurchaseResult(
      status: PurchaseResultStatus.success,
      product: product,
      purchaseDetails: details,
      message: 'Purchase completed successfully',
    );
  }

  factory PurchaseResult.cancelled() {
    return const PurchaseResult(
      status: PurchaseResultStatus.cancelled,
      message: 'Purchase cancelled by user',
    );
  }

  factory PurchaseResult.failed(String message) {
    return PurchaseResult(
      status: PurchaseResultStatus.failed,
      message: message,
    );
  }

  factory PurchaseResult.pending() {
    return const PurchaseResult(
      status: PurchaseResultStatus.pending,
      message: 'Purchase is being processed',
    );
  }
}

/// Enhanced IAP Manager with complete product catalog support
class EnhancedIAPManager extends ChangeNotifier {
  static final EnhancedIAPManager _instance = EnhancedIAPManager._internal();
  factory EnhancedIAPManager() => _instance;
  EnhancedIAPManager._internal();

  // Core systems
  final InAppPurchase _iap = InAppPurchase.instance;
  final IAPReceiptValidator _validator = IAPReceiptValidator();
  final FirebaseAnalyticsManager _analytics = FirebaseAnalyticsManager();

  // Dependencies
  InventoryManager? _inventory;
  LivesManager? _lives;

  // State management
  bool _isInitialized = false;
  bool _isAvailable = false;
  bool _isPurchasing = false;
  Map<String, ProductDetails> _products = {};
  Map<String, PurchaseDetails> _pendingPurchases = {};
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  
  // Caching to prevent repeated checks
  bool? _availabilityCache;
  DateTime? _lastAvailabilityCheck;
  
  // 🔥 CRITICAL: Purchase state management to prevent backend overwrite
  bool _isProcessingPurchase = false;
  DateTime? _lastPurchaseTime;

  // Purchase tracking
  final Map<String, DateTime> _purchaseAttempts = {};
  final Set<String> _validatedPurchases = {};
  final Map<String, int> _failureCount = {};

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isAvailable => _isAvailable;
  bool get isPurchasing => _isPurchasing;
  Map<String, ProductDetails> get products => Map.unmodifiable(_products);
  List<IAPProduct> get availableProducts => _getAvailableIAPProducts();
  
  /// 🔥 CRITICAL: Check if we're currently processing a purchase (prevents backend overwrite)
  bool get isProcessingPurchase => _isProcessingPurchase;
  
  /// 🔥 CRITICAL: Check if we recently completed a purchase (prevents backend overwrite for 30 seconds)
  bool get isRecentlyPurchased {
    if (_lastPurchaseTime == null) return false;
    final timeSincePurchase = DateTime.now().difference(_lastPurchaseTime!);
    return timeSincePurchase.inSeconds < 30; // 30 second grace period
  }

  /// Initialize the IAP system
  Future<void> initialize({
    InventoryManager? inventory,
    LivesManager? lives,
  }) async {
    if (_isInitialized) return;

    // Initialize receipt validator with configuration
    _validator.initialize(
      appleSharedSecret: IAPConfig.appleSharedSecret,
      androidPackageName: IAPConfig.androidPackageName,
    );
    
    // Log configuration status
    safePrint('🔐 Apple IAP configured: ${IAPConfig.isAppleConfigured}');
    safePrint('🔐 Android IAP configured: ${IAPConfig.isAndroidConfigured}');

    try {
      // Set dependencies
      _inventory = inventory;
      _lives = lives;

      // Check IAP availability with enhanced detection
      _isAvailable = await _checkIAPAvailability();

      if (!_isAvailable) {
        safePrint('💳 ⚠️ IAP not available - ${await _getIAPUnavailableReason()}');
        _isInitialized = true;
        notifyListeners();
        return;
      }

      // Set up purchase stream
      _subscription = _iap.purchaseStream.listen(
        _handlePurchaseUpdates,
        onDone: () => _subscription?.cancel(),
        onError: (error) {
          safePrint('💳 ❌ IAP Stream Error: $error');
          _trackPurchaseEvent('iap_stream_error', {'error': error.toString()});
        },
      );

      // Load products and restore purchases
      await _loadProducts();
      await restorePurchases();

      _isInitialized = true;
      safePrint('💳 ✅ Enhanced IAP Manager initialized successfully!');
      safePrint('💳 📊 Loaded ${_products.length} products');

      // Track initialization
      await _trackPurchaseEvent('iap_initialized', {
        'products_loaded': _products.length,
        'platform': Platform.isIOS ? 'ios' : 'android',
      });

    } catch (e) {
      safePrint('💳 ❌ IAP initialization failed: $e');
      _isAvailable = false;
      _isInitialized = true;
      
      await _trackPurchaseEvent('iap_init_failed', {
        'error': e.toString(),
      });
    }

    notifyListeners();
  }

  /// Load all products from the catalog
  Future<void> _loadProducts() async {
    try {
      final storeIds = IAPProductCatalog.getAllStoreIds();
      // Load products silently

      final response = await _iap.queryProductDetails(storeIds);
      
      if (response.error != null) {
        safePrint('💳 ❌ Error loading products: ${response.error!.message}');
        await _trackPurchaseEvent('products_load_failed', {
          'error': response.error!.message,
          'error_code': response.error!.code,
        });
        return;
      }

      // Map products by store ID
      _products.clear();
      for (final product in response.productDetails) {
        _products[product.id] = product;
      }

      // Check for missing products
      final loadedIds = _products.keys.toSet();
      final missingIds = storeIds.difference(loadedIds);
      if (missingIds.isNotEmpty) {
        safePrint('💳 ⚠️ Missing products: $missingIds');
        await _trackPurchaseEvent('products_missing', {
          'missing_products': missingIds.toList(),
          'loaded_count': loadedIds.length,
          'expected_count': storeIds.length,
        });
      }

    } catch (e) {
      safePrint('💳 ❌ Product loading error: $e');
      await _trackPurchaseEvent('products_load_error', {
        'error': e.toString(),
      });
    }
  }

  /// Get available IAP products with pricing
  List<IAPProduct> _getAvailableIAPProducts() {
    final availableProducts = <IAPProduct>[];
    
    for (final iapProduct in IAPProductCatalog.getAllProducts().values) {
      final storeProduct = _products[iapProduct.storeId];
      if (storeProduct != null) {
        availableProducts.add(iapProduct);
      }
    }
    
    return availableProducts;
  }

  /// Purchase a product by ID
  Future<PurchaseResult> purchaseProduct(String productId) async {
    if (!_isAvailable || _isPurchasing) {
      return PurchaseResult.failed('IAP not available or purchase in progress');
    }

    final iapProduct = IAPProductCatalog.getProductById(productId);
    if (iapProduct == null) {
      return PurchaseResult.failed('Product not found: $productId');
    }

    // Check if we're in emulator simulation mode
    if (kDebugMode && await _isRunningOnEmulator()) {
      return await _simulateEmulatorPurchase(iapProduct);
    }

    final storeProduct = _products[iapProduct.storeId];
    if (storeProduct == null) {
      return PurchaseResult.failed('Store product not available: ${iapProduct.storeId}');
    }

    // Track purchase attempt
    _purchaseAttempts[productId] = DateTime.now();
    await _trackPurchaseEvent('purchase_initiated', {
      'product_id': productId,
      'product_type': iapProduct.type.name,
      'price_usd': iapProduct.priceUSD,
    });

    _isPurchasing = true;
    notifyListeners();

    try {
      final purchaseParam = PurchaseParam(productDetails: storeProduct);
      
      // Use appropriate purchase method based on product type
      if (iapProduct.type == IAPProductType.jetSkin) {
        // Non-consumable for permanent items
        await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      } else {
        // Consumable for gems, boosters, etc.
        await _iap.buyConsumable(purchaseParam: purchaseParam);
      }

      // Return pending - actual result comes through stream
      return PurchaseResult.pending();

    } catch (e) {
      _isPurchasing = false;
      notifyListeners();
      
      final errorMessage = 'Purchase failed: $e';
      safePrint('💳 ❌ $errorMessage');
      
      await _trackPurchaseEvent('purchase_failed', {
        'product_id': productId,
        'error': e.toString(),
      });
      
      return PurchaseResult.failed(errorMessage);
    }
  }

  /// Handle purchase updates from the stream
  void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      _processPurchaseUpdate(purchaseDetails);
    }
  }

  /// Process individual purchase update
  Future<void> _processPurchaseUpdate(PurchaseDetails purchaseDetails) async {
    safePrint('💳 📦 Processing purchase: ${purchaseDetails.productID} - ${purchaseDetails.status}');

    // Use the original product ID directly - no mapping needed
    // The product IDs in the purchase stream should match our storeId values
    final mappedPurchaseDetails = PurchaseDetails(
      productID: purchaseDetails.productID,
      transactionDate: purchaseDetails.transactionDate,
      status: purchaseDetails.status,
      verificationData: purchaseDetails.verificationData,
      purchaseID: purchaseDetails.purchaseID,
    );

    switch (purchaseDetails.status) {
      case PurchaseStatus.pending:
        await _handlePendingPurchase(mappedPurchaseDetails);
        break;
      case PurchaseStatus.purchased:
        await _handleSuccessfulPurchase(mappedPurchaseDetails);
        break;
      case PurchaseStatus.error:
        await _handleFailedPurchase(mappedPurchaseDetails);
        break;
      case PurchaseStatus.restored:
        await _handleRestoredPurchase(mappedPurchaseDetails);
        break;
      case PurchaseStatus.canceled:
        await _handleCancelledPurchase(mappedPurchaseDetails);
        break;
    }

    // Complete the purchase if needed
    if (mappedPurchaseDetails.pendingCompletePurchase) {
      await _iap.completePurchase(mappedPurchaseDetails);
    }

    _isPurchasing = false;
    notifyListeners();
  }

  /// Handle pending purchase
  Future<void> _handlePendingPurchase(PurchaseDetails purchaseDetails) async {
    _pendingPurchases[purchaseDetails.productID] = purchaseDetails;
    
    await _trackPurchaseEvent('purchase_pending', {
      'product_id': purchaseDetails.productID,
      'transaction_id': purchaseDetails.purchaseID,
    });
    
    safePrint('💳 ⏳ Purchase pending: ${purchaseDetails.productID}');
  }

  /// Handle successful purchase
  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) async {
    try {
      // 🔥 CRITICAL: Set processing flag to prevent backend overwrite
      _isProcessingPurchase = true;
      
      // Find the IAP product
      final iapProduct = IAPProductCatalog.getProductByStoreId(purchaseDetails.productID);
      if (iapProduct == null) {
        safePrint('💳 ❌ Unknown product purchased: ${purchaseDetails.productID}');
        _isProcessingPurchase = false; // Reset flag on error
        return;
      }

      // Validate receipt with server
      safePrint('💳 🔐 Starting receipt validation for: ${purchaseDetails.productID}');
      final validationResult = await _validator.validatePurchase(
        purchaseDetails: purchaseDetails,
        platform: Platform.isIOS ? 'ios' : 'android',
      );

      safePrint('💳 🔐 Validation result: valid=${validationResult.isValid}, method=${validationResult.validationMethod}, error=${validationResult.error}');

      if (!validationResult.isValid) {
        safePrint('💳 ❌ Purchase validation failed: ${validationResult.error}');
        
        // For sandbox testing, allow offline validation as fallback
        if (kDebugMode) {
          safePrint('💳 🧪 Debug mode: Trying offline validation as fallback...');
          final offlineResult = _validator.validateOffline(purchaseDetails);
          if (offlineResult.isValid) {
            safePrint('💳 ✅ Offline validation passed - proceeding with purchase');
          } else {
            safePrint('💳 ❌ Offline validation also failed: ${offlineResult.error}');
            await _trackPurchaseEvent('purchase_validation_failed', {
              'product_id': iapProduct.id,
              'error': validationResult.error,
              'transaction_id': purchaseDetails.purchaseID,
            });
            _isProcessingPurchase = false; // Reset flag on error
            return;
          }
        } else {
          await _trackPurchaseEvent('purchase_validation_failed', {
            'product_id': iapProduct.id,
            'error': validationResult.error,
            'transaction_id': purchaseDetails.purchaseID,
          });
          _isProcessingPurchase = false; // Reset flag on error
          return;
        }
      }

      // Grant the purchased items
      await _grantPurchaseRewards(iapProduct, purchaseDetails);

      // Mark as validated
      _validatedPurchases.add(purchaseDetails.purchaseID ?? '');
      _pendingPurchases.remove(purchaseDetails.productID);

      // Track successful purchase
      await _trackPurchaseEvent('purchase_completed', {
        'product_id': iapProduct.id,
        'product_type': iapProduct.type.name,
        'price_usd': iapProduct.priceUSD,
        'transaction_id': purchaseDetails.purchaseID,
        'validation_method': validationResult.validationMethod,
      });

      // Track comprehensive analytics for IAP purchase
      try {
        await ComprehensiveAnalyticsManager().trackIAPPurchase(
          productId: iapProduct.id,
          productType: iapProduct.type.name,
          priceUsd: iapProduct.priceUSD,
          currency: 'USD',
          success: true,
        );
      } catch (e) {
        safePrint('⚠️ Failed to track comprehensive IAP analytics: $e');
      }

      safePrint('💳 ✅ Purchase completed: ${iapProduct.displayName}');
      
      // 🔥 CRITICAL: Set completion flags to prevent backend overwrite
      _isProcessingPurchase = false;
      _lastPurchaseTime = DateTime.now();
      safePrint('💳 🔒 Purchase processing completed - backend protection active for 30 seconds');

    } catch (e) {
      safePrint('💳 ❌ Error processing successful purchase: $e');
      await _trackPurchaseEvent('purchase_processing_error', {
        'product_id': purchaseDetails.productID,
        'error': e.toString(),
      });
      
      // 🔥 CRITICAL: Reset processing flag on error
      _isProcessingPurchase = false;
    }
  }

  /// Grant rewards for purchased product
  Future<void> _grantPurchaseRewards(IAPProduct product, PurchaseDetails? purchaseDetails) async {
    try {
      safePrint('💳 🎁 Starting reward granting for: ${product.displayName}');
      safePrint('💳 🎁 Product details: gems=${product.totalGems}, coins=${product.totalCoins}, hearts=${product.hearts}, booster=${product.heartBoosterHours}h, skin=${product.jetSkinId}');
      
      // Grant gems
      if (product.totalGems > 0 && _inventory != null) {
        safePrint('💳 💎 Granting ${product.totalGems} gems...');
        await _inventory!.grantGems(product.totalGems);
        safePrint('💳 💎 Granted ${product.totalGems} gems');
        
        // 🔥 CRITICAL: Sync gems to backend after IAP purchase
        try {
          await _syncGemsToBackend();
          safePrint('💳 🔄 Gems synced to backend after IAP purchase: ${product.totalGems} gems');
        } catch (syncError) {
          safePrint('💳 ⚠️ Failed to sync gems to backend after purchase: $syncError');
          // Don't fail the purchase if sync fails - gems are still granted locally
        }
      }

      // Grant coins
      if (product.totalCoins > 0 && _inventory != null) {
        await _inventory!.addCoinsWithAnimation(product.totalCoins);
        safePrint('💳 🪙 Granted ${product.totalCoins} coins');
      }

      // Grant hearts
      if (product.hearts > 0 && _lives != null) {
        for (int i = 0; i < product.hearts; i++) {
          await _lives!.addLife();
        }
        safePrint('💳 ❤️ Granted ${product.hearts} hearts');
      }

      // Activate heart booster
      if (product.heartBoosterHours > 0 && _inventory != null) {
        await _inventory!.activateHeartBooster(Duration(hours: product.heartBoosterHours));
        // Refill hearts to new maximum when booster is activated
        if (_lives != null) {
          await _lives!.refillToMax();
        }
        safePrint('💳 ⚡ Activated ${product.heartBoosterHours}h heart booster');
      }

      // Unlock jet skin
      if (product.jetSkinId != null && _inventory != null) {
        await _inventory!.unlockSkin(product.jetSkinId!);
        safePrint('💳 🚁 Unlocked jet skin: ${product.jetSkinId}');
        
        // 🔥 NEW: Sync skin to backend
        try {
          final inventorySyncService = InventorySyncService();
          await inventorySyncService.syncSkin(
            product.jetSkinId!,
            equipped: false,
            acquiredMethod: 'iap_purchase',
          );
          safePrint('💳 🔄 Jet skin synced to backend: ${product.jetSkinId}');
        } catch (syncError) {
          safePrint('💳 ⚠️ Failed to sync jet skin to backend: $syncError');
          // Don't fail the purchase if sync fails - skin is still unlocked locally
        }
      }

    } catch (e) {
      safePrint('💳 ❌ Error granting purchase rewards: $e');
      rethrow;
    }
  }

  /// Handle failed purchase
  Future<void> _handleFailedPurchase(PurchaseDetails purchaseDetails) async {
    final error = purchaseDetails.error;
    safePrint('💳 ❌ Purchase failed: ${error?.message}');

    _failureCount[purchaseDetails.productID] = 
        (_failureCount[purchaseDetails.productID] ?? 0) + 1;

    await _trackPurchaseEvent('purchase_failed', {
      'product_id': purchaseDetails.productID,
      'error_code': error?.code,
      'error_message': error?.message,
      'failure_count': _failureCount[purchaseDetails.productID],
    });
  }

  /// Handle cancelled purchase
  Future<void> _handleCancelledPurchase(PurchaseDetails purchaseDetails) async {
    safePrint('💳 🚫 Purchase cancelled: ${purchaseDetails.productID}');

    await _trackPurchaseEvent('purchase_cancelled', {
      'product_id': purchaseDetails.productID,
    });
  }

  /// Handle restored purchase
  Future<void> _handleRestoredPurchase(PurchaseDetails purchaseDetails) async {
    safePrint('💳 🔄 Purchase restored: ${purchaseDetails.productID}');
    
    // Process as successful purchase
    await _handleSuccessfulPurchase(purchaseDetails);
    
    await _trackPurchaseEvent('purchase_restored', {
      'product_id': purchaseDetails.productID,
    });
  }

  /// Restore previous purchases
  Future<void> restorePurchases() async {
    try {
      safePrint('💳 🔄 Restoring purchases...');
      await _iap.restorePurchases();
      
      await _trackPurchaseEvent('purchases_restore_initiated', {});
      
    } catch (e) {
      safePrint('💳 ❌ Error restoring purchases: $e');
      await _trackPurchaseEvent('purchases_restore_failed', {
        'error': e.toString(),
      });
    }
  }

  /// Track purchase analytics event
  Future<void> _trackPurchaseEvent(String eventName, Map<String, dynamic> parameters) async {
    try {
      await _analytics.trackEvent('iap_$eventName', {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'platform': Platform.isIOS ? 'ios' : 'android',
        ...parameters,
      });
    } catch (e) {
      safePrint('💳 ⚠️ Failed to track purchase event: $e');
    }
  }

  /// Get product details for display
  ProductDetails? getProductDetails(String productId) {
    final iapProduct = IAPProductCatalog.getProductById(productId);
    if (iapProduct == null) return null;
    
    return _products[iapProduct.storeId];
  }

  /// Check if product is available for purchase
  bool isProductAvailable(String productId) {
    final iapProduct = IAPProductCatalog.getProductById(productId);
    if (iapProduct == null) return false;
    
    return _products.containsKey(iapProduct.storeId);
  }

  /// Enhanced IAP availability check with better emulator/device detection
  Future<bool> _checkIAPAvailability() async {
    try {
      // Use cache if available and recent (within 30 seconds)
      if (_availabilityCache != null && 
          _lastAvailabilityCheck != null && 
          DateTime.now().difference(_lastAvailabilityCheck!).inSeconds < 30) {
        return _availabilityCache!;
      }
      
      // First check the basic IAP availability
      final basicAvailability = await _iap.isAvailable();
      
      if (basicAvailability) {
        _availabilityCache = true;
        _lastAvailabilityCheck = DateTime.now();
        return true; // Real device with IAP support
      }
      
      // Check if we're on an emulator
      final isEmulator = await _isRunningOnEmulator();
      
      if (isEmulator) {
        // On emulator, only enable IAP simulation in debug mode
        if (kDebugMode) {
          _availabilityCache = true;
          _lastAvailabilityCheck = DateTime.now();
          safePrint('💳 🧪 IAP simulation enabled for emulator (debug mode)');
          return true;
        } else {
          _availabilityCache = false;
          _lastAvailabilityCheck = DateTime.now();
          safePrint('💳 ⚠️ IAP not available on emulator (release mode)');
          return false;
        }
      }
      
      // Real device without IAP support
      _availabilityCache = false;
      _lastAvailabilityCheck = DateTime.now();
      return false;
      
    } catch (e) {
      safePrint('💳 ❌ Error checking IAP availability: $e');
      _availabilityCache = false;
      _lastAvailabilityCheck = DateTime.now();
      return false;
    }
  }
  
  /// Detect if running on emulator
  Future<bool> _isRunningOnEmulator() async {
    try {
      if (Platform.isAndroid) {
        // Check common Android emulator indicators
        final brand = Platform.environment['ro.product.brand'] ?? '';
        final model = Platform.environment['ro.product.model'] ?? '';
        final device = Platform.environment['ro.product.device'] ?? '';
        final manufacturer = Platform.environment['ro.product.manufacturer'] ?? '';
        
        // More comprehensive emulator detection
        final emulatorIndicators = [
          'generic', 'emulator', 'sdk', 'google_sdk', 'droid4x',
          'genymotion', 'vbox', 'virtualbox', 'andy', 'nox'
        ];
        
        final deviceInfo = '${brand}_${model}_${device}_${manufacturer}'.toLowerCase();
        
        for (final indicator in emulatorIndicators) {
          if (deviceInfo.contains(indicator)) {
            return true;
          }
        }
        
        // Check for specific emulator patterns
        if (model.toLowerCase().contains('sdk') || 
            device.toLowerCase().contains('generic') ||
            brand.toLowerCase().contains('generic')) {
          return true;
        }
      } else if (Platform.isIOS) {
        // iOS Simulator detection
        return Platform.environment['SIMULATOR_DEVICE_NAME'] != null;
      }
    } catch (e) {
      safePrint('💳 ⚠️ Could not detect emulator status: $e');
    }
    return false;
  }
  
  /// Get detailed reason why IAP is unavailable
  Future<String> _getIAPUnavailableReason() async {
    try {
      final isEmulator = await _isRunningOnEmulator();
      
      if (isEmulator) {
        return 'Running on emulator (IAP simulation ${kDebugMode ? 'enabled' : 'disabled'})';
      }
      
      if (Platform.isAndroid) {
        return 'Google Play Store not available or device not supported';
      } else if (Platform.isIOS) {
        return 'App Store not available or device not supported';
      }
      
      return 'In-app purchases not supported on this platform';
    } catch (e) {
      return 'Unknown IAP availability issue: $e';
    }
  }

  /// Simulate purchase on emulator for development/testing
  Future<PurchaseResult> _simulateEmulatorPurchase(IAPProduct iapProduct) async {
    safePrint('💳 🧪 Simulating purchase on emulator: ${iapProduct.displayName}');
    
    _isPurchasing = true;
    notifyListeners();
    
    // Simulate purchase delay
    await Future.delayed(const Duration(milliseconds: 1500));
    
    try {
      // Grant rewards directly (skip server validation on emulator)
      await _grantPurchaseRewards(iapProduct, null);
      
      // Track simulated purchase
      await _trackPurchaseEvent('purchase_simulated', {
        'product_id': iapProduct.id,
        'product_type': iapProduct.type.name,
        'price_usd': iapProduct.priceUSD,
        'platform': 'emulator',
      });
      
      _isPurchasing = false;
      notifyListeners();
      
      safePrint('💳 ✅ Emulator purchase simulation completed: ${iapProduct.displayName}');
      return PurchaseResult.success(iapProduct, null);
      
    } catch (e) {
      _isPurchasing = false;
      notifyListeners();
      
      safePrint('💳 ❌ Emulator purchase simulation failed: $e');
      return PurchaseResult.failed('Simulation failed: $e');
    }
  }

  /// 🔥 CRITICAL: Sync gems to backend after IAP purchase
  Future<void> _syncGemsToBackend() async {
    try {
      final playerIdentityManager = PlayerIdentityManager();
      if (!playerIdentityManager.isAuthenticated) {
        safePrint('💳 ⚠️ Cannot sync gems to backend - not authenticated');
        return;
      }

      final token = playerIdentityManager.authToken;
      if (token.isEmpty) return;

      final response = await http.put(
        Uri.parse('https://flappyjet-backend-production.up.railway.app/api/player/sync-currency'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'coins': _inventory?.softCurrency ?? 0,
          'gems': _inventory?.gems ?? 0,
          'syncReason': 'iap_purchase',
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        safePrint('💳 ✅ Gems synced to backend after IAP purchase: ${_inventory?.gems ?? 0} gems');
      } else {
        safePrint('💳 ⚠️ Failed to sync gems to backend: ${response.statusCode}');
      }
    } catch (e) {
      safePrint('💳 ❌ Error syncing gems to backend: $e');
      // Don't throw - local functionality should work even if backend sync fails
    }
  }

  /// Dispose resources
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

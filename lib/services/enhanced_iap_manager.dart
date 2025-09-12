/// 💳 Enhanced IAP Manager - Production-ready In-App Purchase system
/// Handles complete FlappyJet product catalog with server-side validation
library;

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../core/debug_logger.dart';
import '../game/core/iap_products.dart';
import '../game/systems/inventory_manager.dart';
import '../game/systems/lives_manager.dart';
import '../game/systems/firebase_analytics_manager.dart';
import 'iap_receipt_validator.dart';

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

  /// Initialize the IAP system
  Future<void> initialize({
    InventoryManager? inventory,
    LivesManager? lives,
  }) async {
    if (_isInitialized) return;

    try {
      safePrint('💳 🚀 Initializing Enhanced IAP Manager...');

      // Set dependencies
      _inventory = inventory;
      _lives = lives;

      // Check IAP availability with enhanced detection
      _isAvailable = await _checkIAPAvailability();
      safePrint('💳 📊 IAP Available: $_isAvailable');
      
      if (kDebugMode) {
        safePrint('💳 🧪 Debug Mode: Platform=${Platform.isAndroid ? 'Android' : 'iOS'}, Emulator=${await _isRunningOnEmulator()}');
      }

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
      safePrint('💳 🛒 Loading ${storeIds.length} products...');

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
        safePrint('💳 ✅ Loaded: ${product.title} - ${product.price}');
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

    switch (purchaseDetails.status) {
      case PurchaseStatus.pending:
        await _handlePendingPurchase(purchaseDetails);
        break;
      case PurchaseStatus.purchased:
        await _handleSuccessfulPurchase(purchaseDetails);
        break;
      case PurchaseStatus.error:
        await _handleFailedPurchase(purchaseDetails);
        break;
      case PurchaseStatus.restored:
        await _handleRestoredPurchase(purchaseDetails);
        break;
      case PurchaseStatus.canceled:
        await _handleCancelledPurchase(purchaseDetails);
        break;
    }

    // Complete the purchase if needed
    if (purchaseDetails.pendingCompletePurchase) {
      await _iap.completePurchase(purchaseDetails);
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
      // Find the IAP product
      final iapProduct = IAPProductCatalog.getProductByStoreId(purchaseDetails.productID);
      if (iapProduct == null) {
        safePrint('💳 ❌ Unknown product purchased: ${purchaseDetails.productID}');
        return;
      }

      // Validate receipt with server
      final validationResult = await _validator.validatePurchase(
        purchaseDetails: purchaseDetails,
        platform: Platform.isIOS ? 'ios' : 'android',
      );

      if (!validationResult.isValid) {
        safePrint('💳 ❌ Purchase validation failed: ${validationResult.error}');
        await _trackPurchaseEvent('purchase_validation_failed', {
          'product_id': iapProduct.id,
          'error': validationResult.error,
          'transaction_id': purchaseDetails.purchaseID,
        });
        return;
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

      safePrint('💳 ✅ Purchase completed: ${iapProduct.displayName}');

    } catch (e) {
      safePrint('💳 ❌ Error processing successful purchase: $e');
      await _trackPurchaseEvent('purchase_processing_error', {
        'product_id': purchaseDetails.productID,
        'error': e.toString(),
      });
    }
  }

  /// Grant rewards for purchased product
  Future<void> _grantPurchaseRewards(IAPProduct product, PurchaseDetails? purchaseDetails) async {
    try {
      // Grant gems
      if (product.totalGems > 0 && _inventory != null) {
        await _inventory!.grantGems(product.totalGems);
        safePrint('💳 💎 Granted ${product.totalGems} gems');
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
      // First check the basic IAP availability
      final basicAvailability = await _iap.isAvailable();
      
      if (basicAvailability) {
        return true; // Real device with IAP support
      }
      
      // Enhanced checks for emulators and development
      if (kDebugMode) {
        final isEmulator = await _isRunningOnEmulator();
        if (isEmulator) {
          safePrint('💳 🧪 Running on emulator - enabling IAP simulation mode');
          return true; // Enable IAP simulation on emulators in debug mode
        }
      }
      
      return false; // Real device without IAP support
      
    } catch (e) {
      safePrint('💳 ❌ Error checking IAP availability: $e');
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
        
        return brand.toLowerCase().contains('generic') ||
               model.toLowerCase().contains('emulator') ||
               device.toLowerCase().contains('emulator') ||
               model.toLowerCase().contains('sdk');
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

  /// Dispose resources
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

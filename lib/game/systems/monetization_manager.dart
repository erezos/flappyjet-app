import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'dart:async';


/// MINIMAL MONETIZATION SYSTEM - Firebase/AdMob dependencies temporarily removed to fix crash
/// This preserves the interface while removing problematic dependencies
class MonetizationManager extends ChangeNotifier {
  static final MonetizationManager _instance = MonetizationManager._internal();
  factory MonetizationManager() => _instance;
  MonetizationManager._internal();

  // Core systems (IAP only for now)
  final InAppPurchase _iap = InAppPurchase.instance;
  
  // Development mode (forced true for now)
  bool _developmentMode = true;
  bool _firebaseAvailable = false;
  bool _adMobAvailable = true; // enable AdMob path
  
  // State management
  bool _isAvailable = false;
  bool _isPurchasing = false;
  List<ProductDetails> _products = [];
  final List<PurchaseDetails> _purchases = [];
  int _premiumCoins = 1000; // Demo coins for testing
  bool _isRewardedAdLoaded = false;
  String _adMobAppIdIOS = '';
  String _rewardedUnitIdIOS = '';
  String _adMobAppIdAndroid = '';
  String _rewardedUnitIdAndroid = '';
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // Product IDs
  static const String productIdPremiumCoins250 = 'premium_coins_250';
  static const String productIdPremiumCoins500 = 'premium_coins_500';  
  static const String productIdPremiumCoins1000 = 'premium_coins_1000';
  static const String productIdJetSkinGoldenFalcon = 'jet_skin_golden_falcon';

  // Getters
  bool get isAvailable => _isAvailable;
  bool get isPurchasing => _isPurchasing;
  bool get developmentMode => _developmentMode;
  bool get firebaseAvailable => _firebaseAvailable;
  bool get adMobAvailable => _adMobAvailable;
  List<ProductDetails> get products => List.unmodifiable(_products);
  List<PurchaseDetails> get purchases => List.unmodifiable(_purchases);
  int get premiumCoins => _premiumCoins;
  bool get isRewardedAdLoaded => _isRewardedAdLoaded;

  /// MINIMAL initialization - IAP only
  Future<void> initialize() async {
    try {
      debugPrint('💰 🧪 Initializing MonetizationManager (minimal mode - Firebase/AdMob disabled)...');
      
      // Force development mode
      _developmentMode = true;
      _firebaseAvailable = false;
      _adMobAvailable = true;
      
      // Initialize IAP only
      await _initializeIAP();
      
      debugPrint('💰 ✅ MonetizationManager initialized successfully!');
      debugPrint('💰 📊 Service Status: Dev Mode: $_developmentMode, IAP: $_isAvailable, Firebase: $_firebaseAvailable, AdMob: $_adMobAvailable');
      
    } catch (e) {
      debugPrint('💰 ❌ MonetizationManager initialization error: $e');
      // Set safe defaults
      _developmentMode = true;
      _firebaseAvailable = false;
      _adMobAvailable = false;
    }
    notifyListeners();
  }

  // Configure AdMob IDs at runtime (from app config or remote config)
  void configureAdMob({
    required String iosAppId,
    required String iosRewardedUnitId,
    String? androidAppId,
    String? androidRewardedUnitId,
  }) {
    _adMobAvailable = true;
    _adMobAppIdIOS = iosAppId;
    _rewardedUnitIdIOS = iosRewardedUnitId;
    if (androidAppId != null) _adMobAppIdAndroid = androidAppId;
    if (androidRewardedUnitId != null) _rewardedUnitIdAndroid = androidRewardedUnitId;
    notifyListeners();
  }

  // Rewarded state getters
  String get adMobAppIdIOS => _adMobAppIdIOS;
  String get rewardedUnitIdIOS => _rewardedUnitIdIOS;
  String get adMobAppIdAndroid => _adMobAppIdAndroid;
  String get rewardedUnitIdAndroid => _rewardedUnitIdAndroid;
  
  /// Initialize In-App Purchases (works independently)
  Future<void> _initializeIAP() async {
    try {
      _isAvailable = await _iap.isAvailable();
      debugPrint('💰 💳 IAP Available: $_isAvailable');
      
      if (_isAvailable) {
        // Listen to purchase updates
        _subscription = _iap.purchaseStream.listen(
          _handlePurchaseUpdates,
          onDone: () => _subscription?.cancel(),
          onError: (error) => debugPrint('💰 ❌ IAP Stream Error: $error'),
        );
        
        // Load products and past purchases
        await _loadProducts();
        await _loadPastPurchases();
      }
    } catch (e) {
      debugPrint('💰 ❌ IAP initialization failed: $e');
      _isAvailable = false;
    }
  }

  /// Load products for IAP
  Future<void> _loadProducts() async {
    const Set<String> kProductIds = {
      productIdPremiumCoins250,
      productIdPremiumCoins500,
      productIdPremiumCoins1000,
      productIdJetSkinGoldenFalcon,
      // Additional jet skin product IDs
      'jet_skin_silver_lightning',
      'jet_skin_stealth_phantom', 
      'jet_skin_combat_ace',
      'jet_skin_neon_racer',
      'jet_skin_plasma_destroyer',
      'jet_skin_dragon_wing',
      'jet_skin_phoenix_flame',
    };
    
    try {
      final ProductDetailsResponse response = await _iap.queryProductDetails(kProductIds);
      if (response.error != null) {
        debugPrint('💰 ⚠️ Error loading products: ${response.error!.message}');
      } else {
        _products = response.productDetails;
        debugPrint('💰 ✅ Loaded ${_products.length} products');
        for (var p in _products) {
          debugPrint('💰 🛒 Product: ${p.title} (${p.id}) - ${p.price}');
        }
      }
    } catch (e) {
      debugPrint('💰 ❌ Product loading error: $e');
    }
    notifyListeners();
  }

  /// Load past purchases
  Future<void> _loadPastPurchases() async {
    try {
      await _iap.restorePurchases();
      notifyListeners();
    } catch (e) {
      debugPrint('💰 ⚠️ Error loading past purchases: $e');
    }
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        _showPendingUI();
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          _handleError(purchaseDetails.error!);
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                   purchaseDetails.status == PurchaseStatus.restored) {
          _processPurchase(purchaseDetails);
        }
        if (purchaseDetails.pendingCompletePurchase) {
          _iap.completePurchase(purchaseDetails);
        }
      }
    }
    notifyListeners();
  }

  void _showPendingUI() {
    debugPrint('💰 ⏳ Purchase is pending...');
    _isPurchasing = true;
    notifyListeners();
  }

  void _handleError(IAPError error) {
    debugPrint('💰 ❌ Purchase error: ${error.message}');
    _isPurchasing = false;
    notifyListeners();
  }

  void _processPurchase(PurchaseDetails purchaseDetails) {
    debugPrint('💰 ✅ Processing purchase: ${purchaseDetails.productID}');
    _isPurchasing = false;

    // Add premium coins for coin packages
    if (purchaseDetails.productID == productIdPremiumCoins250) {
      _premiumCoins += 250;
      debugPrint('💰 💎 Added 250 premium coins. Total: $_premiumCoins');
    } else if (purchaseDetails.productID == productIdPremiumCoins500) {
      _premiumCoins += 500;
      debugPrint('💰 💎 Added 500 premium coins. Total: $_premiumCoins');
    } else if (purchaseDetails.productID == productIdPremiumCoins1000) {
      _premiumCoins += 1000;
      debugPrint('💰 💎 Added 1000 premium coins. Total: $_premiumCoins');
    }

    notifyListeners();
  }

  /// Purchase a product safely
  Future<void> purchaseProduct(String productId) async {
    if (!_isAvailable || _isPurchasing) {
      debugPrint('💰 ⚠️ Purchase not available or already in progress');
      return;
    }

    final product = _products.where((p) => p.id == productId).firstOrNull;
    if (product == null) {
      debugPrint('💰 ❌ Product not found: $productId');
      return;
    }

    _isPurchasing = true;
    notifyListeners();

    try {
      final purchaseParam = PurchaseParam(productDetails: product);
      await _iap.buyConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint('💰 ❌ Purchase error: $e');
      _isPurchasing = false;
      notifyListeners();
    }
  }

  /// Rewarded ad flow (dev: simulate; prod: integrate google_mobile_ads outside of core)
  Future<void> showRewardedAdForExtraLife({required VoidCallback onReward}) async {
    if (!_adMobAvailable || _rewardedUnitIdIOS.isEmpty) {
      debugPrint('📺 🧪 Simulating rewarded ad (AdMob disabled or IDs missing)');
      onReward();
      _premiumCoins += 50;
      notifyListeners();
      return;
    }
    // Placeholder: integrate google_mobile_ads plugin in app layer. For now simulate immediately.
    debugPrint('📺 ⚠️ AdMob path enabled, but plugin integration deferred. Simulating reward.');
    onReward();
    _premiumCoins += 50;
    notifyListeners();
  }

  /// Simulate analytics tracking in development mode
  void trackPlayerEngagement(Map<String, dynamic> parameters) {
    debugPrint('📊 🧪 Development mode: Analytics event simulated (Firebase disabled)');
    debugPrint('📊 🧪 Event data: $parameters');
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
} 
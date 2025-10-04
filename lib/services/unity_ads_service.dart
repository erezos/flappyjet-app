import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import '../core/debug_logger.dart';

/// 🎯 Unity Ads Service with AdMob Fallback
/// 
/// Implements ad mediation waterfall:
/// 1. Try Unity Ads first (gaming-focused, family-safe, $3-8 CPM)
/// 2. Fall back to AdMob (PG-rated only, $0.50-2 CPM)
/// 
/// This service is designed for production use with live users.
class UnityAdsService {
  static final UnityAdsService _instance = UnityAdsService._internal();
  factory UnityAdsService() => _instance;
  UnityAdsService._internal();

  // ==================== CREDENTIALS ====================
  // Unity Ads Configuration
  static const String _unityGameId = '5958877';
  static const String _unityPlacementId = 'Rewarded_Android';
  
  // AdMob Configuration (Fallback)
  static const String _adMobRewardedAdUnitId = kDebugMode
      ? 'ca-app-pub-3940256099942544/5224354917'  // Test ID
      : 'ca-app-pub-9307424222926115~5619528650'; // Production ID

  // ==================== STATE ====================
  bool _isInitialized = false;
  bool _isUnityReady = false;
  bool _isAdMobReady = false;
  
  AdProvider? _currentProvider;
  RewardedAd? _adMobRewardedAd;
  
  bool _isLoading = false;
  bool _isShowing = false;

  // ==================== CALLBACKS ====================
  // Public callbacks for UI integration
  Function()? onAdLoaded;
  Function(String error)? onAdFailedToLoad;
  Function()? onAdShown;
  Function()? onAdClosed;
  Function()? onAdRewardGranted;
  Function()? onAdSkippedEarly;  // Called when user exits ad before completion (no reward)

  // ==================== INITIALIZATION ====================
  
  /// Initialize Unity Ads and AdMob fallback
  /// 
  /// Call this once during app startup (in main.dart).
  /// Safe to call multiple times - will only initialize once.
  Future<void> initialize() async {
    if (_isInitialized) {
      safePrint('⚠️ UnityAdsService already initialized');
      return;
    }

    safePrint('🎯 Initializing Unity Ads Service (Family-Safe)...');

    // Initialize both networks in parallel for faster startup
    await Future.wait([
      _initializeUnityAds(),
      _initializeAdMob(),
    ]);

    _isInitialized = true;
    
    safePrint('🎯 ✅ Unity Ads Service initialized');
    safePrint('   Unity Ads: $_isUnityReady');
    safePrint('   AdMob (fallback): $_isAdMobReady');
    
    if (!_isUnityReady && !_isAdMobReady) {
      safePrint('❌ WARNING: No ad networks available!');
    }
    
    // 🚀 CRITICAL: Pre-load first ad so it's ready when user needs it
    // This was the old AdMob behavior - load in background during init
    safePrint('🎯 📺 Pre-loading first rewarded ad in background...');
    loadRewardedAd(); // Non-blocking call
  }

  /// Initialize Unity Ads
  Future<bool> _initializeUnityAds() async {
    try {
      safePrint('🎮 Initializing Unity Ads...');
      
      // Use Completer to properly wait for async initialization
      final Completer<bool> initCompleter = Completer<bool>();
      
      await UnityAds.init(
        gameId: _unityGameId,
        testMode: kDebugMode, // Test mode in debug builds, production ads in release
        onComplete: () {
          _isUnityReady = true;
          safePrint('🎮 ✅ Unity Ads ready');
          if (!initCompleter.isCompleted) {
            initCompleter.complete(true);
          }
        },
        onFailed: (error, message) {
          _isUnityReady = false;
          safePrint('❌ Unity Ads initialization failed: $message (error: $error)');
          if (!initCompleter.isCompleted) {
            initCompleter.complete(false);
          }
        },
      );

      // Wait for initialization to complete (with timeout)
      final result = await initCompleter.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          safePrint('❌ Unity Ads initialization timeout after 10s');
          _isUnityReady = false;
          return false;
        },
      );
      
      return result;
    } catch (e) {
      safePrint('❌ Unity Ads initialization error: $e');
      _isUnityReady = false;
      return false;
    }
  }

  /// Initialize AdMob with family-safe configuration
  Future<bool> _initializeAdMob() async {
    try {
      safePrint('📱 Initializing AdMob (family-safe fallback)...');
      
      await MobileAds.instance.initialize();
      
      // ✅ CRITICAL: Family-safe configuration
      // Matches AdMob Console blocking controls
      MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          maxAdContentRating: MaxAdContentRating.pg, // PG-rated ads only
          tagForChildDirectedTreatment: TagForChildDirectedTreatment.yes,
        ),
      );
      
      _isAdMobReady = true;
      safePrint('📱 ✅ AdMob ready (PG-rated only)');
      return true;
    } catch (e) {
      safePrint('❌ AdMob initialization error: $e');
      _isAdMobReady = false;
      return false;
    }
  }

  // ==================== LOAD AD ====================
  
  /// Load rewarded ad with waterfall logic
  /// 
  /// Waterfall:
  /// 1. Try Unity Ads first (higher CPM)
  /// 2. If Unity fails, try AdMob (fallback)
  Future<void> loadRewardedAd() async {
    if (_isLoading) {
      safePrint('⚠️ Ad already loading, skipping...');
      return;
    }

    if (!_isInitialized) {
      safePrint('⚠️ Service not initialized, initializing now...');
      await initialize();
    }

    _isLoading = true;
    safePrint('🎯 Loading rewarded ad (waterfall)...');

    try {
      // Try Unity Ads first
      if (_isUnityReady) {
        await _loadUnityRewarded();
      } 
      // Fall back to AdMob
      else if (_isAdMobReady) {
        safePrint('⚠️ Unity not available, using AdMob fallback...');
        await _loadAdMobRewarded();
      }
      // No networks available
      else {
        _isLoading = false;
        onAdFailedToLoad?.call('No ad networks available');
        safePrint('❌ No ad networks available');
      }
    } catch (e) {
      _isLoading = false;
      onAdFailedToLoad?.call('Load error: $e');
      safePrint('❌ Load ad error: $e');
    }
  }

  /// Load Unity rewarded ad
  Future<void> _loadUnityRewarded() async {
    try {
      _currentProvider = AdProvider.unity;
      safePrint('🎮 Loading from Unity Ads...');
      
      // Use a completer to wait for the async load
      final completer = Completer<bool>();
      
      // Check if Unity ad is ready
      UnityAds.load(
        placementId: _unityPlacementId,
        onComplete: (placementId) {
          _isLoading = false;
          onAdLoaded?.call();
          safePrint('🎮 ✅ Unity ad loaded for placement: $placementId');
          if (!completer.isCompleted) completer.complete(true);
        },
        onFailed: (placementId, error, message) {
          // 🔍 DETAILED ERROR LOGGING
          safePrint('❌ Unity ad load failed:');
          safePrint('   Placement ID: $placementId');
          safePrint('   Error Code: $error');
          safePrint('   Error Message: $message');
          safePrint('   Unity Ready: $_isUnityReady');
          safePrint('   Test Mode: ${kDebugMode ? 'ENABLED' : 'DISABLED'}');
          safePrint('   → Falling back to AdMob...');
          
          if (!completer.isCompleted) completer.complete(false);
          _loadAdMobRewarded();
        },
      );
      
      // Wait for load to complete (with timeout)
      await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          safePrint('⏱️ Unity ad load timeout, trying AdMob...');
          _loadAdMobRewarded();
          return false;
        },
      );
    } catch (e) {
      safePrint('❌ Unity load error: $e, trying AdMob...');
      _loadAdMobRewarded();
    }
  }

  /// Load AdMob rewarded ad (fallback)
  Future<void> _loadAdMobRewarded() async {
    if (!_isAdMobReady) {
      _isLoading = false;
      onAdFailedToLoad?.call('AdMob not available');
      return;
    }

    _currentProvider = AdProvider.adMob;
    safePrint('📱 Loading from AdMob (fallback)...');
    
    try {
      await RewardedAd.load(
        adUnitId: _adMobRewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _adMobRewardedAd = ad;
            _isLoading = false;
            onAdLoaded?.call();
            safePrint('📱 ✅ AdMob ad loaded (fallback)');
            
            // Set full screen content callback
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (ad) {
                _isShowing = true;
                onAdShown?.call();
                safePrint('📱 AdMob ad shown');
              },
              onAdDismissedFullScreenContent: (ad) {
                _isShowing = false;
                _currentProvider = null; // Clear provider
                onAdClosed?.call();
                ad.dispose();
                _adMobRewardedAd = null;
                safePrint('📱 AdMob ad closed');
                
                // 🚀 CRITICAL: Pre-load next ad immediately (old AdMob behavior)
                safePrint('📱 📺 Pre-loading next ad...');
                loadRewardedAd(); // Non-blocking
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                _isShowing = false;
                _currentProvider = null; // Clear provider
                ad.dispose();
                _adMobRewardedAd = null;
                onAdFailedToLoad?.call('AdMob show failed: ${error.message}');
                safePrint('❌ AdMob show failed: ${error.message}');
                
                // Try loading next ad even after failure
                safePrint('📱 📺 Attempting to load next ad after failure...');
                loadRewardedAd(); // Non-blocking
              },
            );
          },
          onAdFailedToLoad: (error) {
            _isLoading = false;
            onAdFailedToLoad?.call('All ad networks failed: ${error.message}');
            safePrint('❌ All ad networks failed: ${error.message}');
          },
        ),
      );
    } catch (e) {
      _isLoading = false;
      onAdFailedToLoad?.call('AdMob error: $e');
      safePrint('❌ AdMob error: $e');
    }
  }

  // ==================== SHOW AD ====================
  
  /// Show rewarded ad
  /// 
  /// Returns true if ad was shown successfully, false otherwise.
  Future<bool> showRewardedAd() async {
    if (_isShowing) {
      safePrint('⚠️ Ad already showing');
      return false;
    }

    if (_currentProvider == null) {
      safePrint('❌ No ad loaded to show');
      onAdFailedToLoad?.call('No ad loaded');
      return false;
    }

    safePrint('🎯 Showing ad from: $_currentProvider');

    try {
      _isShowing = true;

      switch (_currentProvider!) {
        case AdProvider.unity:
          await _showUnityAd();
          break;
          
        case AdProvider.adMob:
          await _showAdMobAd();
          break;
      }

      return true;
    } catch (e) {
      _isShowing = false;
      safePrint('❌ Show ad error: $e');
      onAdFailedToLoad?.call('Show error: $e');
      return false;
    }
  }

  /// Show Unity ad
  Future<void> _showUnityAd() async {
    UnityAds.showVideoAd(
      placementId: _unityPlacementId,
      onComplete: (placementId) {
        _isShowing = false;
        _currentProvider = null; // Clear provider so new ad can be loaded
        onAdRewardGranted?.call();
        safePrint('🎮 ✅ Unity ad completed - Reward granted!');
        
        // 🚀 CRITICAL: Pre-load next ad immediately (old AdMob behavior)
        safePrint('🎮 📺 Pre-loading next ad...');
        loadRewardedAd(); // Non-blocking
      },
      onFailed: (placementId, error, message) {
        _isShowing = false;
        _currentProvider = null; // Clear provider
        onAdFailedToLoad?.call('Unity show failed: $message');
        safePrint('❌ Unity show failed: $message');
        
        // Try loading next ad even after failure
        safePrint('🎮 📺 Attempting to load next ad after failure...');
        loadRewardedAd(); // Non-blocking
      },
      onStart: (placementId) {
        onAdShown?.call();
        safePrint('🎮 Unity ad started');
      },
      onSkipped: (placementId) {
        _isShowing = false;
        _currentProvider = null; // Clear provider
        // ⚠️ CRITICAL: User exited ad early - NO REWARD!
        // Call special callback so UI can show explanatory popup
        onAdSkippedEarly?.call();
        safePrint('🎮 ⚠️ Unity ad skipped early (NO REWARD) - user needs to complete ad');
        
        // Pre-load next ad
        safePrint('🎮 📺 Pre-loading next ad after skip...');
        loadRewardedAd(); // Non-blocking
      },
      onClick: (placementId) {
        safePrint('🎮 Unity ad clicked');
      },
    );
  }

  /// Show AdMob ad
  Future<void> _showAdMobAd() async {
    if (_adMobRewardedAd == null) {
      _isShowing = false;
      onAdFailedToLoad?.call('AdMob ad not loaded');
      return;
    }

    await _adMobRewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        onAdRewardGranted?.call();
        safePrint('📱 ✅ AdMob reward granted: ${reward.amount} ${reward.type}');
      },
    );
  }

  // ==================== UTILITIES ====================
  
  /// Check if an ad is ready to show
  bool get isAdReady {
    if (_currentProvider == null) return false;
    
    switch (_currentProvider!) {
      case AdProvider.unity:
        // Unity Ads doesn't have a direct "isReady" check in the plugin
        // We rely on the load callback
        return true;
      case AdProvider.adMob:
        return _adMobRewardedAd != null;
    }
  }

  /// Check if ad is currently loading
  bool get isLoading => _isLoading;

  /// Check if ad is currently showing
  bool get isShowing => _isShowing;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Get current ad provider name (for analytics)
  String? get currentProviderName => _currentProvider?.name;

  /// Dispose resources
  void dispose() {
    safePrint('🗑️ Disposing UnityAdsService...');
    _adMobRewardedAd?.dispose();
    _adMobRewardedAd = null;
    _currentProvider = null;
    _isLoading = false;
    _isShowing = false;
  }
}

/// Ad provider enum for tracking which network served the ad
enum AdProvider {
  unity,
  adMob,
}


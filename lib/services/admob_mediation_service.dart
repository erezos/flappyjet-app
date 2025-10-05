import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../core/debug_logger.dart';

/// 🚀 AdMob Mediation Service - Unity Ads + AdMob Network
/// 
/// This service uses Google's official AdMob Mediation to manage multiple ad networks:
/// - Unity Ads (primary, gaming-focused, $3-8 CPM)
/// - AdMob Network (fallback, $0.50-2 CPM)
/// 
/// Benefits:
/// - ✅ Automatic bidding between networks
/// - ✅ Google handles callback order (no race conditions)
/// - ✅ Higher revenue through competition
/// - ✅ Simpler code (no custom waterfall)
/// - ✅ Battle-tested by millions of apps
class AdMobMediationService {
  static final AdMobMediationService _instance = AdMobMediationService._internal();
  factory AdMobMediationService() => _instance;
  AdMobMediationService._internal();

  // Ad state
  RewardedAd? _rewardedAd;
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _rewardGranted = false; // Track reward status at class level to avoid race conditions

  // Callbacks
  VoidCallback? onAdLoaded;
  Function(String error)? onAdFailedToLoad;
  VoidCallback? onAdShown;
  VoidCallback? onAdRewardGranted;
  VoidCallback? onAdSkippedEarly;
  VoidCallback? onAdClosed;

  // Ad Unit IDs
  static const String _rewardedAdUnitId = kDebugMode
      ? 'ca-app-pub-3940256099942544/5224354917'  // Test ID
      : 'ca-app-pub-9307424222926115/6438263608'; // Production ID (AdMob Mediation)

  /// Initialize the AdMob SDK
  Future<void> initialize() async {
    if (_isInitialized) {
      safePrint('📱 AdMob Mediation already initialized');
      return;
    }

    try {
      safePrint('📱 Initializing AdMob Mediation...');
      
      // Initialize Google Mobile Ads SDK
      await MobileAds.instance.initialize();
      
      _isInitialized = true;
      safePrint('📱 ✅ AdMob Mediation initialized successfully');
      safePrint('📱 📊 Mediation includes: Unity Ads + AdMob Network');
      
      // Pre-load first ad
      safePrint('📱 📺 Pre-loading first rewarded ad...');
      await loadRewardedAd();
    } catch (e) {
      safePrint('❌ AdMob Mediation initialization failed: $e');
      _isInitialized = false;
    }
  }

  /// Load a rewarded ad
  Future<void> loadRewardedAd() async {
    if (_isLoading) {
      safePrint('📱 ⚠️ Ad already loading, skipping...');
      return;
    }

    if (_rewardedAd != null) {
      safePrint('📱 ✅ Ad already loaded, skipping...');
      return;
    }

    _isLoading = true;
    safePrint('📱 Loading rewarded ad (AdMob Mediation)...');

    try {
      await RewardedAd.load(
        adUnitId: _rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _isLoading = false;
            safePrint('📱 ✅ Ad loaded successfully (AdMob Mediation)');
            safePrint('📱 📊 Ad source: ${ad.responseInfo?.mediationAdapterClassName ?? "Unknown"}');
            onAdLoaded?.call();
          },
          onAdFailedToLoad: (error) {
            _isLoading = false;
            safePrint('📱 ❌ Ad failed to load: ${error.message}');
            safePrint('📱 📊 Error code: ${error.code}');
            onAdFailedToLoad?.call(error.message);
          },
        ),
      );
    } catch (e) {
      _isLoading = false;
      safePrint('❌ Exception loading ad: $e');
      onAdFailedToLoad?.call(e.toString());
    }
  }

  /// Show a rewarded ad
  /// 
  /// Returns a Future<bool> that completes when the ad is closed:
  /// - true: User earned reward
  /// - false: User did not earn reward (early exit or failure)
  Future<bool> showRewardedAd() async {
    if (_rewardedAd == null) {
      safePrint('📱 ❌ No ad available to show');
      onAdFailedToLoad?.call('No ad loaded');
      return false;
    }

    // 🔧 CRITICAL: Reset reward status at the START
    _rewardGranted = false;
    
    // Create completer to wait for ad dismissal
    final Completer<bool> completer = Completer<bool>();

    safePrint('📱 🎬 Showing rewarded ad...');

    // Set up callbacks BEFORE showing
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        onAdShown?.call();
        safePrint('📱 🎬 Ad showing full screen');
      },
      onAdDismissedFullScreenContent: (ad) {
        safePrint('📱 ✅ Ad dismissed - Final reward status: $_rewardGranted');
        
        // Cleanup
        ad.dispose();
        _rewardedAd = null;
        onAdClosed?.call();
        
        // Complete with final reward status
        if (!completer.isCompleted) {
          completer.complete(_rewardGranted);
        }
        
        // Pre-load next ad
        safePrint('📱 📺 Pre-loading next ad...');
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        safePrint('📱 ❌ Ad failed to show: ${error.message}');
        
        // Cleanup
        ad.dispose();
        _rewardedAd = null;
        onAdFailedToLoad?.call(error.message);
        onAdClosed?.call();
        
        // Complete with failure
        if (!completer.isCompleted) {
          completer.complete(false);
        }
        
        // Try loading next ad
        safePrint('📱 📺 Attempting to load next ad after failure...');
        loadRewardedAd();
      },
    );

    // Show the ad with reward callback
    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        _rewardGranted = true;
        safePrint('📱 ✅ ✅ ✅ REWARD EARNED! ${reward.amount} ${reward.type}');
        safePrint('📱 📊 Ad source: ${ad.responseInfo?.mediationAdapterClassName ?? "Unknown"}');
      },
    );

    // Wait for dismissal
    return completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        safePrint('📱 ⏱️ Timeout - reward status: $_rewardGranted');
        return _rewardGranted;
      },
    );
  }

  /// Check if an ad is ready to show
  bool get isAdReady => _rewardedAd != null;

  /// Check if the service is initialized
  bool get isInitialized => _isInitialized;

  /// Dispose resources
  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isLoading = false;
    safePrint('📱 AdMob Mediation Service disposed');
  }
}

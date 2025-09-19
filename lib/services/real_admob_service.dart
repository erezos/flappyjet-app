/// 📺 Real AdMob Integration Service - Production Ready
/// 
/// Handles real Google AdMob rewarded ads with proper error handling,
/// loading states, and fallback mechanisms for FlappyJet.
library;

import 'dart:async';
import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import '../core/debug_logger.dart';

class RealAdMobService {
  static final RealAdMobService _instance = RealAdMobService._internal();
  factory RealAdMobService() => _instance;
  RealAdMobService._internal();

  // 🎯 Production Ad Unit IDs from AdMob Console
  static const String _rewardedAdUnitIdAndroid = 'ca-app-pub-9307424222926115/6438263608';
  static const String _rewardedAdUnitIdIOS = 'ca-app-pub-9307424222926115/8013454758';
  
  // 🧪 Test Ad Unit IDs for development
  static const String _testRewardedAdUnitIdAndroid = 'ca-app-pub-3940256099942544/5224354917';
  static const String _testRewardedAdUnitIdIOS = 'ca-app-pub-3940256099942544/1712485313';
  
  // State management
  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;
  bool _isLoading = false;
  bool _isInitialized = false;
  int _loadAttempts = 0;
  static const int _maxLoadAttempts = 3;

  // Getters
  bool get isAdLoaded => _isAdLoaded;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;

  /// Initialize AdMob SDK with App Tracking Transparency
  Future<void> initialize() async {
    if (_isInitialized) {
      safePrint('📺 AdMob already initialized');
      return;
    }

    try {
      safePrint('📺 🚀 Initializing AdMob SDK...');
      
      // 🍎 iOS: Request App Tracking Transparency permission first
      if (Platform.isIOS) {
        await _requestTrackingPermission();
      }
      
      // Initialize Mobile Ads SDK
      final initializationStatus = await MobileAds.instance.initialize();
      
      // Log adapter statuses for debugging
      final adapterStatuses = initializationStatus.adapterStatuses;
      for (final entry in adapterStatuses.entries) {
        safePrint('📺 Adapter ${entry.key}: ${entry.value.state.name}');
      }

      _isInitialized = true;
      safePrint('📺 ✅ AdMob SDK initialized successfully');
      
      // Preload first rewarded ad
      await _loadRewardedAd();
      
    } catch (e) {
      safePrint('📺 ❌ AdMob initialization failed: $e');
      _isInitialized = false;
    }
  }

  /// 🍎 Request App Tracking Transparency permission (iOS only)
  Future<void> _requestTrackingPermission() async {
    try {
      safePrint('📺 🍎 Requesting App Tracking Transparency permission...');
      
      final status = await AppTrackingTransparency.requestTrackingAuthorization();
      
      switch (status) {
        case TrackingStatus.authorized:
          safePrint('📺 ✅ ATT: User authorized tracking - personalized ads enabled');
          break;
        case TrackingStatus.denied:
          safePrint('📺 ⚠️ ATT: User denied tracking - non-personalized ads only');
          break;
        case TrackingStatus.restricted:
          safePrint('📺 ⚠️ ATT: Tracking restricted by system - non-personalized ads only');
          break;
        case TrackingStatus.notDetermined:
          safePrint('📺 ⚠️ ATT: Permission not determined - non-personalized ads only');
          break;
        case TrackingStatus.notSupported:
          safePrint('📺 ℹ️ ATT: Not supported on this device - non-personalized ads only');
          break;
      }
      
      // Note: AdMob automatically handles personalized vs non-personalized ads
      // based on the ATT status, so no additional configuration needed
      
    } catch (e) {
      safePrint('📺 ❌ ATT permission request failed: $e');
      // Continue with non-personalized ads if ATT fails
    }
  }

  /// Load rewarded ad with retry logic
  Future<void> _loadRewardedAd() async {
    if (_isLoading || _isAdLoaded) {
      safePrint('📺 ⚠️ Ad already loading or loaded, skipping');
      return;
    }
    
    if (_loadAttempts >= _maxLoadAttempts) {
      safePrint('📺 ❌ Max load attempts reached, stopping');
      return;
    }

    _isLoading = true;
    _loadAttempts++;
    
    safePrint('📺 🔄 Loading rewarded ad (attempt $_loadAttempts/$_maxLoadAttempts)...');
    
    try {
      await RewardedAd.load(
        adUnitId: _getRewardedAdUnitId(),
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _isAdLoaded = true;
            _isLoading = false;
            _loadAttempts = 0; // Reset attempts on success
            _setAdCallbacks();
            safePrint('📺 ✅ Rewarded ad loaded successfully');
          },
          onAdFailedToLoad: (error) {
            _isAdLoaded = false;
            _isLoading = false;
            safePrint('📺 ❌ Rewarded ad failed to load: ${error.message} (Code: ${error.code})');
            
            // Retry with exponential backoff
            if (_loadAttempts < _maxLoadAttempts) {
              final delaySeconds = _loadAttempts * 10; // 10s, 20s, 30s
              safePrint('📺 🔄 Retrying in ${delaySeconds}s...');
              Future.delayed(Duration(seconds: delaySeconds), _loadRewardedAd);
            } else {
              safePrint('📺 ❌ All load attempts failed');
            }
          },
        ),
      );
    } catch (e) {
      _isLoading = false;
      safePrint('📺 ❌ Exception during ad loading: $e');
    }
  }

  /// Set ad lifecycle callbacks
  void _setAdCallbacks() {
    _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        safePrint('📺 🎬 Rewarded ad showed full screen content');
      },
      onAdDismissedFullScreenContent: (ad) {
        safePrint('📺 ❌ Rewarded ad dismissed');
        _cleanupAfterAd();
        _preloadNextAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        safePrint('📺 ❌ Rewarded ad failed to show: ${error.message}');
        _cleanupAfterAd();
        _preloadNextAd();
      },
      onAdImpression: (ad) {
        safePrint('📺 👁️ Rewarded ad impression recorded');
      },
    );
  }

  /// 🛡️ BULLETPROOF ad showing with guaranteed fallback for blockbuster games
  /// 🎯 CRITICAL: Ad shows FIRST, then game continues (proper UX flow)
  Future<AdRewardResult> showRewardedAd() async {
    try {
      safePrint('📺 🚀 BULLETPROOF: Starting ad flow - ad shows FIRST, then game continues');
      
      // Check if ad is ready
      if (!_isInitialized || !_isAdLoaded || _rewardedAd == null) {
        safePrint('📺 ⚡ BULLETPROOF: No ad ready - immediate fallback (3s delay for UX)');
        
        // Try to reload ad for next attempt (don't wait for it)
        if (!_isLoading && _loadAttempts < _maxLoadAttempts) {
          _loadRewardedAd().catchError((e) {
            safePrint('📺 Background ad reload failed: $e');
          });
        }
        
        // Add small delay so user doesn't feel cheated
        await Future.delayed(const Duration(milliseconds: 1500));
        return AdRewardResult.timeoutFallback('No ad available - reward granted');
      }

      // Show ad and wait for completion
      final result = await _showAdAndWaitForCompletion();
      
      if (result.status == AdRewardStatus.timeoutFallback) {
        safePrint('📺 ⚡ BULLETPROOF: Ad timeout/failure - granting reward for UX');
        _trackAdTimeout();
      }
      
      return result;
      
    } catch (e) {
      safePrint('📺 🛡️ BULLETPROOF: Exception caught - granting reward anyway: $e');
      // Add small delay for UX consistency
      await Future.delayed(const Duration(milliseconds: 1000));
      return AdRewardResult.timeoutFallback('Ad system error - reward granted');
    }
  }

  /// 🎯 CRITICAL: Show ad and wait for DISMISSAL before continuing game
  Future<AdRewardResult> _showAdAndWaitForCompletion() async {
    final Completer<AdRewardResult> completer = Completer<AdRewardResult>();
    AdRewardResult? rewardResult;
    
    try {
      safePrint('📺 🎬 Showing ad - waiting for DISMISSAL before continuing game...');
      
      // Set up completion callbacks BEFORE showing ad
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          safePrint('📺 🎬 Ad showed full screen - user is watching... (waiting for dismissal)');
        },
        onAdDismissedFullScreenContent: (ad) {
          safePrint('📺 ✅ Ad dismissed - now safe to continue game!');
          if (!completer.isCompleted) {
            // Use the reward result if we have one, otherwise fallback
            final finalResult = rewardResult ?? AdRewardResult.timeoutFallback('Ad dismissed - reward granted for UX');
            completer.complete(finalResult);
          }
          _cleanupAfterAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          safePrint('📺 ❌ Ad failed to show: $error - granting reward anyway');
          if (!completer.isCompleted) {
            completer.complete(AdRewardResult.timeoutFallback('Ad failed - reward granted'));
          }
          _cleanupAfterAd();
        },
      );

      // Show the ad
      await _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          rewardResult = AdRewardResult.success(reward.type, reward.amount.toInt());
          safePrint('📺 🎁 AdMob reward received: ${reward.amount} ${reward.type} (NOTE: Game logic determines actual reward - waiting for dismissal...)');
          // Don't complete here - wait for dismissal!
        },
      );

      // Wait for actual user dismissal (no forced timeout!)
      final result = await completer.future;

      safePrint('📺 ✅ Ad flow completed - game can now continue safely');
      return result;

    } catch (e) {
      safePrint('📺 ❌ Ad show error: $e - granting reward anyway');
      _cleanupAfterAd();
      return AdRewardResult.timeoutFallback('Ad error - reward granted');
    }
  }

  /// Clean up after ad completion
  void _cleanupAfterAd() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isAdLoaded = false;
    // Start loading next ad in background
    Future.delayed(const Duration(milliseconds: 500), _loadRewardedAd);
  }

  /// Track ad timeouts for analytics (silent)
  void _trackAdTimeout() {
    // Silent analytics tracking - don't impact user experience
    try {
      safePrint('📺 📊 ANALYTICS: Ad timeout tracked for optimization');
      // Future: Send to analytics service
    } catch (e) {
      // Even analytics failures shouldn't impact UX
      safePrint('📺 📊 Analytics error (ignored): $e');
    }
  }


  /// Preload next ad for better UX
  void _preloadNextAd() {
    safePrint('📺 🔄 Preloading next rewarded ad...');
    Future.delayed(const Duration(seconds: 2), () {
      if (!_isAdLoaded && !_isLoading) {
        _loadRewardedAd();
      }
    });
  }

  /// Get platform-specific ad unit ID
  String _getRewardedAdUnitId() {
    if (kDebugMode) {
      // Use test IDs in debug mode
      return Platform.isAndroid 
          ? _testRewardedAdUnitIdAndroid 
          : _testRewardedAdUnitIdIOS;
    }
    
    // Use production IDs in release mode
    return Platform.isAndroid 
        ? _rewardedAdUnitIdAndroid 
        : _rewardedAdUnitIdIOS;
  }

  /// Force reload ad (useful for retry mechanisms)
  Future<void> forceReloadAd() async {
    safePrint('📺 🔄 Force reloading rewarded ad...');
          _cleanupAfterAd();
    _loadAttempts = 0; // Reset attempts
    await _loadRewardedAd();
  }

  /// Get detailed ad status for debugging
  Map<String, dynamic> getAdStatus() {
    return {
      'isInitialized': _isInitialized,
      'isAdLoaded': _isAdLoaded,
      'isLoading': _isLoading,
      'loadAttempts': _loadAttempts,
      'adUnitId': _getRewardedAdUnitId(),
      'hasAdInstance': _rewardedAd != null,
    };
  }

  /// Dispose resources
  void dispose() {
    safePrint('📺 🧹 Disposing AdMob service...');
          _cleanupAfterAd();
    _isInitialized = false;
  }
}

/// Result wrapper for ad reward operations
class AdRewardResult {
  final AdRewardStatus status;
  final String message;
  final String? rewardType;
  final int? rewardAmount;

  AdRewardResult._(this.status, this.message, this.rewardType, this.rewardAmount);

  factory AdRewardResult.success(String rewardType, int rewardAmount) {
    return AdRewardResult._(AdRewardStatus.success, 'Reward earned', rewardType, rewardAmount);
  }

  factory AdRewardResult.dismissed(String message) {
    return AdRewardResult._(AdRewardStatus.dismissed, message, null, null);
  }

  factory AdRewardResult.noAdAvailable(String message) {
    return AdRewardResult._(AdRewardStatus.noAdAvailable, message, null, null);
  }

  factory AdRewardResult.error(String message) {
    return AdRewardResult._(AdRewardStatus.error, message, null, null);
  }

  factory AdRewardResult.timeoutFallback(String message) {
    return AdRewardResult._(AdRewardStatus.timeoutFallback, message, 'coins', 1);
  }

  bool get isSuccess => status == AdRewardStatus.success;
  bool get shouldGrantReward => isSuccess || status == AdRewardStatus.timeoutFallback;
}

enum AdRewardStatus {
  success,
  dismissed,
  noAdAvailable,
  error,
  timeoutFallback,
}

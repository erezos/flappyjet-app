import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/analytics/unified_analytics_manager.dart';
import '../core/debug_logger.dart';

/// Manages interstitial ads for Story Mode with frequency caps and cooldowns
/// 
/// Strategy:
/// - Session 1: First 3 wins = no ads, then every 2nd win + 2min cooldown
/// - Session 2+: Every 2nd win + 2min cooldown
/// 
/// This ensures positive UX while maximizing revenue.
class InterstitialAdManager {
  static final InterstitialAdManager _instance = InterstitialAdManager._internal();
  factory InterstitialAdManager() => _instance;
  InterstitialAdManager._internal();

  // ============================================================================
  // CONFIGURATION
  // ============================================================================
  
  /// Ad Unit IDs - PRODUCTION
  /// AdMob App ID Android: ca-app-pub-9307424222926115~5619528650
  /// AdMob App ID iOS: ca-app-pub-9307424222926115~7731555244
  static const String _adUnitIdAndroid = 'ca-app-pub-9307424222926115/7832054871'; // PRODUCTION
  static const String _adUnitIdIOS = 'ca-app-pub-9307424222926115/5421513959'; // PRODUCTION
  
  /// First session grace period (no ads for first X wins)
  static const int _graceWins = 3;
  
  /// Show ad every X wins
  static const int _winsPerAd = 2;
  
  /// Minimum time between ads (cooldown)
  static const Duration _minTimeBetweenAds = Duration(minutes: 2);

  // ============================================================================
  // STATE
  // ============================================================================
  
  InterstitialAd? _interstitialAd;
  bool _isAdLoading = false;
  bool _isAdReady = false;
  
  /// ✅ FIX: Store callback to call when ad is ACTUALLY dismissed
  VoidCallback? _pendingOnAdClosed;
  
  /// Last time an ad was shown
  DateTime? _lastAdShownTime;
  
  /// Number of wins since last ad
  int _winsSinceLastAd = 0;
  
  /// Total wins this session
  int _winsThisSession = 0;
  
  /// Is this the first session?
  bool _isFirstSession = true;

  // ============================================================================
  // INITIALIZATION
  // ============================================================================
  
  String get _adUnitId {
    if (Platform.isAndroid) return _adUnitIdAndroid;
    if (Platform.isIOS) return _adUnitIdIOS;
    return '';
  }

  /// Initialize the manager and load first ad
  Future<void> initialize() async {
    try {
      // Check if first session
      final prefs = await SharedPreferences.getInstance();
      _isFirstSession = !(prefs.getBool('has_seen_interstitial') ?? false);
      
      safePrint('📺 InterstitialAdManager initialized (First session: $_isFirstSession)');
      
      // Load first ad
      await _loadAd();
    } catch (e) {
      safePrint('⚠️ InterstitialAdManager initialization error: $e');
    }
  }

  /// Load an interstitial ad
  Future<void> _loadAd() async {
    if (_isAdLoading || _isAdReady) {
      return; // Already loading or ready
    }
    
    _isAdLoading = true;
    safePrint('📺 Loading interstitial ad...');
    
    try {
      await InterstitialAd.load(
        adUnitId: _adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            safePrint('✅ Interstitial ad loaded successfully');
            _interstitialAd = ad;
            _isAdReady = true;
            _isAdLoading = false;
            _setupAdCallbacks(ad);
          },
          onAdFailedToLoad: (error) {
            safePrint('❌ Interstitial ad failed to load: ${error.message}');
            _isAdLoading = false;
            _isAdReady = false;
            
            // Track analytics
            UnifiedAnalyticsManager().trackEvent('interstitial_load_failed', {
              'error_code': error.code,
              'error_message': error.message,
            });
            
            // Retry after 30 seconds
            Future.delayed(const Duration(seconds: 30), () {
              if (!_isAdReady && !_isAdLoading) {
                _loadAd();
              }
            });
          },
        ),
      );
    } catch (e) {
      safePrint('❌ Exception loading interstitial ad: $e');
      _isAdLoading = false;
      _isAdReady = false;
    }
  }

  /// Set up ad lifecycle callbacks
  void _setupAdCallbacks(InterstitialAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        safePrint('📺 Interstitial ad showed');
        _lastAdShownTime = DateTime.now();
        _winsSinceLastAd = 0;
        
        // Track analytics
        UnifiedAnalyticsManager().trackEvent('interstitial_shown', {
          'wins_this_session': _winsThisSession,
          'is_first_session': _isFirstSession,
          'time_since_last_ad': _lastAdShownTime != null 
            ? DateTime.now().difference(_lastAdShownTime!).inSeconds 
            : null,
        });
      },
      onAdDismissedFullScreenContent: (ad) {
        safePrint('📺 Interstitial ad dismissed');
        ad.dispose();
        _isAdReady = false;
        _loadAd(); // Load next ad
        
        // ✅ FIX: Call the stored callback when ad is ACTUALLY dismissed
        if (_pendingOnAdClosed != null) {
          safePrint('✅ Calling onAdClosed callback after ad dismissed');
          _pendingOnAdClosed!();
          _pendingOnAdClosed = null; // Clear the callback
        }
        
        // Track analytics
        UnifiedAnalyticsManager().trackEvent('interstitial_dismissed', {
          'wins_this_session': _winsThisSession,
        });
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        safePrint('❌ Interstitial ad failed to show: ${error.message}');
        ad.dispose();
        _isAdReady = false;
        _loadAd();
        
        // ✅ FIX: Call the stored callback even if ad fails
        if (_pendingOnAdClosed != null) {
          safePrint('✅ Calling onAdClosed callback after ad failed');
          _pendingOnAdClosed!();
          _pendingOnAdClosed = null; // Clear the callback
        }
        
        // Track analytics
        UnifiedAnalyticsManager().trackEvent('interstitial_show_failed', {
          'error_code': error.code,
          'error_message': error.message,
        });
      },
    );
  }

  // ============================================================================
  // PUBLIC API
  // ============================================================================

  /// Call this when player wins a level
  Future<void> onLevelWon() async {
    _winsThisSession++;
    _winsSinceLastAd++;
    
    safePrint('🏆 Level won! Wins this session: $_winsThisSession, Wins since last ad: $_winsSinceLastAd');
  }

  /// Check if ad should be shown based on current state
  Future<bool> shouldShowAd() async {
    // Check if ad is ready
    if (!_isAdReady) {
      safePrint('📺 Ad not ready to show');
      return false;
    }

    // First session: Grace period (first 3 wins = no ads)
    if (_isFirstSession && _winsThisSession <= _graceWins) {
      safePrint('📺 First session grace period (${_winsThisSession}/$_graceWins wins)');
      return false;
    }

    // Check wins frequency (every 2nd win)
    if (_winsSinceLastAd < _winsPerAd) {
      safePrint('📺 Not enough wins since last ad ($_winsSinceLastAd/$_winsPerAd)');
      return false;
    }

    // Check time-based cooldown (2 minutes)
    if (_lastAdShownTime != null) {
      final timeSinceLastAd = DateTime.now().difference(_lastAdShownTime!);
      if (timeSinceLastAd < _minTimeBetweenAds) {
        final remainingSeconds = (_minTimeBetweenAds - timeSinceLastAd).inSeconds;
        safePrint('📺 Cooldown active (${remainingSeconds}s remaining)');
        return false;
      }
    }

    safePrint('✅ All conditions met - showing ad!');
    return true;
  }

  /// Show the interstitial ad
  Future<void> showAd({VoidCallback? onAdClosed}) async {
    if (!_isAdReady || _interstitialAd == null) {
      safePrint('⚠️ Cannot show ad - not ready');
      onAdClosed?.call();
      return;
    }

    try {
      // ✅ FIX: Store callback to call when ad is ACTUALLY dismissed
      _pendingOnAdClosed = onAdClosed;
      
      // Mark that user has seen an interstitial (no longer first session after first ad)
      if (_isFirstSession) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('has_seen_interstitial', true);
        _isFirstSession = false;
        safePrint('📺 First interstitial shown - future sessions will skip grace period');
      }

      // Show the ad (callback will be called by onAdDismissedFullScreenContent)
      await _interstitialAd!.show();
    } catch (e) {
      safePrint('❌ Exception showing interstitial ad: $e');
      _pendingOnAdClosed = null; // Clear stored callback on error
      onAdClosed?.call();
    }
  }

  /// Check and show ad if conditions are met
  /// Returns true if ad was shown, false otherwise
  Future<bool> checkAndShowAd({VoidCallback? onAdClosed}) async {
    final shouldShow = await shouldShowAd();
    
    if (shouldShow) {
      await showAd(onAdClosed: onAdClosed);
      return true;
    }
    
    return false;
  }

  // ============================================================================
  // SESSION MANAGEMENT
  // ============================================================================

  /// Reset session counters (call on app restart if needed)
  void resetSession() {
    _winsThisSession = 0;
    _winsSinceLastAd = 0;
    safePrint('📺 Session reset');
  }

  /// Dispose of resources
  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isAdReady = false;
    _isAdLoading = false;
    safePrint('📺 InterstitialAdManager disposed');
  }

  // ============================================================================
  // DEBUG / TESTING
  // ============================================================================

  /// Get current state for debugging
  Map<String, dynamic> getDebugState() {
    return {
      'is_ready': _isAdReady,
      'is_loading': _isAdLoading,
      'wins_this_session': _winsThisSession,
      'wins_since_last_ad': _winsSinceLastAd,
      'is_first_session': _isFirstSession,
      'last_ad_time': _lastAdShownTime?.toIso8601String(),
      'cooldown_remaining': _lastAdShownTime != null
          ? _minTimeBetweenAds.inSeconds - DateTime.now().difference(_lastAdShownTime!).inSeconds
          : 0,
    };
  }

  /// Force show ad for testing (bypasses all checks)
  Future<void> forceShowAdForTesting({VoidCallback? onAdClosed}) async {
    if (_isAdReady && _interstitialAd != null) {
      safePrint('🧪 FORCE SHOWING AD FOR TESTING');
      await _interstitialAd!.show();
      onAdClosed?.call();
    } else {
      safePrint('🧪 Cannot force show - ad not ready');
      onAdClosed?.call();
    }
  }
}


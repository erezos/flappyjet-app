import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/analytics/unified_analytics_manager.dart';
import '../core/events/event_bus.dart';
import '../core/debug_logger.dart';

/// Manages interstitial ads for Story Mode with frequency caps and cooldowns
/// 
/// Strategy:
/// - 1st win: No ad (grace period)
/// - 2nd win onwards: Show ad every win + 2min cooldown
/// 
/// This ensures positive first impression while maximizing revenue.
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
  
  /// ✅ NEW LOGIC: First win is free, then ads every win (with cooldown)
  /// No grace period, no "every 2nd win" - just cooldown-based after 1st win
  
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
  
  /// ✅ NEW: Total wins in lifetime (across all sessions)
  /// Used to check if this is the very first win ever
  int _totalLifetimeWins = 0;
  
  /// Total wins this session
  int _winsThisSession = 0;

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
      // Load lifetime wins count
      final prefs = await SharedPreferences.getInstance();
      _totalLifetimeWins = prefs.getInt('total_lifetime_wins') ?? 0;
      
      safePrint('📺 InterstitialAdManager initialized (Lifetime wins: $_totalLifetimeWins)');
      
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
        
        // ✅ FIX: Calculate time since last ad BEFORE updating the timestamp
        final timeSinceLastAd = _lastAdShownTime != null 
          ? DateTime.now().difference(_lastAdShownTime!).inSeconds 
          : null;
        
        // Update timestamp AFTER calculating the difference
        _lastAdShownTime = DateTime.now();
        
        // Track analytics to Firebase
        UnifiedAnalyticsManager().trackEvent('interstitial_shown', {
          'wins_this_session': _winsThisSession,
          'lifetime_wins': _totalLifetimeWins,
          'time_since_last_ad': timeSinceLastAd,
        });
        
        // 📊 Send to Railway backend via EventBus
        EventBus().fire('interstitial_shown', {
          'wins_this_session': _winsThisSession,
          'lifetime_wins': _totalLifetimeWins,
          'time_since_last_ad': timeSinceLastAd,
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
        
        // Track analytics to Firebase
        UnifiedAnalyticsManager().trackEvent('interstitial_dismissed', {
          'wins_this_session': _winsThisSession,
        });
        
        // 📊 Send to Railway backend via EventBus (optional but good for completeness)
        EventBus().fire('interstitial_dismissed', {
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
    _totalLifetimeWins++;
    
    // Save lifetime wins
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('total_lifetime_wins', _totalLifetimeWins);
    } catch (e) {
      safePrint('⚠️ Failed to save lifetime wins: $e');
    }
    
    safePrint('🏆 Level won! Session wins: $_winsThisSession, Lifetime wins: $_totalLifetimeWins');
  }

  /// Check if ad should be shown based on current state
  Future<bool> shouldShowAd() async {
    // Check if ad is ready
    if (!_isAdReady) {
      safePrint('📺 Ad not ready to show');
      return false;
    }

    // ✅ NEW LOGIC: First win ever = no ad
    if (_totalLifetimeWins <= 1) {
      safePrint('📺 First win ever - no ad (Lifetime wins: $_totalLifetimeWins)');
      return false;
    }

    // ✅ NEW LOGIC: After first win, show ad every time IF cooldown has passed
    if (_lastAdShownTime != null) {
      final timeSinceLastAd = DateTime.now().difference(_lastAdShownTime!);
      if (timeSinceLastAd < _minTimeBetweenAds) {
        final remainingSeconds = (_minTimeBetweenAds - timeSinceLastAd).inSeconds;
        safePrint('📺 Cooldown active (${remainingSeconds}s remaining, ${timeSinceLastAd.inSeconds}s since last ad)');
        return false;
      }
    }

    safePrint('✅ All conditions met - showing ad! (Lifetime wins: $_totalLifetimeWins)');
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
    // NOTE: _totalLifetimeWins persists across sessions (saved in SharedPreferences)
    safePrint('📺 Session reset (Lifetime wins preserved: $_totalLifetimeWins)');
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
      'total_lifetime_wins': _totalLifetimeWins,
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


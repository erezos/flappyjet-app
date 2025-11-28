import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/analytics/unified_analytics_manager.dart';
import '../core/events/event_bus.dart';
import '../core/debug_logger.dart';

/// Manages interstitial ads for Story Mode with frequency caps and cooldowns
/// 
/// Strategy (Updated):
/// - First ad: After completing level 3
/// - Then: Every 2 level wins (levels 3, 5, 7, 9, etc.)
/// - Cooldown: 2 minutes between ads
/// - Rewarded video bonus: 3 minute cooldown after watching rewarded ad
/// 
/// This balances user experience with revenue optimization.
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
  
  /// First interstitial shows after this many level completions
  static const int _firstAdAfterLevels = 3;
  
  /// Show ad every N level wins (after first ad)
  static const int _adFrequencyLevels = 2;
  
  /// Default cooldown between interstitial ads
  static const Duration _defaultCooldown = Duration(minutes: 2);
  
  /// Extended cooldown after user watches a rewarded video
  static const Duration _rewardedVideoCooldown = Duration(minutes: 3);

  // ============================================================================
  // STATE
  // ============================================================================
  
  InterstitialAd? _interstitialAd;
  bool _isAdLoading = false;
  bool _isAdReady = false;
  
  /// Store callback to call when ad is ACTUALLY dismissed
  VoidCallback? _pendingOnAdClosed;
  
  /// Last time an ad was shown
  DateTime? _lastAdShownTime;
  
  /// Track when current ad started showing (for view duration)
  DateTime? _currentAdStartTime;
  
  /// Track if user clicked the ad (positive engagement)
  bool _currentAdWasClicked = false;
  
  /// Total level wins in lifetime (across all sessions)
  int _totalLifetimeWins = 0;
  
  /// Total wins this session
  int _winsThisSession = 0;
  
  /// Level number at last ad shown (to track "every 2 levels")
  int _lastAdAtWinCount = 0;
  
  /// Current cooldown duration (can be extended after rewarded video)
  Duration _currentCooldown = _defaultCooldown;

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
      _lastAdAtWinCount = prefs.getInt('last_ad_at_win_count') ?? 0;
      
      safePrint('📺 InterstitialAdManager initialized');
      safePrint('📺 Config: First ad after level $_firstAdAfterLevels, then every $_adFrequencyLevels levels');
      safePrint('📺 Lifetime wins: $_totalLifetimeWins, Last ad at win: $_lastAdAtWinCount');
      
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
        
        // Calculate time since last ad BEFORE updating the timestamp
        final timeSinceLastAd = _lastAdShownTime != null 
          ? DateTime.now().difference(_lastAdShownTime!).inSeconds 
          : null;
        
        // Update timestamp AFTER calculating the difference
        _lastAdShownTime = DateTime.now();
        
        // Track when this ad started (for view duration calculation)
        _currentAdStartTime = DateTime.now();
        _currentAdWasClicked = false; // Reset click tracking
        
        // Track analytics to Firebase
        UnifiedAnalyticsManager().trackEvent('interstitial_shown', {
          'wins_this_session': _winsThisSession,
          'lifetime_wins': _totalLifetimeWins,
          'time_since_last_ad': timeSinceLastAd,
          'current_cooldown_minutes': _currentCooldown.inMinutes,
        });
        
        // 📊 Send to Railway backend via EventBus
        EventBus().fire('interstitial_shown', {
          'wins_this_session': _winsThisSession,
          'lifetime_wins': _totalLifetimeWins,
          'time_since_last_ad': timeSinceLastAd,
        });
        
        // 💰 Track ad revenue for ROI/LTV calculation
        // Estimated eCPM for interstitials: ~$10 average → $0.01 per impression
        // Conservative estimate to avoid over-reporting
        EventBus().fire('ad_revenue', {
          'ad_type': 'interstitial',
          'ad_format': 'fullscreen',
          'estimated_revenue_usd': 0.01, // $10 eCPM / 1000
          'currency': 'USD',
        });
        safePrint('💰 Ad revenue tracked: \$0.01 (interstitial)');
      },
      onAdDismissedFullScreenContent: (ad) {
        safePrint('📺 Interstitial ad dismissed');
        
        // Calculate view duration
        final viewDurationSeconds = _currentAdStartTime != null 
          ? DateTime.now().difference(_currentAdStartTime!).inSeconds 
          : null;
        _currentAdStartTime = null; // Reset
        
        // Early dismissal = closed in less than 5 seconds (user likely hit back/X)
        final isEarlyDismissal = viewDurationSeconds != null && viewDurationSeconds < 5;
        
        safePrint('📺 Ad view duration: ${viewDurationSeconds}s, early dismissal: $isEarlyDismissal, clicked: $_currentAdWasClicked');
        
        ad.dispose();
        _isAdReady = false;
        _loadAd(); // Load next ad
        
        // Reset cooldown to default after showing an ad
        _currentCooldown = _defaultCooldown;
        
        // Call the stored callback when ad is ACTUALLY dismissed
        if (_pendingOnAdClosed != null) {
          safePrint('✅ Calling onAdClosed callback after ad dismissed');
          _pendingOnAdClosed!();
          _pendingOnAdClosed = null; // Clear the callback
        }
        
        // Track analytics to Firebase
        UnifiedAnalyticsManager().trackEvent('interstitial_dismissed', {
          'wins_this_session': _winsThisSession,
          'view_duration_seconds': viewDurationSeconds,
          'is_early_dismissal': isEarlyDismissal,
          'was_clicked': _currentAdWasClicked,
        });
        
        // 📊 Send to Railway backend via EventBus
        EventBus().fire('interstitial_dismissed', {
          'wins_this_session': _winsThisSession,
          'view_duration_seconds': viewDurationSeconds,
          'is_early_dismissal': isEarlyDismissal,
          'was_clicked': _currentAdWasClicked,
        });
        
        _currentAdWasClicked = false; // Reset
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        safePrint('❌ Interstitial ad failed to show: ${error.message}');
        ad.dispose();
        _isAdReady = false;
        _loadAd();
        
        // Call the stored callback even if ad fails
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
      onAdClicked: (ad) {
        // ✅ NEW: Track when user clicks the ad (good engagement!)
        safePrint('📺 Interstitial ad CLICKED by user');
        _currentAdWasClicked = true;
        
        UnifiedAnalyticsManager().trackEvent('interstitial_clicked', {
          'wins_this_session': _winsThisSession,
          'lifetime_wins': _totalLifetimeWins,
        });
        
        EventBus().fire('interstitial_clicked', {
          'wins_this_session': _winsThisSession,
          'lifetime_wins': _totalLifetimeWins,
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
    
    // Save state
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('total_lifetime_wins', _totalLifetimeWins);
    } catch (e) {
      safePrint('⚠️ Failed to save lifetime wins: $e');
    }
    
    safePrint('🏆 Level won! Session wins: $_winsThisSession, Lifetime wins: $_totalLifetimeWins');
  }

  /// Call this when user watches a rewarded video (for continue)
  /// This extends the interstitial cooldown to give user a break
  void onRewardedVideoWatched() {
    _currentCooldown = _rewardedVideoCooldown;
    _lastAdShownTime = DateTime.now(); // Reset the timer
    
    safePrint('🎬 Rewarded video watched - interstitial cooldown extended to ${_currentCooldown.inMinutes} minutes');
    
    UnifiedAnalyticsManager().trackEvent('interstitial_cooldown_extended', {
      'reason': 'rewarded_video',
      'new_cooldown_minutes': _currentCooldown.inMinutes,
    });
  }

  /// Check if ad should be shown based on current state
  Future<bool> shouldShowAd() async {
    // Check if ad is ready
    if (!_isAdReady) {
      safePrint('📺 Ad not ready to show');
      return false;
    }

    // Rule 1: First ad only after completing level 3 (3 wins)
    if (_totalLifetimeWins < _firstAdAfterLevels) {
      safePrint('📺 Not enough wins yet (${_totalLifetimeWins}/$_firstAdAfterLevels) - no ad');
      return false;
    }

    // Rule 2: Check cooldown
    if (_lastAdShownTime != null) {
      final timeSinceLastAd = DateTime.now().difference(_lastAdShownTime!);
      if (timeSinceLastAd < _currentCooldown) {
        final remainingSeconds = (_currentCooldown - timeSinceLastAd).inSeconds;
        safePrint('📺 Cooldown active (${remainingSeconds}s remaining, cooldown: ${_currentCooldown.inMinutes}min)');
        return false;
      }
    }

    // Rule 3: Every 2 levels after first ad
    // First ad at level 3, then 5, 7, 9, etc.
    final levelsSinceLastAd = _totalLifetimeWins - _lastAdAtWinCount;
    
    if (_lastAdAtWinCount == 0) {
      // First ad ever - show it (we already checked we have >= 3 wins)
      safePrint('📺 First interstitial ad! (Level $_totalLifetimeWins)');
      return true;
    }
    
    if (levelsSinceLastAd >= _adFrequencyLevels) {
      safePrint('📺 Time for ad! ($levelsSinceLastAd levels since last ad, need $_adFrequencyLevels)');
      return true;
    }

    safePrint('📺 Not enough levels since last ad ($levelsSinceLastAd/$_adFrequencyLevels)');
    return false;
  }

  /// Show the interstitial ad
  Future<void> showAd({VoidCallback? onAdClosed}) async {
    if (!_isAdReady || _interstitialAd == null) {
      safePrint('⚠️ Cannot show ad - not ready');
      onAdClosed?.call();
      return;
    }

    try {
      // Store callback to call when ad is ACTUALLY dismissed
      _pendingOnAdClosed = onAdClosed;
      
      // Record that we showed an ad at this win count
      _lastAdAtWinCount = _totalLifetimeWins;
      
      // Save state
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('last_ad_at_win_count', _lastAdAtWinCount);
      } catch (e) {
        safePrint('⚠️ Failed to save last_ad_at_win_count: $e');
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
    _currentCooldown = _defaultCooldown;
    // NOTE: _totalLifetimeWins and _lastAdAtWinCount persist across sessions
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
      'last_ad_at_win_count': _lastAdAtWinCount,
      'levels_since_last_ad': _totalLifetimeWins - _lastAdAtWinCount,
      'last_ad_time': _lastAdShownTime?.toIso8601String(),
      'current_cooldown_minutes': _currentCooldown.inMinutes,
      'cooldown_remaining_seconds': _lastAdShownTime != null
          ? (_currentCooldown.inSeconds - DateTime.now().difference(_lastAdShownTime!).inSeconds).clamp(0, 999)
          : 0,
      'config': {
        'first_ad_after_levels': _firstAdAfterLevels,
        'ad_frequency_levels': _adFrequencyLevels,
        'default_cooldown_minutes': _defaultCooldown.inMinutes,
        'rewarded_video_cooldown_minutes': _rewardedVideoCooldown.inMinutes,
      },
    };
  }

  /// Force show ad for testing (bypasses all checks)
  Future<void> forceShowAdForTesting({VoidCallback? onAdClosed}) async {
    if (_isAdReady && _interstitialAd != null) {
      safePrint('🧪 FORCE SHOWING AD FOR TESTING');
      _lastAdAtWinCount = _totalLifetimeWins;
      await _interstitialAd!.show();
      onAdClosed?.call();
    } else {
      safePrint('🧪 Cannot force show - ad not ready');
      onAdClosed?.call();
    }
  }
  
  /// Reset for testing
  Future<void> resetForTesting() async {
    _totalLifetimeWins = 0;
    _lastAdAtWinCount = 0;
    _winsThisSession = 0;
    _currentCooldown = _defaultCooldown;
    _lastAdShownTime = null;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('total_lifetime_wins', 0);
      await prefs.setInt('last_ad_at_win_count', 0);
    } catch (e) {
      safePrint('⚠️ Failed to reset SharedPreferences: $e');
    }
    
    safePrint('🧪 InterstitialAdManager reset for testing');
  }
}

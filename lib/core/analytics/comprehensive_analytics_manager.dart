// 📊 Comprehensive Analytics Manager v2
// Fires all 16 KPIs events asynchronously and non-blocking
// Production-ready with Railway Pro backend integration

import 'dart:async';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';
import '../../core/debug_logger.dart';
import '../../core/network/network_manager.dart';
import '../../core/identity/unified_id_manager.dart';

/// Comprehensive analytics manager that tracks all 16 KPIs
/// Fires events asynchronously and non-blocking for optimal performance
class ComprehensiveAnalyticsManager {
  static final ComprehensiveAnalyticsManager _instance = ComprehensiveAnalyticsManager._internal();
  factory ComprehensiveAnalyticsManager() => _instance;
  ComprehensiveAnalyticsManager._internal();

  // Core services
  final NetworkManager _networkManager = NetworkManager();
  final UnifiedIdManager _idManager = UnifiedIdManager();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  
  // Event batching and queuing
  final List<Map<String, dynamic>> _eventQueue = [];
  Timer? _batchTimer;
  Timer? _sessionTimer;
  
  // Session management
  String? _currentSessionId;
  DateTime? _sessionStartTime;
  int _gamesInCurrentSession = 0;
  bool _isSessionActive = false;
  
  // User state
  String? _playerId;
  String? _userType;
  String? _platform;
  String? _appVersion;
  String? _deviceModel;
  
  // Performance optimization
  static const int _maxBatchSize = 50;
  static const Duration _batchInterval = Duration(seconds: 30);
  static const Duration _sessionTimeout = Duration(minutes: 30);
  
  /// Initialize the analytics manager
  Future<void> initialize() async {
    try {
      safePrint('📊 ComprehensiveAnalyticsManager: Initializing...');
      
      // Initialize core services
      await _idManager.initialize();
      
      // Get device and app info
      await _loadDeviceInfo();
      
      // Load user state
      await _loadUserState();
      
      // Start session management
      _startSessionManagement();
      
      // Start batch processing
      _startBatchProcessing();
      
      // Fire initialization event
      await trackEvent('app_launch', {
        'platform': _platform,
        'app_version': _appVersion,
        'device_model': _deviceModel,
        'user_type': _userType,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      
      safePrint('📊 ComprehensiveAnalyticsManager: Initialized successfully');
    } catch (e) {
      safePrint('📊 ComprehensiveAnalyticsManager: Initialization failed: $e');
    }
  }
  
  /// Load device and app information
  Future<void> _loadDeviceInfo() async {
    try {
      // Get real app version from package info
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = packageInfo.version;
      
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        _platform = 'android';
        _deviceModel = '${androidInfo.brand} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        _platform = 'ios';
        _deviceModel = '${iosInfo.name} ${iosInfo.model}';
      }
    } catch (e) {
      safePrint('📊 Failed to load device info: $e');
      _platform = 'unknown';
      _deviceModel = 'unknown';
      _appVersion = '1.5.5'; // Fallback to current version
    }
  }
  
  /// Load user state from preferences
  Future<void> _loadUserState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _playerId = prefs.getString('player_id') ?? await _idManager.getMasterId();
      _userType = prefs.getString('user_type') ?? 'anonymous';
    } catch (e) {
      safePrint('📊 Failed to load user state: $e');
      _playerId = await _idManager.getMasterId();
      _userType = 'anonymous';
    }
  }
  
  /// Start session management
  void _startSessionManagement() {
    _sessionTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_isSessionActive && _sessionStartTime != null) {
        final sessionDuration = DateTime.now().difference(_sessionStartTime!);
        if (sessionDuration > _sessionTimeout) {
          _endSession();
        }
      }
    });
  }
  
  /// Start batch processing
  void _startBatchProcessing() {
    _batchTimer = Timer.periodic(_batchInterval, (timer) {
      _processBatch();
    });
  }
  
  /// Start a new session
  Future<void> startSession() async {
    if (_isSessionActive) {
      safePrint('📊 Session already active, extending current session');
      return;
    }
    
    _currentSessionId = const Uuid().v4();
    _sessionStartTime = DateTime.now();
    _gamesInCurrentSession = 0;
    _isSessionActive = true;
    
    await trackEvent('session_start', {
      'session_id': _currentSessionId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'user_type': _userType,
    });
    
    safePrint('📊 Session started: $_currentSessionId');
  }
  
  /// End current session
  Future<void> _endSession() async {
    if (!_isSessionActive || _currentSessionId == null || _sessionStartTime == null) {
      return;
    }
    
    final sessionDuration = DateTime.now().difference(_sessionStartTime!);
    
    await trackEvent('session_end', {
      'session_id': _currentSessionId,
      'session_duration_seconds': sessionDuration.inSeconds,
      'games_in_session': _gamesInCurrentSession,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    
    _isSessionActive = false;
    _currentSessionId = null;
    _sessionStartTime = null;
    _gamesInCurrentSession = 0;
    
    safePrint('📊 Session ended: Duration ${sessionDuration.inSeconds}s, Games $_gamesInCurrentSession');
  }
  
  /// Track a game start
  Future<void> trackGameStart() async {
    _gamesInCurrentSession++;
    
    await trackEvent('game_start', {
      'games_in_session': _gamesInCurrentSession,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    
    safePrint('📊 Game started: Session game #$_gamesInCurrentSession');
  }
  
  /// Track a game end
  Future<void> trackGameEnd({
    required int score,
    required int lives,
    required bool isHighScore,
    required String endReason,
  }) async {
    await trackEvent('game_end', {
      'score': score,
      'lives_remaining': lives,
      'is_high_score': isHighScore,
      'end_reason': endReason,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    
    safePrint('📊 Game ended: Score $score, Reason $endReason');
  }
  
  /// Track mission completion
  Future<void> trackMissionComplete({
    required String missionType,
    required String missionId,
    required int progress,
    required bool isDailyMission,
  }) async {
    await trackEvent('mission_complete', {
      'mission_type': missionType,
      'mission_id': missionId,
      'progress': progress,
      'is_daily_mission': isDailyMission,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    
    safePrint('📊 Mission completed: $missionType ($missionId)');
  }
  
  /// Track daily mission cycle completion
  Future<void> trackDailyMissionCycleComplete({
    required int missionsCompleted,
    required int totalMissions,
    required bool allMissionsCompleted,
  }) async {
    await trackEvent('daily_mission_cycle_complete', {
      'missions_completed': missionsCompleted,
      'total_missions': totalMissions,
      'all_missions_completed': allMissionsCompleted,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    
    safePrint('📊 Daily mission cycle: $missionsCompleted/$totalMissions (All: $allMissionsCompleted)');
  }
  
  /// Track achievement unlock
  Future<void> trackAchievementUnlock({
    required String achievementId,
    required String achievementName,
    required int achievementsCount,
  }) async {
    await trackEvent('achievement_unlock', {
      'achievement_id': achievementId,
      'achievement_name': achievementName,
      'achievements_count': achievementsCount,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    
    safePrint('📊 Achievement unlocked: $achievementName');
  }
  
  /// Track continue usage
  Future<void> trackContinueUsed({
    required String continueType, // 'ad' or 'gems'
    required int gemsSpent,
    required bool success,
  }) async {
    await trackEvent('continue_used', {
      'continue_type': continueType,
      'gems_spent': gemsSpent,
      'success': success,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    
    safePrint('📊 Continue used: $continueType (Gems: $gemsSpent, Success: $success)');
  }
  
  /// Track ad events
  Future<void> trackAdShown({required String adType}) async {
    await trackEvent('ad_shown', {
      'ad_type': adType,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    
    safePrint('📊 Ad shown: $adType');
  }
  
  Future<void> trackAdCompleted({required String adType, required String rewardType, required int rewardAmount}) async {
    await trackEvent('ad_completed', {
      'ad_type': adType,
      'reward_type': rewardType,
      'reward_amount': rewardAmount,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    
    safePrint('📊 Ad completed: $adType (Reward: $rewardAmount $rewardType)');
  }
  
  Future<void> trackAdAbandoned({required String adType, required String reason}) async {
    await trackEvent('ad_abandoned', {
      'ad_type': adType,
      'reason': reason,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    
    safePrint('📊 Ad abandoned: $adType (Reason: $reason)');
  }
  
  /// Track currency events
  Future<void> trackCurrencyEarned({
    required String currencyType, // 'coins' or 'gems'
    required int amount,
    required String source, // 'game', 'mission', 'achievement', 'ad'
  }) async {
    await trackEvent('currency_earned', {
      'currency_type': currencyType,
      'amount': amount,
      'source': source,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    
    safePrint('📊 Currency earned: $amount $currencyType from $source');
  }
  
  Future<void> trackCurrencySpent({
    required String currencyType, // 'coins' or 'gems'
    required int amount,
    required String purpose, // 'continue', 'purchase', 'upgrade'
  }) async {
    await trackEvent('currency_spent', {
      'currency_type': currencyType,
      'amount': amount,
      'purpose': purpose,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    
    safePrint('📊 Currency spent: $amount $currencyType for $purpose');
  }
  
  /// Track IAP purchases
  Future<void> trackIAPPurchase({
    required String productId,
    required String productType, // 'gems', 'hearts', 'jet', 'remove_ads'
    required double priceUsd,
    required String currency,
    required bool success,
  }) async {
    await trackEvent('iap_purchase', {
      'product_id': productId,
      'product_type': productType,
      'price_usd': priceUsd,
      'currency': currency,
      'success': success,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    
    safePrint('📊 IAP Purchase: $productType (\$${priceUsd.toStringAsFixed(2)})');
  }
  
  /// Track retention events
  Future<void> trackRetentionEvent({
    required String eventType, // 'day_1', 'day_7', 'day_30'
    required bool isRetained,
  }) async {
    await trackEvent('retention_event', {
      'event_type': eventType,
      'is_retained': isRetained,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    
    safePrint('📊 Retention event: $eventType (Retained: $isRetained)');
  }
  
  /// Track daily summary
  Future<void> trackDailySummary({
    required int gamesPlayed,
    required int totalScore,
    required int missionsCompleted,
    required int achievementsUnlocked,
    required int coinsEarned,
    required int gemsEarned,
    required int coinsSpent,
    required int gemsSpent,
    required int continuesUsed,
    required int adsWatched,
  }) async {
    await trackEvent('daily_summary', {
      'games_played': gamesPlayed,
      'total_score': totalScore,
      'missions_completed': missionsCompleted,
      'achievements_unlocked': achievementsUnlocked,
      'coins_earned': coinsEarned,
      'gems_earned': gemsEarned,
      'coins_spent': coinsSpent,
      'gems_spent': gemsSpent,
      'continues_used': continuesUsed,
      'ads_watched': adsWatched,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    
    safePrint('📊 Daily summary: $gamesPlayed games, $missionsCompleted missions, $achievementsUnlocked achievements');
  }
  
  /// Track error events
  Future<void> trackError({
    required String errorType,
    required String errorMessage,
    required String stackTrace,
    required bool isFatal,
  }) async {
    await trackEvent('error_occurred', {
      'error_type': errorType,
      'error_message': errorMessage,
      'stack_trace': stackTrace,
      'is_fatal': isFatal,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    
    safePrint('📊 Error tracked: $errorType (Fatal: $isFatal)');
  }
  
  /// Core event tracking method - adds to queue for batch processing
  Future<void> trackEvent(String eventName, Map<String, dynamic> eventData) async {
    try {
      // Add to queue
      final event = {
        'event_name': eventName,
        'event_data': eventData,
        'session_id': _currentSessionId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'user_type': _userType,
        'player_id': _playerId,
      };
      
      _eventQueue.add(event);
      
      // Process immediately if queue is full
      if (_eventQueue.length >= _maxBatchSize) {
        _processBatch();
      }
      
    } catch (e) {
      safePrint('📊 Failed to track event $eventName: $e');
    }
  }
  
  /// Process batch of events
  Future<void> _processBatch() async {
    if (_eventQueue.isEmpty) return;
    
    try {
      final batch = List<Map<String, dynamic>>.from(_eventQueue);
      _eventQueue.clear();
      
      safePrint('📊 Processing batch of ${batch.length} events');
      
      // Send to backend v2 endpoint
      final result = await _networkManager.request(NetworkRequest(
        endpoint: '/api/analytics/v2/batch',
        method: 'POST',
        body: {'events': batch},
      ));
      
      if (result.success) {
        safePrint('📊 ✅ Batch processed successfully: ${batch.length} events');
      } else {
        safePrint('📊 ❌ Batch processing failed: ${result.error}');
        // Re-queue failed events (with limit to prevent memory issues)
        if (_eventQueue.length < 100) {
          _eventQueue.addAll(batch.take(20)); // Re-queue first 20 events
        }
      }
      
    } catch (e) {
      safePrint('📊 Batch processing error: $e');
    }
  }
  
  /// Force process all queued events
  Future<void> flushEvents() async {
    await _processBatch();
  }
  
  /// Update user type (anonymous -> registered)
  Future<void> updateUserType(String newUserType) async {
    _userType = newUserType;
    
    // Update preferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_type', newUserType);
    } catch (e) {
      safePrint('📊 Failed to update user type in preferences: $e');
    }
    
    safePrint('📊 User type updated to: $newUserType');
  }
  
  /// Update player ID
  Future<void> updatePlayerId(String newPlayerId) async {
    _playerId = newPlayerId;
    safePrint('📊 Player ID updated to: $newPlayerId');
  }
  
  /// Get analytics status
  Map<String, dynamic> getAnalyticsStatus() {
    return {
      'is_initialized': _playerId != null,
      'current_session_id': _currentSessionId,
      'is_session_active': _isSessionActive,
      'games_in_session': _gamesInCurrentSession,
      'queue_size': _eventQueue.length,
      'user_type': _userType,
      'platform': _platform,
      'app_version': _appVersion,
    };
  }
  
  /// Dispose resources
  void dispose() {
    _batchTimer?.cancel();
    _sessionTimer?.cancel();
    _endSession();
    flushEvents();
  }
}
/// 📊 Firebase Analytics Manager - Production-ready analytics tracking for FlappyJet Pro
library;

import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/debug_logger.dart';

/// Comprehensive analytics manager for tracking game events, user behavior, and performance
class FirebaseAnalyticsManager {
  static final FirebaseAnalyticsManager _instance = FirebaseAnalyticsManager._internal();
  factory FirebaseAnalyticsManager() => _instance;
  FirebaseAnalyticsManager._internal();

  late FirebaseAnalytics _analytics;
  late FirebaseCrashlytics _crashlytics;
  late FirebasePerformance _performance;
  
  bool _isInitialized = false;
  String? _playerId;
  String? _deviceModel;
  String? _appVersion;

  /// Initialize Firebase Analytics with comprehensive setup
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _analytics = FirebaseAnalytics.instance;
      _crashlytics = FirebaseCrashlytics.instance;
      _performance = FirebasePerformance.instance;
      
      // Set up device and app info
      await _setupDeviceInfo();
      
      // Configure Crashlytics
      await _configureCrashlytics();
      
      // Set default analytics properties
      await _setDefaultProperties();
      
      _isInitialized = true;
      safePrint('📊 Firebase Analytics Manager initialized successfully');
      
      // Track app launch
      await trackEvent('app_launch', {
        'device_model': _deviceModel ?? 'unknown',
        'app_version': _appVersion ?? 'unknown',
        'platform': defaultTargetPlatform.name,
      });
      
    } catch (e) {
      safePrint('📊 ❌ Firebase Analytics initialization failed: $e');
      _crashlytics.recordError(e, null, fatal: false);
    }
  }

  /// Set up device and app information
  Future<void> _setupDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();
      
      _appVersion = packageInfo.version;
      
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await deviceInfo.androidInfo;
        _deviceModel = '${androidInfo.manufacturer} ${androidInfo.model}';
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _deviceModel = '${iosInfo.name} ${iosInfo.model}';
      }
    } catch (e) {
      safePrint('📊 Failed to get device info: $e');
    }
  }

  /// Configure Firebase Crashlytics
  Future<void> _configureCrashlytics() async {
    try {
      // Enable crash collection in release mode
      await _crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
      
      // Set custom keys for better crash analysis
      await _crashlytics.setCustomKey('game_version', _appVersion ?? 'unknown');
      await _crashlytics.setCustomKey('device_model', _deviceModel ?? 'unknown');
      
    } catch (e) {
      safePrint('📊 Failed to configure Crashlytics: $e');
    }
  }

  /// Set default analytics properties
  Future<void> _setDefaultProperties() async {
    try {
      await _analytics.setDefaultEventParameters({
        'app_version': _appVersion ?? 'unknown',
        'device_model': _deviceModel ?? 'unknown',
        'platform': defaultTargetPlatform.name,
      });
    } catch (e) {
      safePrint('📊 Failed to set default properties: $e');
    }
  }

  /// Set user ID for analytics tracking
  Future<void> setUserId(String userId) async {
    if (!_isInitialized) return;
    
    try {
      _playerId = userId;
      await _analytics.setUserId(id: userId);
      await _crashlytics.setUserIdentifier(userId);
      
      safePrint('📊 User ID set: $userId');
    } catch (e) {
      safePrint('📊 Failed to set user ID: $e');
    }
  }

  /// Set user properties for segmentation
  Future<void> setUserProperty(String name, String value) async {
    if (!_isInitialized) return;
    
    try {
      await _analytics.setUserProperty(name: name, value: value);
      await _crashlytics.setCustomKey(name, value);
    } catch (e) {
      safePrint('📊 Failed to set user property $name: $e');
    }
  }

  /// Track custom events with parameters
  Future<void> trackEvent(String eventName, Map<String, dynamic> parameters) async {
    if (!_isInitialized) return;
    
    try {
      // Add timestamp and player ID to all events
      final enrichedParams = Map<String, dynamic>.from(parameters);
      enrichedParams['timestamp'] = DateTime.now().millisecondsSinceEpoch;
      if (_playerId != null) {
        enrichedParams['player_id'] = _playerId;
      }
      
      // Convert parameters to Firebase-compatible types
      final firebaseParams = <String, Object>{};
      for (final entry in enrichedParams.entries) {
        final value = entry.value;
        if (value is bool) {
          firebaseParams[entry.key] = value ? 1 : 0; // Convert bool to int
        } else if (value is String || value is num) {
          firebaseParams[entry.key] = value;
        } else {
          firebaseParams[entry.key] = value.toString(); // Convert other types to string
        }
      }
      
      await _analytics.logEvent(
        name: eventName,
        parameters: firebaseParams,
      );
      
      if (kDebugMode) {
        safePrint('📊 Event tracked: $eventName with params: $enrichedParams');
      }
    } catch (e) {
      safePrint('📊 Failed to track event $eventName: $e');
    }
  }

  // === GAME-SPECIFIC ANALYTICS EVENTS ===

  /// Track game session start
  Future<void> trackGameStart({
    required String gameMode,
    required String selectedJet,
    required String theme,
    int? playerLevel,
    int? totalCoins,
    int? totalGems,
  }) async {
    await trackEvent('game_start', {
      'game_mode': gameMode,
      'selected_jet': selectedJet,
      'theme': theme,
      'player_level': playerLevel ?? 0,
      'total_coins': totalCoins ?? 0,
      'total_gems': totalGems ?? 0,
    });
  }

  /// Track game session end
  Future<void> trackGameEnd({
    required int finalScore,
    required int survivalTimeSeconds,
    required String causeOfDeath,
    required String theme,
    required String selectedJet,
    int? coinsEarned,
    int? gemsEarned,
    bool? usedContinue,
    int? livesUsed,
  }) async {
    await trackEvent('game_end', {
      'final_score': finalScore,
      'survival_time_seconds': survivalTimeSeconds,
      'cause_of_death': causeOfDeath,
      'theme': theme,
      'selected_jet': selectedJet,
      'coins_earned': coinsEarned ?? 0,
      'gems_earned': gemsEarned ?? 0,
      'used_continue': usedContinue ?? false,
      'lives_used': livesUsed ?? 0,
    });
  }

  /// Track level progression
  Future<void> trackLevelProgression({
    required int newLevel,
    required int previousLevel,
    required String unlockMethod,
  }) async {
    await trackEvent('level_up', {
      'new_level': newLevel,
      'previous_level': previousLevel,
      'unlock_method': unlockMethod,
    });
  }

  /// Track in-app purchases
  Future<void> trackPurchase({
    required String itemId,
    required String itemName,
    required double price,
    required String currency,
    required String purchaseType, // 'real_money', 'coins', 'gems'
  }) async {
    await trackEvent('purchase', {
      'item_id': itemId,
      'item_name': itemName,
      'price': price,
      'currency': currency,
      'purchase_type': purchaseType,
    });
  }

  /// Track ad interactions
  Future<void> trackAdEvent({
    required String adType, // 'rewarded', 'interstitial', 'banner'
    required String action, // 'shown', 'clicked', 'completed', 'failed'
    String? adUnitId,
    String? rewardType,
    int? rewardAmount,
  }) async {
    await trackEvent('ad_event', {
      'ad_type': adType,
      'action': action,
      'ad_unit_id': adUnitId ?? 'unknown',
      'reward_type': rewardType,
      'reward_amount': rewardAmount,
    });
  }

  /// Track mission completion
  Future<void> trackMissionComplete({
    required String missionId,
    required String missionType,
    required int rewardCoins,
    required int rewardGems,
    required int completionTimeSeconds,
  }) async {
    await trackEvent('mission_complete', {
      'mission_id': missionId,
      'mission_type': missionType,
      'reward_coins': rewardCoins,
      'reward_gems': rewardGems,
      'completion_time_seconds': completionTimeSeconds,
    });
  }

  /// Track achievement unlocks
  Future<void> trackAchievementUnlock({
    required String achievementId,
    required String achievementName,
    required String category,
    required String rarity,
    int? rewardCoins,
    int? rewardGems,
  }) async {
    await trackEvent('achievement_unlock', {
      'achievement_id': achievementId,
      'achievement_name': achievementName,
      'category': category,
      'rarity': rarity,
      'reward_coins': rewardCoins ?? 0,
      'reward_gems': rewardGems ?? 0,
    });
  }

  /// Track tournament participation
  Future<void> trackTournamentEvent({
    required String action, // 'join', 'score_submit', 'complete'
    required String tournamentId,
    String? tournamentName,
    int? score,
    int? rank,
    int? totalParticipants,
  }) async {
    await trackEvent('tournament_event', {
      'action': action,
      'tournament_id': tournamentId,
      'tournament_name': tournamentName ?? 'unknown',
      'score': score,
      'rank': rank,
      'total_participants': totalParticipants,
    });
  }

  /// Track user engagement metrics
  Future<void> trackEngagement({
    required String action, // 'session_start', 'session_end', 'background', 'foreground'
    int? sessionDurationSeconds,
    int? dailyPlayCount,
    int? weeklyPlayCount,
  }) async {
    await trackEvent('user_engagement', {
      'action': action,
      'session_duration_seconds': sessionDurationSeconds,
      'daily_play_count': dailyPlayCount,
      'weekly_play_count': weeklyPlayCount,
    });
  }

  /// Track performance metrics
  Future<void> trackPerformance({
    required String metric, // 'fps', 'load_time', 'crash'
    required double value,
    String? context,
  }) async {
    await trackEvent('performance_metric', {
      'metric': metric,
      'value': value,
      'context': context ?? 'unknown',
    });
  }

  /// Track custom trace for performance monitoring
  Future<T> trackTrace<T>(String traceName, Future<T> Function() operation) async {
    if (!_isInitialized) return await operation();
    
    final trace = _performance.newTrace(traceName);
    await trace.start();
    
    try {
      final result = await operation();
      await trace.stop();
      return result;
    } catch (e) {
      await trace.stop();
      await recordError(e, StackTrace.current, context: 'Performance trace: $traceName');
      rethrow;
    }
  }

  /// Record errors and crashes
  Future<void> recordError(
    dynamic error,
    StackTrace? stackTrace, {
    String? context,
    bool fatal = false,
    Map<String, dynamic>? additionalData,
  }) async {
    if (!_isInitialized) return;
    
    try {
      // Add context to crashlytics
      if (context != null) {
        await _crashlytics.setCustomKey('error_context', context);
      }
      
      if (additionalData != null) {
        for (final entry in additionalData.entries) {
          await _crashlytics.setCustomKey(entry.key, entry.value.toString());
        }
      }
      
      await _crashlytics.recordError(error, stackTrace, fatal: fatal);
      
      // Also track as analytics event for non-fatal errors
      if (!fatal) {
        await trackEvent('error_occurred', {
          'error_type': error.runtimeType.toString(),
          'error_message': error.toString(),
          'context': context ?? 'unknown',
          'fatal': fatal,
        });
      }
      
    } catch (e) {
      safePrint('📊 Failed to record error: $e');
    }
  }

  /// Get analytics instance for custom usage
  FirebaseAnalytics get analytics => _analytics;
  
  /// Get crashlytics instance for custom usage
  FirebaseCrashlytics get crashlytics => _crashlytics;
  
  /// Get performance instance for custom usage
  FirebasePerformance get performance => _performance;
  
  /// Check if analytics is initialized
  bool get isInitialized => _isInitialized;
}

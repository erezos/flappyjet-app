/// 🚀 Unified Analytics Manager - Zero Performance Impact
/// 
/// Combines Firebase Analytics and Smart Railway Analytics
/// Provides a single interface for all analytics tracking
/// with zero performance impact on the app
library;

import 'package:flutter/foundation.dart';
import '../debug_logger.dart';
import '../../game/systems/firebase_analytics_manager.dart';
import 'smart_railway_analytics.dart';

/// Unified Analytics Manager
class UnifiedAnalyticsManager {
  static final UnifiedAnalyticsManager _instance = UnifiedAnalyticsManager._internal();
  factory UnifiedAnalyticsManager() => _instance;
  UnifiedAnalyticsManager._internal();

  FirebaseAnalyticsManager? _firebaseAnalytics;
  SmartRailwayAnalytics? _railwayAnalytics;
  bool _isInitialized = false;

  /// Initialize unified analytics
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Firebase Analytics
      _firebaseAnalytics = FirebaseAnalyticsManager();
      await _firebaseAnalytics!.initialize();

      // Initialize Smart Railway Analytics
      _railwayAnalytics = SmartRailwayAnalytics();
      await _railwayAnalytics!.initialize();

      _isInitialized = true;
      safePrint('🚀 Unified Analytics Manager initialized successfully');
      
    } catch (e) {
      safePrint('🚀 ❌ Unified Analytics initialization failed: $e');
    }
  }

  /// Track event to both Firebase and Railway (zero performance impact)
  void trackEvent(String eventName, Map<String, dynamic> parameters) {
    if (!_isInitialized) {
      safePrint('🚀 ⚠️ Analytics not initialized, skipping: $eventName');
      return;
    }

    try {
      // Track to Firebase (synchronous, but lightweight)
      _firebaseAnalytics?.trackEvent(eventName, parameters);

      // Track to Railway (asynchronous, zero impact)
      _railwayAnalytics?.trackEvent(eventName, parameters);

      if (kDebugMode) {
        safePrint('🚀 Event tracked: $eventName');
      }

    } catch (e) {
      safePrint('🚀 ❌ Failed to track event $eventName: $e');
    }
  }

  // === GAME-SPECIFIC ANALYTICS EVENTS ===

  /// Track game session start
  void trackGameStart({
    required String gameMode,
    required String selectedJet,
    required String theme,
    int? playerLevel,
    int? totalCoins,
    int? totalGems,
  }) {
    trackEvent('game_start', {
      'game_mode': gameMode,
      'selected_jet': selectedJet,
      'theme': theme,
      'player_level': playerLevel ?? 0,
      'total_coins': totalCoins ?? 0,
      'total_gems': totalGems ?? 0,
    });
  }

  /// Track game session end
  void trackGameEnd({
    required int finalScore,
    required int survivalTimeSeconds,
    required String causeOfDeath,
    required String theme,
    required String selectedJet,
    int? coinsEarned,
    int? gemsEarned,
    bool? usedContinue,
    int? livesUsed,
  }) {
    trackEvent('game_end', {
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
  void trackLevelProgression({
    required int newLevel,
    required int previousLevel,
    required String unlockMethod,
  }) {
    trackEvent('level_up', {
      'new_level': newLevel,
      'previous_level': previousLevel,
      'unlock_method': unlockMethod,
    });
  }

  /// Track in-app purchases
  void trackPurchase({
    required String itemId,
    required String itemName,
    required double price,
    required String currency,
    required String purchaseType,
  }) {
    trackEvent('purchase', {
      'item_id': itemId,
      'item_name': itemName,
      'price': price,
      'currency': currency,
      'purchase_type': purchaseType,
    });
  }

  /// Track ad interactions
  void trackAdEvent({
    required String adType,
    required String action,
    String? adUnitId,
    String? rewardType,
    int? rewardAmount,
  }) {
    trackEvent('ad_event', {
      'ad_type': adType,
      'action': action,
      'ad_unit_id': adUnitId ?? 'unknown',
      'reward_type': rewardType,
      'reward_amount': rewardAmount,
    });
  }

  /// Track mission completion
  void trackMissionComplete({
    required String missionId,
    required String missionType,
    required int rewardCoins,
    required int rewardGems,
    required int completionTimeSeconds,
  }) {
    trackEvent('mission_complete', {
      'mission_id': missionId,
      'mission_type': missionType,
      'reward_coins': rewardCoins,
      'reward_gems': rewardGems,
      'completion_time_seconds': completionTimeSeconds,
    });
  }

  /// Track achievement unlocks
  void trackAchievementUnlock({
    required String achievementId,
    required String achievementName,
    required String category,
    required String rarity,
    int? rewardCoins,
    int? rewardGems,
  }) {
    trackEvent('achievement_unlock', {
      'achievement_id': achievementId,
      'achievement_name': achievementName,
      'category': category,
      'rarity': rarity,
      'reward_coins': rewardCoins ?? 0,
      'reward_gems': rewardGems ?? 0,
    });
  }

  /// Track tournament participation
  void trackTournamentEvent({
    required String action,
    required String tournamentId,
    String? tournamentName,
    int? score,
    int? rank,
    int? totalParticipants,
  }) {
    trackEvent('tournament_event', {
      'action': action,
      'tournament_id': tournamentId,
      'tournament_name': tournamentName ?? 'unknown',
      'score': score,
      'rank': rank,
      'total_participants': totalParticipants,
    });
  }

  /// Track user engagement metrics
  void trackEngagement({
    required String action,
    int? sessionDurationSeconds,
    int? dailyPlayCount,
    int? weeklyPlayCount,
  }) {
    trackEvent('user_engagement', {
      'action': action,
      'session_duration_seconds': sessionDurationSeconds,
      'daily_play_count': dailyPlayCount,
      'weekly_play_count': weeklyPlayCount,
    });
  }

  /// Track social sharing
  void trackSocialShare({
    required String shareType,
    required String contentType,
    required String platform,
    int? score,
  }) {
    trackEvent('social_share', {
      'share_type': shareType,
      'content_type': contentType,
      'platform': platform,
      'score': score,
    });
  }

  /// Track app rating
  void trackAppRating({
    required int rating,
    String? feedback,
  }) {
    trackEvent('app_rating', {
      'rating': rating,
      'feedback': feedback,
    });
  }

  /// Track feature usage
  void trackFeatureUsage({
    required String featureName,
    Map<String, dynamic>? metadata,
  }) {
    trackEvent('feature_usage', {
      'feature_name': featureName,
      'metadata': metadata ?? {},
    });
  }

  /// Track performance metrics
  void trackPerformance({
    required String metricName,
    required double value,
    String? unit,
    Map<String, dynamic>? context,
  }) {
    trackEvent('performance_metric', {
      'metric_name': metricName,
      'value': value,
      'unit': unit,
      'context': context ?? {},
    });
  }

  /// Track crash/error
  void trackError({
    required String errorType,
    required String errorMessage,
    String? stackTrace,
    Map<String, dynamic>? context,
  }) {
    trackEvent('app_error', {
      'error_type': errorType,
      'error_message': errorMessage,
      'stack_trace': stackTrace,
      'context': context ?? {},
    });
  }

  /// Update player ID and process queued events
  void updatePlayerId(String? playerId) {
    _railwayAnalytics?.updatePlayerId(playerId);
  }

  /// Get analytics statistics
  Map<String, dynamic> getStats() {
    final railwayStats = _railwayAnalytics?.getStats() ?? {};
    
    return {
      'firebase_initialized': _firebaseAnalytics != null,
      'railway_initialized': _railwayAnalytics != null,
      'railway_stats': railwayStats,
    };
  }

  /// Force flush all events (for app shutdown)
  Future<void> flush() async {
    await _railwayAnalytics?.flush();
  }

  /// Dispose resources
  void dispose() {
    _railwayAnalytics?.dispose();
  }
}



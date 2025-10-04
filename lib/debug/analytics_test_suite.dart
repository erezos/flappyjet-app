/// 🧪 Analytics Test Suite - Comprehensive testing for Railway + Firebase analytics
/// 
/// Tests the complete analytics flow from Flutter app to Railway backend
library;

import 'package:flutter/foundation.dart';
import '../core/debug_logger.dart';
import '../core/analytics/unified_analytics_manager.dart';
import '../core/analytics/smart_railway_analytics.dart';
import '../core/analytics/app_lifecycle_analytics.dart';

/// Analytics Test Suite
class AnalyticsTestSuite {
  static final AnalyticsTestSuite _instance = AnalyticsTestSuite._internal();
  factory AnalyticsTestSuite() => _instance;
  AnalyticsTestSuite._internal();

  final UnifiedAnalyticsManager _analytics = UnifiedAnalyticsManager();
  final SmartRailwayAnalytics _railwayAnalytics = SmartRailwayAnalytics();
  final AppLifecycleAnalytics _lifecycleAnalytics = AppLifecycleAnalytics();

  /// Run comprehensive analytics test suite
  Future<void> runFullTestSuite() async {
    safePrint('🧪 Starting Analytics Test Suite...');
    
    try {
      // Test 1: Basic event tracking
      await _testBasicEventTracking();
      
      // Test 2: Game lifecycle events
      await _testGameLifecycleEvents();
      
      // Test 3: Monetization events
      await _testMonetizationEvents();
      
      // Test 4: User engagement events
      await _testUserEngagementEvents();
      
      // Test 5: Performance metrics
      await _testPerformanceMetrics();
      
      // Test 6: Error tracking
      await _testErrorTracking();
      
      // Test 7: Railway analytics stats
      await _testRailwayAnalyticsStats();
      
      safePrint('🧪 ✅ Analytics Test Suite completed successfully!');
      
    } catch (e) {
      safePrint('🧪 ❌ Analytics Test Suite failed: $e');
    }
  }

  /// Test basic event tracking
  Future<void> _testBasicEventTracking() async {
    safePrint('🧪 Testing basic event tracking...');
    
    _analytics.trackEvent('test_basic_event', {
      'test_parameter': 'test_value',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    
    await Future.delayed(Duration(milliseconds: 100));
    safePrint('🧪 ✅ Basic event tracking test completed');
  }

  /// Test game lifecycle events
  Future<void> _testGameLifecycleEvents() async {
    safePrint('🧪 Testing game lifecycle events...');
    
    // Test game start
    _analytics.trackGameStart(
      gameMode: 'test_mode',
      selectedJet: 'test_jet',
      theme: 'test_theme',
      playerLevel: 1,
      totalCoins: 100,
      totalGems: 50,
    );
    
    await Future.delayed(Duration(milliseconds: 100));
    
    // Test game end
    _analytics.trackGameEnd(
      finalScore: 42,
      survivalTimeSeconds: 30,
      causeOfDeath: 'test_collision',
      theme: 'test_theme',
      selectedJet: 'test_jet',
      coinsEarned: 10,
      gemsEarned: 5,
      usedContinue: false,
      livesUsed: 1,
    );
    
    await Future.delayed(Duration(milliseconds: 100));
    safePrint('🧪 ✅ Game lifecycle events test completed');
  }

  /// Test monetization events
  Future<void> _testMonetizationEvents() async {
    safePrint('🧪 Testing monetization events...');
    
    // Test purchase event
    _analytics.trackPurchase(
      itemId: 'test_item',
      itemName: 'Test Item',
      price: 4.99,
      currency: 'USD',
      purchaseType: 'real_money',
    );
    
    await Future.delayed(Duration(milliseconds: 100));
    
    // Test ad event
    _analytics.trackAdEvent(
      adType: 'rewarded',
      action: 'completed',
      adUnitId: 'test_ad_unit',
      rewardType: 'coins',
      rewardAmount: 50,
    );
    
    await Future.delayed(Duration(milliseconds: 100));
    safePrint('🧪 ✅ Monetization events test completed');
  }

  /// Test user engagement events
  Future<void> _testUserEngagementEvents() async {
    safePrint('🧪 Testing user engagement events...');
    
    // Test engagement event
    _analytics.trackEngagement(
      action: 'test_session',
      sessionDurationSeconds: 120,
      dailyPlayCount: 3,
      weeklyPlayCount: 15,
    );
    
    await Future.delayed(Duration(milliseconds: 100));
    
    // Test social share
    _analytics.trackSocialShare(
      shareType: 'score_share',
      contentType: 'test_content',
      platform: 'test_platform',
      score: 42,
    );
    
    await Future.delayed(Duration(milliseconds: 100));
    
    // Test feature usage
    _analytics.trackFeatureUsage(
      featureName: 'test_feature',
      metadata: {'test_meta': 'test_value'},
    );
    
    await Future.delayed(Duration(milliseconds: 100));
    safePrint('🧪 ✅ User engagement events test completed');
  }

  /// Test performance metrics
  Future<void> _testPerformanceMetrics() async {
    safePrint('🧪 Testing performance metrics...');
    
    _analytics.trackPerformance(
      metricName: 'test_fps',
      value: 60.0,
      unit: 'fps',
      context: {'test_context': 'test_value'},
    );
    
    await Future.delayed(Duration(milliseconds: 100));
    safePrint('🧪 ✅ Performance metrics test completed');
  }

  /// Test error tracking
  Future<void> _testErrorTracking() async {
    safePrint('🧪 Testing error tracking...');
    
    _analytics.trackError(
      errorType: 'test_error',
      errorMessage: 'This is a test error',
      stackTrace: 'Test stack trace',
      context: {'test_context': 'test_value'},
    );
    
    await Future.delayed(Duration(milliseconds: 100));
    safePrint('🧪 ✅ Error tracking test completed');
  }

  /// Test Railway analytics stats
  Future<void> _testRailwayAnalyticsStats() async {
    safePrint('🧪 Testing Railway analytics stats...');
    
    final stats = _railwayAnalytics.getStats();
    safePrint('🧪 📊 Railway Analytics Stats:');
    safePrint('   - Events tracked: ${stats['events_tracked']}');
    safePrint('   - Events sent: ${stats['events_sent']}');
    safePrint('   - Events failed: ${stats['events_failed']}');
    safePrint('   - Queue size: ${stats['queue_size']}');
    safePrint('   - Session ID: ${stats['session_id']}');
    safePrint('   - Player ID: ${stats['player_id']}');
    
    final performance = stats['performance'] as Map<String, dynamic>?;
    if (performance != null) {
      safePrint('   - Avg processing time: ${performance['avg_processing_time_ms']}ms');
      safePrint('   - Avg batch size: ${performance['avg_batch_size']}');
      safePrint('   - Consecutive failures: ${performance['consecutive_failures']}');
      safePrint('   - User active: ${performance['is_user_active']}');
    }
    
    safePrint('🧪 ✅ Railway analytics stats test completed');
  }

  /// Test specific event categories
  Future<void> testEventCategory(String category) async {
    safePrint('🧪 Testing $category events...');
    
    switch (category) {
      case 'gameplay':
        await _testGameplayEvents();
        break;
      case 'monetization':
        await _testMonetizationEvents();
        break;
      case 'retention':
        await _testRetentionEvents();
        break;
      case 'system':
        await _testSystemEvents();
        break;
      default:
        safePrint('🧪 ⚠️ Unknown category: $category');
    }
  }

  /// Test gameplay events
  Future<void> _testGameplayEvents() async {
    _analytics.trackEvent('test_level_up', {
      'new_level': 2,
      'previous_level': 1,
      'unlock_method': 'test',
    });
    
    _analytics.trackMissionComplete(
      missionId: 'test_mission',
      missionType: 'test_type',
      rewardCoins: 100,
      rewardGems: 10,
      completionTimeSeconds: 60,
    );
    
    _analytics.trackAchievementUnlock(
      achievementId: 'test_achievement',
      achievementName: 'Test Achievement',
      category: 'test_category',
      rarity: 'common',
      rewardCoins: 50,
      rewardGems: 5,
    );
  }

  /// Test retention events
  Future<void> _testRetentionEvents() async {
    _analytics.trackEvent('app_start', {
      'session_count': 1,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    
    _analytics.trackAppRating(
      rating: 5,
      feedback: 'Test feedback',
    );
  }

  /// Test system events
  Future<void> _testSystemEvents() async {
    _analytics.trackPerformance(
      metricName: 'memory_usage',
      value: 128.5,
      unit: 'MB',
    );
    
    _analytics.trackError(
      errorType: 'system_error',
      errorMessage: 'Test system error',
    );
  }

  /// Force flush all analytics events
  Future<void> flushAllEvents() async {
    safePrint('🧪 Flushing all analytics events...');
    await _analytics.flush();
    safePrint('🧪 ✅ All events flushed');
  }

  /// Get comprehensive analytics report
  Map<String, dynamic> getAnalyticsReport() {
    final unifiedStats = _analytics.getStats();
    final railwayStats = _railwayAnalytics.getStats();
    
    return {
      'unified_analytics': unifiedStats,
      'railway_analytics': railwayStats,
      'test_timestamp': DateTime.now().toIso8601String(),
    };
  }
}


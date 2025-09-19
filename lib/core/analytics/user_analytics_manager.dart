/// 📊 User Analytics Manager - Comprehensive User Tracking
/// 
/// Tracks all user behavior and statistics for business intelligence
/// Based on successful mobile game analytics patterns
library;

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../debug_logger.dart';
import '../network/network_manager.dart';
import '../../game/systems/player_identity_manager.dart';

/// Comprehensive user analytics data
class UserAnalytics {
  // Install & Session Data
  final DateTime installDate;
  final int numberOfSessions;
  final int totalPlayTimeSeconds;
  final DateTime lastSessionDate;
  final int sessionStreak; // consecutive days played
  
  // Game Performance Data
  final int numberOfGames;
  final int bestStreak;
  final int highScore;
  final int totalScore; // sum of all scores
  final double averageScore;
  
  // Progression Data
  final int dailyMissionsCompleted;
  final int achievementsCompleted;
  final int totalAchievementPoints;
  
  // Monetization Data
  final int numberOfPurchases;
  final double totalSpentUSD;
  final int numberOfContinuesUsed;
  final int totalGemsSpent;
  final int totalCoinsSpent;
  
  // Inventory Data
  final int jetsOwned;
  final List<String> ownedJetIds;
  final String currentJetId;
  final int skinsOwned;
  
  // Device & Location Data
  final String deviceModel;
  final String osVersion;
  final String platform; // android/ios
  final String countryCode;
  final String timezone;
  final String appVersion;
  
  // Engagement Data
  final int adWatchCount;
  final int shareCount;
  final int rateUsPromptShown;
  final bool hasRatedApp;
  final int crashCount;
  final DateTime lastCrashDate;
  
  // Behavioral Data
  final Map<String, int> featureUsage; // feature_name -> usage_count
  final Map<String, double> levelCompletionTimes;
  final int tutorialCompleted; // 0=not started, 1=in progress, 2=completed
  final List<String> preferredPlayTimes; // hour ranges when user plays most

  UserAnalytics({
    required this.installDate,
    required this.numberOfSessions,
    required this.totalPlayTimeSeconds,
    required this.lastSessionDate,
    required this.sessionStreak,
    required this.numberOfGames,
    required this.bestStreak,
    required this.highScore,
    required this.totalScore,
    required this.averageScore,
    required this.dailyMissionsCompleted,
    required this.achievementsCompleted,
    required this.totalAchievementPoints,
    required this.numberOfPurchases,
    required this.totalSpentUSD,
    required this.numberOfContinuesUsed,
    required this.totalGemsSpent,
    required this.totalCoinsSpent,
    required this.jetsOwned,
    required this.ownedJetIds,
    required this.currentJetId,
    required this.skinsOwned,
    required this.deviceModel,
    required this.osVersion,
    required this.platform,
    required this.countryCode,
    required this.timezone,
    required this.appVersion,
    required this.adWatchCount,
    required this.shareCount,
    required this.rateUsPromptShown,
    required this.hasRatedApp,
    required this.crashCount,
    required this.lastCrashDate,
    required this.featureUsage,
    required this.levelCompletionTimes,
    required this.tutorialCompleted,
    required this.preferredPlayTimes,
  });

  Map<String, dynamic> toJson() => {
    'installDate': installDate.millisecondsSinceEpoch,
    'numberOfSessions': numberOfSessions,
    'totalPlayTimeSeconds': totalPlayTimeSeconds,
    'lastSessionDate': lastSessionDate.millisecondsSinceEpoch,
    'sessionStreak': sessionStreak,
    'numberOfGames': numberOfGames,
    'bestStreak': bestStreak,
    'highScore': highScore,
    'totalScore': totalScore,
    'averageScore': averageScore,
    'dailyMissionsCompleted': dailyMissionsCompleted,
    'achievementsCompleted': achievementsCompleted,
    'totalAchievementPoints': totalAchievementPoints,
    'numberOfPurchases': numberOfPurchases,
    'totalSpentUSD': totalSpentUSD,
    'numberOfContinuesUsed': numberOfContinuesUsed,
    'totalGemsSpent': totalGemsSpent,
    'totalCoinsSpent': totalCoinsSpent,
    'jetsOwned': jetsOwned,
    'ownedJetIds': ownedJetIds,
    'currentJetId': currentJetId,
    'skinsOwned': skinsOwned,
    'deviceModel': deviceModel,
    'osVersion': osVersion,
    'platform': platform,
    'countryCode': countryCode,
    'timezone': timezone,
    'appVersion': appVersion,
    'adWatchCount': adWatchCount,
    'shareCount': shareCount,
    'rateUsPromptShown': rateUsPromptShown,
    'hasRatedApp': hasRatedApp,
    'crashCount': crashCount,
    'lastCrashDate': lastCrashDate.millisecondsSinceEpoch,
    'featureUsage': featureUsage,
    'levelCompletionTimes': levelCompletionTimes,
    'tutorialCompleted': tutorialCompleted,
    'preferredPlayTimes': preferredPlayTimes,
  };

  factory UserAnalytics.fromJson(Map<String, dynamic> json) {
    return UserAnalytics(
      installDate: DateTime.fromMillisecondsSinceEpoch(json['installDate'] ?? DateTime.now().millisecondsSinceEpoch),
      numberOfSessions: json['numberOfSessions'] ?? 0,
      totalPlayTimeSeconds: json['totalPlayTimeSeconds'] ?? 0,
      lastSessionDate: DateTime.fromMillisecondsSinceEpoch(json['lastSessionDate'] ?? DateTime.now().millisecondsSinceEpoch),
      sessionStreak: json['sessionStreak'] ?? 0,
      numberOfGames: json['numberOfGames'] ?? 0,
      bestStreak: json['bestStreak'] ?? 0,
      highScore: json['highScore'] ?? 0,
      totalScore: json['totalScore'] ?? 0,
      averageScore: json['averageScore']?.toDouble() ?? 0.0,
      dailyMissionsCompleted: json['dailyMissionsCompleted'] ?? 0,
      achievementsCompleted: json['achievementsCompleted'] ?? 0,
      totalAchievementPoints: json['totalAchievementPoints'] ?? 0,
      numberOfPurchases: json['numberOfPurchases'] ?? 0,
      totalSpentUSD: json['totalSpentUSD']?.toDouble() ?? 0.0,
      numberOfContinuesUsed: json['numberOfContinuesUsed'] ?? 0,
      totalGemsSpent: json['totalGemsSpent'] ?? 0,
      totalCoinsSpent: json['totalCoinsSpent'] ?? 0,
      jetsOwned: json['jetsOwned'] ?? 1,
      ownedJetIds: List<String>.from(json['ownedJetIds'] ?? ['sky_jet']),
      currentJetId: json['currentJetId'] ?? 'sky_jet',
      skinsOwned: json['skinsOwned'] ?? 1,
      deviceModel: json['deviceModel'] ?? 'unknown',
      osVersion: json['osVersion'] ?? 'unknown',
      platform: json['platform'] ?? 'unknown',
      countryCode: json['countryCode'] ?? 'US',
      timezone: json['timezone'] ?? 'UTC',
      appVersion: json['appVersion'] ?? '1.0.0',
      adWatchCount: json['adWatchCount'] ?? 0,
      shareCount: json['shareCount'] ?? 0,
      rateUsPromptShown: json['rateUsPromptShown'] ?? 0,
      hasRatedApp: json['hasRatedApp'] ?? false,
      crashCount: json['crashCount'] ?? 0,
      lastCrashDate: DateTime.fromMillisecondsSinceEpoch(json['lastCrashDate'] ?? 0),
      featureUsage: Map<String, int>.from(json['featureUsage'] ?? {}),
      levelCompletionTimes: Map<String, double>.from(json['levelCompletionTimes'] ?? {}),
      tutorialCompleted: json['tutorialCompleted'] ?? 0,
      preferredPlayTimes: List<String>.from(json['preferredPlayTimes'] ?? []),
    );
  }

  /// Create a copy with updated values
  UserAnalytics copyWith({
    DateTime? installDate,
    int? numberOfSessions,
    int? totalPlayTimeSeconds,
    DateTime? lastSessionDate,
    int? sessionStreak,
    int? numberOfGames,
    int? bestStreak,
    int? highScore,
    int? totalScore,
    double? averageScore,
    int? dailyMissionsCompleted,
    int? achievementsCompleted,
    int? totalAchievementPoints,
    int? numberOfPurchases,
    double? totalSpentUSD,
    int? numberOfContinuesUsed,
    int? totalGemsSpent,
    int? totalCoinsSpent,
    int? jetsOwned,
    List<String>? ownedJetIds,
    String? currentJetId,
    int? skinsOwned,
    String? deviceModel,
    String? osVersion,
    String? platform,
    String? countryCode,
    String? timezone,
    String? appVersion,
    int? adWatchCount,
    int? shareCount,
    int? rateUsPromptShown,
    bool? hasRatedApp,
    int? crashCount,
    DateTime? lastCrashDate,
    Map<String, int>? featureUsage,
    Map<String, double>? levelCompletionTimes,
    int? tutorialCompleted,
    List<String>? preferredPlayTimes,
  }) {
    return UserAnalytics(
      installDate: installDate ?? this.installDate,
      numberOfSessions: numberOfSessions ?? this.numberOfSessions,
      totalPlayTimeSeconds: totalPlayTimeSeconds ?? this.totalPlayTimeSeconds,
      lastSessionDate: lastSessionDate ?? this.lastSessionDate,
      sessionStreak: sessionStreak ?? this.sessionStreak,
      numberOfGames: numberOfGames ?? this.numberOfGames,
      bestStreak: bestStreak ?? this.bestStreak,
      highScore: highScore ?? this.highScore,
      totalScore: totalScore ?? this.totalScore,
      averageScore: averageScore ?? this.averageScore,
      dailyMissionsCompleted: dailyMissionsCompleted ?? this.dailyMissionsCompleted,
      achievementsCompleted: achievementsCompleted ?? this.achievementsCompleted,
      totalAchievementPoints: totalAchievementPoints ?? this.totalAchievementPoints,
      numberOfPurchases: numberOfPurchases ?? this.numberOfPurchases,
      totalSpentUSD: totalSpentUSD ?? this.totalSpentUSD,
      numberOfContinuesUsed: numberOfContinuesUsed ?? this.numberOfContinuesUsed,
      totalGemsSpent: totalGemsSpent ?? this.totalGemsSpent,
      totalCoinsSpent: totalCoinsSpent ?? this.totalCoinsSpent,
      jetsOwned: jetsOwned ?? this.jetsOwned,
      ownedJetIds: ownedJetIds ?? this.ownedJetIds,
      currentJetId: currentJetId ?? this.currentJetId,
      skinsOwned: skinsOwned ?? this.skinsOwned,
      deviceModel: deviceModel ?? this.deviceModel,
      osVersion: osVersion ?? this.osVersion,
      platform: platform ?? this.platform,
      countryCode: countryCode ?? this.countryCode,
      timezone: timezone ?? this.timezone,
      appVersion: appVersion ?? this.appVersion,
      adWatchCount: adWatchCount ?? this.adWatchCount,
      shareCount: shareCount ?? this.shareCount,
      rateUsPromptShown: rateUsPromptShown ?? this.rateUsPromptShown,
      hasRatedApp: hasRatedApp ?? this.hasRatedApp,
      crashCount: crashCount ?? this.crashCount,
      lastCrashDate: lastCrashDate ?? this.lastCrashDate,
      featureUsage: featureUsage ?? this.featureUsage,
      levelCompletionTimes: levelCompletionTimes ?? this.levelCompletionTimes,
      tutorialCompleted: tutorialCompleted ?? this.tutorialCompleted,
      preferredPlayTimes: preferredPlayTimes ?? this.preferredPlayTimes,
    );
  }
}

/// User Analytics Manager - Comprehensive tracking system
class UserAnalyticsManager extends ChangeNotifier {
  static final UserAnalyticsManager _instance = UserAnalyticsManager._internal();
  factory UserAnalyticsManager() => _instance;
  UserAnalyticsManager._internal();

  // Dependencies
  final NetworkManager _networkManager = NetworkManager();
  final PlayerIdentityManager _playerIdentity = PlayerIdentityManager();

  // Storage
  static const String _keyUserAnalytics = 'user_analytics_v1';
  static const String _keySessionStart = 'session_start_time';

  // Current analytics data
  UserAnalytics? _analytics;
  DateTime? _sessionStartTime;
  bool _isInitialized = false;

  // Getters
  UserAnalytics? get analytics => _analytics;
  bool get isInitialized => _isInitialized;

  /// Initialize analytics system
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _loadAnalytics();
    await _updateDeviceInfo();
    await _startSession();
    
    _isInitialized = true;
    safePrint('📊 User Analytics Manager initialized');
  }

  /// Load analytics from storage
  Future<void> _loadAnalytics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final analyticsJson = prefs.getString(_keyUserAnalytics);
      
      if (analyticsJson != null) {
        final data = jsonDecode(analyticsJson);
        _analytics = UserAnalytics.fromJson(data);
      } else {
        // First time user - create initial analytics
        _analytics = await _createInitialAnalytics();
        await _saveAnalytics();
      }
    } catch (e) {
      safePrint('📊 ⚠️ Failed to load analytics: $e');
      _analytics = await _createInitialAnalytics();
    }
  }

  /// Create initial analytics for new user
  Future<UserAnalytics> _createInitialAnalytics() async {
    final deviceInfo = await _getDeviceInfo();
    
    return UserAnalytics(
      installDate: DateTime.now(),
      numberOfSessions: 0,
      totalPlayTimeSeconds: 0,
      lastSessionDate: DateTime.now(),
      sessionStreak: 0,
      numberOfGames: 0,
      bestStreak: 0,
      highScore: 0,
      totalScore: 0,
      averageScore: 0.0,
      dailyMissionsCompleted: 0,
      achievementsCompleted: 0,
      totalAchievementPoints: 0,
      numberOfPurchases: 0,
      totalSpentUSD: 0.0,
      numberOfContinuesUsed: 0,
      totalGemsSpent: 0,
      totalCoinsSpent: 0,
      jetsOwned: 1,
      ownedJetIds: ['sky_jet'],
      currentJetId: 'sky_jet',
      skinsOwned: 1,
      deviceModel: deviceInfo['model'] ?? 'unknown',
      osVersion: deviceInfo['osVersion'] ?? 'unknown',
      platform: deviceInfo['platform'] ?? 'unknown',
      countryCode: await _getCountryCode(), // Detect from device locale
      timezone: DateTime.now().timeZoneName,
      appVersion: '1.4.6',
      adWatchCount: 0,
      shareCount: 0,
      rateUsPromptShown: 0,
      hasRatedApp: false,
      crashCount: 0,
      lastCrashDate: DateTime.fromMillisecondsSinceEpoch(0),
      featureUsage: {},
      levelCompletionTimes: {},
      tutorialCompleted: 0,
      preferredPlayTimes: [],
    );
  }

  /// Get device information
  Future<Map<String, String>> _getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return {
          'model': '${androidInfo.brand} ${androidInfo.model}',
          'osVersion': 'Android ${androidInfo.version.release}',
          'platform': 'android',
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return {
          'model': '${iosInfo.name} ${iosInfo.model}',
          'osVersion': 'iOS ${iosInfo.systemVersion}',
          'platform': 'ios',
        };
      }
    } catch (e) {
      safePrint('📊 ⚠️ Failed to get device info: $e');
    }
    
    return {
      'model': 'unknown',
      'osVersion': 'unknown',
      'platform': 'unknown',
    };
  }

  /// Update device info if needed
  Future<void> _updateDeviceInfo() async {
    if (_analytics == null) return;
    
    final deviceInfo = await _getDeviceInfo();
    
    _analytics = _analytics!.copyWith(
      deviceModel: deviceInfo['model'],
      osVersion: deviceInfo['osVersion'],
      platform: deviceInfo['platform'],
      appVersion: '1.4.6',
    );
  }

  /// Get country code from device locale
  Future<String> _getCountryCode() async {
    try {
      // Try to get country from device locale
      final locale = Platform.localeName; // e.g., "en_US", "fr_FR", "ja_JP"
      final parts = locale.split('_');
      
      if (parts.length >= 2) {
        final countryCode = parts[1].toUpperCase();
        // Validate it's a 2-letter country code
        if (countryCode.length == 2 && RegExp(r'^[A-Z]{2}$').hasMatch(countryCode)) {
          return countryCode;
        }
      }
      
      // Final fallback
      return 'US';
    } catch (e) {
      return 'US';
    }
  }

  /// Start a new session
  Future<void> _startSession() async {
    if (_analytics == null) return;

    _sessionStartTime = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySessionStart, _sessionStartTime!.millisecondsSinceEpoch);

    // Update session count and streak
    final now = DateTime.now();
    final lastSession = _analytics!.lastSessionDate;
    final daysSinceLastSession = now.difference(lastSession).inDays;
    
    int newStreak = _analytics!.sessionStreak;
    if (daysSinceLastSession == 1) {
      // Consecutive day
      newStreak++;
    } else if (daysSinceLastSession > 1) {
      // Streak broken
      newStreak = 1;
    }
    // If same day, keep current streak

    _analytics = _analytics!.copyWith(
      numberOfSessions: _analytics!.numberOfSessions + 1,
      lastSessionDate: now,
      sessionStreak: newStreak,
    );

    await _saveAnalytics();
    await _syncToBackend();

    safePrint('📊 Session started - Total sessions: ${_analytics!.numberOfSessions}, Streak: $newStreak days');
  }

  /// End current session
  Future<void> endSession() async {
    if (_sessionStartTime == null || _analytics == null) return;

    final sessionDuration = DateTime.now().difference(_sessionStartTime!).inSeconds;
    
    _analytics = _analytics!.copyWith(
      totalPlayTimeSeconds: _analytics!.totalPlayTimeSeconds + sessionDuration,
    );

    await _saveAnalytics();
    await _syncToBackend();

    safePrint('📊 Session ended - Duration: ${sessionDuration}s, Total playtime: ${_analytics!.totalPlayTimeSeconds}s');
  }

  /// Track game completion
  Future<void> trackGameCompletion({
    required int score,
    required int streak,
    required int survivalTimeSeconds,
  }) async {
    if (_analytics == null) return;

    final newTotalScore = _analytics!.totalScore + score;
    final newGameCount = _analytics!.numberOfGames + 1;
    final newAverageScore = newTotalScore / newGameCount;

    _analytics = _analytics!.copyWith(
      numberOfGames: newGameCount,
      bestStreak: streak > _analytics!.bestStreak ? streak : _analytics!.bestStreak,
      highScore: score > _analytics!.highScore ? score : _analytics!.highScore,
      totalScore: newTotalScore,
      averageScore: newAverageScore,
    );

    await _saveAnalytics();
    await _syncToBackend();

    safePrint('📊 Game completed - Score: $score, New high: ${score > (_analytics!.highScore - score)}');
  }

  /// Track mission completion
  Future<void> trackMissionCompletion() async {
    if (_analytics == null) return;

    _analytics = _analytics!.copyWith(
      dailyMissionsCompleted: _analytics!.dailyMissionsCompleted + 1,
    );

    await _saveAnalytics();
    await _syncToBackend();
  }

  /// Track achievement unlock
  Future<void> trackAchievementUnlock(int points) async {
    if (_analytics == null) return;

    _analytics = _analytics!.copyWith(
      achievementsCompleted: _analytics!.achievementsCompleted + 1,
      totalAchievementPoints: _analytics!.totalAchievementPoints + points,
    );

    await _saveAnalytics();
    await _syncToBackend();
  }

  /// Track purchase
  Future<void> trackPurchase(double amountUSD) async {
    if (_analytics == null) return;

    _analytics = _analytics!.copyWith(
      numberOfPurchases: _analytics!.numberOfPurchases + 1,
      totalSpentUSD: _analytics!.totalSpentUSD + amountUSD,
    );

    await _saveAnalytics();
    await _syncToBackend();
  }

  /// Track continue usage
  Future<void> trackContinueUsed() async {
    if (_analytics == null) return;

    _analytics = _analytics!.copyWith(
      numberOfContinuesUsed: _analytics!.numberOfContinuesUsed + 1,
    );

    await _saveAnalytics();
    await _syncToBackend();
  }

  /// Track currency spending
  Future<void> trackCurrencySpent({int? gems, int? coins}) async {
    if (_analytics == null) return;

    _analytics = _analytics!.copyWith(
      totalGemsSpent: _analytics!.totalGemsSpent + (gems ?? 0),
      totalCoinsSpent: _analytics!.totalCoinsSpent + (coins ?? 0),
    );

    await _saveAnalytics();
  }

  /// Track jet/skin ownership
  Future<void> trackInventoryUpdate({
    required List<String> ownedJetIds,
    required String currentJetId,
    required int skinsOwned,
  }) async {
    if (_analytics == null) return;

    _analytics = _analytics!.copyWith(
      jetsOwned: ownedJetIds.length,
      ownedJetIds: ownedJetIds,
      currentJetId: currentJetId,
      skinsOwned: skinsOwned,
    );

    await _saveAnalytics();
  }

  /// Track ad watch
  Future<void> trackAdWatch() async {
    if (_analytics == null) return;

    _analytics = _analytics!.copyWith(
      adWatchCount: _analytics!.adWatchCount + 1,
    );

    await _saveAnalytics();
  }

  /// Track social share
  Future<void> trackShare() async {
    if (_analytics == null) return;

    _analytics = _analytics!.copyWith(
      shareCount: _analytics!.shareCount + 1,
    );

    await _saveAnalytics();
    await _syncToBackend();
  }

  /// Track rate us prompt
  Future<void> trackRateUsPrompt() async {
    if (_analytics == null) return;

    _analytics = _analytics!.copyWith(
      rateUsPromptShown: _analytics!.rateUsPromptShown + 1,
    );

    await _saveAnalytics();
  }

  /// Track app rating
  Future<void> trackAppRated() async {
    if (_analytics == null) return;

    _analytics = _analytics!.copyWith(
      hasRatedApp: true,
    );

    await _saveAnalytics();
    await _syncToBackend();
  }

  /// Track feature usage
  Future<void> trackFeatureUsage(String featureName) async {
    if (_analytics == null) return;

    final currentUsage = Map<String, int>.from(_analytics!.featureUsage);
    currentUsage[featureName] = (currentUsage[featureName] ?? 0) + 1;

    _analytics = _analytics!.copyWith(
      featureUsage: currentUsage,
    );

    await _saveAnalytics();
  }

  /// Track crash
  Future<void> trackCrash() async {
    if (_analytics == null) return;

    _analytics = _analytics!.copyWith(
      crashCount: _analytics!.crashCount + 1,
      lastCrashDate: DateTime.now(),
    );

    await _saveAnalytics();
    await _syncToBackend();
  }

  /// Save analytics to local storage
  Future<void> _saveAnalytics() async {
    if (_analytics == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUserAnalytics, jsonEncode(_analytics!.toJson()));
    } catch (e) {
      safePrint('📊 ⚠️ Failed to save analytics: $e');
    }
  }

  /// Sync analytics to backend
  Future<void> _syncToBackend() async {
    if (_analytics == null || !_playerIdentity.isAuthenticated) return;

    try {
      final result = await _networkManager.submitAnalyticsEvent(
        eventName: 'user_analytics_sync',
        eventData: _analytics!.toJson(),
      );

      if (result.success) {
        safePrint('📊 ✅ Analytics synced to backend');
      } else {
        safePrint('📊 ⚠️ Failed to sync analytics: ${result.error}');
      }
    } catch (e) {
      safePrint('📊 ❌ Analytics sync error: $e');
    }
  }

  /// Force sync to backend
  Future<void> forceSyncToBackend() async {
    await _syncToBackend();
  }

  /// Get analytics summary for debugging
  Map<String, dynamic> getAnalyticsSummary() {
    if (_analytics == null) return {};

    return {
      'daysInstalled': DateTime.now().difference(_analytics!.installDate).inDays,
      'totalSessions': _analytics!.numberOfSessions,
      'totalPlayTimeHours': (_analytics!.totalPlayTimeSeconds / 3600).toStringAsFixed(1),
      'totalGames': _analytics!.numberOfGames,
      'highScore': _analytics!.highScore,
      'averageScore': _analytics!.averageScore.toStringAsFixed(1),
      'totalSpent': '\$${_analytics!.totalSpentUSD.toStringAsFixed(2)}',
      'jetsOwned': _analytics!.jetsOwned,
      'achievementsCompleted': _analytics!.achievementsCompleted,
    };
  }
}

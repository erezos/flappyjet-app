/// 🎯 CONVERSION EVENTS MANAGER
/// 
/// Tracks milestone events for Google Ads conversion optimization.
/// These events help Google identify high-quality users for ad targeting.
/// 
/// Events tracked:
/// - User played 3/5/10 games
/// - User logged in 3/6 sessions
/// - User completed level 3/5/10
/// 
/// Key behaviors:
/// - Each event fires EXACTLY ONCE per unique user
/// - Events fire to both Firebase (for Google Ads) and Railway backend
/// - Events are checked on app open and after relevant actions
/// - All events fire asynchronously (non-blocking)
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../events/event_bus.dart';
import '../debug_logger.dart';
import '../database/local_database_manager.dart';
import '../repositories/user_stats_repository.dart';
import '../../game/systems/level_system_manager.dart';
import 'unified_analytics_manager.dart';

/// Conversion milestone types
enum ConversionMilestone {
  gamesPlayed3('games_played_3', 3, MilestoneType.gamesPlayed),
  gamesPlayed5('games_played_5', 5, MilestoneType.gamesPlayed),
  gamesPlayed10('games_played_10', 10, MilestoneType.gamesPlayed),
  sessions3('sessions_3', 3, MilestoneType.sessions),
  sessions6('sessions_6', 6, MilestoneType.sessions),
  levelCompleted3('level_completed_3', 3, MilestoneType.levelCompleted),
  levelCompleted5('level_completed_5', 5, MilestoneType.levelCompleted),
  levelCompleted10('level_completed_10', 10, MilestoneType.levelCompleted);

  final String eventName;
  final int threshold;
  final MilestoneType type;

  const ConversionMilestone(this.eventName, this.threshold, this.type);
}

enum MilestoneType {
  gamesPlayed,
  sessions,
  levelCompleted,
}

/// 🎯 Manages conversion event tracking for Google Ads optimization
class ConversionEventsManager {
  static final ConversionEventsManager _instance = ConversionEventsManager._internal();
  factory ConversionEventsManager() => _instance;
  ConversionEventsManager._internal();

  // Dependencies
  final EventBus _eventBus = EventBus();
  final UnifiedAnalyticsManager _analytics = UnifiedAnalyticsManager();

  // State
  bool _isInitialized = false;
  final Set<String> _firedEvents = {};
  int _totalGamesPlayed = 0;
  int _sessionCount = 0;
  int _highestLevelCompleted = 0;

  // Prefs keys
  static const String _keyPrefix = 'conversion_event_fired_';
  static const String _keyTotalGames = 'conversion_total_games_played';
  static const String _keySessions = 'conversion_session_count';

  /// Initialize the manager and check for pending events
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load fired events state
      for (final milestone in ConversionMilestone.values) {
        if (prefs.getBool('$_keyPrefix${milestone.eventName}') ?? false) {
          _firedEvents.add(milestone.eventName);
        }
      }

      // Load counters
      _totalGamesPlayed = prefs.getInt(_keyTotalGames) ?? 0;
      _sessionCount = prefs.getInt(_keySessions) ?? 0;

      // Try to sync with actual data sources
      await _syncWithDataSources();

      _isInitialized = true;
      safePrint('🎯 ConversionEventsManager initialized');
      safePrint('🎯 Games: $_totalGamesPlayed, Sessions: $_sessionCount, Level: $_highestLevelCompleted');
      safePrint('🎯 Already fired: ${_firedEvents.join(', ')}');

      // Check for any pending milestones on startup
      await checkAllMilestones();
    } catch (e) {
      safePrint('⚠️ ConversionEventsManager init error: $e');
      _isInitialized = true; // Mark as initialized to prevent repeated errors
    }
  }

  /// Sync our counters with actual data sources
  Future<void> _syncWithDataSources() async {
    try {
      // Get actual games played from user stats
      final db = LocalDatabaseManager();
      final userStatsRepo = UserStatsRepository(db);
      final userStats = await userStatsRepo.getUserStats();
      if (userStats.totalGamesPlayed > _totalGamesPlayed) {
        _totalGamesPlayed = userStats.totalGamesPlayed;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_keyTotalGames, _totalGamesPlayed);
      }

      // Get highest level completed from level system
      final levelManager = LevelSystemManager();
      final currentLevel = levelManager.currentLevel;
      if (currentLevel > _highestLevelCompleted) {
        _highestLevelCompleted = currentLevel;
      }
    } catch (e) {
      safePrint('⚠️ Conversion sync error (non-fatal): $e');
    }
  }

  /// Increment session count on app open
  Future<void> onAppOpen() async {
    if (!_isInitialized) await initialize();

    _sessionCount++;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keySessions, _sessionCount);
    } catch (e) {
      safePrint('⚠️ Failed to save session count: $e');
    }

    safePrint('🎯 Session count: $_sessionCount');
    
    // Check session milestones
    await _checkSessionMilestones();
    
    // Also check other milestones in case any were missed
    await checkAllMilestones();
  }

  /// Call this when a game is played (any mode: endless, story, tournament)
  Future<void> onGamePlayed() async {
    if (!_isInitialized) await initialize();

    _totalGamesPlayed++;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyTotalGames, _totalGamesPlayed);
    } catch (e) {
      safePrint('⚠️ Failed to save games played: $e');
    }

    safePrint('🎯 Total games played: $_totalGamesPlayed');
    
    // Check games played milestones
    await _checkGamesPlayedMilestones();
  }

  /// Call this when a level is completed
  Future<void> onLevelCompleted(int levelNumber) async {
    if (!_isInitialized) await initialize();

    if (levelNumber > _highestLevelCompleted) {
      _highestLevelCompleted = levelNumber;
    }

    safePrint('🎯 Level completed: $levelNumber (highest: $_highestLevelCompleted)');
    
    // Check level milestones
    await _checkLevelMilestones();
  }

  /// Check all milestones (call on app open)
  Future<void> checkAllMilestones() async {
    await _checkGamesPlayedMilestones();
    await _checkSessionMilestones();
    await _checkLevelMilestones();
  }

  /// Check games played milestones
  Future<void> _checkGamesPlayedMilestones() async {
    for (final milestone in ConversionMilestone.values) {
      if (milestone.type != MilestoneType.gamesPlayed) continue;
      
      if (_totalGamesPlayed >= milestone.threshold) {
        await _fireMilestoneEvent(milestone);
      }
    }
  }

  /// Check session milestones
  Future<void> _checkSessionMilestones() async {
    for (final milestone in ConversionMilestone.values) {
      if (milestone.type != MilestoneType.sessions) continue;
      
      if (_sessionCount >= milestone.threshold) {
        await _fireMilestoneEvent(milestone);
      }
    }
  }

  /// Check level completion milestones
  Future<void> _checkLevelMilestones() async {
    for (final milestone in ConversionMilestone.values) {
      if (milestone.type != MilestoneType.levelCompleted) continue;
      
      if (_highestLevelCompleted >= milestone.threshold) {
        await _fireMilestoneEvent(milestone);
      }
    }
  }

  /// Fire a milestone event (if not already fired)
  Future<void> _fireMilestoneEvent(ConversionMilestone milestone) async {
    // Skip if already fired
    if (_firedEvents.contains(milestone.eventName)) {
      return;
    }

    // Mark as fired first to prevent duplicates
    _firedEvents.add(milestone.eventName);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('$_keyPrefix${milestone.eventName}', true);
    } catch (e) {
      safePrint('⚠️ Failed to persist fired event: $e');
    }

    safePrint('🎯 🎉 CONVERSION EVENT: ${milestone.eventName}');

    // Build event data with all user context for Google Ads
    final eventData = await _buildEventData(milestone);

    // 🔥 Fire to Firebase (non-blocking, for Google Ads conversion tracking)
    _fireToFirebase(milestone.eventName, eventData);

    // 📤 Fire to Railway backend (non-blocking, for our analytics)
    _fireToRailway(milestone.eventName, eventData);
  }

  /// Build event data with full user context
  Future<Map<String, dynamic>> _buildEventData(ConversionMilestone milestone) async {
    final data = <String, dynamic>{
      'milestone_type': milestone.type.name,
      'threshold': milestone.threshold,
      'total_games_played': _totalGamesPlayed,
      'session_count': _sessionCount,
      'highest_level': _highestLevelCompleted,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    // Add additional context for Google Ads
    try {
      final db = LocalDatabaseManager();
      final userStatsRepo = UserStatsRepository(db);
      final userStats = await userStatsRepo.getUserStats();
      data['high_score'] = userStats.highScore;
      data['total_score'] = userStats.totalScore;
      data['coins_earned'] = userStats.coins;
      data['gems_earned'] = userStats.gems;

      // Add level system data
      final levelManager = LevelSystemManager();
      data['current_level'] = levelManager.currentLevel;
      data['highest_level_unlocked'] = levelManager.highestLevelUnlocked;
    } catch (e) {
      safePrint('⚠️ Failed to add extra context: $e');
    }

    return data;
  }

  /// Fire event to Firebase Analytics (for Google Ads)
  void _fireToFirebase(String eventName, Map<String, dynamic> data) {
    // Non-blocking async
    Future(() {
      try {
        // Use unified analytics which wraps Firebase
        _analytics.trackEvent('conversion_$eventName', data);
        safePrint('🔥 Firebase: conversion_$eventName sent');
      } catch (e) {
        safePrint('⚠️ Firebase conversion event failed (non-blocking): $e');
      }
    });
  }

  /// Fire event to Railway backend (for our analytics)
  void _fireToRailway(String eventName, Map<String, dynamic> data) {
    // Non-blocking async via EventBus
    Future(() {
      try {
        _eventBus.fire('conversion_$eventName', data);
        safePrint('📤 Railway: conversion_$eventName sent');
      } catch (e) {
        safePrint('⚠️ Railway conversion event failed (non-blocking): $e');
      }
    });
  }

  /// Debug: Get current state
  Map<String, dynamic> getDebugState() {
    return {
      'is_initialized': _isInitialized,
      'total_games_played': _totalGamesPlayed,
      'session_count': _sessionCount,
      'highest_level_completed': _highestLevelCompleted,
      'fired_events': _firedEvents.toList(),
      'pending_events': ConversionMilestone.values
          .where((m) => !_firedEvents.contains(m.eventName))
          .map((m) => '${m.eventName} (need: ${m.threshold})')
          .toList(),
    };
  }

  /// Test: Force fire all events (for debugging)
  Future<void> forceFireAllForTesting() async {
    if (!kDebugMode) return;
    
    safePrint('🧪 Force firing all conversion events for testing');
    
    // Clear fired state
    _firedEvents.clear();
    final prefs = await SharedPreferences.getInstance();
    for (final milestone in ConversionMilestone.values) {
      await prefs.remove('$_keyPrefix${milestone.eventName}');
    }
    
    // Fire all
    for (final milestone in ConversionMilestone.values) {
      await _fireMilestoneEvent(milestone);
    }
  }

  /// Reset for testing
  Future<void> resetForTesting() async {
    if (!kDebugMode) return;
    
    _firedEvents.clear();
    _totalGamesPlayed = 0;
    _sessionCount = 0;
    _highestLevelCompleted = 0;
    
    final prefs = await SharedPreferences.getInstance();
    for (final milestone in ConversionMilestone.values) {
      await prefs.remove('$_keyPrefix${milestone.eventName}');
    }
    await prefs.remove(_keyTotalGames);
    await prefs.remove(_keySessions);
    
    safePrint('🧪 ConversionEventsManager reset for testing');
  }
}


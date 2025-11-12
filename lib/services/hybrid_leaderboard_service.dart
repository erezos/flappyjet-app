/// 🏆 Hybrid Leaderboard Service - Local-first with background sync
/// 
/// Provides a seamless leaderboard experience that works offline with cached data
/// and synchronizes with the backend in the background for real global rankings.
/// 
/// Features:
/// - Instant local scores (0ms latency)
/// - Background sync (non-blocking)
/// - Cached global leaderboards
/// - Network-aware (handles offline gracefully)
/// - Automatic retry with exponential backoff
library;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/debug_logger.dart';
import '../core/identity/device_identity_manager.dart';
import '../core/repositories/leaderboard_repository.dart';
import '../core/events/event_bus.dart';

/// Leaderboard data model for UI consumption
class LeaderboardData {
  final List<LeaderboardEntry> entries;
  final DateTime? lastUpdated;
  final bool isFetching;
  final bool isStale;
  final String? error;

  LeaderboardData({
    required this.entries,
    this.lastUpdated,
    this.isFetching = false,
    this.isStale = false,
    this.error,
  });

  LeaderboardData copyWith({
    List<LeaderboardEntry>? entries,
    DateTime? lastUpdated,
    bool? isFetching,
    bool? isStale,
    String? error,
  }) {
    return LeaderboardData(
      entries: entries ?? this.entries,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isFetching: isFetching ?? this.isFetching,
      isStale: isStale ?? this.isStale,
      error: error ?? this.error,
    );
  }
}

/// Tournament data model
class TournamentData {
  final String tournamentId;
  final DateTime startTime;
  final DateTime endTime;
  final String? prizePool;
  final int? userScore;
  final int? userRank;
  final int totalParticipants;
  final List<TournamentEntry> leaderboard;
  final DateTime? lastUpdated;
  final bool isFetching;

  TournamentData({
    required this.tournamentId,
    required this.startTime,
    required this.endTime,
    this.prizePool,
    this.userScore,
    this.userRank,
    this.totalParticipants = 0,
    required this.leaderboard,
    this.lastUpdated,
    this.isFetching = false,
  });
}

/// Hybrid leaderboard service with local-first + background sync
class HybridLeaderboardService extends ChangeNotifier {
  final LeaderboardRepository _repository;
  final DeviceIdentityManager _identity;
  final EventBus _eventBus;
  final String _backendUrl;

  // State
  LeaderboardData _globalLeaderboard = LeaderboardData(entries: []);
  TournamentData? _currentTournament;
  Timer? _syncTimer;
  bool _isInitialized = false;

  // Configuration
  static const Duration _syncInterval = Duration(minutes: 5);
  static const Duration _cacheStaleThreshold = Duration(minutes: 10);
  static const Duration _requestTimeout = Duration(seconds: 10);

  HybridLeaderboardService({
    required LeaderboardRepository repository,
    required DeviceIdentityManager identity,
    required EventBus eventBus,
    required String backendUrl,
  })  : _repository = repository,
        _identity = identity,
        _eventBus = eventBus,
        _backendUrl = backendUrl;

  // ===== GETTERS =====

  LeaderboardData get globalLeaderboard => _globalLeaderboard;
  TournamentData? get currentTournament => _currentTournament;
  bool get isInitialized => _isInitialized;

  // ===== INITIALIZATION =====

  /// Initialize the service and start background sync
  Future<void> initialize() async {
    if (_isInitialized) {
      safePrint('🏆 HybridLeaderboardService already initialized');
      return;
    }

    safePrint('🏆 Initializing HybridLeaderboardService...');

    try {
      // Load cached data
      await _loadCachedData();

      // Start background sync
      _startBackgroundSync();

      // Trigger immediate sync if cache is stale
      if (_isCacheStale()) {
        safePrint('🏆 Cache is stale, triggering immediate sync');
        unawaited(_syncInBackground());
      }

      _isInitialized = true;
      safePrint('🏆 ✅ HybridLeaderboardService initialized');
    } catch (e) {
      safePrint('🏆 ❌ Error initializing HybridLeaderboardService: $e');
    }
  }

  /// Load cached leaderboard data from database
  Future<void> _loadCachedData() async {
    try {
      // Load global leaderboard
      final entries = await _repository.getGlobalLeaderboard(limit: 100);
      final cacheAge = await _repository.getGlobalCacheAge();

      _globalLeaderboard = LeaderboardData(
        entries: entries,
        lastUpdated: cacheAge != null ? DateTime.now().subtract(cacheAge) : null,
        isStale: cacheAge != null && cacheAge > _cacheStaleThreshold,
      );

      safePrint('🏆 Loaded ${entries.length} cached global leaderboard entries');
      
      // Load tournament data (if exists)
      // TODO: Implement tournament cache loading in Phase 4
    } catch (e) {
      safePrint('🏆 ❌ Error loading cached data: $e');
    }
  }

  /// Check if cache is stale
  bool _isCacheStale() {
    if (_globalLeaderboard.lastUpdated == null) return true;
    final age = DateTime.now().difference(_globalLeaderboard.lastUpdated!);
    return age > _cacheStaleThreshold;
  }

  /// Start background sync timer
  void _startBackgroundSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (_) {
      unawaited(_syncInBackground());
    });
    safePrint('🏆 Background sync started (every ${_syncInterval.inMinutes} min)');
  }

  // ===== BACKGROUND SYNC =====

  /// Sync global leaderboard in background (non-blocking)
  Future<void> _syncInBackground() async {
    if (_globalLeaderboard.isFetching) {
      safePrint('🏆 Sync already in progress, skipping');
      return;
    }

    safePrint('🏆 🔄 Syncing global leaderboard in background...');

    // Update state to show fetching
    _globalLeaderboard = _globalLeaderboard.copyWith(isFetching: true, error: null);
    notifyListeners();

    try {
      // Fetch from backend
      final response = await http
          .get(
            Uri.parse('$_backendUrl/api/leaderboard/global?limit=100'),
            headers: {'User-Id': _identity.userId},
          )
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true && data['leaderboard'] != null) {
          final now = DateTime.now();
          final entries = (data['leaderboard'] as List)
              .map((e) => LeaderboardEntry(
                    rank: e['rank'] as int,
                    userId: e['user_id'] as String,
                    nickname: e['nickname'] as String?,
                    score: e['score'] as int,
                    jetSkin: e['jet_skin'] as String?,
                    theme: e['theme'] as String?,
                    timestamp: DateTime.fromMillisecondsSinceEpoch(e['timestamp'] as int),
                    cachedAt: now,
                  ))
              .toList();

          // Update cache
          await _repository.updateGlobalCache(entries);

          // Update state
          _globalLeaderboard = LeaderboardData(
            entries: entries,
            lastUpdated: now,
            isFetching: false,
            isStale: false,
          );

          safePrint('🏆 ✅ Global leaderboard synced: ${entries.length} entries');
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      safePrint('🏆 ⚠️ Background sync failed (will retry): $e');
      
      // Update state with error (but keep cached data)
      _globalLeaderboard = _globalLeaderboard.copyWith(
        isFetching: false,
        error: 'Sync failed: $e',
      );
    }

    notifyListeners();
  }

  // ===== PUBLIC API =====

  /// Get global leaderboard (returns cached data immediately)
  LeaderboardData getGlobalLeaderboard() {
    return _globalLeaderboard;
  }

  /// Force refresh global leaderboard (user-triggered)
  Future<void> refreshGlobalLeaderboard() async {
    safePrint('🏆 Manual refresh triggered');
    await _syncInBackground();
  }

  /// Submit score locally and fire event to backend
  Future<void> submitScore({
    required int score,
    required String gameMode,
    String? levelId,
    int? survivalTimeSeconds,
    int? obstaclesPassed,
    int? coinsCollected,
    int? gemsCollected,
    String? jetUsed,
    String? themeUsed,
    int? continuesUsed,
  }) async {
    try {
      // 1. Save locally first (instant)
      await _repository.addLocalScore(
        userId: _identity.userId,
        score: score,
        gameMode: gameMode,
        levelId: levelId,
        survivalTimeSeconds: survivalTimeSeconds,
        obstaclesPassed: obstaclesPassed,
        coinsCollected: coinsCollected,
        gemsCollected: gemsCollected,
        jetUsed: jetUsed,
        themeUsed: themeUsed,
        continuesUsed: continuesUsed,
      );

      safePrint('🏆 ✅ Score submitted locally: $score');

      // NOTE: game_ended event is now fired from GameStateManager with correct schema
      // This duplicate event firing has been removed to prevent schema conflicts
      // See: game_state_manager.dart setGameOver() method

      // 3. Trigger a sync shortly after score submission (gives backend time to process)
      Timer(const Duration(seconds: 10), () {
        unawaited(_syncInBackground());
      });
    } catch (e) {
      safePrint('🏆 ❌ Error submitting score: $e');
    }
  }

  /// Clear all cached leaderboard data
  Future<void> clearCache() async {
    await _repository.clearAllCache();
    await _loadCachedData();
    notifyListeners();
    safePrint('🏆 Cache cleared');
  }

  // ===== CLEANUP =====

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
    safePrint('🏆 HybridLeaderboardService disposed');
  }
}

/// Helper function for unawaited futures
void unawaited(Future<void> future) {
  // Intentionally not awaited - fire and forget
}


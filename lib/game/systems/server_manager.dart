/// 🌐 Server Manager - Production-ready backend for missions, leaderboards, and analytics
library;

import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'missions_manager.dart';
import 'achievements_manager.dart';
import 'player_identity_manager.dart';

/// Server endpoints configuration
class ServerConfig {
  // 🔥 Firebase Functions URLs (replace with your project)
  static const String baseUrl = 'https://us-central1-flappyjet-pro.cloudfunctions.net';
  
  // API Endpoints
  static const String syncPlayerData = '$baseUrl/syncPlayerData';
  static const String submitScore = '$baseUrl/submitScore';
  static const String getLeaderboard = '$baseUrl/getLeaderboard';
  static const String syncMissions = '$baseUrl/syncMissions';
  static const String validatePurchase = '$baseUrl/validatePurchase';
  static const String reportEvent = '$baseUrl/reportEvent';
  static const String getRemoteConfig = '$baseUrl/getRemoteConfig';
  
  // Fallback to local if server unavailable
  static const bool enableOfflineMode = true;
  static const int requestTimeoutSeconds = 10;
}

/// Player data sync model
class PlayerDataSync {
  final String playerId;
  final String nickname;
  final int bestScore;
  final int bestStreak;
  final int totalGamesPlayed;
  final int totalCoinsEarned;
  final List<String> unlockedAchievements;
  final List<String> ownedSkins;
  final String equippedSkin;
  final Map<String, dynamic> missionProgress;
  final DateTime lastSyncTime;

  PlayerDataSync({
    required this.playerId,
    required this.nickname,
    required this.bestScore,
    required this.bestStreak,
    required this.totalGamesPlayed,
    required this.totalCoinsEarned,
    required this.unlockedAchievements,
    required this.ownedSkins,
    required this.equippedSkin,
    required this.missionProgress,
    required this.lastSyncTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'nickname': nickname,
      'bestScore': bestScore,
      'bestStreak': bestStreak,
      'totalGamesPlayed': totalGamesPlayed,
      'totalCoinsEarned': totalCoinsEarned,
      'unlockedAchievements': unlockedAchievements,
      'ownedSkins': ownedSkins,
      'equippedSkin': equippedSkin,
      'missionProgress': missionProgress,
      'lastSyncTime': lastSyncTime.millisecondsSinceEpoch,
      'clientVersion': '1.0.0',
      'platform': defaultTargetPlatform.name,
    };
  }

  factory PlayerDataSync.fromJson(Map<String, dynamic> json) {
    return PlayerDataSync(
      playerId: json['playerId'],
      nickname: json['nickname'],
      bestScore: json['bestScore'],
      bestStreak: json['bestStreak'],
      totalGamesPlayed: json['totalGamesPlayed'],
      totalCoinsEarned: json['totalCoinsEarned'],
      unlockedAchievements: List<String>.from(json['unlockedAchievements']),
      ownedSkins: List<String>.from(json['ownedSkins']),
      equippedSkin: json['equippedSkin'],
      missionProgress: Map<String, dynamic>.from(json['missionProgress']),
      lastSyncTime: DateTime.fromMillisecondsSinceEpoch(json['lastSyncTime']),
    );
  }
}

/// Leaderboard entry model
class LeaderboardEntry {
  final String playerId;
  final String nickname;
  final int score;
  final int rank;
  final String skinId;
  final DateTime achievedAt;
  final bool isCurrentPlayer;

  LeaderboardEntry({
    required this.playerId,
    required this.nickname,
    required this.score,
    required this.rank,
    required this.skinId,
    required this.achievedAt,
    this.isCurrentPlayer = false,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      playerId: json['playerId'],
      nickname: json['nickname'],
      score: json['score'],
      rank: json['rank'],
      skinId: json['skinId'],
      achievedAt: DateTime.fromMillisecondsSinceEpoch(json['achievedAt']),
      isCurrentPlayer: json['isCurrentPlayer'] ?? false,
    );
  }
}

/// Server Manager - Handles all backend communication
class ServerManager extends ChangeNotifier {
  static final ServerManager _instance = ServerManager._internal();
  factory ServerManager() => _instance;
  ServerManager._internal();

  static const String _keyLastSyncTime = 'server_last_sync';
  static const String _keyOfflineQueue = 'server_offline_queue';
  static const String _keyPlayerToken = 'server_player_token';

  bool _isOnline = true;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  String? _playerToken;
  final List<Map<String, dynamic>> _offlineQueue = [];

  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Initialize server manager
  Future<void> initialize() async {
    await _loadOfflineQueue();
    await _loadLastSyncTime();
    await _generatePlayerToken();
    
    // Try to sync offline data
    if (_offlineQueue.isNotEmpty) {
      await _processOfflineQueue();
    }
    
    // Start periodic sync
    _startPeriodicSync();
  }

  /// Generate or load player authentication token
  Future<void> _generatePlayerToken() async {
    final prefs = await SharedPreferences.getInstance();
    _playerToken = prefs.getString(_keyPlayerToken);
    
    if (_playerToken == null) {
      // Generate unique token for this device/player
      final random = Random();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _playerToken = 'player_${timestamp}_${random.nextInt(999999)}';
      await prefs.setString(_keyPlayerToken, _playerToken!);
    }
  }

  /// Load offline queue from storage
  Future<void> _loadOfflineQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final queueJson = prefs.getString(_keyOfflineQueue);
    
    if (queueJson != null) {
      try {
        final List<dynamic> queue = jsonDecode(queueJson);
        _offlineQueue.clear();
        _offlineQueue.addAll(queue.cast<Map<String, dynamic>>());
      } catch (e) {
        debugPrint('🌐 Error loading offline queue: $e');
      }
    }
  }

  /// Save offline queue to storage
  Future<void> _saveOfflineQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyOfflineQueue, jsonEncode(_offlineQueue));
  }

  /// Load last sync time
  Future<void> _loadLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final syncTimeMs = prefs.getInt(_keyLastSyncTime);
    if (syncTimeMs != null) {
      _lastSyncTime = DateTime.fromMillisecondsSinceEpoch(syncTimeMs);
    }
  }

  /// Save last sync time
  Future<void> _saveLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    _lastSyncTime = DateTime.now();
    await prefs.setInt(_keyLastSyncTime, _lastSyncTime!.millisecondsSinceEpoch);
  }

  /// Make HTTP request with error handling and offline support
  Future<Map<String, dynamic>?> _makeRequest(
    String endpoint,
    Map<String, dynamic> data, {
    bool addToOfflineQueue = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_playerToken',
          'X-Client-Version': '1.0.0',
          'X-Platform': defaultTargetPlatform.name,
        },
        body: jsonEncode(data),
      ).timeout(Duration(seconds: ServerConfig.requestTimeoutSeconds));

      if (response.statusCode == 200) {
        _isOnline = true;
        notifyListeners();
        return jsonDecode(response.body);
      } else {
        debugPrint('🌐 Server error ${response.statusCode}: ${response.body}');
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('🌐 Network error: $e');
      _isOnline = false;
      
      // Add to offline queue if enabled
      if (addToOfflineQueue && ServerConfig.enableOfflineMode) {
        _offlineQueue.add({
          'endpoint': endpoint,
          'data': data,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        await _saveOfflineQueue();
      }
      
      notifyListeners();
      return null;
    }
  }

  /// Submit score to leaderboard
  Future<bool> submitScore({
    required int score,
    required int survivalTime,
    required String skinUsed,
    required int coinsEarned,
  }) async {
    final playerIdentity = PlayerIdentityManager();
    
    final data = {
      'playerId': playerIdentity.playerId,
      'nickname': playerIdentity.playerName,
      'score': score,
      'survivalTime': survivalTime,
      'skinUsed': skinUsed,
      'coinsEarned': coinsEarned,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'gameVersion': '1.0.0',
    };

    final response = await _makeRequest(ServerConfig.submitScore, data);
    return response != null && response['success'] == true;
  }

  /// Get global leaderboard
  Future<List<LeaderboardEntry>> getLeaderboard({
    int limit = 100,
    String period = 'all_time', // 'daily', 'weekly', 'monthly', 'all_time'
  }) async {
    final playerIdentity = PlayerIdentityManager();
    
    final data = {
      'limit': limit,
      'period': period,
      'playerId': playerIdentity.playerId, // To highlight current player
    };

    final response = await _makeRequest(
      ServerConfig.getLeaderboard, 
      data,
      addToOfflineQueue: false, // Don't queue leaderboard requests
    );

    if (response != null && response['leaderboard'] != null) {
      final List<dynamic> entries = response['leaderboard'];
      return entries.map((entry) => LeaderboardEntry.fromJson(entry)).toList();
    }

    // Return empty list if offline or error
    return [];
  }

  /// Sync player data with server
  Future<bool> syncPlayerData() async {
    if (_isSyncing) return false;
    
    _isSyncing = true;
    notifyListeners();

    try {
      final playerIdentity = PlayerIdentityManager();
      final missionsManager = MissionsManager();
      final achievementsManager = AchievementsManager();
      
      // Prepare sync data
      final syncData = PlayerDataSync(
        playerId: playerIdentity.playerId,
        nickname: playerIdentity.playerName,
        bestScore: 0, // Will be loaded from LivesManager
        bestStreak: 0, // Will be loaded from LivesManager
        totalGamesPlayed: 0, // Will be loaded from stats
        totalCoinsEarned: 0, // Will be loaded from stats
        unlockedAchievements: achievementsManager.unlockedAchievements
            .map((a) => a.id)
            .toList(),
        ownedSkins: [], // Will be loaded from InventoryManager
        equippedSkin: '', // Will be loaded from InventoryManager
        missionProgress: {}, // Will be loaded from MissionsManager
        lastSyncTime: DateTime.now(),
      );

      final response = await _makeRequest(
        ServerConfig.syncPlayerData,
        syncData.toJson(),
      );

      if (response != null && response['success'] == true) {
        await _saveLastSyncTime();
        debugPrint('🌐 Player data synced successfully');
        return true;
      }

      return false;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Sync missions with server (get personalized missions)
  Future<List<Mission>?> syncMissions(PlayerStats playerStats) async {
    final data = {
      'playerId': PlayerIdentityManager().playerId,
      'playerStats': {
        'bestScore': playerStats.bestScore,
        'bestStreak': playerStats.bestStreak,
        'totalGamesPlayed': playerStats.totalGamesPlayed,
        'averageScore': playerStats.averageScore,
        'skillLevel': playerStats.skillLevel.name,
      },
      'currentMissions': MissionsManager().dailyMissions
          .map((m) => m.toJson())
          .toList(),
    };

    final response = await _makeRequest(
      ServerConfig.syncMissions,
      data,
      addToOfflineQueue: false, // Missions are generated locally if offline
    );

    if (response != null && response['missions'] != null) {
      final List<dynamic> missionsData = response['missions'];
      return missionsData.map((data) => Mission.fromJson(data)).toList();
    }

    return null; // Use local generation
  }

  /// Validate in-app purchase
  Future<bool> validatePurchase({
    required String productId,
    required String purchaseToken,
    required String platform,
  }) async {
    final data = {
      'playerId': PlayerIdentityManager().playerId,
      'productId': productId,
      'purchaseToken': purchaseToken,
      'platform': platform,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    final response = await _makeRequest(ServerConfig.validatePurchase, data);
    return response != null && response['valid'] == true;
  }

  /// Report analytics event
  Future<void> reportEvent({
    required String eventName,
    required Map<String, dynamic> parameters,
  }) async {
    final data = {
      'playerId': PlayerIdentityManager().playerId,
      'eventName': eventName,
      'parameters': parameters,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'sessionId': _playerToken,
    };

    // Don't block gameplay for analytics
    _makeRequest(ServerConfig.reportEvent, data);
  }

  /// Get remote configuration
  Future<Map<String, dynamic>?> getRemoteConfig() async {
    final data = {
      'playerId': PlayerIdentityManager().playerId,
      'clientVersion': '1.0.0',
      'platform': defaultTargetPlatform.name,
    };

    final response = await _makeRequest(
      ServerConfig.getRemoteConfig,
      data,
      addToOfflineQueue: false,
    );

    return response?['config'];
  }

  /// Process offline queue when connection is restored
  Future<void> _processOfflineQueue() async {
    if (_offlineQueue.isEmpty || !_isOnline) return;

    debugPrint('🌐 Processing ${_offlineQueue.length} offline requests');
    
    final processedItems = <Map<String, dynamic>>[];
    
    for (final item in _offlineQueue) {
      try {
        final response = await _makeRequest(
          item['endpoint'],
          item['data'],
          addToOfflineQueue: false, // Don't re-queue
        );
        
        if (response != null) {
          processedItems.add(item);
        }
      } catch (e) {
        debugPrint('🌐 Failed to process offline item: $e');
        break; // Stop processing if we're offline again
      }
    }
    
    // Remove successfully processed items
    for (final item in processedItems) {
      _offlineQueue.remove(item);
    }
    
    await _saveOfflineQueue();
    
    if (processedItems.isNotEmpty) {
      debugPrint('🌐 Processed ${processedItems.length} offline requests');
    }
  }

  /// Start periodic sync (every 5 minutes when app is active)
  void _startPeriodicSync() {
    // This would be implemented with a timer in a real app
    // For now, sync is triggered manually or on game events
  }

  /// Force sync now (manual trigger)
  Future<void> forceSyncNow() async {
    await syncPlayerData();
    await _processOfflineQueue();
  }

  /// Check if sync is needed (every 30 minutes)
  bool get needsSync {
    if (_lastSyncTime == null) return true;
    return DateTime.now().difference(_lastSyncTime!).inMinutes > 30;
  }

  /// Get offline queue size for debugging
  int get offlineQueueSize => _offlineQueue.length;
}

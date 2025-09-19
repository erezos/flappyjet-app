/// 🎮 Game Data Manager - AAA Mobile Game Standard
/// 
/// Single source of truth for all game data with real-time sync
/// Based on patterns from successful mobile games like Supercell titles
library;

import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../debug_logger.dart';
import '../network/network_manager.dart';
import '../../game/systems/player_identity_manager.dart';

/// Player statistics data
class PlayerStats {
  final int bestScore;
  final int bestStreak;
  final int totalGamesPlayed;
  final int totalCoinsEarned;
  final int totalGemsEarned;
  final int totalPlayTime; // in seconds
  final DateTime lastPlayedAt;

  PlayerStats({
    required this.bestScore,
    required this.bestStreak,
    required this.totalGamesPlayed,
    required this.totalCoinsEarned,
    required this.totalGemsEarned,
    required this.totalPlayTime,
    required this.lastPlayedAt,
  });

  Map<String, dynamic> toJson() => {
    'bestScore': bestScore,
    'bestStreak': bestStreak,
    'totalGamesPlayed': totalGamesPlayed,
    'totalCoinsEarned': totalCoinsEarned,
    'totalGemsEarned': totalGemsEarned,
    'totalPlayTime': totalPlayTime,
    'lastPlayedAt': lastPlayedAt.millisecondsSinceEpoch,
  };

  factory PlayerStats.fromJson(Map<String, dynamic> json) {
    return PlayerStats(
      bestScore: json['bestScore'] ?? 0,
      bestStreak: json['bestStreak'] ?? 0,
      totalGamesPlayed: json['totalGamesPlayed'] ?? 0,
      totalCoinsEarned: json['totalCoinsEarned'] ?? 0,
      totalGemsEarned: json['totalGemsEarned'] ?? 0,
      totalPlayTime: json['totalPlayTime'] ?? 0,
      lastPlayedAt: DateTime.fromMillisecondsSinceEpoch(
        json['lastPlayedAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  PlayerStats copyWith({
    int? bestScore,
    int? bestStreak,
    int? totalGamesPlayed,
    int? totalCoinsEarned,
    int? totalGemsEarned,
    int? totalPlayTime,
    DateTime? lastPlayedAt,
  }) {
    return PlayerStats(
      bestScore: bestScore ?? this.bestScore,
      bestStreak: bestStreak ?? this.bestStreak,
      totalGamesPlayed: totalGamesPlayed ?? this.totalGamesPlayed,
      totalCoinsEarned: totalCoinsEarned ?? this.totalCoinsEarned,
      totalGemsEarned: totalGemsEarned ?? this.totalGemsEarned,
      totalPlayTime: totalPlayTime ?? this.totalPlayTime,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
    );
  }
}

/// Player resources (coins, gems, hearts)
class PlayerResources {
  final int coins;
  final int gems;
  final int hearts;
  final DateTime heartsLastRegen;
  final bool heartBoosterActive;
  final DateTime? heartBoosterExpiry;

  PlayerResources({
    required this.coins,
    required this.gems,
    required this.hearts,
    required this.heartsLastRegen,
    required this.heartBoosterActive,
    this.heartBoosterExpiry,
  });

  Map<String, dynamic> toJson() => {
    'coins': coins,
    'gems': gems,
    'hearts': hearts,
    'heartsLastRegen': heartsLastRegen.millisecondsSinceEpoch,
    'heartBoosterActive': heartBoosterActive,
    'heartBoosterExpiry': heartBoosterExpiry?.millisecondsSinceEpoch,
  };

  factory PlayerResources.fromJson(Map<String, dynamic> json) {
    return PlayerResources(
      coins: json['coins'] ?? 500, // Default new player bonus
      gems: json['gems'] ?? 25,   // Default new player bonus
      hearts: json['hearts'] ?? 3,
      heartsLastRegen: DateTime.fromMillisecondsSinceEpoch(
        json['heartsLastRegen'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      heartBoosterActive: json['heartBoosterActive'] ?? false,
      heartBoosterExpiry: json['heartBoosterExpiry'] != null
        ? DateTime.fromMillisecondsSinceEpoch(json['heartBoosterExpiry'])
        : null,
    );
  }

  PlayerResources copyWith({
    int? coins,
    int? gems,
    int? hearts,
    DateTime? heartsLastRegen,
    bool? heartBoosterActive,
    DateTime? heartBoosterExpiry,
  }) {
    return PlayerResources(
      coins: coins ?? this.coins,
      gems: gems ?? this.gems,
      hearts: hearts ?? this.hearts,
      heartsLastRegen: heartsLastRegen ?? this.heartsLastRegen,
      heartBoosterActive: heartBoosterActive ?? this.heartBoosterActive,
      heartBoosterExpiry: heartBoosterExpiry ?? this.heartBoosterExpiry,
    );
  }
}

/// Game data synchronization state
enum SyncState {
  idle,
  syncing,
  conflict,
  error,
}

/// Game Data Manager - Unified data management with real-time sync
class GameDataManager extends ChangeNotifier {
  static final GameDataManager _instance = GameDataManager._internal();
  factory GameDataManager() => _instance;
  GameDataManager._internal();

  // Dependencies
  final NetworkManager _networkManager = NetworkManager();
  final PlayerIdentityManager _playerIdentity = PlayerIdentityManager();

  // Storage keys
  static const String _keyPlayerStats = 'player_stats_v2';
  static const String _keyPlayerResources = 'player_resources_v2';
  static const String _keyLastSyncTime = 'last_sync_time_v2';
  static const String _keyPendingChanges = 'pending_changes_v2';

  // Data state
  PlayerStats _playerStats = PlayerStats(
    bestScore: 0,
    bestStreak: 0,
    totalGamesPlayed: 0,
    totalCoinsEarned: 0,
    totalGemsEarned: 0,
    totalPlayTime: 0,
    lastPlayedAt: DateTime.now(),
  );

  PlayerResources _playerResources = PlayerResources(
    coins: 500,
    gems: 25,
    hearts: 3,
    heartsLastRegen: DateTime.now(),
    heartBoosterActive: false,
  );

  // Sync state
  SyncState _syncState = SyncState.idle;
  DateTime? _lastSyncTime;
  final Map<String, dynamic> _pendingChanges = {};
  Timer? _syncTimer;

  // Getters
  PlayerStats get playerStats => _playerStats;
  PlayerResources get playerResources => _playerResources;
  SyncState get syncState => _syncState;
  DateTime? get lastSyncTime => _lastSyncTime;
  bool get hasPendingChanges => _pendingChanges.isNotEmpty;

  /// Initialize game data manager
  Future<void> initialize() async {
    await _loadLocalData();
    await _startPeriodicSync();
    
    // Initial sync if authenticated
    if (_playerIdentity.isAuthenticated) {
      await _performSync();
    }
    
    safePrint('🎮 Game Data Manager initialized');
  }

  /// Update player statistics
  Future<void> updatePlayerStats({
    int? bestScore,
    int? bestStreak,
    int? totalGamesPlayed,
    int? totalCoinsEarned,
    int? totalGemsEarned,
    int? totalPlayTime,
  }) async {
    final oldStats = _playerStats;
    
    _playerStats = _playerStats.copyWith(
      bestScore: bestScore ?? _playerStats.bestScore,
      bestStreak: bestStreak ?? _playerStats.bestStreak,
      totalGamesPlayed: totalGamesPlayed ?? _playerStats.totalGamesPlayed,
      totalCoinsEarned: totalCoinsEarned ?? _playerStats.totalCoinsEarned,
      totalGemsEarned: totalGemsEarned ?? _playerStats.totalGemsEarned,
      totalPlayTime: totalPlayTime ?? _playerStats.totalPlayTime,
      lastPlayedAt: DateTime.now(),
    );

    // Track changes for sync
    if (bestScore != null && bestScore != oldStats.bestScore) {
      _pendingChanges['bestScore'] = bestScore;
    }
    if (bestStreak != null && bestStreak != oldStats.bestStreak) {
      _pendingChanges['bestStreak'] = bestStreak;
    }
    if (totalGamesPlayed != null && totalGamesPlayed != oldStats.totalGamesPlayed) {
      _pendingChanges['totalGamesPlayed'] = totalGamesPlayed;
    }

    await _saveLocalData();
    notifyListeners();

    // Trigger immediate sync for important changes (new high score)
    if (bestScore != null && bestScore > oldStats.bestScore) {
      await _performSync();
    }
  }

  /// Update player resources
  Future<void> updatePlayerResources({
    int? coins,
    int? gems,
    int? hearts,
    DateTime? heartsLastRegen,
    bool? heartBoosterActive,
    DateTime? heartBoosterExpiry,
  }) async {
    final oldResources = _playerResources;
    
    _playerResources = _playerResources.copyWith(
      coins: coins ?? _playerResources.coins,
      gems: gems ?? _playerResources.gems,
      hearts: hearts ?? _playerResources.hearts,
      heartsLastRegen: heartsLastRegen ?? _playerResources.heartsLastRegen,
      heartBoosterActive: heartBoosterActive ?? _playerResources.heartBoosterActive,
      heartBoosterExpiry: heartBoosterExpiry ?? _playerResources.heartBoosterExpiry,
    );

    // Track changes for sync
    if (coins != null && coins != oldResources.coins) {
      _pendingChanges['coins'] = coins;
    }
    if (gems != null && gems != oldResources.gems) {
      _pendingChanges['gems'] = gems;
    }
    if (hearts != null && hearts != oldResources.hearts) {
      _pendingChanges['hearts'] = hearts;
    }

    await _saveLocalData();
    notifyListeners();
  }

  /// Add coins with validation
  Future<bool> addCoins(int amount) async {
    if (amount <= 0) return false;
    
    final newAmount = _playerResources.coins + amount;
    await updatePlayerResources(coins: newAmount);
    
    safePrint('🎮 💰 Added $amount coins (Total: $newAmount)');
    return true;
  }

  /// Spend coins with validation
  Future<bool> spendCoins(int amount) async {
    if (amount <= 0 || _playerResources.coins < amount) return false;
    
    final newAmount = _playerResources.coins - amount;
    await updatePlayerResources(coins: newAmount);
    
    safePrint('🎮 💰 Spent $amount coins (Remaining: $newAmount)');
    return true;
  }

  /// Add gems with validation
  Future<bool> addGems(int amount) async {
    if (amount <= 0) return false;
    
    final newAmount = _playerResources.gems + amount;
    await updatePlayerResources(gems: newAmount);
    
    safePrint('🎮 💎 Added $amount gems (Total: $newAmount)');
    return true;
  }

  /// Spend gems with validation
  Future<bool> spendGems(int amount) async {
    if (amount <= 0 || _playerResources.gems < amount) return false;
    
    final newAmount = _playerResources.gems - amount;
    await updatePlayerResources(gems: newAmount);
    
    safePrint('🎮 💎 Spent $amount gems (Remaining: $newAmount)');
    return true;
  }

  /// Use a heart (for game play)
  Future<bool> useHeart() async {
    if (_playerResources.hearts <= 0) return false;
    
    final newAmount = _playerResources.hearts - 1;
    await updatePlayerResources(hearts: newAmount);
    
    safePrint('🎮 ❤️ Used heart (Remaining: $newAmount)');
    return true;
  }

  /// Regenerate hearts based on time
  Future<void> regenerateHearts() async {
    const maxHearts = 3;
    const regenTimeMinutes = 30;
    
    if (_playerResources.hearts >= maxHearts) return;
    
    final now = DateTime.now();
    final timeSinceLastRegen = now.difference(_playerResources.heartsLastRegen);
    final heartsToRegen = (timeSinceLastRegen.inMinutes / regenTimeMinutes).floor();
    
    if (heartsToRegen > 0) {
      final newHearts = (_playerResources.hearts + heartsToRegen).clamp(0, maxHearts);
      await updatePlayerResources(
        hearts: newHearts,
        heartsLastRegen: now,
      );
      
      safePrint('🎮 ❤️ Regenerated hearts: $newHearts/$maxHearts');
    }
  }

  /// Record game completion
  Future<void> recordGameCompletion({
    required int score,
    required int survivalTime,
    required int coinsEarned,
    required int gemsEarned,
  }) async {
    final newBestScore = score > _playerStats.bestScore ? score : _playerStats.bestScore;
    
    await updatePlayerStats(
      bestScore: newBestScore,
      totalGamesPlayed: _playerStats.totalGamesPlayed + 1,
      totalCoinsEarned: _playerStats.totalCoinsEarned + coinsEarned,
      totalGemsEarned: _playerStats.totalGemsEarned + gemsEarned,
      totalPlayTime: _playerStats.totalPlayTime + survivalTime,
    );

    await addCoins(coinsEarned);
    await addGems(gemsEarned);

    // Submit score to leaderboard
    await _networkManager.submitScore(
      score: score,
      survivalTime: survivalTime,
      skinUsed: 'sky_jet', // This should come from inventory manager
      coinsEarned: coinsEarned,
      gemsEarned: gemsEarned,
    );
  }

  /// Force synchronization with backend
  Future<bool> forcSync() async {
    return await _performSync();
  }

  /// Perform data synchronization with backend
  Future<bool> _performSync() async {
    if (!_playerIdentity.isAuthenticated || _syncState == SyncState.syncing) {
      return false;
    }

    _setSyncState(SyncState.syncing);

    try {
      // Prepare sync data
      final syncData = {
        'stats': _playerStats.toJson(),
        'resources': _playerResources.toJson(),
        'pendingChanges': _pendingChanges,
        'lastSyncTime': _lastSyncTime?.millisecondsSinceEpoch,
      };

      // Send to backend
      final result = await _networkManager.syncPlayerData(syncData);

      if (result.success && result.data != null) {
        // Handle sync response
        await _handleSyncResponse(result.data!);
        
        _lastSyncTime = DateTime.now();
        _pendingChanges.clear();
        await _saveLocalData();
        
        _setSyncState(SyncState.idle);
        safePrint('🎮 ✅ Data sync completed successfully');
        return true;
      } else {
        _setSyncState(SyncState.error);
        safePrint('🎮 ❌ Data sync failed: ${result.error}');
        return false;
      }
    } catch (e) {
      _setSyncState(SyncState.error);
      safePrint('🎮 ❌ Data sync error: $e');
      return false;
    }
  }

  /// Handle sync response from backend
  Future<void> _handleSyncResponse(Map<String, dynamic> response) async {
    // Check for conflicts and resolve them
    final serverStats = response['stats'];
    final serverResources = response['resources'];
    
    if (serverStats != null) {
      final serverPlayerStats = PlayerStats.fromJson(serverStats);
      
      // Resolve conflicts (server wins for most cases, local wins for resources)
      _playerStats = PlayerStats(
        bestScore: [_playerStats.bestScore, serverPlayerStats.bestScore].reduce((a, b) => a > b ? a : b),
        bestStreak: [_playerStats.bestStreak, serverPlayerStats.bestStreak].reduce((a, b) => a > b ? a : b),
        totalGamesPlayed: [_playerStats.totalGamesPlayed, serverPlayerStats.totalGamesPlayed].reduce((a, b) => a > b ? a : b),
        totalCoinsEarned: [_playerStats.totalCoinsEarned, serverPlayerStats.totalCoinsEarned].reduce((a, b) => a > b ? a : b),
        totalGemsEarned: [_playerStats.totalGemsEarned, serverPlayerStats.totalGemsEarned].reduce((a, b) => a > b ? a : b),
        totalPlayTime: [_playerStats.totalPlayTime, serverPlayerStats.totalPlayTime].reduce((a, b) => a > b ? a : b),
        lastPlayedAt: [_playerStats.lastPlayedAt, serverPlayerStats.lastPlayedAt].reduce((a, b) => a.isAfter(b) ? a : b),
      );
    }

    if (serverResources != null) {
      // For resources, local version usually wins (to prevent loss of purchases)
      // But we can sync hearts and booster status
      final serverPlayerResources = PlayerResources.fromJson(serverResources);
      
      _playerResources = _playerResources.copyWith(
        heartBoosterActive: serverPlayerResources.heartBoosterActive,
        heartBoosterExpiry: serverPlayerResources.heartBoosterExpiry,
      );
    }

    notifyListeners();
  }

  /// Load data from local storage
  Future<void> _loadLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load player stats
      final statsJson = prefs.getString(_keyPlayerStats);
      if (statsJson != null) {
        _playerStats = PlayerStats.fromJson(jsonDecode(statsJson));
      }
      
      // Load player resources
      final resourcesJson = prefs.getString(_keyPlayerResources);
      if (resourcesJson != null) {
        _playerResources = PlayerResources.fromJson(jsonDecode(resourcesJson));
      }
      
      // Load sync metadata
      final lastSyncMs = prefs.getInt(_keyLastSyncTime);
      if (lastSyncMs != null) {
        _lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSyncMs);
      }
      
      final pendingChangesJson = prefs.getString(_keyPendingChanges);
      if (pendingChangesJson != null) {
        _pendingChanges.addAll(Map<String, dynamic>.from(jsonDecode(pendingChangesJson)));
      }
      
    } catch (e) {
      safePrint('🎮 ⚠️ Failed to load local data: $e');
    }
  }

  /// Save data to local storage
  Future<void> _saveLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString(_keyPlayerStats, jsonEncode(_playerStats.toJson()));
      await prefs.setString(_keyPlayerResources, jsonEncode(_playerResources.toJson()));
      
      if (_lastSyncTime != null) {
        await prefs.setInt(_keyLastSyncTime, _lastSyncTime!.millisecondsSinceEpoch);
      }
      
      await prefs.setString(_keyPendingChanges, jsonEncode(_pendingChanges));
      
    } catch (e) {
      safePrint('🎮 ⚠️ Failed to save local data: $e');
    }
  }

  /// Start periodic sync timer
  Future<void> _startPeriodicSync() async {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(Duration(minutes: 5), (timer) {
      if (_playerIdentity.isAuthenticated && _pendingChanges.isNotEmpty) {
        _performSync();
      }
    });
  }

  /// Set sync state and notify listeners
  void _setSyncState(SyncState newState) {
    if (_syncState != newState) {
      _syncState = newState;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}

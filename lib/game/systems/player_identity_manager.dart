/// 🎯 Player Identity Manager - Single source of truth for player identity
library;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_manager.dart';
import 'leaderboard_manager.dart';
import 'global_leaderboard_service.dart';

/// Centralized player identity management
/// Ensures all systems use consistent player names and IDs
class PlayerIdentityManager extends ChangeNotifier {
  static final PlayerIdentityManager _instance = PlayerIdentityManager._internal();
  factory PlayerIdentityManager() => _instance;
  PlayerIdentityManager._internal();

  static const String _keyPlayerName = 'unified_player_name';
  static const String _keyPlayerId = 'unified_player_id';
  
  String _playerName = '';
  String _playerId = '';
  bool _isInitialized = false;

  String get playerName => _playerName;
  String get playerId => _playerId;
  bool get isInitialized => _isInitialized;

  /// Initialize and sync all player identity systems
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load existing identity
      _playerId = prefs.getString(_keyPlayerId) ?? _generatePlayerId();
      _playerName = prefs.getString(_keyPlayerName) ?? '';
      
      // Migrate from existing systems
      await _migrateFromExistingSystems(prefs);
      
      // Save unified identity
      await prefs.setString(_keyPlayerId, _playerId);
      await prefs.setString(_keyPlayerName, _playerName);
      
      _isInitialized = true;
      notifyListeners();
      
      debugPrint('🎯 PlayerIdentityManager initialized: $_playerName ($_playerId)');
    } catch (e) {
      debugPrint('⚠️ Failed to initialize PlayerIdentityManager: $e');
      _isInitialized = true;
    }
  }

  /// Update player name across all systems
  Future<void> updatePlayerName(String newName) async {
    if (newName.trim().isEmpty || newName.trim() == _playerName) return;
    
    final oldName = _playerName;
    _playerName = newName.trim();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyPlayerName, _playerName);
      
      // Update all dependent systems
      await _syncToAllSystems();
      
      notifyListeners();
      debugPrint('🎯 Player name updated: $oldName → $_playerName');
    } catch (e) {
      debugPrint('⚠️ Failed to update player name: $e');
      _playerName = oldName; // Rollback
    }
  }

  /// Sync identity to all dependent systems
  Future<void> _syncToAllSystems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Update ProfileManager storage
      await prefs.setString('profile_nickname', _playerName);
      
      // Update LeaderboardManager storage
      await prefs.setString('player_name', _playerName);
      
      // Update GlobalLeaderboardService storage
      await prefs.setString('global_player_name', _playerName);
      
      // Trigger updates in managers if they're initialized
      final profileManager = ProfileManager();
      if (profileManager.nickname != _playerName) {
        await profileManager.setNickname(_playerName);
      }
      
      final leaderboardManager = LeaderboardManager();
      if (leaderboardManager.isInitialized && leaderboardManager.playerName != _playerName) {
        await leaderboardManager.updatePlayerName(_playerName);
      }
      
      final globalService = GlobalLeaderboardService();
      if (globalService.isInitialized && globalService.playerName != _playerName) {
        await globalService.registerPlayer(playerName: _playerName);
      }
      
    } catch (e) {
      debugPrint('⚠️ Failed to sync to all systems: $e');
    }
  }

  /// Migrate data from existing fragmented systems
  Future<void> _migrateFromExistingSystems(SharedPreferences prefs) async {
    // Priority order for name migration
    final sources = [
      'profile_nickname',  // ProfileManager (fixed key)
      'pf_nickname',       // Old ProfileManager key
      'player_name',       // LeaderboardManager
      'global_player_name', // GlobalLeaderboardService
    ];
    
    for (final key in sources) {
      final name = prefs.getString(key);
      if (name != null && name.isNotEmpty && name != 'You' && name != 'Anonymous') {
        _playerName = name;
        debugPrint('🎯 Migrated player name from $key: $_playerName');
        break;
      }
    }
    
    // Generate default if no valid name found
    if (_playerName.isEmpty) {
      _playerName = _generateDefaultName();
      debugPrint('🎯 Generated default player name: $_playerName');
    }
  }

  String _generatePlayerId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'player_$random';
  }

  String _generateDefaultName() {
    // Use same format as ProfileManager for consistency: Pilot#### 
    final rng = math.Random();
    final num = 1000 + rng.nextInt(9000);
    return 'Pilot$num';
  }

  /// Force reset manager to new player state (for development reset)
  Future<void> forceResetToNewPlayer() async {
    _isInitialized = false;
    _playerName = '';
    _playerId = '';
    
    // Generate new player identity
    _playerId = _generatePlayerId();
    _playerName = _generateDefaultName();
    
    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPlayerId, _playerId);
    await prefs.setString(_keyPlayerName, _playerName);
    
    // Sync to all systems
    await _syncToAllSystems();
    
    _isInitialized = true;
    notifyListeners();
    
    debugPrint('🎯 PlayerIdentityManager force reset: $_playerName ($_playerId)');
  }
}

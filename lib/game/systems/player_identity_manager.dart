/// 🎯 Player Identity Manager - Single source of truth for player identity
library;
import '../../core/debug_logger.dart';

import 'dart:math' as math;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'profile_manager.dart';
import 'leaderboard_manager.dart';
import 'global_leaderboard_service.dart';
import 'game_events_tracker.dart';
import 'railway_server_manager.dart';

/// Centralized player identity management
/// Ensures all systems use consistent player names and IDs
class PlayerIdentityManager extends ChangeNotifier {
  static final PlayerIdentityManager _instance =
      PlayerIdentityManager._internal();
  factory PlayerIdentityManager() => _instance;
  PlayerIdentityManager._internal();

  static const String _keyPlayerName = 'unified_player_name';
  static const String _keyPlayerId = 'unified_player_id';
  static const String _keyDeviceId = 'device_id';

  static const String _keyBackendRegistered = 'backend_registered';
  static const String _keyAuthToken = 'auth_token';

  String _playerName = '';
  String _playerId = '';
  String _deviceId = '';
  String _authToken = '';
  bool _isInitialized = false;
  bool _isFirstTimeUser = true;
  bool _isBackendRegistered = false;

  String get playerName => _playerName;
  String get playerId => _playerId;
  String get deviceId => _deviceId;
  String get authToken => _authToken;
  bool get isInitialized => _isInitialized;
  bool get isFirstTimeUser => _isFirstTimeUser;
  bool get isBackendRegistered => _isBackendRegistered;

  /// Get device ID for backend registration
  Future<String> _getDeviceId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id; // Android ID
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? _generateFallbackDeviceId();
      } else {
        return _generateFallbackDeviceId();
      }
    } catch (e) {
      safePrint('⚠️ Failed to get device ID: $e');
      return _generateFallbackDeviceId();
    }
  }

  String _generateFallbackDeviceId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = math.Random().nextInt(999999).toString().padLeft(6, '0');
    return 'device_${timestamp}_$random';
  }

  /// Initialize and sync all player identity systems
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // Get device ID first
      _deviceId = prefs.getString(_keyDeviceId) ?? await _getDeviceId();
      await prefs.setString(_keyDeviceId, _deviceId);

      // Check if this is a first-time user (no backend registration yet)
      final existingPlayerId = prefs.getString(_keyPlayerId);
      final isBackendRegistered = prefs.getBool(_keyBackendRegistered) ?? false;

      _isFirstTimeUser = !isBackendRegistered;
      _isBackendRegistered = isBackendRegistered;

      safePrint('🎯 DEBUG PlayerIdentityManager: deviceId = $_deviceId');
      safePrint(
        '🎯 DEBUG PlayerIdentityManager: existingPlayerId = $existingPlayerId',
      );
      safePrint(
        '🎯 DEBUG PlayerIdentityManager: isBackendRegistered = $_isBackendRegistered',
      );
      safePrint(
        '🎯 DEBUG PlayerIdentityManager: isFirstTimeUser = $_isFirstTimeUser',
      );

      // Load existing identity if backend registered
      if (_isBackendRegistered && existingPlayerId != null) {
        _playerId = existingPlayerId;
        _playerName = prefs.getString(_keyPlayerName) ?? _generateDefaultName();
        _authToken = prefs.getString(_keyAuthToken) ?? '';
      } else {
        // For first-time users, generate temporary local ID until backend registration
        _playerId = _generatePlayerId();
        _playerName = _generateDefaultName();
        _authToken = '';
      }

      // Migrate from existing systems
      await _migrateFromExistingSystems(prefs);

      // Save current identity (but don't mark as registered until backend confirms)
      await prefs.setString(_keyPlayerId, _playerId);
      await prefs.setString(_keyPlayerName, _playerName);

      _isInitialized = true;
      notifyListeners();

      safePrint(
        '🎯 PlayerIdentityManager initialized: $_playerName ($_playerId) - Device: $_deviceId - First time: $_isFirstTimeUser',
      );
    } catch (e) {
      safePrint('⚠️ Failed to initialize PlayerIdentityManager: $e');
      _isInitialized = true;
    }
  }

  /// Mark player as registered with backend
  Future<void> markBackendRegistered(
    String backendPlayerId,
    String playerName, [
    String? authToken,
  ]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyBackendRegistered, true);
      await prefs.setString(_keyPlayerId, backendPlayerId);
      await prefs.setString(_keyPlayerName, playerName);

      if (authToken != null) {
        await prefs.setString(_keyAuthToken, authToken);
        _authToken = authToken;
      }

      _isBackendRegistered = true;
      _playerId = backendPlayerId;
      _playerName = playerName;

      notifyListeners();

      safePrint(
        '🎯 Player marked as backend registered: $backendPlayerId ($playerName)',
      );
    } catch (e) {
      safePrint('⚠️ Failed to mark backend registered: $e');
    }
  }

  /// Update auth token (for token refresh)
  Future<void> updateAuthToken(String newToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyAuthToken, newToken);
      _authToken = newToken;

      notifyListeners();

      safePrint('🎯 Auth token updated successfully');
    } catch (e) {
      safePrint('⚠️ Failed to update auth token: $e');
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

      // 🚂 CRITICAL: Sync nickname to Railway backend
      try {
        final railwayManager = RailwayServerManager();
        if (railwayManager.isAuthenticated) {
          final success = await railwayManager.updatePlayerProfile(nickname: _playerName);
          if (success) {
            safePrint('🚂 ✅ Nickname synced to Railway backend: $_playerName');
          } else {
            safePrint('🚂 ⚠️ Nickname sync failed, added to offline queue for retry');
          }
        } else {
          safePrint('🚂 ⚠️ Cannot sync nickname - not authenticated with Railway (will retry when online)');
          // Still add to offline queue for when authentication is restored
          railwayManager.updatePlayerProfile(nickname: _playerName);
        }
      } catch (e) {
        safePrint('🚂 ❌ Failed to sync nickname to Railway backend: $e');
      }

      // 🎯 IMPORTANT: Track nickname change for missions/achievements
      try {
        final gameEventsTracker = GameEventsTracker();
        await gameEventsTracker.onNicknameChanged(_playerName);
        safePrint('🎯 Nickname change tracked for missions/achievements');
      } catch (e) {
        safePrint('⚠️ Failed to track nickname change event: $e');
      }

      notifyListeners();
      safePrint('🎯 Player name updated: $oldName → $_playerName');
    } catch (e) {
      safePrint('⚠️ Failed to update player name: $e');
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
      if (leaderboardManager.isInitialized &&
          leaderboardManager.playerName != _playerName) {
        await leaderboardManager.updatePlayerName(_playerName);
      }

      final globalService = GlobalLeaderboardService();
      if (globalService.isInitialized &&
          globalService.playerName != _playerName) {
        await globalService.registerPlayer(playerName: _playerName);
      }
    } catch (e) {
      safePrint('⚠️ Failed to sync to all systems: $e');
    }
  }

  /// Migrate data from existing fragmented systems
  Future<void> _migrateFromExistingSystems(SharedPreferences prefs) async {
    // Priority order for name migration
    final sources = [
      'profile_nickname', // ProfileManager (fixed key)
      'pf_nickname', // Old ProfileManager key
      'player_name', // LeaderboardManager
      'global_player_name', // GlobalLeaderboardService
    ];

    for (final key in sources) {
      final name = prefs.getString(key);
      if (name != null &&
          name.isNotEmpty &&
          name != 'You' &&
          name != 'Anonymous') {
        _playerName = name;
        safePrint('🎯 Migrated player name from $key: $_playerName');
        break;
      }
    }

    // Generate default if no valid name found
    if (_playerName.isEmpty) {
      _playerName = _generateDefaultName();
      safePrint('🎯 Generated default player name: $_playerName');
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

    safePrint(
      '🎯 PlayerIdentityManager force reset: $_playerName ($_playerId)',
    );
  }
}

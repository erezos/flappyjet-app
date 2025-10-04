/// 🎭 Anonymous Identity Manager - Instant App Startup
/// Provides immediate local identity without network dependency
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/debug_logger.dart';
import '../../core/identity/unified_id_manager.dart';
import 'player_identity_manager.dart';

enum IdentityState {
  anonymous,      // Local-only identity
  connecting,     // Attempting cloud connection
  connected,      // Successfully connected to cloud
  failed,         // Connection failed, staying anonymous
}

/// Anonymous Identity Manager - Instant startup with optional cloud connection
class AnonymousIdentityManager extends ChangeNotifier {
  static final AnonymousIdentityManager _instance = AnonymousIdentityManager._internal();
  factory AnonymousIdentityManager() => _instance;
  AnonymousIdentityManager._internal();

  // Dependencies
  final UnifiedIdManager _idManager = UnifiedIdManager();

  // Storage keys
  static const String _keyAnonymousId = 'anonymous_id';
  static const String _keyPlayerName = 'anonymous_player_name';
  static const String _keyCloudPlayerId = 'cloud_player_id';
  static const String _keyAuthToken = 'auth_token';
  static const String _keyIdentityState = 'identity_state';
  static const String _keyLastCloudSync = 'last_cloud_sync';

  // Core Identity (Always Available)
  String _anonymousId = '';
  String _playerName = '';
  IdentityState _state = IdentityState.anonymous;
  
  // Cloud Identity (Optional)
  String _cloudPlayerId = '';
  String _authToken = '';
  DateTime? _lastCloudSync;
  
  // Status
  bool _isInitialized = false;
  bool _isConnecting = false;

  // Getters - Always available
  String get playerId => _cloudPlayerId.isNotEmpty ? _cloudPlayerId : _anonymousId;
  String get anonymousId => _anonymousId;
  String get playerName => _playerName;
  IdentityState get state => _state;
  bool get isInitialized => _isInitialized;
  bool get isConnecting => _isConnecting;
  bool get isConnectedToCloud => _state == IdentityState.connected;
  bool get hasCloudAccount => _cloudPlayerId.isNotEmpty;
  String get authToken => _authToken;
  DateTime? get lastCloudSync => _lastCloudSync;

  /// INSTANT initialization - No network calls, always succeeds
  Future<void> initializeInstant() async {
    if (_isInitialized) return;

    try {
      // Initialize unified ID manager first
      await _idManager.initialize();
      
      final prefs = await SharedPreferences.getInstance();
      
      // Load or generate anonymous identity using unified ID manager
      _anonymousId = prefs.getString(_keyAnonymousId) ?? _idManager.generateAnonymousId();
      await prefs.setString(_keyAnonymousId, _anonymousId);
      
      // Load or generate player name
      _playerName = prefs.getString(_keyPlayerName) ?? _generateAnonymousName();
      await prefs.setString(_keyPlayerName, _playerName);
      
      // Load cloud identity if exists
      _cloudPlayerId = prefs.getString(_keyCloudPlayerId) ?? '';
      _authToken = prefs.getString(_keyAuthToken) ?? '';
      
      // Load state
      final stateIndex = prefs.getInt(_keyIdentityState) ?? 0;
      _state = IdentityState.values[stateIndex];
      
      // Load last sync time
      final lastSyncMs = prefs.getInt(_keyLastCloudSync);
      if (lastSyncMs != null) {
        _lastCloudSync = DateTime.fromMillisecondsSinceEpoch(lastSyncMs);
      }
      
      // If we had cloud connection but no valid token, revert to anonymous
      if (_state == IdentityState.connected && _authToken.isEmpty) {
        _state = IdentityState.anonymous;
        await _saveState();
      }

      _isInitialized = true;
      
      safePrint('🎭 ✅ Anonymous Identity initialized instantly');
      safePrint('🎭 Anonymous ID: ${_anonymousId.substring(0, 8)}...');
      safePrint('🎭 Player Name: $_playerName');
      safePrint('🎭 State: $_state');
      
      notifyListeners();
      
    } catch (e) {
      safePrint('🎭 ❌ Failed to initialize anonymous identity: $e');
      // Even if loading fails, create minimal identity using unified ID manager
      _anonymousId = _idManager.generateAnonymousId();
      _playerName = _generateAnonymousName();
      _state = IdentityState.anonymous;
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// ASYNC cloud connection - Non-blocking, happens in background
  Future<bool> connectToCloudAsync({String? customNickname}) async {
    if (_isConnecting) return false;
    
    _isConnecting = true;
    _state = IdentityState.connecting;
    notifyListeners();
    
    try {
      safePrint('🎭 🌐 Attempting cloud connection...');
      
      // Use custom nickname if provided, otherwise use current name
      final nickname = customNickname ?? _playerName;
      
      // Try to connect to backend (non-blocking)
      final success = await _attemptCloudConnection(nickname);
      
      if (success) {
        _state = IdentityState.connected;
        _lastCloudSync = DateTime.now();
        await _saveState();
        
        safePrint('🎭 ✅ Cloud connection successful');
        safePrint('🎭 Cloud Player ID: ${_cloudPlayerId.substring(0, 8)}...');
      } else {
        _state = IdentityState.failed;
        await _saveState();
        
        safePrint('🎭 ⚠️ Cloud connection failed, staying anonymous');
      }
      
      _isConnecting = false;
      notifyListeners();
      return success;
      
    } catch (e) {
      safePrint('🎭 ❌ Cloud connection error: $e');
      _state = IdentityState.failed;
      _isConnecting = false;
      await _saveState();
      notifyListeners();
      return false;
    }
  }

  /// Disconnect from cloud - revert to anonymous
  Future<void> disconnectFromCloud() async {
    _cloudPlayerId = '';
    _authToken = '';
    _state = IdentityState.anonymous;
    _lastCloudSync = null;
    
    await _clearCloudData();
    await _saveState();
    
    safePrint('🎭 📱 Disconnected from cloud, reverted to anonymous');
    notifyListeners();
  }

  /// Update player name (works in both anonymous and connected modes)
  Future<void> updatePlayerName(String newName) async {
    if (newName.trim().isEmpty) return;
    
    _playerName = newName.trim();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPlayerName, _playerName);
    
    // If connected to cloud, sync the name change
    if (_state == IdentityState.connected) {
      // Queue name update for cloud sync (non-blocking)
      _syncNameToCloud(newName);
    }
    
    notifyListeners();
  }

  /// Get master ID for data recovery
  Future<String> getMasterId() async {
    return await _idManager.getMasterId();
  }

  /// Get device ID for analytics
  Future<String> getDeviceId() async {
    return await _idManager.getDeviceId();
  }

  /// Generate anonymous player name using unified approach
  String _generateAnonymousName() {
    // Use same format as PlayerIdentityManager for consistency: Pilot####
    final random = DateTime.now().millisecondsSinceEpoch % 9000;
    final num = 1000 + random;
    return 'Pilot$num';
  }

  /// Attempt cloud connection (actual network call)
  Future<bool> _attemptCloudConnection(String nickname) async {
    try {
      // Use existing PlayerIdentityManager for actual auth
      final playerIdentity = PlayerIdentityManager();
      final authResult = await playerIdentity.authenticatePlayer(nickname);
      
      if (authResult) {
        _cloudPlayerId = playerIdentity.playerId;
        _authToken = playerIdentity.authToken;
        return true;
      }
      
      return false;
    } catch (e) {
      safePrint('🎭 ❌ Cloud connection attempt failed: $e');
      return false;
    }
  }

  /// Sync name change to cloud (non-blocking)
  Future<void> _syncNameToCloud(String newName) async {
    try {
      // Queue this for background sync - don't block UI
      // Implementation would use NetworkManager to queue the request
      safePrint('🎭 🌐 Queuing name sync to cloud: $newName');
    } catch (e) {
      safePrint('🎭 ⚠️ Failed to sync name to cloud: $e');
    }
  }

  /// Save current state to storage
  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString(_keyCloudPlayerId, _cloudPlayerId);
      await prefs.setString(_keyAuthToken, _authToken);
      await prefs.setInt(_keyIdentityState, _state.index);
      
      if (_lastCloudSync != null) {
        await prefs.setInt(_keyLastCloudSync, _lastCloudSync!.millisecondsSinceEpoch);
      }
      
    } catch (e) {
      safePrint('🎭 ⚠️ Failed to save state: $e');
    }
  }

  /// Clear cloud data from storage
  Future<void> _clearCloudData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.remove(_keyCloudPlayerId);
      await prefs.remove(_keyAuthToken);
      await prefs.remove(_keyLastCloudSync);
      
    } catch (e) {
      safePrint('🎭 ⚠️ Failed to clear cloud data: $e');
    }
  }

  /// Check if feature requires cloud connection
  bool requiresCloudConnection(String feature) {
    switch (feature) {
      case 'leaderboard':
      case 'tournaments':
      case 'cloud_save':
      case 'cross_device_sync':
        return true;
      case 'gameplay':
      case 'local_progress':
      case 'skins':
      case 'achievements':
      case 'missions':
        return false;
      default:
        return false;
    }
  }

  /// Get connection prompt message for feature
  String getConnectionPromptMessage(String feature) {
    switch (feature) {
      case 'leaderboard':
        return 'Connect to see global leaderboards and compete with other players!';
      case 'tournaments':
        return 'Connect to join tournaments and win exclusive rewards!';
      case 'cloud_save':
        return 'Connect to save your progress to the cloud and play on multiple devices!';
      default:
        return 'Connect to unlock online features!';
    }
  }
}

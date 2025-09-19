/// 🎯 Player Identity Manager - Single source of truth for player identity
library;
import '../../core/debug_logger.dart';

import 'dart:convert';
import 'dart:math' as math;
import 'dart:io' show Platform;
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/user_restoration_service.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_app_installations/firebase_app_installations.dart';
import 'package:http/http.dart' as http;
import 'profile_manager.dart';
import 'leaderboard_manager.dart';
import 'global_leaderboard_service.dart';
import 'game_events_tracker.dart';
// Removed auth_manager import - functionality moved here
import '../../core/network/network_manager.dart';
import '../../services/nickname_validation_service.dart';
// Removed railway_leaderboard_service import - consumers will initialize as needed

/// Authentication states for reactive UI updates
enum AuthState {
  unauthenticated,
  authenticating,
  authenticated,
  tokenExpired,
  error,
}

/// Registration data for new players
class PlayerRegistration {
  final String deviceId;
  final String nickname;
  final String platform;
  final String appVersion;
  final String? countryCode;
  final String? timezone;

  PlayerRegistration({
    required this.deviceId,
    required this.nickname,
    required this.platform,
    required this.appVersion,
    this.countryCode,
    this.timezone,
  });

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'nickname': nickname,
    'platform': platform,
    'appVersion': appVersion,
    'countryCode': countryCode,
    'timezone': timezone,
  };
}

/// Centralized player identity management
/// Ensures all systems use consistent player names and IDs
class PlayerIdentityManager extends ChangeNotifier {
  static final PlayerIdentityManager _instance =
      PlayerIdentityManager._internal();
  factory PlayerIdentityManager() => _instance;
  PlayerIdentityManager._internal();

  // Configuration
  static const String baseUrl = 'https://flappyjet-backend-production.up.railway.app';
  static const Duration requestTimeout = Duration(seconds: 15);
  static const Duration tokenRefreshBuffer = Duration(minutes: 5);

  // Storage keys
  static const String _keyPlayerName = 'unified_player_name';
  static const String _keyPlayerId = 'unified_player_id';
  static const String _keyDeviceId = 'device_id';
  static const String _keyBackendRegistered = 'backend_registered';
  static const String _keyAuthToken = 'auth_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyTokenExpiry = 'token_expiry';
  static const String _keyPlayerData = 'player_data';

  // Core Identity
  String _playerName = '';
  String _playerId = '';
  String _deviceId = '';
  
  // Authentication
  String _authToken = '';
  String _refreshToken = '';
  DateTime? _tokenExpiry;
  Map<String, dynamic> _playerData = {};
  AuthState _authState = AuthState.unauthenticated;
  
  // Status
  bool _isInitialized = false;
  bool _isFirstTimeUser = true;
  bool _isBackendRegistered = false;
  
  // HTTP client
  final http.Client _httpClient = http.Client();

  // Core Identity Getters
  String get playerName => _playerName;
  String get playerId => _playerId;
  String get deviceId => _deviceId;
  
  // Authentication Getters
  String get authToken => _authToken;
  String get refreshToken => _refreshToken;
  DateTime? get tokenExpiry => _tokenExpiry;
  Map<String, dynamic> get playerData => Map.unmodifiable(_playerData);
  AuthState get authState => _authState;
  
  // Status Getters
  bool get isInitialized => _isInitialized;
  bool get isFirstTimeUser => _isFirstTimeUser;
  bool get isBackendRegistered => _isBackendRegistered;
  bool get isAuthenticated => _authState == AuthState.authenticated && _authToken.isNotEmpty;
  bool get isTokenExpired => _tokenExpiry != null && DateTime.now().isAfter(_tokenExpiry!);
  bool get needsTokenRefresh => _tokenExpiry != null && DateTime.now().isAfter(_tokenExpiry!.subtract(tokenRefreshBuffer));

  /// Get device ID for backend registration with backward compatibility
  Future<String> _getDeviceId() async {
    // STEP 0: Check if we already have a stored device ID from previous session
    final prefs = await SharedPreferences.getInstance();
    final storedDeviceId = prefs.getString(_keyDeviceId);
    
    if (storedDeviceId != null && storedDeviceId.isNotEmpty) {
      safePrint('🔐 ✅ Using previously stored device ID: ${storedDeviceId.substring(0, 10)}...');
      return storedDeviceId;
    }
    
    // STEP 1: Try original method first (for first-time existing players)
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        final androidId = androidInfo.id;
        if (androidId.isNotEmpty) {
          safePrint('🔐 ✅ Using original Android ID for existing player');
          // Store it for future use
          await prefs.setString(_keyDeviceId, androidId);
          return androidId;
        }
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        final idfv = iosInfo.identifierForVendor;
        if (idfv != null && idfv.isNotEmpty) {
          safePrint('🔐 ✅ Using original iOS IDFV for existing player');
          // Store it for future use
          await prefs.setString(_keyDeviceId, idfv);
          return idfv;
        }
      }
    } catch (e) {
      safePrint('🔐 ⚠️ Original device ID method failed: $e');
    }
    
    // STEP 2: Firebase Installation ID (for new players)
    try {
      final installationId = await FirebaseInstallations.instance.getId();
      if (installationId.isNotEmpty) {
        final deviceId = 'fid_$installationId';
        safePrint('🔐 ✅ Using Firebase Installation ID for new player');
        // Store it for future use
        await prefs.setString(_keyDeviceId, deviceId);
        return deviceId;
      }
    } catch (e) {
      safePrint('🔐 ⚠️ Firebase Installation ID failed: $e');
    }
    
    // STEP 3: Enhanced fallback
    final fallbackId = _generateEnhancedFallbackDeviceId();
    await prefs.setString(_keyDeviceId, fallbackId);
    return fallbackId;
  }


  String _generateEnhancedFallbackDeviceId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = math.Random().nextInt(999999).toString().padLeft(6, '0');
    safePrint('🔐 ⚠️ Using enhanced fallback device ID');
    return 'uuid_${timestamp}_$random';
  }

  /// Set authentication state and notify listeners
  void _setAuthState(AuthState newState) {
    if (_authState != newState) {
      _authState = newState;
      notifyListeners();
    }
  }

  /// Register new player or login existing player
  Future<bool> authenticatePlayer(String nickname) async {
    // Device ID is now ALWAYS available with our enhanced system
    _setAuthState(AuthState.authenticating);

    try {
      // Try login first (for existing players)
      final loginResult = await _attemptLogin();
      if (loginResult) {
        _setAuthState(AuthState.authenticated);
        return true;
      }

      // If login fails, try registration
      final registrationData = PlayerRegistration(
        deviceId: _deviceId,
        nickname: nickname,
        platform: _getPlatformString(),
        appVersion: await _getAppVersion(),
        countryCode: await _getCountryCode(),
        timezone: DateTime.now().timeZoneName,
      );

      final registerResult = await _attemptRegistration(registrationData);
      if (registerResult) {
        _setAuthState(AuthState.authenticated);
        return true;
      }

      _setAuthState(AuthState.error);
      return false;
    } catch (e) {
      safePrint('🔐 ❌ Authentication error: $e');
      _setAuthState(AuthState.error);
      return false;
    }
  }

  /// Attempt login with existing device
  Future<bool> _attemptLogin() async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: _getHeaders(),
        body: jsonEncode({
          'deviceId': _deviceId,
          'platform': _getPlatformString(),
          'appVersion': await _getAppVersion(),
        }),
      ).timeout(requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          await _handleAuthSuccess(data);
          safePrint('🔐 ✅ Login successful');
          return true;
        }
      }
      
      safePrint('🔐 ℹ️ Login failed - player not found (will try registration)');
      return false;
    } catch (e) {
      safePrint('🔐 ⚠️ Login request failed: $e');
      return false;
    }
  }

  /// Attempt registration for new player
  Future<bool> _attemptRegistration(PlayerRegistration registration) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: _getHeaders(),
        body: jsonEncode(registration.toJson()),
      ).timeout(requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          await _handleAuthSuccess(data);
          safePrint('🔐 ✅ Registration successful');
          return true;
        }
      }

      safePrint('🔐 ❌ Registration failed: ${response.body}');
      return false;
    } catch (e) {
      safePrint('🔐 ❌ Registration request failed: $e');
      return false;
    }
  }

  /// Handle successful authentication response
  Future<void> _handleAuthSuccess(Map<String, dynamic> data) async {
    final token = data['token'];
    final player = data['player'];
    
    // Parse token to get expiry (JWT tokens contain expiry in payload)
    final tokenExpiry = _parseTokenExpiry(token) ?? DateTime.now().add(Duration(days: 30));
    
    _authToken = token;
    _refreshToken = token; // In this implementation, same token is used for refresh
    _tokenExpiry = tokenExpiry;
    _playerData = Map<String, dynamic>.from(player);
    
    // Update player identity from backend
    _playerId = player['id'];
    _playerName = player['nickname'];
    _isBackendRegistered = true;

    await _saveAuthData();
    await _savePlayerData();
    
    // Trigger user state restoration after successful authentication
    _triggerUserStateRestoration();
  }

  /// Parse JWT token to extract expiry date
  DateTime? _parseTokenExpiry(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final data = jsonDecode(decoded);
      
      final exp = data['exp'];
      if (exp != null) {
        return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      }
    } catch (e) {
      safePrint('🔐 ⚠️ Failed to parse token expiry: $e');
    }
    return null;
  }

  /// Refresh expired token
  Future<bool> _refreshAuthToken() async {
    if (_refreshToken.isEmpty) return false;

    try {
      final response = await _httpClient.post(
        Uri.parse('$baseUrl/api/auth/refresh'),
        headers: _getHeaders(),
        body: jsonEncode({
          'refreshToken': _refreshToken,
        }),
      ).timeout(requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          await _handleAuthSuccess(data);
          safePrint('🔐 ✅ Token refreshed successfully');
          return true;
        }
      }

      safePrint('🔐 ❌ Token refresh failed');
      return false;
    } catch (e) {
      safePrint('🔐 ❌ Token refresh error: $e');
      return false;
    }
  }

  /// Validate current token with server
  Future<bool> _validateToken() async {
    if (_authToken.isEmpty) return false;

    try {
      final response = await _httpClient.get(
        Uri.parse('$baseUrl/api/auth/profile'),
        headers: _getAuthHeaders(),
      ).timeout(requestTimeout);

      return response.statusCode == 200;
    } catch (e) {
      safePrint('🔐 ⚠️ Token validation failed: $e');
      return false;
    }
  }

  /// Proactively refresh token if needed
  Future<void> ensureValidToken() async {
    if (needsTokenRefresh) {
      await _refreshAuthToken();
    }
  }

  /// Save authentication data to storage
  Future<void> _saveAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyAuthToken, _authToken);
      await prefs.setString(_keyRefreshToken, _refreshToken);
      if (_tokenExpiry != null) {
        await prefs.setInt(_keyTokenExpiry, _tokenExpiry!.millisecondsSinceEpoch);
      }
      await prefs.setString(_keyPlayerData, jsonEncode(_playerData));
    } catch (e) {
      safePrint('🔐 ⚠️ Failed to save auth data: $e');
    }
  }

  /// Load stored authentication data
  Future<void> _loadAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString(_keyAuthToken) ?? '';
      _refreshToken = prefs.getString(_keyRefreshToken) ?? '';
      final expiryMs = prefs.getInt(_keyTokenExpiry);
      if (expiryMs != null) {
        _tokenExpiry = DateTime.fromMillisecondsSinceEpoch(expiryMs);
      }
      final playerDataJson = prefs.getString(_keyPlayerData);
      if (playerDataJson != null) {
        _playerData = Map<String, dynamic>.from(jsonDecode(playerDataJson));
      }
    } catch (e) {
      safePrint('🔐 ⚠️ Failed to load auth data: $e');
      await _clearAuthData();
    }
  }

  /// Clear all authentication data
  Future<void> _clearAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyAuthToken);
      await prefs.remove(_keyRefreshToken);
      await prefs.remove(_keyTokenExpiry);
      await prefs.remove(_keyPlayerData);
      _authToken = '';
      _refreshToken = '';
      _tokenExpiry = null;
      _playerData.clear();
    } catch (e) {
      safePrint('🔐 ⚠️ Failed to clear auth data: $e');
    }
  }

  /// Logout current player
  Future<void> logout() async {
    await _clearAuthData();
    _setAuthState(AuthState.unauthenticated);
    _isBackendRegistered = false;
    safePrint('🔐 ✅ Player logged out');
  }

  /// Get standard HTTP headers
  Map<String, String> _getHeaders() => {
    'Content-Type': 'application/json',
    'User-Agent': 'FlappyJet/${_getAppVersion()}',
  };

  /// Get authenticated HTTP headers
  Map<String, String> _getAuthHeaders() => {
    ..._getHeaders(),
    'Authorization': 'Bearer $_authToken',
  };

  /// Get platform string
  String _getPlatformString() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }

  /// Get app version
  Future<String> _getAppVersion() async {
    // This should be loaded from package_info_plus
    return '1.4.6';
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
          safePrint('🌍 Detected country code from locale: $countryCode');
          return countryCode;
        }
      }
      
      // Final fallback
      safePrint('🌍 ⚠️ Could not detect country code, using default: US');
      return 'US';
    } catch (e) {
      safePrint('🌍 ❌ Error detecting country code: $e, using default: US');
      return 'US';
    }
  }

  /// Trigger user state restoration in background (non-blocking)
  void _triggerUserStateRestoration() {
    // Run restoration in background to avoid blocking authentication flow
    Future.delayed(Duration(milliseconds: 500), () async {
      try {
        final restorationService = UserRestorationService();
        await restorationService.restoreUserState();
      } catch (e) {
        safePrint('🔄 ⚠️ Failed to run user restoration service: $e');
      }
    });
  }

  /// Save player data to storage
  Future<void> _savePlayerData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyPlayerId, _playerId);
      await prefs.setString(_keyPlayerName, _playerName);
      await prefs.setBool(_keyBackendRegistered, _isBackendRegistered);
    } catch (e) {
      safePrint('🔐 ⚠️ Failed to save player data: $e');
    }
  }

  /// Initialize and sync all player identity systems
  Future<void> initialize() async {
    if (_isInitialized) return;

    _setAuthState(AuthState.authenticating);

    try {
      final prefs = await SharedPreferences.getInstance();

      // Get device ID with enhanced backward compatibility
      _deviceId = await _getDeviceId(); // This now handles storage internally

      // Load authentication data
      await _loadAuthData();

      // Check if this is a first-time user (no backend registration yet)
      final existingPlayerId = prefs.getString(_keyPlayerId);
      final isBackendRegisteredFromPrefs = prefs.getBool(_keyBackendRegistered) ?? false;

      _isFirstTimeUser = !isBackendRegisteredFromPrefs;
      _isBackendRegistered = isBackendRegisteredFromPrefs;

      safePrint('🎯 DEBUG PlayerIdentityManager: deviceId = $_deviceId');
      safePrint(
        '🎯 DEBUG PlayerIdentityManager: existingPlayerId = $existingPlayerId',
      );
      safePrint(
        '🎯 DEBUG PlayerIdentityManager: _isBackendRegistered = $_isBackendRegistered',
      );
      safePrint(
        '🎯 DEBUG PlayerIdentityManager: isFirstTimeUser = $_isFirstTimeUser',
      );

      // Load existing identity if backend registered
      if (_isBackendRegistered && existingPlayerId != null) {
        _playerId = existingPlayerId;
        _playerName = prefs.getString(_keyPlayerName) ?? _generateDefaultName();
        
        // Validate existing token if available
        if (_authToken.isNotEmpty) {
          if (isTokenExpired) {
            safePrint('🔐 Token expired, attempting refresh...');
            final refreshed = await _refreshAuthToken();
            if (!refreshed) {
              await _clearAuthData();
              _setAuthState(AuthState.tokenExpired);
            } else {
              _setAuthState(AuthState.authenticated);
            }
          } else {
            // Validate token with server
            final isValid = await _validateToken();
            if (isValid) {
              _setAuthState(AuthState.authenticated);
              safePrint('🔐 ✅ Authentication restored from storage');
              
              // Trigger user state restoration after successful authentication
              _triggerUserStateRestoration();
            } else {
              await _clearAuthData();
              _setAuthState(AuthState.unauthenticated);
            }
          }
        } else {
          _setAuthState(AuthState.unauthenticated);
        }
      } else {
        // For first-time users, generate temporary local ID until backend registration
        _playerId = _generatePlayerId();
        _playerName = _generateDefaultName();
        _setAuthState(AuthState.unauthenticated);
      }

      // Migrate from existing systems
      await _migrateFromExistingSystems(prefs);

      // Save current identity (but don't mark as registered until backend confirms)
      await _savePlayerData();

      // Railway leaderboard service will be initialized by consumers as needed

      _isInitialized = true;
      notifyListeners();

      safePrint(
        '🎯 PlayerIdentityManager initialized: $_playerName ($_playerId) - Device: $_deviceId - First time: $_isFirstTimeUser - Auth: $_authState',
      );
    } catch (e) {
      safePrint('⚠️ Failed to initialize PlayerIdentityManager: $e');
      _setAuthState(AuthState.error);
      _isInitialized = true;
    }
  }

  /// Mark player as registered with backend
  Future<void> markBackendRegistered(
    String backendPlayerId,
    String _playerName, [
    String? _authToken,
  ]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyBackendRegistered, true);
      await prefs.setString(_keyPlayerId, backendPlayerId);
      await prefs.setString(_keyPlayerName, _playerName);

      if (_authToken != null) {
        await prefs.setString(_keyAuthToken, _authToken);
        _authToken = _authToken;
      }

      _isBackendRegistered = true;
      _playerId = backendPlayerId;
      _playerName = _playerName;

      notifyListeners();

      safePrint(
        '🎯 Player marked as backend registered: $backendPlayerId ($_playerName)',
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

  /// Update player name across all systems with validation
  Future<void> updatePlayerName(String newName) async {
    if (newName.trim().isEmpty || newName.trim() == _playerName) return;

    // 🛡️ CRITICAL: Validate nickname before updating
    final validationResult = await _validateNickname(newName.trim());
    if (!validationResult.isValid) {
      throw Exception('Nickname validation failed: ${validationResult.errorMessage}');
    }

    final oldName = _playerName;
    _playerName = validationResult.cleanedNickname;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyPlayerName, _playerName);

      // Update all dependent systems
      await _syncToAllSystems();

      // 🚂 CRITICAL: Sync nickname to Railway backend using PlayerAuthService
      bool backendSyncSuccess = false;
      try {
        if (_isBackendRegistered && _authToken.isNotEmpty) {
          // Use new unified system for proper API communication
          final networkManager = NetworkManager();
          
          final updateResult = await networkManager.updatePlayerProfile({
            'nickname': _playerName,
          });
          
          if (updateResult.success) {
            safePrint('🚂 ✅ Nickname synced to Railway backend: $_playerName');
            backendSyncSuccess = true;
          } else {
            safePrint('🚂 ⚠️ Nickname sync failed: ${updateResult.error}');
            
            // If token expired, try to refresh and retry
            if (updateResult.error?.contains('expired') == true || 
                updateResult.error?.contains('Invalid') == true) {
              safePrint('🚂 🔄 Token expired, attempting refresh...');
              
              // Use internal token refresh
              await ensureValidToken();
              // Retry the update after token refresh
              final retryResult = await networkManager.updatePlayerProfile({
                'nickname': _playerName,
              });
              
              if (retryResult.success) {
                safePrint('🚂 ✅ Nickname sync successful after token refresh');
                backendSyncSuccess = true;
              } else {
                safePrint('🚂 ❌ Nickname sync failed even after token refresh: ${retryResult.error}');
              }
            }
          }
        } else {
          safePrint('🚂 ⚠️ Cannot sync nickname - not authenticated with backend');
        }
      } catch (e) {
        safePrint('🚂 ❌ Failed to sync nickname to Railway backend: $e');
      }

      // 🚨 CRITICAL: Warn user if backend sync failed
      if (!backendSyncSuccess) {
        safePrint('🚨 WARNING: Nickname updated locally but backend sync failed!');
        safePrint('🚨 Tournament scores may show old nickname until sync succeeds');
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

  /// Force immediate nickname sync to backend (for critical operations like tournaments)
  Future<bool> forceNicknameSyncToBackend() async {
    try {
      if (!_isBackendRegistered) {
        safePrint('🚂 ❌ Cannot force sync - not registered with backend');
        return false;
      }

      // Use new unified system for proper API communication
      final networkManager = NetworkManager();
      
      // First try with current token
      if (_authToken.isNotEmpty) {
        final updateResult = await networkManager.updatePlayerProfile({
          'nickname': _playerName,
        });
        
        if (updateResult.success) {
          safePrint('🚂 ✅ Force nickname sync successful: $_playerName');
          return true;
        }
        
        // If token expired, try to refresh
        if (updateResult.error?.contains('expired') == true || 
            updateResult.error?.contains('Invalid') == true) {
          safePrint('🚂 🔄 Force nickname sync: re-authenticating...');
          
          // Try to refresh token
          await ensureValidToken();
          
          // Retry with refreshed token
          final retryResult = await networkManager.updatePlayerProfile({
            'nickname': _playerName,
          });
          
          if (retryResult.success) {
            safePrint('🚂 ✅ Force nickname sync successful after token refresh: $_playerName');
            return true;
          } else {
            safePrint('🚂 ❌ Force nickname sync failed even after token refresh');
            return false;
          }
        } else {
          safePrint('🚂 ❌ Force nickname sync failed');
          return false;
        }
      } else {
        safePrint('🚂 ❌ No auth token available for force sync');
        return false;
      }
    } catch (e) {
      safePrint('🚂 ❌ Force nickname sync error: $e');
      return false;
    }
  }

  /// Sync identity to all dependent systems
  Future<void> _syncToAllSystems() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Update ProfileManager storage
      await prefs.setString('profile_nickname', _playerName);

      // Update LeaderboardManager storage
      await prefs.setString(_keyPlayerName, _playerName);

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
      _keyPlayerName, // LeaderboardManager
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
    // Generate a proper UUID for backend compatibility
    const uuid = Uuid();
    return uuid.v4();
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

  @override
  void dispose() {
    _httpClient.close();
    super.dispose();
  }

  /// 🛡️ Validate nickname using comprehensive validation service
  Future<NicknameValidationResult> _validateNickname(String nickname) async {
    try {
      // Use server-side validation if authenticated, otherwise client-side
      if (_isBackendRegistered && _authToken.isNotEmpty) {
        return await NicknameValidationService.validateNicknameWithServer(
          nickname,
          authToken: _authToken,
        );
      } else {
        // Fallback to client-side validation
        return NicknameValidationService.validateNickname(nickname);
      }
    } catch (e) {
      safePrint('🛡️ ❌ Nickname validation error: $e');
      // Return client-side validation as fallback
      return NicknameValidationService.validateNickname(nickname);
    }
  }
}

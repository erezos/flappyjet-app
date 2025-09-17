/// 🚂 Railway Server Manager - Production backend integration for FlappyJet Pro
library;
import '../../core/debug_logger.dart';

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../services/player_auth_service.dart';
import 'player_identity_manager.dart';

/// Server configuration for Railway backend
class RailwayConfig {
  // 🚂 Railway Backend URL (replace with your actual Railway deployment URL)
  static const String baseUrl = 'https://flappyjet-backend-production.up.railway.app';  // Always use production
  
  // Alternative: Use localhost only when explicitly needed
  // static const String baseUrl = kDebugMode 
  //     ? 'http://localhost:3000'  // Local development
  //     : 'https://flappyjet-backend-production.up.railway.app';  // Production
  
  // API Endpoints
  static const String authRegister = '$baseUrl/api/auth/register';
  static const String authLogin = '$baseUrl/api/auth/login';
  static const String authRefresh = '$baseUrl/api/auth/refresh';
  static const String authProfile = '$baseUrl/api/auth/profile';
  
  static const String leaderboardSubmit = '$baseUrl/api/leaderboard/submit';
  static const String leaderboardGlobal = '$baseUrl/api/leaderboard/global';
  static const String leaderboardPlayer = '$baseUrl/api/leaderboard/player';
  
  static const String missionsDailyGet = '$baseUrl/api/missions/daily';
  static const String missionsProgress = '$baseUrl/api/missions/progress';
  static const String missionsRefresh = '$baseUrl/api/missions/refresh';
  
  static const String achievementsGet = '$baseUrl/api/achievements';
  static const String achievementsPlayer = '$baseUrl/api/achievements/player';
  
  static const String playerProfile = '$baseUrl/api/player/profile';
  static const String playerSync = '$baseUrl/api/player/sync';
  
  static const String purchaseValidate = '$baseUrl/api/purchase/validate';
  static const String analyticsEvent = '$baseUrl/api/analytics/event';
  
  static const String healthCheck = '$baseUrl/health';
  
  // Configuration
  static const Duration requestTimeout = Duration(seconds: 10);
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
}

/// Player data model for server communication
class ServerPlayerData {
  final String id;
  final String nickname;
  final int bestScore;
  final int bestStreak;
  final int totalGamesPlayed;
  final int currentCoins;
  final int currentGems;
  final int currentHearts;
  final bool isPremium;
  final DateTime? heartBoosterExpiry;
  final DateTime createdAt;
  final DateTime lastActiveAt;

  ServerPlayerData({
    required this.id,
    required this.nickname,
    required this.bestScore,
    required this.bestStreak,
    required this.totalGamesPlayed,
    required this.currentCoins,
    required this.currentGems,
    required this.currentHearts,
    required this.isPremium,
    this.heartBoosterExpiry,
    required this.createdAt,
    required this.lastActiveAt,
  });

  factory ServerPlayerData.fromJson(Map<String, dynamic> json) {
    return ServerPlayerData(
      id: json['id'],
      nickname: json['nickname'],
      bestScore: json['best_score'] ?? 0,
      bestStreak: json['best_streak'] ?? 0,
      totalGamesPlayed: json['total_games_played'] ?? 0,
      currentCoins: json['current_coins'] ?? 0,
      currentGems: json['current_gems'] ?? 0,
      currentHearts: json['current_hearts'] ?? 3,
      isPremium: json['is_premium'] ?? false,
      heartBoosterExpiry: json['heart_booster_expiry'] != null
          ? DateTime.parse(json['heart_booster_expiry'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      lastActiveAt: DateTime.parse(json['last_active_at']),
    );
  }
}

/// Leaderboard entry from server
class ServerLeaderboardEntry {
  final int rank;
  final String playerId;
  final String nickname;
  final int score;
  final String skinUsed;
  final DateTime achievedAt;
  final String? countryCode;
  final bool isCurrentPlayer;

  ServerLeaderboardEntry({
    required this.rank,
    required this.playerId,
    required this.nickname,
    required this.score,
    required this.skinUsed,
    required this.achievedAt,
    this.countryCode,
    required this.isCurrentPlayer,
  });

  factory ServerLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return ServerLeaderboardEntry(
      rank: json['rank'],
      playerId: json['player_id'],
      nickname: json['nickname'],
      score: json['score'],
      skinUsed: json['skin_used'] ?? 'sky_jet',
      achievedAt: DateTime.parse(json['achieved_at']),
      countryCode: json['country_code'],
      isCurrentPlayer: json['is_current_player'] ?? false,
    );
  }
}

/// Server mission data
class ServerMission {
  final String id;
  final String missionType;
  final String difficultyLevel;
  final String title;
  final String description;
  final int target;
  final int reward;
  final int progress;
  final bool completed;
  final DateTime? completedAt;
  final DateTime expiresAt;
  final DateTime createdAt;

  ServerMission({
    required this.id,
    required this.missionType,
    required this.difficultyLevel,
    required this.title,
    required this.description,
    required this.target,
    required this.reward,
    required this.progress,
    required this.completed,
    this.completedAt,
    required this.expiresAt,
    required this.createdAt,
  });

  factory ServerMission.fromJson(Map<String, dynamic> json) {
    return ServerMission(
      id: json['id'],
      missionType: json['mission_type'],
      difficultyLevel: json['difficulty_level'],
      title: json['title'],
      description: json['description'],
      target: json['target'],
      reward: json['reward'],
      progress: json['progress'] ?? 0,
      completed: json['completed'] ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      expiresAt: DateTime.parse(json['expires_at']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

/// Railway Server Manager - Main class for backend communication
class RailwayServerManager extends ChangeNotifier {
  static final RailwayServerManager _instance = RailwayServerManager._internal();
  factory RailwayServerManager() => _instance;
  RailwayServerManager._internal();

  static const String _keyAuthToken = 'railway_auth_token';
  static const String _keyPlayerId = 'railway_player_id';
  static const String _keyDeviceId = 'railway_device_id';
  static const String _keyLastSync = 'railway_last_sync';

  String? _authToken;
  String? _playerId;
  String? _deviceId;
  bool _isOnline = true;
  bool _isAuthenticated = false;
  DateTime? _lastSyncTime;
  final List<Map<String, dynamic>> _offlineQueue = [];

  // Getters
  bool get isOnline => _isOnline;
  bool get isAuthenticated => _isAuthenticated;
  String? get playerId => _playerId;
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Initialize the server manager
  Future<void> initialize() async {
    await _loadStoredData();
    await _generateDeviceId();
    
    // Try to authenticate if we have a token
    if (_authToken != null) {
      await _validateToken();
    }
    
    // Check server connectivity
    await _checkServerHealth();
    
    safePrint('🚂 Railway Server Manager initialized - Online: $_isOnline, Authenticated: $_isAuthenticated');
  }

  /// Load stored authentication data
  Future<void> _loadStoredData() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString(_keyAuthToken);
    _playerId = prefs.getString(_keyPlayerId);
    _deviceId = prefs.getString(_keyDeviceId);
    
    final lastSyncMs = prefs.getInt(_keyLastSync);
    if (lastSyncMs != null) {
      _lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSyncMs);
    }
  }

  /// Generate unique device ID
  Future<void> _generateDeviceId() async {
    if (_deviceId != null) return;

    try {
      final deviceInfo = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();
      
      String deviceIdentifier;
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceIdentifier = 'android_${androidInfo.id}_${packageInfo.packageName}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceIdentifier = 'ios_${iosInfo.identifierForVendor}_${packageInfo.packageName}';
      } else {
        deviceIdentifier = 'web_${DateTime.now().millisecondsSinceEpoch}_${packageInfo.packageName}';
      }

      _deviceId = deviceIdentifier;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyDeviceId, _deviceId!);
      
    } catch (e) {
      safePrint('🚂 ⚠️ Failed to generate device ID: $e');
      _deviceId = 'fallback_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Check server health
  Future<void> _checkServerHealth() async {
    try {
      final response = await http.get(
        Uri.parse(RailwayConfig.healthCheck),
        headers: _getHeaders(),
      ).timeout(RailwayConfig.requestTimeout);

      _isOnline = response.statusCode == 200;
      
      if (_isOnline) {
        final healthData = jsonDecode(response.body);
        safePrint('🚂 ✅ Server healthy: ${healthData['status']}');
      }
    } catch (e) {
      _isOnline = false;
      safePrint('🚂 ❌ Server health check failed: $e');
    }
    
    notifyListeners();
  }

  /// Validate stored authentication token
  Future<void> _validateToken() async {
    if (_authToken == null) return;

    try {
      final response = await http.get(
        Uri.parse(RailwayConfig.authProfile),
        headers: _getHeaders(includeAuth: true),
      ).timeout(RailwayConfig.requestTimeout);

      if (response.statusCode == 200) {
        _isAuthenticated = true;
        final data = jsonDecode(response.body);
        _playerId = data['player']['id'];
        safePrint('🚂 ✅ Token validated for player: $_playerId');
      } else if (response.statusCode == 403) {
        // Token expired - try to refresh
        safePrint('🚂 🔄 Token expired, attempting refresh...');
        final refreshSuccess = await _refreshAuthToken();
        if (!refreshSuccess) {
          await _clearAuthData();
          safePrint('🚂 ⚠️ Token refresh failed, cleared auth data');
        }
      } else {
        // Other error - clear auth data
        await _clearAuthData();
        safePrint('🚂 ⚠️ Token validation failed, cleared auth data');
      }
    } catch (e) {
      safePrint('🚂 ⚠️ Token validation error: $e');
    }
  }

  /// Refresh expired authentication token
  Future<bool> _refreshAuthToken() async {
    if (_authToken == null) return false;

    try {
      final playerAuthService = PlayerAuthService(baseUrl: RailwayConfig.baseUrl.replaceAll('/api', ''));
      final refreshResult = await playerAuthService.refreshToken(_authToken!);
      
      if (refreshResult.isSuccess) {
        _authToken = refreshResult.data!;
        _isAuthenticated = true;
        await _saveAuthData();
        safePrint('🚂 ✅ Token refreshed successfully');
        return true;
      } else {
        safePrint('🚂 ❌ Token refresh failed: ${refreshResult.error}');
        return false;
      }
    } catch (e) {
      safePrint('🚂 ❌ Token refresh error: $e');
      return false;
    }
  }

  /// Public method for FCM service to make authenticated requests
  Future<Map<String, dynamic>> makeAuthenticatedRequest(
    String method,
    String endpoint,
    Map<String, dynamic>? data,
  ) async {
    try {
      final url = '${RailwayConfig.baseUrl}$endpoint';
      final headers = _getHeaders(includeAuth: true);
      
      http.Response? response;
      
      switch (method.toUpperCase()) {
        case 'GET':
          response = await _makeAuthenticatedRequest(() => 
            http.get(Uri.parse(url), headers: headers).timeout(RailwayConfig.requestTimeout)
          );
          break;
        case 'POST':
          response = await _makeAuthenticatedRequest(() => 
            http.post(
              Uri.parse(url), 
              headers: headers, 
              body: data != null ? jsonEncode(data) : null
            ).timeout(RailwayConfig.requestTimeout)
          );
          break;
        case 'PUT':
          response = await _makeAuthenticatedRequest(() => 
            http.put(
              Uri.parse(url), 
              headers: headers, 
              body: data != null ? jsonEncode(data) : null
            ).timeout(RailwayConfig.requestTimeout)
          );
          break;
        case 'DELETE':
          response = await _makeAuthenticatedRequest(() => 
            http.delete(Uri.parse(url), headers: headers).timeout(RailwayConfig.requestTimeout)
          );
          break;
        default:
          return {'success': false, 'error': 'Unsupported HTTP method: $method'};
      }
      
      if (response != null) {
        final responseData = jsonDecode(response.body);
        return responseData;
      } else {
        return {'success': false, 'error': 'No response received'};
      }
    } catch (e) {
      safePrint('🚂 FCM API request failed: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Make authenticated API call with automatic token refresh
  Future<http.Response?> _makeAuthenticatedRequest(
    Future<http.Response> Function() requestFunction,
    {int maxRetries = 1}
  ) async {
    if (!_isAuthenticated) return null;

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final response = await requestFunction();
        
        if (response.statusCode == 403) {
          // Token expired - try to refresh
          safePrint('🚂 🔄 API call failed with 403, attempting token refresh (attempt ${attempt + 1}/${maxRetries + 1})');
          
          if (attempt < maxRetries) {
            final refreshSuccess = await _refreshAuthToken();
            if (refreshSuccess) {
              continue; // Retry with new token
            }
          }
          
          // Refresh failed or max retries reached
          await _clearAuthData();
          safePrint('🚂 ❌ Authentication failed, cleared auth data');
          return response;
        }
        
        return response;
      } catch (e) {
        if (attempt == maxRetries) {
          safePrint('🚂 ❌ API request failed after ${maxRetries + 1} attempts: $e');
          rethrow;
        }
      }
    }
    
    return null;
  }

  /// Register new player or login existing using PlayerAuthService
  Future<ServerPlayerData?> authenticatePlayer(String nickname) async {
    try {
      if (_deviceId == null) {
        await _generateDeviceId();
      }

      // Use PlayerAuthService for proper authentication
      final playerAuthService = PlayerAuthService(baseUrl: RailwayConfig.baseUrl.replaceAll('/api', ''));
      
      // Try login first (for existing players)
      final loginResult = await playerAuthService.loginPlayer(_deviceId!);
      
      if (loginResult.isSuccess) {
        // Login successful - update our state
        final playerIdentity = PlayerIdentityManager();
        _authToken = playerIdentity.authToken;
        _playerId = playerIdentity.playerId;
        _isAuthenticated = true;
        
        await _saveAuthData();
        
        safePrint('🚂 ✅ Player authenticated via login: $_playerId');
        
        // Get player data from backend
        final profileResult = await playerAuthService.getPlayerProfile(_authToken!);
        if (profileResult.isSuccess) {
          final profileData = profileResult.data!;
          return ServerPlayerData(
            id: profileData.playerId,
            nickname: profileData.nickname,
            bestScore: profileData.bestScore,
            bestStreak: profileData.bestStreak,
            totalGamesPlayed: profileData.totalGamesPlayed,
            currentCoins: profileData.currentCoins,
            currentGems: profileData.currentGems,
            currentHearts: profileData.currentHearts,
            isPremium: profileData.isPremium,
            createdAt: DateTime.now(), // Will be updated from backend
            lastActiveAt: DateTime.now(),
          );
        }
        
        notifyListeners();
        return null;
      } else {
        // Login failed - try registration
        safePrint('🚂 🔄 Login failed, trying registration: ${loginResult.error}');
        
        final packageInfo = await PackageInfo.fromPlatform();
        final registrationResult = await playerAuthService.registerPlayer(
          PlayerRegistrationData(
            deviceId: _deviceId!,
            nickname: nickname,
            platform: Platform.isAndroid ? 'android' : Platform.isIOS ? 'ios' : 'web',
            appVersion: packageInfo.version,
            countryCode: 'US', // Default, could be detected
            timezone: DateTime.now().timeZoneName,
          ),
        );
        
        if (registrationResult.isSuccess) {
          // Registration successful - update our state
          final playerIdentity = PlayerIdentityManager();
          _authToken = playerIdentity.authToken;
          _playerId = playerIdentity.playerId;
          _isAuthenticated = true;
          
          await _saveAuthData();
          
          safePrint('🚂 ✅ Player authenticated via registration: $_playerId');
          
          notifyListeners();
          return null; // PlayerAuthService already updated PlayerIdentityManager
        } else {
          throw Exception('Authentication failed: ${registrationResult.error}');
        }
      }
      
    } catch (e) {
      safePrint('🚂 ❌ Authentication error: $e');
      return null;
    }
  }

  /// Submit score to leaderboard
  Future<Map<String, dynamic>?> submitScore({
    required int score,
    required int survivalTime,
    required String skinUsed,
    required int coinsEarned,
    required int gemsEarned,
    required int gameDuration,
  }) async {
    if (!_isAuthenticated) {
      safePrint('🚂 ⚠️ Cannot submit score: not authenticated');
      return null;
    }

    try {
      final requestData = {
        'score': score,
        'survivalTime': survivalTime,
        'skinUsed': skinUsed,
        'coinsEarned': coinsEarned,
        'gemsEarned': gemsEarned,
        'gameDuration': gameDuration,
        'difficultyPhase': _calculateDifficultyPhase(score),
      };

      final response = await http.post(
        Uri.parse(RailwayConfig.leaderboardSubmit),
        headers: _getHeaders(includeAuth: true),
        body: jsonEncode(requestData),
      ).timeout(RailwayConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          safePrint('🚂 ✅ Score submitted: $score (Rank: ${data['rank']})');
          return data;
        }
      }
      
      throw Exception('Score submission failed: ${response.statusCode}');
      
    } catch (e) {
      safePrint('🚂 ❌ Score submission error: $e');
      
      // Add to offline queue
      _addToOfflineQueue('submitScore', {
        'score': score,
        'survivalTime': survivalTime,
        'skinUsed': skinUsed,
        'coinsEarned': coinsEarned,
        'gemsEarned': gemsEarned,
        'gameDuration': gameDuration,
      });
      
      return null;
    }
  }

  /// Get global leaderboard
  Future<List<ServerLeaderboardEntry>> getGlobalLeaderboard({
    int limit = 100,
    int offset = 0,
    String period = 'all_time',
  }) async {
    try {
      final uri = Uri.parse(RailwayConfig.leaderboardGlobal).replace(
        queryParameters: {
          'limit': limit.toString(),
          'offset': offset.toString(),
          'period': period,
          if (_playerId != null) 'playerId': _playerId!,
        },
      );

      final response = await http.get(
        uri,
        headers: _getHeaders(),
      ).timeout(RailwayConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          final List<dynamic> leaderboardData = data['leaderboard'];
          return leaderboardData
              .map((entry) => ServerLeaderboardEntry.fromJson(entry))
              .toList();
        }
      }
      
      throw Exception('Leaderboard fetch failed: ${response.statusCode}');
      
    } catch (e) {
      safePrint('🚂 ❌ Leaderboard fetch error: $e');
      return [];
    }
  }

  /// Get daily missions
  Future<List<ServerMission>> getDailyMissions() async {
    if (!_isAuthenticated) return [];

    try {
      final response = await http.get(
        Uri.parse(RailwayConfig.missionsDailyGet),
        headers: _getHeaders(includeAuth: true),
      ).timeout(RailwayConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          final List<dynamic> missionsData = data['missions'];
          return missionsData
              .map((mission) => ServerMission.fromJson(mission))
              .toList();
        }
      }
      
      throw Exception('Missions fetch failed: ${response.statusCode}');
      
    } catch (e) {
      safePrint('🚂 ❌ Missions fetch error: $e');
      return [];
    }
  }

  /// Update mission progress
  Future<bool> updateMissionProgress(String missionType, int amount) async {
    if (!_isAuthenticated) return false;

    try {
      final requestData = {
        'missionType': missionType,
        'amount': amount,
      };

      final response = await _makeAuthenticatedRequest(() => 
        http.post(
          Uri.parse(RailwayConfig.missionsProgress),
          headers: _getHeaders(includeAuth: true),
          body: jsonEncode(requestData),
        ).timeout(RailwayConfig.requestTimeout)
      );

      if (response?.statusCode == 200) {
        final data = jsonDecode(response!.body);
        if (data['success']) {
          safePrint('🚂 ✅ Mission progress updated: $missionType +$amount');
          return true;
        }
      }
      
      throw Exception('Mission progress update failed: ${response?.statusCode}');
      
    } catch (e) {
      safePrint('🚂 ❌ Mission progress update error: $e');
      
      // Add to offline queue
      _addToOfflineQueue('updateMissionProgress', {
        'missionType': missionType,
        'amount': amount,
      });
      
      return false;
    }
  }

  /// Update player profile on Railway backend
  Future<bool> updatePlayerProfile({
    String? nickname,
    String? countryCode,
    String? timezone,
  }) async {
    if (!_isAuthenticated) {
      safePrint('🚂 ❌ Cannot update profile - not authenticated');
      return false;
    }

    try {
      final updateData = <String, dynamic>{};
      if (nickname != null) updateData['nickname'] = nickname;
      if (countryCode != null) updateData['countryCode'] = countryCode;
      if (timezone != null) updateData['timezone'] = timezone;

      if (updateData.isEmpty) {
        safePrint('🚂 ⚠️ No profile data to update');
        return true;
      }

      final response = await http.put(
        Uri.parse(RailwayConfig.playerProfile),
        headers: _getHeaders(includeAuth: true),
        body: jsonEncode(updateData),
      ).timeout(RailwayConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          safePrint('🚂 ✅ Player profile updated successfully');
          return true;
        }
      }
      
      throw Exception('Profile update failed: ${response.statusCode}');
      
    } catch (e) {
      safePrint('🚂 ❌ Profile update error: $e');
      
      // Add to offline queue for retry when connection is restored
      _addToOfflineQueue('updatePlayerProfile', {
        'nickname': nickname,
        'countryCode': countryCode,
        'timezone': timezone,
      });
      
      return false;
    }
  }

  /// Track analytics event
  Future<void> trackEvent(String eventName, Map<String, dynamic> parameters) async {
    try {
      final requestData = {
        'eventName': eventName,
        'parameters': parameters,
      };

      // Don't await - fire and forget for analytics
      http.post(
        Uri.parse(RailwayConfig.analyticsEvent),
        headers: _getHeaders(includeAuth: _isAuthenticated),
        body: jsonEncode(requestData),
      ).timeout(RailwayConfig.requestTimeout);

    } catch (e) {
      safePrint('🚂 ⚠️ Analytics event error: $e');
    }
  }

  /// Get HTTP headers
  Map<String, String> _getHeaders({bool includeAuth = false}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth && _authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    return headers;
  }

  /// Calculate difficulty phase based on score
  int _calculateDifficultyPhase(int score) {
    if (score < 6) return 1;
    if (score < 12) return 2;
    if (score < 18) return 3;
    if (score < 25) return 4;
    if (score < 35) return 5;
    if (score < 45) return 6;
    if (score < 60) return 7;
    return 8;
  }

  /// Save authentication data
  Future<void> _saveAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    if (_authToken != null) {
      await prefs.setString(_keyAuthToken, _authToken!);
    }
    if (_playerId != null) {
      await prefs.setString(_keyPlayerId, _playerId!);
    }
  }

  /// Clear authentication data
  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAuthToken);
    await prefs.remove(_keyPlayerId);
    
    _authToken = null;
    _playerId = null;
    _isAuthenticated = false;
    
    notifyListeners();
  }

  /// Add request to offline queue
  void _addToOfflineQueue(String action, Map<String, dynamic> data) {
    _offlineQueue.add({
      'action': action,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    
    // Limit queue size
    if (_offlineQueue.length > 100) {
      _offlineQueue.removeAt(0);
    }
  }

  /// Process offline queue when connection is restored
  Future<void> processOfflineQueue() async {
    if (!_isOnline || !_isAuthenticated || _offlineQueue.isEmpty) return;

    safePrint('🚂 Processing ${_offlineQueue.length} offline requests');
    
    final processedItems = <Map<String, dynamic>>[];
    
    for (final item in _offlineQueue) {
      try {
        final action = item['action'];
        final data = item['data'];
        
        bool success = false;
        
        switch (action) {
          case 'submitScore':
            final result = await submitScore(
              score: data['score'],
              survivalTime: data['survivalTime'],
              skinUsed: data['skinUsed'],
              coinsEarned: data['coinsEarned'],
              gemsEarned: data['gemsEarned'],
              gameDuration: data['gameDuration'],
            );
            success = result != null;
            break;
            
          case 'updateMissionProgress':
            success = await updateMissionProgress(
              data['missionType'],
              data['amount'],
            );
            break;
            
          case 'updatePlayerProfile':
            success = await updatePlayerProfile(
              nickname: data['nickname'],
              countryCode: data['countryCode'],
              timezone: data['timezone'],
            );
            break;
        }
        
        if (success) {
          processedItems.add(item);
        }
        
      } catch (e) {
        safePrint('🚂 ⚠️ Failed to process offline item: $e');
        break; // Stop processing if we're offline again
      }
    }
    
    // Remove successfully processed items
    for (final item in processedItems) {
      _offlineQueue.remove(item);
    }
    
    if (processedItems.isNotEmpty) {
      safePrint('🚂 ✅ Processed ${processedItems.length} offline requests');
    }
  }

  /// Force sync with server
  Future<void> forceSyncNow() async {
    await _checkServerHealth();
    if (_isOnline) {
      await processOfflineQueue();
      _lastSyncTime = DateTime.now();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyLastSync, _lastSyncTime!.millisecondsSinceEpoch);
      
      notifyListeners();
    }
  }

  /// Logout and clear all data
  Future<void> logout() async {
    await _clearAuthData();
    _offlineQueue.clear();
    safePrint('🚂 ✅ Logged out successfully');
  }
}
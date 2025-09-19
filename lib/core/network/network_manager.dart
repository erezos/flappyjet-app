/// 🌐 Unified Network Manager - AAA Mobile Game Standard
/// 
/// Handles all network communication with Railway backend
/// Based on patterns from successful mobile games with robust offline support
library;

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../debug_logger.dart';
import '../../game/systems/player_identity_manager.dart';
import 'offline_manager.dart';

/// Network request result wrapper
class NetworkResult<T> {
  final bool success;
  final T? data;
  final String? error;
  final int? statusCode;
  final bool fromCache;

  NetworkResult.success(this.data, {this.fromCache = false}) 
    : success = true, error = null, statusCode = 200;
  
  NetworkResult.error(this.error, {this.statusCode}) 
    : success = false, data = null, fromCache = false;
  
  NetworkResult.cached(this.data) 
    : success = true, error = null, statusCode = 200, fromCache = true;
}

/// Network request configuration
class NetworkRequest {
  final String endpoint;
  final String method;
  final Map<String, dynamic>? body;
  final Map<String, String>? headers;
  final bool requiresAuth;
  final bool canQueue; // Can be queued for offline processing
  final Duration timeout;
  final int maxRetries;
  final int priority; // 1 = highest, 5 = lowest
  final String? deduplicationKey; // For preventing duplicate requests

  NetworkRequest({
    required this.endpoint,
    this.method = 'GET',
    this.body,
    this.headers,
    this.requiresAuth = true,
    this.canQueue = true,
    this.timeout = const Duration(seconds: 15),
    this.maxRetries = 3,
    this.priority = 3, // Default medium priority
    this.deduplicationKey,
  });

  /// Generate a unique key for deduplication
  String get uniqueKey => deduplicationKey ?? '$method:$endpoint:${body?.toString() ?? ''}';
}

/// Unified Network Manager - Single point for all backend communication
class NetworkManager extends ChangeNotifier {
  static final NetworkManager _instance = NetworkManager._internal();
  factory NetworkManager() => _instance;
  NetworkManager._internal();

  // Dependencies
  final PlayerIdentityManager _playerIdentity = PlayerIdentityManager();
  final OfflineManager _offlineManager = OfflineManager();
  
  // Configuration
  static const String baseUrl = 'https://flappyjet-backend-production.up.railway.app';
  
  // HTTP client with connection pooling
  final http.Client _httpClient = http.Client();
  
  // Network state
  bool _isOnline = true;
  int _activeRequestCount = 0;
  
  // Request deduplication
  final Map<String, Future<NetworkResult<Map<String, dynamic>>>> _activeRequests = {};
  
  // Getters
  bool get isOnline => _isOnline;
  bool get hasActiveRequests => _activeRequestCount > 0;

  /// Initialize network manager
  Future<void> initialize() async {
    // Initialize dependencies
    // PlayerIdentityManager initialization handled separately
    await _offlineManager.initialize();
    
    // Check initial connectivity
    await _checkConnectivity();
    
    // Process any queued offline requests
    await _offlineManager.processQueue(_makeAuthenticatedRequest);
    
    safePrint('🌐 Network Manager initialized - Online: $_isOnline');
  }

  /// Make authenticated API request with deduplication
  Future<NetworkResult<Map<String, dynamic>>> request(NetworkRequest request) async {
    // Check for duplicate requests
    final requestKey = request.uniqueKey;
    if (_activeRequests.containsKey(requestKey)) {
      safePrint('🌐 Deduplicating request: ${request.endpoint}');
      return await _activeRequests[requestKey]!;
    }

    // Ensure we have valid authentication if required
    if (request.requiresAuth) {
      if (!_playerIdentity.isAuthenticated) {
        return NetworkResult.error('Not authenticated');
      }
      await _playerIdentity.ensureValidToken();
    }

    // Create and track the request future
    final requestFuture = _makeRequest(request);
    _activeRequests[requestKey] = requestFuture;

    try {
      // Try to make the request
      final result = await requestFuture;
      
      // If request failed and can be queued, add to offline queue
      if (!result.success && request.canQueue && _isOnline) {
        await _offlineManager.queueRequest(request);
      }
      
      return result;
    } finally {
      // Clean up the active request
      _activeRequests.remove(requestKey);
    }
  }

  /// Internal request method with retry logic
  Future<NetworkResult<Map<String, dynamic>>> _makeRequest(NetworkRequest request) async {
    for (int attempt = 0; attempt <= request.maxRetries; attempt++) {
      try {
        _activeRequestCount++;
        notifyListeners();

        final response = await _makeHttpRequest(request);
        
        if (response != null) {
          _isOnline = true;
          
          if (response.statusCode >= 200 && response.statusCode < 300) {
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            return NetworkResult.success(data);
          } else if (response.statusCode == 401 || response.statusCode == 403) {
            // Authentication error - don't retry
            return NetworkResult.error('Authentication failed', statusCode: response.statusCode);
          } else {
            // Server error - retry if not last attempt
            if (attempt < request.maxRetries) {
              await Future.delayed(Duration(seconds: (attempt + 1) * 2)); // Exponential backoff
              continue;
            }
            return NetworkResult.error('Server error: ${response.statusCode}', statusCode: response.statusCode);
          }
        } else {
          // Network error - retry if not last attempt
          if (attempt < request.maxRetries) {
            await Future.delayed(Duration(seconds: (attempt + 1) * 2));
            continue;
          }
          _isOnline = false;
          return NetworkResult.error('Network error');
        }
      } catch (e) {
        safePrint('🌐 Request attempt ${attempt + 1} failed: $e');
        if (attempt < request.maxRetries) {
          await Future.delayed(Duration(seconds: (attempt + 1) * 2));
          continue;
        }
        _isOnline = false;
        return NetworkResult.error('Network error: $e');
      } finally {
        _activeRequestCount--;
        notifyListeners();
      }
    }
    
    return NetworkResult.error('Max retries exceeded');
  }

  /// Make HTTP request with proper headers and timeout
  Future<http.Response?> _makeHttpRequest(NetworkRequest request) async {
    final uri = Uri.parse('$baseUrl${request.endpoint}');
    final headers = _buildHeaders(request);
    
    try {
      switch (request.method.toUpperCase()) {
        case 'GET':
          return await _httpClient.get(uri, headers: headers).timeout(request.timeout);
        case 'POST':
          return await _httpClient.post(
            uri, 
            headers: headers, 
            body: request.body != null ? jsonEncode(request.body) : null,
          ).timeout(request.timeout);
        case 'PUT':
          return await _httpClient.put(
            uri, 
            headers: headers, 
            body: request.body != null ? jsonEncode(request.body) : null,
          ).timeout(request.timeout);
        case 'DELETE':
          return await _httpClient.delete(uri, headers: headers).timeout(request.timeout);
        default:
          throw UnsupportedError('HTTP method ${request.method} not supported');
      }
    } catch (e) {
      safePrint('🌐 HTTP request failed: $e');
      return null;
    }
  }

  /// Build request headers
  Map<String, String> _buildHeaders(NetworkRequest request) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'User-Agent': 'FlappyJet/1.4.6',
      'X-Platform': Platform.isAndroid ? 'android' : 'ios',
      'X-App-Version': '1.4.6',
    };

    // Add custom headers
    if (request.headers != null) {
      headers.addAll(request.headers!);
    }

    // Add authentication header if required
    if (request.requiresAuth && _playerIdentity.authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${_playerIdentity.authToken}';
    }

    return headers;
  }

  /// Check network connectivity
  Future<void> _checkConnectivity() async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$baseUrl/api/health'),
      ).timeout(Duration(seconds: 5));
      
      _isOnline = response.statusCode == 200;
    } catch (e) {
      _isOnline = false;
    }
    
    safePrint('🌐 Connectivity check: ${_isOnline ? 'Online' : 'Offline'}');
    notifyListeners();
  }

  /// Wrapper method for authenticated requests (used by offline manager)
  Future<NetworkResult<Map<String, dynamic>>> _makeAuthenticatedRequest(NetworkRequest request) async {
    return await _makeRequest(request);
  }

  // ==================== GAME-SPECIFIC API METHODS ====================

  /// Submit game score
  Future<NetworkResult<Map<String, dynamic>>> submitScore({
    required int score,
    required int survivalTime,
    required String skinUsed,
    required int coinsEarned,
    required int gemsEarned,
  }) async {
    return await request(NetworkRequest(
      endpoint: '/api/leaderboard/submit',
      method: 'POST',
      body: {
        'score': score,
        'survival_time': survivalTime,
        'skin_used': skinUsed,
        'coins_earned': coinsEarned,
        'gems_earned': gemsEarned,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    ));
  }

  /// Get global leaderboard
  Future<NetworkResult<Map<String, dynamic>>> getGlobalLeaderboard({
    int limit = 100,
    int offset = 0,
  }) async {
    return await request(NetworkRequest(
      endpoint: '/api/leaderboard/global?limit=$limit&offset=$offset',
      method: 'GET',
      canQueue: false, // Don't queue leaderboard requests
    ));
  }

  /// Sync player data
  Future<NetworkResult<Map<String, dynamic>>> syncPlayerData(Map<String, dynamic> playerData) async {
    return await request(NetworkRequest(
      endpoint: '/api/player/sync',
      method: 'POST',
      body: playerData,
    ));
  }

  /// Get daily missions
  Future<NetworkResult<Map<String, dynamic>>> getDailyMissions() async {
    return await request(NetworkRequest(
      endpoint: '/api/missions/daily',
      method: 'GET',
    ));
  }

  /// Update mission progress
  Future<NetworkResult<Map<String, dynamic>>> updateMissionProgress({
    required String missionId,
    required int progress,
  }) async {
    return await request(NetworkRequest(
      endpoint: '/api/missions/progress',
      method: 'POST',
      body: {
        'mission_id': missionId,
        'progress': progress,
      },
    ));
  }

  /// Get player achievements
  Future<NetworkResult<Map<String, dynamic>>> getPlayerAchievements() async {
    return await request(NetworkRequest(
      endpoint: '/api/achievements/player',
      method: 'GET',
    ));
  }

  /// Submit analytics event
  Future<NetworkResult<Map<String, dynamic>>> submitAnalyticsEvent({
    required String eventName,
    required Map<String, dynamic> eventData,
  }) async {
    return await request(NetworkRequest(
      endpoint: '/api/analytics/event',
      method: 'POST',
      body: {
        'event_name': eventName,
        'event_data': eventData,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      requiresAuth: false, // Analytics can be anonymous
    ));
  }

  /// Register FCM token
  Future<NetworkResult<Map<String, dynamic>>> registerFCMToken(String token) async {
    return await request(NetworkRequest(
      endpoint: '/api/fcm/register',
      method: 'POST',
      body: {
        'fcm_token': token,
        'platform': Platform.isAndroid ? 'android' : 'ios',
      },
    ));
  }

  /// Get player profile
  Future<NetworkResult<Map<String, dynamic>>> getPlayerProfile() async {
    return await request(NetworkRequest(
      endpoint: '/api/player/profile',
      method: 'GET',
    ));
  }

  /// Update player profile
  Future<NetworkResult<Map<String, dynamic>>> updatePlayerProfile(Map<String, dynamic> profileData) async {
    // For nickname updates, use the leaderboard endpoint
    if (profileData.containsKey('nickname')) {
      final playerIdentity = PlayerIdentityManager();
      final playerId = playerIdentity.playerId;
      
      if (playerId.isEmpty) {
        return NetworkResult.error('Player not authenticated');
      }
      
      return await request(NetworkRequest(
        endpoint: '/api/leaderboard/player/$playerId/nickname',
        method: 'PUT',
        body: {'nickname': profileData['nickname']},
      ));
    }
    
    // For other profile updates, use the general profile endpoint (if it exists)
    return await request(NetworkRequest(
      endpoint: '/api/player/profile',
      method: 'PUT',
      body: profileData,
    ));
  }

  /// Validate purchase
  Future<NetworkResult<Map<String, dynamic>>> validatePurchase({
    required String purchaseToken,
    required String productId,
    required String platform,
  }) async {
    return await request(NetworkRequest(
      endpoint: '/api/purchase/validate',
      method: 'POST',
      body: {
        'purchase_token': purchaseToken,
        'product_id': productId,
        'platform': platform,
      },
    ));
  }

  // ==================== UTILITY METHODS ====================

  /// Force connectivity check
  Future<void> checkConnectivity() async {
    await _checkConnectivity();
  }

  /// Get network statistics
  Map<String, dynamic> getNetworkStats() {
    return {
      'isOnline': _isOnline,
      'activeRequests': _activeRequests,
      'queuedRequests': _offlineManager.queueSize,
    };
  }

  @override
  void dispose() {
    _httpClient.close();
    super.dispose();
  }
}

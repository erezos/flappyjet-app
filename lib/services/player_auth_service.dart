/// 👤 Player Authentication Service - Handles backend player registration and auth
library;
import '../core/debug_logger.dart';

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flappy_jet_pro/game/systems/player_identity_manager.dart';
import 'tournament_service.dart';

/// Player registration data
class PlayerRegistrationData {
  final String deviceId;
  final String nickname;
  final String platform;
  final String appVersion;
  final String? countryCode;
  final String? timezone;

  PlayerRegistrationData({
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

/// Player profile data from backend
class PlayerProfileData {
  final String playerId;
  final String nickname;
  final int bestScore;
  final int bestStreak;
  final int totalGamesPlayed;
  final int currentCoins;
  final int currentGems;
  final int currentHearts;
  final bool isPremium;

  PlayerProfileData({
    required this.playerId,
    required this.nickname,
    required this.bestScore,
    required this.bestStreak,
    required this.totalGamesPlayed,
    required this.currentCoins,
    required this.currentGems,
    required this.currentHearts,
    required this.isPremium,
  });

  factory PlayerProfileData.fromJson(Map<String, dynamic> json) {
    return PlayerProfileData(
      playerId: json['id'],
      nickname: json['nickname'],
      bestScore: json['best_score'] ?? 0,
      bestStreak: json['best_streak'] ?? 0,
      totalGamesPlayed: json['total_games_played'] ?? 0,
      currentCoins: json['current_coins'] ?? 0,
      currentGems: json['current_gems'] ?? 0,
      currentHearts: json['current_hearts'] ?? 0,
      isPremium: json['is_premium'] ?? false,
    );
  }
}

/// 🔐 Player Authentication Service
class PlayerAuthService {
  final String baseUrl;
  final http.Client httpClient;

  PlayerAuthService({
    required this.baseUrl,
    http.Client? httpClient,
  }) : httpClient = httpClient ?? http.Client();

  /// Register a new player with the backend
  Future<ApiResult<String>> registerPlayer(PlayerRegistrationData registrationData) async {
    try {
      final response = await httpClient.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: _getHeaders(),
        body: json.encode(registrationData.toJson()),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final token = data['token'];
        final playerId = data['player']['id']; // Backend returns player.id, not playerId

        safePrint('👤 Player registered successfully: $playerId');
        safePrint('👤 Registration response: ${data.toString()}');

        // Mark player as registered in PlayerIdentityManager
        final identityManager = PlayerIdentityManager();
        await identityManager.markBackendRegistered(playerId, registrationData.nickname, token);

        return ApiResult.success(token, message: data['message'] ?? 'Registration successful');
      } else {
        safePrint('👤 ❌ Registration failed - Status: ${response.statusCode}, Response: ${response.body}');
        return ApiResult.error(data['error'] ?? 'Registration failed');
      }
    } catch (e) {
      safePrint('Error registering player: $e');
      return ApiResult.error('Network error: $e');
    }
  }

  /// Login existing player
  Future<ApiResult<String>> loginPlayer(String deviceId) async {
    try {
      final response = await httpClient.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: _getHeaders(),
        body: json.encode({
          'deviceId': deviceId,
          'platform': _getPlatformString(),
          'appVersion': '1.3.3', // Updated version
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final token = data['token'];
        final playerId = data['player']['id']; // Backend returns player.id
        final nickname = data['player']['nickname']; // Backend returns player.nickname

        safePrint('👤 Player logged in successfully: $playerId');
        safePrint('👤 Login response: ${data.toString()}');

        // Update PlayerIdentityManager with backend data
        final identityManager = PlayerIdentityManager();
        await identityManager.markBackendRegistered(playerId, nickname, token);

        return ApiResult.success(token, message: data['message'] ?? 'Login successful');
      } else {
        safePrint('👤 ❌ Login failed - Status: ${response.statusCode}, Response: ${response.body}');
        return ApiResult.error(data['error'] ?? 'Login failed');
      }
    } catch (e) {
      safePrint('Error logging in player: $e');
      return ApiResult.error('Network error: $e');
    }
  }

  /// Refresh expired JWT token
  Future<ApiResult<String>> refreshToken(String currentToken) async {
    try {
      final response = await httpClient.post(
        Uri.parse('$baseUrl/api/auth/refresh'),
        headers: _getHeaders(authToken: currentToken),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final newToken = data['token'];
        
        safePrint('👤 Token refreshed successfully');

        // Update PlayerIdentityManager with new token
        final identityManager = PlayerIdentityManager();
        await identityManager.updateAuthToken(newToken);

        return ApiResult.success(newToken, message: 'Token refreshed');
      } else {
        return ApiResult.error(data['error'] ?? 'Token refresh failed');
      }
    } catch (e) {
      safePrint('Error refreshing token: $e');
      return ApiResult.error('Network error: $e');
    }
  }

  /// Get player profile from backend
  Future<ApiResult<PlayerProfileData>> getPlayerProfile(String authToken) async {
    try {
      final response = await httpClient.get(
        Uri.parse('$baseUrl/api/player/profile'),
        headers: _getHeaders(authToken: authToken),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final profile = PlayerProfileData.fromJson(data['profile']);
        return ApiResult.success(profile);
      } else {
        return ApiResult.error(data['error'] ?? 'Failed to get profile');
      }
    } catch (e) {
      safePrint('Error getting player profile: $e');
      return ApiResult.error('Network error: $e');
    }
  }

  /// Update player profile
  Future<ApiResult<bool>> updatePlayerProfile({
    required String authToken,
    String? nickname,
    String? countryCode,
    String? timezone,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (nickname != null) updateData['nickname'] = nickname;
      if (countryCode != null) updateData['countryCode'] = countryCode;
      if (timezone != null) updateData['timezone'] = timezone;

      final response = await httpClient.put(
        Uri.parse('$baseUrl/api/player/profile'),
        headers: _getHeaders(authToken: authToken),
        body: json.encode(updateData),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResult.success(true, message: data['message']);
      } else {
        return ApiResult.error(data['error'] ?? 'Profile update failed');
      }
    } catch (e) {
      safePrint('Error updating player profile: $e');
      return ApiResult.error('Network error: $e');
    }
  }

  Map<String, String> _getHeaders({String? authToken}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    return headers;
  }

  /// Get platform string for backend registration
  String _getPlatformString() {
    try {
      if (Platform.isAndroid) {
        return 'android';
      } else if (Platform.isIOS) {
        return 'ios';
      } else {
        return 'web';
      }
    } catch (e) {
      // Fallback for web or unknown platforms
      return 'web';
    }
  }

  void dispose() {
    httpClient.close();
  }
}
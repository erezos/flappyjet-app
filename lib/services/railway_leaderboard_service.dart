/// 🏆 Railway Leaderboard Service
/// Connects to Railway backend for real leaderboard data
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../game/systems/player_identity_manager.dart';

class RailwayLeaderboardService {
  static const String _baseUrl = 'https://flappyjet-backend-production.up.railway.app';
  static const Duration _timeout = Duration(seconds: 10);
  
  final PlayerIdentityManager _playerIdentityManager;
  
  RailwayLeaderboardService({
    required PlayerIdentityManager playerIdentityManager,
  }) : _playerIdentityManager = playerIdentityManager;

  /// Get global leaderboard with top players
  Future<LeaderboardResult> getGlobalLeaderboard({
    int limit = 15,
    int offset = 0,
    bool includeUserPosition = true,
  }) async {
    try {
      final playerId = includeUserPosition && _playerIdentityManager.playerId.isNotEmpty 
          ? _playerIdentityManager.playerId 
          : null;
      final uri = Uri.parse('$_baseUrl/api/leaderboard/global').replace(
        queryParameters: {
          'limit': limit.toString(),
          'offset': offset.toString(),
          if (playerId != null) 'playerId': playerId,
        },
      );

      debugPrint('🏆 Fetching global leaderboard from: $uri');
      debugPrint('🏆 Request playerId: $playerId');

      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          final leaderboard = (data['leaderboard'] as List)
              .map((item) => LeaderboardEntry.fromJson(item))
              .toList();
          
          final userPosition = data['userPosition'] != null
              ? LeaderboardEntry.fromJson(data['userPosition'])
              : null;

          debugPrint('🏆 ✅ Loaded ${leaderboard.length} leaderboard entries');
          
          return LeaderboardResult(
            success: true,
            leaderboard: leaderboard,
            userPosition: userPosition,
          );
        } else {
          debugPrint('🏆 ❌ API returned error: ${data['error']}');
          return LeaderboardResult(
            success: false,
            error: data['error'] ?? 'Unknown error',
          );
        }
      } else {
        debugPrint('🏆 ❌ HTTP error: ${response.statusCode}');
        return LeaderboardResult(
          success: false,
          error: 'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('🏆 ❌ Exception getting global leaderboard: $e');
      return LeaderboardResult(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  /// Get player's personal top scores
  Future<PersonalScoresResult> getPersonalScores({int limit = 10}) async {
    try {
      final playerId = _playerIdentityManager.playerId;
      final authToken = _playerIdentityManager.authToken;
      
      if (playerId.isEmpty || authToken.isEmpty) {
        return PersonalScoresResult(
          success: false,
          error: 'Player not authenticated',
        );
      }

      final uri = Uri.parse('$_baseUrl/api/leaderboard/player/$playerId/scores').replace(
        queryParameters: {
          'limit': limit.toString(),
        },
      );

      debugPrint('🏆 Fetching personal scores from: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          final scores = (data['scores'] as List)
              .map((item) => PersonalScore.fromJson(item))
              .toList();

          debugPrint('🏆 ✅ Loaded ${scores.length} personal scores');
          
          return PersonalScoresResult(
            success: true,
            scores: scores,
          );
        } else {
          debugPrint('🏆 ❌ API returned error: ${data['error']}');
          return PersonalScoresResult(
            success: false,
            error: data['error'] ?? 'Unknown error',
          );
        }
      } else {
        debugPrint('🏆 ❌ HTTP error: ${response.statusCode}');
        return PersonalScoresResult(
          success: false,
          error: 'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('🏆 ❌ Exception getting personal scores: $e');
      return PersonalScoresResult(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  /// Submit a new score to the leaderboard
  Future<ScoreSubmissionResult> submitScore({
    required int score,
    String? jetSkin,
    String? theme,
    Map<String, dynamic>? gameData,
  }) async {
    try {
      final authToken = _playerIdentityManager.authToken;
      
      if (authToken.isEmpty) {
        return ScoreSubmissionResult(
          success: false,
          error: 'Player not authenticated',
        );
      }

      final uri = Uri.parse('$_baseUrl/api/leaderboard/submit');

      debugPrint('🏆 Submitting score: $score');

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'score': score,
          if (jetSkin != null) 'jetSkin': jetSkin,
          if (theme != null) 'theme': theme,
          if (gameData != null) 'gameData': gameData,
        }),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          debugPrint('🏆 ✅ Score submitted successfully');
          
          return ScoreSubmissionResult(
            success: true,
            newBest: data['newBest'] ?? false,
            globalRank: data['globalRank'],
          );
        } else {
          debugPrint('🏆 ❌ API returned error: ${data['error']}');
          return ScoreSubmissionResult(
            success: false,
            error: data['error'] ?? 'Unknown error',
          );
        }
      } else {
        debugPrint('🏆 ❌ HTTP error: ${response.statusCode}');
        return ScoreSubmissionResult(
          success: false,
          error: 'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('🏆 ❌ Exception submitting score: $e');
      return ScoreSubmissionResult(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  /// Update player nickname across all systems
  Future<NicknameUpdateResult> updateNickname(String newNickname) async {
    try {
      final playerId = _playerIdentityManager.playerId;
      final authToken = _playerIdentityManager.authToken;
      
      if (playerId.isEmpty || authToken.isEmpty) {
        return NicknameUpdateResult(
          success: false,
          error: 'Player not authenticated',
        );
      }

      final uri = Uri.parse('$_baseUrl/api/leaderboard/player/$playerId/nickname');

      debugPrint('🏆 Updating nickname to: $newNickname');

      final response = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'nickname': newNickname,
        }),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          debugPrint('🏆 ✅ Nickname updated successfully');
          
          return NicknameUpdateResult(
            success: true,
            message: data['message'],
          );
        } else {
          debugPrint('🏆 ❌ API returned error: ${data['error']}');
          return NicknameUpdateResult(
            success: false,
            error: data['error'] ?? 'Unknown error',
          );
        }
      } else {
        debugPrint('🏆 ❌ HTTP error: ${response.statusCode}');
        return NicknameUpdateResult(
          success: false,
          error: 'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('🏆 ❌ Exception updating nickname: $e');
      return NicknameUpdateResult(
        success: false,
        error: 'Network error: $e',
      );
    }
  }
}

/// Result classes for API responses
class LeaderboardResult {
  final bool success;
  final List<LeaderboardEntry> leaderboard;
  final LeaderboardEntry? userPosition;
  final String? error;

  LeaderboardResult({
    required this.success,
    this.leaderboard = const [],
    this.userPosition,
    this.error,
  });
}

class PersonalScoresResult {
  final bool success;
  final List<PersonalScore> scores;
  final String? error;

  PersonalScoresResult({
    required this.success,
    this.scores = const [],
    this.error,
  });
}

class ScoreSubmissionResult {
  final bool success;
  final bool newBest;
  final int? globalRank;
  final String? error;

  ScoreSubmissionResult({
    required this.success,
    this.newBest = false,
    this.globalRank,
    this.error,
  });
}

class NicknameUpdateResult {
  final bool success;
  final String? message;
  final String? error;

  NicknameUpdateResult({
    required this.success,
    this.message,
    this.error,
  });
}

/// Data models
class LeaderboardEntry {
  final String playerId;
  final String playerName;
  final int score;
  final int totalGames;
  final String jetSkin;
  final String theme;
  final int rank;
  final DateTime achievedAt;

  LeaderboardEntry({
    required this.playerId,
    required this.playerName,
    required this.score,
    required this.totalGames,
    required this.jetSkin,
    required this.theme,
    required this.rank,
    required this.achievedAt,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      playerId: json['playerId'] ?? '',
      playerName: json['playerName'] ?? 'Anonymous',
      score: json['score'] ?? 0,
      totalGames: json['totalGames'] ?? 0,
      jetSkin: json['jetSkin'] ?? 'jets/green_lightning.png',
      theme: json['theme'] ?? 'sky',
      rank: json['rank'] ?? 0,
      achievedAt: DateTime.tryParse(json['achievedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class PersonalScore {
  final int rank;
  final int score;
  final int survivalTime;
  final String jetSkin;
  final String theme;
  final Map<String, dynamic> gameData;
  final DateTime achievedAt;

  PersonalScore({
    required this.rank,
    required this.score,
    required this.survivalTime,
    required this.jetSkin,
    required this.theme,
    required this.gameData,
    required this.achievedAt,
  });

  factory PersonalScore.fromJson(Map<String, dynamic> json) {
    return PersonalScore(
      rank: json['rank'] ?? 0,
      score: json['score'] ?? 0,
      survivalTime: json['survivalTime'] ?? 0,
      jetSkin: json['jetSkin'] ?? 'jets/green_lightning.png',
      theme: json['theme'] ?? 'sky',
      gameData: json['gameData'] ?? {},
      achievedAt: DateTime.tryParse(json['achievedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

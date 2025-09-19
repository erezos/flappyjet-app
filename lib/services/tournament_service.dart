import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/debug_logger.dart';

import '../models/tournament.dart';
import '../models/tournament_leaderboard_entry.dart';
import '../models/tournament_session_result.dart';
import '../game/systems/player_identity_manager.dart';
import '../game/core/error_handler.dart';
// Removed network_manager import - not used directly

/// Service for interacting with the tournament API
class TournamentService {
  final String baseUrl;
  final http.Client httpClient;
  
  TournamentService({
    required this.baseUrl,
    http.Client? httpClient,
  }) : httpClient = httpClient ?? http.Client();

  /// Get the current active tournament
  Future<ApiResult<Tournament?>> getCurrentTournament() async {
    try {
      final response = await httpClient.get(
        Uri.parse('$baseUrl/api/tournaments/current'),
        headers: _getHeaders(),
      );

      safePrint('🏆 Tournament API Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = ErrorHandler.safeSync(
          () => json.decode(response.body) as Map<String, dynamic>,
          context: 'tournament_response_parsing',
          severity: ErrorSeverity.high,
        );

        if (data == null) {
          return ApiResult.error('Failed to parse tournament response');
        }

        if (data['success'] == true) {
          if (data['tournament'] != null) {
            final tournament = ErrorHandler.safeSync(
              () => Tournament.fromJson(data['tournament']),
              context: 'tournament_model_parsing',
              severity: ErrorSeverity.high,
            );

            if (tournament != null) {
              return ApiResult.success(tournament);
            } else {
              return ApiResult.error('Failed to parse tournament data');
            }
          } else {
            return ApiResult.success(null);
          }
        } else {
          return ApiResult.error(data['error'] ?? 'Unknown API error');
        }
      } else {
        ErrorHandler.handleError(
          'Tournament API returned HTTP ${response.statusCode}',
          null,
          context: 'tournament_api_call',
          severity: ErrorSeverity.high,
        );
        return ApiResult.error('HTTP ${response.statusCode}: Failed to fetch tournament');
      }
    } catch (error, stackTrace) {
      ErrorHandler.handleError(
        error,
        stackTrace,
        context: 'tournament_fetch',
        severity: ErrorSeverity.high,
      );
      return ApiResult.error('Network error occurred');
    }
  }

  /// Register for a tournament
  Future<ApiResult<String>> registerForTournament({
    required String tournamentId,
    required String playerName,
    required String authToken,
  }) async {
    try {
      final response = await httpClient.post(
        Uri.parse('$baseUrl/api/tournaments/$tournamentId/register'),
        headers: _getHeaders(authToken: authToken),
        body: json.encode({
          'playerName': playerName,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return ApiResult.success(
          data['participantId'],
          message: data['message'],
        );
      } else {
        return ApiResult.error(data['error'] ?? 'Registration failed');
      }
    } catch (e) {
      safePrint('Error registering for tournament: $e');
      return ApiResult.error('Network error: $e');
    }
  }

  /// Submit a score to a tournament
  Future<ApiResult<ScoreSubmissionResult>> submitScore({
    required String tournamentId,
    required int score,
    required String authToken,
    Map<String, dynamic>? gameData,
  }) async {
    try {
      final response = await httpClient.post(
        Uri.parse('$baseUrl/api/tournaments/$tournamentId/scores'),
        headers: _getHeaders(authToken: authToken),
        body: json.encode({
          'score': score,
          'gameData': gameData ?? {},
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final result = ScoreSubmissionResult(
          newBest: data['newBest'] ?? false,
          score: data['score'],
          previousBest: data['previousBest'],
          rank: data['rank'],
          totalGames: data['totalGames'],
        );
        return ApiResult.success(result);
      } else {
        return ApiResult.error(data['error'] ?? 'Score submission failed');
      }
    } catch (e) {
      safePrint('Error submitting score: $e');
      return ApiResult.error('Network error: $e');
    }
  }

  /// Get tournament leaderboard
  Future<ApiResult<TournamentLeaderboardResponse>> getTournamentLeaderboard({
    required String tournamentId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/tournaments/$tournamentId/leaderboard')
          .replace(queryParameters: {
        'limit': limit.toString(),
        'offset': offset.toString(),
      });

      final response = await httpClient.get(
        uri,
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          final entries = (data['leaderboard'] as List)
              .map((entry) => TournamentLeaderboardEntry.fromJson(entry))
              .toList();
          
          final pagination = TournamentPagination.fromJson(data['pagination']);
          
          final leaderboardResponse = TournamentLeaderboardResponse(
            entries: entries,
            pagination: pagination,
          );
          
          return ApiResult.success(leaderboardResponse);
        } else {
          return ApiResult.error(data['error'] ?? 'Failed to fetch leaderboard');
        }
      } else {
        return ApiResult.error('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      safePrint('Error getting tournament leaderboard: $e');
      return ApiResult.error('Failed to parse response: $e');
    }
  }

  /// Unified tournament session - handles registration, score submission, and state retrieval
  Future<ApiResult<TournamentSessionResult>> handleTournamentSession({
    String tournamentId = 'current',
    required String action, // 'get_status' or 'submit_score'
    int? score,
    Map<String, dynamic>? gameData,
  }) async {
    try {
      final playerIdentity = PlayerIdentityManager();
      if (!playerIdentity.isBackendRegistered) {
        return ApiResult.error('Player not registered with backend');
      }

      // 🚨 CRITICAL: Ensure nickname is synced to backend before tournament submission
      safePrint('🚂 🏆 Ensuring nickname sync before tournament submission...');
      final syncSuccess = await playerIdentity.forceNicknameSyncToBackend();
      if (!syncSuccess) {
        safePrint('🚨 WARNING: Nickname sync failed - tournament may show old name');
      }

      // DEBUG: Log current player identity
      safePrint('🎯 TOURNAMENT DEBUG: Current player name = ${playerIdentity.playerName}');
      safePrint('🎯 TOURNAMENT DEBUG: Current player ID = ${playerIdentity.playerId}');
      safePrint('🎯 TOURNAMENT DEBUG: Device ID = ${playerIdentity.deviceId}');
      safePrint('🎯 TOURNAMENT DEBUG: Backend sync status = $syncSuccess');

      // Try with current token first
      safePrint('🏆 Making tournament request with token: ${playerIdentity.authToken.substring(0, 20)}...');
      safePrint('🏆 Tournament request payload: tournamentId=$tournamentId, action=$action, playerName=${playerIdentity.playerName}');
      
      var response = await httpClient.post(
        Uri.parse('$baseUrl/api/tournaments/session'),
        headers: _getHeaders(authToken: playerIdentity.authToken),
        body: json.encode({
          'tournamentId': tournamentId,
          'action': action,
          'playerName': playerIdentity.playerName, // Include current player name
          if (score != null) 'score': score,
          if (gameData != null) 'gameData': gameData,
        }),
      );

      safePrint('🏆 Tournament response: ${response.statusCode} - ${response.body}');
      var data = json.decode(response.body);

      // If authentication failed (403 or 401), try to refresh and retry
      if ((response.statusCode == 403 || response.statusCode == 401) && 
          (data['error']?.contains('expired') == true || 
           data['error']?.contains('Invalid') == true ||
           data['error']?.contains('token') == true ||
           data['code'] == 'AUTH_TOKEN_INVALID' ||
           data['code'] == 'AUTH_TOKEN_MISSING')) {
        safePrint('🔄 Authentication failed (${response.statusCode}): ${data['error']} - attempting refresh...');
        
        final refreshResult = await _refreshTokenAndRetry();
        if (!refreshResult) {
          return ApiResult.error('Authentication failed - please restart the app');
        }

        // Retry with new token
        response = await httpClient.post(
          Uri.parse('$baseUrl/api/tournaments/session'),
          headers: _getHeaders(authToken: playerIdentity.authToken),
          body: json.encode({
            'tournamentId': tournamentId,
            'action': action,
            'playerName': playerIdentity.playerName, // Include current player name
            if (score != null) 'score': score,
            if (gameData != null) 'gameData': gameData,
          }),
        );

        data = json.decode(response.body);
      }

      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResult.success(
          TournamentSessionResult.fromJson(data),
          message: 'Tournament session completed successfully',
        );
      } else {
        return ApiResult.error(data['error'] ?? 'Tournament session failed');
      }
    } catch (e) {
      safePrint('Error in tournament session: $e');
      return ApiResult.error('Network error during tournament session');
    }
  }

  /// Get player's rank in a specific tournament (null if not registered) - DEPRECATED
  /// Use handleTournamentSession with action: 'get_status' instead
  @deprecated
  Future<int?> getPlayerTournamentRank(String tournamentId) async {
    try {
      final result = await handleTournamentSession(
        tournamentId: tournamentId,
        action: 'get_status',
      );
      
      if (result.isSuccess) {
        return result.data?.player.rank;
      }
      
      return null;
    } catch (e) {
      safePrint('Error getting player tournament rank: $e');
      return null;
    }
  }

  /// Get player tournament statistics
  Future<ApiResult<PlayerTournamentStats>> getPlayerStats({
    required String playerId,
    required String authToken,
  }) async {
    try {
      final response = await httpClient.get(
        Uri.parse('$baseUrl/api/tournaments/player/$playerId/stats'),
        headers: _getHeaders(authToken: authToken),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          final stats = PlayerTournamentStats.fromJson(data['stats']);
          return ApiResult.success(stats);
        } else {
          return ApiResult.error(data['error'] ?? 'Failed to fetch stats');
        }
      } else {
        return ApiResult.error('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      safePrint('Error getting player stats: $e');
      return ApiResult.error('Network error: $e');
    }
  }

  /// Get player prize history
  Future<ApiResult<List<PrizeHistoryEntry>>> getPlayerPrizeHistory({
    required String playerId,
    required String authToken,
    int limit = 50,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/tournaments/player/$playerId/prizes')
          .replace(queryParameters: {
        'limit': limit.toString(),
      });

      final response = await httpClient.get(
        uri,
        headers: _getHeaders(authToken: authToken),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          final prizes = (data['prizeHistory'] as List)
              .map((prize) => PrizeHistoryEntry.fromJson(prize))
              .toList();
          
          return ApiResult.success(prizes);
        } else {
          return ApiResult.error(data['error'] ?? 'Failed to fetch prize history');
        }
      } else {
        return ApiResult.error('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      safePrint('Error getting prize history: $e');
      return ApiResult.error('Network error: $e');
    }
  }

  /// Refresh token and retry authentication
  Future<bool> _refreshTokenAndRetry() async {
    try {
      safePrint('🔄 Attempting JWT token refresh...');
      
      // First try proper JWT refresh endpoint
      final playerIdentity = PlayerIdentityManager();
      try {
        await playerIdentity.ensureValidToken();
        // Token refreshed successfully
        safePrint('🔄 ✅ JWT token refreshed successfully');
        return true;
      } catch (e) {
        safePrint('🔄 JWT refresh failed: $e');
        
        // If JWT refresh fails, try full login as fallback
        safePrint('🔄 Attempting full re-authentication...');
        final loginResult = await playerIdentity.authenticatePlayer(playerIdentity.playerName);
        
        if (loginResult) {
          safePrint('🔄 ✅ Re-authentication successful via login');
          return true;
        } else {
          safePrint('🔄 ❌ All authentication methods failed');
          return false;
        }
      }
    } catch (e) {
      safePrint('🔄 ❌ Error during token refresh: $e');
      return false;
    }
  }

  /// Get platform string for authentication
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
      return 'web';
    }
  }

  /// Get common headers for API requests
  Map<String, String> _getHeaders({String? authToken}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    if (authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    
    return headers;
  }

  /// Dispose of resources
  void dispose() {
    httpClient.close();
  }
}

/// Generic API result wrapper
class ApiResult<T> {
  final bool isSuccess;
  final T? data;
  final String? error;
  final String? message;

  const ApiResult._({
    required this.isSuccess,
    this.data,
    this.error,
    this.message,
  });

  factory ApiResult.success(T data, {String? message}) {
    return ApiResult._(
      isSuccess: true,
      data: data,
      message: message,
    );
  }

  factory ApiResult.error(String error) {
    return ApiResult._(
      isSuccess: false,
      error: error,
    );
  }
}

/// Score submission result
class ScoreSubmissionResult {
  final bool newBest;
  final int score;
  final int? previousBest;
  final int? rank;
  final int? totalGames;

  const ScoreSubmissionResult({
    required this.newBest,
    required this.score,
    this.previousBest,
    this.rank,
    this.totalGames,
  });
}

/// Tournament leaderboard response
class TournamentLeaderboardResponse {
  final List<TournamentLeaderboardEntry> entries;
  final TournamentPagination pagination;

  const TournamentLeaderboardResponse({
    required this.entries,
    required this.pagination,
  });
}

/// Pagination information
class TournamentPagination {
  final int limit;
  final int offset;
  final bool hasMore;

  const TournamentPagination({
    required this.limit,
    required this.offset,
    required this.hasMore,
  });

  factory TournamentPagination.fromJson(Map<String, dynamic> json) {
    return TournamentPagination(
      limit: json['limit'],
      offset: json['offset'],
      hasMore: json['hasMore'] ?? false,
    );
  }
}

/// Player tournament statistics
class PlayerTournamentStats {
  final int tournamentsJoined;
  final int? bestRank;
  final int totalPrizes;
  final int? currentTournamentRank;

  const PlayerTournamentStats({
    required this.tournamentsJoined,
    this.bestRank,
    required this.totalPrizes,
    this.currentTournamentRank,
  });

  factory PlayerTournamentStats.fromJson(Map<String, dynamic> json) {
    return PlayerTournamentStats(
      tournamentsJoined: json['tournaments_joined'] ?? 0,
      bestRank: json['best_rank'],
      totalPrizes: json['total_prizes'] ?? 0,
      currentTournamentRank: json['current_tournament_rank'],
    );
  }
}

/// Prize history entry
class PrizeHistoryEntry {
  final String tournamentName;
  final int finalRank;
  final int prizeWon;
  final DateTime endDate;
  final String tournamentType;
  final bool isClaimed;

  const PrizeHistoryEntry({
    required this.tournamentName,
    required this.finalRank,
    required this.prizeWon,
    required this.endDate,
    required this.tournamentType,
    this.isClaimed = false,
  });

  factory PrizeHistoryEntry.fromJson(Map<String, dynamic> json) {
    return PrizeHistoryEntry(
      tournamentName: json['tournament_name'],
      finalRank: json['final_rank'],
      prizeWon: json['prize_won'],
      endDate: DateTime.parse(json['end_date']),
      tournamentType: json['tournament_type'],
      isClaimed: json['is_claimed'] ?? false,
    );
  }
}
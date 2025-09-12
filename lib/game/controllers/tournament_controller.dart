/// 🏆 TOURNAMENT CONTROLLER - Manages all tournament-related functionality
/// Extracted from EnhancedFlappyGame to separate tournament concerns
library;
import '../../core/debug_logger.dart';

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../game/managers/game_state_manager.dart';
import '../../services/tournament_service.dart';
import '../../models/tournament.dart';
import '../../models/tournament_leaderboard_entry.dart';
import '../systems/player_identity_manager.dart';

/// Tournament event types
enum TournamentEvent {
  tournamentStarted,
  tournamentEnded,
  playerJoined,
  scoreSubmitted,
  rankUpdated,
}

/// Tournament controller configuration
class TournamentConfig {
  final Duration scoreSubmissionDelay;
  final bool enableAutoSubmission;
  final int maxRetryAttempts;

  const TournamentConfig({
    this.scoreSubmissionDelay = const Duration(milliseconds: 500),
    this.enableAutoSubmission = true,
    this.maxRetryAttempts = 3,
  });
}

/// 🏆 Tournament Controller - Manages tournament participation and scoring
class TournamentController extends ChangeNotifier {
  final TournamentService _tournamentService;
  final GameStateManager _gameState;
  final PlayerIdentityManager _playerIdentity;
  final TournamentConfig _config;

  // Tournament state
  Tournament? _currentTournament;
  bool _isParticipating = false;
  int _playerRank = 0;
  int _totalParticipants = 0;
  Timer? _scoreSubmissionTimer;

  // Event callbacks
  void Function(TournamentEvent, Map<String, dynamic>)? _onTournamentEvent;

  TournamentController({
    required TournamentService tournamentService,
    required GameStateManager gameState,
    required PlayerIdentityManager playerIdentity,
    TournamentConfig config = const TournamentConfig(),
  }) : _tournamentService = tournamentService,
       _gameState = gameState,
       _playerIdentity = playerIdentity,
       _config = config {
    _initialize();
  }

  /// Set event callback
  void setEventCallback(void Function(TournamentEvent, Map<String, dynamic>)? callback) {
    _onTournamentEvent = callback;
  }

  /// Get current tournament
  Tournament? get currentTournament => _currentTournament;

  /// Check if player is participating
  bool get isParticipating => _isParticipating;

  /// Get player's current rank
  int get playerRank => _playerRank;

  /// Get total participants
  int get totalParticipants => _totalParticipants;

  /// Initialize tournament controller
  Future<void> _initialize() async {
    await _loadCurrentTournament();
    _setupGameStateListeners();
  }

  /// Load current active tournament
  Future<void> _loadCurrentTournament() async {
    try {
      final result = await _tournamentService.getCurrentTournament();

      if (result.isSuccess && result.data != null) {
        _currentTournament = result.data;
        safePrint('🏆 Loaded current tournament: ${_currentTournament!.name}');

        // Check if player is already participating
        await _checkParticipationStatus();

        _notifyEvent(TournamentEvent.tournamentStarted, {
          'tournament': _currentTournament!.toJson(),
        });
      } else {
        safePrint('ℹ️ No active tournament available');
      }
    } catch (e) {
      safePrint('⚠️ Failed to load current tournament: $e');
    }
  }

  /// Check if player is participating in current tournament
  Future<void> _checkParticipationStatus() async {
    if (_currentTournament == null || !_playerIdentity.isBackendRegistered) {
      _isParticipating = false;
      return;
    }

    try {
      // Check player's rank to determine participation
      final rankResult = await _tournamentService.getPlayerTournamentRank(_currentTournament!.id);

      if (rankResult != null) {
        _isParticipating = true;
        _playerRank = rankResult;
        safePrint('🏆 Player is participating in tournament (Rank: $_playerRank)');
      } else {
        _isParticipating = false;
        safePrint('🏆 Player is not participating in tournament');
      }
    } catch (e) {
      safePrint('⚠️ Failed to check participation status: $e');
      _isParticipating = false;
    }

    notifyListeners();
  }

  /// Join current tournament
  Future<bool> joinTournament() async {
    if (_currentTournament == null) {
      safePrint('⚠️ No active tournament to join');
      return false;
    }

    if (!_playerIdentity.isBackendRegistered) {
      safePrint('⚠️ Player not registered with backend');
      return false;
    }

    if (_isParticipating) {
      safePrint('ℹ️ Already participating in tournament');
      return true;
    }

    try {
      // Register for tournament using real JWT token
      final authToken = _playerIdentity.authToken;
      
      if (authToken.isEmpty) {
        safePrint('⚠️ No valid auth token available for tournament registration');
        return false;
      }
      
      final registerResult = await _tournamentService.registerForTournament(
        tournamentId: _currentTournament!.id,
        playerName: _playerIdentity.playerName,
        authToken: authToken,
      );

      if (registerResult.isSuccess) {
        _isParticipating = true;
        _playerRank = (registerResult.data as int?) ?? 0;

        safePrint('🏆 Successfully joined tournament: ${_currentTournament!.name}');

        _notifyEvent(TournamentEvent.playerJoined, {
          'tournamentId': _currentTournament!.id,
          'playerRank': _playerRank,
        });

        notifyListeners();
        return true;
      } else {
        safePrint('⚠️ Failed to join tournament: ${registerResult.error}');
        return false;
      }
    } catch (e) {
      safePrint('⚠️ Error joining tournament: $e');
      return false;
    }
  }

  /// Submit score to tournament
  Future<bool> submitScore({
    required int score,
    required String theme,
    required String jetSkin,
    Map<String, dynamic>? gameData,
  }) async {
    if (!_isParticipating || _currentTournament == null) {
      safePrint('⚠️ Not participating in tournament or no active tournament');
      return false;
    }

    try {
      // Prepare comprehensive game data
      final comprehensiveGameData = {
        'survivalTime': _gameState.stats.gameDurationSeconds,
        'theme': theme,
        'jetSkin': jetSkin,
        'coinsEarned': score,
        'continuesUsed': _gameState.stats.continuesUsedThisRun,
        'sessionLength': _gameState.stats.gameDurationSeconds,
        'gameVersion': '1.0.0',
        'platform': 'mobile',
        'livesUsed': _gameState.stats.continuesUsedThisRun,
        'scoreMultiplier': 1.0,
        ...?gameData,
      };

      // Use real JWT token from PlayerIdentityManager - don't fall back to temp tokens
      final authToken = _playerIdentity.authToken;
      
      if (authToken.isEmpty) {
        safePrint('⚠️ No valid auth token available for tournament submission');
        return false;
      }

      // Submit score with delay to prevent spam
      if (_config.scoreSubmissionDelay > Duration.zero) {
        await Future.delayed(_config.scoreSubmissionDelay);
      }

      final submitResult = await _tournamentService.submitScore(
        tournamentId: _currentTournament!.id,
        score: score,
        authToken: authToken,
        gameData: comprehensiveGameData,
      );

      if (submitResult.isSuccess) {
        // Update player's rank
        final newRank = submitResult.data?.rank ?? _playerRank;
        if (newRank != _playerRank) {
          _playerRank = newRank;
          notifyListeners();

          _notifyEvent(TournamentEvent.rankUpdated, {
            'oldRank': _playerRank,
            'newRank': newRank,
            'score': score,
          });
        }

        safePrint('🏆 Score submitted to tournament: ${_currentTournament!.name} (Score: $score, Rank: $newRank)');

        _notifyEvent(TournamentEvent.scoreSubmitted, {
          'tournamentId': _currentTournament!.id,
          'score': score,
          'rank': newRank,
          'gameData': comprehensiveGameData,
        });

        return true;
      } else {
        safePrint('⚠️ Failed to submit score: ${submitResult.error}');
        return false;
      }
    } catch (e) {
      safePrint('⚠️ Error submitting score: $e');
      return false;
    }
  }

  /// Get tournament leaderboard
  Future<List<TournamentLeaderboardEntry>?> getTournamentLeaderboard({
    int limit = 50,
    int offset = 0,
  }) async {
    if (_currentTournament == null) {
      return null;
    }

    try {
      final result = await _tournamentService.getTournamentLeaderboard(
        tournamentId: _currentTournament!.id,
        limit: limit,
        offset: offset,
      );

      if (result.isSuccess && result.data != null) {
        _totalParticipants = result.data!.entries.length; // Use entries count instead of totalCount
        notifyListeners();
        return result.data!.entries;
      }

      return null;
    } catch (e) {
      safePrint('⚠️ Error getting tournament leaderboard: $e');
      return null;
    }
  }

  /// Auto-submit score when game ends (if enabled)
  void onGameEnded(int finalScore, String theme, String jetSkin) {
    if (!_config.enableAutoSubmission) {
      return;
    }

    // Cancel any pending submission
    _scoreSubmissionTimer?.cancel();

    // Submit score after a short delay
    _scoreSubmissionTimer = Timer(const Duration(seconds: 2), () async {
      if (_isParticipating && _currentTournament != null) {
        await submitScore(
          score: finalScore,
          theme: theme,
          jetSkin: jetSkin,
          gameData: {
            'gameResult': 'completed',
            'finalScore': finalScore,
            'duration': _gameState.stats.gameDurationSeconds,
          },
        );
      }
    });
  }

  /// Handle tournament end
  void onTournamentEnded() {
    safePrint('🏆 Tournament ended: ${_currentTournament?.name}');

    _notifyEvent(TournamentEvent.tournamentEnded, {
      'tournamentId': _currentTournament?.id,
      'finalRank': _playerRank,
    });

    // Reset participation status
    _isParticipating = false;
    _playerRank = 0;
    notifyListeners();
  }

  /// Setup game state listeners
  void _setupGameStateListeners() {
    // Listen to game state changes
    _gameState.addListener(() {
      final state = _gameState.currentState;

      // Auto-submit score when game ends
      if (state == GameState.gameOver && _isParticipating) {
        onGameEnded(
          _gameState.stats.score,
          _gameState.stats.currentTheme,
          'jets/sky_jet.png', // Default jet skin
        );
      }
    });
  }

  /// Check if tournament is still active
  bool get isTournamentActive {
    if (_currentTournament == null) return false;

    final now = DateTime.now();
    return now.isAfter(_currentTournament!.startDate) &&
           now.isBefore(_currentTournament!.endDate);
  }

  /// Get tournament time remaining
  Duration getTournamentTimeRemaining() {
    if (_currentTournament == null) return Duration.zero;

    final now = DateTime.now();
    final endTime = _currentTournament!.endDate;

    if (now.isAfter(endTime)) return Duration.zero;

    return endTime.difference(now);
  }

  /// Force refresh tournament data
  Future<void> refreshTournamentData() async {
    await _loadCurrentTournament();
  }

  /// Get tournament statistics
  Map<String, dynamic> getTournamentStats() => {
        'isParticipating': _isParticipating,
        'playerRank': _playerRank,
        'totalParticipants': _totalParticipants,
        'tournamentName': _currentTournament?.name ?? 'None',
        'timeRemaining': getTournamentTimeRemaining().inSeconds,
        'isActive': isTournamentActive,
      };

  /// Notify event listeners
  void _notifyEvent(TournamentEvent event, Map<String, dynamic> data) {
    _onTournamentEvent?.call(event, data);
  }

  /// Reset tournament state
  void reset() {
    _scoreSubmissionTimer?.cancel();
    _scoreSubmissionTimer = null;
    _isParticipating = false;
    _playerRank = 0;
    _totalParticipants = 0;
  }

  /// Dispose of resources
  @override
  void dispose() {
    _scoreSubmissionTimer?.cancel();
    _scoreSubmissionTimer = null;
    reset();
    safePrint('🏆 TournamentController disposed');
    super.dispose(); // Call super.dispose() as required by @mustCallSuper
  }
}
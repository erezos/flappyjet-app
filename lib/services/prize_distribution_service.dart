import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flappy_jet_pro/game/systems/inventory_manager.dart';
import 'package:flappy_jet_pro/services/tournament_service.dart';
import 'package:flappy_jet_pro/models/tournament.dart';
import 'package:flappy_jet_pro/game/core/error_handler.dart';
import '../core/debug_logger.dart';

/// 🎁 Prize Distribution Service - Modern Tournament Prize Claim System
///
/// This service implements a comprehensive prize distribution system with:
/// - Real-time notifications for tournament results
/// - Active prize claiming with celebration animations
/// - Progressive disclosure UX patterns
/// - Social proof and engagement features
///
/// Based on mobile gaming best practices for maximum user engagement.

class PrizeDistributionService extends ChangeNotifier {
  final String baseUrl;
  final TournamentService tournamentService;
  final InventoryManager inventoryManager;
  final http.Client _httpClient;

  // Service state
  bool _isLoading = false;
  String? _errorMessage;
  final List<PrizeNotification> _pendingNotifications = [];
  StreamSubscription? _tournamentUpdatesSubscription;

  PrizeDistributionService({
    required this.baseUrl,
    required this.tournamentService,
    required this.inventoryManager,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client() {
    _initializeService();
  }

  /// Initialize the prize distribution service
  void _initializeService() {
    safePrint('🎁 Initializing Prize Distribution Service...');

    // Listen for tournament updates
    _setupTournamentUpdatesListener();

    safePrint('🎁 Prize Distribution Service initialized');
  }

  /// Setup real-time tournament updates listener
  void _setupTournamentUpdatesListener() {
    // This would connect to WebSocket for real-time updates
    // For now, we'll implement polling-based updates
    Timer.periodic(const Duration(seconds: 30), (_) {
      _checkForTournamentUpdates();
    });
  }

  /// Check for tournament updates (prizes available, etc.)
  Future<void> _checkForTournamentUpdates() async {
    try {
      // Get current tournament status
      final tournamentResult = await tournamentService.getCurrentTournament();

      if (tournamentResult.isSuccess && tournamentResult.data != null) {
        final tournament = tournamentResult.data!;

        // Check if tournament has ended
        if (tournament.status == 'ended') {
          await _handleTournamentEnded(tournament);
        } else if (tournament.status == 'active' &&
                   tournament.timeRemaining != null &&
                   tournament.timeRemaining!.inMinutes < 30) {
          // Tournament ending soon - show anticipation
          _showTournamentEndingSoonNotification(tournament);
        }
      }
    } catch (error, stackTrace) {
      ErrorHandler.handleError(
        error,
        stackTrace,
        context: 'tournament_updates_check',
        severity: ErrorSeverity.medium,
      );
    }
  }

  /// Handle tournament ended event
  Future<void> _handleTournamentEnded(Tournament tournament) async {
    try {
      // Check if user has a prize in this tournament
      final prizeHistoryResult = await tournamentService.getPlayerPrizeHistory(
        playerId: inventoryManager.playerId ?? 'unknown',
        authToken: inventoryManager.authToken ?? '',
      );

      if (prizeHistoryResult.isSuccess && prizeHistoryResult.data != null) {
        final prizeHistory = prizeHistoryResult.data!;

        // Find unclaimed prize for this tournament
        final unclaimedPrize = prizeHistory.cast<PrizeHistoryEntry?>().firstWhere(
          (prize) =>
            prize != null &&
            prize.tournamentName == tournament.name &&
            !prize.isClaimed,
          orElse: () => null,
        );

        // Create prize notification if unclaimed prize exists
        if (unclaimedPrize != null) {
          final notification = PrizeNotification(
            id: 'prize_${tournament.id}_${DateTime.now().millisecondsSinceEpoch}',
            tournamentId: tournament.id,
            tournamentName: tournament.name,
            finalRank: unclaimedPrize.finalRank,
            prizeAmount: unclaimedPrize.prizeWon,
            endDate: unclaimedPrize.endDate,
            createdAt: DateTime.now(),
          );

          _pendingNotifications.add(notification);
          notifyListeners();
          
          // Show push notification
          _showPrizeAvailableNotification(notification);
        }
      }
    } catch (error, stackTrace) {
      ErrorHandler.handleError(
        error,
        stackTrace,
        context: 'tournament_ended_handling',
        severity: ErrorSeverity.high,
      );
    }
  }

  /// Show notification when tournament is ending soon
  void _showTournamentEndingSoonNotification(Tournament tournament) {
    TournamentEndingNotification(
      tournamentId: tournament.id,
      tournamentName: tournament.name,
      timeRemaining: tournament.timeRemaining!,
      prizePool: tournament.prizePool,
      createdAt: DateTime.now(),
    );

    // This would trigger UI notification
    safePrint('⏰ Tournament ending soon: ${tournament.name}');
  }

  /// Show prize available notification
  void _showPrizeAvailableNotification(PrizeNotification notification) {
    safePrint('🎁 Prize available! ${notification.prizeAmount} coins from ${notification.tournamentName}');

    // This would trigger:
    // 1. Push notification
    // 2. In-app badge
    // 3. Celebration animation
  }

  /// Claim a prize with celebration
  Future<PrizeClaimResult> claimPrize({
    required String tournamentId,
    required String authToken,
  }) async {
    if (_isLoading) {
      return PrizeClaimResult.error('Already processing a claim');
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Call backend to claim prize
      final response = await _httpClient.post(
        Uri.parse('$baseUrl/api/tournaments/$tournamentId/claim-prize'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          final prizeAmount = data['prizeAmount'] as int;

          // Add coins to inventory with animation
          await inventoryManager.addCoinsWithAnimation(prizeAmount);

          // Remove notification from pending list
          _pendingNotifications.removeWhere((n) => n.tournamentId == tournamentId);
          notifyListeners();

          safePrint('✅ Prize claimed successfully: $prizeAmount coins');

          return PrizeClaimResult.success(
            prizeAmount: prizeAmount,
            message: data['message'] ?? 'Prize claimed successfully!',
          );
        } else {
          return PrizeClaimResult.error(data['error'] ?? 'Failed to claim prize');
        }
      } else {
        return PrizeClaimResult.error('HTTP ${response.statusCode}: Failed to claim prize');
      }
    } catch (error, stackTrace) {
      ErrorHandler.handleError(
        error,
        stackTrace,
        context: 'prize_claim',
        severity: ErrorSeverity.high,
      );

      return PrizeClaimResult.error('Network error: $error');
    } finally {
      _isLoading = true;
      notifyListeners();
    }
  }

  /// Get pending prize notifications
  List<PrizeNotification> get pendingNotifications => _pendingNotifications;

  /// Check if user has unclaimed prizes
  bool get hasUnclaimedPrizes => _pendingNotifications.isNotEmpty;

  /// Get total unclaimed prize amount
  int get totalUnclaimedAmount {
    return _pendingNotifications.fold(0, (sum, notification) => sum + notification.prizeAmount);
  }

  /// Clear all notifications (for testing)
  void clearNotifications() {
    _pendingNotifications.clear();
    notifyListeners();
  }

  /// Dispose resources
  @override
  void dispose() {
    _tournamentUpdatesSubscription?.cancel();
    _httpClient.close();
    super.dispose();
  }

  // Getters for UI state
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
}

/// Prize notification model
class PrizeNotification {
  final String id;
  final String tournamentId;
  final String tournamentName;
  final int finalRank;
  final int prizeAmount;
  final DateTime endDate;
  final DateTime createdAt;

  const PrizeNotification({
    required this.id,
    required this.tournamentId,
    required this.tournamentName,
    required this.finalRank,
    required this.prizeAmount,
    required this.endDate,
    required this.createdAt,
  });

  /// Get rank display text
  String get rankDisplay {
    switch (finalRank) {
      case 1:
        return '🥇 1st Place';
      case 2:
        return '🥈 2nd Place';
      case 3:
        return '🥉 3rd Place';
      default:
        return '${finalRank}th Place';
    }
  }

  /// Get celebration color based on rank
  String get celebrationColor {
    switch (finalRank) {
      case 1:
        return 'gold';
      case 2:
        return 'silver';
      case 3:
        return 'bronze';
      default:
        return 'blue';
    }
  }
}

/// Tournament ending notification
class TournamentEndingNotification {
  final String tournamentId;
  final String tournamentName;
  final Duration timeRemaining;
  final int prizePool;
  final DateTime createdAt;

  const TournamentEndingNotification({
    required this.tournamentId,
    required this.tournamentName,
    required this.timeRemaining,
    required this.prizePool,
    required this.createdAt,
  });
}

/// Prize claim result
class PrizeClaimResult {
  final bool isSuccess;
  final int? prizeAmount;
  final String? error;
  final String? message;

  const PrizeClaimResult._({
    required this.isSuccess,
    this.prizeAmount,
    this.error,
    this.message,
  });

  factory PrizeClaimResult.success({
    required int prizeAmount,
    required String message,
  }) {
    return PrizeClaimResult._(
      isSuccess: true,
      prizeAmount: prizeAmount,
      message: message,
    );
  }

  factory PrizeClaimResult.error(String error) {
    return PrizeClaimResult._(
      isSuccess: false,
      error: error,
    );
  }
}
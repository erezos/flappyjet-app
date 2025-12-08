/// 🏆 Tournament Manager
/// 
/// State management for tournaments using client-only architecture.
/// Local state (SharedPreferences) is the source of truth.
/// Backend events are async, non-blocking for analytics only.
/// 
/// Phase 1: Foundation
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/tournament_config.dart';
import '../../models/tournament_entry.dart';
import '../../core/debug_logger.dart';
import '../../core/events/event_bus.dart';

/// Tournament Manager - Singleton pattern for consistent state
class TournamentManager extends ChangeNotifier {
  // ✅ SINGLETON PATTERN - Ensures all code uses the same instance
  static final TournamentManager _instance = TournamentManager._internal();
  factory TournamentManager() => _instance;
  TournamentManager._internal();

  // SharedPreferences keys
  static const String _keyAvailableTournaments = 'tournaments_available';
  static const String _keyActiveEntry = 'tournaments_active_entry';
  static const String _keyCompletedTournaments = 'tournaments_completed';
  static const String _keyFreeTickets = 'tournaments_free_tickets';
  static const String _keyTournamentHistory = 'tournaments_history';
  static const String _keyLastRefresh = 'tournaments_last_refresh';

  // State
  List<TournamentConfig> _availableTournaments = [];
  TournamentEntry? _activeEntry;
  Set<String> _completedTournamentIds = {};
  Map<String, int> _freeTickets = {}; // tier -> count
  List<TournamentHistoryEntry> _history = [];
  bool _isInitialized = false;
  DateTime? _lastRefresh;

  // Getters
  List<TournamentConfig> get availableTournaments => _availableTournaments;
  TournamentEntry? get activeEntry => _activeEntry;
  bool get hasActiveEntry => _activeEntry != null && _activeEntry!.status.isActive;
  bool get isInitialized => _isInitialized;
  Set<String> get completedTournamentIds => _completedTournamentIds;
  List<TournamentHistoryEntry> get history => _history;

  /// Get available tournaments for display (active status only)
  List<TournamentConfig> get displayableTournaments =>
      _availableTournaments.where((t) => 
        t.status == TournamentStatus.active || 
        t.status == TournamentStatus.upcoming
      ).toList();

  /// Get count of free tickets for a specific tier
  int getFreeTickets(TournamentTier tier) => _freeTickets[tier.name] ?? 0;

  /// Get total free tickets across all tiers
  int get totalFreeTickets => 
      _freeTickets.values.fold(0, (sum, count) => sum + count);

  /// Check if player has a free ticket for a specific tournament
  bool hasFreeTicketFor(TournamentConfig tournament) =>
      getFreeTickets(tournament.tier) > 0;

  // ============================================================================
  // 🎯 INITIALIZATION
  // ============================================================================

  /// Initialize the tournament manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    safePrint('🏆 TournamentManager: Initializing...');
    
    try {
      // Load all persisted state
      await _loadState();
      
      // Load tournament configs (from assets or remote config)
      await _loadTournamentConfigs();

      _isInitialized = true;
      notifyListeners();
      
      safePrint('🏆 TournamentManager: Initialized with ${_availableTournaments.length} tournaments');
      
      // Fire initialization event (async, non-blocking)
      _fireEvent('tournament_manager_initialized', {
        'available_count': _availableTournaments.length,
        'has_active_entry': hasActiveEntry,
        'total_free_tickets': totalFreeTickets,
      });
    } catch (e) {
      safePrint('🏆 ❌ TournamentManager initialization failed: $e');
      _isInitialized = true; // Mark as initialized even on error to prevent retry loops
    }
  }

  /// Load persisted state from SharedPreferences
  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();

    // Load active entry
    final activeEntryJson = prefs.getString(_keyActiveEntry);
    if (activeEntryJson != null) {
      try {
        _activeEntry = TournamentEntry.fromJsonString(activeEntryJson);
        safePrint('🏆 Loaded active entry: ${_activeEntry?.tournamentName}');
      } catch (e) {
        safePrint('🏆 ⚠️ Failed to load active entry: $e');
        _activeEntry = null;
      }
    }

    // Load completed tournament IDs
    final completedList = prefs.getStringList(_keyCompletedTournaments) ?? [];
    _completedTournamentIds = completedList.toSet();

    // Load free tickets
    final ticketsJson = prefs.getString(_keyFreeTickets);
    if (ticketsJson != null) {
      try {
        final decoded = jsonDecode(ticketsJson) as Map<String, dynamic>;
        _freeTickets = decoded.map((k, v) => MapEntry(k, v as int));
      } catch (e) {
        safePrint('🏆 ⚠️ Failed to load free tickets: $e');
        _freeTickets = {};
      }
    }

    // Load history
    final historyJson = prefs.getString(_keyTournamentHistory);
    if (historyJson != null) {
      try {
        final decoded = jsonDecode(historyJson) as List<dynamic>;
        _history = decoded
            .map((e) => TournamentHistoryEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        safePrint('🏆 ⚠️ Failed to load history: $e');
        _history = [];
      }
    }

    // Load last refresh time
    final lastRefreshMs = prefs.getInt(_keyLastRefresh) ?? 0;
    _lastRefresh = lastRefreshMs > 0 
        ? DateTime.fromMillisecondsSinceEpoch(lastRefreshMs) 
        : null;
  }

  /// Load tournament configurations from assets
  Future<void> _loadTournamentConfigs() async {
    try {
      // Load from local JSON file (can be extended to Remote Config later)
      _availableTournaments = await TournamentConfig.loadAllTournaments();
      safePrint('🏆 Loaded ${_availableTournaments.length} tournament configs');
    } catch (e) {
      safePrint('🏆 ❌ Failed to load tournament configs: $e');
      _availableTournaments = [];
    }
  }

  // ============================================================================
  // 🎮 TOURNAMENT ENTRY & LIFECYCLE
  // ============================================================================

  /// Check if player can enter a tournament
  CanEnterResult canEnterTournament(
    TournamentConfig tournament, {
    required int playerCoins,
    required int playerGems,
  }) {
    // Check if already has an active entry in THIS tournament
    if (hasActiveEntry && _activeEntry!.tournamentId == tournament.id) {
      return CanEnterResult(
        canEnter: false,
        reason: 'Already in progress',
        hasActiveEntry: true,
      );
    }

    // Check if has free ticket
    if (hasFreeTicketFor(tournament)) {
      return CanEnterResult(
        canEnter: true,
        reason: 'Free ticket available',
        useFreeTicket: true,
        freeTicketTier: tournament.tier,
      );
    }

    // Check currency
    switch (tournament.entry.type) {
      case EntryFeeType.coins:
        if (playerCoins >= tournament.entry.amount) {
          return CanEnterResult(
            canEnter: true,
            reason: 'Sufficient coins',
            cost: tournament.entry.amount,
            costType: EntryFeeType.coins,
          );
        }
        return CanEnterResult(
          canEnter: false,
          reason: 'Not enough coins (need ${tournament.entry.amount})',
        );

      case EntryFeeType.gems:
        if (playerGems >= tournament.entry.amount) {
          return CanEnterResult(
            canEnter: true,
            reason: 'Sufficient gems',
            cost: tournament.entry.amount,
            costType: EntryFeeType.gems,
          );
        }
        return CanEnterResult(
          canEnter: false,
          reason: 'Not enough gems (need ${tournament.entry.amount})',
        );

      case EntryFeeType.freeTicket:
        return CanEnterResult(
          canEnter: hasFreeTicketFor(tournament),
          reason: hasFreeTicketFor(tournament) 
              ? 'Free ticket available' 
              : 'Free ticket required',
          useFreeTicket: true,
          freeTicketTier: tournament.tier,
        );
    }
  }

  /// Enter a tournament (deducts cost, creates entry)
  /// Returns the entry if successful, null otherwise
  /// Note: Cost deduction should be handled by the caller (InventoryManager)
  Future<TournamentEntry?> enterTournament(
    TournamentConfig tournament, {
    required bool useFreeTicket,
  }) async {
    if (hasActiveEntry && _activeEntry!.tournamentId == tournament.id) {
      safePrint('🏆 ⚠️ Already have active entry for ${tournament.name}');
      return _activeEntry;
    }

    // Use free ticket if applicable
    if (useFreeTicket) {
      if (!hasFreeTicketFor(tournament)) {
        safePrint('🏆 ❌ No free ticket available for ${tournament.name}');
        return null;
      }
      await _useFreeTicket(tournament.tier);
    }

    // Create new entry
    _activeEntry = TournamentEntry.start(
      tournamentId: tournament.id,
      tournamentName: tournament.name,
      totalTries: tournament.tries.count,
    );

    await _saveActiveEntry();
    notifyListeners();

    safePrint('🏆 ✅ Entered tournament: ${tournament.name}');

    // Fire event (async, non-blocking)
    _fireEvent('tournament_entered', {
      'tournament_id': tournament.id,
      'tournament_name': tournament.name,
      'tournament_tier': tournament.tier.name,
      'entry_type': useFreeTicket ? 'free_ticket' : tournament.entry.type.name,
      'entry_cost': useFreeTicket ? 0 : tournament.entry.amount,
      'total_tries': tournament.tries.count,
    });

    return _activeEntry;
  }

  /// Resume active entry (continue where left off)
  TournamentEntry? resumeActiveEntry() {
    if (!hasActiveEntry) {
      safePrint('🏆 ⚠️ No active entry to resume');
      return null;
    }
    
    safePrint('🏆 Resuming tournament: ${_activeEntry!.tournamentName}');
    return _activeEntry;
  }

  /// Complete a round successfully
  Future<void> completeRound({
    required int roundNumber,
    required int coinsReward,
    required int gemsReward,
    required int heartsUsed,
    required int continuesUsed,
    required Duration duration,
  }) async {
    if (!hasActiveEntry) {
      safePrint('🏆 ⚠️ No active entry to update');
      return;
    }

    _activeEntry!.completeRound(
      roundNumber: roundNumber,
      coinsReward: coinsReward,
      gemsReward: gemsReward,
      heartsUsed: heartsUsed,
      continuesUsed: continuesUsed,
      duration: duration,
    );

    await _saveActiveEntry();
    notifyListeners();

    safePrint('🏆 ✅ Round $roundNumber completed');

    // Fire event
    _fireEvent('tournament_round_completed', {
      'tournament_id': _activeEntry!.tournamentId,
      'round_number': roundNumber,
      'try_number': _activeEntry!.currentTry,
      'coins_earned': coinsReward,
      'gems_earned': gemsReward,
      'hearts_used': heartsUsed,
      'continues_used': continuesUsed,
      'duration_seconds': duration.inSeconds,
    });
  }

  /// Fail current round (ran out of hearts and continues)
  Future<void> failRound({
    required int roundNumber,
    required int heartsUsed,
    required int continuesUsed,
    required Duration duration,
  }) async {
    if (!hasActiveEntry) return;

    _activeEntry!.failRound(
      roundNumber: roundNumber,
      heartsUsed: heartsUsed,
      continuesUsed: continuesUsed,
      duration: duration,
    );

    await _saveActiveEntry();
    notifyListeners();

    safePrint('🏆 ❌ Round $roundNumber failed');

    // Fire event
    _fireEvent('tournament_round_failed', {
      'tournament_id': _activeEntry!.tournamentId,
      'round_number': roundNumber,
      'try_number': _activeEntry!.currentTry,
      'hearts_used': heartsUsed,
      'continues_used': continuesUsed,
      'duration_seconds': duration.inSeconds,
    });
  }

  /// Advance the active entry to the next round (persists + notifies).
  /// Used by playoff flow to move from Quarter→Semi→Finals after a win.
  Future<void> advanceToNextRound() async {
    if (!hasActiveEntry) return;

    final nextRound = _activeEntry!.currentRound + 1;
    _activeEntry!.startRound(nextRound);

    await _saveActiveEntry();
    notifyListeners();

    safePrint('🏆 ➡️ Advanced to round $nextRound');

    _fireEvent('tournament_round_advanced', {
      'tournament_id': _activeEntry!.tournamentId,
      'round_number': nextRound,
      'try_number': _activeEntry!.currentTry,
    });
  }

  /// Use a continue (respawn with full hearts)
  Future<void> useContinue() async {
    if (!hasActiveEntry) return;

    _activeEntry!.useContinue();
    await _saveActiveEntry();
    notifyListeners();

    safePrint('🏆 Continue used (${_activeEntry!.continuesUsedThisTry} this try)');

    // Fire event
    _fireEvent('tournament_continue_used', {
      'tournament_id': _activeEntry!.tournamentId,
      'round_number': _activeEntry!.currentRound,
      'try_number': _activeEntry!.currentTry,
      'continues_this_try': _activeEntry!.continuesUsedThisTry,
      'total_continues': _activeEntry!.totalContinuesUsed,
    });
  }

  /// Fail current try (moves to next try or fails tournament)
  Future<TournamentEntryStatus> failCurrentTry() async {
    if (!hasActiveEntry) return TournamentEntryStatus.failed;

    final previousStatus = _activeEntry!.status;
    _activeEntry!.failCurrentTry();
    
    await _saveActiveEntry();
    notifyListeners();

    final newStatus = _activeEntry!.status;
    safePrint('🏆 Try failed. Status: ${newStatus.name}, Tries remaining: ${_activeEntry!.triesRemaining}');

    // Fire event
    _fireEvent('tournament_try_failed', {
      'tournament_id': _activeEntry!.tournamentId,
      'try_number': _activeEntry!.currentTry - 1, // Previous try
      'tries_remaining': _activeEntry!.triesRemaining,
      'highest_round': _activeEntry!.highestRoundReached,
      'total_coins_earned': _activeEntry!.coinsEarned,
      'total_gems_earned': _activeEntry!.gemsEarned,
      'tournament_failed': newStatus == TournamentEntryStatus.failed,
    });

    // If tournament failed, add to history
    if (newStatus == TournamentEntryStatus.failed && previousStatus != newStatus) {
      await _addToHistory(_activeEntry!, false);
    }

    return newStatus;
  }

  /// Complete the tournament successfully
  /// Returns the completion reward for the caller to process
  Future<TournamentReward?> completeTournament({
    required int bonusCoins,
    required int bonusGems,
    TournamentReward? completionReward,
  }) async {
    if (!hasActiveEntry) return null;

    _activeEntry!.completeTournament(
      bonusCoins: bonusCoins,
      bonusGems: bonusGems,
    );

    // Mark as completed
    _completedTournamentIds.add(_activeEntry!.tournamentId);
    
    await _saveActiveEntry();
    await _saveCompletedTournaments();
    await _addToHistory(_activeEntry!, true);
    
    // Award free ticket if part of reward
    if (completionReward?.freeTicketTier != null) {
      await grantFreeTicket(completionReward!.freeTicketTier!);
      safePrint('🏆 🎫 Awarded free ticket for ${completionReward.freeTicketTier!.displayName} tier');
    }
    
    notifyListeners();

    safePrint('🏆 🎉 Tournament completed! Earned ${_activeEntry!.coinsEarned} coins, ${_activeEntry!.gemsEarned} gems');

    // Fire event with full reward details
    _fireEvent('tournament_completed', {
      'tournament_id': _activeEntry!.tournamentId,
      'tournament_name': _activeEntry!.tournamentName,
      'tries_used': _activeEntry!.currentTry,
      'total_continues': _activeEntry!.totalContinuesUsed,
      'coins_earned': _activeEntry!.coinsEarned,
      'gems_earned': _activeEntry!.gemsEarned,
      'duration_seconds': _activeEntry!.duration.inSeconds,
      'success_rate': _activeEntry!.successRate,
      'skin_reward': completionReward?.skinId,
      'free_ticket_tier': completionReward?.freeTicketTier?.name,
      'booster_type': completionReward?.booster?.type.name,
      'booster_duration': completionReward?.booster?.durationHours,
    });
    
    return completionReward;
  }

  /// Abandon the tournament (user quits)
  Future<void> abandonTournament() async {
    if (!hasActiveEntry) return;

    _activeEntry!.abandon();
    
    await _saveActiveEntry();
    await _addToHistory(_activeEntry!, false);
    
    notifyListeners();

    safePrint('🏆 Tournament abandoned: ${_activeEntry!.tournamentName}');

    // Fire event
    _fireEvent('tournament_abandoned', {
      'tournament_id': _activeEntry!.tournamentId,
      'tournament_name': _activeEntry!.tournamentName,
      'current_try': _activeEntry!.currentTry,
      'highest_round': _activeEntry!.highestRoundReached,
      'coins_earned': _activeEntry!.coinsEarned,
      'gems_earned': _activeEntry!.gemsEarned,
    });
  }

  /// Clear active entry (after claiming rewards or abandoning)
  Future<void> clearActiveEntry() async {
    _activeEntry = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyActiveEntry);
    
    notifyListeners();
    safePrint('🏆 Active entry cleared');
  }

  // ============================================================================
  // 🎫 FREE TICKETS
  // ============================================================================

  /// Grant a free ticket for a tier
  Future<void> grantFreeTicket(TournamentTier tier, {int count = 1}) async {
    _freeTickets[tier.name] = (_freeTickets[tier.name] ?? 0) + count;
    await _saveFreeTickets();
    notifyListeners();

    safePrint('🏆 🎫 Granted $count free ticket(s) for ${tier.displayName}');

    // Fire event
    _fireEvent('tournament_ticket_granted', {
      'tier': tier.name,
      'count': count,
      'total_for_tier': _freeTickets[tier.name],
    });
  }

  /// Use a free ticket
  Future<void> _useFreeTicket(TournamentTier tier) async {
    if ((_freeTickets[tier.name] ?? 0) <= 0) {
      throw StateError('No free tickets for tier ${tier.name}');
    }
    
    _freeTickets[tier.name] = _freeTickets[tier.name]! - 1;
    await _saveFreeTickets();

    safePrint('🏆 🎫 Used free ticket for ${tier.displayName}');

    // Fire event
    _fireEvent('tournament_ticket_used', {
      'tier': tier.name,
      'remaining_for_tier': _freeTickets[tier.name],
    });
  }

  // ============================================================================
  // 🎁 SPECIAL DEALS
  // ============================================================================

  /// Purchase extra tries (from special deal after losing all tries)
  Future<bool> purchaseExtraTries({
    required int extraTries,
    required int cost,
    required EntryFeeType costType,
  }) async {
    // Check for a failed entry (note: hasActiveEntry returns false for failed entries,
    // so we check _activeEntry directly)
    if (_activeEntry == null || _activeEntry!.status != TournamentEntryStatus.failed) {
      safePrint('🏆 ⚠️ Cannot purchase extra tries - no failed entry');
      return false;
    }

    _activeEntry!.addExtraTries(extraTries);
    await _saveActiveEntry();
    notifyListeners();

    safePrint('🏆 ✅ Purchased $extraTries extra tries');

    // Fire event
    _fireEvent('tournament_extra_tries_purchased', {
      'tournament_id': _activeEntry!.tournamentId,
      'extra_tries': extraTries,
      'cost': cost,
      'cost_type': costType.name,
      'new_tries_remaining': _activeEntry!.triesRemaining,
    });

    return true;
  }

  // ============================================================================
  // 💾 PERSISTENCE
  // ============================================================================

  Future<void> _saveActiveEntry() async {
    final prefs = await SharedPreferences.getInstance();
    if (_activeEntry != null) {
      await prefs.setString(_keyActiveEntry, _activeEntry!.toJsonString());
    } else {
      await prefs.remove(_keyActiveEntry);
    }
  }

  Future<void> _saveCompletedTournaments() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyCompletedTournaments, _completedTournamentIds.toList());
  }

  Future<void> _saveFreeTickets() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFreeTickets, jsonEncode(_freeTickets));
  }

  Future<void> _addToHistory(TournamentEntry entry, bool success) async {
    final historyEntry = TournamentHistoryEntry(
      tournamentId: entry.tournamentId,
      tournamentName: entry.tournamentName,
      completedAt: DateTime.now(),
      success: success,
      highestRound: entry.highestRoundReached,
      coinsEarned: entry.coinsEarned,
      gemsEarned: entry.gemsEarned,
      triesUsed: entry.currentTry,
      continuesUsed: entry.totalContinuesUsed,
      duration: entry.duration,
    );

    _history.insert(0, historyEntry);
    
    // Keep last 50 entries
    if (_history.length > 50) {
      _history = _history.sublist(0, 50);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyTournamentHistory, 
      jsonEncode(_history.map((h) => h.toJson()).toList()),
    );
  }

  // ============================================================================
  // 📊 ANALYTICS
  // ============================================================================

  void _fireEvent(String eventName, Map<String, dynamic> payload) {
    try {
      EventBus().fire(eventName, payload);
      safePrint('🏆 📊 Event fired: $eventName');
    } catch (e) {
      safePrint('🏆 ⚠️ Failed to fire event $eventName: $e');
    }
  }

  // ============================================================================
  // 🔧 TESTING & DEBUG
  // ============================================================================

  /// Reset for testing - DO NOT use in production!
  @visibleForTesting
  void resetForTesting() {
    _availableTournaments = [];
    _activeEntry = null;
    _completedTournamentIds = {};
    _freeTickets = {};
    _history = [];
    _isInitialized = false;
    _lastRefresh = null;
  }

  /// Get debug state
  Map<String, dynamic> getDebugState() => {
    'is_initialized': _isInitialized,
    'available_tournaments': _availableTournaments.length,
    'has_active_entry': hasActiveEntry,
    'active_tournament': _activeEntry?.tournamentName,
    'active_status': _activeEntry?.status.name,
    'completed_count': _completedTournamentIds.length,
    'free_tickets': _freeTickets,
    'history_count': _history.length,
  };
}

// ============================================================================
// 📦 HELPER CLASSES
// ============================================================================

/// Result of checking if player can enter a tournament
class CanEnterResult {
  final bool canEnter;
  final String reason;
  final bool hasActiveEntry;
  final bool useFreeTicket;
  final TournamentTier? freeTicketTier;
  final int? cost;
  final EntryFeeType? costType;

  const CanEnterResult({
    required this.canEnter,
    required this.reason,
    this.hasActiveEntry = false,
    this.useFreeTicket = false,
    this.freeTicketTier,
    this.cost,
    this.costType,
  });

  @override
  String toString() => 'CanEnterResult(canEnter: $canEnter, reason: $reason)';
}

/// Tournament history entry for analytics
class TournamentHistoryEntry {
  final String tournamentId;
  final String tournamentName;
  final DateTime completedAt;
  final bool success;
  final int highestRound;
  final int coinsEarned;
  final int gemsEarned;
  final int triesUsed;
  final int continuesUsed;
  final Duration duration;

  const TournamentHistoryEntry({
    required this.tournamentId,
    required this.tournamentName,
    required this.completedAt,
    required this.success,
    required this.highestRound,
    required this.coinsEarned,
    required this.gemsEarned,
    required this.triesUsed,
    required this.continuesUsed,
    required this.duration,
  });

  Map<String, dynamic> toJson() => {
    'tournament_id': tournamentId,
    'tournament_name': tournamentName,
    'completed_at': completedAt.toIso8601String(),
    'success': success,
    'highest_round': highestRound,
    'coins_earned': coinsEarned,
    'gems_earned': gemsEarned,
    'tries_used': triesUsed,
    'continues_used': continuesUsed,
    'duration_seconds': duration.inSeconds,
  };

  factory TournamentHistoryEntry.fromJson(Map<String, dynamic> json) {
    return TournamentHistoryEntry(
      tournamentId: json['tournament_id'] as String,
      tournamentName: json['tournament_name'] as String,
      completedAt: DateTime.parse(json['completed_at'] as String),
      success: json['success'] as bool,
      highestRound: json['highest_round'] as int? ?? 0,
      coinsEarned: json['coins_earned'] as int? ?? 0,
      gemsEarned: json['gems_earned'] as int? ?? 0,
      triesUsed: json['tries_used'] as int? ?? 1,
      continuesUsed: json['continues_used'] as int? ?? 0,
      duration: Duration(seconds: json['duration_seconds'] as int? ?? 0),
    );
  }

  @override
  String toString() => 'TournamentHistoryEntry('
      'tournament: $tournamentName, '
      'success: $success, '
      'highest_round: $highestRound'
      ')';
}


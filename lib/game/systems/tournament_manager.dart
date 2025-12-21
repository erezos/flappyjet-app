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
import 'achievements_manager.dart';
import 'missions_manager.dart';

/// Tournament Manager - Singleton pattern for consistent state
class TournamentManager extends ChangeNotifier {
  // ✅ SINGLETON PATTERN - Ensures all code uses the same instance
  static final TournamentManager _instance = TournamentManager._internal();
  factory TournamentManager() => _instance;
  TournamentManager._internal();

  // SharedPreferences keys
  static const String _keyActiveEntry = 'tournaments_active_entry'; // legacy single-entry key
  static const String _keyActiveEntries = 'tournaments_active_entries'; // new multi-entry map
  static const String _keyCurrentTournament = 'tournaments_current_tournament';
  static const String _keyCompletedTournaments = 'tournaments_completed';
  static const String _keyFreeTickets = 'tournaments_free_tickets';
  static const String _keyTournamentHistory = 'tournaments_history';
  // State
  List<TournamentConfig> _availableTournaments = [];
  final Map<String, TournamentEntry> _activeEntries = {};
  String? _currentTournamentId;
  Set<String> _completedTournamentIds = {};
  Map<String, int> _freeTickets = {}; // tier -> count
  List<TournamentHistoryEntry> _history = [];
  bool _isInitialized = false;

  // Getters
  List<TournamentConfig> get availableTournaments => _availableTournaments;
  Map<String, TournamentEntry> get activeEntries => Map.unmodifiable(_activeEntries);
  TournamentEntry? get activeEntry => _currentTournamentId != null ? _activeEntries[_currentTournamentId] : null;
  bool get hasActiveEntry => activeEntry?.status.isActive ?? false;
  bool get hasAnyActiveEntry => _activeEntries.values.any((e) => e.status.isActive);
  TournamentEntry? activeEntryFor(String tournamentId) => _activeEntries[tournamentId];
  bool hasActiveEntryFor(String tournamentId) => activeEntryFor(tournamentId)?.status.isActive ?? false;
  bool get isInitialized => _isInitialized;
  Set<String> get completedTournamentIds => _completedTournamentIds;
  List<TournamentHistoryEntry> get history => _history;

  /// Get available tournaments for display (active status only, not expired)
  List<TournamentConfig> get displayableTournaments =>
      _availableTournaments.where((t) => 
        (t.status == TournamentStatus.active || 
         t.status == TournamentStatus.upcoming) &&
        t.isAvailable
      ).toList();

  /// Get count of free tickets for a specific tier
  int getFreeTickets(TournamentTier tier) => _freeTickets[tier.name] ?? 0;

  /// Set the current tournament context (used by game flows)
  void selectTournamentContext(String tournamentId) {
    if (_activeEntries.containsKey(tournamentId)) {
      _setCurrentTournament(tournamentId);
    }
  }

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
        'has_active_entry': hasAnyActiveEntry,
        'total_free_tickets': totalFreeTickets,
      });
    } catch (e) {
      safePrint('🏆 ❌ TournamentManager initialization failed: $e');
      _isInitialized = true; // Mark as initialized even on error to prevent retry loops
    }
  }

  String? _selectDefaultCurrentTournamentId() {
    // Prefer an in-progress entry; otherwise pick any existing entry.
    for (final entry in _activeEntries.entries) {
      if (entry.value.status.isActive) return entry.key;
    }
    if (_activeEntries.isNotEmpty) return _activeEntries.keys.first;
    return null;
  }

  /// Load persisted state from SharedPreferences
  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();

    // Load active entries (multi-entry). Migrate from legacy single entry if needed.
    final activeEntriesJson = prefs.getString(_keyActiveEntries);
    if (activeEntriesJson != null) {
      try {
        final decoded = jsonDecode(activeEntriesJson) as Map<String, dynamic>;
        decoded.forEach((tournamentId, entryJson) {
          _activeEntries[tournamentId] = TournamentEntry.fromJson(entryJson as Map<String, dynamic>);
        });
        safePrint('🏆 Loaded ${_activeEntries.length} active entries');
      } catch (e) {
        safePrint('🏆 ⚠️ Failed to load active entries: $e');
        _activeEntries.clear();
      }
    } else {
      // Legacy migration: single active entry key
      final legacyActiveEntryJson = prefs.getString(_keyActiveEntry);
      if (legacyActiveEntryJson != null) {
        try {
          final entry = TournamentEntry.fromJsonString(legacyActiveEntryJson);
          _activeEntries[entry.tournamentId] = entry;
          _currentTournamentId = entry.tournamentId;
          safePrint('🏆 Migrated legacy active entry: ${entry.tournamentName}');
          await prefs.remove(_keyActiveEntry);
        } catch (e) {
          safePrint('🏆 ⚠️ Failed to migrate legacy active entry: $e');
        }
      }
    }

    // Load current tournament context (for single-entry APIs during gameplay)
    _currentTournamentId = prefs.getString(_keyCurrentTournament) ?? _selectDefaultCurrentTournamentId();

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
    if (hasActiveEntryFor(tournament.id)) {
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
    final existingEntry = activeEntryFor(tournament.id);
    if (existingEntry != null && existingEntry.status.isActive) {
      safePrint('🏆 ⚠️ Already have active entry for ${tournament.name}');
      _setCurrentTournament(tournament.id);
      return existingEntry;
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
    final entry = TournamentEntry.start(
      tournamentId: tournament.id,
      tournamentName: tournament.name,
      totalTries: tournament.tries.count,
    );

    _activeEntries[tournament.id] = entry;
    _setCurrentTournament(tournament.id);
    await _saveActiveEntries();
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

    // Track achievements and missions
    try {
      await AchievementsManager().checkTournamentAchievements(tournamentsEntered: 1);
      final missions = MissionsManager();
      if (!missions.isInitialized) {
        await missions.initialize();
      }
      await missions.updateMissionProgress(MissionType.enterTournament, 1);
    } catch (e) {
      safePrint('🏆 ⚠️ Failed to track tournament entry achievements: $e');
    }

    return entry;
  }

  /// Resume active entry (continue where left off)
  TournamentEntry? resumeActiveEntry({String? tournamentId}) {
    final entry = _requireActiveEntry(tournamentId: tournamentId);
    if (entry == null) {
      safePrint('🏆 ⚠️ No active entry to resume');
      return null;
    }
    
    safePrint('🏆 Resuming tournament: ${entry.tournamentName}');
    return entry;
  }

  /// Complete a round successfully
  Future<void> completeRound({
    required int roundNumber,
    required int coinsReward,
    required int gemsReward,
    required int heartsUsed,
    required int continuesUsed,
    required Duration duration,
    String? tournamentId,
  }) async {
    final entry = _requireActiveEntry(tournamentId: tournamentId);
    if (entry == null) {
      safePrint('🏆 ⚠️ No active entry to update');
      return;
    }

    entry.completeRound(
      roundNumber: roundNumber,
      coinsReward: coinsReward,
      gemsReward: gemsReward,
      heartsUsed: heartsUsed,
      continuesUsed: continuesUsed,
      duration: duration,
    );

    await _saveActiveEntries();
    notifyListeners();

    safePrint('🏆 ✅ Round $roundNumber completed');

    // Fire event
    _fireEvent('tournament_round_completed', {
      'tournament_id': entry.tournamentId,
      'round_number': roundNumber,
      'try_number': entry.currentTry,
      'coins_earned': coinsReward,
      'gems_earned': gemsReward,
      'hearts_used': heartsUsed,
      'continues_used': continuesUsed,
      'duration_seconds': duration.inSeconds,
    });

    // Track achievements and missions
    try {
      await AchievementsManager().checkTournamentAchievements(roundsWon: 1);
      final missions = MissionsManager();
      if (!missions.isInitialized) {
        await missions.initialize();
      }
      await missions.updateMissionProgress(MissionType.winTournamentRound, 1);
    } catch (e) {
      safePrint('🏆 ⚠️ Failed to track tournament round achievements: $e');
    }
  }

  /// Fail current round (ran out of hearts and continues)
  Future<void> failRound({
    required int roundNumber,
    required int heartsUsed,
    required int continuesUsed,
    required Duration duration,
    String? tournamentId,
  }) async {
    final entry = _requireActiveEntry(tournamentId: tournamentId);
    if (entry == null) return;

    entry.failRound(
      roundNumber: roundNumber,
      heartsUsed: heartsUsed,
      continuesUsed: continuesUsed,
      duration: duration,
    );

    await _saveActiveEntries();
    notifyListeners();

    safePrint('🏆 ❌ Round $roundNumber failed');

    // Fire event
    _fireEvent('tournament_round_failed', {
      'tournament_id': entry.tournamentId,
      'round_number': roundNumber,
      'try_number': entry.currentTry,
      'hearts_used': heartsUsed,
      'continues_used': continuesUsed,
      'duration_seconds': duration.inSeconds,
    });
  }

  /// Advance the active entry to the next round (persists + notifies).
  /// Used by playoff flow to move from Quarter→Semi→Finals after a win.
  Future<void> advanceToNextRound({String? tournamentId}) async {
    final entry = _requireActiveEntry(tournamentId: tournamentId);
    if (entry == null) return;

    final nextRound = entry.currentRound + 1;
    entry.startRound(nextRound);

    await _saveActiveEntries();
    notifyListeners();

    safePrint('🏆 ➡️ Advanced to round $nextRound');

    _fireEvent('tournament_round_advanced', {
      'tournament_id': entry.tournamentId,
      'round_number': nextRound,
      'try_number': entry.currentTry,
    });
  }

  /// Use a continue (respawn with full hearts)
  Future<void> useContinue({String? tournamentId}) async {
    final entry = _requireActiveEntry(tournamentId: tournamentId);
    if (entry == null) return;

    entry.useContinue();
    await _saveActiveEntries();
    notifyListeners();

    safePrint('🏆 Continue used (${entry.continuesUsedThisTry} this try)');

    // Fire event
    _fireEvent('tournament_continue_used', {
      'tournament_id': entry.tournamentId,
      'round_number': entry.currentRound,
      'try_number': entry.currentTry,
      'continues_this_try': entry.continuesUsedThisTry,
      'total_continues': entry.totalContinuesUsed,
    });
  }

  /// Fail current try (moves to next try or fails tournament)
  Future<TournamentEntryStatus> failCurrentTry({String? tournamentId}) async {
    final entry = _requireActiveEntry(tournamentId: tournamentId);
    if (entry == null) return TournamentEntryStatus.failed;

    final previousStatus = entry.status;
    entry.failCurrentTry();
    
    await _saveActiveEntries();
    notifyListeners();

    final newStatus = entry.status;
    safePrint('🏆 Try failed. Status: ${newStatus.name}, Tries remaining: ${entry.triesRemaining}');

    // Fire event
    _fireEvent('tournament_try_failed', {
      'tournament_id': entry.tournamentId,
      'try_number': entry.currentTry - 1, // Previous try
      'tries_remaining': entry.triesRemaining,
      'highest_round': entry.highestRoundReached,
      'total_coins_earned': entry.coinsEarned,
      'total_gems_earned': entry.gemsEarned,
      'tournament_failed': newStatus == TournamentEntryStatus.failed,
    });

    // If tournament failed, add to history
    if (newStatus == TournamentEntryStatus.failed && previousStatus != newStatus) {
      await _addToHistory(entry, false);
    }

    return newStatus;
  }

  /// Complete the tournament successfully
  /// Returns the completion reward for the caller to process
  Future<TournamentReward?> completeTournament({
    required int bonusCoins,
    required int bonusGems,
    TournamentReward? completionReward,
    String? tournamentId,
  }) async {
    final entry = _requireActiveEntry(tournamentId: tournamentId);
    if (entry == null) return null;

    entry.completeTournament(
      bonusCoins: bonusCoins,
      bonusGems: bonusGems,
    );

    // Mark as completed
    _completedTournamentIds.add(entry.tournamentId);
    
    await _saveActiveEntries();
    await _saveCompletedTournaments();
    await _addToHistory(entry, true);
    
    // Award free ticket if part of reward
    if (completionReward?.freeTicketTier != null) {
      await grantFreeTicket(completionReward!.freeTicketTier!);
      safePrint('🏆 🎫 Awarded free ticket for ${completionReward.freeTicketTier!.displayName} tier');
    }
    
    notifyListeners();

    safePrint('🏆 🎉 Tournament completed! Earned ${entry.coinsEarned} coins, ${entry.gemsEarned} gems');

    // Fire event with full reward details
    _fireEvent('tournament_completed', {
      'tournament_id': entry.tournamentId,
      'tournament_name': entry.tournamentName,
      'tries_used': entry.currentTry,
      'total_continues': entry.totalContinuesUsed,
      'coins_earned': entry.coinsEarned,
      'gems_earned': entry.gemsEarned,
      'duration_seconds': entry.duration.inSeconds,
      'success_rate': entry.successRate,
      'skin_reward': completionReward?.skinId,
      'free_ticket_tier': completionReward?.freeTicketTier?.name,
      'booster_type': completionReward?.booster?.type.name,
      'booster_duration': completionReward?.booster?.durationHours,
    });
    
    return completionReward;
  }

  /// Abandon the tournament (user quits)
  Future<void> abandonTournament({String? tournamentId}) async {
    final entry = _requireActiveEntry(tournamentId: tournamentId);
    if (entry == null) return;

    entry.abandon();
    
    await _saveActiveEntries();
    await _addToHistory(entry, false);
    
    notifyListeners();

    safePrint('🏆 Tournament abandoned: ${entry.tournamentName}');

    // Fire event
    _fireEvent('tournament_abandoned', {
      'tournament_id': entry.tournamentId,
      'tournament_name': entry.tournamentName,
      'current_try': entry.currentTry,
      'highest_round': entry.highestRoundReached,
      'coins_earned': entry.coinsEarned,
      'gems_earned': entry.gemsEarned,
    });
  }

  /// Clear active entry (after claiming rewards or abandoning)
  Future<void> clearActiveEntry({String? tournamentId}) async {
    final id = tournamentId ?? _currentTournamentId;
    if (id == null) return;

    _activeEntries.remove(id);
    if (_currentTournamentId == id) {
      _currentTournamentId = _selectDefaultCurrentTournamentId();
    }
    
    await _saveActiveEntries();
    notifyListeners();
    safePrint('🏆 Active entry cleared for tournament $id');
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
    String? tournamentId,
  }) async {
    // Check for a failed entry (note: hasActiveEntry returns false for failed entries,
    // so we check the stored entry directly)
    final entry = _requireActiveEntry(tournamentId: tournamentId, allowFinished: true);
    if (entry == null || entry.status != TournamentEntryStatus.failed) {
      safePrint('🏆 ⚠️ Cannot purchase extra tries - no failed entry');
      return false;
    }

    entry.addExtraTries(extraTries);
    await _saveActiveEntries();
    notifyListeners();

    safePrint('🏆 ✅ Purchased $extraTries extra tries');

    // Fire event
    _fireEvent('tournament_extra_tries_purchased', {
      'tournament_id': entry.tournamentId,
      'extra_tries': extraTries,
      'cost': cost,
      'cost_type': costType.name,
      'new_tries_remaining': entry.triesRemaining,
    });

    return true;
  }

  // ============================================================================
  // 💾 PERSISTENCE
  // ============================================================================

  /// Update an active entry (for game count tracking, etc.)
  Future<void> updateActiveEntry(String tournamentId, TournamentEntry entry) async {
    _activeEntries[tournamentId] = entry;
    await _saveActiveEntries();
  }

  Future<void> _saveActiveEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _activeEntries.map((key, entry) => MapEntry(key, entry.toJson()));
    await prefs.setString(_keyActiveEntries, jsonEncode(encoded));

    if (_currentTournamentId != null) {
      await prefs.setString(_keyCurrentTournament, _currentTournamentId!);
    } else {
      await prefs.remove(_keyCurrentTournament);
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
  // 🔧 INTERNAL HELPERS
  // ============================================================================

  void _setCurrentTournament(String tournamentId) {
    _currentTournamentId = tournamentId;
  }

  TournamentEntry? _requireActiveEntry({String? tournamentId, bool allowFinished = false}) {
    final id = tournamentId ?? _currentTournamentId;
    if (id == null) {
      safePrint('🏆 ⚠️ No current tournament context set');
      return null;
    }

    final entry = _activeEntries[id];
    if (entry == null) {
      safePrint('🏆 ⚠️ No entry found for tournament $id');
      return null;
    }

    if (!allowFinished && !entry.status.isActive) {
      safePrint('🏆 ⚠️ Entry for $id is not active (${entry.status.name})');
      return null;
    }

    _setCurrentTournament(id);
    return entry;
  }

  // ============================================================================
  // 🔧 TESTING & DEBUG
  // ============================================================================

  /// Reset for testing - DO NOT use in production!
  @visibleForTesting
  void resetForTesting() {
    _availableTournaments = [];
    _activeEntries.clear();
    _currentTournamentId = null;
    _completedTournamentIds = {};
    _freeTickets = {};
    _history = [];
    _isInitialized = false;
  }

  /// Get debug state
  Map<String, dynamic> getDebugState() => {
    'is_initialized': _isInitialized,
    'available_tournaments': _availableTournaments.length,
    'has_active_entry': hasAnyActiveEntry,
    'active_tournament_id': _currentTournamentId,
    'active_tournament': activeEntry?.tournamentName,
    'active_status': activeEntry?.status.name,
    'active_entry_count': _activeEntries.length,
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


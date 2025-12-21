/// 🏆 Tournament Entry Model
/// 
/// Tracks player's progress within an active tournament.
/// Persisted to SharedPreferences for state recovery on app restart.
/// 
/// Phase 1: Foundation
library;

import 'dart:convert';

/// Tournament entry status
enum TournamentEntryStatus {
  inProgress,
  completed,
  failed,
  abandoned;

  bool get isActive => this == TournamentEntryStatus.inProgress;
  bool get isFinished => this != TournamentEntryStatus.inProgress;
}

/// Player's active tournament entry
class TournamentEntry {
  final String id;
  final String tournamentId;
  final String tournamentName;
  final DateTime startedAt;
  final int totalTries;
  
  // Progress tracking
  int currentTry;
  int currentRound;
  int triesRemaining;
  int continuesUsedThisTry;
  int totalContinuesUsed;
  
  // Game count tracking (for interstitial ads - every 2 games)
  int gamesPlayed;
  
  // Rewards earned (partial rewards kept on failure)
  int coinsEarned;
  int gemsEarned;
  
  // Round-by-round tracking
  final List<RoundResult> roundResults;
  
  // Playoff bracket state (for playoff tournaments)
  // Maps matchupId to winner jet skin ID
  // AI vs AI matches are resolved with 50% random when bracket loads
  final Map<String, String> bracketWinners;
  // The shuffled jet order for this tournament attempt (player + 7 opponents).
  final List<String> bracketJetOrder;
  
  // Status
  TournamentEntryStatus status;
  DateTime? completedAt;

  TournamentEntry({
    required this.id,
    required this.tournamentId,
    required this.tournamentName,
    required this.startedAt,
    required this.totalTries,
    this.currentTry = 1,
    this.currentRound = 1,
    int? triesRemaining,
    this.continuesUsedThisTry = 0,
    this.totalContinuesUsed = 0,
    this.gamesPlayed = 0,
    this.coinsEarned = 0,
    this.gemsEarned = 0,
    List<RoundResult>? roundResults,
    Map<String, String>? bracketWinners,
    List<String>? bracketJetOrder,
    this.status = TournamentEntryStatus.inProgress,
    this.completedAt,
  }) : triesRemaining = triesRemaining ?? totalTries,
       roundResults = roundResults ?? [],
       bracketWinners = bracketWinners ?? {},
       bracketJetOrder = bracketJetOrder ?? [];

  /// Create a new entry for starting a tournament
  factory TournamentEntry.start({
    required String tournamentId,
    required String tournamentName,
    required int totalTries,
    Map<String, String>? initialBracketWinners,
    List<String>? initialBracketJetOrder,
  }) {
    return TournamentEntry(
      id: 'entry_${tournamentId}_${DateTime.now().millisecondsSinceEpoch}',
      tournamentId: tournamentId,
      tournamentName: tournamentName,
      startedAt: DateTime.now(),
      totalTries: totalTries,
      currentTry: 1,
      currentRound: 1,
      triesRemaining: totalTries,
      bracketWinners: initialBracketWinners ?? {},
      bracketJetOrder: initialBracketJetOrder ?? [],
    );
  }
  
  /// Record a bracket match winner
  void recordBracketWinner({
    required int roundNumber,
    required int matchupId,
    required String winnerJetSkin,
  }) {
    final key = 'round_${roundNumber}_match_$matchupId';
    bracketWinners[key] = winnerJetSkin;
  }

  /// Ensure jet order is stored (only if empty) to keep consistency across loads.
  void ensureBracketJetOrder(List<String> jetOrder) {
    if (bracketJetOrder.isEmpty && jetOrder.length == 8) {
      bracketJetOrder.addAll(jetOrder);
    }
  }
  
  /// Get winner for a specific match (null if not yet decided)
  String? getBracketWinner(int roundNumber, int matchupId) {
    final key = 'round_${roundNumber}_match_$matchupId';
    return bracketWinners[key];
  }
  
  /// Check if player's match in current round is complete
  bool isPlayerMatchComplete(int roundNumber) {
    return getBracketWinner(roundNumber, 0) != null;
  }

  /// Check if player can continue (has tries remaining)
  bool get canRetry => triesRemaining > 0 && status == TournamentEntryStatus.inProgress;

  /// Check if current try can use a continue
  bool canUseContinue(int maxContinuesPerTry) => 
      continuesUsedThisTry < maxContinuesPerTry;

  /// Start a new round
  void startRound(int roundNumber) {
    currentRound = roundNumber;
  }

  /// Complete current round successfully
  void completeRound({
    required int roundNumber,
    required int coinsReward,
    required int gemsReward,
    required int heartsUsed,
    required int continuesUsed,
    required Duration duration,
  }) {
    roundResults.add(RoundResult(
      roundNumber: roundNumber,
      tryNumber: currentTry,
      success: true,
      coinsEarned: coinsReward,
      gemsEarned: gemsReward,
      heartsUsed: heartsUsed,
      continuesUsed: continuesUsed,
      duration: duration,
    ));
    
    coinsEarned += coinsReward;
    gemsEarned += gemsReward;
    totalContinuesUsed += continuesUsed;
  }

  /// Fail current round (ran out of hearts and continues)
  void failRound({
    required int roundNumber,
    required int heartsUsed,
    required int continuesUsed,
    required Duration duration,
  }) {
    roundResults.add(RoundResult(
      roundNumber: roundNumber,
      tryNumber: currentTry,
      success: false,
      coinsEarned: 0,
      gemsEarned: 0,
      heartsUsed: heartsUsed,
      continuesUsed: continuesUsed,
      duration: duration,
    ));
    
    totalContinuesUsed += continuesUsed;
  }

  /// Use a continue (respawn with full hearts)
  void useContinue() {
    continuesUsedThisTry++;
    totalContinuesUsed++;
  }

  /// Start next try after failing
  void startNextTry() {
    if (triesRemaining <= 0) {
      throw StateError('No tries remaining');
    }
    
    triesRemaining--;
    currentTry++;
    currentRound = 1; // Reset to first round
    continuesUsedThisTry = 0;
  }

  /// Fail current try (moves to next try or fails tournament)
  void failCurrentTry() {
    triesRemaining--;
    
    if (triesRemaining <= 0) {
      status = TournamentEntryStatus.failed;
      completedAt = DateTime.now();
    } else {
      // Can still retry
      currentTry++;
      currentRound = 1;
      continuesUsedThisTry = 0;
    }
  }

  /// Complete the tournament successfully
  void completeTournament({
    required int bonusCoins,
    required int bonusGems,
  }) {
    coinsEarned += bonusCoins;
    gemsEarned += bonusGems;
    status = TournamentEntryStatus.completed;
    completedAt = DateTime.now();
  }

  /// Abandon the tournament (user quits)
  void abandon() {
    status = TournamentEntryStatus.abandoned;
    completedAt = DateTime.now();
  }

  /// Add extra tries (from special deal purchase)
  void addExtraTries(int extraTries) {
    triesRemaining += extraTries;
    totalTries + extraTries; // Track total for analytics
    
    // If was failed, revert to in progress
    if (status == TournamentEntryStatus.failed) {
      status = TournamentEntryStatus.inProgress;
      completedAt = null;
    }
  }

  /// Get duration of tournament attempt
  Duration get duration => 
      (completedAt ?? DateTime.now()).difference(startedAt);

  /// Get success rate (rounds won / rounds attempted)
  double get successRate {
    if (roundResults.isEmpty) return 0.0;
    final successful = roundResults.where((r) => r.success).length;
    return successful / roundResults.length;
  }

  /// Get highest round reached
  int get highestRoundReached {
    if (roundResults.isEmpty) return 0;
    return roundResults.map((r) => r.roundNumber).reduce((a, b) => a > b ? a : b);
  }

  /// Serialize to JSON for persistence
  Map<String, dynamic> toJson() => {
    'id': id,
    'tournament_id': tournamentId,
    'tournament_name': tournamentName,
    'started_at': startedAt.toIso8601String(),
    'total_tries': totalTries,
    'current_try': currentTry,
    'current_round': currentRound,
    'tries_remaining': triesRemaining,
    'continues_used_this_try': continuesUsedThisTry,
    'total_continues_used': totalContinuesUsed,
    'games_played': gamesPlayed,
    'coins_earned': coinsEarned,
    'gems_earned': gemsEarned,
    'round_results': roundResults.map((r) => r.toJson()).toList(),
    'bracket_winners': bracketWinners,
    'bracket_jet_order': bracketJetOrder,
    'status': status.name,
    'completed_at': completedAt?.toIso8601String(),
  };

  /// Deserialize from JSON
  factory TournamentEntry.fromJson(Map<String, dynamic> json) {
    return TournamentEntry(
      id: json['id'] as String,
      tournamentId: json['tournament_id'] as String,
      tournamentName: json['tournament_name'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
      totalTries: json['total_tries'] as int,
      currentTry: json['current_try'] as int? ?? 1,
      currentRound: json['current_round'] as int? ?? 1,
      triesRemaining: json['tries_remaining'] as int?,
      continuesUsedThisTry: json['continues_used_this_try'] as int? ?? 0,
      totalContinuesUsed: json['total_continues_used'] as int? ?? 0,
      gamesPlayed: json['games_played'] as int? ?? 0,
      coinsEarned: json['coins_earned'] as int? ?? 0,
      gemsEarned: json['gems_earned'] as int? ?? 0,
      roundResults: (json['round_results'] as List<dynamic>?)
          ?.map((r) => RoundResult.fromJson(r as Map<String, dynamic>))
          .toList(),
      bracketWinners: (json['bracket_winners'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v as String)) ?? {},
      bracketJetOrder: (json['bracket_jet_order'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      status: TournamentEntryStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => TournamentEntryStatus.inProgress,
      ),
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  /// Serialize to JSON string
  String toJsonString() => jsonEncode(toJson());

  /// Deserialize from JSON string
  factory TournamentEntry.fromJsonString(String jsonString) {
    return TournamentEntry.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  @override
  String toString() => 'TournamentEntry('
      'id: $id, '
      'tournament: $tournamentName, '
      'try: $currentTry/$totalTries, '
      'round: $currentRound, '
      'status: ${status.name}'
      ')';
}

/// Result of a single round attempt
class RoundResult {
  final int roundNumber;
  final int tryNumber;
  final bool success;
  final int coinsEarned;
  final int gemsEarned;
  final int heartsUsed;
  final int continuesUsed;
  final Duration duration;

  const RoundResult({
    required this.roundNumber,
    required this.tryNumber,
    required this.success,
    required this.coinsEarned,
    required this.gemsEarned,
    required this.heartsUsed,
    required this.continuesUsed,
    required this.duration,
  });

  Map<String, dynamic> toJson() => {
    'round_number': roundNumber,
    'try_number': tryNumber,
    'success': success,
    'coins_earned': coinsEarned,
    'gems_earned': gemsEarned,
    'hearts_used': heartsUsed,
    'continues_used': continuesUsed,
    'duration_seconds': duration.inSeconds,
  };

  factory RoundResult.fromJson(Map<String, dynamic> json) {
    return RoundResult(
      roundNumber: json['round_number'] as int,
      tryNumber: json['try_number'] as int,
      success: json['success'] as bool,
      coinsEarned: json['coins_earned'] as int? ?? 0,
      gemsEarned: json['gems_earned'] as int? ?? 0,
      heartsUsed: json['hearts_used'] as int? ?? 0,
      continuesUsed: json['continues_used'] as int? ?? 0,
      duration: Duration(seconds: json['duration_seconds'] as int? ?? 0),
    );
  }

  @override
  String toString() => 'RoundResult('
      'round: $roundNumber, '
      'try: $tryNumber, '
      'success: $success, '
      'coins: $coinsEarned'
      ')';
}


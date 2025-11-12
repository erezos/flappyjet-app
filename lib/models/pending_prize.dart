/// Model for pending prizes that the user can claim
/// These are calculated by the backend after a tournament ends
library;

class PendingPrize {
  final String prizeId; // Unique prize ID from backend
  final String tournamentId; // Tournament this prize is from
  final String tournamentName; // e.g., "Weekly Championship"
  final int rank; // User's final rank (1 = first place)
  final int coins; // Coin reward
  final int gems; // Gem reward
  final DateTime awardedAt; // When the backend calculated this prize
  final DateTime? claimedAt; // When the user claimed it (null if unclaimed)

  PendingPrize({
    required this.prizeId,
    required this.tournamentId,
    required this.tournamentName,
    required this.rank,
    required this.coins,
    required this.gems,
    required this.awardedAt,
    this.claimedAt,
  });

  /// From JSON (from backend API)
  factory PendingPrize.fromJson(Map<String, dynamic> json) {
    return PendingPrize(
      prizeId: json['prize_id'] as String,
      tournamentId: json['tournament_id'] as String,
      tournamentName: json['tournament_name'] as String? ?? 'Tournament',
      rank: json['rank'] as int,
      coins: json['coins'] as int? ?? 0,
      gems: json['gems'] as int? ?? 0,
      awardedAt: DateTime.parse(json['awarded_at'] as String),
      claimedAt: json['claimed_at'] != null
          ? DateTime.parse(json['claimed_at'] as String)
          : null,
    );
  }

  /// To JSON (for backend API)
  Map<String, dynamic> toJson() {
    return {
      'prize_id': prizeId,
      'tournament_id': tournamentId,
      'tournament_name': tournamentName,
      'rank': rank,
      'coins': coins,
      'gems': gems,
      'awarded_at': awardedAt.toIso8601String(),
      'claimed_at': claimedAt?.toIso8601String(),
    };
  }

  /// To database map (for local SQLite storage)
  Map<String, dynamic> toDb() {
    return {
      'prize_id': prizeId,
      'tournament_id': tournamentId,
      'tournament_name': tournamentName,
      'rank': rank,
      'coins': coins,
      'gems': gems,
      'awarded_at': awardedAt.millisecondsSinceEpoch,
      'claimed_at': claimedAt?.millisecondsSinceEpoch,
    };
  }

  /// From database map (from local SQLite storage)
  factory PendingPrize.fromDb(Map<String, dynamic> map) {
    return PendingPrize(
      prizeId: map['prize_id'] as String,
      tournamentId: map['tournament_id'] as String,
      tournamentName: map['tournament_name'] as String,
      rank: map['rank'] as int,
      coins: map['coins'] as int,
      gems: map['gems'] as int,
      awardedAt: DateTime.fromMillisecondsSinceEpoch(map['awarded_at'] as int),
      claimedAt: map['claimed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['claimed_at'] as int)
          : null,
    );
  }

  /// Is this prize claimed?
  bool get isClaimed => claimedAt != null;

  /// Is this prize unclaimed?
  bool get isUnclaimed => claimedAt == null;

  /// Copy with
  PendingPrize copyWith({
    String? prizeId,
    String? tournamentId,
    String? tournamentName,
    int? rank,
    int? coins,
    int? gems,
    DateTime? awardedAt,
    DateTime? claimedAt,
  }) {
    return PendingPrize(
      prizeId: prizeId ?? this.prizeId,
      tournamentId: tournamentId ?? this.tournamentId,
      tournamentName: tournamentName ?? this.tournamentName,
      rank: rank ?? this.rank,
      coins: coins ?? this.coins,
      gems: gems ?? this.gems,
      awardedAt: awardedAt ?? this.awardedAt,
      claimedAt: claimedAt ?? this.claimedAt,
    );
  }

  /// Get trophy color based on rank
  String get trophyColor {
    if (rank == 1) return 'gold';
    if (rank == 2) return 'silver';
    if (rank == 3) return 'bronze';
    return 'default';
  }

  /// Get rank suffix (1st, 2nd, 3rd, 4th, etc.)
  String get rankSuffix {
    if (rank % 100 >= 11 && rank % 100 <= 13) {
      return '${rank}th';
    }
    switch (rank % 10) {
      case 1:
        return '${rank}st';
      case 2:
        return '${rank}nd';
      case 3:
        return '${rank}rd';
      default:
        return '${rank}th';
    }
  }

  @override
  String toString() {
    return 'PendingPrize(prizeId: $prizeId, tournament: $tournamentName, rank: $rank, coins: $coins, gems: $gems, claimed: $isClaimed)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PendingPrize && other.prizeId == prizeId;
  }

  @override
  int get hashCode => prizeId.hashCode;
}


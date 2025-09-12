import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'tournament_participant.g.dart';

/// Represents a player's participation in a tournament
@JsonSerializable()
class TournamentParticipant extends Equatable {
  /// Unique participant identifier
  final String id;

  /// Tournament this participant is in
  @JsonKey(name: 'tournament_id')
  final String tournamentId;

  /// Player's unique identifier
  @JsonKey(name: 'player_id')
  final String playerId;

  /// Player's display name
  @JsonKey(name: 'player_name')
  final String playerName;

  /// When the player registered for the tournament
  @JsonKey(name: 'registered_at')
  final DateTime registeredAt;

  /// Entry fee paid by the player
  @JsonKey(name: 'entry_fee_paid')
  final int entryFeePaid;

  /// Player's best score in this tournament
  @JsonKey(name: 'best_score')
  final int bestScore;

  /// Total number of games played in this tournament
  @JsonKey(name: 'total_games')
  final int totalGames;

  /// Final rank in the tournament (null if tournament not ended)
  @JsonKey(name: 'final_rank')
  final int? finalRank;

  /// Prize amount won (0 if no prize)
  @JsonKey(name: 'prize_won')
  final int prizeWon;

  /// Whether the prize has been claimed
  @JsonKey(name: 'prize_claimed')
  final bool prizeClaimed;

  /// When the prize was claimed
  @JsonKey(name: 'prize_claimed_at')
  final DateTime? prizeClaimedAt;

  const TournamentParticipant({
    required this.id,
    required this.tournamentId,
    required this.playerId,
    required this.playerName,
    required this.registeredAt,
    this.entryFeePaid = 0,
    this.bestScore = 0,
    this.totalGames = 0,
    this.finalRank,
    this.prizeWon = 0,
    this.prizeClaimed = false,
    this.prizeClaimedAt,
  });

  /// Create TournamentParticipant from JSON
  factory TournamentParticipant.fromJson(Map<String, dynamic> json) =>
      _$TournamentParticipantFromJson(json);

  /// Convert TournamentParticipant to JSON
  Map<String, dynamic> toJson() => _$TournamentParticipantToJson(this);

  /// Check if this participant won a prize
  bool get wonPrize => prizeWon > 0;

  /// Check if participant has unclaimed prize
  bool get hasUnclaimedPrize => wonPrize && !prizeClaimed;

  /// Get average score per game
  double get averageScore => totalGames > 0 ? bestScore / totalGames : 0.0;

  /// Get formatted rank with ordinal suffix
  String get formattedRank {
    if (finalRank == null) return 'TBD';
    return _getOrdinalSuffix(finalRank!);
  }

  /// Helper method to get ordinal suffix for numbers
  String _getOrdinalSuffix(int number) {
    if (number >= 11 && number <= 13) {
      return '${number}th';
    }
    switch (number % 10) {
      case 1:
        return '${number}st';
      case 2:
        return '${number}nd';
      case 3:
        return '${number}rd';
      default:
        return '${number}th';
    }
  }

  @override
  List<Object?> get props => [
    id,
    tournamentId,
    playerId,
    playerName,
    registeredAt,
    entryFeePaid,
    bestScore,
    totalGames,
    finalRank,
    prizeWon,
    prizeClaimed,
    prizeClaimedAt,
  ];

  /// Create a copy of this participant with updated fields
  TournamentParticipant copyWith({
    String? id,
    String? tournamentId,
    String? playerId,
    String? playerName,
    DateTime? registeredAt,
    int? entryFeePaid,
    int? bestScore,
    int? totalGames,
    int? finalRank,
    int? prizeWon,
    bool? prizeClaimed,
    DateTime? prizeClaimedAt,
  }) {
    return TournamentParticipant(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      registeredAt: registeredAt ?? this.registeredAt,
      entryFeePaid: entryFeePaid ?? this.entryFeePaid,
      bestScore: bestScore ?? this.bestScore,
      totalGames: totalGames ?? this.totalGames,
      finalRank: finalRank ?? this.finalRank,
      prizeWon: prizeWon ?? this.prizeWon,
      prizeClaimed: prizeClaimed ?? this.prizeClaimed,
      prizeClaimedAt: prizeClaimedAt ?? this.prizeClaimedAt,
    );
  }
}

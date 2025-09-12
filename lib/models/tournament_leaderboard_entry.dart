import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'tournament_leaderboard_entry.g.dart';

/// Represents a single entry in the tournament leaderboard
@JsonSerializable()
class TournamentLeaderboardEntry extends Equatable {
  /// Player's unique identifier
  @JsonKey(name: 'player_id')
  final String playerId;

  /// Player's display name
  @JsonKey(name: 'player_name')
  final String playerName;

  /// Player's best score in the tournament
  final int score;

  /// Player's current rank in the tournament
  final int rank;

  /// Total number of games played by this player
  @JsonKey(name: 'total_games')
  final int totalGames;

  /// Final rank (only set when tournament ends)
  @JsonKey(name: 'final_rank')
  final int? finalRank;

  /// Prize won by this player (0 if no prize)
  @JsonKey(name: 'prize_won')
  final int prizeWon;

  /// Whether this entry represents the current player
  @JsonKey(name: 'is_current_player')
  final bool isCurrentPlayer;

  /// Player's avatar URL (optional)
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;

  /// Country code for flag display (optional)
  @JsonKey(name: 'country_code')
  final String? countryCode;

  const TournamentLeaderboardEntry({
    required this.playerId,
    required this.playerName,
    required this.score,
    required this.rank,
    required this.totalGames,
    this.finalRank,
    this.prizeWon = 0,
    this.isCurrentPlayer = false,
    this.avatarUrl,
    this.countryCode,
  });

  /// Create TournamentLeaderboardEntry from JSON
  factory TournamentLeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      _$TournamentLeaderboardEntryFromJson(json);

  /// Convert TournamentLeaderboardEntry to JSON
  Map<String, dynamic> toJson() => _$TournamentLeaderboardEntryToJson(this);

  /// Check if this player won a prize
  bool get wonPrize => prizeWon > 0;

  /// Check if this is a podium position (top 3)
  bool get isPodiumPosition => rank <= 3;

  /// Get average score per game
  double get averageScore => totalGames > 0 ? score / totalGames : 0.0;

  /// Get formatted rank with ordinal suffix
  String get formattedRank => _getOrdinalSuffix(rank);

  /// Get rank color based on position
  RankColor get rankColor {
    switch (rank) {
      case 1:
        return RankColor.gold;
      case 2:
        return RankColor.silver;
      case 3:
        return RankColor.bronze;
      default:
        return RankColor.normal;
    }
  }

  /// Get rank emoji based on position
  String get rankEmoji {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '🏅';
    }
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
    playerId,
    playerName,
    score,
    rank,
    totalGames,
    finalRank,
    prizeWon,
    isCurrentPlayer,
    avatarUrl,
    countryCode,
  ];

  /// Create a copy of this entry with updated fields
  TournamentLeaderboardEntry copyWith({
    String? playerId,
    String? playerName,
    int? score,
    int? rank,
    int? totalGames,
    int? finalRank,
    int? prizeWon,
    bool? isCurrentPlayer,
    String? avatarUrl,
    String? countryCode,
  }) {
    return TournamentLeaderboardEntry(
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      score: score ?? this.score,
      rank: rank ?? this.rank,
      totalGames: totalGames ?? this.totalGames,
      finalRank: finalRank ?? this.finalRank,
      prizeWon: prizeWon ?? this.prizeWon,
      isCurrentPlayer: isCurrentPlayer ?? this.isCurrentPlayer,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      countryCode: countryCode ?? this.countryCode,
    );
  }
}

/// Enum for rank colors in the leaderboard
enum RankColor { gold, silver, bronze, normal }

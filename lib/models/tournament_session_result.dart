import 'package:json_annotation/json_annotation.dart';

part 'tournament_session_result.g.dart';

@JsonSerializable()
class TournamentSessionResult {
  final bool success;
  final TournamentInfo tournament;
  final PlayerTournamentInfo player;
  final ScoreSubmissionInfo? scoreSubmission;
  final List<LeaderboardEntryInfo> leaderboard;

  const TournamentSessionResult({
    required this.success,
    required this.tournament,
    required this.player,
    this.scoreSubmission,
    required this.leaderboard,
  });

  factory TournamentSessionResult.fromJson(Map<String, dynamic> json) =>
      _$TournamentSessionResultFromJson(json);

  Map<String, dynamic> toJson() => _$TournamentSessionResultToJson(this);
}

@JsonSerializable()
class TournamentInfo {
  final String id;
  final String name;
  final String status;
  @JsonKey(fromJson: _parseEndsAt)
  final String endsAt;
  final int prizePool;

  const TournamentInfo({
    required this.id,
    required this.name,
    required this.status,
    required this.endsAt,
    required this.prizePool,
  });

  factory TournamentInfo.fromJson(Map<String, dynamic> json) =>
      _$TournamentInfoFromJson(json);

  Map<String, dynamic> toJson() => _$TournamentInfoToJson(this);

  /// Parse endsAt field - handle both String and DateTime from backend
  static String _parseEndsAt(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is DateTime) return value.toIso8601String();
    return value.toString();
  }
}

@JsonSerializable()
class PlayerTournamentInfo {
  final bool registered;
  final int? rank;
  final int bestScore;
  final int totalGames;
  final bool justRegistered;

  const PlayerTournamentInfo({
    required this.registered,
    this.rank,
    required this.bestScore,
    required this.totalGames,
    required this.justRegistered,
  });

  factory PlayerTournamentInfo.fromJson(Map<String, dynamic> json) =>
      _$PlayerTournamentInfoFromJson(json);

  Map<String, dynamic> toJson() => _$PlayerTournamentInfoToJson(this);
}

@JsonSerializable()
class ScoreSubmissionInfo {
  final bool accepted;
  final String? error;
  final bool? newBest;
  final int? score;
  final int? previousBest;
  final int? rankImprovement;

  const ScoreSubmissionInfo({
    required this.accepted,
    this.error,
    this.newBest,
    this.score,
    this.previousBest,
    this.rankImprovement,
  });

  factory ScoreSubmissionInfo.fromJson(Map<String, dynamic> json) =>
      _$ScoreSubmissionInfoFromJson(json);

  Map<String, dynamic> toJson() => _$ScoreSubmissionInfoToJson(this);
}

@JsonSerializable()
class LeaderboardEntryInfo {
  final int rank;
  final String playerName;
  final int score;

  const LeaderboardEntryInfo({
    required this.rank,
    required this.playerName,
    required this.score,
  });

  factory LeaderboardEntryInfo.fromJson(Map<String, dynamic> json) =>
      _$LeaderboardEntryInfoFromJson(json);

  Map<String, dynamic> toJson() => _$LeaderboardEntryInfoToJson(this);
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tournament_session_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TournamentSessionResult _$TournamentSessionResultFromJson(
  Map<String, dynamic> json,
) => TournamentSessionResult(
  success: json['success'] as bool,
  tournament: TournamentInfo.fromJson(
    json['tournament'] as Map<String, dynamic>,
  ),
  player: PlayerTournamentInfo.fromJson(json['player'] as Map<String, dynamic>),
  scoreSubmission: json['scoreSubmission'] == null
      ? null
      : ScoreSubmissionInfo.fromJson(
          json['scoreSubmission'] as Map<String, dynamic>,
        ),
  leaderboard: (json['leaderboard'] as List<dynamic>)
      .map((e) => LeaderboardEntryInfo.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$TournamentSessionResultToJson(
  TournamentSessionResult instance,
) => <String, dynamic>{
  'success': instance.success,
  'tournament': instance.tournament,
  'player': instance.player,
  'scoreSubmission': instance.scoreSubmission,
  'leaderboard': instance.leaderboard,
};

TournamentInfo _$TournamentInfoFromJson(Map<String, dynamic> json) =>
    TournamentInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      status: json['status'] as String,
      endsAt: TournamentInfo._parseEndsAt(json['endsAt']),
      prizePool: (json['prizePool'] as num).toInt(),
    );

Map<String, dynamic> _$TournamentInfoToJson(TournamentInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'status': instance.status,
      'endsAt': instance.endsAt,
      'prizePool': instance.prizePool,
    };

PlayerTournamentInfo _$PlayerTournamentInfoFromJson(
  Map<String, dynamic> json,
) => PlayerTournamentInfo(
  registered: json['registered'] as bool,
  rank: (json['rank'] as num?)?.toInt(),
  bestScore: (json['bestScore'] as num).toInt(),
  totalGames: (json['totalGames'] as num).toInt(),
  justRegistered: json['justRegistered'] as bool,
);

Map<String, dynamic> _$PlayerTournamentInfoToJson(
  PlayerTournamentInfo instance,
) => <String, dynamic>{
  'registered': instance.registered,
  'rank': instance.rank,
  'bestScore': instance.bestScore,
  'totalGames': instance.totalGames,
  'justRegistered': instance.justRegistered,
};

ScoreSubmissionInfo _$ScoreSubmissionInfoFromJson(Map<String, dynamic> json) =>
    ScoreSubmissionInfo(
      accepted: json['accepted'] as bool,
      error: json['error'] as String?,
      newBest: json['newBest'] as bool?,
      score: (json['score'] as num?)?.toInt(),
      previousBest: (json['previousBest'] as num?)?.toInt(),
      rankImprovement: (json['rankImprovement'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ScoreSubmissionInfoToJson(
  ScoreSubmissionInfo instance,
) => <String, dynamic>{
  'accepted': instance.accepted,
  'error': instance.error,
  'newBest': instance.newBest,
  'score': instance.score,
  'previousBest': instance.previousBest,
  'rankImprovement': instance.rankImprovement,
};

LeaderboardEntryInfo _$LeaderboardEntryInfoFromJson(
  Map<String, dynamic> json,
) => LeaderboardEntryInfo(
  rank: (json['rank'] as num).toInt(),
  playerName: json['playerName'] as String,
  score: (json['score'] as num).toInt(),
);

Map<String, dynamic> _$LeaderboardEntryInfoToJson(
  LeaderboardEntryInfo instance,
) => <String, dynamic>{
  'rank': instance.rank,
  'playerName': instance.playerName,
  'score': instance.score,
};

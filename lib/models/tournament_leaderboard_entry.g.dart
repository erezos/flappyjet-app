// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tournament_leaderboard_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TournamentLeaderboardEntry _$TournamentLeaderboardEntryFromJson(
  Map<String, dynamic> json,
) => TournamentLeaderboardEntry(
  playerId: json['player_id'] as String,
  playerName: json['player_name'] as String,
  score: (json['score'] as num).toInt(),
  rank: (json['rank'] as num).toInt(),
  totalGames: (json['total_games'] as num).toInt(),
  finalRank: (json['final_rank'] as num?)?.toInt(),
  prizeWon: (json['prize_won'] as num?)?.toInt() ?? 0,
  isCurrentPlayer: json['is_current_player'] as bool? ?? false,
  avatarUrl: json['avatar_url'] as String?,
  countryCode: json['country_code'] as String?,
);

Map<String, dynamic> _$TournamentLeaderboardEntryToJson(
  TournamentLeaderboardEntry instance,
) => <String, dynamic>{
  'player_id': instance.playerId,
  'player_name': instance.playerName,
  'score': instance.score,
  'rank': instance.rank,
  'total_games': instance.totalGames,
  'final_rank': instance.finalRank,
  'prize_won': instance.prizeWon,
  'is_current_player': instance.isCurrentPlayer,
  'avatar_url': instance.avatarUrl,
  'country_code': instance.countryCode,
};

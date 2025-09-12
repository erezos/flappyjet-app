// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tournament_participant.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TournamentParticipant _$TournamentParticipantFromJson(
  Map<String, dynamic> json,
) => TournamentParticipant(
  id: json['id'] as String,
  tournamentId: json['tournament_id'] as String,
  playerId: json['player_id'] as String,
  playerName: json['player_name'] as String,
  registeredAt: DateTime.parse(json['registered_at'] as String),
  entryFeePaid: (json['entry_fee_paid'] as num?)?.toInt() ?? 0,
  bestScore: (json['best_score'] as num?)?.toInt() ?? 0,
  totalGames: (json['total_games'] as num?)?.toInt() ?? 0,
  finalRank: (json['final_rank'] as num?)?.toInt(),
  prizeWon: (json['prize_won'] as num?)?.toInt() ?? 0,
  prizeClaimed: json['prize_claimed'] as bool? ?? false,
  prizeClaimedAt: json['prize_claimed_at'] == null
      ? null
      : DateTime.parse(json['prize_claimed_at'] as String),
);

Map<String, dynamic> _$TournamentParticipantToJson(
  TournamentParticipant instance,
) => <String, dynamic>{
  'id': instance.id,
  'tournament_id': instance.tournamentId,
  'player_id': instance.playerId,
  'player_name': instance.playerName,
  'registered_at': instance.registeredAt.toIso8601String(),
  'entry_fee_paid': instance.entryFeePaid,
  'best_score': instance.bestScore,
  'total_games': instance.totalGames,
  'final_rank': instance.finalRank,
  'prize_won': instance.prizeWon,
  'prize_claimed': instance.prizeClaimed,
  'prize_claimed_at': instance.prizeClaimedAt?.toIso8601String(),
};

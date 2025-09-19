// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tournament.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Tournament _$TournamentFromJson(Map<String, dynamic> json) => Tournament(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] == null
          ? ''
          : Tournament._parseDescription(json['description']),
      tournamentType:
          $enumDecode(_$TournamentTypeEnumMap, json['tournament_type']),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      status: $enumDecode(_$TournamentStatusEnumMap, json['status']),
      prizePool: (json['prize_pool'] as num).toInt(),
      prizeDistribution: json['prize_distribution'] == null
          ? const {1: 0.5, 2: 0.3, 3: 0.2}
          : Tournament._parsePrizeDistribution(json['prize_distribution']),
      participantCount:
          Tournament._parseParticipantCount(json['participant_count']),
      maxParticipants: (json['max_participants'] as num?)?.toInt(),
      entryFee: (json['entry_fee'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$TournamentToJson(Tournament instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'tournament_type': _$TournamentTypeEnumMap[instance.tournamentType]!,
      'start_date': instance.startDate.toIso8601String(),
      'end_date': instance.endDate.toIso8601String(),
      'status': _$TournamentStatusEnumMap[instance.status]!,
      'prize_pool': instance.prizePool,
      'prize_distribution':
          instance.prizeDistribution.map((k, e) => MapEntry(k.toString(), e)),
      'participant_count': instance.participantCount,
      'max_participants': instance.maxParticipants,
      'entry_fee': instance.entryFee,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

const _$TournamentTypeEnumMap = {
  TournamentType.weekly: 'weekly',
  TournamentType.monthly: 'monthly',
  TournamentType.special: 'special',
};

const _$TournamentStatusEnumMap = {
  TournamentStatus.upcoming: 'upcoming',
  TournamentStatus.registration: 'registration',
  TournamentStatus.active: 'active',
  TournamentStatus.ended: 'ended',
  TournamentStatus.cancelled: 'cancelled',
  TournamentStatus.archived: 'archived',
};

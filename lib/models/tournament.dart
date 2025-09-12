import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import '../core/debug_logger.dart';

part 'tournament.g.dart';

/// Tournament types available in the system
enum TournamentType {
  @JsonValue('weekly')
  weekly,
  @JsonValue('monthly')
  monthly,
  @JsonValue('special')
  special,
}

/// Tournament status lifecycle
enum TournamentStatus {
  @JsonValue('upcoming')
  upcoming,
  @JsonValue('registration')
  registration,
  @JsonValue('active')
  active,
  @JsonValue('ended')
  ended,
  @JsonValue('cancelled')
  cancelled,
  @JsonValue('archived')
  archived,
}

/// Main tournament model representing a competitive event
@JsonSerializable()
class Tournament extends Equatable {
  /// Unique tournament identifier
  final String id;
  
  /// Tournament display name
  final String name;
  
  /// Tournament description
  @JsonKey(fromJson: _parseDescription)
  final String description;
  
  /// Type of tournament (weekly, monthly, special)
  @JsonKey(name: 'tournament_type')
  final TournamentType tournamentType;
  
  /// Tournament start date and time
  @JsonKey(name: 'start_date')
  final DateTime startDate;
  
  /// Tournament end date and time
  @JsonKey(name: 'end_date')
  final DateTime endDate;
  
  /// Current tournament status
  final TournamentStatus status;
  
  /// Total prize pool in gems
  @JsonKey(name: 'prize_pool')
  final int prizePool;
  
  /// Prize distribution by rank (rank -> percentage)
  @JsonKey(name: 'prize_distribution', fromJson: _parsePrizeDistribution)
  final Map<int, double> prizeDistribution;
  
  /// Current number of participants
  @JsonKey(name: 'participant_count', fromJson: _parseParticipantCount)
  final int participantCount;
  
  /// Maximum allowed participants (null = unlimited)
  @JsonKey(name: 'max_participants')
  final int? maxParticipants;
  
  /// Entry fee in gems (0 = free)
  @JsonKey(name: 'entry_fee')
  final int entryFee;
  
  /// Tournament creation timestamp
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  
  /// Last update timestamp
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  const Tournament({
    required this.id,
    required this.name,
    this.description = '',
    required this.tournamentType,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.prizePool,
    this.prizeDistribution = const {1: 0.5, 2: 0.3, 3: 0.2},
    required this.participantCount,
    this.maxParticipants,
    this.entryFee = 0,
    this.createdAt,
    this.updatedAt,
  });

  /// Create Tournament from JSON
  factory Tournament.fromJson(Map<String, dynamic> json) => _$TournamentFromJson(json);
  
  /// Convert Tournament to JSON
  Map<String, dynamic> toJson() => _$TournamentToJson(this);

  /// Check if tournament is currently active
  bool get isActive => status == TournamentStatus.active;
  
  /// Check if tournament has started
  bool get hasStarted => DateTime.now().isAfter(startDate);
  
  /// Check if tournament has ended
  bool get hasEnded => DateTime.now().isAfter(endDate);
  
  /// Check if registration is open
  bool get isRegistrationOpen => 
      status == TournamentStatus.upcoming || 
      status == TournamentStatus.registration ||
      status == TournamentStatus.active;
  
  /// Check if tournament is full
  bool get isFull => maxParticipants != null && participantCount >= maxParticipants!;
  
  /// Get time remaining until tournament ends (null if already ended)
  Duration? get timeRemaining {
    if (hasEnded) return null;
    return endDate.difference(DateTime.now());
  }
  
  /// Get time until tournament starts (null if already started)
  Duration? get timeUntilStart {
    if (hasStarted) return null;
    return startDate.difference(DateTime.now());
  }
  
  /// Get formatted time remaining string
  String get formattedTimeRemaining {
    final remaining = timeRemaining;
    if (remaining == null) return 'Ended';
    
    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;
    
    if (days > 0) {
      return '${days}d ${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
  
  /// Get prize amount for a specific rank
  int getPrizeForRank(int rank) {
    final percentage = prizeDistribution[rank] ?? 0.0;
    return (prizePool * percentage).round();
  }
  
  /// Get total number of prize positions
  int get prizePositions => prizeDistribution.length;
  
  /// Check if rank receives a prize
  bool rankReceivesPrize(int rank) => prizeDistribution.containsKey(rank);

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    tournamentType,
    startDate,
    endDate,
    status,
    prizePool,
    prizeDistribution,
    participantCount,
    maxParticipants,
    entryFee,
    createdAt,
    updatedAt,
  ];
  
  /// Create a copy of this tournament with updated fields
  Tournament copyWith({
    String? id,
    String? name,
    String? description,
    TournamentType? tournamentType,
    DateTime? startDate,
    DateTime? endDate,
    TournamentStatus? status,
    int? prizePool,
    Map<int, double>? prizeDistribution,
    int? participantCount,
    int? maxParticipants,
    int? entryFee,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Tournament(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      tournamentType: tournamentType ?? this.tournamentType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      prizePool: prizePool ?? this.prizePool,
      prizeDistribution: prizeDistribution ?? this.prizeDistribution,
      participantCount: participantCount ?? this.participantCount,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      entryFee: entryFee ?? this.entryFee,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Parse participant count from string or int
  static int _parseParticipantCount(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Parse description with default value
  static String _parseDescription(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
  }

  /// Parse prize distribution with default value
  static Map<int, double> _parsePrizeDistribution(dynamic value) {
    if (value == null) {
      return {1: 0.5, 2: 0.3, 3: 0.2}; // Default prize distribution
    }

    if (value is Map) {
      try {
        return value.map((k, v) => MapEntry(
          k is int ? k : int.tryParse(k.toString()) ?? 0,
          v is double ? v : double.tryParse(v.toString()) ?? 0.0,
        ));
      } catch (e) {
        safePrint('⚠️ Failed to parse prize distribution: $e');
        // Return default distribution on error
      }
    }

    // Fallback to default distribution
    return {1: 0.5, 2: 0.3, 3: 0.2}; // Default prize distribution
  }
}
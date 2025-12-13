/// 🏆 Tournament Configuration Model
/// 
/// Defines the structure for tournament data loaded from JSON configuration.
/// Follows the same pattern as zone_levels.json for familiarity and flexibility.
/// 
/// Phase 1: Foundation
library;

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../core/debug_logger.dart';

/// Tournament tier levels
enum TournamentTier {
  bronze,
  silver,
  gold,
  platinum,
  special;

  String get displayName {
    switch (this) {
      case TournamentTier.bronze:
        return 'Bronze';
      case TournamentTier.silver:
        return 'Silver';
      case TournamentTier.gold:
        return 'Gold';
      case TournamentTier.platinum:
        return 'Platinum';
      case TournamentTier.special:
        return 'Special';
    }
  }

  String get emoji {
    switch (this) {
      case TournamentTier.bronze:
        return '🥉';
      case TournamentTier.silver:
        return '🥈';
      case TournamentTier.gold:
        return '🥇';
      case TournamentTier.platinum:
        return '💎';
      case TournamentTier.special:
        return '⭐';
    }
  }
}

/// Entry fee type
enum EntryFeeType {
  coins,
  gems,
  freeTicket;
}

/// Obstacle movement pattern type (for Phase 2)
enum ObstaclePatternType {
  static,
  verticalOscillate,
  horizontalApproach,
  diagonal;
}

/// Tournament progression type
enum TournamentProgressionType {
  /// Linear progression through levels (world map style)
  linear,
  /// Playoff bracket style (16→8→4→finals)
  playoff;
}

/// Booster type for tournament rewards
enum BoosterType {
  hearts6For24Hours,
  doubleCoins,
  shieldStart;
  
  String get displayName {
    switch (this) {
      case BoosterType.hearts6For24Hours:
        return '6 Hearts for 24 Hours';
      case BoosterType.doubleCoins:
        return 'Double Coins';
      case BoosterType.shieldStart:
        return 'Start with Shield';
    }
  }
  
  int get durationHours {
    switch (this) {
      case BoosterType.hearts6For24Hours:
        return 24;
      case BoosterType.doubleCoins:
        return 12;
      case BoosterType.shieldStart:
        return 6;
    }
  }
}

/// Tournament status
enum TournamentStatus {
  active,
  upcoming,
  ended,
  hidden;
}

/// Main tournament configuration
class TournamentConfig {
  final String id;
  final String name;
  final String description;
  final TournamentTier tier;
  final TournamentStatus status;
  final TournamentProgressionType progressionType;
  final TournamentEntryConfig entry;
  final TournamentTriesConfig tries;
  final TournamentContinuesConfig continues;
  final List<TournamentLevel> levels;
  final TournamentReward completionReward;
  final TournamentSpecialDeal? loseAllTriesOffer;
  final TournamentDisplay display;
  final TournamentUnlockRequirement? unlockRequirement;
  final PlayoffBracketConfig? playoffConfig;

  const TournamentConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.tier,
    required this.status,
    this.progressionType = TournamentProgressionType.linear,
    required this.entry,
    required this.tries,
    required this.continues,
    required this.levels,
    required this.completionReward,
    this.loseAllTriesOffer,
    required this.display,
    this.unlockRequirement,
    this.playoffConfig,
  });
  
  /// Whether this is a playoff-style tournament
  bool get isPlayoff => progressionType == TournamentProgressionType.playoff;

  /// Total rounds in the tournament
  int get totalRounds => levels.length;

  /// Total possible rewards from all rounds
  int get totalCoinsFromRounds => 
      levels.fold(0, (sum, level) => sum + level.reward.coins);
  
  int get totalGemsFromRounds => 
      levels.fold(0, (sum, level) => sum + level.reward.gems);

  /// Check if user can enter (has enough currency or ticket)
  bool canEnter({required int userCoins, required int userGems, required bool hasTicket}) {
    if (hasTicket && entry.freeTicketTier == tier) {
      return true;
    }
    
    switch (entry.type) {
      case EntryFeeType.coins:
        return userCoins >= entry.amount;
      case EntryFeeType.gems:
        return userGems >= entry.amount;
      case EntryFeeType.freeTicket:
        return hasTicket;
    }
  }

  /// Parse from JSON
  factory TournamentConfig.fromJson(Map<String, dynamic> json) {
    return TournamentConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      tier: TournamentTier.values.firstWhere(
        (t) => t.name == json['tier'],
        orElse: () => TournamentTier.bronze,
      ),
      status: TournamentStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => TournamentStatus.active,
      ),
      progressionType: TournamentProgressionType.values.firstWhere(
        (p) => p.name == json['progression_type'],
        orElse: () => TournamentProgressionType.linear,
      ),
      entry: TournamentEntryConfig.fromJson(json['entry'] as Map<String, dynamic>),
      tries: TournamentTriesConfig.fromJson(json['tries'] as Map<String, dynamic>),
      continues: TournamentContinuesConfig.fromJson(json['continues'] as Map<String, dynamic>),
      levels: (json['levels'] as List<dynamic>)
          .map((l) => TournamentLevel.fromJson(l as Map<String, dynamic>))
          .toList(),
      completionReward: TournamentReward.fromJson(json['completion_reward'] as Map<String, dynamic>),
      loseAllTriesOffer: json['lose_all_tries_offer'] != null
          ? TournamentSpecialDeal.fromJson(json['lose_all_tries_offer'] as Map<String, dynamic>)
          : null,
      display: TournamentDisplay.fromJson(json['display'] as Map<String, dynamic>),
      unlockRequirement: json['unlock_requirement'] != null
          ? TournamentUnlockRequirement.fromJson(json['unlock_requirement'] as Map<String, dynamic>)
          : null,
      playoffConfig: json['playoff_config'] != null
          ? PlayoffBracketConfig.fromJson(json['playoff_config'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'tier': tier.name,
    'status': status.name,
    'progression_type': progressionType.name,
    'entry': entry.toJson(),
    'tries': tries.toJson(),
    'continues': continues.toJson(),
    'levels': levels.map((l) => l.toJson()).toList(),
    'completion_reward': completionReward.toJson(),
    'lose_all_tries_offer': loseAllTriesOffer?.toJson(),
    'display': display.toJson(),
    'unlock_requirement': unlockRequirement?.toJson(),
    'playoff_config': playoffConfig?.toJson(),
  };

  /// Load all tournaments from assets (local JSON file)
  /// Can be extended to load from Remote Config for server-side control
  static Future<List<TournamentConfig>> loadAllTournaments() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/tournaments.json');
      final decoded = jsonDecode(jsonString);
      
      // Handle both single tournament and array of tournaments
      if (decoded is List) {
        return decoded
            .map((t) => TournamentConfig.fromJson(t as Map<String, dynamic>))
            .toList();
      } else if (decoded is Map) {
        // Single tournament or wrapped in 'tournaments' key
        if (decoded.containsKey('tournaments')) {
          return (decoded['tournaments'] as List)
              .map((t) => TournamentConfig.fromJson(t as Map<String, dynamic>))
              .toList();
        } else {
          return [TournamentConfig.fromJson(decoded as Map<String, dynamic>)];
        }
      }
      
      safePrint('🏆 ⚠️ Unexpected tournaments.json format');
      return [];
    } catch (e) {
      safePrint('🏆 ❌ Failed to load tournaments: $e');
      return [];
    }
  }
}

/// Entry fee configuration
class TournamentEntryConfig {
  final EntryFeeType type;
  final int amount;
  final TournamentTier? freeTicketTier;

  const TournamentEntryConfig({
    required this.type,
    required this.amount,
    this.freeTicketTier,
  });

  factory TournamentEntryConfig.fromJson(Map<String, dynamic> json) {
    return TournamentEntryConfig(
      type: EntryFeeType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => EntryFeeType.coins,
      ),
      amount: json['amount'] as int? ?? 0,
      freeTicketTier: json['free_ticket_tier'] != null
          ? TournamentTier.values.firstWhere(
              (t) => t.name == json['free_ticket_tier'],
              orElse: () => TournamentTier.bronze,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'amount': amount,
    'free_ticket_tier': freeTicketTier?.name,
  };
}

/// Tries configuration
class TournamentTriesConfig {
  final int count;

  const TournamentTriesConfig({required this.count});

  factory TournamentTriesConfig.fromJson(Map<String, dynamic> json) {
    return TournamentTriesConfig(
      count: json['count'] as int? ?? 3,
    );
  }

  Map<String, dynamic> toJson() => {'count': count};
}

/// Continues configuration
class TournamentContinuesConfig {
  final int maxPerTry;
  final int gemCost;
  final bool adAvailable;

  const TournamentContinuesConfig({
    required this.maxPerTry,
    required this.gemCost,
    required this.adAvailable,
  });

  factory TournamentContinuesConfig.fromJson(Map<String, dynamic> json) {
    return TournamentContinuesConfig(
      maxPerTry: json['max_per_try'] as int? ?? 5,
      gemCost: json['gem_cost'] as int? ?? 3,
      adAvailable: json['ad_available'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'max_per_try': maxPerTry,
    'gem_cost': gemCost,
    'ad_available': adAvailable,
  };
}

/// Tournament level/round configuration
class TournamentLevel {
  final int round;
  final String name;
  final String background;
  final String? opponentJet;
  final TournamentDifficulty difficulty;
  final List<ObstaclePattern> obstaclePatterns;
  final TournamentReward reward;
  
  /// Stunt mode configuration (if present, level uses stunt obstacles)
  /// Contains: mode, asset_path, obstacle_size_percent, spawn_interval, etc.
  final Map<String, dynamic>? stuntConfig;
  
  /// Whether this level uses stunt mode (single moving obstacles)
  bool get isStuntMode => stuntConfig != null;

  const TournamentLevel({
    required this.round,
    required this.name,
    required this.background,
    this.opponentJet,
    required this.difficulty,
    required this.obstaclePatterns,
    required this.reward,
    this.stuntConfig,
  });

  factory TournamentLevel.fromJson(Map<String, dynamic> json) {
    final obstaclesJson = json['obstacles'] as Map<String, dynamic>?;
    final patternMix = obstaclesJson?['pattern_mix'] as List<dynamic>? ?? [];
    
    // Handle null difficulty (playoff tournaments don't use this - they use boss_battle config)
    final difficultyJson = json['difficulty'] as Map<String, dynamic>?;
    final difficulty = difficultyJson != null
        ? TournamentDifficulty.fromJson(difficultyJson)
        : const TournamentDifficulty(
            speedMultiplier: 1.0,
            obstacleGap: 350,
            obstacleFrequency: 2.5,
            maxGapShift: 50,
            requiredDistance: 50,
          );
    
    return TournamentLevel(
      round: json['round'] as int,
      name: json['name'] as String,
      background: json['background'] as String? ?? 'default',
      opponentJet: json['opponent_jet'] as String?,
      difficulty: difficulty,
      obstaclePatterns: patternMix
          .map((p) => ObstaclePattern.fromJson(p as Map<String, dynamic>))
          .toList(),
      reward: TournamentReward.fromJson(json['reward'] as Map<String, dynamic>),
      stuntConfig: json['stunt_config'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    'round': round,
    'name': name,
    'background': background,
    'opponent_jet': opponentJet,
    'difficulty': difficulty.toJson(),
    'obstacles': {
      'pattern_mix': obstaclePatterns.map((p) => p.toJson()).toList(),
    },
    'reward': reward.toJson(),
    if (stuntConfig != null) 'stunt_config': stuntConfig,
  };
}

/// Difficulty parameters (matching existing level system)
class TournamentDifficulty {
  final double speedMultiplier;
  final int obstacleGap;
  final double obstacleFrequency;
  final int maxGapShift;
  final int requiredDistance;

  const TournamentDifficulty({
    required this.speedMultiplier,
    required this.obstacleGap,
    required this.obstacleFrequency,
    required this.maxGapShift,
    required this.requiredDistance,
  });

  factory TournamentDifficulty.fromJson(Map<String, dynamic> json) {
    return TournamentDifficulty(
      speedMultiplier: (json['speedMultiplier'] as num?)?.toDouble() ?? 1.0,
      obstacleGap: json['obstacleGap'] as int? ?? 350,
      obstacleFrequency: (json['obstacleFrequency'] as num?)?.toDouble() ?? 2.5,
      maxGapShift: json['maxGapShift'] as int? ?? 50,
      requiredDistance: json['requiredDistance'] as int? ?? 50,
    );
  }

  Map<String, dynamic> toJson() => {
    'speedMultiplier': speedMultiplier,
    'obstacleGap': obstacleGap,
    'obstacleFrequency': obstacleFrequency,
    'maxGapShift': maxGapShift,
    'requiredDistance': requiredDistance,
  };
}

/// Obstacle movement pattern (for Phase 2)
class ObstaclePattern {
  final ObstaclePatternType type;
  final int weight;
  final Map<String, dynamic> params;

  const ObstaclePattern({
    required this.type,
    required this.weight,
    this.params = const {},
  });

  factory ObstaclePattern.fromJson(Map<String, dynamic> json) {
    return ObstaclePattern(
      type: ObstaclePatternType.values.firstWhere(
        (t) => t.name == json['type'] || t.name == _snakeToCamel(json['type'] as String? ?? 'static'),
        orElse: () => ObstaclePatternType.static,
      ),
      weight: json['weight'] as int? ?? 100,
      params: json['params'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'weight': weight,
    'params': params,
  };
  
  static String _snakeToCamel(String snake) {
    final parts = snake.split('_');
    if (parts.length == 1) return snake;
    return parts.first + parts.skip(1).map((s) => 
      s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : s
    ).join();
  }
}

/// Reward configuration
class TournamentReward {
  final int coins;
  final int gems;
  final String? skinId;
  final String? trophyId;
  final TournamentTier? freeTicketTier; // Free ticket to another tournament tier
  final BoosterReward? booster; // Time-limited booster

  const TournamentReward({
    this.coins = 0,
    this.gems = 0,
    this.skinId,
    this.trophyId,
    this.freeTicketTier,
    this.booster,
  });

  factory TournamentReward.fromJson(Map<String, dynamic> json) {
    return TournamentReward(
      coins: json['coins'] as int? ?? 0,
      gems: json['gems'] as int? ?? 0,
      skinId: json['skin_id'] as String?,
      trophyId: json['trophy_id'] as String?,
      freeTicketTier: json['free_ticket_tier'] != null
          ? TournamentTier.values.firstWhere(
              (t) => t.name == json['free_ticket_tier'],
              orElse: () => TournamentTier.bronze,
            )
          : null,
      booster: json['booster'] != null
          ? BoosterReward.fromJson(json['booster'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'coins': coins,
    'gems': gems,
    'skin_id': skinId,
    'trophy_id': trophyId,
    'free_ticket_tier': freeTicketTier?.name,
    'booster': booster?.toJson(),
  };

  /// Check if this reward has any value
  bool get hasReward => 
      coins > 0 || 
      gems > 0 || 
      skinId != null || 
      trophyId != null || 
      freeTicketTier != null ||
      booster != null;
      
  /// Get all reward items as display strings
  List<String> get rewardDescriptions {
    final items = <String>[];
    if (coins > 0) items.add('$coins Coins');
    if (gems > 0) items.add('$gems Gems');
    if (skinId != null) items.add('Exclusive Jet Skin');
    if (freeTicketTier != null) items.add('Free Ticket (${freeTicketTier!.displayName})');
    if (booster != null) items.add(booster!.displayName);
    if (trophyId != null) items.add('Trophy');
    return items;
  }
}

/// Booster reward configuration
class BoosterReward {
  final BoosterType type;
  final int durationHours;

  const BoosterReward({
    required this.type,
    required this.durationHours,
  });

  factory BoosterReward.fromJson(Map<String, dynamic> json) {
    return BoosterReward(
      type: BoosterType.values.firstWhere(
        (b) => b.name == json['type'],
        orElse: () => BoosterType.hearts6For24Hours,
      ),
      durationHours: json['duration_hours'] as int? ?? 24,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'duration_hours': durationHours,
  };
  
  String get displayName => '${type.displayName} ($durationHours hrs)';
}

/// Special deal when losing all tries
class TournamentSpecialDeal {
  final bool enabled;
  final int discountPercent;
  final int extraTries;
  final int baseGemCost;

  const TournamentSpecialDeal({
    required this.enabled,
    required this.discountPercent,
    required this.extraTries,
    required this.baseGemCost,
  });

  /// Actual cost after discount
  int get discountedGemCost => 
      (baseGemCost * (100 - discountPercent) / 100).round();

  factory TournamentSpecialDeal.fromJson(Map<String, dynamic> json) {
    return TournamentSpecialDeal(
      enabled: json['enabled'] as bool? ?? false,
      discountPercent: json['discount_percent'] as int? ?? 0,
      extraTries: json['extra_tries'] as int? ?? 2,
      baseGemCost: json['base_gem_cost'] as int? ?? 200,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'discount_percent': discountPercent,
    'extra_tries': extraTries,
    'base_gem_cost': baseGemCost,
  };
}

/// Display configuration
class TournamentDisplay {
  final String bannerImage;
  final String icon;
  final String colorPrimary;
  final String? colorSecondary;

  const TournamentDisplay({
    required this.bannerImage,
    required this.icon,
    required this.colorPrimary,
    this.colorSecondary,
  });

  factory TournamentDisplay.fromJson(Map<String, dynamic> json) {
    return TournamentDisplay(
      bannerImage: json['banner_image'] as String? ?? 'tournament_default_banner',
      icon: json['icon'] as String? ?? 'trophy_bronze',
      colorPrimary: json['color_primary'] as String? ?? '#CD7F32',
      colorSecondary: json['color_secondary'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'banner_image': bannerImage,
    'icon': icon,
    'color_primary': colorPrimary,
    'color_secondary': colorSecondary,
  };
}

/// Unlock requirement
class TournamentUnlockRequirement {
  final String type; // 'level', 'trophies', 'none'
  final int? value;

  const TournamentUnlockRequirement({
    required this.type,
    this.value,
  });

  bool isUnlocked({int currentLevel = 0, int totalTrophies = 0}) {
    switch (type) {
      case 'level':
        return currentLevel >= (value ?? 0);
      case 'trophies':
        return totalTrophies >= (value ?? 0);
      case 'none':
      default:
        return true;
    }
  }

  factory TournamentUnlockRequirement.fromJson(Map<String, dynamic> json) {
    return TournamentUnlockRequirement(
      type: json['type'] as String? ?? 'none',
      value: json['value'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'value': value,
  };
}

/// Playoff bracket configuration for tournament-style progression
/// 
/// Supports 8-jet brackets with 3 rounds (Quarter Finals → Semi Finals → Grand Finals)
/// or 16-jet brackets with 4 rounds.
/// 
/// Each bracket has seeded matchups defined in [bracketMatchups].
class PlayoffBracketConfig {
  final int totalOpponents; // e.g., 8 for an 8-player bracket
  final List<PlayoffRound> rounds; // Quarter Finals, Semi Finals, Grand Finals
  final List<String> opponentJetSkins; // Pool of jet skins for opponents (should match totalOpponents)
  final List<BracketMatchup> bracketMatchups; // Initial seeded matchups

  const PlayoffBracketConfig({
    required this.totalOpponents,
    required this.rounds,
    required this.opponentJetSkins,
    this.bracketMatchups = const [],
  });

  factory PlayoffBracketConfig.fromJson(Map<String, dynamic> json) {
    final totalOpponents = json['total_opponents'] as int? ?? 8;
    final opponentJetSkins = (json['opponent_jet_skins'] as List<dynamic>?)
            ?.cast<String>() ?? [];
    
    // Parse explicit matchups or generate default seeding
    final matchupsJson = json['bracket_matchups'] as List<dynamic>?;
    List<BracketMatchup> matchups;
    
    if (matchupsJson != null && matchupsJson.isNotEmpty) {
      matchups = matchupsJson
          .map((m) => BracketMatchup.fromJson(m as Map<String, dynamic>))
          .toList();
    } else {
      // Generate default seeding: 1v8, 2v7, 3v6, 4v5 for 8-jet bracket
      matchups = _generateDefaultMatchups(opponentJetSkins);
    }
    
    return PlayoffBracketConfig(
      totalOpponents: totalOpponents,
      rounds: (json['rounds'] as List<dynamic>?)
              ?.map((r) => PlayoffRound.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      opponentJetSkins: opponentJetSkins,
      bracketMatchups: matchups,
    );
  }
  
  /// Generate default bracket matchups from jet skins list
  /// For 8 jets: Player vs Jet1, Jet2 vs Jet3, Jet4 vs Jet5, Jet6 vs Jet7
  static List<BracketMatchup> _generateDefaultMatchups(List<String> jetSkins) {
    if (jetSkins.isEmpty) return [];
    
    final matchups = <BracketMatchup>[];
    final numMatchups = jetSkins.length ~/ 2;
    
    for (int i = 0; i < numMatchups; i++) {
      final topIndex = i;
      final bottomIndex = jetSkins.length - 1 - i;
      
      if (topIndex >= bottomIndex) break;
      
      matchups.add(BracketMatchup(
        matchupId: i,
        position: i == 0 ? BracketPosition.playerSide : BracketPosition.opponentSide,
        topJetSkin: jetSkins[topIndex],
        bottomJetSkin: jetSkins[bottomIndex],
      ));
    }
    
    return matchups;
  }

  Map<String, dynamic> toJson() => {
    'total_opponents': totalOpponents,
    'rounds': rounds.map((r) => r.toJson()).toList(),
    'opponent_jet_skins': opponentJetSkins,
    'bracket_matchups': bracketMatchups.map((m) => m.toJson()).toList(),
  };
  
  /// Get the bracket stage name for a round number
  String getRoundStageName(int roundNumber) {
    if (roundNumber <= 0 || roundNumber > rounds.length) {
      return 'Round $roundNumber';
    }
    return rounds[roundNumber - 1].stageName;
  }
  
  /// Get number of matches in a given round
  /// Round 1: 4 matches (8 jets), Round 2: 2 matches (4 jets), Round 3: 1 match (2 jets)
  int getMatchesInRound(int roundNumber) {
    if (roundNumber <= 0) return totalOpponents ~/ 2;
    return totalOpponents ~/ (1 << roundNumber);
  }
  
  /// Get remaining opponents at a given round
  int getRemainingOpponents(int roundNumber) {
    if (roundNumber <= 0) return totalOpponents;
    // Each round halves the number of remaining opponents
    return totalOpponents ~/ (1 << (roundNumber));
  }
  
  /// Number of rounds in this bracket (3 for 8 jets, 4 for 16 jets)
  int get totalRounds => rounds.length;
}

/// Position in the bracket (player's side vs opponent's side)
enum BracketPosition {
  playerSide,
  opponentSide,
}

/// Represents a single matchup in the bracket (2 jets facing each other)
class BracketMatchup {
  final int matchupId;
  final BracketPosition position;
  final String topJetSkin;
  final String bottomJetSkin;
  final String? topJetName;
  final String? bottomJetName;

  const BracketMatchup({
    required this.matchupId,
    required this.position,
    required this.topJetSkin,
    required this.bottomJetSkin,
    this.topJetName,
    this.bottomJetName,
  });

  factory BracketMatchup.fromJson(Map<String, dynamic> json) {
    return BracketMatchup(
      matchupId: json['matchup_id'] as int? ?? 0,
      position: BracketPosition.values.firstWhere(
        (p) => p.name == json['position'],
        orElse: () => BracketPosition.opponentSide,
      ),
      topJetSkin: json['top_jet_skin'] as String? ?? 'sky_rookie',
      bottomJetSkin: json['bottom_jet_skin'] as String? ?? 'sky_rookie',
      topJetName: json['top_jet_name'] as String?,
      bottomJetName: json['bottom_jet_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'matchup_id': matchupId,
    'position': position.name,
    'top_jet_skin': topJetSkin,
    'bottom_jet_skin': bottomJetSkin,
    'top_jet_name': topJetName,
    'bottom_jet_name': bottomJetName,
  };
}

/// Individual round in a playoff bracket with boss battle configuration
class PlayoffRound {
  final int roundNumber;
  final String stageName; // "Quarter Finals", "Semi Finals", "Grand Finals"
  final String opponentJet; // Player's opponent jet for this round
  final String displayName; // Opponent display name
  final String? opponentNickname; // Optional fun nickname
  
  // Boss battle configuration
  final PlayoffBossBattle? bossBattle;

  const PlayoffRound({
    required this.roundNumber,
    required this.stageName,
    required this.opponentJet,
    required this.displayName,
    this.opponentNickname,
    this.bossBattle,
  });

  factory PlayoffRound.fromJson(Map<String, dynamic> json) {
    return PlayoffRound(
      roundNumber: json['round_number'] as int,
      stageName: json['stage_name'] as String? ?? 'Round ${json['round_number']}',
      opponentJet: json['opponent_jet'] as String? ?? 'sky_rookie',
      displayName: json['display_name'] as String? ?? 'Opponent',
      opponentNickname: json['opponent_nickname'] as String?,
      bossBattle: json['boss_battle'] != null
          ? PlayoffBossBattle.fromJson(json['boss_battle'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'round_number': roundNumber,
    'stage_name': stageName,
    'opponent_jet': opponentJet,
    'display_name': displayName,
    'opponent_nickname': opponentNickname,
    'boss_battle': bossBattle?.toJson(),
  };
}

/// Boss battle configuration for a playoff round
/// Defines background, obstacles, and boss AI abilities
class PlayoffBossBattle {
  final String background;
  final String obstacleTheme;   // Obstacle sprite (e.g., "phase1_wooden_pipes.png")
  final String music;           // Music track (e.g., "battle", "sky_rookie", "storm_ace")
  final double skillLevel;      // 0.0-1.0 (AI skill)
  final double reactionTime;    // Seconds delay before AI reacts
  final double mistakeRate;     // 0.0-1.0 (chance of AI mistakes)
  final int requiredDistance;   // Obstacles to pass to win
  final double speedMultiplier;
  final int obstacleGap;
  final double obstacleFrequency;
  final int maxGapShift;
  final List<ObstaclePattern> obstaclePatterns;

  const PlayoffBossBattle({
    required this.background,
    this.obstacleTheme = 'phase1_wooden_pipes.png',
    this.music = 'battle',      // Default to battle music for tournaments
    this.skillLevel = 0.6,
    this.reactionTime = 0.25,
    this.mistakeRate = 0.15,
    this.requiredDistance = 50,
    this.speedMultiplier = 1.0,
    this.obstacleGap = 350,
    this.obstacleFrequency = 2.5,
    this.maxGapShift = 50,
    this.obstaclePatterns = const [],
  });

  factory PlayoffBossBattle.fromJson(Map<String, dynamic> json) {
    final obstaclesJson = json['obstacles'] as Map<String, dynamic>?;
    final patternMix = obstaclesJson?['pattern_mix'] as List<dynamic>? ?? [];
    
    return PlayoffBossBattle(
      background: json['background'] as String? ?? 'phase1_dawn_complete.png',
      obstacleTheme: json['obstacle_theme'] as String? ?? 'phase1_wooden_pipes.png',
      music: json['music'] as String? ?? 'battle',
      skillLevel: (json['skill_level'] as num?)?.toDouble() ?? 0.6,
      reactionTime: (json['reaction_time'] as num?)?.toDouble() ?? 0.25,
      mistakeRate: (json['mistake_rate'] as num?)?.toDouble() ?? 0.15,
      requiredDistance: json['required_distance'] as int? ?? 50,
      speedMultiplier: (json['speed_multiplier'] as num?)?.toDouble() ?? 1.0,
      obstacleGap: json['obstacle_gap'] as int? ?? 350,
      obstacleFrequency: (json['obstacle_frequency'] as num?)?.toDouble() ?? 2.5,
      maxGapShift: json['max_gap_shift'] as int? ?? 50,
      obstaclePatterns: patternMix
          .map((p) => ObstaclePattern.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'background': background,
    'obstacle_theme': obstacleTheme,
    'music': music,
    'skill_level': skillLevel,
    'reaction_time': reactionTime,
    'mistake_rate': mistakeRate,
    'required_distance': requiredDistance,
    'speed_multiplier': speedMultiplier,
    'obstacle_gap': obstacleGap,
    'obstacle_frequency': obstacleFrequency,
    'max_gap_shift': maxGapShift,
    'obstacles': {
      'pattern_mix': obstaclePatterns.map((p) => p.toJson()).toList(),
    },
  };
}

/// Loader for tournament configurations
class TournamentConfigLoader {
  static List<TournamentConfig>? _cachedConfigs;
  
  /// Load tournaments from JSON asset
  static Future<List<TournamentConfig>> loadFromAsset() async {
    if (_cachedConfigs != null) {
      return _cachedConfigs!;
    }
    
    try {
      final jsonString = await rootBundle.loadString('assets/data/tournaments.json');
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      
      final tournaments = (jsonData['tournaments'] as List<dynamic>)
          .map((t) => TournamentConfig.fromJson(t as Map<String, dynamic>))
          .toList();
      
      _cachedConfigs = tournaments;
      safePrint('🏆 Loaded ${tournaments.length} tournaments from config');
      
      return tournaments;
    } catch (e, stackTrace) {
      safePrint('❌ Failed to load tournaments config: $e');
      safePrint('Stack: $stackTrace');
      return [];
    }
  }
  
  /// Clear cache (for hot reload during development)
  static void clearCache() {
    _cachedConfigs = null;
  }
  
  /// Get active tournaments only
  static Future<List<TournamentConfig>> getActiveTournaments() async {
    final all = await loadFromAsset();
    return all.where((t) => t.status == TournamentStatus.active).toList();
  }
  
  /// Get tournament by ID
  static Future<TournamentConfig?> getTournamentById(String id) async {
    final all = await loadFromAsset();
    try {
      return all.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}


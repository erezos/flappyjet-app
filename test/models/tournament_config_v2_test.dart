/// 🏆 Tournament Config V2 Tests
/// 
/// Tests for new tournament features:
/// - Playoff tournaments
/// - Free ticket rewards
/// - Booster rewards
/// - PlayoffBracketConfig
/// - BoosterReward

import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/models/tournament_config.dart';

void main() {
  group('TournamentProgressionType', () {
    test('should have linear and playoff types', () {
      expect(TournamentProgressionType.values.length, 2);
      expect(TournamentProgressionType.values, contains(TournamentProgressionType.linear));
      expect(TournamentProgressionType.values, contains(TournamentProgressionType.playoff));
    });
  });

  group('BoosterType', () {
    test('should have correct display names', () {
      expect(BoosterType.hearts6For24Hours.displayName, '6 Hearts for 24 Hours');
      expect(BoosterType.doubleCoins.displayName, 'Double Coins');
      expect(BoosterType.shieldStart.displayName, 'Start with Shield');
    });

    test('should have correct duration hours', () {
      expect(BoosterType.hearts6For24Hours.durationHours, 24);
      expect(BoosterType.doubleCoins.durationHours, 12);
      expect(BoosterType.shieldStart.durationHours, 6);
    });
  });

  group('BoosterReward', () {
    test('should parse from JSON', () {
      final json = {
        'type': 'hearts6For24Hours',
        'duration_hours': 24,
      };

      final booster = BoosterReward.fromJson(json);
      
      expect(booster.type, BoosterType.hearts6For24Hours);
      expect(booster.durationHours, 24);
    });

    test('should serialize to JSON', () {
      const booster = BoosterReward(
        type: BoosterType.doubleCoins,
        durationHours: 12,
      );

      final json = booster.toJson();
      
      expect(json['type'], 'doubleCoins');
      expect(json['duration_hours'], 12);
    });

    test('should have correct display name', () {
      const booster = BoosterReward(
        type: BoosterType.hearts6For24Hours,
        durationHours: 48,
      );

      expect(booster.displayName, '6 Hearts for 24 Hours (48 hrs)');
    });
  });

  group('TournamentReward with new features', () {
    test('should parse free ticket tier from JSON', () {
      final json = {
        'coins': 1000,
        'gems': 50,
        'free_ticket_tier': 'silver',
      };

      final reward = TournamentReward.fromJson(json);
      
      expect(reward.coins, 1000);
      expect(reward.gems, 50);
      expect(reward.freeTicketTier, TournamentTier.silver);
    });

    test('should parse booster reward from JSON', () {
      final json = {
        'coins': 500,
        'gems': 25,
        'booster': {
          'type': 'hearts6For24Hours',
          'duration_hours': 24,
        },
      };

      final reward = TournamentReward.fromJson(json);
      
      expect(reward.coins, 500);
      expect(reward.booster, isNotNull);
      expect(reward.booster!.type, BoosterType.hearts6For24Hours);
      expect(reward.booster!.durationHours, 24);
    });

    test('should serialize free ticket tier to JSON', () {
      const reward = TournamentReward(
        coins: 1000,
        gems: 50,
        freeTicketTier: TournamentTier.gold,
      );

      final json = reward.toJson();
      
      expect(json['coins'], 1000);
      expect(json['gems'], 50);
      expect(json['free_ticket_tier'], 'gold');
    });

    test('should serialize booster to JSON', () {
      const reward = TournamentReward(
        coins: 500,
        booster: BoosterReward(
          type: BoosterType.shieldStart,
          durationHours: 6,
        ),
      );

      final json = reward.toJson();
      
      expect(json['booster'], isNotNull);
      expect(json['booster']['type'], 'shieldStart');
      expect(json['booster']['duration_hours'], 6);
    });

    test('hasReward should return true for free ticket', () {
      const reward = TournamentReward(
        freeTicketTier: TournamentTier.bronze,
      );

      expect(reward.hasReward, true);
    });

    test('hasReward should return true for booster', () {
      const reward = TournamentReward(
        booster: BoosterReward(
          type: BoosterType.doubleCoins,
          durationHours: 12,
        ),
      );

      expect(reward.hasReward, true);
    });

    test('rewardDescriptions should include all reward types', () {
      const reward = TournamentReward(
        coins: 1000,
        gems: 50,
        skinId: 'space_destroyer',
        freeTicketTier: TournamentTier.silver,
        booster: BoosterReward(
          type: BoosterType.hearts6For24Hours,
          durationHours: 24,
        ),
        trophyId: 'champion_trophy',
      );

      final descriptions = reward.rewardDescriptions;
      
      expect(descriptions, contains('1000 Coins'));
      expect(descriptions, contains('50 Gems'));
      expect(descriptions, contains('Exclusive Jet Skin'));
      expect(descriptions, contains('Free Ticket (Silver)'));
      expect(descriptions, contains('6 Hearts for 24 Hours (24 hrs)'));
      expect(descriptions, contains('Trophy'));
    });
  });

  group('PlayoffRound', () {
    test('should parse from JSON', () {
      final json = {
        'round_number': 1,
        'stage_name': 'Quarter Finals',
        'opponent_jet': 'desert_storm',
        'display_name': 'Storm Walker',
        'opponent_nickname': 'The Desert Phantom',
      };

      final round = PlayoffRound.fromJson(json);
      
      expect(round.roundNumber, 1);
      expect(round.stageName, 'Quarter Finals');
      expect(round.opponentJet, 'desert_storm');
      expect(round.displayName, 'Storm Walker');
      expect(round.opponentNickname, 'The Desert Phantom');
    });

    test('should serialize to JSON', () {
      const round = PlayoffRound(
        roundNumber: 2,
        stageName: 'Semi Finals',
        opponentJet: 'defender',
        displayName: 'Iron Shield',
        opponentNickname: 'The Impenetrable',
      );

      final json = round.toJson();
      
      expect(json['round_number'], 2);
      expect(json['stage_name'], 'Semi Finals');
      expect(json['opponent_jet'], 'defender');
      expect(json['display_name'], 'Iron Shield');
      expect(json['opponent_nickname'], 'The Impenetrable');
    });

    test('should handle missing optional fields', () {
      final json = {
        'round_number': 1,
        'opponent_jet': 'sky_rookie',
        'display_name': 'Opponent',
      };

      final round = PlayoffRound.fromJson(json);
      
      expect(round.roundNumber, 1);
      expect(round.stageName, 'Round 1'); // Default
      expect(round.opponentNickname, isNull);
    });
  });

  group('PlayoffBracketConfig', () {
    test('should parse from JSON', () {
      final json = {
        'total_opponents': 16,
        'opponent_jet_skins': ['desert_storm', 'defender', 'red_alert', 'space_destroyer'],
        'rounds': [
          {
            'round_number': 1,
            'stage_name': 'Round of 16',
            'opponent_jet': 'desert_storm',
            'display_name': 'Storm Walker',
          },
          {
            'round_number': 2,
            'stage_name': 'Quarter Finals',
            'opponent_jet': 'defender',
            'display_name': 'Iron Shield',
          },
        ],
      };

      final config = PlayoffBracketConfig.fromJson(json);
      
      expect(config.totalOpponents, 16);
      expect(config.opponentJetSkins.length, 4);
      expect(config.rounds.length, 2);
      expect(config.rounds[0].stageName, 'Round of 16');
      expect(config.rounds[1].stageName, 'Quarter Finals');
    });

    test('should serialize to JSON', () {
      const config = PlayoffBracketConfig(
        totalOpponents: 8,
        rounds: [
          PlayoffRound(
            roundNumber: 1,
            stageName: 'Quarter Finals',
            opponentJet: 'storm_chaser',
            displayName: 'Thunder Hawk',
          ),
        ],
        opponentJetSkins: ['storm_chaser', 'cobra_strike'],
      );

      final json = config.toJson();
      
      expect(json['total_opponents'], 8);
      expect(json['opponent_jet_skins'], ['storm_chaser', 'cobra_strike']);
      expect((json['rounds'] as List).length, 1);
    });

    test('getRoundStageName should return correct stage name', () {
      const config = PlayoffBracketConfig(
        totalOpponents: 16,
        rounds: [
          PlayoffRound(
            roundNumber: 1,
            stageName: 'Round of 16',
            opponentJet: 'desert_storm',
            displayName: 'Opponent 1',
          ),
          PlayoffRound(
            roundNumber: 2,
            stageName: 'Quarter Finals',
            opponentJet: 'defender',
            displayName: 'Opponent 2',
          ),
          PlayoffRound(
            roundNumber: 3,
            stageName: 'Semi Finals',
            opponentJet: 'red_alert',
            displayName: 'Opponent 3',
          ),
          PlayoffRound(
            roundNumber: 4,
            stageName: 'Grand Finals',
            opponentJet: 'space_destroyer',
            displayName: 'Opponent 4',
          ),
        ],
        opponentJetSkins: [],
      );

      expect(config.getRoundStageName(1), 'Round of 16');
      expect(config.getRoundStageName(2), 'Quarter Finals');
      expect(config.getRoundStageName(3), 'Semi Finals');
      expect(config.getRoundStageName(4), 'Grand Finals');
    });

    test('getRemainingOpponents should calculate correctly', () {
      const config = PlayoffBracketConfig(
        totalOpponents: 16,
        rounds: [],
        opponentJetSkins: [],
      );

      expect(config.getRemainingOpponents(0), 16);
      expect(config.getRemainingOpponents(1), 8);  // After round 1: 16/2 = 8
      expect(config.getRemainingOpponents(2), 4);  // After round 2: 16/4 = 4
      expect(config.getRemainingOpponents(3), 2);  // After round 3: 16/8 = 2
      expect(config.getRemainingOpponents(4), 1);  // After round 4: 16/16 = 1
    });
  });

  group('TournamentConfig with playoff', () {
    test('should parse progression type from JSON', () {
      final json = {
        'id': 'bosses_showdown',
        'name': 'Bosses Showdown',
        'description': 'Epic playoff battle!',
        'tier': 'bronze',
        'status': 'active',
        'progression_type': 'playoff',
        'entry': {'type': 'coins', 'amount': 0},
        'tries': {'count': 3},
        'continues': {'max_per_try': 5, 'gem_cost': 3, 'ad_available': true},
        'levels': [
          {
            'round': 1,
            'name': 'Round 1',
            'background': 'desert',
            'difficulty': {
              'speedMultiplier': 1.0,
              'obstacleGap': 350,
              'obstacleFrequency': 2.5,
              'maxGapShift': 50,
              'requiredDistance': 50,
            },
            'obstacles': {'pattern_mix': []},
            'reward': {'coins': 100, 'gems': 5},
          },
        ],
        'completion_reward': {'coins': 1000, 'gems': 50},
        'display': {
          'banner_image': 'test.png',
          'icon': 'trophy',
          'color_primary': '#FF6B35',
        },
      };

      final config = TournamentConfig.fromJson(json);
      
      expect(config.progressionType, TournamentProgressionType.playoff);
      expect(config.isPlayoff, true);
    });

    test('should default to linear progression type', () {
      final json = {
        'id': 'stunt_tournament',
        'name': 'Stunt Tournament',
        'description': 'Linear tournament!',
        'tier': 'silver',
        'status': 'active',
        // No progression_type specified
        'entry': {'type': 'coins', 'amount': 1000},
        'tries': {'count': 3},
        'continues': {'max_per_try': 5, 'gem_cost': 3, 'ad_available': true},
        'levels': [
          {
            'round': 1,
            'name': 'Round 1',
            'background': 'city',
            'difficulty': {
              'speedMultiplier': 1.0,
              'obstacleGap': 350,
              'obstacleFrequency': 2.5,
              'maxGapShift': 50,
              'requiredDistance': 50,
            },
            'obstacles': {'pattern_mix': []},
            'reward': {'coins': 100, 'gems': 5},
          },
        ],
        'completion_reward': {'coins': 2000, 'gems': 30},
        'display': {
          'banner_image': 'stunt.png',
          'icon': 'trophy_silver',
          'color_primary': '#9E9E9E',
        },
      };

      final config = TournamentConfig.fromJson(json);
      
      expect(config.progressionType, TournamentProgressionType.linear);
      expect(config.isPlayoff, false);
    });

    test('should parse playoff config from JSON', () {
      final json = {
        'id': 'playoff_test',
        'name': 'Playoff Test',
        'description': 'Test',
        'tier': 'gold',
        'status': 'active',
        'progression_type': 'playoff',
        'entry': {'type': 'gems', 'amount': 50},
        'tries': {'count': 3},
        'continues': {'max_per_try': 5, 'gem_cost': 3, 'ad_available': true},
        'levels': [],
        'completion_reward': {'coins': 3000, 'gems': 75},
        'display': {
          'banner_image': 'playoff.png',
          'icon': 'trophy_gold',
          'color_primary': '#FFD700',
        },
        'playoff_config': {
          'total_opponents': 8,
          'opponent_jet_skins': ['lord_of_war', 'cobra_strike'],
          'rounds': [
            {
              'round_number': 1,
              'stage_name': 'Quarter Finals',
              'opponent_jet': 'storm_chaser',
              'display_name': 'Thunder Hawk',
            },
          ],
        },
      };

      final config = TournamentConfig.fromJson(json);
      
      expect(config.playoffConfig, isNotNull);
      expect(config.playoffConfig!.totalOpponents, 8);
      expect(config.playoffConfig!.rounds.length, 1);
      expect(config.playoffConfig!.rounds[0].stageName, 'Quarter Finals');
    });

    test('should serialize progression type to JSON', () {
      const config = TournamentConfig(
        id: 'test',
        name: 'Test',
        description: 'Test',
        tier: TournamentTier.bronze,
        status: TournamentStatus.active,
        progressionType: TournamentProgressionType.playoff,
        entry: TournamentEntryConfig(type: EntryFeeType.coins, amount: 0),
        tries: TournamentTriesConfig(count: 3),
        continues: TournamentContinuesConfig(
          maxPerTry: 5,
          gemCost: 3,
          adAvailable: true,
        ),
        levels: [],
        completionReward: TournamentReward(coins: 1000),
        display: TournamentDisplay(
          bannerImage: 'test.png',
          icon: 'trophy',
          colorPrimary: '#FF6B35',
        ),
      );

      final json = config.toJson();
      
      expect(json['progression_type'], 'playoff');
    });
  });

  group('Full tournament JSON parsing (Bosses Showdown)', () {
    test('should parse Bosses Showdown tournament with all features', () {
      // Simulate Bosses Showdown tournament from tournaments.json
      final json = {
        'id': 'bosses_showdown',
        'name': '⚔️ Bosses Showdown',
        'description': 'Face 4 legendary bosses in an epic playoff battle!',
        'tier': 'bronze',
        'status': 'active',
        'progression_type': 'playoff',
        'entry': {'type': 'coins', 'amount': 0, 'free_ticket_tier': 'bronze'},
        'tries': {'count': 3},
        'continues': {'max_per_try': 5, 'gem_cost': 3, 'ad_available': true},
        'playoff_config': {
          'total_opponents': 16,
          'opponent_jet_skins': ['desert_storm', 'defender'],
          'rounds': [
            {
              'round_number': 1,
              'stage_name': 'Round of 16',
              'opponent_jet': 'desert_storm',
              'display_name': 'Storm Walker',
              'opponent_nickname': 'The Desert Phantom',
            },
            {
              'round_number': 2,
              'stage_name': 'Quarter Finals',
              'opponent_jet': 'defender',
              'display_name': 'Iron Shield',
            },
            {
              'round_number': 3,
              'stage_name': 'Semi Finals',
              'opponent_jet': 'red_alert',
              'display_name': 'Crimson Fury',
            },
            {
              'round_number': 4,
              'stage_name': 'Grand Finals',
              'opponent_jet': 'space_destroyer',
              'display_name': 'Cosmic Overlord',
            },
          ],
        },
        'levels': [
          {
            'round': 1,
            'name': 'Round of 16',
            'background': 'desert',
            'opponent_jet': 'desert_storm',
            'difficulty': {
              'speedMultiplier': 0.95,
              'obstacleGap': 400,
              'obstacleFrequency': 2.8,
              'maxGapShift': 35,
              'requiredDistance': 40,
            },
            'obstacles': {'pattern_mix': [{'type': 'static', 'weight': 100}]},
            'reward': {'coins': 100, 'gems': 2},
          },
        ],
        'completion_reward': {
          'coins': 1000,
          'gems': 15,
          'skin_id': 'space_destroyer',
          'trophy_id': 'bosses_showdown_champion',
          'free_ticket_tier': 'silver',
          'booster': {
            'type': 'hearts6For24Hours',
            'duration_hours': 24,
          },
        },
        'lose_all_tries_offer': {
          'enabled': true,
          'discount_percent': 50,
          'extra_tries': 2,
          'base_gem_cost': 150,
        },
        'display': {
          'banner_image': 'tournament_bosses_showdown.png',
          'icon': 'trophy_gold',
          'color_primary': '#FF6B35',
          'color_secondary': '#F7931E',
        },
      };

      final config = TournamentConfig.fromJson(json);
      
      // Basic info
      expect(config.id, 'bosses_showdown');
      expect(config.name, '⚔️ Bosses Showdown');
      expect(config.isPlayoff, true);
      expect(config.tier, TournamentTier.bronze);
      
      // Entry (FREE)
      expect(config.entry.type, EntryFeeType.coins);
      expect(config.entry.amount, 0);
      
      // Playoff config
      expect(config.playoffConfig, isNotNull);
      expect(config.playoffConfig!.totalOpponents, 16);
      expect(config.playoffConfig!.rounds.length, 4);
      expect(config.playoffConfig!.getRoundStageName(1), 'Round of 16');
      expect(config.playoffConfig!.getRoundStageName(4), 'Grand Finals');
      
      // Completion reward with all features
      expect(config.completionReward.coins, 1000);
      expect(config.completionReward.gems, 15);
      expect(config.completionReward.skinId, 'space_destroyer');
      expect(config.completionReward.freeTicketTier, TournamentTier.silver);
      expect(config.completionReward.booster, isNotNull);
      expect(config.completionReward.booster!.type, BoosterType.hearts6For24Hours);
      expect(config.completionReward.booster!.durationHours, 24);
      
      // Reward descriptions
      final descriptions = config.completionReward.rewardDescriptions;
      expect(descriptions.length, 6); // coins, gems, skin, ticket, booster, trophy
    });
  });
}


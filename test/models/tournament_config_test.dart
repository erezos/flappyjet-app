/// Unit tests for TournamentConfig model
/// 
/// Tests JSON parsing, validation, and helper methods
import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/models/tournament_config.dart';

void main() {
  group('TournamentConfig', () {
    test('should parse valid JSON correctly', () {
      final json = {
        'id': 'test_tournament',
        'name': 'Test Cup',
        'description': 'A test tournament',
        'tier': 'bronze',
        'status': 'active',
        'entry': {
          'type': 'coins',
          'amount': 500,
          'free_ticket_tier': 'bronze',
        },
        'tries': {'count': 3},
        'continues': {
          'max_per_try': 5,
          'gem_cost': 3,
          'ad_available': true,
        },
        'levels': [
          {
            'round': 1,
            'name': 'Round 1',
            'background': 'desert',
            'difficulty': {
              'speedMultiplier': 1.0,
              'obstacleGap': 400,
              'obstacleFrequency': 2.5,
              'maxGapShift': 50,
              'requiredDistance': 50,
            },
            'obstacles': {
              'pattern_mix': [
                {'type': 'static', 'weight': 100}
              ]
            },
            'reward': {'coins': 100, 'gems': 0},
          }
        ],
        'completion_reward': {
          'coins': 1000,
          'gems': 20,
          'trophy_id': 'test_trophy',
        },
        'display': {
          'banner_image': 'test_banner',
          'icon': 'trophy_bronze',
          'color_primary': '#CD7F32',
        },
      };

      final config = TournamentConfig.fromJson(json);

      expect(config.id, equals('test_tournament'));
      expect(config.name, equals('Test Cup'));
      expect(config.tier, equals(TournamentTier.bronze));
      expect(config.status, equals(TournamentStatus.active));
      expect(config.entry.type, equals(EntryFeeType.coins));
      expect(config.entry.amount, equals(500));
      expect(config.tries.count, equals(3));
      expect(config.continues.maxPerTry, equals(5));
      expect(config.continues.gemCost, equals(3));
      expect(config.levels.length, equals(1));
      expect(config.completionReward.coins, equals(1000));
      expect(config.completionReward.gems, equals(20));
    });

    test('should calculate total rounds correctly', () {
      final json = _createMinimalTournamentJson(levelCount: 4);
      final config = TournamentConfig.fromJson(json);
      
      expect(config.totalRounds, equals(4));
    });

    test('should calculate total rewards from rounds', () {
      final json = {
        ..._createMinimalTournamentJson(levelCount: 0),
        'levels': [
          _createMinimalLevelJson(round: 1, coins: 100, gems: 5),
          _createMinimalLevelJson(round: 2, coins: 150, gems: 10),
          _createMinimalLevelJson(round: 3, coins: 200, gems: 15),
        ],
      };
      final config = TournamentConfig.fromJson(json);
      
      expect(config.totalCoinsFromRounds, equals(450));
      expect(config.totalGemsFromRounds, equals(30));
    });

    test('canEnter should return true when user has enough coins', () {
      final json = _createMinimalTournamentJson();
      final config = TournamentConfig.fromJson(json);
      
      expect(
        config.canEnter(userCoins: 1000, userGems: 0, hasTicket: false),
        isTrue,
      );
    });

    test('canEnter should return false when user lacks coins', () {
      final json = _createMinimalTournamentJson();
      final config = TournamentConfig.fromJson(json);
      
      expect(
        config.canEnter(userCoins: 100, userGems: 0, hasTicket: false),
        isFalse,
      );
    });

    test('canEnter should return true with matching free ticket', () {
      final json = _createMinimalTournamentJson();
      final config = TournamentConfig.fromJson(json);
      
      expect(
        config.canEnter(userCoins: 0, userGems: 0, hasTicket: true),
        isTrue,
      );
    });
  });

  group('TournamentTier', () {
    test('should have correct display names', () {
      expect(TournamentTier.bronze.displayName, equals('Bronze'));
      expect(TournamentTier.silver.displayName, equals('Silver'));
      expect(TournamentTier.gold.displayName, equals('Gold'));
      expect(TournamentTier.platinum.displayName, equals('Platinum'));
      expect(TournamentTier.special.displayName, equals('Special'));
    });

    test('should have correct emojis', () {
      expect(TournamentTier.bronze.emoji, equals('🥉'));
      expect(TournamentTier.silver.emoji, equals('🥈'));
      expect(TournamentTier.gold.emoji, equals('🥇'));
    });
  });

  group('TournamentSpecialDeal', () {
    test('should calculate discounted price correctly', () {
      final deal = TournamentSpecialDeal(
        enabled: true,
        discountPercent: 50,
        extraTries: 2,
        baseGemCost: 200,
      );

      expect(deal.discountedGemCost, equals(100));
    });

    test('should handle 0% discount', () {
      final deal = TournamentSpecialDeal(
        enabled: true,
        discountPercent: 0,
        extraTries: 2,
        baseGemCost: 200,
      );

      expect(deal.discountedGemCost, equals(200));
    });
  });

  group('TournamentUnlockRequirement', () {
    test('should unlock when level requirement met', () {
      final requirement = TournamentUnlockRequirement(
        type: 'level',
        value: 10,
      );

      expect(requirement.isUnlocked(currentLevel: 15), isTrue);
      expect(requirement.isUnlocked(currentLevel: 10), isTrue);
      expect(requirement.isUnlocked(currentLevel: 5), isFalse);
    });

    test('should always unlock when type is none', () {
      final requirement = TournamentUnlockRequirement(type: 'none');

      expect(requirement.isUnlocked(currentLevel: 0), isTrue);
    });
  });

  group('TournamentReward', () {
    test('hasReward should return true when coins > 0', () {
      final reward = TournamentReward(coins: 100);
      expect(reward.hasReward, isTrue);
    });

    test('hasReward should return false when all values are zero/null', () {
      final reward = TournamentReward();
      expect(reward.hasReward, isFalse);
    });

    test('hasReward should return true when skinId is set', () {
      final reward = TournamentReward(skinId: 'exclusive_skin');
      expect(reward.hasReward, isTrue);
    });
  });

  group('ObstaclePattern', () {
    test('should parse static pattern', () {
      final pattern = ObstaclePattern.fromJson({
        'type': 'static',
        'weight': 100,
      });

      expect(pattern.type, equals(ObstaclePatternType.static));
      expect(pattern.weight, equals(100));
    });

    test('should parse vertical_oscillate with params', () {
      final pattern = ObstaclePattern.fromJson({
        'type': 'vertical_oscillate',
        'weight': 30,
        'params': {
          'amplitude': 40,
          'frequency': 0.8,
        },
      });

      expect(pattern.type, equals(ObstaclePatternType.verticalOscillate));
      expect(pattern.weight, equals(30));
      expect(pattern.params['amplitude'], equals(40));
      expect(pattern.params['frequency'], equals(0.8));
    });
  });
}

/// Helper to create minimal tournament JSON for testing
Map<String, dynamic> _createMinimalTournamentJson({int levelCount = 1}) {
  return {
    'id': 'test',
    'name': 'Test',
    'description': '',
    'tier': 'bronze',
    'status': 'active',
    'entry': {
      'type': 'coins',
      'amount': 500,
      'free_ticket_tier': 'bronze',
    },
    'tries': {'count': 3},
    'continues': {
      'max_per_try': 5,
      'gem_cost': 3,
      'ad_available': true,
    },
    'levels': List.generate(
      levelCount,
      (i) => _createMinimalLevelJson(round: i + 1),
    ),
    'completion_reward': {'coins': 1000, 'gems': 20},
    'display': {
      'banner_image': 'test',
      'icon': 'test',
      'color_primary': '#000000',
    },
  };
}

/// Helper to create minimal level JSON for testing
Map<String, dynamic> _createMinimalLevelJson({
  required int round,
  int coins = 100,
  int gems = 0,
}) {
  return {
    'round': round,
    'name': 'Round $round',
    'background': 'default',
    'difficulty': {
      'speedMultiplier': 1.0,
      'obstacleGap': 400,
      'obstacleFrequency': 2.5,
      'maxGapShift': 50,
      'requiredDistance': 50,
    },
    'obstacles': {
      'pattern_mix': [
        {'type': 'static', 'weight': 100}
      ]
    },
    'reward': {'coins': coins, 'gems': gems},
  };
}


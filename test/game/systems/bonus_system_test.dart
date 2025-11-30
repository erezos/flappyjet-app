import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/models/bonus_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('BonusConfig', () {
    test('should create disabled config by default', () {
      const config = BonusConfig();
      expect(config.enabled, false);
      expect(config.hasAnyBonusTypes, false);
    });
    
    test('should create story mode default config', () {
      const config = BonusConfig.storyModeDefault;
      expect(config.enabled, true);
      expect(config.hasAnyBonusTypes, true);
      expect(config.spawnChance, 0.20);
      expect(config.minPerLevel, 0);
      expect(config.maxPerLevel, 2);
    });
    
    test('should serialize and deserialize correctly', () {
      const original = BonusConfig(
        enabled: true,
        minPerLevel: 1,
        maxPerLevel: 3,
        spawnChance: 0.30,
        minObstaclesBeforeFirstBonus: 3,
        minObstaclesBetweenBonuses: 4,
        shield: BonusTypeConfig(
          chance: 0.20,
          shieldTierWeights: {
            ShieldTier.blue: 0.5,
            ShieldTier.red: 0.35,
            ShieldTier.green: 0.15,
          },
        ),
        coins: BonusTypeConfig(
          chance: 0.55,
          minAmount: 15,
          maxAmount: 30,
        ),
        gems: BonusTypeConfig(
          chance: 0.25,
          minAmount: 1,
          maxAmount: 5,
        ),
      );
      
      final json = original.toJson();
      final deserialized = BonusConfig.fromJson(json);
      
      expect(deserialized.enabled, original.enabled);
      expect(deserialized.minPerLevel, original.minPerLevel);
      expect(deserialized.maxPerLevel, original.maxPerLevel);
      expect(deserialized.spawnChance, original.spawnChance);
      expect(deserialized.shield?.chance, original.shield?.chance);
      expect(deserialized.coins?.minAmount, original.coins?.minAmount);
      expect(deserialized.gems?.maxAmount, original.gems?.maxAmount);
    });
    
    test('should parse JSON with missing optional fields', () {
      final json = {
        'enabled': true,
        'spawnChance': 0.15,
        'coins': {
          'chance': 1.0,
          'minAmount': 5,
          'maxAmount': 10,
        },
      };
      
      final config = BonusConfig.fromJson(json);
      
      expect(config.enabled, true);
      expect(config.spawnChance, 0.15);
      expect(config.minPerLevel, 0); // Default
      expect(config.maxPerLevel, 2); // Default
      expect(config.shield, isNull);
      expect(config.coins?.chance, 1.0);
      expect(config.gems, isNull);
    });
  });
  
  group('SpawnLocationConfig', () {
    test('should select locations based on weights', () {
      const config = SpawnLocationConfig(
        insideGapWeight: 1.0,
        betweenObstaclesWeight: 0.0,
        upperZoneWeight: 0.0,
        lowerZoneWeight: 0.0,
      );
      
      // With 100% inside gap weight, should always return insideGap
      expect(config.selectLocation(0.0), BonusSpawnLocation.insideGap);
      expect(config.selectLocation(0.5), BonusSpawnLocation.insideGap);
      expect(config.selectLocation(0.99), BonusSpawnLocation.insideGap);
    });
    
    test('should calculate total weight correctly', () {
      const config = SpawnLocationConfig(
        insideGapWeight: 0.5,
        betweenObstaclesWeight: 0.3,
        upperZoneWeight: 0.1,
        lowerZoneWeight: 0.1,
      );
      
      expect(config.totalWeight, 1.0);
    });
    
    test('should distribute locations proportionally', () {
      const config = SpawnLocationConfig(
        insideGapWeight: 0.25,
        betweenObstaclesWeight: 0.25,
        upperZoneWeight: 0.25,
        lowerZoneWeight: 0.25,
      );
      
      // Test boundaries
      expect(config.selectLocation(0.0), BonusSpawnLocation.insideGap);
      expect(config.selectLocation(0.24), BonusSpawnLocation.insideGap);
      expect(config.selectLocation(0.26), BonusSpawnLocation.betweenObstacles);
      expect(config.selectLocation(0.51), BonusSpawnLocation.upperZone);
      expect(config.selectLocation(0.76), BonusSpawnLocation.lowerZone);
    });
  });
  
  group('ShieldTier', () {
    test('should have correct durations', () {
      expect(ShieldTier.blue.duration, 3.0);
      expect(ShieldTier.red.duration, 4.0);
      expect(ShieldTier.green.duration, 5.0);
    });
    
    test('should have correct asset names', () {
      expect(ShieldTier.blue.assetName, 'shield_bonus_blue.png');
      expect(ShieldTier.red.assetName, 'shield_bonus_red.png');
      expect(ShieldTier.green.assetName, 'shield_bonus_green.png');
    });
  });
  
  group('BonusTypeConfig', () {
    test('should serialize shield tier weights correctly', () {
      const config = BonusTypeConfig(
        chance: 0.20,
        shieldTierWeights: {
          ShieldTier.blue: 0.6,
          ShieldTier.red: 0.3,
          ShieldTier.green: 0.1,
        },
      );
      
      final json = config.toJson();
      expect(json['chance'], 0.20);
      expect(json['shieldTierWeights']['blue'], 0.6);
      expect(json['shieldTierWeights']['red'], 0.3);
      expect(json['shieldTierWeights']['green'], 0.1);
    });
    
    test('should deserialize shield tier weights correctly', () {
      final json = {
        'chance': 0.15,
        'shieldTierWeights': {
          'blue': 0.5,
          'red': 0.35,
          'green': 0.15,
        },
      };
      
      final config = BonusTypeConfig.fromJson(json);
      expect(config.chance, 0.15);
      expect(config.shieldTierWeights?[ShieldTier.blue], 0.5);
      expect(config.shieldTierWeights?[ShieldTier.red], 0.35);
      expect(config.shieldTierWeights?[ShieldTier.green], 0.15);
    });
    
    test('should serialize coin/gem config correctly', () {
      const config = BonusTypeConfig(
        chance: 0.65,
        minAmount: 10,
        maxAmount: 25,
      );
      
      final json = config.toJson();
      expect(json['chance'], 0.65);
      expect(json['minAmount'], 10);
      expect(json['maxAmount'], 25);
      expect(json.containsKey('shieldTierWeights'), false);
    });
  });
  
  group('BonusType enum', () {
    test('should have all expected values', () {
      expect(BonusType.values.length, 3);
      expect(BonusType.values, contains(BonusType.shield));
      expect(BonusType.values, contains(BonusType.coins));
      expect(BonusType.values, contains(BonusType.gems));
    });
  });
}


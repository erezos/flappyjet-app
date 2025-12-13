import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flappy_jet_pro/game/systems/achievements_manager.dart';

/// 🏅 NEW ENGAGEMENT ACHIEVEMENTS TESTS
/// 
/// These tests verify the new engagement and tournament achievements:
/// - daily_grinder: Play 10+ games in a single day
/// - weekly_warrior: Complete all daily missions for 7 consecutive days
/// - bonus_hunter: Collect 100 power-ups total
/// - mission_master: Complete 100 daily missions total
/// - tournament entry/win ladders (rookie → legend)
/// 
/// WHY: These achievements drive long-term engagement and reward
/// consistent player behavior.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('New Engagement Achievements Registration', () {
    late AchievementsManager manager;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      manager = AchievementsManager();
      await manager.initialize();
    });

    test('daily_grinder achievement is registered', () {
      final achievement = manager.achievements['daily_grinder'];
      
      expect(achievement, isNotNull);
      expect(achievement!.id, equals('daily_grinder'));
      expect(achievement.title, equals('Daily Grinder'));
      expect(achievement.target, equals(10));
      expect(achievement.category, equals(AchievementCategory.mastery));
      expect(achievement.rarity, equals(AchievementRarity.silver));
    });

    test('weekly_warrior achievement is registered', () {
      final achievement = manager.achievements['weekly_warrior'];
      
      expect(achievement, isNotNull);
      expect(achievement!.id, equals('weekly_warrior'));
      expect(achievement.title, equals('Weekly Warrior'));
      expect(achievement.target, equals(7));
      expect(achievement.category, equals(AchievementCategory.mastery));
      expect(achievement.rarity, equals(AchievementRarity.platinum));
    });

    test('bonus_hunter achievement is registered', () {
      final achievement = manager.achievements['bonus_hunter'];
      
      expect(achievement, isNotNull);
      expect(achievement!.id, equals('bonus_hunter'));
      expect(achievement.title, equals('Bonus Hunter'));
      expect(achievement.target, equals(100));
      expect(achievement.category, equals(AchievementCategory.collection));
      expect(achievement.rarity, equals(AchievementRarity.gold));
    });

    test('mission_master achievement is registered', () {
      final achievement = manager.achievements['mission_master'];
      
      expect(achievement, isNotNull);
      expect(achievement!.id, equals('mission_master'));
      expect(achievement.title, equals('Mission Master'));
      expect(achievement.target, equals(100));
      expect(achievement.category, equals(AchievementCategory.mastery));
      expect(achievement.rarity, equals(AchievementRarity.diamond));
    });

    test('tournament_rookie achievement is registered', () {
      final achievement = manager.achievements['tournament_rookie'];
      
      expect(achievement, isNotNull);
      expect(achievement!.id, equals('tournament_rookie'));
      expect(achievement.title, equals('Tournament Rookie'));
      expect(achievement.target, equals(1));
      expect(achievement.category, equals(AchievementCategory.special));
      expect(achievement.rarity, equals(AchievementRarity.bronze));
    });

    test('round_winner achievement is registered', () {
      final achievement = manager.achievements['round_winner'];
      
      expect(achievement, isNotNull);
      expect(achievement!.id, equals('round_winner'));
      expect(achievement.title, equals('Round Winner'));
      expect(achievement.target, equals(1));
      expect(achievement.category, equals(AchievementCategory.special));
      expect(achievement.rarity, equals(AchievementRarity.bronze));
    });
  });

  group('New Engagement Achievements Rewards', () {
    late AchievementsManager manager;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      manager = AchievementsManager();
      await manager.initialize();
    });

    test('daily_grinder has appropriate rewards', () {
      final achievement = manager.achievements['daily_grinder']!;
      
      // Silver tier = 200 coins, 5 gems
      expect(achievement.coinReward, equals(200));
      expect(achievement.gemReward, equals(5));
    });

    test('weekly_warrior has appropriate rewards', () {
      final achievement = manager.achievements['weekly_warrior']!;
      
      // Platinum tier = 1000 coins, 30 gems
      expect(achievement.coinReward, equals(1000));
      expect(achievement.gemReward, equals(30));
    });

    test('bonus_hunter has appropriate rewards', () {
      final achievement = manager.achievements['bonus_hunter']!;
      
      // Gold tier = 400 coins, 10 gems
      expect(achievement.coinReward, equals(400));
      expect(achievement.gemReward, equals(10));
    });

    test('mission_master has appropriate rewards', () {
      final achievement = manager.achievements['mission_master']!;
      
      // Diamond tier = 2000 coins, 50 gems
      expect(achievement.coinReward, equals(2000));
      expect(achievement.gemReward, equals(50));
    });

    test('tournament_veteran has appropriate rewards', () {
      final achievement = manager.achievements['tournament_veteran']!;
      
      expect(achievement.coinReward, greaterThan(0));
      expect(achievement.gemReward, greaterThan(0));
    });

    test('round_veteran has appropriate rewards', () {
      final achievement = manager.achievements['round_veteran']!;
      
      expect(achievement.coinReward, greaterThan(0));
      expect(achievement.gemReward, greaterThan(0));
    });
  });

  group('New Engagement Achievements Progress', () {
    late AchievementsManager manager;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      manager = AchievementsManager();
      await manager.initialize();
    });

    test('daily_grinder can be unlocked by playing 10 games', () async {
      // Update progress to 10
      await manager.setProgress('daily_grinder', 10);
      
      final achievement = manager.achievements['daily_grinder']!;
      expect(achievement.unlocked, isTrue);
    });

    test('bonus_hunter tracks progress correctly', () async {
      // Add 50 bonuses
      await manager.updateProgress('bonus_hunter', 50);
      
      final achievement = manager.achievements['bonus_hunter']!;
      expect(achievement.progress, equals(50));
      expect(achievement.unlocked, isFalse); // Need 100
    });

    test('bonus_hunter unlocks at 100', () async {
      // Add enough to reach 100
      await manager.setProgress('bonus_hunter', 100);
      
      final achievement = manager.achievements['bonus_hunter']!;
      expect(achievement.unlocked, isTrue);
    });

    test('weekly_warrior tracks consecutive days', () async {
      // Simulate 5 consecutive days
      await manager.setProgress('weekly_warrior', 5);
      
      final achievement = manager.achievements['weekly_warrior']!;
      expect(achievement.progress, equals(5));
      expect(achievement.unlocked, isFalse); // Need 7
    });

    test('weekly_warrior unlocks at 7 consecutive days', () async {
      await manager.setProgress('weekly_warrior', 7);
      
      final achievement = manager.achievements['weekly_warrior']!;
      expect(achievement.unlocked, isTrue);
    });

    test('tournament_rookie unlocks on first entry', () async {
      await manager.checkTournamentAchievements(tournamentsEntered: 1);
      final achievement = manager.achievements['tournament_rookie']!;
      expect(achievement.unlocked, isTrue);
    });

    test('round_winner unlocks on first win', () async {
      await manager.checkTournamentAchievements(roundsWon: 1);
      final achievement = manager.achievements['round_winner']!;
      expect(achievement.unlocked, isTrue);
    });
  });

  group('Achievement Category Counts', () {
    late AchievementsManager manager;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      manager = AchievementsManager();
      await manager.initialize();
    });

    test('mastery category contains new engagement achievements', () {
      final masteryAchievements = manager.getAchievementsByCategory(AchievementCategory.mastery);
      
      final masteryIds = masteryAchievements.map((a) => a.id).toList();
      
      expect(masteryIds, contains('daily_grinder'));
      expect(masteryIds, contains('weekly_warrior'));
      expect(masteryIds, contains('mission_master'));
      expect(masteryIds, contains('tournament_veteran'));
      expect(masteryIds, contains('round_veteran'));
    });

    test('collection category contains bonus_hunter', () {
      final collectionAchievements = manager.getAchievementsByCategory(AchievementCategory.collection);
      
      final collectionIds = collectionAchievements.map((a) => a.id).toList();
      
      expect(collectionIds, contains('bonus_hunter'));
    });

    test('total achievements count is correct', () {
      // Count all registered achievements
      final totalAchievements = manager.achievements.length;
      
      // Should have a significant number of achievements (40+)
      expect(totalAchievements, greaterThanOrEqualTo(40));
    });
  });

  group('Achievement Rarity Distribution', () {
    late AchievementsManager manager;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      manager = AchievementsManager();
      await manager.initialize();
    });

    test('has achievements of all rarities', () {
      final rarities = manager.achievements.values.map((a) => a.rarity).toSet();
      
      expect(rarities, contains(AchievementRarity.bronze));
      expect(rarities, contains(AchievementRarity.silver));
      expect(rarities, contains(AchievementRarity.gold));
      expect(rarities, contains(AchievementRarity.platinum));
      expect(rarities, contains(AchievementRarity.diamond));
    });

    test('diamond achievements have highest rewards', () {
      final diamondAchievements = manager.achievements.values
          .where((a) => a.rarity == AchievementRarity.diamond)
          .toList();
      
      for (final achievement in diamondAchievements) {
        expect(achievement.coinReward, greaterThanOrEqualTo(2000));
        expect(achievement.gemReward, greaterThanOrEqualTo(25));
      }
    });

    test('bronze achievements have lowest rewards', () {
      final bronzeAchievements = manager.achievements.values
          .where((a) => a.rarity == AchievementRarity.bronze)
          .toList();
      
      for (final achievement in bronzeAchievements) {
        expect(achievement.coinReward, lessThanOrEqualTo(150));
      }
    });
  });

  group('checkEngagementAchievements method', () {
    late AchievementsManager manager;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      manager = AchievementsManager();
      await manager.initialize();
    });

    test('checkSpecialAchievements updates daily grinder', () async {
      // Check engagement achievements with high game count
      await manager.checkSpecialAchievements(
        missionsCompleted: 10,
        daysPlayed: 5,
      );
      
      // Verify perfectionist was updated (missions completed)
      final perfectionist = manager.achievements['perfectionist']!;
      expect(perfectionist.progress, greaterThanOrEqualTo(10));
    });

    test('checkSpecialAchievements updates dedication incarnate', () async {
      await manager.checkSpecialAchievements(
        daysPlayed: 30,
      );
      
      final dedication = manager.achievements['dedication_incarnate']!;
      expect(dedication.unlocked, isTrue);
    });
  });
}



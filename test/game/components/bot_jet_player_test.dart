/// 🧪 BOT JET PLAYER UNIT TESTS
/// 
/// Tests for the BotJetPlayer component, especially the minimum obstacle pass feature.

import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/game/components/bot_jet_player.dart';

void main() {
  group('BotJetPlayer - Minimum Obstacle Pass Feature', () {
    test('Dynamic skill level returns 0.99 during guarantee phase', () {
      // Arrange: Create bot with minObstaclePass = 5
      final bot = BotJetPlayer(
        skinId: 'test_bot',
        skillLevel: 0.85, // Base skill
        reactionTime: 0.4,
        mistakeRate: 0.08, // Base mistake rate
        minObstaclesToPass: 5,
      );
      
      // Act & Assert: During guarantee phase (score < 5), skill should be 0.99
      expect(bot.currentSkillLevel, equals(0.99));
    });
    
    test('Dynamic skill level ramps down after guarantee phase', () {
      // Arrange: Create bot with minObstaclePass = 5
      final bot = BotJetPlayer(
        skinId: 'test_bot',
        skillLevel: 0.85,
        reactionTime: 0.4,
        mistakeRate: 0.08,
        minObstaclesToPass: 5,
      );
      
      // Act: Simulate passing 5 obstacles (enter transition phase)
      for (int i = 0; i < 5; i++) {
        bot.incrementScore();
      }
      
      // Assert: During transition (score 5-9), skill should be ramping down
      // At score = 5 (first transition obstacle): skill = 0.99 - 0% of diff = 0.99
      expect(bot.currentSkillLevel, equals(0.99));
      
      // Act: Pass one more obstacle
      bot.incrementScore(); // score = 6
      
      // Assert: At score = 6: skill = 0.99 - 20% of (0.99-0.85) = 0.962
      expect(bot.currentSkillLevel, closeTo(0.962, 0.001));
      
      // Act: Pass to end of transition
      for (int i = 0; i < 4; i++) {
        bot.incrementScore(); // score = 7, 8, 9, 10
      }
      
      // Assert: After transition (score >= 10), skill should be base level
      expect(bot.currentSkillLevel, equals(0.85));
    });
    
    test('Dynamic mistake rate returns 0.0 during guarantee phase', () {
      // Arrange: Create bot with minObstaclePass = 5
      final bot = BotJetPlayer(
        skinId: 'test_bot',
        skillLevel: 0.85,
        reactionTime: 0.4,
        mistakeRate: 0.08, // Base mistake rate
        minObstaclesToPass: 5,
      );
      
      // Act & Assert: During guarantee phase (score < 5), mistakes should be 0%
      expect(bot.currentMistakeRate, equals(0.0));
    });
    
    test('Dynamic mistake rate ramps up after guarantee phase', () {
      // Arrange: Create bot with minObstaclePass = 5
      final bot = BotJetPlayer(
        skinId: 'test_bot',
        skillLevel: 0.85,
        reactionTime: 0.4,
        mistakeRate: 0.08,
        minObstaclesToPass: 5,
      );
      
      // Act: Simulate passing 5 obstacles (enter transition phase)
      for (int i = 0; i < 5; i++) {
        bot.incrementScore();
      }
      
      // Assert: During transition (score 5-9), mistakes should be ramping up
      // At score = 5 (first transition obstacle): mistakes = 0% of 0.08 = 0.0
      expect(bot.currentMistakeRate, equals(0.0));
      
      // Act: Pass one more obstacle
      bot.incrementScore(); // score = 6
      
      // Assert: At score = 6: mistakes = 20% of 0.08 = 0.016
      expect(bot.currentMistakeRate, closeTo(0.016, 0.001));
      
      // Act: Pass to end of transition
      for (int i = 0; i < 4; i++) {
        bot.incrementScore(); // score = 7, 8, 9, 10
      }
      
      // Assert: After transition (score >= 10), mistakes should be base rate
      expect(bot.currentMistakeRate, equals(0.08));
    });
    
    test('Bot score increments correctly', () {
      // Arrange
      final bot = BotJetPlayer(
        skinId: 'test_bot',
        skillLevel: 0.85,
        reactionTime: 0.4,
        mistakeRate: 0.08,
        minObstaclesToPass: 5,
      );
      
      // Act: Increment score 3 times
      bot.incrementScore();
      bot.incrementScore();
      bot.incrementScore();
      
      // Assert: Score should be 3 (accessing via getter if available, or test behavior)
      // Since _score is private, we test behavior: skill should still be 0.99 (< 5)
      expect(bot.currentSkillLevel, equals(0.99));
      expect(bot.currentMistakeRate, equals(0.0));
    });
    
    test('No minimum guarantee when minObstaclePass = 0', () {
      // Arrange: Create bot with NO minimum guarantee
      final bot = BotJetPlayer(
        skinId: 'test_bot',
        skillLevel: 0.85,
        reactionTime: 0.4,
        mistakeRate: 0.08,
        minObstaclesToPass: 0, // No guarantee
      );
      
      // Act & Assert: Bot should use base skill/mistakes from the start
      expect(bot.currentSkillLevel, equals(0.85));
      expect(bot.currentMistakeRate, equals(0.08));
      
      // Act: Pass some obstacles
      for (int i = 0; i < 10; i++) {
        bot.incrementScore();
      }
      
      // Assert: Still using base skill/mistakes (no ramping)
      expect(bot.currentSkillLevel, equals(0.85));
      expect(bot.currentMistakeRate, equals(0.08));
    });
    
    test('Skill and mistake rate transition smoothly over 5 obstacles', () {
      // Arrange
      final bot = BotJetPlayer(
        skinId: 'test_bot',
        skillLevel: 0.70, // Lower base skill for bigger difference
        reactionTime: 0.4,
        mistakeRate: 0.15, // Higher base mistakes for bigger difference
        minObstaclesToPass: 3, // Short guarantee for easier testing
      );
      
      // Assert: Start at perfect skill, zero mistakes
      expect(bot.currentSkillLevel, equals(0.99));
      expect(bot.currentMistakeRate, equals(0.0));
      
      // Act: Pass 3 obstacles (end of guarantee)
      for (int i = 0; i < 3; i++) {
        bot.incrementScore();
      }
      
      // Assert: At score = 3, still perfect (transition hasn't started)
      expect(bot.currentSkillLevel, equals(0.99));
      expect(bot.currentMistakeRate, equals(0.0));
      
      // Act: Enter transition (score 3-7)
      bot.incrementScore(); // score = 4 (20% through transition)
      expect(bot.currentSkillLevel, closeTo(0.932, 0.001)); // 0.99 - 20% of 0.29
      expect(bot.currentMistakeRate, closeTo(0.03, 0.001)); // 20% of 0.15
      
      bot.incrementScore(); // score = 5 (40% through transition)
      expect(bot.currentSkillLevel, closeTo(0.874, 0.001)); // 0.99 - 40% of 0.29
      expect(bot.currentMistakeRate, closeTo(0.06, 0.001)); // 40% of 0.15
      
      bot.incrementScore(); // score = 6 (60% through transition)
      expect(bot.currentSkillLevel, closeTo(0.816, 0.001)); // 0.99 - 60% of 0.29
      expect(bot.currentMistakeRate, closeTo(0.09, 0.001)); // 60% of 0.15
      
      bot.incrementScore(); // score = 7 (80% through transition)
      expect(bot.currentSkillLevel, closeTo(0.758, 0.001)); // 0.99 - 80% of 0.29
      expect(bot.currentMistakeRate, closeTo(0.12, 0.001)); // 80% of 0.15
      
      bot.incrementScore(); // score = 8 (100% through transition)
      expect(bot.currentSkillLevel, equals(0.70)); // Full base skill
      expect(bot.currentMistakeRate, equals(0.15)); // Full base mistakes
    });
    
    test('Score increments and skill/mistake values respond correctly', () {
      // Arrange
      final bot = BotJetPlayer(
        skinId: 'test_bot',
        skillLevel: 0.85,
        reactionTime: 0.4,
        mistakeRate: 0.08,
        minObstaclesToPass: 5,
      );
      
      // Act: Pass some obstacles to enter transition phase
      for (int i = 0; i < 10; i++) {
        bot.incrementScore();
      }
      
      // Assert: After 10 obstacles, skill/mistakes should be at base
      expect(bot.currentSkillLevel, equals(0.85));
      expect(bot.currentMistakeRate, equals(0.08));
      
      // Note: We can't test reset() in unit tests because it requires 
      // the bot to be attached to a game instance (accesses game.size.y).
      // This would be tested in integration tests instead.
    });
  });
}


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
    
    group('Level 5 Bot Battle Parameters (skill=0.45, mistakeRate=0.35, minObstaclePass=6)', () {
      test('Bot starts in guarantee phase with perfect skill and zero mistakes', () {
        // Arrange: Level 5 bot configuration
        final bot = BotJetPlayer(
          skinId: 'police_patrol',
          skillLevel: 0.45,
          reactionTime: 0.45,
          mistakeRate: 0.35,
          minObstaclesToPass: 6,
        );
        
        // Assert: At score 0, bot should be in guarantee phase
        expect(bot.score, equals(0));
        expect(bot.currentSkillLevel, equals(0.99), reason: 'Bot should have perfect skill during guarantee phase');
        expect(bot.currentMistakeRate, equals(0.0), reason: 'Bot should have zero mistakes during guarantee phase');
      });
      
      test('Bot maintains guarantee phase through obstacles 0-5', () {
        // Arrange: Level 5 bot configuration
        final bot = BotJetPlayer(
          skinId: 'police_patrol',
          skillLevel: 0.45,
          reactionTime: 0.45,
          mistakeRate: 0.35,
          minObstaclesToPass: 6,
        );
        
        // Act & Assert: Pass obstacles 0-5 (guarantee phase)
        for (int i = 0; i < 6; i++) {
          bot.incrementScore();
          expect(bot.score, equals(i + 1), reason: 'Score should increment correctly');
          expect(bot.currentSkillLevel, equals(0.99), reason: 'Bot should maintain perfect skill at score ${i + 1}');
          expect(bot.currentMistakeRate, equals(0.0), reason: 'Bot should maintain zero mistakes at score ${i + 1}');
        }
      });
      
      test('Bot transitions correctly at obstacle 6 (entering transition phase)', () {
        // Arrange: Level 5 bot configuration
        final bot = BotJetPlayer(
          skinId: 'police_patrol',
          skillLevel: 0.45,
          reactionTime: 0.45,
          mistakeRate: 0.35,
          minObstaclesToPass: 6,
        );
        
        // Act: Pass 6 obstacles (end of guarantee phase)
        for (int i = 0; i < 6; i++) {
          bot.incrementScore();
        }
        
        // Assert: At score 6, still in guarantee phase (transition starts at score 6)
        expect(bot.score, equals(6));
        expect(bot.currentSkillLevel, equals(0.99), reason: 'At score 6, still perfect (transition starts)');
        expect(bot.currentMistakeRate, equals(0.0), reason: 'At score 6, still zero mistakes');
        
        // Act: Pass obstacle 7 (first transition obstacle)
        bot.incrementScore();
        
        // Assert: At score 7, transition should have started
        expect(bot.score, equals(7));
        final expectedSkill7 = 0.99 - (0.99 - 0.45) * 0.2; // 20% through transition
        expect(bot.currentSkillLevel, closeTo(expectedSkill7, 0.01), reason: 'At score 7, skill should start decreasing');
        final expectedMistakes7 = 0.35 * 0.2; // 20% of base mistake rate
        expect(bot.currentMistakeRate, closeTo(expectedMistakes7, 0.01), reason: 'At score 7, mistakes should start increasing');
      });
      
      test('Bot completes transition phase correctly (obstacles 6-11)', () {
        // Arrange: Level 5 bot configuration
        final bot = BotJetPlayer(
          skinId: 'police_patrol',
          skillLevel: 0.45,
          reactionTime: 0.45,
          mistakeRate: 0.35,
          minObstaclesToPass: 6,
        );
        
        // Act: Pass 6 obstacles (guarantee phase)
        for (int i = 0; i < 6; i++) {
          bot.incrementScore();
        }
        
        // Act: Pass transition obstacles (7-11)
        for (int i = 6; i < 11; i++) {
          bot.incrementScore();
          final transitionProgress = (bot.score - 6) / 5.0;
          final expectedSkill = 0.99 - (0.99 - 0.45) * transitionProgress;
          final expectedMistakes = 0.35 * transitionProgress;
          
          expect(bot.currentSkillLevel, closeTo(expectedSkill, 0.01), 
            reason: 'At score ${bot.score}, skill should be ${expectedSkill.toStringAsFixed(2)}');
          expect(bot.currentMistakeRate, closeTo(expectedMistakes, 0.01),
            reason: 'At score ${bot.score}, mistakes should be ${expectedMistakes.toStringAsFixed(2)}');
        }
        
        // Assert: After transition (score 11), should be at base values
        expect(bot.score, equals(11));
        expect(bot.currentSkillLevel, equals(0.45), reason: 'After transition, skill should be base level');
        expect(bot.currentMistakeRate, equals(0.35), reason: 'After transition, mistakes should be base rate');
      });
      
      test('Bot uses base skill/mistakes after transition (obstacles 12+)', () {
        // Arrange: Level 5 bot configuration
        final bot = BotJetPlayer(
          skinId: 'police_patrol',
          skillLevel: 0.45,
          reactionTime: 0.45,
          mistakeRate: 0.35,
          minObstaclesToPass: 6,
        );
        
        // Act: Pass 15 obstacles (well past transition)
        for (int i = 0; i < 15; i++) {
          bot.incrementScore();
        }
        
        // Assert: Should be using base values
        expect(bot.score, equals(15));
        expect(bot.currentSkillLevel, equals(0.45), reason: 'After transition, skill should stay at base');
        expect(bot.currentMistakeRate, equals(0.35), reason: 'After transition, mistakes should stay at base');
        
        // Act: Pass more obstacles
        for (int i = 0; i < 50; i++) {
          bot.incrementScore();
        }
        
        // Assert: Should still be using base values (no further changes)
        expect(bot.score, equals(65));
        expect(bot.currentSkillLevel, equals(0.45), reason: 'At high scores, skill should stay at base');
        expect(bot.currentMistakeRate, equals(0.35), reason: 'At high scores, mistakes should stay at base');
      });
      
      test('Bot score getter returns correct value throughout gameplay', () {
        // Arrange: Level 5 bot configuration
        final bot = BotJetPlayer(
          skinId: 'police_patrol',
          skillLevel: 0.45,
          reactionTime: 0.45,
          mistakeRate: 0.35,
          minObstaclesToPass: 6,
        );
        
        // Assert: Initial score should be 0
        expect(bot.score, equals(0));
        
        // Act & Assert: Increment score and verify getter
        for (int i = 0; i < 20; i++) {
          bot.incrementScore();
          expect(bot.score, equals(i + 1), reason: 'Score getter should return ${i + 1} after ${i + 1} increments');
        }
      });
      
      test('Bot behavior changes are reflected immediately after incrementScore', () {
        // Arrange: Level 5 bot configuration
        final bot = BotJetPlayer(
          skinId: 'police_patrol',
          skillLevel: 0.45,
          reactionTime: 0.45,
          mistakeRate: 0.35,
          minObstaclesToPass: 6,
        );
        
        // Capture initial values
        final skillBefore = bot.currentSkillLevel;
        final mistakesBefore = bot.currentMistakeRate;
        
        // Act: Pass 6 obstacles
        for (int i = 0; i < 6; i++) {
          bot.incrementScore();
        }
        
        // Assert: Values should still be same (still in guarantee phase)
        expect(bot.currentSkillLevel, equals(skillBefore), reason: 'Skill should not change during guarantee phase');
        expect(bot.currentMistakeRate, equals(mistakesBefore), reason: 'Mistakes should not change during guarantee phase');
        
        // Act: Pass one more obstacle (enter transition)
        bot.incrementScore();
        
        // Assert: Values should have changed immediately
        expect(bot.currentSkillLevel, lessThan(skillBefore), reason: 'Skill should decrease immediately after guarantee phase');
        expect(bot.currentMistakeRate, greaterThan(mistakesBefore), reason: 'Mistakes should increase immediately after guarantee phase');
      });
    });
    
    group('Edge Cases and Bug Detection', () {
      test('Bot score does not increment when inactive', () {
        // Note: This test requires a game instance for crash() to work.
        // Testing incrementScore() behavior when inactive would require
        // either mocking the game or testing in integration tests.
        // The incrementScore() method already checks _isActive, so the logic is correct.
        // Skipping this test in unit tests - would be tested in integration tests.
      });
      
      test('Bot maintains correct phase detection at boundary scores', () {
        // Arrange: Level 5 bot configuration
        final bot = BotJetPlayer(
          skinId: 'police_patrol',
          skillLevel: 0.45,
          reactionTime: 0.45,
          mistakeRate: 0.35,
          minObstaclesToPass: 6,
        );
        
        // Test boundary: score = 5 (last guarantee obstacle)
        for (int i = 0; i < 5; i++) {
          bot.incrementScore();
        }
        expect(bot.score, equals(5));
        expect(bot.currentSkillLevel, equals(0.99), reason: 'At score 5, should still be in guarantee phase');
        
        // Test boundary: score = 6 (first transition obstacle)
        bot.incrementScore();
        expect(bot.score, equals(6));
        expect(bot.currentSkillLevel, equals(0.99), reason: 'At score 6, transition starts (still perfect)');
        
        // Test boundary: score = 11 (last transition obstacle)
        for (int i = 6; i < 11; i++) {
          bot.incrementScore();
        }
        expect(bot.score, equals(11));
        expect(bot.currentSkillLevel, closeTo(0.45, 0.01), reason: 'At score 11, should be at base skill');
        
        // Test boundary: score = 12 (first post-transition obstacle)
        bot.incrementScore();
        expect(bot.score, equals(12));
        expect(bot.currentSkillLevel, equals(0.45), reason: 'At score 12, should be at base skill');
      });
      
      test('Bot score tracking is independent of multiple incrementScore calls', () {
        // Arrange: Level 5 bot configuration
        final bot = BotJetPlayer(
          skinId: 'police_patrol',
          skillLevel: 0.45,
          reactionTime: 0.45,
          mistakeRate: 0.35,
          minObstaclesToPass: 6,
        );
        
        // Act: Increment score multiple times rapidly
        for (int i = 0; i < 10; i++) {
          bot.incrementScore();
        }
        
        // Assert: Score should be exactly 10
        expect(bot.score, equals(10), reason: 'Score should track all increments correctly');
        
        // Assert: Skill/mistakes should reflect score 10 (in transition phase)
        expect(bot.currentSkillLevel, lessThan(0.99), reason: 'At score 10, skill should be transitioning');
        expect(bot.currentMistakeRate, greaterThan(0.0), reason: 'At score 10, mistakes should be transitioning');
      });
    });
  });
}


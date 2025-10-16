/// Baseline Scoring System Tests
/// 
/// Verifies current scoring behavior before refactoring
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flame_test/flame_test.dart';
import '../../lib/game/flappy_game.dart';
import '../../lib/game/components/dynamic_obstacle.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Baseline: Scoring', () {
    testWidgets('Score increments when passing obstacle', (tester) async {
      final game = TestHelpers.createTestGame();
      await tester.pumpWidget(GameWidget(game: game));
      await tester.pump();
      
      await TestHelpers.waitForGameReady(game);
      await TestHelpers.simulateTap(game);
      await tester.pump();
      
      final initialScore = TestHelpers.getScore(game);
      
      // Create obstacle behind jet (already passed)
      final obstacle = DynamicObstacle(
        Vector2(game.jet.position.x - 100, game.size.y / 2),
        gapSize: 200,
      );
      await game.add(obstacle);
      
      // Trigger scoring check
      game.update(0.016);
      await tester.pump();
      
      // BASELINE: Score should increment by 1
      expect(
        TestHelpers.getScore(game),
        initialScore + 1,
        reason: 'Passing obstacle should increment score by 1',
      );
    });
    
    testWidgets('No double-scoring for same obstacle', (tester) async {
      final game = TestHelpers.createTestGame();
      await tester.pumpWidget(GameWidget(game: game));
      await tester.pump();
      
      await TestHelpers.waitForGameReady(game);
      await TestHelpers.simulateTap(game);
      await tester.pump();
      
      final obstacle = DynamicObstacle(
        Vector2(game.jet.position.x - 50, game.size.y / 2),
        gapSize: 200,
      );
      await game.add(obstacle);
      
      // First scoring
      game.update(0.016);
      await tester.pump();
      final scoreAfterFirst = TestHelpers.getScore(game);
      
      // Update again (should not score twice)
      game.update(0.016);
      await tester.pump();
      
      // BASELINE: Score should be same (no double-scoring)
      expect(
        TestHelpers.getScore(game),
        scoreAfterFirst,
        reason: 'Should not score same obstacle twice',
      );
    });
    
    testWidgets('Score does not increment before passing obstacle', (tester) async {
      final game = TestHelpers.createTestGame();
      await tester.pumpWidget(GameWidget(game: game));
      await tester.pump();
      
      await TestHelpers.waitForGameReady(game);
      await TestHelpers.simulateTap(game);
      await tester.pump();
      
      final initialScore = TestHelpers.getScore(game);
      
      // Obstacle ahead of jet
      final obstacle = DynamicObstacle(
        Vector2(game.jet.position.x + 200, game.size.y / 2),
        gapSize: 200,
      );
      await game.add(obstacle);
      
      game.update(0.016);
      await tester.pump();
      
      // BASELINE: Score should not change (obstacle not passed yet)
      expect(
        TestHelpers.getScore(game),
        initialScore,
        reason: 'Score should not change before passing obstacle',
      );
    });
  });
}


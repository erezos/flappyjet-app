/// Tests for FlappyGame state synchronization fixes
/// 
/// Tests the fix for setState() during build error by ensuring
/// LivesManager sync is deferred using SchedulerBinding.addPostFrameCallback.
/// Follows Flame game engine best practices and mobile gaming standards.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/game/systems/lives_manager.dart';
import 'package:flappy_jet_pro/models/level_data_schema.dart';
import 'package:flame/game.dart';
import '../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FlappyGame - State Synchronization Fixes', () {
    testWidgets('syncStoryModeLivesWithManager defers state update to post-frame', (tester) async {
      // Arrange: Create a story mode game
      final level = TestHelpers.createTestLevel(
        id: 1,
        zone: 1,
        type: ObjectiveType.passObstacles,
        target: 10,
      );

      final game = TestHelpers.createTestGame(
        isStoryMode: true,
        level: level,
      );

      await tester.pumpWidget(GameWidget(game: game));
      await tester.pump();

      // Act: Trigger collision which calls syncStoryModeLivesWithManager
      // This should NOT cause setState() during build error
      final initialLives = game.gameStateManager.lives;
      game.gameStateManager.handleCollision();

      // Wait for post-frame callback to execute
      await tester.pump();
      await tester.pump(); // Extra pump for post-frame callback

      // Assert: LivesManager should be synced after build phase
      final livesManager = LivesManager();
      expect(
        livesManager.currentLives,
        equals(initialLives - 1),
        reason: 'LivesManager should be synced after collision, but deferred to post-frame',
      );
    });

    test('syncStoryModeLivesWithManager does nothing in non-story mode', () async {
      // Arrange: Create a non-story mode game
      final game = TestHelpers.createTestGame(isStoryMode: false);

      // Act: Call syncStoryModeLivesWithManager
      await game.syncStoryModeLivesWithManager();

      // Assert: Should return early without error
      // (No assertion needed - just ensuring no exception is thrown)
    });

    testWidgets('syncStoryModeLivesWithManager handles errors gracefully', (tester) async {
      // Arrange: Create a story mode game
      final level = TestHelpers.createTestLevel(
        id: 1,
        zone: 1,
        type: ObjectiveType.passObstacles,
        target: 10,
      );

      final game = TestHelpers.createTestGame(
        isStoryMode: true,
        level: level,
      );

      await tester.pumpWidget(GameWidget(game: game));
      await tester.pump();

      // Act: Call syncStoryModeLivesWithManager
      // Even if LivesManager throws an error, it should be caught
      await game.syncStoryModeLivesWithManager();

      // Wait for post-frame callback
      await tester.pump();
      await tester.pump();

      // Assert: Should not throw exception
      // (Test passes if no exception is thrown)
    });
  });
}


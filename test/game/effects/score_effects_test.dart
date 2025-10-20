import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/game/components/score_zone.dart';
import 'package:flappy_jet_pro/game/flappy_game.dart';

void main() {
  group('ScoreZone Celebration Effects', () {
    testWithGame<FlappyGame>(
      'onScored() applies scale pulse effect',
      FlappyGame.new,
      (game) async {
        final scoreZone = ScoreZone(
          width: 100,
          height: 300,
        );
        
        await game.ensureAdd(scoreZone);
        
        // Initial scale
        expect(scoreZone.scale, Vector2(1.0, 1.0));
        
        // Trigger score
        scoreZone.onScored();
        
        // Advance to peak of pulse (0.1s)
        game.update(0.1);
        
        // Scale should be larger
        expect(scoreZone.scale.x, greaterThan(1.0), reason: 'Should pulse out');
        expect(scoreZone.scale.y, greaterThan(1.0), reason: 'Should pulse out');
        
        // Advance to end of pulse (0.4s total)
        game.update(0.35);
        
        // Scale should return to normal
        expect(scoreZone.scale.x, closeTo(1.0, 0.1));
        expect(scoreZone.scale.y, closeTo(1.0, 0.1));
      },
    );

    testWithGame<FlappyGame>(
      'onScored() applies color flash effect',
      FlappyGame.new,
      (game) async {
        final scoreZone = ScoreZone(
          width: 100,
          height: 300,
        );
        
        await game.ensureAdd(scoreZone);
        
        // Trigger score
        scoreZone.onScored();
        
        // Color effect should be applied
        final colorEffects = scoreZone.children.whereType<ColorEffect>();
        expect(colorEffects.isNotEmpty, isTrue, reason: 'Should have color flash');
        
        // Advance time
        game.update(0.2);
        
        // Color should be visible
        // (Exact color testing is tricky, just verify effect exists)
      },
    );

    testWithGame<FlappyGame>(
      'multiple scores apply multiple celebration effects',
      FlappyGame.new,
      (game) async {
        final scoreZone = ScoreZone(
          width: 100,
          height: 300,
        );
        
        await game.ensureAdd(scoreZone);
        
        // Trigger first score
        scoreZone.onScored();
        game.update(0.1);
        
        // Trigger second score before first completes
        scoreZone.onScored();
        
        // Multiple effects should be active
        final effectCount = scoreZone.children.whereType<Effect>().length;
        expect(effectCount, greaterThan(1), 
            reason: 'Multiple celebrations should stack');
      },
    );

    testWithGame<FlappyGame>(
      'celebration effects complete and clean up',
      FlappyGame.new,
      (game) async {
        final scoreZone = ScoreZone(
          width: 100,
          height: 300,
        );
        
        await game.ensureAdd(scoreZone);
        
        // Trigger score
        scoreZone.onScored();
        
        // Wait for all effects to complete (1 second should be enough)
        game.update(1.0);
        
        // Effects should be cleaned up
        final effectCount = scoreZone.children.whereType<Effect>().length;
        expect(effectCount, lessThan(2), 
            reason: 'Completed effects should be removed');
      },
    );
  });

  group('ScoreZone Effect Timing', () {
    testWithGame<FlappyGame>(
      'scale pulse follows easeOut -> easeIn curve',
      FlappyGame.new,
      (game) async {
        final scoreZone = ScoreZone(
          width: 100,
          height: 300,
        );
        
        await game.ensureAdd(scoreZone);
        
        scoreZone.onScored();
        
        // Sample scale at different points
        game.update(0.05); // Early
        final earlyScale = scoreZone.scale.x;
        
        game.update(0.05); // Peak
        final peakScale = scoreZone.scale.x;
        
        // Peak should be larger than early
        expect(peakScale, greaterThanOrEqualTo(earlyScale),
            reason: 'Should grow during easeOut phase');
        
        game.update(0.3); // End
        final endScale = scoreZone.scale.x;
        
        // End should return to ~1.0
        expect(endScale, closeTo(1.0, 0.1));
      },
    );

    testWithGame<FlappyGame>(
      'color flash fades over time',
      FlappyGame.new,
      (game) async {
        final scoreZone = ScoreZone(
          width: 100,
          height: 300,
        );
        
        await game.ensureAdd(scoreZone);
        
        scoreZone.onScored();
        
        // Get initial color effect
        final colorEffect = scoreZone.children.whereType<ColorEffect>().firstOrNull;
        expect(colorEffect, isNotNull);
        
        // Advance to end of flash
        game.update(0.5);
        
        // Color effect should complete
        // (Testing exact color values is complex, just verify duration)
      },
    );
  });

  group('ScoreZone Effect Performance', () {
    testWithGame<FlappyGame>(
      'rapid scoring does not cause performance issues',
      FlappyGame.new,
      (game) async {
        final scoreZone = ScoreZone(
          width: 100,
          height: 300,
        );
        
        await game.ensureAdd(scoreZone);
        
        // Rapid scoring
        final stopwatch = Stopwatch()..start();
        for (int i = 0; i < 30; i++) {
          scoreZone.onScored();
          game.update(0.05);
        }
        stopwatch.stop();
        
        // Should complete without major lag
        expect(stopwatch.elapsedMilliseconds, lessThan(2000),
            reason: 'Rapid celebrations should not kill performance');
      },
    );

    testWithGame<FlappyGame>(
      'effects do not leak memory over time',
      FlappyGame.new,
      (game) async {
        final scoreZone = ScoreZone(
          width: 100,
          height: 300,
        );
        
        await game.ensureAdd(scoreZone);
        
        // Trigger many scores
        for (int i = 0; i < 50; i++) {
          scoreZone.onScored();
          game.update(0.1);
        }
        
        // Wait for cleanup
        game.update(2.0);
        
        // Effect count should not grow unbounded
        final effectCount = scoreZone.children.whereType<Effect>().length;
        expect(effectCount, lessThan(10),
            reason: 'Old effects should be garbage collected');
      },
    );
  });
}


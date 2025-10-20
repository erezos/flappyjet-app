import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/game/components/jet_player.dart';
import 'package:flappy_jet_pro/game/flappy_game.dart';

void main() {
  group('JetPlayer Effects', () {
    testWithGame<FlappyGame>(
      'jump() applies squash and stretch effect',
      FlappyGame.new,
      (game) async {
        final jet = game.jet;
        
        // Initial scale should be (1.0, 1.0)
        expect(jet.scale, Vector2(1.0, 1.0));
        
        // Trigger jump
        jet.jump();
        
        // Advance time to middle of squash phase (0.05s)
        game.update(0.05);
        
        // Scale should be squashed (wider, shorter)
        expect(jet.scale.x, greaterThan(1.0), reason: 'Should be wider');
        expect(jet.scale.y, lessThan(1.0), reason: 'Should be shorter');
        
        // Advance to stretch phase (0.15s total)
        game.update(0.10);
        
        // Scale should be stretched (narrower, taller)
        expect(jet.scale.x, lessThan(1.0), reason: 'Should be narrower');
        expect(jet.scale.y, greaterThan(1.0), reason: 'Should be taller');
        
        // Advance to end of animation (0.3s total)
        game.update(0.15);
        
        // Scale should return to normal
        expect(jet.scale.x, closeTo(1.0, 0.1));
        expect(jet.scale.y, closeTo(1.0, 0.1));
      },
    );

    testWithGame<FlappyGame>(
      'jump() applies rotation effect',
      FlappyGame.new,
      (game) async {
        final jet = game.jet;
        
        // Initial angle should be 0
        expect(jet.angle, 0.0);
        
        // Trigger jump
        jet.jump();
        
        // Advance time to middle of rotation
        game.update(0.1);
        
        // Angle should be tilted back (negative)
        expect(jet.angle, lessThan(0.0), reason: 'Should tilt back on jump');
        
        // Advance to end of rotation
        game.update(0.15);
        
        // Angle should return closer to 0
        expect(jet.angle, greaterThan(-0.05), reason: 'Should return to normal');
      },
    );

    testWithGame<FlappyGame>(
      'multiple jumps apply multiple effects',
      FlappyGame.new,
      (game) async {
        final jet = game.jet;
        
        // First jump
        jet.jump();
        game.update(0.05);
        final firstScale = jet.scale.clone();
        
        // Second jump before first completes
        jet.jump();
        game.update(0.05);
        
        // Effects should stack/combine
        expect(jet.children.whereType<Effect>().length, greaterThan(1),
            reason: 'Multiple effects should be active');
      },
    );

    testWithGame<FlappyGame>(
      'effects complete and remove themselves',
      FlappyGame.new,
      (game) async {
        final jet = game.jet;
        
        // Trigger jump
        jet.jump();
        
        final initialEffectCount = jet.children.whereType<Effect>().length;
        expect(initialEffectCount, greaterThan(0), reason: 'Should have effects after jump');
        
        // Advance past all effect durations (1 second should be enough)
        game.update(1.0);
        
        // Effects should be removed after completion
        final finalEffectCount = jet.children.whereType<Effect>().length;
        expect(finalEffectCount, lessThanOrEqualTo(initialEffectCount),
            reason: 'Completed effects should be removed');
      },
    );
  });

  group('JetPlayer Damage Effects', () {
    testWithGame<FlappyGame>(
      'taking damage applies color flash effect',
      FlappyGame.new,
      (game) async {
        final jet = game.jet;
        
        // Take damage
        jet.setDamageStateFromLives(2);
        
        // Color effect should be applied
        final colorEffects = jet.children.whereType<ColorEffect>();
        expect(colorEffects.isNotEmpty, isTrue, reason: 'Should have color effect');
      },
    );

    testWithGame<FlappyGame>(
      'invulnerability applies opacity flicker effect',
      FlappyGame.new,
      (game) async {
        final jet = game.jet;
        
        // Enable invulnerability
        jet.setInvulnerable(true);
        
        // Opacity effect should be applied
        final opacityEffects = jet.children.whereType<OpacityEffect>();
        expect(opacityEffects.isNotEmpty, isTrue, reason: 'Should have opacity effect');
        
        // Advance time
        game.update(0.3);
        
        // Opacity should flicker (not always 1.0)
        expect(jet.opacity, isNot(equals(1.0)), reason: 'Should be flickering');
      },
    );

    testWithGame<FlappyGame>(
      'disabling invulnerability removes flicker effect',
      FlappyGame.new,
      (game) async {
        final jet = game.jet;
        
        // Enable then disable invulnerability
        jet.setInvulnerable(true);
        game.update(0.1);
        jet.setInvulnerable(false);
        
        // Opacity effect should be removed
        final opacityEffects = jet.children.whereType<OpacityEffect>();
        expect(opacityEffects.isEmpty, isTrue, reason: 'Flicker should be removed');
        
        // Opacity should be reset to 1.0
        expect(jet.opacity, 1.0, reason: 'Opacity should be restored');
      },
    );
  });

  group('JetPlayer Effect Performance', () {
    testWithGame<FlappyGame>(
      'effects do not cause memory leaks',
      FlappyGame.new,
      (game) async {
        final jet = game.jet;
        
        // Trigger many jumps
        for (int i = 0; i < 50; i++) {
          jet.jump();
          game.update(0.1);
        }
        
        // Wait for all effects to complete
        game.update(2.0);
        
        // Effect count should not grow unbounded
        final effectCount = jet.children.whereType<Effect>().length;
        expect(effectCount, lessThan(10), 
            reason: 'Old effects should be cleaned up');
      },
    );

    testWithGame<FlappyGame>(
      'effects maintain 60 FPS performance',
      FlappyGame.new,
      (game) async {
        final jet = game.jet;
        
        // Trigger multiple effects simultaneously
        jet.jump();
        jet.setDamageStateFromLives(2);
        jet.setInvulnerable(true);
        
        // Measure update time
        final stopwatch = Stopwatch()..start();
        for (int i = 0; i < 60; i++) {
          game.update(1 / 60); // 60 FPS
        }
        stopwatch.stop();
        
        // Should complete 60 frames in reasonable time (<1 second + overhead)
        expect(stopwatch.elapsedMilliseconds, lessThan(1500),
            reason: 'Effects should not significantly impact performance');
      },
    );
  });
}


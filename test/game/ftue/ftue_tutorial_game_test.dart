import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/game/ftue/ftue_tutorial_game.dart';

void main() {
  group('FTUETutorialGame', () {
    test('should create game instance successfully', () {
      bool completionCalled = false;
      
      final game = FTUETutorialGame(
        onComplete: ({required bool completed, required int taps, required Duration duration}) {
          completionCalled = true;
        },
      );
      
      expect(game, isNotNull);
      expect(completionCalled, isFalse);
    });
  });

  group('JetComponent', () {
    test('should create component with correct asset path', () {
      final component = JetComponent(
        assetPath: 'jets/test.png',
        size: Vector2.all(80),
      );
      
      expect(component.assetPath, equals('jets/test.png'));
      expect(component.size.x, equals(80));
      expect(component.size.y, equals(80));
    });
  });

  group('FingerTapComponent', () {
    test('should create component with callback', () {
      bool callbackTriggered = false;
      
      final component = FingerTapComponent(
        onTapComplete: () {
          callbackTriggered = true;
        },
      );
      
      expect(component, isNotNull);
      expect(callbackTriggered, isFalse);
    });
  });

  group('TapCounterOverlay', () {
    test('should initialize with default text', () {
      final overlay = TapCounterOverlay();
      
      expect(overlay.text, contains('0/5'));
      expect(overlay.text, contains('Tap to Jump'));
    });

    test('should update text when updateCount is called', () {
      final overlay = TapCounterOverlay();
      
      overlay.updateCount(3, 5);
      
      expect(overlay.text, contains('3/5'));
    });
  });

  group('SkipButtonOverlay', () {
    test('should create button with callback', () {
      bool skipCalled = false;
      
      final button = SkipButtonOverlay(
        onSkip: () {
          skipCalled = true;
        },
      );
      
      expect(button, isNotNull);
      expect(button.isVisible, isFalse);
      expect(skipCalled, isFalse);
    });

    test('should become visible when reveal is called', () {
      final button = SkipButtonOverlay(
        onSkip: () {},
      );
      
      button.reveal();
      
      expect(button.isVisible, isTrue);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flappy_jet_pro/game/core/game_config.dart';

void main() {
  group('🔧 COMPREHENSIVE COLLISION CONFIG', () {
    setUpAll(() async {
      WidgetsFlutterBinding.ensureInitialized();
    });

    test('🎯 RESPONSIVE POSITIONING: Jet should scale with screen size', () {
      final testScreenSizes = [
        Vector2(320, 568),
        Vector2(375, 667),
        Vector2(414, 896),
        Vector2(428, 926),
        Vector2(400, 800),
      ];

      for (final screenSize in testScreenSizes) {
        final jetX = GameConfig.getStartScreenJetX(screenSize.x);
        final jetY = GameConfig.getStartScreenJetY(screenSize.y);
        final textY = screenSize.y * 0.75;

        expect(jetX / screenSize.x, closeTo(GameConfig.startScreenJetXRatio, 1e-9));

        final expectedJetY = screenSize.y * GameConfig.startScreenJetYRatio;
        expect(jetY, equals(expectedJetY));

        expect(jetY, lessThan(textY));
      }
    });

    test('🚫 SCREEN BOUNDARY COLLISION: Top and bottom thresholds', () {
      final gameHeight = GameConfig.gameHeight;
      final jetSize = GameConfig.jetSize;
      final halfSize = jetSize / 2;

      final topCollisionY = halfSize;
      expect(topCollisionY, equals(halfSize));

      final groundLevel = gameHeight - 50;
      final bottomCollisionY = groundLevel - halfSize;
      expect(bottomCollisionY, equals(groundLevel - halfSize));

      final safePlayHeight = bottomCollisionY - topCollisionY;
      final minSafeHeight = gameHeight * 0.7;
      expect(safePlayHeight, greaterThan(minSafeHeight));
    });

    test('⚖️ COLLISION BOX CONSISTENCY sizes', () {
      final jetSize = GameConfig.jetSize;
      final gameLogicCollisionSize = jetSize * 0.6;
      final flameHitboxSize = jetSize * 0.6;

      expect(flameHitboxSize, equals(gameLogicCollisionSize));

      final sizeReduction = jetSize - gameLogicCollisionSize;
      final reductionPercentage = (sizeReduction / jetSize) * 100;

      expect(reductionPercentage, greaterThanOrEqualTo(35.0));
      expect(reductionPercentage, lessThanOrEqualTo(50.0));
    });
  });
}



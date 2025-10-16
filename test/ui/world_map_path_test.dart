/// 🧪 UNIT TESTS - WORLD MAP PATH CALCULATOR
/// 
/// Tests for path calculation and position generation for the world map.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flappy_jet_pro/ui/widgets/world_map_path_painter.dart';

void main() {
  group('WorldMapPathCalculator', () {
    test('calculates correct number of positions for zone', () {
      final screenSize = const Size(400, 800);
      final path = WorldMapPathCalculator.calculateZonePath(
        zoneId: 1,
        levelCount: 10,
        screenSize: screenSize,
      );
      
      expect(path.length, equals(10));
    });

    test('positions are within screen bounds', () {
      final screenSize = const Size(400, 800);
      final path = WorldMapPathCalculator.calculateZonePath(
        zoneId: 1,
        levelCount: 10,
        screenSize: screenSize,
      );
      
      for (final position in path) {
        expect(position.dx, greaterThanOrEqualTo(0));
        expect(position.dx, lessThanOrEqualTo(screenSize.width));
        expect(position.dy, greaterThanOrEqualTo(0));
        expect(position.dy, lessThanOrEqualTo(screenSize.height));
      }
    });

    test('path progresses from bottom to top', () {
      final screenSize = const Size(400, 800);
      final path = WorldMapPathCalculator.calculateZonePath(
        zoneId: 1,
        levelCount: 10,
        screenSize: screenSize,
      );
      
      // First position should be lower (higher Y value) than last position
      expect(path.first.dy, greaterThan(path.last.dy));
    });

    test('different zones produce different paths', () {
      final screenSize = const Size(400, 800);
      final path1 = WorldMapPathCalculator.calculateZonePath(
        zoneId: 1,
        levelCount: 10,
        screenSize: screenSize,
      );
      final path2 = WorldMapPathCalculator.calculateZonePath(
        zoneId: 2,
        levelCount: 10,
        screenSize: screenSize,
      );
      
      // Paths should be different due to randomization seeded by zone ID
      expect(path1, isNot(equals(path2)));
    });

    test('getLevelPosition returns correct position', () {
      final path = [
        const Offset(100, 100),
        const Offset(200, 200),
        const Offset(300, 300),
      ];
      
      expect(
        WorldMapPathCalculator.getLevelPosition(path, 0),
        equals(const Offset(100, 100)),
      );
      expect(
        WorldMapPathCalculator.getLevelPosition(path, 1),
        equals(const Offset(200, 200)),
      );
      expect(
        WorldMapPathCalculator.getLevelPosition(path, 2),
        equals(const Offset(300, 300)),
      );
    });

    test('getLevelPosition handles out of bounds gracefully', () {
      final path = [
        const Offset(100, 100),
        const Offset(200, 200),
      ];
      
      // Negative index should return first position
      expect(
        WorldMapPathCalculator.getLevelPosition(path, -1),
        equals(const Offset(100, 100)),
      );
      
      // Out of bounds index should return first position
      expect(
        WorldMapPathCalculator.getLevelPosition(path, 10),
        equals(const Offset(100, 100)),
      );
    });

    test('handles empty path gracefully', () {
      final path = <Offset>[];
      
      expect(
        WorldMapPathCalculator.getLevelPosition(path, 0),
        equals(Offset.zero),
      );
    });

    test('respects padding parameters', () {
      final screenSize = const Size(400, 800);
      final topPadding = 100.0;
      final bottomPadding = 150.0;
      
      final path = WorldMapPathCalculator.calculateZonePath(
        zoneId: 1,
        levelCount: 10,
        screenSize: screenSize,
        topPadding: topPadding,
        bottomPadding: bottomPadding,
      );
      
      // First node should be near bottom (accounting for bottom padding)
      expect(path.first.dy, greaterThan(screenSize.height - bottomPadding - 100));
      
      // Last node should be near top (accounting for top padding)
      expect(path.last.dy, lessThan(topPadding + 100));
    });

    test('creates zigzag pattern', () {
      final screenSize = const Size(400, 800);
      final path = WorldMapPathCalculator.calculateZonePath(
        zoneId: 1,
        levelCount: 10,
        screenSize: screenSize,
      );
      
      // Check that X coordinates vary (not all in a straight line)
      final xValues = path.map((p) => p.dx).toSet();
      expect(xValues.length, greaterThan(1)); // Should have multiple X positions
    });
  });

  group('WorldMapPathPainter', () {
    testWidgets('shouldRepaint returns true when properties change', (tester) async {
      final nodePositions1 = [const Offset(100, 100), const Offset(200, 200)];
      final nodePositions2 = [const Offset(150, 150), const Offset(250, 250)];
      
      final painter1 = WorldMapPathPainter(
        nodePositions: nodePositions1,
        completedUpTo: 0,
      );
      
      // Different positions
      final painter2 = WorldMapPathPainter(
        nodePositions: nodePositions2,
        completedUpTo: 0,
      );
      expect(painter1.shouldRepaint(painter2), isTrue);
      
      // Different completion
      final painter3 = WorldMapPathPainter(
        nodePositions: nodePositions1,
        completedUpTo: 1,
      );
      expect(painter1.shouldRepaint(painter3), isTrue);
      
      // Same properties
      final painter4 = WorldMapPathPainter(
        nodePositions: nodePositions1,
        completedUpTo: 0,
      );
      expect(painter1.shouldRepaint(painter4), isFalse);
    });
  });
}


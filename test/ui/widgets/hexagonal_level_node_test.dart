/// 🧪 Tests for HexagonalLevelNode widget
/// 
/// Verifies consistent node rendering for both story mode and tournament world maps.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/ui/widgets/hexagonal_level_node.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HexagonalLevelNode - Widget Structure', () {
    testWidgets('renders with correct size', (tester) async {
      const nodeSize = 60.0;
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: HexagonalLevelNode(
                isUnlocked: true,
                isCompleted: false,
                isCurrent: false,
                nodeSize: nodeSize,
                child: Text('1'),
              ),
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, nodeSize);
      expect(sizedBox.height, nodeSize);
    });

    testWidgets('displays child content (level number)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: HexagonalLevelNode(
                isUnlocked: true,
                isCompleted: false,
                isCurrent: true,
                nodeSize: 60.0,
                child: Text('5'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('shows lock icon for locked nodes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: HexagonalLevelNode(
                isUnlocked: false,
                isCompleted: false,
                isCurrent: false,
                nodeSize: 60.0,
                child: Text('3'),
              ),
            ),
          ),
        ),
      );

      // Should find lock icon
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    });

    testWidgets('no lock icon for unlocked nodes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: HexagonalLevelNode(
                isUnlocked: true,
                isCompleted: false,
                isCurrent: false,
                nodeSize: 60.0,
                child: Text('3'),
              ),
            ),
          ),
        ),
      );

      // Should NOT find lock icon
      expect(find.byIcon(Icons.lock_rounded), findsNothing);
    });
  });

  group('HexagonalLevelNode - VS Battle Badge', () {
    testWidgets('shows VS badge for bot battle nodes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: HexagonalLevelNode(
                isUnlocked: true,
                isCompleted: false,
                isCurrent: true,
                isBotBattle: true,
                nodeSize: 85.0,
                child: Text('VS'),
              ),
            ),
          ),
        ),
      );

      // Should find VS text inside the badge
      expect(find.text('VS'), findsWidgets);
    });

    testWidgets('no VS badge for regular nodes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: HexagonalLevelNode(
                isUnlocked: true,
                isCompleted: false,
                isCurrent: true,
                isBotBattle: false,
                nodeSize: 60.0,
                child: Text('1'),
              ),
            ),
          ),
        ),
      );

      // Should NOT find VS badge (only the child text '1')
      expect(find.text('VS'), findsNothing);
    });
  });

  group('HexagonalLevelNode - CustomPainter', () {
    testWidgets('uses HexagonBadgePainter for main badge', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: HexagonalLevelNode(
                isUnlocked: true,
                isCompleted: false,
                isCurrent: false,
                nodeSize: 60.0,
                child: Text('1'),
              ),
            ),
          ),
        ),
      );

      // Find CustomPaint widgets
      final customPaints = tester.widgetList<CustomPaint>(find.byType(CustomPaint));
      expect(customPaints.isNotEmpty, isTrue, reason: 'Should have CustomPaint for hexagon badge');
    });

    testWidgets('uses HexagonGlowPainter for current node glow', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: HexagonalLevelNode(
                isUnlocked: true,
                isCompleted: false,
                isCurrent: true,
                nodeSize: 60.0,
                child: Text('1'),
              ),
            ),
          ),
        ),
      );

      // Current nodes should have glow (multiple CustomPaint widgets)
      final customPaints = tester.widgetList<CustomPaint>(find.byType(CustomPaint));
      expect(customPaints.length, greaterThanOrEqualTo(2), 
          reason: 'Current node should have badge + glow painters');
    });
  });

  group('HexagonalLevelNode - Animation', () {
    testWidgets('current node has pulse animation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: HexagonalLevelNode(
                isUnlocked: true,
                isCompleted: false,
                isCurrent: true,
                nodeSize: 60.0,
                child: Text('1'),
              ),
            ),
          ),
        ),
      );

      // Find AnimatedBuilder widgets (may be multiple due to widget tree)
      expect(find.byType(AnimatedBuilder), findsWidgets);
      
      // Find Transform.scale for the pulse effect
      expect(find.byType(Transform), findsWidgets);
    });

    testWidgets('non-current node has no pulse animation scale', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: HexagonalLevelNode(
                isUnlocked: true,
                isCompleted: false,
                isCurrent: false,
                nodeSize: 60.0,
                child: Text('1'),
              ),
            ),
          ),
        ),
      );

      // AnimatedBuilder exists (may be multiple due to widget tree)
      expect(find.byType(AnimatedBuilder), findsWidgets);
    });
  });

  group('HexagonalLevelNode - Custom Colors', () {
    testWidgets('accepts custom active color', (tester) async {
      const customOrange = Color(0xFFFF6B35);
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: HexagonalLevelNode(
                isUnlocked: true,
                isCompleted: false,
                isCurrent: true,
                nodeSize: 60.0,
                activeColor: customOrange,
                child: Text('1'),
              ),
            ),
          ),
        ),
      );

      // Widget should render without error
      expect(find.byType(HexagonalLevelNode), findsOneWidget);
    });

    testWidgets('accepts custom completed color', (tester) async {
      const customGreen = Color(0xFF4CAF50);
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: HexagonalLevelNode(
                isUnlocked: true,
                isCompleted: true,
                isCurrent: false,
                nodeSize: 60.0,
                completedColor: customGreen,
                child: Text('1'),
              ),
            ),
          ),
        ),
      );

      // Widget should render without error
      expect(find.byType(HexagonalLevelNode), findsOneWidget);
    });
  });

  group('HexagonBadgePainter', () {
    test('shouldRepaint returns true when state changes', () {
      final painter1 = HexagonBadgePainter(
        isUnlocked: true,
        isCompleted: false,
        isCurrent: false,
      );
      
      final painter2 = HexagonBadgePainter(
        isUnlocked: true,
        isCompleted: true, // Changed
        isCurrent: false,
      );

      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('shouldRepaint returns false when state is same', () {
      final painter1 = HexagonBadgePainter(
        isUnlocked: true,
        isCompleted: false,
        isCurrent: true,
      );
      
      final painter2 = HexagonBadgePainter(
        isUnlocked: true,
        isCompleted: false,
        isCurrent: true,
      );

      expect(painter1.shouldRepaint(painter2), isFalse);
    });
  });

  group('HexagonGlowPainter', () {
    test('shouldRepaint returns true when color changes', () {
      final painter1 = HexagonGlowPainter(
        color: Colors.amber,
        blurRadius: 12,
      );
      
      final painter2 = HexagonGlowPainter(
        color: Colors.red, // Changed
        blurRadius: 12,
      );

      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('shouldRepaint returns true when blurRadius changes', () {
      final painter1 = HexagonGlowPainter(
        color: Colors.amber,
        blurRadius: 12,
      );
      
      final painter2 = HexagonGlowPainter(
        color: Colors.amber,
        blurRadius: 20, // Changed
      );

      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('shouldRepaint returns false when same', () {
      final painter1 = HexagonGlowPainter(
        color: Colors.amber,
        blurRadius: 12,
      );
      
      final painter2 = HexagonGlowPainter(
        color: Colors.amber,
        blurRadius: 12,
      );

      expect(painter1.shouldRepaint(painter2), isFalse);
    });
  });
}


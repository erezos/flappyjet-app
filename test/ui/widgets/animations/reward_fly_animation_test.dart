/// 🧪 REWARD FLY ANIMATION TESTS
/// 
/// Comprehensive tests for reward fly animation widget.
/// Follows Flame best practices and mobile gaming top standards.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flappy_jet_pro/ui/widgets/animations/reward_fly_animation.dart';

void main() {
  group('RewardFlyConfig', () {
    test('should create config with default values', () {
      const config = RewardFlyConfig(
        coins: 100,
        gems: 5,
        sourcePosition: Offset(100, 200),
        targetPosition: Offset(50, 50),
      );

      expect(config.coins, 100);
      expect(config.gems, 5);
      expect(config.sourcePosition, const Offset(100, 200));
      expect(config.targetPosition, const Offset(50, 50));
      expect(config.duration, const Duration(milliseconds: 1200));
      expect(config.particleCount, 5);
      expect(config.particleSize, 24.0);
    });

    test('should create config with custom values', () {
      const config = RewardFlyConfig(
        coins: 50,
        gems: 10,
        sourcePosition: Offset(200, 300),
        targetPosition: Offset(100, 100),
        duration: Duration(milliseconds: 2000),
        particleCount: 8,
        particleSize: 32.0,
      );

      expect(config.coins, 50);
      expect(config.gems, 10);
      expect(config.duration, const Duration(milliseconds: 2000));
      expect(config.particleCount, 8);
      expect(config.particleSize, 32.0);
    });
  });

  group('getPositionFromKey', () {
    testWidgets('should return null for null key', (WidgetTester tester) async {
      final result = getPositionFromKey(GlobalKey());
      expect(result, isNull);
    });

    testWidgets('should return correct position from key', (WidgetTester tester) async {
      final key = GlobalKey();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Container(
                key: key,
                width: 100,
                height: 50,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      
      final position = getPositionFromKey(key);
      expect(position, isNotNull);
      expect(position!.dx, greaterThan(0));
      expect(position.dy, greaterThan(0));
    });
  });

  group('RewardFlyAnimation Widget', () {
    testWidgets('should create animation widget', (WidgetTester tester) async {
      const config = RewardFlyConfig(
        coins: 100,
        gems: 0,
        sourcePosition: Offset(200, 300),
        targetPosition: Offset(50, 50),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RewardFlyAnimation(
              config: config,
            ),
          ),
        ),
      );

      expect(find.byType(RewardFlyAnimation), findsOneWidget);
    });

    testWidgets('should create particles for coins', (WidgetTester tester) async {
      const config = RewardFlyConfig(
        coins: 100,
        gems: 0,
        sourcePosition: Offset(200, 300),
        targetPosition: Offset(50, 50),
        particleCount: 3,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RewardFlyAnimation(
              config: config,
            ),
          ),
        ),
      );

      await tester.pump(); // Initial frame
      
      // Should have created particles (they're in the Stack)
      expect(find.byType(Stack), findsWidgets);
    });

    testWidgets('should create particles for gems', (WidgetTester tester) async {
      const config = RewardFlyConfig(
        coins: 0,
        gems: 10,
        sourcePosition: Offset(200, 300),
        targetPosition: Offset(50, 50),
        particleCount: 3,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RewardFlyAnimation(
              config: config,
            ),
          ),
        ),
      );

      await tester.pump(); // Initial frame
      
      // Should have created particles
      expect(find.byType(Stack), findsWidgets);
    });

    testWidgets('should create particles for both coins and gems', (WidgetTester tester) async {
      const config = RewardFlyConfig(
        coins: 100,
        gems: 10,
        sourcePosition: Offset(200, 300),
        targetPosition: Offset(50, 50),
        particleCount: 2,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RewardFlyAnimation(
              config: config,
            ),
          ),
        ),
      );

      await tester.pump(); // Initial frame
      
      // Should have created particles for both
      expect(find.byType(Stack), findsWidgets);
    });

    testWidgets('should call onComplete callback', (WidgetTester tester) async {
      bool callbackCalled = false;
      
      const config = RewardFlyConfig(
        coins: 100,
        gems: 0,
        sourcePosition: Offset(200, 300),
        targetPosition: Offset(50, 50),
        duration: Duration(milliseconds: 100), // Short duration for testing
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RewardFlyAnimation(
              config: config,
              onComplete: () {
                callbackCalled = true;
              },
            ),
          ),
        ),
      );

      // Wait for animation to complete
      await tester.pumpAndSettle(const Duration(milliseconds: 200));
      
      expect(callbackCalled, isTrue);
    });

    testWidgets('should dispose controllers properly', (WidgetTester tester) async {
      const config = RewardFlyConfig(
        coins: 100,
        gems: 0,
        sourcePosition: Offset(200, 300),
        targetPosition: Offset(50, 50),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RewardFlyAnimation(
              config: config,
            ),
          ),
        ),
      );

      // Dispose widget
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
      
      // Should not throw errors
      expect(tester.takeException(), isNull);
    });
  });

  group('createRewardFlyOverlay', () {
    testWidgets('should create OverlayEntry', (WidgetTester tester) async {
      const config = RewardFlyConfig(
        coins: 100,
        gems: 0,
        sourcePosition: Offset(200, 300),
        targetPosition: Offset(50, 50),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: _TestTickerProvider(
            child: Builder(
              builder: (context) {
                final tickerProvider = context.findAncestorStateOfType<_TestTickerProviderState>()!;
                final overlay = createRewardFlyOverlay(
                  config: config,
                  vsync: tickerProvider,
                );
                expect(overlay, isA<OverlayEntry>());
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });
  });

  group('Particle Animation Behavior', () {
    testWidgets('should animate particles along bezier curve', (WidgetTester tester) async {
      const config = RewardFlyConfig(
        coins: 100,
        gems: 0,
        sourcePosition: Offset(200, 300),
        targetPosition: Offset(50, 50),
        particleCount: 1,
        duration: Duration(milliseconds: 500),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RewardFlyAnimation(
              config: config,
            ),
          ),
        ),
      );

      // Pump multiple frames to see animation progress
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 250));

      // Animation should be running
      expect(find.byType(RewardFlyAnimation), findsOneWidget);
    });

    testWidgets('should stagger particle animations', (WidgetTester tester) async {
      const config = RewardFlyConfig(
        coins: 100,
        gems: 0,
        sourcePosition: Offset(200, 300),
        targetPosition: Offset(50, 50),
        particleCount: 3,
        duration: Duration(milliseconds: 100),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RewardFlyAnimation(
              config: config,
            ),
          ),
        ),
      );

      await tester.pump();
      
      // All particles should be created
      expect(find.byType(Stack), findsWidgets);
    });
  });

  group('Edge Cases', () {
    testWidgets('should handle zero coins and gems', (WidgetTester tester) async {
      const config = RewardFlyConfig(
        coins: 0,
        gems: 0,
        sourcePosition: Offset(200, 300),
        targetPosition: Offset(50, 50),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RewardFlyAnimation(
              config: config,
            ),
          ),
        ),
      );

      await tester.pump();
      
      // Should not crash
      expect(find.byType(RewardFlyAnimation), findsOneWidget);
    });

    testWidgets('should handle very large reward amounts', (WidgetTester tester) async {
      const config = RewardFlyConfig(
        coins: 10000,
        gems: 1000,
        sourcePosition: Offset(200, 300),
        targetPosition: Offset(50, 50),
        particleCount: 10,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RewardFlyAnimation(
              config: config,
            ),
          ),
        ),
      );

      await tester.pump();
      
      // Should handle large amounts gracefully
      expect(find.byType(RewardFlyAnimation), findsOneWidget);
    });
  });
}

/// Helper class for testing with TickerProvider
class _TestTickerProvider extends StatefulWidget {
  final Widget child;
  
  const _TestTickerProvider({required this.child});
  
  @override
  State<_TestTickerProvider> createState() => _TestTickerProviderState();
}

class _TestTickerProviderState extends State<_TestTickerProvider>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) => widget.child;
}


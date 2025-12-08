/// 🪙 Coin3DIcon Widget Tests
/// Tests for the consistent coin icon widget used throughout the app
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/ui/widgets/coin_3d_icon.dart';

void main() {
  group('Coin3DIcon', () {
    testWidgets('renders with given size', (tester) async {
      const testSize = 32.0;
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Coin3DIcon(size: testSize),
            ),
          ),
        ),
      );
      
      // Find the SizedBox that wraps the icon
      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
      expect(sizedBox.width, testSize);
      expect(sizedBox.height, testSize);
    });

    testWidgets('renders Image.asset widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Coin3DIcon(size: 24),
            ),
          ),
        ),
      );
      
      // Should contain an Image widget
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('renders with small size', (tester) async {
      const testSize = 12.0;
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Coin3DIcon(size: testSize),
            ),
          ),
        ),
      );
      
      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
      expect(sizedBox.width, testSize);
      expect(sizedBox.height, testSize);
    });

    testWidgets('renders with large size', (tester) async {
      const testSize = 64.0;
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Coin3DIcon(size: testSize),
            ),
          ),
        ),
      );
      
      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
      expect(sizedBox.width, testSize);
      expect(sizedBox.height, testSize);
    });

    testWidgets('can be used in Row with other widgets', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Coin3DIcon(size: 24),
                SizedBox(width: 8),
                Text('100'),
              ],
            ),
          ),
        ),
      );
      
      expect(find.byType(Coin3DIcon), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('renders correctly with primaryColor parameter', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Coin3DIcon(
                size: 24,
                primaryColor: Colors.orange,
              ),
            ),
          ),
        ),
      );
      
      // Should still render with the size
      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
      expect(sizedBox.width, 24.0);
      expect(sizedBox.height, 24.0);
    });

    testWidgets('can be used with const constructor', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Coin3DIcon(size: 24),
            ),
          ),
        ),
      );
      
      expect(find.byType(Coin3DIcon), findsOneWidget);
    });

    testWidgets('renders in different orientations', (tester) async {
      // Portrait
      await tester.binding.setSurfaceSize(const Size(400, 800));
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Coin3DIcon(size: 32),
            ),
          ),
        ),
      );
      
      expect(find.byType(Coin3DIcon), findsOneWidget);
      
      // Landscape
      await tester.binding.setSurfaceSize(const Size(800, 400));
      await tester.pump();
      
      expect(find.byType(Coin3DIcon), findsOneWidget);
      
      // Reset
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('works in Column layout', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Coin3DIcon(size: 48),
                Text('Coins'),
              ],
            ),
          ),
        ),
      );
      
      expect(find.byType(Coin3DIcon), findsOneWidget);
      expect(find.text('Coins'), findsOneWidget);
    });

    testWidgets('multiple instances render correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Coin3DIcon(size: 16),
                Coin3DIcon(size: 24),
                Coin3DIcon(size: 32),
              ],
            ),
          ),
        ),
      );
      
      expect(find.byType(Coin3DIcon), findsNWidgets(3));
    });
  });
}


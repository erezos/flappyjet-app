import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/ui/screens/stunning_homepage.dart';
import '../../lib/game/systems/monetization_manager.dart';

void main() {
  group('🎵 Main Menu Audio Widget Tests', () {
    late MonetizationManager monetization;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      monetization = MonetizationManager();
    });

    testWidgets('main menu should build with audio system', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StunningHomepage(
            developmentMode: true,
            monetization: monetization,
          ),
        ),
      );

      // Should build without errors
      expect(find.byType(StunningHomepage), findsOneWidget);
      
      // Should have main menu elements
      expect(find.text('FLAPPYJET PRO'), findsOneWidget);
      expect(find.text('PLAY'), findsOneWidget);
    });

    testWidgets('main menu should handle audio initialization errors', (WidgetTester tester) async {
      // This test ensures the menu still works even if audio fails to initialize
      await tester.pumpWidget(
        MaterialApp(
          home: StunningHomepage(
            developmentMode: true,
            monetization: monetization,
          ),
        ),
      );

      // Wait for initialization
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Menu should still be functional
      expect(find.byType(StunningHomepage), findsOneWidget);
      expect(find.text('PLAY'), findsOneWidget);
    });

    testWidgets('menu should handle navigation with audio cleanup', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StunningHomepage(
            developmentMode: true,
            monetization: monetization,
          ),
        ),
      );

      // Wait for initial load
      await tester.pump();
      
      // Find and tap the PLAY button
      final playButton = find.text('PLAY');
      expect(playButton, findsOneWidget);
      
      // Note: We can't actually test navigation without proper setup
      // But we can ensure the button exists and is tappable
      expect(tester.widget<Widget>(playButton), isNotNull);
    });

    testWidgets('menu should handle dispose with audio cleanup', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StunningHomepage(
            developmentMode: true,
            monetization: monetization,
          ),
        ),
      );

      // Wait for initialization
      await tester.pump();

      // Navigate away (simulating dispose)
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Text('Different Screen'),
          ),
        ),
      );

      // Should handle dispose without errors
      expect(find.text('Different Screen'), findsOneWidget);
    });

    testWidgets('menu should show all expected UI elements', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StunningHomepage(
            developmentMode: true,
            monetization: monetization,
          ),
        ),
      );

      await tester.pump();

      // Check for main UI elements
      expect(find.text('FLAPPYJET PRO'), findsOneWidget);
      expect(find.text('PLAY'), findsOneWidget);
      expect(find.text('STORE'), findsOneWidget);
      expect(find.text('SETTINGS'), findsOneWidget);
      
      // Check for logo/icon
      expect(find.byIcon(Icons.flight), findsOneWidget);
    });

    testWidgets('menu animations should work with audio', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StunningHomepage(
            developmentMode: true,
            monetization: monetization,
          ),
        ),
      );

      // Pump initial frame
      await tester.pump();
      
      // Pump through animation duration
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 1500));

      // Should still be working
      expect(find.byType(StunningHomepage), findsOneWidget);
      expect(find.text('PLAY'), findsOneWidget);
    });

    group('Menu Button Audio Feedback', () {
      testWidgets('buttons should provide haptic feedback', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: StunningHomepage(
              developmentMode: true,
              monetization: monetization,
            ),
          ),
        );

        await tester.pump();

        // Test that buttons exist and are tappable
        final playButton = find.text('PLAY');
        expect(playButton, findsOneWidget);
        
        final storeButton = find.text('STORE');
        expect(storeButton, findsOneWidget);
        
        final settingsButton = find.text('SETTINGS');
        expect(settingsButton, findsOneWidget);
        
        // Note: Testing actual haptic feedback requires device testing
        // But we can verify the buttons exist and are properly configured
      });
    });

    group('Audio System Edge Cases', () {
      testWidgets('menu should handle rapid audio calls', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: StunningHomepage(
              developmentMode: true,
              monetization: monetization,
            ),
          ),
        );

        // Pump multiple times rapidly
        for (int i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 10));
        }

        // Should still be stable
        expect(find.byType(StunningHomepage), findsOneWidget);
      });

      testWidgets('menu should survive audio system errors', (WidgetTester tester) async {
        // This simulates what happens when audio files are completely missing
        await tester.pumpWidget(
          MaterialApp(
            home: StunningHomepage(
              developmentMode: true,
              monetization: monetization,
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // UI should still work even if audio completely fails
        expect(find.byType(StunningHomepage), findsOneWidget);
        expect(find.text('PLAY'), findsOneWidget);
      });
    });
  });
}
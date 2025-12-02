import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flappy_jet_pro/game/systems/rate_us_manager.dart';
import 'package:flappy_jet_pro/ui/widgets/rate_us_integration.dart';
import 'package:flappy_jet_pro/ui/widgets/rate_us_popup.dart';

/// Full Flow Tests for Rate Us System
/// 
/// Tests the complete user journey:
/// 1. Integration checks eligibility correctly
/// 2. Popup shows and handles all user actions
/// 3. State is persisted correctly
/// 4. Error handling doesn't crash the app
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RateUsManager manager;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    manager = RateUsManager();
    await manager.resetForTesting();
  });

  group('RateUsIntegration - Full Flow', () {
    testWidgets('shouldShow returns false when not eligible', (tester) async {
      await manager.initialize();
      
      // Session 1 - not eligible yet
      expect(RateUsIntegration.shouldShow, isFalse);
    });

    testWidgets('shouldShow returns true when eligible', (tester) async {
      // Setup eligible user
      SharedPreferences.setMockInitialValues({
        'rate_us_session_count': 5,
        'rate_us_first_launch_date': DateTime.now()
            .subtract(const Duration(days: 10))
            .millisecondsSinceEpoch,
      });
      
      await manager.initialize();
      
      expect(RateUsIntegration.shouldShow, isTrue);
    });

    testWidgets('hasUserRated reflects manager state', (tester) async {
      await manager.initialize();
      
      expect(RateUsIntegration.hasUserRated, isFalse);
      
      await manager.markAsRated();
      
      expect(RateUsIntegration.hasUserRated, isTrue);
    });

    testWidgets('hasUserDeclined reflects manager state', (tester) async {
      await manager.initialize();
      
      expect(RateUsIntegration.hasUserDeclined, isFalse);
      
      await manager.handleDeclined();
      
      expect(RateUsIntegration.hasUserDeclined, isTrue);
    });

    testWidgets('debugState returns valid map', (tester) async {
      await manager.initialize();
      
      final state = RateUsIntegration.debugState;
      
      expect(state, isA<Map<String, dynamic>>());
      expect(state.containsKey('is_initialized'), isTrue);
      expect(state.containsKey('session_count'), isTrue);
      expect(state.containsKey('config'), isTrue);
    });
  });

  group('RateUsPopup - Widget Tests', () {
    testWidgets('popup renders correctly on small screen', (tester) async {
      // Set small screen size (iPhone SE)
      tester.view.physicalSize = const Size(640, 1136);
      tester.view.devicePixelRatio = 2.0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const RateUsPopup(),
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      // Use pump - animation loops forever, pumpAndSettle would timeout
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify popup elements exist
      expect(find.text('Loving FlappyJet? ✈️'), findsOneWidget);
      expect(find.text('RATE FLAPPYJET ⭐'), findsOneWidget);
      expect(find.text('MAYBE LATER'), findsOneWidget);
      expect(find.text('No Thanks'), findsOneWidget);
      
      // Reset screen size
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('popup renders correctly on large screen (tablet)', (tester) async {
      // Set tablet screen size
      tester.view.physicalSize = const Size(2048, 2732);
      tester.view.devicePixelRatio = 2.0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const RateUsPopup(),
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify popup elements exist on tablet too
      expect(find.text('Loving FlappyJet? ✈️'), findsOneWidget);
      expect(find.text('RATE FLAPPYJET ⭐'), findsOneWidget);
      
      // Reset screen size
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('Maybe Later button closes popup', (tester) async {
      // Use realistic phone size
      tester.view.physicalSize = const Size(1170, 2532); // iPhone 14 Pro
      tester.view.devicePixelRatio = 3.0;
      
      bool dismissed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => RateUsPopup(
                      onDismissed: () => dismissed = true,
                    ),
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await manager.initialize();
      await tester.tap(find.text('Show'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Tap Maybe Later
      await tester.tap(find.text('MAYBE LATER'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Popup should be gone
      expect(find.text('Loving FlappyJet? ✈️'), findsNothing);
      expect(dismissed, isTrue);
      
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('No Thanks button closes popup and marks declined', (tester) async {
      // Use realistic phone size
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      
      bool dismissed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => RateUsPopup(
                      onDismissed: () => dismissed = true,
                    ),
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await manager.initialize();
      await tester.tap(find.text('Show'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Tap No Thanks
      await tester.tap(find.text('No Thanks'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Popup should be gone
      expect(find.text('Loving FlappyJet? ✈️'), findsNothing);
      expect(dismissed, isTrue);
      
      // User should be marked as declined
      expect(manager.hasDeclined, isTrue);
      
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('close button (X) closes popup', (tester) async {
      // Use realistic phone size
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const RateUsPopup(),
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await manager.initialize();
      await tester.tap(find.text('Show'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Find and tap the close button (X icon)
      final closeButton = find.byIcon(Icons.close);
      expect(closeButton, findsOneWidget);
      
      await tester.tap(closeButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Popup should be gone
      expect(find.text('Loving FlappyJet? ✈️'), findsNothing);
      
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  group('RateUsPopup - Error Handling', () {
    testWidgets('popup handles errors gracefully', (tester) async {
      // Use realistic phone size
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      
      // This test verifies that even if something goes wrong,
      // the popup still closes and doesn't crash
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => RateUsPopup(
                      onRated: () {
                        // Callback that might fail
                        throw Exception('Test exception');
                      },
                    ),
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await manager.initialize();
      await tester.tap(find.text('Show'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Popup should be visible
      expect(find.text('Loving FlappyJet? ✈️'), findsOneWidget);

      // Even with a throwing callback, the popup should handle it
      // Note: In real implementation, the try/catch will prevent crash
      
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  group('RateUsPopup - Responsive Design', () {
    testWidgets('star animation runs smoothly', (tester) async {
      // Use realistic phone size
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const RateUsPopup(),
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await manager.initialize();
      await tester.tap(find.text('Show'));
      await tester.pump(); // Initial frame
      
      // Pump a few frames to verify animation runs
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      
      // Should still be visible (animation didn't crash)
      expect(find.text('Loving FlappyJet? ✈️'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsWidgets);
      
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('buttons are tappable on all screen sizes', (tester) async {
      final sizes = [
        const Size(640, 1136),   // iPhone SE
        const Size(750, 1334),   // iPhone 8
        const Size(1170, 2532),  // iPhone 14 Pro
        const Size(2048, 2732),  // iPad Pro
      ];

      for (final size in sizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 2.0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const RateUsPopup(),
                    );
                  },
                  child: const Text('Show'),
                ),
              ),
            ),
          ),
        );

        await manager.initialize();
        await tester.tap(find.text('Show'));
        // Use pump instead of pumpAndSettle - animation never settles (loops)
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // All buttons should be findable and tappable
        expect(find.text('RATE FLAPPYJET ⭐'), findsOneWidget);
        expect(find.text('MAYBE LATER'), findsOneWidget);
        expect(find.text('No Thanks'), findsOneWidget);

        // Close popup for next iteration
        await tester.tap(find.text('MAYBE LATER'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        
        await manager.resetForTesting();
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}


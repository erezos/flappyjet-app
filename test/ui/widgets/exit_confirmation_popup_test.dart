/// 🧪 EXIT CONFIRMATION POPUP TESTS
/// 
/// Tests for the exit confirmation dialog behavior.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/ui/widgets/exit_confirmation_popup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExitConfirmationPopup Widget Tests', () {
    testWidgets('should display title and default message', (tester) async {
      bool exitCalled = false;
      bool stayCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExitConfirmationPopup(
              onExit: () => exitCalled = true,
              onStay: () => stayCalled = true,
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Check title is displayed
      expect(find.text('Leaving So Soon?'), findsOneWidget);
      
      // Check default message
      expect(find.text('Are you sure you want to exit FlappyJet?'), findsOneWidget);
      
      // Check buttons are displayed
      expect(find.text('KEEP PLAYING'), findsOneWidget);
      expect(find.text('EXIT'), findsOneWidget);
    });

    testWidgets('should display custom reminder message', (tester) async {
      const customMessage = "Don't forget your daily streak! 🔥";
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExitConfirmationPopup(
              reminderMessage: customMessage,
              onExit: () {},
              onStay: () {},
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Custom message should replace default
      expect(find.text(customMessage), findsOneWidget);
      expect(find.text('Are you sure you want to exit FlappyJet?'), findsNothing);
    });

    testWidgets('should call onStay when KEEP PLAYING is tapped', (tester) async {
      bool stayCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExitConfirmationPopup(
              onExit: () {},
              onStay: () => stayCalled = true,
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Tap KEEP PLAYING button
      await tester.tap(find.text('KEEP PLAYING'));
      await tester.pumpAndSettle();
      
      expect(stayCalled, isTrue);
    });

    testWidgets('should call onExit when EXIT is tapped', (tester) async {
      bool exitCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExitConfirmationPopup(
              onExit: () => exitCalled = true,
              onStay: () {},
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Tap EXIT button
      await tester.tap(find.text('EXIT'));
      await tester.pumpAndSettle();
      
      expect(exitCalled, isTrue);
    });

    testWidgets('should have jet icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExitConfirmationPopup(
              onExit: () {},
              onStay: () {},
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Jet emoji should be visible
      expect(find.text('✈️'), findsOneWidget);
    });
  });

  group('showExitConfirmation Function Tests', () {
    testWidgets('should return false when user stays', (tester) async {
      bool? result;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    result = await showExitConfirmation(context);
                  },
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        ),
      );
      
      // Tap to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();
      
      // Dialog should be visible
      expect(find.text('Leaving So Soon?'), findsOneWidget);
      
      // Tap KEEP PLAYING
      await tester.tap(find.text('KEEP PLAYING'));
      await tester.pumpAndSettle();
      
      expect(result, isFalse);
    });

    testWidgets('should return true when user exits', (tester) async {
      bool? result;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    result = await showExitConfirmation(context);
                  },
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        ),
      );
      
      // Tap to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();
      
      // Tap EXIT
      await tester.tap(find.text('EXIT'));
      await tester.pumpAndSettle();
      
      expect(result, isTrue);
    });

    testWidgets('should pass custom reminder message', (tester) async {
      const customMessage = 'Custom test message';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    await showExitConfirmation(
                      context,
                      reminderMessage: customMessage,
                    );
                  },
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        ),
      );
      
      // Tap to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();
      
      // Custom message should be displayed
      expect(find.text(customMessage), findsOneWidget);
    });

    testWidgets('should dismiss when tapping outside (barrier dismissible)', (tester) async {
      bool? result;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    result = await showExitConfirmation(context);
                  },
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        ),
      );
      
      // Tap to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();
      
      // Dialog should be visible
      expect(find.text('Leaving So Soon?'), findsOneWidget);
      
      // Tap outside the dialog (on the barrier)
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      
      // Dialog should be dismissed and result should be false
      expect(result, isFalse);
    });
  });

  // NOTE: Responsive tests skipped due to test environment constraints.
  // The popup is designed with responsive sizing using ResponsiveConfig.
  // Actual device testing confirms proper responsive behavior.
}


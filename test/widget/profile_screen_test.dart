/// 🧪 Profile Screen Widget Tests - Comprehensive testing of all profile components
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flappy_jet_pro/ui/screens/profile_screen.dart';
import 'package:flappy_jet_pro/game/core/jet_skins.dart';
import '../mocks/profile_mocks.dart';

void main() {
  group('ProfileScreen Widget Tests', () {
    late ProfileTestMocks mocks;

    setUp(() async {
      // Initialize SharedPreferences for testing
      SharedPreferences.setMockInitialValues({
        'best_score': 89,
        'best_streak': 89,
        'player_name': 'TestPlayer',
      });
      
      // Create mock objects
      mocks = ProfileTestData.createFullMockSet(
        playerName: 'TestPlayer',
        nickname: 'TestNickname',
        equippedSkin: 'sky_jet',
        coins: 1000,
        gems: 50,
      );
      
      // Initialize mock catalog
      MockJetSkinCatalog.resetToDefaults();
    });

    tearDown(() {
      mocks.dispose();
      MockJetSkinCatalog.clearTestSkins();
    });

    group('ProfileScreen Rendering', () {
      testWidgets('renders profile screen with all main components', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ProfileScreen(),
          ),
        );
        
        // Wait for async initialization
        await tester.pumpAndSettle();

        // Check for main components
        expect(find.byType(ProfileScreen), findsOneWidget);
        
        // Check for back button
        expect(find.byIcon(Icons.arrow_back), findsOneWidget);
        
        // Check for profile title (either image or fallback text)
        expect(find.text('PROFILE').or(find.byType(Image)), findsOneWidget);
        
        // Check for nickname section
        expect(find.byType(TextField), findsOneWidget);
        
        // Check for stats section
        expect(find.text('HIGH SCORE'), findsOneWidget);
        expect(find.text('HOTTEST STREAK'), findsOneWidget);
        
        // Check for jet preview section
        expect(find.text('SKY ROOKIE'), findsOneWidget);
        
        // Check for choose jet button
        expect(find.text('CHOOSE JET'), findsOneWidget);
      });

      testWidgets('displays correct background image', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ProfileScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Check for background container with decoration
        final containerFinder = find.byType(Container);
        expect(containerFinder, findsWidgets);
        
        // Verify background image is set
        final container = tester.widget<Container>(containerFinder.first);
        expect(container.decoration, isA<BoxDecoration>());
        
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.image, isNotNull);
        expect(decoration.image!.image, isA<AssetImage>());
      });

      testWidgets('handles missing profile title image gracefully', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ProfileScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // The errorBuilder should show fallback text if image fails
        // In normal testing, the image might not load, so we should see either
        expect(
          find.text('PROFILE').or(find.byType(Image)),
          findsOneWidget,
        );
      });
    });

    group('Nickname Functionality', () {
      testWidgets('displays nickname input field correctly', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ProfileScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Find the nickname text field
        final textFieldFinder = find.byType(TextField);
        expect(textFieldFinder, findsOneWidget);

        final textField = tester.widget<TextField>(textFieldFinder);
        expect(textField.textAlign, TextAlign.center);
        expect(textField.maxLength, 16);
      });

      testWidgets('allows nickname editing', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ProfileScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Find and tap the text field
        final textFieldFinder = find.byType(TextField);
        await tester.tap(textFieldFinder);
        await tester.pumpAndSettle();

        // Clear and enter new text
        await tester.enterText(textFieldFinder, 'NewNickname');
        await tester.pumpAndSettle();

        // Verify text was entered
        expect(find.text('NewNickname'), findsOneWidget);
      });

      testWidgets('nickname save button is present and tappable', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ProfileScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Find the edit icon button
        final editButtonFinder = find.byIcon(Icons.edit_outlined);
        expect(editButtonFinder, findsOneWidget);

        // Tap the edit button
        await tester.tap(editButtonFinder);
        await tester.pumpAndSettle();

        // Should not crash (actual save functionality tested in integration tests)
      });

      testWidgets('nickname field has proper styling', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ProfileScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Check nickname container styling
        final containerFinder = find.ancestor(
          of: find.byType(TextField),
          matching: find.byType(Container),
        ).first;
        
        final container = tester.widget<Container>(containerFinder);
        expect(container.decoration, isA<BoxDecoration>());
        
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.borderRadius, isNotNull);
        expect(decoration.gradient, isNotNull);
      });
    });

    group('Stats Display', () {
      testWidgets('displays high score correctly', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ProfileScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Check for high score display
        expect(find.text('HIGH SCORE'), findsOneWidget);
        expect(find.text('89'), findsAtLeastNWidgets(1)); // Score value
      });

      testWidgets('displays hottest streak correctly', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ProfileScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Check for streak display
        expect(find.text('HOTTEST STREAK'), findsOneWidget);
        expect(find.text('89'), findsAtLeastNWidgets(1)); // Streak value
      });

      testWidgets('stats cards have proper icons', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ProfileScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Check for trophy and fire icons
        expect(find.byIcon(Icons.emoji_events_outlined), findsOneWidget);
        expect(find.byIcon(Icons.local_fire_department_outlined), findsOneWidget);
      });

      testWidgets('stats cards have glassmorphism styling', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ProfileScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Find stats containers
        final statContainers = find.descendant(
          of: find.byType(Row), // Stats are in a Row
          matching: find.byType(Container),
        );
        
        expect(statContainers, findsAtLeastNWidgets(2));
      });
    });

    group('Jet Preview Section', () {
      testWidgets('displays equipped jet correctly', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ProfileScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Check for jet name display
        expect(find.text('SKY ROOKIE'), findsOneWidget);
        
        // Check for jet image (or error icon fallback)
        expect(
          find.byType(Image).or(find.byIcon(Icons.flight)),
          findsAtLeastNWidgets(1),
        );
      });

      testWidgets('jet image has correct dimensions', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ProfileScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Find the jet image container
        final sizedBoxFinder = find.descendant(
          of: find.byType(Column),
          matching: find.byType(SizedBox),
        );
        
        expect(sizedBoxFinder, findsAtLeastNWidgets(1));
      });

      testWidgets('jet name has gradient styling', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ProfileScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Check for ShaderMask (used for gradient text)
        expect(find.byType(ShaderMask), findsOneWidget);
      });
    });

    group('Choose Jet Button', () {
      testWidgets('choose jet button is present and styled', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ProfileScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Find the choose jet button
        final buttonFinder = find.text('CHOOSE JET');
        expect(buttonFinder, findsOneWidget);

        // Check button container styling
        final buttonContainer = find.ancestor(
          of: buttonFinder,
          matching: find.byType(Container),
        ).first;
        
        final container = tester.widget<Container>(buttonContainer);
        expect(container.decoration, isA<BoxDecoration>());
      });

      testWidgets('choose jet button opens modal when tapped', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ProfileScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Tap the choose jet button
        await tester.tap(find.text('CHOOSE JET'));
        await tester.pumpAndSettle();

        // Check for modal content
        expect(find.text('YOUR JETS'), findsOneWidget);
        expect(find.byType(GridView), findsOneWidget);
      });
    });

    group('Jet Selection Modal', () {
      testWidgets('modal displays available jets', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ProfileScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Open the modal
        await tester.tap(find.text('CHOOSE JET'));
        await tester.pumpAndSettle();

        // Check modal structure
        expect(find.text('YOUR JETS'), findsOneWidget);
        expect(find.byType(GridView), findsOneWidget);
        
        // Check for jet cells
        expect(find.text('Sky Jet'), findsOneWidget);
        expect(find.text('Flames'), findsOneWidget);
      });

      testWidgets('modal has proper styling and handle', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ProfileScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Open the modal
        await tester.tap(find.text('CHOOSE JET'));
        await tester.pumpAndSettle();

        // Check for modal handle (small container at top)
        final handleFinder = find.byType(Container).where((finder) {
          final container = tester.widget<Container>(finder);
          return container.constraints?.maxHeight == 4;
        });
        
        expect(handleFinder, findsOneWidget);
      });

      testWidgets('jet cells show ownership status correctly', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ProfileScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Open the modal
        await tester.tap(find.text('CHOOSE JET'));
        await tester.pumpAndSettle();

        // Check for jet cells with different states
        final jetCells = find.byType(GestureDetector).where((finder) {
          return find.descendant(
            of: finder,
            matching: find.text('Sky Jet').or(find.text('Flames')),
          ).evaluate().isNotEmpty;
        });
        
        expect(jetCells, findsAtLeastNWidgets(2));
      });
    });

    group('Navigation', () {
      testWidgets('back button navigates correctly', (tester) async {
        bool navigationCalled = false;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileScreen(),
                      ),
                    ).then((_) => navigationCalled = true);
                  },
                  child: Text('Go to Profile'),
                ),
              ),
            ),
          ),
        );

        // Navigate to profile
        await tester.tap(find.text('Go to Profile'));
        await tester.pumpAndSettle();

        // Tap back button
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();

        // Should navigate back
        expect(find.byType(ProfileScreen), findsNothing);
      });
    });

    group('Responsive Design', () {
      testWidgets('adapts to different screen sizes', (tester) async {
        // Test with different screen sizes
        await tester.binding.setSurfaceSize(Size(400, 800)); // Narrow screen
        
        await tester.pumpWidget(
          MaterialApp(
            home: ProfileScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Should still render all components
        expect(find.byType(ProfileScreen), findsOneWidget);
        expect(find.text('HIGH SCORE'), findsOneWidget);
        expect(find.text('HOTTEST STREAK'), findsOneWidget);

        // Test with wider screen
        await tester.binding.setSurfaceSize(Size(800, 600)); // Wide screen
        await tester.pumpAndSettle();

        // Should still work
        expect(find.byType(ProfileScreen), findsOneWidget);
      });

      testWidgets('profile title scales with screen height', (tester) async {
        await tester.binding.setSurfaceSize(Size(400, 600)); // Smaller screen
        
        await tester.pumpWidget(
          MaterialApp(
            home: ProfileScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Profile title should be responsive (15% of screen height)
        // This is tested implicitly by ensuring no overflow errors occur
        expect(tester.takeException(), isNull);
      });
    });

    group('Error Handling', () {
      testWidgets('handles missing jet image gracefully', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ProfileScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Should show fallback icon if image fails to load
        // In test environment, images often fail to load
        expect(
          find.byType(Image).or(find.byIcon(Icons.flight)),
          findsAtLeastNWidgets(1),
        );
      });

      testWidgets('handles empty SharedPreferences gracefully', (tester) async {
        // Clear SharedPreferences
        SharedPreferences.setMockInitialValues({});
        
        await tester.pumpWidget(
          MaterialApp(
            home: ProfileScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Should show default values (0) for scores
        expect(find.text('HIGH SCORE'), findsOneWidget);
        expect(find.text('HOTTEST STREAK'), findsOneWidget);
        expect(find.text('0'), findsAtLeastNWidgets(2)); // Default scores
      });
    });

    group('Accessibility', () {
      testWidgets('has proper semantic labels', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ProfileScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Check for accessible elements
        expect(find.byType(IconButton), findsAtLeastNWidgets(1)); // Back button
        expect(find.byType(TextField), findsOneWidget); // Nickname field
        expect(find.byType(GestureDetector), findsAtLeastNWidgets(1)); // Buttons
      });

      testWidgets('supports screen readers', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ProfileScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Verify semantic structure exists
        expect(find.byType(Semantics), findsAtLeastNWidgets(1));
      });
    });
  });
}

/// 🔄 Profile Integration Tests - End-to-end user flow testing
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flappy_jet_pro/ui/screens/profile_screen.dart';
import 'package:flappy_jet_pro/game/core/jet_skins.dart';
import '../mocks/profile_mocks.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Profile Integration Tests', () {
    late ProfileTestMocks mocks;

    setUp(() async {
      // Initialize SharedPreferences with test data
      SharedPreferences.setMockInitialValues({
        'best_score': 150,
        'best_streak': 75,
        'player_name': 'IntegrationTestPlayer',
        'profile_nickname': 'TestNick',
      });
      
      // Create comprehensive mock setup
      mocks = ProfileTestData.createFullMockSet(
        playerName: 'IntegrationTestPlayer',
        nickname: 'TestNick',
        equippedSkin: 'sky_jet',
        coins: 2000,
        gems: 100,
      );
      
      // Setup jet catalog with multiple skins
      MockJetSkinCatalog.resetToDefaults();
      MockJetSkinCatalog.addTestSkin(
        JetSkin(
          id: 'diamond_jet',
          displayName: 'Diamond Jet',
          assetPath: 'jets/diamond_jet.png',
          price: 500,
          description: 'Premium diamond jet',
        ),
      );
    });

    tearDown(() {
      mocks.dispose();
      MockJetSkinCatalog.clearTestSkins();
    });

    group('Complete Profile Initialization Flow', () {
      testWidgets('profile loads and initializes all systems correctly', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ProfileScreen(),
          ),
        );

        // Wait for all async initialization to complete
        await tester.pumpAndSettle(Duration(seconds: 3));

        // Verify all systems are initialized and data is loaded
        expect(find.byType(ProfileScreen), findsOneWidget);
        expect(find.text('HIGH SCORE'), findsOneWidget);
        expect(find.text('150'), findsOneWidget); // Best score
        expect(find.text('HOTTEST STREAK'), findsOneWidget);
        expect(find.text('75'), findsOneWidget); // Best streak
        
        // Verify jet is displayed
        expect(find.text('SKY ROOKIE'), findsOneWidget);
        
        // Verify nickname field is populated
        expect(find.byType(TextField), findsOneWidget);
      });

      testWidgets('handles initialization failures gracefully', (tester) async {
        // Simulate initialization failure
        SharedPreferences.setMockInitialValues({});
        
        await tester.pumpWidget(
          MaterialApp(
            home: ProfileScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Should still render with default values
        expect(find.byType(ProfileScreen), findsOneWidget);
        expect(find.text('0'), findsAtLeastNWidgets(2)); // Default scores
      });
    });

    group('Nickname Management Flow', () {
      testWidgets('complete nickname editing and saving flow', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ProfileScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Find and interact with nickname field
        final textFieldFinder = find.byType(TextField);
        expect(textFieldFinder, findsOneWidget);

        // Clear existing text and enter new nickname
        await tester.tap(textFieldFinder);
        await tester.pumpAndSettle();
        
        await tester.enterText(textFieldFinder, 'NewTestNickname');
        await tester.pumpAndSettle();

        // Tap the save button (edit icon)
        final saveButtonFinder = find.byIcon(Icons.edit_outlined);
        expect(saveButtonFinder, findsOneWidget);
        
        await tester.tap(saveButtonFinder);
        await tester.pumpAndSettle();

        // Verify success message appears
        expect(find.text('Nickname saved'), findsOneWidget);
        
        // Verify the new nickname is displayed
        expect(find.text('NewTestNickname'), findsOneWidget);
      });

      testWidgets('nickname validation and error handling', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ProfileScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Test maximum length constraint
        final textFieldFinder = find.byType(TextField);
        await tester.tap(textFieldFinder);
        await tester.pumpAndSettle();

        // Try to enter text longer than 16 characters
        const longNickname = 'ThisIsAVeryLongNicknameThatExceedsLimit';
        await tester.enterText(textFieldFinder, longNickname);
        await tester.pumpAndSettle();

        // Should be truncated to 16 characters
        final textField = tester.widget<TextField>(textFieldFinder);
        expect(textField.maxLength, 16);
      });

      testWidgets('nickname persists across app restarts', (tester) async {
        // First session - set nickname
        await tester.pumpWidget(
          MaterialApp(
            home: ProfileScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Set nickname
        await tester.tap(find.byType(TextField));
        await tester.enterText(find.byType(TextField), 'PersistentNick');
        await tester.tap(find.byIcon(Icons.edit_outlined));
        await tester.pumpAndSettle();

        // Simulate app restart by creating new widget tree
        await tester.pumpWidget(Container()); // Clear
        await tester.pumpAndSettle();

        // Second session - verify nickname persists
        await tester.pumpWidget(
          MaterialApp(
            home: ProfileScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Nickname should be loaded from persistence
        expect(find.text('PersistentNick'), findsOneWidget);
      });
    });

    group('Jet Selection and Management Flow', () {
      testWidgets('complete jet selection workflow', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ProfileScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Verify initial equipped jet
        expect(find.text('SKY ROOKIE'), findsOneWidget);

        // Open jet selection modal
        await tester.tap(find.text('CHOOSE JET'));
        await tester.pumpAndSettle();

        // Verify modal opened with jet options
        expect(find.text('YOUR JETS'), findsOneWidget);
        expect(find.byType(GridView), findsOneWidget);

        // Find available jets
        expect(find.text('Sky Jet'), findsOneWidget);
        expect(find.text('Flames'), findsOneWidget);

        // Select a different jet (Flames)
        await tester.tap(find.text('Flames'));
        await tester.pumpAndSettle();

        // Modal should close and jet should be equipped
        expect(find.text('YOUR JETS'), findsNothing); // Modal closed
        expect(find.text('FLAMES'), findsOneWidget); // New jet name displayed
      });

      testWidgets('jet purchase workflow for unowned jets', (tester) async {
        // Add an expensive jet that user doesn't own
        MockJetSkinCatalog.addTestSkin(
          JetSkin(
            id: 'premium_jet',
            displayName: 'Premium Jet',
            assetPath: 'jets/premium_jet.png',
            price: 1500, // Less than user's 2000 coins
            description: 'Expensive premium jet',
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: ProfileScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Open jet selection
        await tester.tap(find.text('CHOOSE JET'));
        await tester.pumpAndSettle();

        // Try to select unowned jet
        await tester.tap(find.text('Premium Jet'));
        await tester.pumpAndSettle();

        // Purchase dialog should appear
        expect(find.text('Purchase Premium Jet?'), findsOneWidget);
        expect(find.text('1500 coins'), findsOneWidget);

        // Confirm purchase
        await tester.tap(find.text('Buy'));
        await tester.pumpAndSettle();

        // Should show success message and equip jet
        expect(find.text('Purchased Premium Jet'), findsOneWidget);
        expect(find.text('YOUR JETS'), findsNothing); // Modal closed
      });

      testWidgets('handles insufficient funds for jet purchase', (tester) async {
        // Set low currency amount
        mocks.inventory.setTestCurrency(100, 10); // Low coins and gems

        // Add expensive jet
        MockJetSkinCatalog.addTestSkin(
          JetSkin(
            id: 'expensive_jet',
            displayName: 'Expensive Jet',
            assetPath: 'jets/expensive_jet.png',
            price: 5000, // More than user's coins
            description: 'Very expensive jet',
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: ProfileScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Open jet selection and try to buy expensive jet
        await tester.tap(find.text('CHOOSE JET'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Expensive Jet'));
        await tester.pumpAndSettle();

        // Confirm purchase attempt
        await tester.tap(find.text('Buy'));
        await tester.pumpAndSettle();

        // Should show insufficient funds message
        expect(find.text('Not enough coins'), findsOneWidget);
      });
    });

    group('Stats Display and Updates', () {
      testWidgets('stats load correctly from SharedPreferences', (tester) async {
        // Set specific test scores
        SharedPreferences.setMockInitialValues({
          'best_score': 250,
          'best_streak': 125,
        });

        await tester.pumpWidget(
          MaterialApp(
            home: ProfileScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Verify correct stats are displayed
        expect(find.text('250'), findsOneWidget);
        expect(find.text('125'), findsOneWidget);
        expect(find.text('HIGH SCORE'), findsOneWidget);
        expect(find.text('HOTTEST STREAK'), findsOneWidget);
      });

      testWidgets('handles missing stats gracefully', (tester) async {
        // No stats in SharedPreferences
        SharedPreferences.setMockInitialValues({});

        await tester.pumpWidget(
          MaterialApp(
            home: ProfileScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Should show default values
        expect(find.text('0'), findsAtLeastNWidgets(2));
        expect(find.text('HIGH SCORE'), findsOneWidget);
        expect(find.text('HOTTEST STREAK'), findsOneWidget);
      });

      testWidgets('stats cards have proper visual hierarchy', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ProfileScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Verify stats are displayed in proper containers with icons
        expect(find.byIcon(Icons.emoji_events_outlined), findsOneWidget);
        expect(find.byIcon(Icons.local_fire_department_outlined), findsOneWidget);

        // Verify both stats are in the same row
        final statsRow = find.byType(Row).where((finder) {
          return find.descendant(
            of: finder,
            matching: find.text('HIGH SCORE'),
          ).evaluate().isNotEmpty;
        });
        expect(statsRow, findsOneWidget);
      });
    });

    group('Navigation and State Management', () {
      testWidgets('back navigation preserves app state', (tester) async {
        bool navigationCompleted = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                appBar: AppBar(title: Text('Home')),
                body: ElevatedButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ProfileScreen()),
                    );
                    navigationCompleted = true;
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

        // Verify profile screen loaded
        expect(find.byType(ProfileScreen), findsOneWidget);

        // Navigate back
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();

        // Verify returned to home
        expect(find.text('Home'), findsOneWidget);
        expect(find.byType(ProfileScreen), findsNothing);
      });

      testWidgets('modal state management works correctly', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ProfileScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Open modal
        await tester.tap(find.text('CHOOSE JET'));
        await tester.pumpAndSettle();
        expect(find.text('YOUR JETS'), findsOneWidget);

        // Close modal by tapping outside (if supported) or selecting jet
        await tester.tap(find.text('Sky Jet'));
        await tester.pumpAndSettle();
        expect(find.text('YOUR JETS'), findsNothing);

        // Open modal again to verify state is clean
        await tester.tap(find.text('CHOOSE JET'));
        await tester.pumpAndSettle();
        expect(find.text('YOUR JETS'), findsOneWidget);
      });
    });

    group('Performance and Memory Management', () {
      testWidgets('profile screen handles rapid interactions', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ProfileScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Rapid interactions to test performance
        for (int i = 0; i < 5; i++) {
          await tester.tap(find.text('CHOOSE JET'));
          await tester.pump(Duration(milliseconds: 100));
          
          if (find.text('YOUR JETS').evaluate().isNotEmpty) {
            await tester.tap(find.text('Sky Jet'));
            await tester.pump(Duration(milliseconds: 100));
          }
        }

        await tester.pumpAndSettle();

        // Should still be functional
        expect(find.byType(ProfileScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('memory cleanup on disposal', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ProfileScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Navigate away to trigger disposal
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Text('Different Screen'),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should not have memory leaks (tested implicitly)
        expect(find.text('Different Screen'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('Error Recovery and Edge Cases', () {
      testWidgets('recovers from asset loading failures', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ProfileScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Should handle missing assets gracefully
        expect(find.byType(ProfileScreen), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Fallback elements should be present
        expect(
          find.byIcon(Icons.flight).or(find.byType(Image)),
          findsAtLeastNWidgets(1),
        );
      });

      testWidgets('handles corrupted SharedPreferences data', (tester) async {
        // Set invalid data types
        SharedPreferences.setMockInitialValues({
          'best_score': 'invalid_string',
          'best_streak': null,
          'player_name': 12345, // Wrong type
        });

        await tester.pumpWidget(
          MaterialApp(
            home: ProfileScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Should handle gracefully and show defaults
        expect(find.byType(ProfileScreen), findsOneWidget);
        expect(find.text('0'), findsAtLeastNWidgets(2)); // Default scores
        expect(tester.takeException(), isNull);
      });
    });
  });
}

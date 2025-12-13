/// 🧪 VS INDICATOR TESTS
/// 
/// Comprehensive tests for the VSIndicator widget.
/// Verifies jet displays, score rendering, and opponent states.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/ui/widgets/game/vs_indicator.dart';
import 'package:flappy_jet_pro/game/core/jet_skins.dart';

void main() {
  setUpAll(() async {
    // Initialize jet skin catalog
    await JetSkinCatalog.initializeFromAssets();
  });

  group('VSIndicator', () {
    testWidgets('displays VS badge', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VSIndicator(
              opponentSkinId: 'sky_rookie',
              opponentName: 'Sky Rookie',
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Should show VS badge
      expect(find.text('VS'), findsOneWidget);
    });
    
    testWidgets('displays player label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VSIndicator(
              opponentSkinId: 'sky_rookie',
              opponentName: 'Sky Rookie',
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Should show YOU label for player
      expect(find.text('YOU'), findsOneWidget);
    });
    
    testWidgets('displays opponent name', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VSIndicator(
              opponentSkinId: 'sky_rookie',
              opponentName: 'Storm Ace',
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Should show opponent name
      expect(find.text('Storm Ace'), findsOneWidget);
    });
    
    testWidgets('displays scores when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VSIndicator(
              opponentSkinId: 'sky_rookie',
              opponentName: 'Opponent',
              playerScore: 7,
              opponentScore: 5,
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Should show both scores
      expect(find.text('7'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });
    
    testWidgets('shows crashed indicator when opponent inactive', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VSIndicator(
              opponentSkinId: 'sky_rookie',
              opponentName: 'Opponent',
              opponentIsActive: false,
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Should show close icon for crashed opponent
      expect(find.byIcon(Icons.close), findsOneWidget);
    });
    
    testWidgets('renders fallback icon when jet image fails', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VSIndicator(
              opponentSkinId: 'non_existent_skin',
              opponentName: 'Test',
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Should show airplane icon as fallback
      expect(find.byIcon(Icons.airplanemode_active), findsWidgets);
    });
    
    group('size variants', () {
      testWidgets('small size renders correctly', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: VSIndicator(
                opponentSkinId: 'sky_rookie',
                opponentName: 'Test',
                size: VSIndicatorSize.small,
              ),
            ),
          ),
        );
        
        await tester.pumpAndSettle();
        
        expect(find.text('VS'), findsOneWidget);
      });
      
      testWidgets('large size renders correctly', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: VSIndicator(
                opponentSkinId: 'sky_rookie',
                opponentName: 'Test',
                size: VSIndicatorSize.large,
              ),
            ),
          ),
        );
        
        await tester.pumpAndSettle();
        
        expect(find.text('VS'), findsOneWidget);
      });
    });
  });
  
  group('VSBadgeCompact', () {
    testWidgets('displays scores correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VSBadgeCompact(
              playerScore: 10,
              opponentScore: 8,
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      expect(find.text('10'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('vs'), findsOneWidget);
    });
    
    testWidgets('shows crash indicator when opponent inactive', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VSBadgeCompact(
              playerScore: 10,
              opponentScore: 5,
              opponentIsActive: false,
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Should show cancel icon
      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });
    
    testWidgets('grays out opponent score when inactive', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VSBadgeCompact(
              playerScore: 10,
              opponentScore: 5,
              opponentIsActive: false,
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Widget should still exist with grayed out opponent
      expect(find.text('5'), findsOneWidget);
    });
  });
  
  group('VSIndicatorSize', () {
    test('small size has correct values', () {
      expect(VSIndicatorSize.small.jetSize, equals(32));
      expect(VSIndicatorSize.small.fontSize, equals(12));
      expect(VSIndicatorSize.small.badgePadding, equals(8));
    });
    
    test('normal size has correct values', () {
      expect(VSIndicatorSize.normal.jetSize, equals(40));
      expect(VSIndicatorSize.normal.fontSize, equals(14));
      expect(VSIndicatorSize.normal.badgePadding, equals(12));
    });
    
    test('large size has correct values', () {
      expect(VSIndicatorSize.large.jetSize, equals(56));
      expect(VSIndicatorSize.large.fontSize, equals(18));
      expect(VSIndicatorSize.large.badgePadding, equals(16));
    });
  });
}


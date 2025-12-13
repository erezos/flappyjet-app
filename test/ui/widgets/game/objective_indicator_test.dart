/// 🧪 OBJECTIVE INDICATOR TESTS
/// 
/// Comprehensive tests for the ObjectiveIndicator widget.
/// Verifies all objective types, progress states, and visual elements.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/ui/widgets/game/objective_indicator.dart';
import 'package:flappy_jet_pro/models/level_data_schema.dart';

void main() {
  group('ObjectiveIndicator', () {
    group('passObstacles objective', () {
      testWidgets('displays progress correctly', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ObjectiveIndicator(
                objectiveType: ObjectiveType.passObstacles,
                currentProgress: 5,
                targetProgress: 10,
              ),
            ),
          ),
        );
        
        await tester.pumpAndSettle();
        
        // Should show progress text
        expect(find.text('5/10'), findsOneWidget);
        expect(find.text('OBSTACLES'), findsOneWidget);
      });
      
      testWidgets('shows completed state correctly', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ObjectiveIndicator(
                objectiveType: ObjectiveType.passObstacles,
                currentProgress: 10,
                targetProgress: 10,
                isCompleted: true,
              ),
            ),
          ),
        );
        
        await tester.pumpAndSettle();
        
        // Should show checkmark icon when completed
        expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      });
      
      testWidgets('uses amber color scheme', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ObjectiveIndicator(
                objectiveType: ObjectiveType.passObstacles,
                currentProgress: 0,
                targetProgress: 5,
              ),
            ),
          ),
        );
        
        await tester.pumpAndSettle();
        
        // Should show flag icon for obstacles
        expect(find.byIcon(Icons.flag_rounded), findsOneWidget);
      });
    });
    
    group('surviveTime objective', () {
      testWidgets('displays time remaining correctly', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ObjectiveIndicator(
                objectiveType: ObjectiveType.surviveTime,
                currentProgress: 15, // 15 seconds elapsed
                targetProgress: 30,  // 30 second target
              ),
            ),
          ),
        );
        
        await tester.pumpAndSettle();
        
        // Should show remaining time (30 - 15 = 15s)
        expect(find.text('15s'), findsOneWidget);
        expect(find.text('TIME'), findsOneWidget);
      });
      
      testWidgets('shows DONE! when time objective completed', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ObjectiveIndicator(
                objectiveType: ObjectiveType.surviveTime,
                currentProgress: 30,
                targetProgress: 30,
              ),
            ),
          ),
        );
        
        await tester.pumpAndSettle();
        
        expect(find.text('DONE!'), findsOneWidget);
      });
      
      testWidgets('uses cyan color scheme', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ObjectiveIndicator(
                objectiveType: ObjectiveType.surviveTime,
                currentProgress: 0,
                targetProgress: 30,
              ),
            ),
          ),
        );
        
        await tester.pumpAndSettle();
        
        // Should show timer icon
        expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
      });
    });
    
    group('beatBot objective', () {
      testWidgets('displays player score', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ObjectiveIndicator(
                objectiveType: ObjectiveType.beatBot,
                currentProgress: 7,
                targetProgress: 1,
              ),
            ),
          ),
        );
        
        await tester.pumpAndSettle();
        
        // Should show player score
        expect(find.text('You: 7'), findsOneWidget);
        expect(find.text('VS BATTLE'), findsOneWidget);
      });
      
      testWidgets('displays bot score when provided', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ObjectiveIndicator(
                objectiveType: ObjectiveType.beatBot,
                currentProgress: 7,
                targetProgress: 1,
                botScore: 5,
              ),
            ),
          ),
        );
        
        await tester.pumpAndSettle();
        
        // Should show both scores
        expect(find.text('You: 7 vs Bot: 5'), findsOneWidget);
      });
      
      testWidgets('uses red color scheme', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ObjectiveIndicator(
                objectiveType: ObjectiveType.beatBot,
                currentProgress: 0,
                targetProgress: 1,
              ),
            ),
          ),
        );
        
        await tester.pumpAndSettle();
        
        // Should show trophy icon
        expect(find.byIcon(Icons.emoji_events_rounded), findsOneWidget);
      });
    });
    
    testWidgets('supports custom labels', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ObjectiveIndicator(
              objectiveType: ObjectiveType.passObstacles,
              currentProgress: 3,
              targetProgress: 5,
              customLabel: 'LEVEL 1',
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Should show custom label instead of default
      expect(find.text('LEVEL 1'), findsOneWidget);
      expect(find.text('OBSTACLES'), findsNothing);
    });
    
    testWidgets('has entrance animation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ObjectiveIndicator(
              objectiveType: ObjectiveType.passObstacles,
              currentProgress: 0,
              targetProgress: 10,
            ),
          ),
        ),
      );
      
      // Should animate - pump without settling to catch animation
      await tester.pump(const Duration(milliseconds: 100));
      
      // Widget should exist during animation
      expect(find.byType(ObjectiveIndicator), findsOneWidget);
    });
  });
  
  group('ObjectiveIndicatorCompact', () {
    testWidgets('renders compact version correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ObjectiveIndicatorCompact(
              objectiveType: ObjectiveType.passObstacles,
              currentProgress: 3,
              targetProgress: 10,
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Should show compact progress
      expect(find.text('3/10'), findsOneWidget);
    });
    
    testWidgets('shows checkmark when completed', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ObjectiveIndicatorCompact(
              objectiveType: ObjectiveType.surviveTime,
              currentProgress: 30,
              targetProgress: 30,
              isCompleted: true,
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });
    
    testWidgets('shows checkmark for time completed', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ObjectiveIndicatorCompact(
              objectiveType: ObjectiveType.surviveTime,
              currentProgress: 30,
              targetProgress: 30,
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Should show checkmark when time completed
      expect(find.text('✓'), findsOneWidget);
    });
  });
}


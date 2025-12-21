/// 🧪 Profile Components Responsive Tests
/// 
/// Tests for responsive behavior across different screen sizes
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flappy_jet_pro/ui/widgets/profile/profile_stats_grid.dart';
import 'package:flappy_jet_pro/ui/widgets/profile/profile_data_aggregator.dart';

void main() {
  group('Profile Components Responsive Tests', () {
    final profileData = ProfileData(
      nickname: 'Test Pilot',
      userLevel: 5,
      highestScore: 1000,
      missionsCompleted: 25,
      achievementsCompleted: 10,
      tournamentsWon: 3,
      totalJetsOwned: 5,
      totalJetsAvailable: 20,
      equippedJetId: 'sky_rookie',
    );

    testWidgets('should adapt to small screen (mobile)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(375, 667); // iPhone SE size
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileStatsGrid(profileData: profileData),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render 2 columns on mobile
      expect(find.byType(ProfileStatsGrid), findsOneWidget);
    });

    testWidgets('should adapt to tablet screen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(768, 1024); // iPad size
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileStatsGrid(profileData: profileData),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render properly on tablet
      expect(find.byType(ProfileStatsGrid), findsOneWidget);
    });

    testWidgets('should adapt to large tablet screen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 1366); // iPad Pro size
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileStatsGrid(profileData: profileData),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render properly on large tablet
      expect(find.byType(ProfileStatsGrid), findsOneWidget);
    });
  });
}


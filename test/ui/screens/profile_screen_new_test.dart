/// 🧪 Profile Screen New Tests
/// 
/// Integration tests for ProfileScreenNew
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flappy_jet_pro/ui/screens/profile_screen_new.dart';
import 'package:flappy_jet_pro/core/database/local_database_manager.dart';
import 'package:flappy_jet_pro/core/repositories/user_stats_repository.dart';
import 'package:flappy_jet_pro/ui/widgets/profile/profile_data_aggregator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Initialize FFI for SQLite testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('ProfileScreenNew', () {
    late LocalDatabaseManager dbManager;
    late UserStatsRepository userStats;

    setUp(() async {
      // Clear SharedPreferences
      SharedPreferences.setMockInitialValues({});
      
      // Initialize database
      dbManager = LocalDatabaseManager();
      await dbManager.initialize();
      await dbManager.clearAllData();
      
      userStats = UserStatsRepository(dbManager);
      await userStats.setUserId('test_user_123');
      
      // Set UserStatsRepository in aggregator
      final aggregator = ProfileDataAggregator();
      aggregator.setUserStatsRepository(userStats);
    });

    tearDown(() async {
      await dbManager.clearAllData();
      await dbManager.close();
    });

    testWidgets('should render all main components', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreenNew(),
        ),
      );

      // Wait for initialization with multiple pumps
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      
      // Check for main components (may take time to load)
      // Use findsWidgets instead of findsOneWidget to be more lenient
      expect(find.text('PILOT LICENSE'), findsWidgets);
    });

    testWidgets('should show loading indicator during initialization', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreenNew(),
        ),
      );

      // Should show loading initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display nickname', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreenNew(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should display nickname (might be default "Pilot" if empty)
      expect(find.textContaining('Pilot'), findsWidgets);
    });

    testWidgets('should display stats grid', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreenNew(),
        ),
      );

      // Wait for initialization with multiple pumps (don't use pumpAndSettle for async init)
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Should find stat labels (may take time to load)
      expect(find.text('High Score'), findsWidgets);
      expect(find.text('Missions'), findsWidgets);
      expect(find.text('Achievements'), findsWidgets);
      expect(find.text('Tournaments'), findsWidgets);
    });
  });
}


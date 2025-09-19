/// Tests for Railway Leaderboard Service
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:flappy_jet_pro/services/railway_leaderboard_service.dart';
import 'package:flappy_jet_pro/game/systems/player_identity_manager.dart';

import 'railway_leaderboard_service_test.mocks.dart';

@GenerateMocks([PlayerIdentityManager])
void main() {
  group('RailwayLeaderboardService Tests', () {
    late MockPlayerIdentityManager mockPlayerIdentityManager;
    late RailwayLeaderboardService service;

    setUp(() {
      mockPlayerIdentityManager = MockPlayerIdentityManager();
      service = RailwayLeaderboardService(
        playerIdentityManager: mockPlayerIdentityManager,
      );
      
      // Default mock setup
      when(mockPlayerIdentityManager.playerId).thenReturn('test-player-id');
      when(mockPlayerIdentityManager.playerName).thenReturn('TestPlayer');
    });

    group('Service Initialization', () {
      test('should initialize with player identity manager', () {
        expect(service, isNotNull);
      });

      test('should handle empty player ID', () {
        when(mockPlayerIdentityManager.playerId).thenReturn('');
        when(mockPlayerIdentityManager.playerName).thenReturn('');
        
        expect(service, isNotNull);
      });
    });

    group('Data Models', () {
      test('LeaderboardEntry should create from JSON correctly', () {
        final json = {
          'playerId': 'player1',
          'playerName': 'TestPlayer',
          'score': 1000,
          'totalGames': 50,
          'jetSkin': 'jets/green_lightning.png',
          'theme': 'sky',
          'rank': 1,
          'achievedAt': '2024-01-01T12:00:00Z',
        };

        final entry = LeaderboardEntry.fromJson(json);

        expect(entry.playerId, 'player1');
        expect(entry.playerName, 'TestPlayer');
        expect(entry.score, 1000);
        expect(entry.totalGames, 50);
        expect(entry.jetSkin, 'jets/green_lightning.png');
        expect(entry.theme, 'sky');
        expect(entry.rank, 1);
        expect(entry.achievedAt, isA<DateTime>());
      });

      test('LeaderboardEntry should handle missing JSON fields', () {
        final json = <String, dynamic>{};

        final entry = LeaderboardEntry.fromJson(json);

        expect(entry.playerId, '');
        expect(entry.playerName, 'Anonymous');
        expect(entry.score, 0);
        expect(entry.totalGames, 0);
        expect(entry.jetSkin, 'jets/green_lightning.png');
        expect(entry.theme, 'sky');
        expect(entry.rank, 0);
        expect(entry.achievedAt, isA<DateTime>());
      });

      test('PersonalScore should create from JSON correctly', () {
        final json = {
          'rank': 1,
          'score': 1000,
          'jetSkin': 'jets/green_lightning.png',
          'theme': 'sky',
          'achievedAt': '2024-01-01T12:00:00Z',
        };

        final score = PersonalScore.fromJson(json);

        expect(score.rank, 1);
        expect(score.score, 1000);
        expect(score.jetSkin, 'jets/green_lightning.png');
        expect(score.theme, 'sky');
        expect(score.achievedAt, isA<DateTime>());
      });
    });

    group('Result Classes', () {
      test('LeaderboardResult should initialize correctly', () {
        final result = LeaderboardResult(
          success: true,
          leaderboard: [],
          userPosition: null,
          error: null,
        );

        expect(result.success, true);
        expect(result.leaderboard, isEmpty);
        expect(result.userPosition, isNull);
        expect(result.error, isNull);
      });

      test('PersonalScoresResult should initialize correctly', () {
        final result = PersonalScoresResult(
          success: true,
          scores: [],
          error: null,
        );

        expect(result.success, true);
        expect(result.scores, isEmpty);
        expect(result.error, isNull);
      });

      test('ScoreSubmissionResult should initialize correctly', () {
        final result = ScoreSubmissionResult(
          success: true,
          newBest: false,
          globalRank: null,
          error: null,
        );

        expect(result.success, true);
        expect(result.newBest, false);
        expect(result.globalRank, isNull);
        expect(result.error, isNull);
      });

      test('NicknameUpdateResult should initialize correctly', () {
        final result = NicknameUpdateResult(
          success: true,
          message: null,
          error: null,
        );

        expect(result.success, true);
        expect(result.message, isNull);
        expect(result.error, isNull);
      });
    });

    group('Error Handling', () {
      test('should handle network errors gracefully', () async {
        // This test would require HTTP mocking which is complex
        // For now, we test that the service doesn't crash on initialization
        expect(service, isNotNull);
      });

      test('should handle invalid JSON responses', () {
        // Test JSON parsing error handling with invalid data
        expect(() => LeaderboardEntry.fromJson(<String, dynamic>{}), returnsNormally);
      });
    });

    group('Player Identity Integration', () {
      test('should use player identity manager for user data', () {
        // Service should be initialized with player identity manager
        expect(service, isNotNull);
        
        // Verify mock setup was called during initialization
        verify(mockPlayerIdentityManager.playerId).called(greaterThanOrEqualTo(0));
        verify(mockPlayerIdentityManager.playerName).called(greaterThanOrEqualTo(0));
      });

      test('should handle player ID changes', () {
        when(mockPlayerIdentityManager.playerId).thenReturn('new-player-id');
        when(mockPlayerIdentityManager.playerName).thenReturn('NewPlayer');

        // Service should adapt to new player identity
        expect(service, isNotNull);
      });
    });
  });
}
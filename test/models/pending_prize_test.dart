/// Unit tests for PendingPrize model
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/models/pending_prize.dart';

void main() {
  group('PendingPrize', () {
    late PendingPrize testPrize;
    late DateTime testAwardedAt;

    setUp(() {
      testAwardedAt = DateTime.parse('2025-11-09T10:00:00Z');
      testPrize = PendingPrize(
        prizeId: 'prize_123',
        tournamentId: 'tournament_456',
        tournamentName: 'Weekly Championship',
        rank: 1,
        coins: 1000,
        gems: 50,
        awardedAt: testAwardedAt,
      );
    });

    test('creates prize with correct properties', () {
      expect(testPrize.prizeId, 'prize_123');
      expect(testPrize.tournamentId, 'tournament_456');
      expect(testPrize.tournamentName, 'Weekly Championship');
      expect(testPrize.rank, 1);
      expect(testPrize.coins, 1000);
      expect(testPrize.gems, 50);
      expect(testPrize.awardedAt, testAwardedAt);
      expect(testPrize.claimedAt, isNull);
    });

    test('fromJson creates prize correctly', () {
      final json = {
        'prize_id': 'prize_789',
        'tournament_id': 'tournament_101',
        'tournament_name': 'Grand Tournament',
        'rank': 2,
        'coins': 500,
        'gems': 25,
        'awarded_at': '2025-11-09T12:00:00Z',
      };

      final prize = PendingPrize.fromJson(json);

      expect(prize.prizeId, 'prize_789');
      expect(prize.tournamentId, 'tournament_101');
      expect(prize.tournamentName, 'Grand Tournament');
      expect(prize.rank, 2);
      expect(prize.coins, 500);
      expect(prize.gems, 25);
      expect(prize.claimedAt, isNull);
    });

    test('toJson serializes correctly', () {
      final json = testPrize.toJson();

      expect(json['prize_id'], 'prize_123');
      expect(json['tournament_id'], 'tournament_456');
      expect(json['tournament_name'], 'Weekly Championship');
      expect(json['rank'], 1);
      expect(json['coins'], 1000);
      expect(json['gems'], 50);
      expect(json['awarded_at'], testAwardedAt.toIso8601String());
      expect(json['claimed_at'], isNull);
    });

    test('toDb converts to database map correctly', () {
      final dbMap = testPrize.toDb();

      expect(dbMap['prize_id'], 'prize_123');
      expect(dbMap['tournament_id'], 'tournament_456');
      expect(dbMap['tournament_name'], 'Weekly Championship');
      expect(dbMap['rank'], 1);
      expect(dbMap['coins'], 1000);
      expect(dbMap['gems'], 50);
      expect(dbMap['awarded_at'], testAwardedAt.millisecondsSinceEpoch);
      expect(dbMap['claimed_at'], isNull);
    });

    test('fromDb creates prize from database map', () {
      final dbMap = {
        'prize_id': 'prize_db',
        'tournament_id': 'tournament_db',
        'tournament_name': 'DB Tournament',
        'rank': 3,
        'coins': 250,
        'gems': 10,
        'awarded_at': testAwardedAt.millisecondsSinceEpoch,
        'claimed_at': null,
      };

      final prize = PendingPrize.fromDb(dbMap);

      expect(prize.prizeId, 'prize_db');
      expect(prize.rank, 3);
      expect(prize.coins, 250);
      expect(prize.gems, 10);
      expect(prize.claimedAt, isNull);
    });

    test('isClaimed returns false for unclaimed prize', () {
      expect(testPrize.isClaimed, false);
      expect(testPrize.isUnclaimed, true);
    });

    test('isClaimed returns true for claimed prize', () {
      final claimedPrize = testPrize.copyWith(
        claimedAt: DateTime.now(),
      );

      expect(claimedPrize.isClaimed, true);
      expect(claimedPrize.isUnclaimed, false);
    });

    test('trophyColor returns correct color for ranks', () {
      expect(testPrize.trophyColor, 'gold'); // rank 1

      final silver = testPrize.copyWith(rank: 2);
      expect(silver.trophyColor, 'silver');

      final bronze = testPrize.copyWith(rank: 3);
      expect(bronze.trophyColor, 'bronze');

      final other = testPrize.copyWith(rank: 4);
      expect(other.trophyColor, 'default');
    });

    test('rankSuffix returns correct suffix', () {
      expect(testPrize.rankSuffix, '1st');

      expect(testPrize.copyWith(rank: 2).rankSuffix, '2nd');
      expect(testPrize.copyWith(rank: 3).rankSuffix, '3rd');
      expect(testPrize.copyWith(rank: 4).rankSuffix, '4th');
      expect(testPrize.copyWith(rank: 11).rankSuffix, '11th');
      expect(testPrize.copyWith(rank: 21).rankSuffix, '21st');
      expect(testPrize.copyWith(rank: 22).rankSuffix, '22nd');
      expect(testPrize.copyWith(rank: 23).rankSuffix, '23rd');
      expect(testPrize.copyWith(rank: 111).rankSuffix, '111th');
    });

    test('copyWith creates new instance with updated fields', () {
      final updated = testPrize.copyWith(
        coins: 2000,
        gems: 100,
      );

      expect(updated.prizeId, testPrize.prizeId);
      expect(updated.coins, 2000);
      expect(updated.gems, 100);
      // Objects are different instances
      expect(identical(updated, testPrize), false);
    });

    test('equality based on prizeId', () {
      final prize1 = PendingPrize(
        prizeId: 'same_id',
        tournamentId: 't1',
        tournamentName: 'Tournament',
        rank: 1,
        coins: 100,
        gems: 10,
        awardedAt: DateTime.now(),
      );

      final prize2 = PendingPrize(
        prizeId: 'same_id',
        tournamentId: 't2',
        tournamentName: 'Different Tournament',
        rank: 2,
        coins: 200,
        gems: 20,
        awardedAt: DateTime.now(),
      );

      expect(prize1 == prize2, true);
      expect(prize1.hashCode == prize2.hashCode, true);
    });

    test('toString returns readable string', () {
      final str = testPrize.toString();
      expect(str, contains('prize_123'));
      expect(str, contains('Weekly Championship'));
      expect(str, contains('rank: 1'));
      expect(str, contains('coins: 1000'));
      expect(str, contains('gems: 50'));
    });
  });
}


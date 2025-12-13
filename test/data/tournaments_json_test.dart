import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('tournaments.json', () {
    late Map<String, dynamic> data;
    late List<dynamic> tournaments;

    setUpAll(() async {
      final file = File('assets/data/tournaments.json');
      data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      tournaments = data['tournaments'] as List<dynamic>;
    });

    Map<String, dynamic>? find(String id) {
      try {
        return tournaments.firstWhere((t) => t['id'] == id) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    }

    test('bosses_showdown tournament exists and has valid structure', () {
      final bosses = find('bosses_showdown');
      expect(bosses, isNotNull, reason: 'bosses_showdown tournament must exist');

      final bossesPlayoff = bosses!['playoff_config'] as Map<String, dynamic>;
      expect(bossesPlayoff['total_opponents'], 8);
      expect((bossesPlayoff['rounds'] as List).length, 3);
      expect((bosses['levels'] as List).length, 3);
      expect(bosses['progression_type'], 'playoff');
    });

    test('stunt_tournament exists and has valid linear structure', () {
      final stunt = find('stunt_tournament');
      expect(stunt, isNotNull, reason: 'stunt_tournament must exist');

      expect(stunt!['progression_type'], 'linear');
      expect((stunt['levels'] as List).length, 5);
      expect(stunt['playoff_config'], isNull, reason: 'linear tournaments should not have playoff_config');
      
      // Verify moving obstacles configuration
      final firstLevel = (stunt['levels'] as List).first as Map<String, dynamic>;
      expect(firstLevel['obstacles'], isNotNull, reason: 'stunt levels should have obstacles config');
      final obstacles = firstLevel['obstacles'] as Map<String, dynamic>;
      expect(obstacles['pattern_mix'], isNotNull);
    });

    test('chopper_adventures mirrors bosses_showdown structure', () {
      final chopper = find('chopper_adventures');
      expect(chopper, isNotNull, reason: 'chopper_adventures tournament must exist');

      final chopperPlayoff = chopper!['playoff_config'] as Map<String, dynamic>;
      expect(chopperPlayoff['total_opponents'], 8);
      expect((chopperPlayoff['rounds'] as List).length, 3);
      expect((chopper['levels'] as List).length, 3);
      expect(chopper['progression_type'], 'playoff');
    });

    test('all tournaments have required fields', () {
      for (final tournament in tournaments) {
        final t = tournament as Map<String, dynamic>;
        expect(t['id'], isNotNull);
        expect(t['name'], isNotNull);
        expect(t['description'], isNotNull);
        expect(t['tier'], isNotNull);
        expect(t['status'], isNotNull);
        expect(t['progression_type'], isNotNull);
        expect(t['entry'], isNotNull);
        expect(t['levels'], isNotNull);
        expect(t['completion_reward'], isNotNull);
        expect(t['display'], isNotNull);
      }
    });
  });
}

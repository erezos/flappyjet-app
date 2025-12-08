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

    test('chopper_adventures mirrors bosses_showdown structure (3 rounds)', () {
      Map<String, dynamic> find(String id) =>
          tournaments.firstWhere((t) => t['id'] == id) as Map<String, dynamic>;

      final bosses = find('bosses_showdown');
      final chopper = find('chopper_adventures');

      final bossesPlayoff = bosses['playoff_config'] as Map<String, dynamic>;
      final chopperPlayoff = chopper['playoff_config'] as Map<String, dynamic>;

      expect(chopperPlayoff['total_opponents'], bossesPlayoff['total_opponents']);
      expect((chopperPlayoff['rounds'] as List).length,
          (bossesPlayoff['rounds'] as List).length);
      expect((chopper['levels'] as List).length,
          (bosses['levels'] as List).length);
    });
  });
}


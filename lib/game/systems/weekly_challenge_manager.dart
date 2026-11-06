import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/legal_config.dart';

class WeeklyScore {
  final String name;
  final int score;
  const WeeklyScore(this.name, this.score);
}

/// One shared seed per ISO week, plus a local board.
class WeeklyChallengeManager {
  static final WeeklyChallengeManager _instance = WeeklyChallengeManager._();
  factory WeeklyChallengeManager() => _instance;
  WeeklyChallengeManager._();

  static const _backend = 'https://flappyjet-backend-production.up.railway.app';

  int get seed {
    final now = DateTime.now().toUtc();
    final thursday = now.add(Duration(days: 3 - ((now.weekday + 6) % 7)));
    final firstThursday = DateTime.utc(thursday.year, 1, 4);
    final week = 1 + ((thursday.difference(firstThursday).inDays) / 7).floor();
    return thursday.year * 100 + week;
  }

  String get weekId => 'week_$seed';

  String shareLink(int score) =>
      '${LegalConfig.challengeUrl}?seed=$seed&score=$score';

  Future<int> bestScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('weekly_best_$seed') ?? 0;
  }

  Future<void> recordScore(int score, String name) async {
    final prefs = await SharedPreferences.getInstance();
    final best = prefs.getInt('weekly_best_$seed') ?? 0;
    if (score > best) {
      await prefs.setInt('weekly_best_$seed', score);
    }
    final raw = prefs.getStringList('weekly_board_$seed') ?? <String>[];
    raw.add(jsonEncode({'name': name, 'score': score}));
    raw.sort((a, b) {
      final as = (jsonDecode(a) as Map)['score'] as int;
      final bs = (jsonDecode(b) as Map)['score'] as int;
      return bs.compareTo(as);
    });
    await prefs.setStringList('weekly_board_$seed', raw.take(20).toList());
    try {
      await http.post(
        Uri.parse('$_backend/api/leaderboard/submit'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'board': weekId,
          'name': name,
          'score': score,
          'seed': seed,
        }),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}
  }

  Future<List<WeeklyScore>> leaderboard() async {
    try {
      final response = await http
          .get(Uri.parse('$_backend/api/leaderboard/global?board=$weekId'))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final rows = (body is Map ? body['scores'] : body) as List?;
        if (rows != null && rows.isNotEmpty) {
          return rows.map((row) {
            final map = row as Map;
            return WeeklyScore(
              (map['name'] ?? map['nickname'] ?? 'Pilot').toString(),
              (map['score'] as num?)?.toInt() ?? 0,
            );
          }).toList();
        }
      }
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('weekly_board_$seed') ?? <String>[];
    return raw.map((line) {
      final map = jsonDecode(line) as Map;
      return WeeklyScore(map['name'] as String, map['score'] as int);
    }).toList();
  }
}

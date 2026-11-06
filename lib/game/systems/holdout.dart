/// Stable 10 percent control group. The same player stays in or out of the
/// holdout across sessions. The holdout keeps today's built-in defaults.
class Holdout {
  static const int percent = 10;

  static bool isControl(String playerId) {
    if (playerId.isEmpty) return false;
    var hash = 0;
    for (final code in playerId.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    return hash % 100 < percent;
  }
}

import '../systems/remote_config_manager.dart';

/// Continue pricing for a single run.
///
/// Attempt 0 is a rewarded ad. Attempt 1 costs the second gem price.
/// Attempt 2 costs the third gem price. Later attempts are closed.
class ContinueOffer {
  static const int maxContinues = 3;

  static int gemCostForAttempt(int attemptIndex) {
    if (attemptIndex <= 0) return 0;
    final second = RemoteConfigManager().getInt('continue_gem_second', 20);
    final third = RemoteConfigManager().getInt('continue_gem_third', 50);
    if (attemptIndex == 1) return second;
    return third;
  }

  static bool isOpen(int attemptIndex) => attemptIndex >= 0 && attemptIndex < maxContinues;

  static double minProgress() =>
      RemoteConfigManager().getDouble('continue_min_progress', 0.5);
}

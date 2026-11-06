import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/game/core/continue_offer.dart';
import 'package:flappy_jet_pro/game/systems/weekly_challenge_manager.dart';

void main() {
  test('first continue is an ad and later continues cost gems', () {
    expect(ContinueOffer.gemCostForAttempt(0), 0);
    expect(ContinueOffer.gemCostForAttempt(1), 20);
    expect(ContinueOffer.gemCostForAttempt(2), 50);
    expect(ContinueOffer.isOpen(0), isTrue);
    expect(ContinueOffer.isOpen(3), isFalse);
  });

  test('weekly seed is stable inside one process', () {
    final manager = WeeklyChallengeManager();
    expect(manager.seed, manager.seed);
    expect(manager.shareLink(12), contains('seed=${manager.seed}'));
    expect(manager.shareLink(12), contains('score=12'));
  });
}

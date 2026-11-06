import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/game/systems/holdout.dart';

void main() {
  test('the same player stays in the same group', () {
    const player = 'device-abc-123';
    expect(Holdout.isControl(player), Holdout.isControl(player));
  });

  test('an empty id is not forced into the holdout', () {
    expect(Holdout.isControl(''), isFalse);
  });

  test('about one in ten ids land in the control group', () {
    var controls = 0;
    for (var i = 0; i < 1000; i++) {
      if (Holdout.isControl('player-$i')) controls++;
    }
    expect(controls, inInclusiveRange(50, 150));
  });
}

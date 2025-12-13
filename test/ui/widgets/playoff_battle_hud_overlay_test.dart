import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flappy_jet_pro/ui/widgets/tournament/playoff_battle_wrapper.dart';
import 'package:flappy_jet_pro/ui/widgets/game/in_game_hearts_display.dart';

void main() {
  Widget _wrap(Widget child) {
    return MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(padding: EdgeInsets.only(top: 10)),
        child: Scaffold(body: child),
      ),
    );
  }

  testWidgets('shows story-style hearts in playoff HUD', (tester) async {
    await tester.pumpWidget(
      _wrap(
        PlayoffBattleHudOverlay(
          topPadding: 10,
          showObstacleCounter: true,
          obstacleCounter: const Text('score'),
          vsIndicator: const Text('VS'),
        ),
      ),
    );

    final heartsFinder = find.byType(InGameHeartsDisplay);
    expect(heartsFinder, findsOneWidget);
    final heartsWidget = tester.widget<InGameHeartsDisplay>(heartsFinder);
    expect(heartsWidget.showBackground, isFalse);
  });

  testWidgets('hides obstacle counter when disabled', (tester) async {
    await tester.pumpWidget(
      _wrap(
        PlayoffBattleHudOverlay(
          topPadding: 10,
          showObstacleCounter: false,
          obstacleCounter: const Text('score'),
          vsIndicator: const Text('VS'),
        ),
      ),
    );

    expect(find.text('score'), findsNothing);
    expect(find.text('VS'), findsOneWidget);
  });
}


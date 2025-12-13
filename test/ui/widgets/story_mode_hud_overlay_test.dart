import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flappy_jet_pro/ui/widgets/story_mode_game_wrapper.dart';
import 'package:flappy_jet_pro/ui/widgets/game/objective_indicator.dart';
import 'package:flappy_jet_pro/ui/widgets/game/unified_game_hud.dart';
import 'package:flappy_jet_pro/ui/widgets/game/vs_indicator.dart';
import 'package:flappy_jet_pro/game/systems/lives_manager.dart';
import 'package:flappy_jet_pro/models/level_data_schema.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LivesManager().forceResetToNewPlayer();
  });

  Widget _wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            child,
          ],
        ),
      ),
    );
  }

  testWidgets('beatBot shows VSIndicator and hides ObjectiveIndicator', (tester) async {
    await tester.pumpWidget(
      _wrap(
        StoryModeHudOverlay(
          objectiveType: ObjectiveType.beatBot,
          currentProgress: 2,
          targetProgress: 10,
          isCompleted: false,
          botScore: 3,
          botIsActive: true,
          botName: 'Bot Alpha',
          botSkinId: 'police_patrol',
        ),
      ),
    );

    expect(find.text('VS'), findsOneWidget);
    expect(find.text('Bot Alpha'), findsOneWidget);
    expect(find.byType(ScoreCounterHUD), findsOneWidget);
    // Score numbers should only come from ScoreCounterHUD, not inside VSIndicator
    final vs = find.byType(VSIndicator);
    expect(find.descendant(of: vs, matching: find.text('2')), findsNothing);
    expect(find.descendant(of: vs, matching: find.text('3')), findsNothing);
    // ObjectiveIndicator label "VS BATTLE" should not be present
    expect(find.text('VS BATTLE'), findsNothing);
  });

  testWidgets('non beatBot shows ObjectiveIndicator', (tester) async {
    await tester.pumpWidget(
      _wrap(
        StoryModeHudOverlay(
          objectiveType: ObjectiveType.passObstacles,
          currentProgress: 1,
          targetProgress: 5,
          isCompleted: false,
          botScore: null,
          botIsActive: true,
        ),
      ),
    );

    expect(find.text('VS BATTLE'), findsNothing);
    expect(find.byType(ObjectiveIndicator), findsOneWidget);
    expect(find.byType(ScoreCounterHUD), findsNothing);
  });
}


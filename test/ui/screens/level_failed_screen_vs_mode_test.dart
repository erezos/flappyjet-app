import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/models/level_data_schema.dart';
import 'package:flappy_jet_pro/ui/screens/level_failed_screen.dart';
import 'package:flappy_jet_pro/models/bonus_config.dart';

LevelData _vsLevel() {
  return LevelData(
    id: 5,
    zone: 1,
    name: 'Police Patrol Showdown',
    theme: LevelTheme(
      background: 'bg.png',
      obstacles: 'obs.png',
      music: 'music',
    ),
    difficulty: DifficultyConfig(
      speedMultiplier: 1.0,
      obstacleGap: 300,
      obstacleFrequency: 2.0,
      maxGapShift: 40,
    ),
    objective: LevelObjective(
      type: ObjectiveType.beatBot,
      target: 1,
      description: 'Beat the boss',
    ),
    botBattle: BotBattle(
      botName: 'Police Patrol',
      botJetSkin: 'police',
      skillLevel: 0.5,
      reactionTime: 0.3,
      mistakeRate: 0.2,
      minObstaclePass: 5,
    ),
    bonuses: BonusConfig.disabled,
    reward: const LevelReward(coins: 0, gems: 0),
  );
}

void main() {
  testWidgets('VS (beatBot) mode hides progress ring and percentage', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LevelFailedScreen(
            level: _vsLevel(),
            objectiveAchieved: 11,
            objectiveTarget: 20,
            continuesRemaining: 5,
          ),
        ),
      ),
    );

    // Progress ring should be hidden
    expect(find.byType(CircularProgressIndicator), findsNothing);
    // The "There!" / percentage text should be absent
    expect(find.textContaining('There!'), findsNothing);
    expect(find.textContaining('%'), findsNothing);
  });
}


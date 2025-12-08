import 'package:flappy_jet_pro/models/level_data_schema.dart';
import 'package:flappy_jet_pro/models/bonus_config.dart';
import 'package:flappy_jet_pro/ui/screens/level_failed_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

LevelData _dummyLevel() {
  return LevelData(
    id: 1,
    zone: 1,
    name: 'Dummy',
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
      description: 'Beat bot',
    ),
    reward: const LevelReward(coins: 0, gems: 0),
    botBattle: BotBattle(
      botName: 'Bot',
      botJetSkin: 'defender',
      skillLevel: 0.5,
      reactionTime: 0.3,
      mistakeRate: 0.2,
      minObstaclePass: 5,
    ),
    bonuses: BonusConfig.disabled,
  );
}

void main() {
  testWidgets('shows tournament stage and start over button', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LevelFailedScreen(
          level: _dummyLevel(),
          objectiveAchieved: 0,
          objectiveTarget: 1,
          isTournamentMode: true,
          tournamentStageName: 'Semi Finals',
          continuesRemaining: 2,
          tournamentEntryFee: 0,
          tournamentIsFreeRestart: true, // Free restart
          onStartOverOverride: () {},
        ),
      ),
    );

    expect(find.text('Semi Finals'), findsOneWidget);
    // ✅ Tournament mode: Button text is "START OVER" (restarts tournament)
    expect(find.text('START OVER'), findsOneWidget);
  });

  testWidgets('free restart shows simple START OVER button', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LevelFailedScreen(
          level: _dummyLevel(),
          objectiveAchieved: 0,
          objectiveTarget: 1,
          isTournamentMode: true,
          tournamentStageName: 'Quarter Finals',
          continuesRemaining: 0,
          tournamentEntryFee: 50,
          tournamentEntryType: 'gems',
          tournamentIsFreeRestart: true, // Free restart (has tries remaining)
          onStartOverOverride: () {},
        ),
      ),
    );

    // ✅ Free tournament restart: Button says "START OVER"
    expect(find.text('START OVER'), findsOneWidget);
  });

  testWidgets('paid restart shows discounted fee when no free tries', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LevelFailedScreen(
          level: _dummyLevel(),
          objectiveAchieved: 0,
          objectiveTarget: 1,
          isTournamentMode: true,
          tournamentStageName: 'Quarter Finals',
          continuesRemaining: 0,
          tournamentEntryFee: 100,
          tournamentEntryType: 'gems',
          tournamentIsFreeRestart: false, // NOT free - need to pay
          tournamentDiscountedFee: 50,
          tournamentDiscountPercent: 50,
          onStartOverOverride: () {},
        ),
      ),
    );

    // ✅ Paid restart: Button shows "START OVER" with original and discounted prices
    expect(find.text('START OVER'), findsOneWidget);
    // Original price should be crossed out
    expect(find.text('100 💎'), findsOneWidget);
    // Discounted price should be visible
    expect(find.text('50 💎'), findsOneWidget);
  });
}

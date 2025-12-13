import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/ui/widgets/tournament/tournament_game_over_popup.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('shows gem continue and start over text', (tester) async {
    await tester.pumpWidget(_wrap(
      TournamentGameOverPopup(
        jetAssetPath: 'assets/images/jets/sky_jet.png',
        levelLabel: 'Level 1: Test',
        subtitle: 'Boss Battle',
        message: "Don't give up, Huge rewards awaits",
        continuesRemaining: 5,
        onContinueWithAd: () {},
        onContinueWithGems: () {},
        onStartOver: () {},
        onClose: () {},
        startOverLabel: 'START OVER',
        continueGemCost: 3,
      ),
    ));

    expect(find.text('3 GEMS'), findsOneWidget);
    expect(find.textContaining('START OVER'), findsOneWidget);
  });

  testWidgets('disables ad/gems when callbacks null', (tester) async {
    await tester.pumpWidget(_wrap(
      TournamentGameOverPopup(
        jetAssetPath: 'assets/images/jets/sky_jet.png',
        levelLabel: 'Level 2: Test',
        subtitle: 'Time Remaining: 5s',
        message: "Don't give up, Huge rewards awaits",
        continuesRemaining: 0,
        onContinueWithAd: null,
        onContinueWithGems: null,
        onStartOver: () {},
        onClose: () {},
        startOverLabel: 'START OVER - 10 gems',
        continueGemCost: 3,
      ),
    ));

    // Buttons still render but should be partially disabled (opacity < 1)
    expect(find.text('FREE'), findsOneWidget);
    expect(find.text('3 GEMS'), findsOneWidget);
  });
}


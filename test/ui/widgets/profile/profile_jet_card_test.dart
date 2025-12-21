/// 🧪 Profile Jet Card Tests
/// 
/// Widget tests for ProfileJetCard component
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flappy_jet_pro/ui/widgets/profile/profile_jet_card.dart';
import 'package:flappy_jet_pro/game/core/jet_skins.dart';

void main() {
  group('ProfileJetCard', () {
    final testJet = JetSkin(
      id: 'test_jet',
      displayName: 'Test Jet',
      description: 'A test jet',
      assetPath: 'jets/test_jet.png',
      price: 100.0,
      rarity: JetRarity.common,
      isPurchased: false,
      isEquipped: false,
      category: JetSkinCategory.classic,
      tags: ['test'],
    );

    testWidgets('should display jet name', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileJetCard(
              jet: testJet,
              isOwned: true,
              isEquipped: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Test Jet'), findsOneWidget);
    });

    testWidgets('should show unlocked status for owned jet', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileJetCard(
              jet: testJet,
              isOwned: true,
              isEquipped: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Unlocked'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('should show locked status for unowned jet', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileJetCard(
              jet: testJet,
              isOwned: false,
              isEquipped: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Locked'), findsOneWidget);
      expect(find.byIcon(Icons.lock), findsWidgets);
    });

    testWidgets('should show equipped badge when equipped', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileJetCard(
              jet: testJet,
              isOwned: true,
              isEquipped: true,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('EQUIPPED'), findsOneWidget);
    });

    testWidgets('should call onTap when tapped', (WidgetTester tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileJetCard(
              jet: testJet,
              isOwned: true,
              isEquipped: false,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ProfileJetCard));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });
}


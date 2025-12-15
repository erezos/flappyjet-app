/// 🧪 Responsive tests for ModernGameButton widget
/// 
/// Verifies:
/// - No overflow errors at different screen sizes
/// - Button scales proportionally
/// - Touch targets meet accessibility standards
/// - Text scales appropriately
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/ui/widgets/buttons/modern_game_button.dart';
import 'package:flappy_jet_pro/ui/widgets/buttons/button_styles.dart';
import '../../../helpers/responsive_test_helper.dart';

void main() {
  group('ModernGameButton Responsive Design', () {
    testWidgets('No overflow errors at different screen sizes', (tester) async {
      ResponsiveTestHelper.testNoOverflow(
        widget: ModernGameButton(
          label: 'TEST BUTTON',
          onPressed: () {},
          style: ModernButtonStyle.primary,
        ),
      );
    });

    testWidgets('Button scales proportionally', (tester) async {
      const baseHeight = 56.0;
      
      ResponsiveTestHelper.testProportionalScaling(
        widget: ModernGameButton(
          label: 'TEST BUTTON',
          onPressed: () {},
          height: baseHeight,
          style: ModernButtonStyle.primary,
        ),
        finder: find.byType(ModernGameButton),
        propertyGetter: (box) => box.size.height,
        baseSize: baseHeight,
      );
    });

    testWidgets('Touch targets meet accessibility standards', (tester) async {
      ResponsiveTestHelper.testAccessibleTouchTargets(
        widget: ModernGameButton(
          label: 'TEST BUTTON',
          onPressed: () {},
          style: ModernButtonStyle.primary,
        ),
        buttonFinder: find.byType(ModernGameButton),
      );
    });

    testWidgets('Text scales appropriately', (tester) async {
      ResponsiveTestHelper.testTextScaling(
        widget: ModernGameButton(
          label: 'TEST BUTTON',
          onPressed: () {},
          style: ModernButtonStyle.primary,
        ),
        textFinder: find.text('TEST BUTTON'),
      );
    });

    testWidgets('Button with icon scales properly', (tester) async {
      ResponsiveTestHelper.testNoOverflow(
        widget: ModernGameButton(
          label: 'PLAY',
          iconAsset: 'assets/images/icons/icon_play.png',
          onPressed: () {},
          style: ModernButtonStyle.primary,
        ),
      );
    });
  });
}


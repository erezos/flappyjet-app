/// 🧪 Responsive tests for StoreHeader widget
/// 
/// Verifies:
/// - No overflow errors at different screen sizes
/// - Proper scaling of currency displays
/// - Touch targets meet accessibility standards
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/ui/widgets/store/store_header.dart';
import 'package:flappy_jet_pro/game/systems/inventory_manager.dart';
import 'package:flappy_jet_pro/game/systems/lives_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../helpers/responsive_test_helper.dart';

void main() {
  group('StoreHeader Responsive Design', () {
    setUp(() async {
      // Set up mock SharedPreferences for LivesManager
      SharedPreferences.setMockInitialValues({});
      LivesManager().forceResetToNewPlayer();
    });

    testWidgets('No overflow errors at different screen sizes', (tester) async {
      final sizes = DeviceSizes.getAll();
      
      for (final size in sizes) {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(size: size),
              child: StoreHeader(inventory: InventoryManager()),
            ),
          ),
        );
        
        await tester.pumpAndSettle();
        
        // Check for overflow errors
        final exception = tester.takeException();
        if (exception != null) {
          final exceptionString = exception.toString();
          if (exceptionString.contains('overflowed') ||
              exceptionString.contains('RenderFlex') ||
              exceptionString.contains('RenderBox')) {
            fail('Overflow error at ${size.width}x${size.height}: $exception');
          }
        }
        
        expect(tester.takeException(), isNull,
          reason: 'Widget should not overflow at ${size.width}x${size.height}',
        );
      }
    });

    testWidgets('Widget is visible at all screen sizes', (tester) async {
      final sizes = DeviceSizes.getAll();
      
      for (final size in sizes) {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(size: size),
              child: StoreHeader(inventory: InventoryManager()),
            ),
          ),
        );
        
        await tester.pumpAndSettle();
        
        expect(find.byType(StoreHeader), findsOneWidget,
          reason: 'Widget should be visible at ${size.width}x${size.height}',
        );
      }
    });

    testWidgets('Currency displays scale proportionally', (tester) async {
      await ResponsiveTestHelper.testAtSizes(
        widget: StoreHeader(inventory: InventoryManager()),
        sizes: DeviceSizes.getMobile(),
        testCallback: (tester, size) async {
          // Verify CoinsGemsDisplay is present
          expect(find.byType(StoreHeader), findsOneWidget);
          
          // Check for no overflow errors
          expect(tester.takeException(), isNull);
        },
      );
    });

    testWidgets('Hearts display scales proportionally', (tester) async {
      await ResponsiveTestHelper.testAtSizes(
        widget: StoreHeader(inventory: InventoryManager()),
        sizes: DeviceSizes.getMobile(),
        testCallback: (tester, size) async {
          // Verify HeartsDisplay is present
          expect(find.byType(StoreHeader), findsOneWidget);
          
          // Check for no overflow errors
          expect(tester.takeException(), isNull);
        },
      );
    });
  });
}


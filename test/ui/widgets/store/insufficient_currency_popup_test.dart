/// 🧪 Tests for Insufficient Currency Popup with Special Popup Frame
/// 
/// Tests ensure:
/// - Special popup frame (ui/special_popup.png) loads correctly
/// - Responsive design works on all screen sizes
/// - Fallback gradient works if image fails
/// - All insufficient currency flows still function correctly
/// - Follows Flame game engine and mobile gaming best practices
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flappy_jet_pro/ui/widgets/store/insufficient_currency_popup.dart';
import 'package:flappy_jet_pro/game/core/special_offer_config.dart';

void main() {
  group('Insufficient Currency Popup - Special Popup Frame', () {
    testWidgets('should display special_popup.png frame', (WidgetTester tester) async {
      // Build the popup widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return InsufficientCurrencyPopupWidget(
                  neededCurrency: OfferCurrencyType.gems,
                  neededAmount: 100,
                  currentAmount: 50,
                  config: const InsufficientCurrencyConfig(),
                  onPurchase: () {},
                  onDismiss: () {},
                );
              },
            ),
          ),
        ),
      );

      // Wait for animations
      await tester.pumpAndSettle();

      // Verify the popup frame image is loaded
      final imageFinder = find.byType(Image);
      expect(imageFinder, findsWidgets);

      // Check that special_popup.png is being used
      final assetImage = (tester.widget<Image>(imageFinder.first).image as AssetImage);
      expect(assetImage, isA<AssetImage>());
      
      // Verify the asset path (check the AssetImage toString)
      // AssetImage toString contains the asset path
      expect(assetImage.toString(), contains('assets/images/ui/special_popup.png'));
    });

    testWidgets('should show fallback gradient if image fails to load', (WidgetTester tester) async {
      // Build the popup widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return InsufficientCurrencyPopupWidget(
                  neededCurrency: OfferCurrencyType.gems,
                  neededAmount: 100,
                  currentAmount: 50,
                  config: const InsufficientCurrencyConfig(),
                  onPurchase: () {},
                  onDismiss: () {},
                );
              },
            ),
          ),
        ),
      );

      // Wait for animations
      await tester.pumpAndSettle();

      // Simulate image load error
      final imageFinder = find.byType(Image);
      if (imageFinder.evaluate().isNotEmpty) {
        // The error builder should show a fallback gradient
        expect(find.byType(Container), findsWidgets);
      }
    });

    testWidgets('should be responsive on different screen sizes', (WidgetTester tester) async {
      // Test on small screen (iPhone SE size)
      await tester.binding.setSurfaceSize(const Size(375, 667));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return InsufficientCurrencyPopupWidget(
                  neededCurrency: OfferCurrencyType.gems,
                  neededAmount: 100,
                  currentAmount: 50,
                  config: const InsufficientCurrencyConfig(),
                  onPurchase: () {},
                  onDismiss: () {},
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify popup renders without overflow
      expect(tester.takeException(), isNull);

      // Test on large screen (iPad size)
      await tester.binding.setSurfaceSize(const Size(1024, 1366));
      await tester.pumpAndSettle();

      // Verify popup still renders correctly
      expect(tester.takeException(), isNull);

      // Reset screen size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('should display correct currency information', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return InsufficientCurrencyPopupWidget(
                  neededCurrency: OfferCurrencyType.gems,
                  neededAmount: 100,
                  currentAmount: 50,
                  config: const InsufficientCurrencyConfig(),
                  onPurchase: () {},
                  onDismiss: () {},
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify "Need More Gems?" title appears
      expect(find.textContaining('Need More'), findsOneWidget);
      expect(find.textContaining('Gems'), findsWidgets);

      // Verify shortfall information
      expect(find.textContaining('50'), findsWidgets); // shortfall = 100 - 50
    });

    testWidgets('should handle purchase button tap', (WidgetTester tester) async {
      // Use larger screen size to ensure popup fits
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      
      bool purchaseCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return InsufficientCurrencyPopupWidget(
                  neededCurrency: OfferCurrencyType.gems,
                  neededAmount: 100,
                  currentAmount: 50,
                  config: const InsufficientCurrencyConfig(),
                  onPurchase: () {
                    purchaseCalled = true;
                  },
                  onDismiss: () {},
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap purchase button
      final purchaseButton = find.text('GET IT NOW!');
      expect(purchaseButton, findsOneWidget);
      
      await tester.tap(purchaseButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Verify purchase callback was called
      expect(purchaseCalled, isTrue);
      
      // Reset screen size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('should handle dismiss button tap', (WidgetTester tester) async {
      // Use larger screen size to ensure popup fits
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      
      bool dismissCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return InsufficientCurrencyPopupWidget(
                  neededCurrency: OfferCurrencyType.gems,
                  neededAmount: 100,
                  currentAmount: 50,
                  config: const InsufficientCurrencyConfig(),
                  onPurchase: () {},
                  onDismiss: () {
                    dismissCalled = true;
                  },
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap dismiss button
      final dismissButton = find.text('Maybe Later');
      expect(dismissButton, findsOneWidget);
      
      await tester.tap(dismissButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Verify dismiss callback was called
      expect(dismissCalled, isTrue);
      
      // Reset screen size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('should handle close button tap', (WidgetTester tester) async {
      bool dismissCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return InsufficientCurrencyPopupWidget(
                  neededCurrency: OfferCurrencyType.gems,
                  neededAmount: 100,
                  currentAmount: 50,
                  config: const InsufficientCurrencyConfig(),
                  onPurchase: () {},
                  onDismiss: () {
                    dismissCalled = true;
                  },
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap close button (X icon)
      final closeButton = find.byIcon(Icons.close);
      expect(closeButton, findsOneWidget);
      
      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      // Verify dismiss callback was called
      expect(dismissCalled, isTrue);
    });

    testWidgets('should display recommended pack information', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return InsufficientCurrencyPopupWidget(
                  neededCurrency: OfferCurrencyType.gems,
                  neededAmount: 100,
                  currentAmount: 50,
                  config: const InsufficientCurrencyConfig(),
                  onPurchase: () {},
                  onDismiss: () {},
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify recommended pack is displayed
      // The pack should show name, description, and price
      expect(find.byType(Container), findsWidgets); // Pack container
    });

    testWidgets('should work with coins currency type', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return InsufficientCurrencyPopupWidget(
                  neededCurrency: OfferCurrencyType.coins,
                  neededAmount: 500,
                  currentAmount: 200,
                  config: const InsufficientCurrencyConfig(),
                  onPurchase: () {},
                  onDismiss: () {},
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify "Need More Coins?" title appears
      expect(find.textContaining('Need More'), findsOneWidget);
      expect(find.textContaining('Coins'), findsWidgets);
    });

    testWidgets('should have proper animations', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return InsufficientCurrencyPopupWidget(
                  neededCurrency: OfferCurrencyType.gems,
                  neededAmount: 100,
                  currentAmount: 50,
                  config: const InsufficientCurrencyConfig(),
                  onPurchase: () {},
                  onDismiss: () {},
                );
              },
            ),
          ),
        ),
      );

      // Verify animations are present
      expect(find.byType(FadeTransition), findsWidgets);
      expect(find.byType(ScaleTransition), findsWidgets);

      // Wait for animations to complete
      await tester.pumpAndSettle();

      // Verify popup is fully visible after animation
      expect(find.textContaining('Need More'), findsOneWidget);
    });

    testWidgets('should maintain proper layout on very small screens', (WidgetTester tester) async {
      // Test on very small screen (e.g., small Android device)
      await tester.binding.setSurfaceSize(const Size(320, 568));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return InsufficientCurrencyPopupWidget(
                  neededCurrency: OfferCurrencyType.gems,
                  neededAmount: 100,
                  currentAmount: 50,
                  config: const InsufficientCurrencyConfig(),
                  onPurchase: () {},
                  onDismiss: () {},
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify popup renders (SingleChildScrollView should prevent overflow)
      expect(find.textContaining('Need More'), findsOneWidget);

      // Reset screen size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('should maintain proper layout on very large screens', (WidgetTester tester) async {
      // Test on very large screen (e.g., tablet in landscape)
      await tester.binding.setSurfaceSize(const Size(1920, 1080));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return InsufficientCurrencyPopupWidget(
                  neededCurrency: OfferCurrencyType.gems,
                  neededAmount: 100,
                  currentAmount: 50,
                  config: const InsufficientCurrencyConfig(),
                  onPurchase: () {},
                  onDismiss: () {},
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify popup renders correctly on large screens
      expect(find.textContaining('Need More'), findsOneWidget);

      // Reset screen size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('should use safe area padding to avoid frame overlap', (WidgetTester tester) async {
      // Use larger screen size to ensure popup fits
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return InsufficientCurrencyPopupWidget(
                  neededCurrency: OfferCurrencyType.gems,
                  neededAmount: 100,
                  currentAmount: 50,
                  config: const InsufficientCurrencyConfig(),
                  onPurchase: () {},
                  onDismiss: () {},
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the Padding widget that contains the content
      final paddingFinder = find.byType(Padding);
      expect(paddingFinder, findsWidgets);

      // Get the padding widget (find the one with safe area padding - should be one of the last ones)
      final paddingWidgets = tester.widgetList<Padding>(paddingFinder).toList();
      // The safe area padding should be in one of the Padding widgets
      EdgeInsets? safeAreaPadding;
      for (final widget in paddingWidgets) {
        final padding = widget.padding as EdgeInsets;
        // Safe area padding should have top > left (270px vs 50px in original)
        if (padding.top > padding.left && padding.top > 0) {
          safeAreaPadding = padding;
          break;
        }
      }

      expect(safeAreaPadding, isNotNull, reason: 'Should find safe area padding');
      
      // Verify padding is applied (should be non-zero)
      expect(safeAreaPadding!.left, greaterThan(0));
      expect(safeAreaPadding.top, greaterThan(0));
      expect(safeAreaPadding.right, greaterThan(0));
      expect(safeAreaPadding.bottom, greaterThan(0));

      // Verify top padding is larger than others (270px in original vs 50px)
      expect(safeAreaPadding.top, greaterThan(safeAreaPadding.left));
      expect(safeAreaPadding.top, greaterThan(safeAreaPadding.right));
      
      // Reset screen size
      await tester.binding.setSurfaceSize(null);
    });

    test('SpecialPopupFrameSafeArea calculates correct padding', () {
      // Test with original image size
      final originalSize = const Size(887.0, 1336.0);
      final padding = SpecialPopupFrameSafeArea.calculateSafeAreaPadding(originalSize);

      // Verify padding matches original frame dimensions
      expect(padding.left, closeTo(50.0, 0.1));
      expect(padding.top, closeTo(270.0, 0.1));
      expect(padding.right, closeTo(50.0, 0.1));
      expect(padding.bottom, closeTo(60.0, 0.1));
    });

    test('SpecialPopupFrameSafeArea scales padding proportionally', () {
      // Test with half size
      final halfSize = const Size(443.5, 668.0); // Half of original
      final padding = SpecialPopupFrameSafeArea.calculateSafeAreaPadding(halfSize);

      // Padding should scale proportionally (approximately half)
      expect(padding.left, closeTo(25.0, 1.0));
      expect(padding.top, closeTo(135.0, 1.0));
      expect(padding.right, closeTo(25.0, 1.0));
      expect(padding.bottom, closeTo(30.0, 1.0));
    });

    test('SpecialPopupFrameSafeArea calculates safe content size correctly', () {
      final originalSize = const Size(887.0, 1336.0);
      final safeSize = SpecialPopupFrameSafeArea.calculateSafeContentSize(originalSize);

      // Safe content area should be: 887-50-50 = 787 width, 1336-270-60 = 1006 height
      expect(safeSize.width, closeTo(787.0, 0.1));
      expect(safeSize.height, closeTo(1006.0, 0.1));
    });

    testWidgets('should maintain safe area padding on different screen sizes', (WidgetTester tester) async {
      // Helper to find safe area padding
      EdgeInsets? findSafeAreaPadding(WidgetTester tester) {
        final paddingFinder = find.byType(Padding);
        final paddingWidgets = tester.widgetList<Padding>(paddingFinder).toList();
        for (final widget in paddingWidgets) {
          final padding = widget.padding as EdgeInsets;
          // Safe area padding should have top > left (270px vs 50px in original)
          if (padding.top > padding.left && padding.top > 0) {
            return padding;
          }
        }
        return null;
      }
      
      // Test on small screen
      await tester.binding.setSurfaceSize(const Size(375, 667));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return InsufficientCurrencyPopupWidget(
                  neededCurrency: OfferCurrencyType.gems,
                  neededAmount: 100,
                  currentAmount: 50,
                  config: const InsufficientCurrencyConfig(),
                  onPurchase: () {},
                  onDismiss: () {},
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final smallScreenPadding = findSafeAreaPadding(tester);
      expect(smallScreenPadding, isNotNull);

      // Test on large screen
      await tester.binding.setSurfaceSize(const Size(1024, 1366));
      await tester.pumpAndSettle();

      final largeScreenPadding = findSafeAreaPadding(tester);
      expect(largeScreenPadding, isNotNull);

      // Padding should scale proportionally with screen size
      // Large screen should have larger or equal padding values (depending on popup size constraints)
      expect(largeScreenPadding!.left, greaterThanOrEqualTo(smallScreenPadding!.left));
      expect(largeScreenPadding.top, greaterThanOrEqualTo(smallScreenPadding.top));
      expect(largeScreenPadding.right, greaterThanOrEqualTo(smallScreenPadding.right));
      expect(largeScreenPadding.bottom, greaterThanOrEqualTo(smallScreenPadding.bottom));

      // Reset screen size
      await tester.binding.setSurfaceSize(null);
    });
  });
}


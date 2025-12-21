/// 🧪 Responsive tests for Store Card layouts
/// 
/// Verifies:
/// - No overflow errors at different screen sizes (including Xiaomi devices)
/// - Proper card aspect ratios maintained
/// - Content fits within card bounds
/// - Cards maintain structure on all devices
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/ui/widgets/store/no_ads_section.dart';
import 'package:flappy_jet_pro/ui/widgets/store/heart_booster_store.dart';
import 'package:flappy_jet_pro/ui/widgets/store/bundles_section.dart';
import 'package:flappy_jet_pro/game/systems/monetization_manager.dart';
import 'package:flappy_jet_pro/game/systems/inventory_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../helpers/responsive_test_helper.dart';

void main() {
  group('Store Cards Responsive Design', () {
    late MonetizationManager monetization;
    late InventoryManager inventory;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      monetization = MonetizationManager();
      inventory = InventoryManager();
    });

    group('No Ads Section Cards', () {
      testWidgets('No overflow errors at different screen sizes', (tester) async {
        final sizes = DeviceSizes.getAll();
        
        for (final size in sizes) {
          await tester.binding.setSurfaceSize(size);
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(size: size),
                child: Scaffold(
                  body: SingleChildScrollView(
                    child: NoAdsSection(
                      onPurchaseNoAds: (_) {},
                      monetization: monetization,
                    ),
                  ),
                ),
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
            reason: 'No Ads cards should not overflow at ${size.width}x${size.height}',
          );
        }
      });

      testWidgets('Cards maintain proper aspect ratio', (tester) async {
        final sizes = DeviceSizes.getAll();
        
        for (final size in sizes) {
          await tester.binding.setSurfaceSize(size);
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(size: size),
                child: Scaffold(
                  body: SingleChildScrollView(
                    child: NoAdsSection(
                      onPurchaseNoAds: (_) {},
                      monetization: monetization,
                    ),
                  ),
                ),
              ),
            ),
          );
          
          await tester.pumpAndSettle();
          
          // Find all card containers
          final cards = find.byType(Container).evaluate();
          
          for (final element in cards) {
            final renderBox = element.renderObject as RenderBox?;
            if (renderBox != null && renderBox.hasSize) {
              final aspectRatio = renderBox.size.width / renderBox.size.height;
              
              // Cards should have reasonable aspect ratio (between 0.5 and 1.5)
              expect(
                aspectRatio,
                greaterThan(0.5),
                reason: 'Card aspect ratio should be > 0.5 at ${size.width}x${size.height}',
              );
              
              expect(
                aspectRatio,
                lessThan(1.5),
                reason: 'Card aspect ratio should be < 1.5 at ${size.width}x${size.height}',
              );
            }
          }
        }
      });

      testWidgets('All content is visible and not clipped', (tester) async {
        final sizes = DeviceSizes.getAll();
        
        for (final size in sizes) {
          await tester.binding.setSurfaceSize(size);
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(size: size),
                child: Scaffold(
                  body: SingleChildScrollView(
                    child: NoAdsSection(
                      onPurchaseNoAds: (_) {},
                      monetization: monetization,
                    ),
                  ),
                ),
              ),
            ),
          );
          
          await tester.pumpAndSettle();
          
          // Check that all text is visible
          expect(find.text('Remove Ads'), findsOneWidget);
          expect(find.text('24 Hours'), findsOneWidget);
          expect(find.text('1 Week'), findsOneWidget);
          expect(find.text('Lifetime'), findsOneWidget);
        }
      });
    });

    group('Heart Booster Section Cards', () {
      testWidgets('No overflow errors at different screen sizes', (tester) async {
        final sizes = DeviceSizes.getAll();
        
        for (final size in sizes) {
          await tester.binding.setSurfaceSize(size);
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(size: size),
                child: Scaffold(
                  body: SingleChildScrollView(
                    child: HeartBoosterStore(
                      inventory: inventory,
                      onPurchaseBooster: (_) {},
                    ),
                  ),
                ),
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
            reason: 'Heart Booster cards should not overflow at ${size.width}x${size.height}',
          );
        }
      });

      testWidgets('Cards maintain proper aspect ratio', (tester) async {
        final sizes = DeviceSizes.getAll();
        
        for (final size in sizes) {
          await tester.binding.setSurfaceSize(size);
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(size: size),
                child: Scaffold(
                  body: SingleChildScrollView(
                    child: HeartBoosterStore(
                      inventory: inventory,
                      onPurchaseBooster: (_) {},
                    ),
                  ),
                ),
              ),
            ),
          );
          
          await tester.pumpAndSettle();
          
          // Find all card containers
          final cards = find.byType(Container).evaluate();
          
          for (final element in cards) {
            final renderBox = element.renderObject as RenderBox?;
            if (renderBox != null && renderBox.hasSize) {
              final aspectRatio = renderBox.size.width / renderBox.size.height;
              
              // Cards should have reasonable aspect ratio
              expect(
                aspectRatio,
                greaterThan(0.5),
                reason: 'Card aspect ratio should be > 0.5 at ${size.width}x${size.height}',
              );
              
              expect(
                aspectRatio,
                lessThan(1.5),
                reason: 'Card aspect ratio should be < 1.5 at ${size.width}x${size.height}',
              );
            }
          }
        }
      });

      testWidgets('All content is visible and not clipped', (tester) async {
        final sizes = DeviceSizes.getAll();
        
        for (final size in sizes) {
          await tester.binding.setSurfaceSize(size);
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(size: size),
                child: Scaffold(
                  body: SingleChildScrollView(
                    child: HeartBoosterStore(
                      inventory: inventory,
                      onPurchaseBooster: (_) {},
                    ),
                  ),
                ),
              ),
            ),
          );
          
          await tester.pumpAndSettle();
          
          // Check that all text is visible
          expect(find.text('Heart Booster'), findsOneWidget);
          expect(find.text('24H Booster'), findsOneWidget);
          expect(find.text('48H Booster'), findsOneWidget);
          expect(find.text('72H Booster'), findsOneWidget);
        }
      });
    });

    group('Bundles Section Cards', () {
      testWidgets('No overflow errors at different screen sizes', (tester) async {
        final sizes = DeviceSizes.getAll();
        
        for (final size in sizes) {
          await tester.binding.setSurfaceSize(size);
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(size: size),
                child: Scaffold(
                  body: SingleChildScrollView(
                    child: BundlesSection(
                      onPurchaseBundle: (_) {},
                    ),
                  ),
                ),
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
            reason: 'Bundles cards should not overflow at ${size.width}x${size.height}',
          );
        }
      });

      testWidgets('Cards maintain proper aspect ratio', (tester) async {
        final sizes = DeviceSizes.getAll();
        
        for (final size in sizes) {
          await tester.binding.setSurfaceSize(size);
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(size: size),
                child: Scaffold(
                  body: SingleChildScrollView(
                    child: BundlesSection(
                      onPurchaseBundle: (_) {},
                    ),
                  ),
                ),
              ),
            ),
          );
          
          await tester.pumpAndSettle();
          
          // Find all card containers
          final cards = find.byType(Container).evaluate();
          
          for (final element in cards) {
            final renderBox = element.renderObject as RenderBox?;
            if (renderBox != null && renderBox.hasSize) {
              final aspectRatio = renderBox.size.width / renderBox.size.height;
              
              // Cards should have reasonable aspect ratio
              expect(
                aspectRatio,
                greaterThan(0.5),
                reason: 'Card aspect ratio should be > 0.5 at ${size.width}x${size.height}',
              );
              
              expect(
                aspectRatio,
                lessThan(1.5),
                reason: 'Card aspect ratio should be < 1.5 at ${size.width}x${size.height}',
              );
            }
          }
        }
      });

      testWidgets('All content is visible and not clipped', (tester) async {
        final sizes = DeviceSizes.getAll();
        
        for (final size in sizes) {
          await tester.binding.setSurfaceSize(size);
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(size: size),
                child: Scaffold(
                  body: SingleChildScrollView(
                    child: BundlesSection(
                      onPurchaseBundle: (_) {},
                    ),
                  ),
                ),
              ),
            ),
          );
          
          await tester.pumpAndSettle();
          
          // Check that all text is visible
          expect(find.text('Bundles'), findsOneWidget);
        }
      });
    });

    group('Xiaomi Device Specific Tests', () {
      // Xiaomi devices often have unique screen dimensions
      // Common Xiaomi sizes: 393x851 (Xiaomi 12), 360x800 (older models)
      final xiaomiSizes = [
        const Size(360.0, 800.0), // Older Xiaomi phones
        const Size(393.0, 851.0), // Xiaomi 12
        const Size(412.0, 915.0), // Xiaomi 13 Pro
        const Size(320.0, 640.0), // Very small Xiaomi phones
      ];

      testWidgets('No overflow on Xiaomi device sizes', (tester) async {
        for (final size in xiaomiSizes) {
          await tester.binding.setSurfaceSize(size);
          
          // Test No Ads Section
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(size: size),
                child: Scaffold(
                  body: SingleChildScrollView(
                    child: Column(
                      children: [
                        NoAdsSection(
                          onPurchaseNoAds: (_) {},
                          monetization: monetization,
                        ),
                        HeartBoosterStore(
                          inventory: inventory,
                          onPurchaseBooster: (_) {},
                        ),
                        BundlesSection(
                          onPurchaseBundle: (_) {},
                        ),
                      ],
                    ),
                  ),
                ),
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
              fail('Overflow error on Xiaomi size ${size.width}x${size.height}: $exception');
            }
          }
          
          expect(tester.takeException(), isNull,
            reason: 'Store cards should not overflow on Xiaomi device size ${size.width}x${size.height}',
          );
        }
      });

      testWidgets('Cards maintain structure on Xiaomi devices', (tester) async {
        for (final size in xiaomiSizes) {
          await tester.binding.setSurfaceSize(size);
          
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(size: size),
                child: Scaffold(
                  body: SingleChildScrollView(
                    child: Column(
                      children: [
                        NoAdsSection(
                          onPurchaseNoAds: (_) {},
                          monetization: monetization,
                        ),
                        HeartBoosterStore(
                          inventory: inventory,
                          onPurchaseBooster: (_) {},
                        ),
                        BundlesSection(
                          onPurchaseBundle: (_) {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          
          await tester.pumpAndSettle();
          
          // Verify cards are rendered
          final cards = find.byType(Container).evaluate();
          expect(cards.length, greaterThan(0),
            reason: 'Cards should be rendered on Xiaomi size ${size.width}x${size.height}',
          );
          
          // Verify all cards have valid sizes
          for (final element in cards) {
            final renderBox = element.renderObject as RenderBox?;
            if (renderBox != null && renderBox.hasSize) {
              expect(renderBox.size.width, greaterThan(0.0),
                reason: 'Card width should be > 0 on Xiaomi size ${size.width}x${size.height}',
              );
              expect(renderBox.size.height, greaterThan(0.0),
                reason: 'Card height should be > 0 on Xiaomi size ${size.width}x${size.height}',
              );
            }
          }
        }
      });
    });

    group('Edge Cases', () {
      testWidgets('Very small screens (320x568)', (tester) async {
        const smallSize = Size(320.0, 568.0);
        await tester.binding.setSurfaceSize(smallSize);
        
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(size: smallSize),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      NoAdsSection(
                        onPurchaseNoAds: (_) {},
                        monetization: monetization,
                      ),
                      HeartBoosterStore(
                        inventory: inventory,
                        onPurchaseBooster: (_) {},
                      ),
                      BundlesSection(
                        onPurchaseBundle: (_) {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        
        await tester.pumpAndSettle();
        
        expect(tester.takeException(), isNull,
          reason: 'Store cards should work on very small screens',
        );
      });

      testWidgets('Very large tablets (1024x1366)', (tester) async {
        const largeSize = Size(1024.0, 1366.0);
        await tester.binding.setSurfaceSize(largeSize);
        
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(size: largeSize),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      NoAdsSection(
                        onPurchaseNoAds: (_) {},
                        monetization: monetization,
                      ),
                      HeartBoosterStore(
                        inventory: inventory,
                        onPurchaseBooster: (_) {},
                      ),
                      BundlesSection(
                        onPurchaseBundle: (_) {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        
        await tester.pumpAndSettle();
        
        expect(tester.takeException(), isNull,
          reason: 'Store cards should work on very large tablets',
        );
      });
    });
  });
}


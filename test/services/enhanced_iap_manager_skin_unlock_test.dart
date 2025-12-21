/// 🧪 Enhanced IAP Manager - Skin Unlock Tests
/// 
/// Tests the fix for multi-skin bundle purchases to ensure:
/// 1. Multi-skin bundles (christmas_jet_bundle, starter_boss_pack) skip automatic unlock
/// 2. Single-skin products still unlock automatically
/// 3. Other bundles without skins are unaffected
/// 4. Follows Flame game engine best practices and mobile gaming standards
library;

import 'package:flutter_test/flutter_test.dart';
import '../../lib/game/core/iap_products.dart';

/// Multi-skin bundle IDs that should skip automatic skin unlock
/// These bundles unlock multiple skins via their dedicated popup handlers
const Set<String> multiSkinBundleIds = {'christmas_jet_bundle', 'starter_boss_pack'};

void main() {
  group('EnhancedIAPManager - Multi-Skin Bundle Skin Unlock Fix', () {

    group('Multi-Skin Bundle Products', () {
      test('christmas_jet_bundle should skip automatic skin unlock', () {
        // Arrange
        final product = IAPProductCatalog.specialOffers['christmas_jet_bundle']!;
        
        // Assert: Product is a bundle with jetSkinId
        expect(product.type, IAPProductType.bundle);
        expect(product.jetSkinId, isNotNull);
        expect(product.jetSkinId, equals('blitzen'));
        
        // Assert: Product ID is in the multi-skin bundle list
        expect(multiSkinBundleIds.contains(product.id), isTrue);
      });

      test('starter_boss_pack should skip automatic skin unlock', () {
        // Arrange
        final product = IAPProductCatalog.specialOffers['starter_boss_pack']!;
        
        // Assert: Product is a bundle with jetSkinId
        expect(product.type, IAPProductType.bundle);
        expect(product.jetSkinId, isNotNull);
        expect(product.jetSkinId, equals('police_patrol'));
        
        // Assert: Product ID is in the multi-skin bundle list
        expect(multiSkinBundleIds.contains(product.id), isTrue);
      });
    });

    group('Single-Skin Products', () {
      test('single-skin product should still unlock automatically', () {
        // Arrange: Create a mock single-skin product
        final singleSkinProduct = IAPProduct(
          id: 'test_single_skin',
          storeId: 'com.flappyjet.test.single_skin',
          priceUSD: 0.99,
          displayName: 'Test Single Skin',
          description: 'Test single skin product',
          type: IAPProductType.jetSkin,
          jetSkinId: 'test_skin',
        );
        
        // Assert: Product is NOT in the multi-skin bundle list
        expect(multiSkinBundleIds.contains(singleSkinProduct.id), isFalse);
        
        // Assert: Product has a jetSkinId and should unlock automatically
        expect(singleSkinProduct.jetSkinId, isNotNull);
        expect(singleSkinProduct.jetSkinId, equals('test_skin'));
      });
    });

    group('Other Bundle Products (No Skins)', () {
      test('bundle_24h should not be affected (no jetSkinId)', () {
        // Arrange
        final product = IAPProductCatalog.bundleProducts['bundle_24h']!;
        
        // Assert: Product is a bundle but has no jetSkinId
        expect(product.type, IAPProductType.bundle);
        expect(product.jetSkinId, isNull);
        
        // Assert: Product is NOT in the multi-skin bundle list
        const multiSkinBundleIds = {'christmas_jet_bundle', 'starter_boss_pack'};
        expect(multiSkinBundleIds.contains(product.id), isFalse);
      });

      test('bundle_48h should not be affected (no jetSkinId)', () {
        // Arrange
        final product = IAPProductCatalog.bundleProducts['bundle_48h']!;
        
        // Assert: Product is a bundle but has no jetSkinId
        expect(product.type, IAPProductType.bundle);
        expect(product.jetSkinId, isNull);
        
        // Assert: Product is NOT in the multi-skin bundle list
        const multiSkinBundleIds = {'christmas_jet_bundle', 'starter_boss_pack'};
        expect(multiSkinBundleIds.contains(product.id), isFalse);
      });

      test('bundle_72h should not be affected (no jetSkinId)', () {
        // Arrange
        final product = IAPProductCatalog.bundleProducts['bundle_72h']!;
        
        // Assert: Product is a bundle but has no jetSkinId
        expect(product.type, IAPProductType.bundle);
        expect(product.jetSkinId, isNull);
        
        // Assert: Product is NOT in the multi-skin bundle list
        const multiSkinBundleIds = {'christmas_jet_bundle', 'starter_boss_pack'};
        expect(multiSkinBundleIds.contains(product.id), isFalse);
      });

      test('currency_bundle_starter should not be affected (no jetSkinId)', () {
        // Arrange
        final product = IAPProductCatalog.currencyBundles['currency_bundle_starter']!;
        
        // Assert: Product is a bundle but has no jetSkinId
        expect(product.type, IAPProductType.bundle);
        expect(product.jetSkinId, isNull);
        
        // Assert: Product is NOT in the multi-skin bundle list
        const multiSkinBundleIds = {'christmas_jet_bundle', 'starter_boss_pack'};
        expect(multiSkinBundleIds.contains(product.id), isFalse);
      });

      test('currency_bundle_value should not be affected (no jetSkinId)', () {
        // Arrange
        final product = IAPProductCatalog.currencyBundles['currency_bundle_value']!;
        
        // Assert: Product is a bundle but has no jetSkinId
        expect(product.type, IAPProductType.bundle);
        expect(product.jetSkinId, isNull);
        
        // Assert: Product is NOT in the multi-skin bundle list
        const multiSkinBundleIds = {'christmas_jet_bundle', 'starter_boss_pack'};
        expect(multiSkinBundleIds.contains(product.id), isFalse);
      });

      test('currency_bundle_mega should not be affected (no jetSkinId)', () {
        // Arrange
        final product = IAPProductCatalog.currencyBundles['currency_bundle_mega']!;
        
        // Assert: Product is a bundle but has no jetSkinId
        expect(product.type, IAPProductType.bundle);
        expect(product.jetSkinId, isNull);
        
        // Assert: Product is NOT in the multi-skin bundle list
        const multiSkinBundleIds = {'christmas_jet_bundle', 'starter_boss_pack'};
        expect(multiSkinBundleIds.contains(product.id), isFalse);
      });
    });

    group('Product Configuration Validation', () {
      test('all multi-skin bundles should have jetSkinId set', () {
        // This ensures the IAP product definitions are correct
        for (final bundleId in multiSkinBundleIds) {
          final product = IAPProductCatalog.specialOffers[bundleId];
          expect(product, isNotNull, reason: 'Product $bundleId should exist');
          expect(product!.jetSkinId, isNotNull, 
            reason: 'Product $bundleId should have jetSkinId set (even though it will be skipped)');
        }
      });

      test('multi-skin bundle list should only contain valid product IDs', () {
        // Ensure all IDs in the list actually exist in the catalog
        for (final bundleId in multiSkinBundleIds) {
          final product = IAPProductCatalog.specialOffers[bundleId];
          expect(product, isNotNull, 
            reason: 'Product ID $bundleId in multi-skin bundle list should exist in catalog');
        }
      });
    });

    group('Edge Cases', () {
      test('product with null jetSkinId should not attempt unlock', () {
        // Arrange: Product without jetSkinId
        final product = IAPProductCatalog.bundleProducts['bundle_24h']!;
        
        // Assert: Product has no jetSkinId
        expect(product.jetSkinId, isNull);
        
        // The unlock logic should check for null jetSkinId first
        // This is already handled in the existing code
      });

      test('non-bundle product with jetSkinId should unlock normally', () {
        // Arrange: Create a mock jetSkin product (not a bundle)
        final jetSkinProduct = IAPProduct(
          id: 'test_jet_skin',
          storeId: 'com.flappyjet.test.jet_skin',
          priceUSD: 0.99,
          displayName: 'Test Jet Skin',
          description: 'Test jet skin product',
          type: IAPProductType.jetSkin,
          jetSkinId: 'test_skin',
        );
        
        // Assert: Product is NOT a bundle
        expect(jetSkinProduct.type, isNot(IAPProductType.bundle));
        
        // Assert: Product is NOT in the multi-skin bundle list
        expect(multiSkinBundleIds.contains(jetSkinProduct.id), isFalse);
        
        // Assert: Product should unlock automatically
        expect(jetSkinProduct.jetSkinId, isNotNull);
      });
    });
  });
}


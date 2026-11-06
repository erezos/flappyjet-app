import '../../../game/core/iap_products.dart';
import '../../../services/enhanced_iap_manager.dart';

/// Store-localized price, falling back to the catalog USD amount.
class StorePrice {
  static String forProduct(String productId, double fallbackUsd) {
    final details = EnhancedIAPManager().getProductDetails(productId);
    final price = details?.price;
    if (price != null && price.isNotEmpty) return price;
    return '\$${fallbackUsd.toStringAsFixed(2)}';
  }

  static String forIap(IAPProduct product) => forProduct(product.id, product.priceUSD);
}

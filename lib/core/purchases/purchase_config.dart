/// Google Play in-app product IDs for the 5 coin packages on
/// `GetCoinsScreen`. **Placeholder** — this app has no Play Console
/// listing yet, so none of these exist as real products (a store
/// query for them will find nothing until then). Once the app is
/// uploaded and its in-app products are created, either use these
/// exact IDs when creating them, or update these constants to match
/// whatever IDs were actually used — the two must match exactly, or
/// `PurchaseRepository.queryProducts` silently returns nothing for the
/// mismatched ones and the row falls back to its static preview price.
class PurchaseConfig {
  const PurchaseConfig._();

  static const String coins500 = 'coins_500';
  static const String coins1200 = 'coins_1200';
  static const String coins2500 = 'coins_2500';
  static const String coins6000 = 'coins_6000';
  static const String coins15000 = 'coins_15000';

  static const List<String> allProductIds = [
    coins500,
    coins1200,
    coins2500,
    coins6000,
    coins15000,
  ];

  /// Coins granted per product ID — a completed purchase only tells us
  /// *which* product ID cleared, never "how many coins it was worth,"
  /// so this mapping is what actually turns a purchase into a grant.
  static const Map<String, int> coinsForProduct = {
    coins500: 500,
    coins1200: 1200,
    coins2500: 2500,
    coins6000: 6000,
    coins15000: 15000,
  };
}

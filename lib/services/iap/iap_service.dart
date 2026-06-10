// The concrete implementation is selected at compile time so the (mobile-only)
// in_app_purchase plugin is never compiled into the web build.
import 'iap_service_stub.dart'
    if (dart.library.io) 'iap_service_mobile.dart';

/// Platform-neutral store product so UI code never touches plugin types.
class ShopProduct {
  const ShopProduct({required this.id, required this.title, required this.price});
  final String id;
  final String title;
  final String price;
}

/// In-app purchase abstraction for coin packs (consumables) and the "remove ads"
/// entitlement (non-consumable).
abstract class IapService {
  Future<void> init();
  bool get available;
  List<ShopProduct> get products;
  ShopProduct? productById(String id);
  Future<void> buy(String productId);
  Future<void> restore();
  void dispose();
}

/// Creates the platform-appropriate IAP service. [onPurchase] is invoked with a
/// product id once a purchase is verified, so fulfilment stays in one place.
IapService createIapService({
  required Future<void> Function(String productId) onPurchase,
}) =>
    createPlatformIapService(onPurchase: onPurchase);

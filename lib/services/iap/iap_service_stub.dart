import 'iap_service.dart';

/// Web / unsupported-platform stub: the store is simply unavailable.
IapService createPlatformIapService({
  required Future<void> Function(String productId) onPurchase,
}) =>
    _NoopIapService();

class _NoopIapService implements IapService {
  @override
  Future<void> init() async {}

  @override
  bool get available => false;

  @override
  List<ShopProduct> get products => const [];

  @override
  ShopProduct? productById(String id) => null;

  @override
  Future<void> buy(String productId) async {}

  @override
  Future<void> restore() async {}

  @override
  void dispose() {}
}

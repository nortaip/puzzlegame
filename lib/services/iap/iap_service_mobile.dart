import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/config/app_config.dart';
import 'iap_service.dart';

IapService createPlatformIapService({
  required Future<void> Function(String productId) onPurchase,
}) =>
    MobileIapService(onPurchase: onPurchase);

/// Wraps `in_app_purchase` for consumable coin packs and the non-consumable
/// "remove ads" entitlement.
class MobileIapService implements IapService {
  MobileIapService({required this.onPurchase});

  final Future<void> Function(String productId) onPurchase;

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  final Map<String, ProductDetails> _details = {};
  List<ShopProduct> _products = const [];
  bool _available = false;

  @override
  bool get available => _available;

  @override
  List<ShopProduct> get products => _products;

  @override
  Future<void> init() async {
    _available = await _iap.isAvailable();
    if (!_available) return;

    _sub = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (Object e) => debugPrint('IAP stream error: $e'),
    );

    final response = await _iap.queryProductDetails(AppConfig.iapProductIds);
    for (final d in response.productDetails) {
      _details[d.id] = d;
    }
    _products = [
      for (final d in response.productDetails)
        ShopProduct(id: d.id, title: d.title, price: d.price),
    ];
  }

  @override
  ShopProduct? productById(String id) {
    for (final p in _products) {
      if (p.id == id) return p;
    }
    return null;
  }

  @override
  Future<void> buy(String productId) async {
    final product = _details[productId];
    if (product == null) return;
    final param = PurchaseParam(productDetails: product);
    if (productId == 'remove_ads') {
      await _iap.buyNonConsumable(purchaseParam: param);
    } else {
      await _iap.buyConsumable(purchaseParam: param);
    }
  }

  @override
  Future<void> restore() => _iap.restorePurchases();

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        // NOTE: For production, verify the receipt server-side (e.g. a Supabase
        // Edge Function) before granting entitlements.
        await onPurchase(purchase.productID);
      }
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  @override
  void dispose() => _sub?.cancel();
}

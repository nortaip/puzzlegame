import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/config/app_config.dart';

/// Wraps `in_app_purchase` for the store's consumable coin packs and the
/// non-consumable "remove ads" entitlement. Purchase fulfilment is delegated to
/// [onPurchase] so the player economy stays in one place.
class IapService {
  IapService({required this.onPurchase});

  /// Called with a verified product id when a purchase completes.
  final Future<void> Function(String productId) onPurchase;

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  List<ProductDetails> products = const [];
  bool available = false;

  Future<void> init() async {
    available = await _iap.isAvailable();
    if (!available) return;

    _sub = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (Object e) => debugPrint('IAP stream error: $e'),
    );

    final response = await _iap.queryProductDetails(AppConfig.iapProductIds);
    products = response.productDetails;
  }

  ProductDetails? productById(String id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<void> buy(ProductDetails product) async {
    final param = PurchaseParam(productDetails: product);
    final isConsumable = product.id != 'remove_ads';
    if (isConsumable) {
      await _iap.buyConsumable(purchaseParam: param);
    } else {
      await _iap.buyNonConsumable(purchaseParam: param);
    }
  }

  Future<void> restore() => _iap.restorePurchases();

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        // NOTE: For production, verify the receipt server-side (e.g. via a
        // Supabase Edge Function) before granting entitlements.
        await onPurchase(purchase.productID);
      }
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  void dispose() => _sub?.cancel();
}

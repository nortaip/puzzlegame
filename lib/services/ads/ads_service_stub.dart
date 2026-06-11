import 'ads_service.dart';

/// Web / unsupported-platform stub. Ads are simply unavailable, so power-up
/// flows fall back to spending coins.
AdsService createPlatformAdsService() => _NoopAdsService();

class _NoopAdsService implements AdsService {
  @override
  Future<void> init() async {}

  @override
  bool get isReady => false;

  @override
  Future<bool> showRewarded(AdPlacement placement) async => false;

  @override
  Future<void> showInterstitial() async {}

  @override
  void dispose() {}
}

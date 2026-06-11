// The concrete implementation is selected at compile time: the mobile build
// pulls in `google_mobile_ads`, while the web build uses a no-op stub so the
// (mobile-only) ads plugin is never compiled for web.
import 'ads_service_stub.dart'
    if (dart.library.io) 'ads_service_mobile.dart';

/// Placement identifiers for rewarded ads.
enum AdPlacement { hint, coins, unlockSkill, extraUndo, hearts }

/// Rewarded-ads abstraction (the only ad format used initially). Implementations
/// must degrade gracefully — `showRewarded` returns false when no ad is
/// available so callers can fall back to spending coins.
abstract class AdsService {
  Future<void> init();
  bool get isReady;

  /// Shows a rewarded ad; resolves true only if the reward was earned.
  Future<bool> showRewarded(AdPlacement placement);

  /// Shows a forced interstitial (between levels). Resolves when dismissed or
  /// immediately if none is ready. No-op on platforms without ads (web).
  Future<void> showInterstitial();

  void dispose();
}

/// Creates the platform-appropriate ads service.
AdsService createAdsService() => createPlatformAdsService();

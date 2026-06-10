import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/config/app_config.dart';
import 'ads_service.dart';

AdsService createPlatformAdsService() => MobileAdsService();

/// Manages rewarded ads on Android/iOS. Pre-loads the next ad so reward flows
/// feel instant, and degrades gracefully on load failure.
class MobileAdsService implements AdsService {
  bool _initialized = false;
  RewardedAd? _rewarded;
  bool _loading = false;

  String get _unitId =>
      Platform.isIOS ? AppConfig.rewardedIos : AppConfig.rewardedAndroid;

  @override
  Future<void> init() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
    _preload();
  }

  void _preload() {
    if (_loading || _rewarded != null) return;
    _loading = true;
    RewardedAd.load(
      adUnitId: _unitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          _loading = false;
        },
        onAdFailedToLoad: (err) {
          if (kDebugMode) debugPrint('Rewarded load failed: $err');
          _rewarded = null;
          _loading = false;
        },
      ),
    );
  }

  @override
  bool get isReady => _rewarded != null;

  @override
  Future<bool> showRewarded(AdPlacement placement) async {
    final ad = _rewarded;
    if (ad == null) {
      _preload();
      return false;
    }
    _rewarded = null;

    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _preload();
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        ad.dispose();
        _preload();
      },
    );

    await ad.show(onUserEarnedReward: (_, __) => earned = true);
    return earned;
  }

  @override
  void dispose() {
    _rewarded?.dispose();
    _rewarded = null;
  }
}

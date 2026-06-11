import '../../core/constants/app_constants.dart';
import 'ads_service.dart';

/// Decides when a forced interstitial appears: after every Nth completed level,
/// never before [AppConstants.interstitialMinLevel], and never when the player
/// has bought "Remove Ads". Keeps the rest of the game free of forced ads.
class AdGate {
  AdGate(this._ads);

  final AdsService _ads;
  int _completedSinceAd = 0;

  Future<void> onLevelCompleted({
    required bool adsRemoved,
    required int level,
  }) async {
    if (adsRemoved) return;
    _completedSinceAd++;
    if (level < AppConstants.interstitialMinLevel) return;
    if (_completedSinceAd < AppConstants.interstitialEveryNLevels) return;
    _completedSinceAd = 0;
    await _ads.showInterstitial();
  }
}

/// Game-wide tunable constants and economy values.
class AppConstants {
  AppConstants._();

  static const String appName = 'Flow & Park Puzzle';

  // ── Economy ───────────────────────────────────────────────────────────────
  static const int baseLevelReward = 25;
  static const int perStarBonus = 10;
  static const int dailyChallengeReward = 100;
  static const int rewardedAdCoins = 50;
  static const int startingCoins = 100;

  // ── Ads ─────────────────────────────────────────────────────────────────
  /// Show a forced interstitial after every Nth completed level…
  static const int interstitialEveryNLevels = 3;

  /// …but never before this level (let new players settle in first).
  static const int interstitialMinLevel = 4;

  // ── Hearts (mistake lives) ─────────────────────────────────────────────────
  static const int maxHearts = 3;
  static const Duration heartRefill = Duration(hours: 2);

  // ── Power-up costs (coins) ────────────────────────────────────────────────
  static const int policeUnlockCost = 60;
  static const int shuffleCost = 40;
  static const int hintCost = 30;

  // ── Animation timings ─────────────────────────────────────────────────────
  static const Duration vehicleSlide = Duration(milliseconds: 180);
  static const Duration screenTransition = Duration(milliseconds: 320);
  static const Duration winCelebration = Duration(milliseconds: 2200);

  // ── Star thresholds (multipliers over a level's optimal move count) ───────
  static const double threeStarFactor = 1.15;
  static const double twoStarFactor = 1.6;
}

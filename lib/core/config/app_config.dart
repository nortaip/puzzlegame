/// Centralised, environment-driven configuration.
///
/// Secrets are injected at build time via `--dart-define` (never hard-code real
/// keys in source). Example:
///
/// ```
/// flutter run \
///   --dart-define=SUPABASE_URL=https://xyz.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=eyJ... \
///   --dart-define=ADMOB_REWARDED_ANDROID=ca-app-pub-.../...
/// ```
class AppConfig {
  AppConfig._();

  // ── Supabase ─────────────────────────────────────────────────────────────
  // The project URL and *publishable* (anon) key are public by design — they
  // ship inside every client and are protected by Row Level Security (see
  // docs/supabase_schema.sql). `--dart-define` still overrides these defaults.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://agmfcoxcurneiyzhnobb.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_MWlMSLD3Uory2jMyTDxlHQ_sb6F2H1i',
  );

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  // ── AdMob ────────────────────────────────────────────────────────────────
  // Google's official test ids are used as defaults so the app is safe to run
  // out of the box without serving live ads. Replace via --dart-define for
  // production, and set the *app id* in AndroidManifest.xml / Info.plist.
  static const String admobAppIdAndroid = String.fromEnvironment(
    'ADMOB_APP_ID_ANDROID',
    defaultValue: 'ca-app-pub-3940256099942544~3347511713',
  );
  static const String admobAppIdIos = String.fromEnvironment(
    'ADMOB_APP_ID_IOS',
    defaultValue: 'ca-app-pub-3940256099942544~1458002511',
  );

  static const String _testRewardedAndroid =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _testRewardedIos =
      'ca-app-pub-3940256099942544/1712485313';

  static const String rewardedAndroid = String.fromEnvironment(
    'ADMOB_REWARDED_ANDROID',
    defaultValue: _testRewardedAndroid,
  );
  static const String rewardedIos = String.fromEnvironment(
    'ADMOB_REWARDED_IOS',
    defaultValue: _testRewardedIos,
  );

  static const String interstitialAndroid = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_ANDROID',
    defaultValue: 'ca-app-pub-3940256099942544/1033173712',
  );
  static const String interstitialIos = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_IOS',
    defaultValue: 'ca-app-pub-3940256099942544/4411468910',
  );

  // ── In-App Purchase product ids ──────────────────────────────────────────
  static const Set<String> iapProductIds = {
    'coins_small',
    'coins_medium',
    'coins_large',
    'remove_ads',
  };

  static const bool analyticsEnabled = true;
}

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
  static const String supabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  // ── AdMob ────────────────────────────────────────────────────────────────
  // Google's official test unit ids are used as defaults so the app is safe to
  // run out of the box without serving live ads.
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

  // ── In-App Purchase product ids ──────────────────────────────────────────
  static const Set<String> iapProductIds = {
    'coins_small',
    'coins_medium',
    'coins_large',
    'remove_ads',
  };

  static const bool analyticsEnabled = true;
}

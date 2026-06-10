import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/logic/level_generator.dart';
import '../services/ads/ads_service.dart';
import '../services/analytics/analytics_service.dart';
import '../services/iap/iap_service.dart';
import '../services/storage/isar_service.dart';
import '../services/supabase/supabase_service.dart';
import '../services/supabase/sync_service.dart';
import 'player_controller.dart';

/// Service singletons are created in `main()` and injected via overrides so the
/// rest of the app can depend on them synchronously.
final isarServiceProvider = Provider<IsarService>(
  (ref) => throw UnimplementedError('Override isarServiceProvider in main()'),
);

final adsServiceProvider = Provider<AdsService>(
  (ref) => throw UnimplementedError('Override adsServiceProvider in main()'),
);

/// The IAP service is constructed by the provider so its fulfilment callback
/// can reach the live player economy without any container/closure cycles.
/// `init()` is called once from `main()` after the container is built.
final iapServiceProvider = Provider<IapService>(
  (ref) => IapService(
    onPurchase: (productId) =>
        _fulfilPurchase(ref.read(playerControllerProvider.notifier), productId),
  ),
);

Future<void> _fulfilPurchase(PlayerController player, String productId) async {
  switch (productId) {
    case 'coins_small':
      await player.addCoins(500);
    case 'coins_medium':
      await player.addCoins(1500);
    case 'coins_large':
      await player.addCoins(5000);
    case 'remove_ads':
      await player.setAdsRemoved(true);
  }
}

final supabaseServiceProvider =
    Provider<SupabaseService>((ref) => SupabaseService.instance);

final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => AnalyticsService(ref.watch(supabaseServiceProvider)),
);

final syncServiceProvider = Provider<SyncService>(
  (ref) => SyncService(
    ref.watch(isarServiceProvider),
    ref.watch(supabaseServiceProvider),
  ),
);

/// The procedural generator is pure and cheap to share.
final levelGeneratorProvider = Provider<LevelGenerator>((ref) => LevelGenerator());

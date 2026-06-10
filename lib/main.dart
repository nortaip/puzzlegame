import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'services/ads/ads_service.dart';
import 'services/storage/isar_service.dart';
import 'services/supabase/supabase_service.dart';
import 'state/player_controller.dart';
import 'state/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // ── Bootstrap services that require async init. The game is fully playable
  //    offline, so cloud/ads failures are swallowed and never block startup.
  final isar = await IsarService.open();

  final supabase = SupabaseService.instance;
  try {
    await supabase.init();
  } catch (_) {/* offline-first: ignore */}

  final ads = AdsService();
  try {
    await ads.init();
  } catch (_) {}

  final root = ProviderContainer(
    overrides: [
      isarServiceProvider.overrideWithValue(isar),
      adsServiceProvider.overrideWithValue(ads),
    ],
  );

  // Load the persisted player profile before first frame.
  await root.read(playerControllerProvider.notifier).init();

  // Initialise IAP via its provider (the fulfilment callback is wired there so
  // there are no container/closure cycles). Failures are non-fatal.
  try {
    await root.read(iapServiceProvider).init();
  } catch (_) {}

  runApp(
    UncontrolledProviderScope(
      container: root,
      child: const FlowParkApp(),
    ),
  );
}

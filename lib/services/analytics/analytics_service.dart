import 'package:flutter/foundation.dart';

import '../../core/config/app_config.dart';
import '../supabase/supabase_service.dart';

/// Lightweight analytics facade. Events are forwarded to Supabase when online;
/// in debug they are also printed. Designed to never throw into game code.
class AnalyticsService {
  AnalyticsService(this._supabase);

  final SupabaseService _supabase;

  Future<void> log(String event, {Map<String, Object?> params = const {}}) async {
    if (!AppConfig.analyticsEnabled) return;
    if (kDebugMode) {
      debugPrint('[analytics] $event $params');
    }
    try {
      final userId = await _supabase.ensureSignedIn();
      if (userId != null) {
        await _supabase.logEvent(userId, event);
      }
    } catch (_) {
      // Analytics must never disrupt gameplay.
    }
  }

  Future<void> levelStarted(int level) => log('level_started', params: {'level': level});
  Future<void> levelCompleted(int level, int moves, int stars) =>
      log('level_completed', params: {'level': level, 'moves': moves, 'stars': stars});
  Future<void> powerUpUsed(String type) => log('powerup_used', params: {'type': type});
  Future<void> rewardedAdWatched(String placement) =>
      log('rewarded_ad', params: {'placement': placement});
  Future<void> purchase(String productId) => log('iap_purchase', params: {'product': productId});
}

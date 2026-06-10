import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';

/// Wraps Supabase initialisation and the small set of tables this game uses
/// (`users`, `progress`, `analytics_events`, `leaderboard`). All methods no-op
/// gracefully when Supabase is not configured so the game stays fully offline.
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  bool _ready = false;
  bool get isReady => _ready && AppConfig.hasSupabase;

  /// Set once auth proves unavailable (e.g. anonymous sign-ins are disabled) so
  /// we stop retrying on every sync.
  bool _authUnavailable = false;

  SupabaseClient get _client => Supabase.instance.client;

  Future<void> init() async {
    if (!AppConfig.hasSupabase) return;
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: true,
      ),
    );
    _ready = true;
  }

  /// Anonymous sign-in gives every device a stable user id for cloud save
  /// without forcing the player through a login wall. Returns null (and never
  /// throws) when auth is unavailable — e.g. anonymous sign-ins are disabled in
  /// the Supabase project — so the game keeps working fully offline.
  Future<String?> ensureSignedIn() async {
    if (!isReady || _authUnavailable) return null;
    final current = _client.auth.currentUser;
    if (current != null) return current.id;
    try {
      final res = await _client.auth.signInAnonymously();
      return res.user?.id;
    } on AuthException catch (e) {
      _authUnavailable = true; // stop retrying (e.g. provider disabled)
      if (kDebugMode) debugPrint('Supabase auth unavailable: ${e.message}');
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('Supabase auth error: $e');
      return null;
    }
  }

  Future<void> upsertUser({
    required String userId,
    required int coins,
    required int level,
  }) async {
    if (!isReady) return;
    await _client.from('users').upsert({
      'id': userId,
      'coins': coins,
      'level': level,
    });
  }

  Future<void> upsertProgress({
    required String userId,
    required int level,
    required int score,
  }) async {
    if (!isReady) return;
    await _client.from('progress').upsert({
      'user_id': userId,
      'level': level,
      'score': score,
      'last_played': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id,level');
  }

  Future<Map<String, dynamic>?> fetchUser(String userId) async {
    if (!isReady) return null;
    return _client.from('users').select().eq('id', userId).maybeSingle();
  }

  Future<void> logEvent(String userId, String name) async {
    if (!isReady) return;
    await _client.from('analytics_events').insert({
      'user_id': userId,
      'event_name': name,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> leaderboard({int limit = 50}) async {
    if (!isReady) return const [];
    final rows = await _client
        .from('users')
        .select('id, coins, level')
        .order('level', ascending: false)
        .order('coins', ascending: false)
        .limit(limit);
    return (rows as List).cast<Map<String, dynamic>>();
  }
}

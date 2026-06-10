import 'package:connectivity_plus/connectivity_plus.dart';

import '../storage/local_store.dart';
import 'supabase_service.dart';

/// Bridges the offline [LocalStore] with Supabase. Sync is best-effort and only
/// runs when online; the game never blocks on it.
class SyncService {
  SyncService(this._store, this._supabase);

  final LocalStore _store;
  final SupabaseService _supabase;

  Future<bool> get _online async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  /// Pushes the local profile + any unsynced level results to the cloud.
  Future<void> pushAll() async {
    if (!_supabase.isReady || !await _online) return;

    final userId = await _supabase.ensureSignedIn();
    if (userId == null) return;

    final profile = await _store.loadProfile();
    profile.remoteUserId = userId;
    await _supabase.upsertUser(
      userId: userId,
      coins: profile.coins,
      level: profile.currentLevel,
      name: profile.username,
    );

    final pending = await _store.unsyncedProgress();
    for (final p in pending) {
      await _supabase.upsertProgress(
        userId: userId,
        level: p.levelNumber,
        score: p.bestScore,
      );
      p.synced = true;
      await _store.saveProgress(p);
    }
    await _store.saveProfile(profile);
  }

  /// Pulls cloud profile when it is ahead of local (cross-device restore).
  Future<void> pullIfNewer() async {
    if (!_supabase.isReady || !await _online) return;
    final userId = await _supabase.ensureSignedIn();
    if (userId == null) return;

    final remote = await _supabase.fetchUser(userId);
    if (remote == null) return;

    final profile = await _store.loadProfile();
    final remoteLevel = (remote['level'] as int?) ?? 1;
    if (remoteLevel > profile.currentLevel) {
      profile
        ..currentLevel = remoteLevel
        ..coins = (remote['coins'] as int?) ?? profile.coins
        ..remoteUserId = userId;
      await _store.saveProfile(profile);
    }
  }
}

import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/haptics.dart';
import '../services/audio/sound_service.dart';
import '../services/storage/models/player_profile.dart';
import 'providers.dart';

/// Holds the live [PlayerProfile] and mediates all economy mutations
/// (coins, power-up charges, cosmetics, settings), persisting each change to the
/// local store and triggering opportunistic cloud sync.
class PlayerController extends Notifier<PlayerProfile> {
  @override
  PlayerProfile build() {
    // Synchronously seed from a default; the real profile is loaded in init().
    return PlayerProfile();
  }

  Future<void> init() async {
    final store = ref.read(localStoreProvider);
    state = await store.loadProfile();
    // Give every install a stable local id the first time.
    if (state.localId.isEmpty) {
      state.localId = _generateId();
      await store.saveProfile(state);
      state = await store.loadProfile();
    }
    Haptics.enabled = state.hapticsEnabled;
    SoundService.instance.enabled = state.soundEnabled;
    // Pull any newer cloud profile, then push local state up.
    final sync = ref.read(syncServiceProvider);
    await sync.pullIfNewer();
    state = await store.loadProfile();
  }

  Future<void> _persist() async {
    await ref.read(localStoreProvider).saveProfile(state);
    // Fire-and-forget cloud push.
    unawaited(ref.read(syncServiceProvider).pushAll());
    // Re-read to reflect bumped revision/updatedAt.
    state = await ref.read(localStoreProvider).loadProfile();
  }

  bool get hasUsername => state.username.trim().isNotEmpty;

  /// Sets the player's display name after checking it isn't already taken by
  /// another player (when online). Returns the outcome so the UI can react.
  Future<UsernameResult> trySetUsername(String name) async {
    final n = name.trim();
    if (n.length < 2) return UsernameResult.tooShort;
    if (n.toLowerCase() == state.username.toLowerCase()) {
      return UsernameResult.ok; // unchanged
    }
    final taken = await ref
        .read(supabaseServiceProvider)
        .isNameTaken(n, excludeId: state.remoteUserId);
    if (taken) return UsernameResult.taken;
    state.username = n;
    await _persist();
    return UsernameResult.ok;
  }

  static String _generateId() {
    final r = Random();
    final ts = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final rand =
        List.generate(5, (_) => r.nextInt(36).toRadixString(36)).join();
    return 'u_$ts$rand';
  }

  bool canAfford(int cost) => state.coins >= cost;

  Future<void> addCoins(int amount) async {
    state.coins += amount;
    await _persist();
  }

  /// Spends coins if affordable; returns false otherwise.
  Future<bool> spendCoins(int amount) async {
    if (state.coins < amount) return false;
    state.coins -= amount;
    await _persist();
    return true;
  }

  Future<void> grantLevelReward(int stars) async {
    state.coins += AppConstants.baseLevelReward + stars * AppConstants.perStarBonus;
    await _persist();
  }

  Future<void> advanceLevel(int completedLevel) async {
    state.levelsCompleted += 1;
    if (completedLevel >= state.currentLevel) {
      state.currentLevel = completedLevel + 1;
    }
    await _persist();
  }

  // ── Power-up inventory ────────────────────────────────────────────────────
  Future<bool> consumePolice() => _consume(() => state.policeCharges,
      (v) => state.policeCharges = v);
  Future<bool> consumeShuffle() => _consume(() => state.shuffleCharges,
      (v) => state.shuffleCharges = v);
  Future<bool> consumeHint() => _consume(() => state.hintCharges,
      (v) => state.hintCharges = v);

  Future<bool> _consume(int Function() get, void Function(int) set) async {
    if (get() <= 0) return false;
    set(get() - 1);
    await _persist();
    return true;
  }

  Future<void> grantPolice([int n = 1]) async {
    state.policeCharges += n;
    await _persist();
  }

  Future<void> grantShuffle([int n = 1]) async {
    state.shuffleCharges += n;
    await _persist();
  }

  Future<void> grantHint([int n = 1]) async {
    state.hintCharges += n;
    await _persist();
  }

  // ── Cosmetics / settings ──────────────────────────────────────────────────
  Future<void> selectTheme(int index) async {
    if (!state.ownedThemes.contains(index)) return;
    state.activeThemeIndex = index;
    await _persist();
  }

  Future<void> unlockTheme(int index) async {
    if (!state.ownedThemes.contains(index)) {
      state.ownedThemes = [...state.ownedThemes, index];
    }
    await _persist();
  }

  Future<void> selectSkin(int index) async {
    if (!state.ownedSkins.contains(index)) return;
    state.activeSkinIndex = index;
    await _persist();
  }

  Future<void> unlockSkin(int index) async {
    if (!state.ownedSkins.contains(index)) {
      state.ownedSkins = [...state.ownedSkins, index];
    }
    await _persist();
  }

  Future<void> setAdsRemoved(bool value) async {
    state.adsRemoved = value;
    await _persist();
  }

  Future<void> setSound(bool value) async {
    state.soundEnabled = value;
    SoundService.instance.enabled = value;
    await _persist();
  }

  Future<void> setHaptics(bool value) async {
    state.hapticsEnabled = value;
    Haptics.enabled = value;
    await _persist();
  }
}

final playerControllerProvider =
    NotifierProvider<PlayerController, PlayerProfile>(PlayerController.new);

/// Outcome of trying to set a username.
enum UsernameResult { ok, taken, tooShort }

/// Minimal `unawaited` to avoid pulling in dart:async everywhere.
void unawaited(Future<void> future) {}

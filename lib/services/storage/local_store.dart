import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models/level_progress.dart';
import 'models/player_profile.dart';

/// The app's primary, fully-offline data store. Backed by [SharedPreferences]
/// and JSON — no native DB and no code generation, so it runs identically on
/// mobile, desktop and web.
class LocalStore {
  LocalStore._(this._prefs);

  final SharedPreferences _prefs;

  static const _profileKey = 'player_profile';
  static const _progressPrefix = 'level_progress_';

  static Future<LocalStore> open() async {
    final prefs = await SharedPreferences.getInstance();
    final store = LocalStore._(prefs);
    if (!prefs.containsKey(_profileKey)) {
      await store.saveProfile(PlayerProfile());
    }
    return store;
  }

  // ── Profile ────────────────────────────────────────────────────────────────
  Future<PlayerProfile> loadProfile() async {
    final raw = _prefs.getString(_profileKey);
    if (raw == null) return PlayerProfile();
    try {
      return PlayerProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return PlayerProfile();
    }
  }

  Future<void> saveProfile(PlayerProfile profile) async {
    profile
      ..updatedAt = DateTime.now()
      ..revision += 1;
    await _prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  // ── Level progress ───────────────────────────────────────────────────────
  Future<LevelProgress?> progressFor(int levelNumber) async {
    final raw = _prefs.getString('$_progressPrefix$levelNumber');
    if (raw == null) return null;
    try {
      return LevelProgress.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveProgress(LevelProgress progress) async {
    progress.lastPlayed = DateTime.now();
    await _prefs.setString(
      '$_progressPrefix${progress.levelNumber}',
      jsonEncode(progress.toJson()),
    );
  }

  Future<List<LevelProgress>> allProgress() async {
    final result = <LevelProgress>[];
    for (final key in _prefs.getKeys()) {
      if (!key.startsWith(_progressPrefix)) continue;
      final raw = _prefs.getString(key);
      if (raw == null) continue;
      try {
        result.add(
            LevelProgress.fromJson(jsonDecode(raw) as Map<String, dynamic>));
      } catch (_) {/* skip corrupt entry */}
    }
    return result;
  }

  Future<List<LevelProgress>> unsyncedProgress() async {
    final all = await allProgress();
    return all.where((p) => !p.synced).toList();
  }
}

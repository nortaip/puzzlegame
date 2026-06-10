import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'models/level_progress.dart';
import 'models/player_profile.dart';

/// Owns the Isar database — the app's primary, fully-offline data store.
class IsarService {
  IsarService._(this._isar);

  final Isar _isar;
  Isar get db => _isar;

  static Future<IsarService> open() async {
    final dir = await getApplicationDocumentsDirectory();
    final isar = await Isar.open(
      [PlayerProfileSchema, LevelProgressSchema],
      directory: dir.path,
      name: 'flow_park',
    );
    final service = IsarService._(isar);
    await service._ensureProfile();
    return service;
  }

  Future<void> _ensureProfile() async {
    final existing = await _isar.playerProfiles.get(0);
    if (existing == null) {
      await _isar.writeTxn(() => _isar.playerProfiles.put(PlayerProfile()));
    }
  }

  // ── Profile ────────────────────────────────────────────────────────────
  Future<PlayerProfile> loadProfile() async =>
      await _isar.playerProfiles.get(0) ?? PlayerProfile();

  Future<void> saveProfile(PlayerProfile profile) async {
    profile
      ..updatedAt = DateTime.now()
      ..revision += 1;
    await _isar.writeTxn(() => _isar.playerProfiles.put(profile));
  }

  Stream<PlayerProfile?> watchProfile() =>
      _isar.playerProfiles.watchObject(0, fireImmediately: true);

  // ── Level progress ───────────────────────────────────────────────────────
  Future<LevelProgress?> progressFor(int levelNumber) =>
      _isar.levelProgress.get(levelNumber);

  Future<void> saveProgress(LevelProgress progress) async {
    progress.lastPlayed = DateTime.now();
    await _isar.writeTxn(() => _isar.levelProgress.put(progress));
  }

  Future<List<LevelProgress>> allProgress() =>
      _isar.levelProgress.where().findAll();

  Future<List<LevelProgress>> unsyncedProgress() =>
      _isar.levelProgress.filter().syncedEqualTo(false).findAll();

  Future<void> close() => _isar.close();
}

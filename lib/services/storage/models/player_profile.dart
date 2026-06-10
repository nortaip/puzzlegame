import 'package:isar/isar.dart';

part 'player_profile.g.dart'; // run: dart run build_runner build

/// The single local player record (offline source of truth). Synced to
/// Supabase opportunistically when a network connection is available.
@collection
class PlayerProfile {
  Id id = 0; // singleton row

  /// Server-side user id once authenticated/synced; null while purely offline.
  String? remoteUserId;

  int coins = 100;

  /// Highest level the player has unlocked (1-based).
  int currentLevel = 1;

  /// Total levels completed (for stats / leaderboard).
  int levelsCompleted = 0;

  // Power-up inventory.
  int policeCharges = 1;
  int shuffleCharges = 1;
  int hintCharges = 3;

  bool adsRemoved = false;

  // Cosmetics.
  int activeThemeIndex = 0;
  int activeSkinIndex = 0;
  List<int> ownedThemes = [0];
  List<int> ownedSkins = [0];

  // Settings.
  bool soundEnabled = true;
  bool hapticsEnabled = true;

  DateTime updatedAt = DateTime.now();

  /// Monotonic counter to resolve last-write-wins sync conflicts.
  int revision = 0;
}

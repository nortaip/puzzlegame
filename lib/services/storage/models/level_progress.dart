import 'package:isar/isar.dart';

part 'level_progress.g.dart'; // run: dart run build_runner build

/// Per-level result record. Keyed by [levelNumber] for fast lookup.
@collection
class LevelProgress {
  /// The level number doubles as the Isar id, so progress is keyed 1:1 by level.
  Id get isarId => levelNumber;

  late int levelNumber;

  int bestMoves = 0;
  int stars = 0; // 0..3
  int bestScore = 0;

  DateTime lastPlayed = DateTime.now();

  /// Set once the result has been pushed to Supabase.
  bool synced = false;
}

import 'dart:math';

/// Difficulty parameters derived from a level number. Encapsulates the
/// progression curve described in the design (grid growth, vehicle density,
/// minimum solution length, and which mechanics are unlocked).
class DifficultyConfig {
  const DifficultyConfig({
    required this.gridSize,
    required this.vehicleCount,
    required this.minOptimalMoves,
    required this.maxOptimalMoves,
    required this.allowTrucks,
    required this.allowLocked,
  });

  final int gridSize;
  final int vehicleCount;
  final int minOptimalMoves;
  final int maxOptimalMoves;
  final bool allowTrucks;
  final bool allowLocked;

  /// Maps a 1-based level number onto a smooth difficulty curve.
  factory DifficultyConfig.forLevel(int level) {
    final int gridSize;
    if (level <= 10) {
      gridSize = 5;
    } else if (level <= 50) {
      gridSize = 6;
    } else if (level <= 120) {
      gridSize = 7;
    } else {
      gridSize = 8;
    }

    // Vehicle density grows with grid area but stays under a packing limit so
    // the board never becomes a gridlocked mess.
    final cells = gridSize * gridSize;
    final density = 0.10 + min(level, 200) * 0.0009; // ~0.10 -> ~0.28
    final vehicleCount = max(3, (cells * density).round());

    final minMoves = (4 + level * 0.6).round().clamp(4, 45);
    final maxMoves = minMoves + 14;

    return DifficultyConfig(
      gridSize: gridSize,
      vehicleCount: vehicleCount,
      minOptimalMoves: minMoves,
      maxOptimalMoves: maxMoves,
      allowTrucks: level >= 6,
      allowLocked: level >= 25,
    );
  }
}

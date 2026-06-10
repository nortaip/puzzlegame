import 'dart:math';

/// Difficulty parameters derived from a level number. Drives grid growth, car
/// density and how deeply cars are jammed in — so levels get meaningfully
/// harder as the player progresses.
class DifficultyConfig {
  const DifficultyConfig({
    required this.gridSize,
    required this.vehicleCount,
    required this.allowTrucks,
    required this.depthBias,
  });

  final int gridSize;
  final int vehicleCount;
  final bool allowTrucks;

  /// 0..1 — how strongly the generator favours parking cars deep (further from
  /// their exit edge), which creates more interlocking jams. Grows with level.
  final double depthBias;

  factory DifficultyConfig.forLevel(int level) {
    final int gridSize;
    if (level <= 8) {
      gridSize = 5;
    } else if (level <= 40) {
      gridSize = 6;
    } else if (level <= 100) {
      gridSize = 7;
    } else {
      gridSize = 8;
    }

    // Car density climbs steadily with the level (capped so the board stays
    // readable and the reverse-generator can always place its cars).
    final cells = gridSize * gridSize;
    final density = (0.20 + level * 0.0020).clamp(0.20, 0.50); // ~0.20 -> 0.50
    final vehicleCount = max(4, (cells * density).round());

    return DifficultyConfig(
      gridSize: gridSize,
      vehicleCount: vehicleCount,
      allowTrucks: level >= 5,
      depthBias: (level * 0.012).clamp(0.0, 0.85),
    );
  }
}

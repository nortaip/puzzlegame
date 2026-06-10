import 'dart:math';

/// Difficulty parameters derived from a level number: grid growth, car density
/// and whether trucks (length-3) appear.
class DifficultyConfig {
  const DifficultyConfig({
    required this.gridSize,
    required this.vehicleCount,
    required this.allowTrucks,
  });

  final int gridSize;
  final int vehicleCount;
  final bool allowTrucks;

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

    // Car density grows with the level but stays under a packing limit so the
    // board stays readable and the reverse-generator can always place cars.
    final cells = gridSize * gridSize;
    final density = 0.16 + min(level, 200) * 0.0010; // ~0.16 -> ~0.36
    final vehicleCount = max(3, (cells * density).round());

    return DifficultyConfig(
      gridSize: gridSize,
      vehicleCount: vehicleCount,
      allowTrucks: level >= 6,
    );
  }
}

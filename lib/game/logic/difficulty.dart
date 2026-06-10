import 'dart:math';

import '../models/vehicle.dart';

/// Difficulty parameters derived from a level number. Drives grid growth, car
/// density, the mix of vehicle types and how deeply cars are jammed in — so
/// levels get meaningfully harder as the player progresses.
class DifficultyConfig {
  const DifficultyConfig({
    required this.gridSize,
    required this.vehicleCount,
    required this.typePool,
    required this.depthBias,
    required this.treeCount,
  });

  final int gridSize;
  final int vehicleCount;

  /// Number of static roadside-tree obstacles that close off some exits.
  final int treeCount;

  /// Weighted pool of vehicle types to draw from (repeats bias the odds).
  final List<VehicleType> typePool;

  /// 0..1 — how strongly the generator favours parking cars deep (further from
  /// their exit edge), which creates more interlocking jams. Grows with level.
  final double depthBias;

  factory DifficultyConfig.forLevel(int level) {
    // Grid grows through the early game, reaches 8 after level 100, then keeps
    // growing by one every 100 levels (9 by 300, 10 by 400, …) up to a sane cap.
    final int gridSize;
    if (level <= 8) {
      gridSize = 5;
    } else if (level <= 40) {
      gridSize = 6;
    } else if (level <= 100) {
      gridSize = 7;
    } else {
      gridSize = (8 + (level - 101) ~/ 100).clamp(8, 14);
    }

    // Car density climbs steadily with the level (capped so the board stays
    // readable and the reverse-generator can always place its cars).
    final cells = gridSize * gridSize;
    final density = (0.20 + level * 0.0020).clamp(0.20, 0.50); // ~0.20 -> 0.50
    final vehicleCount = max(4, (cells * density).round());

    // Vehicle mix: cars are always common; longer vehicles unlock with the grid
    // size (length-4 buses/trucks need a roomier board) and the level.
    final pool = <VehicleType>[
      VehicleType.car,
      VehicleType.car,
      VehicleType.car,
      VehicleType.minivan,
    ];
    if (level >= 4) pool.add(VehicleType.minivan);
    if (gridSize >= 6) pool.add(VehicleType.bus);
    if (gridSize >= 6 && level >= 18) pool.add(VehicleType.truck);
    if (gridSize >= 7) pool.add(VehicleType.bus); // more big vehicles later

    // Trees start appearing in the mid game and grow slowly, capped so plenty
    // of exits stay open (never more than ~the grid side length).
    final treeCount =
        level < 12 ? 0 : (1 + (level - 12) ~/ 18).clamp(0, gridSize);

    return DifficultyConfig(
      gridSize: gridSize,
      vehicleCount: vehicleCount,
      typePool: pool,
      depthBias: (level * 0.012).clamp(0.0, 0.85),
      treeCount: treeCount,
    );
  }
}

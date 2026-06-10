import 'board.dart';
import 'vehicle.dart';

/// An immutable, fully-specified, guaranteed-solvable puzzle.
class Level {
  const Level({
    required this.number,
    required this.gridSize,
    required this.exitRow,
    required this.vehicles,
    required this.initialPositions,
    required this.optimalMoves,
    required this.seed,
    this.themeIndex = 0,
  });

  final int number;
  final int gridSize;
  final int exitRow;
  final List<Vehicle> vehicles;
  final List<int> initialPositions;

  /// Minimum number of slides to solve (from the BFS solver). Drives the star
  /// rating and difficulty banding.
  final int optimalMoves;

  /// Seed used to procedurally generate this level (deterministic / shareable).
  final int seed;

  final int themeIndex;

  /// A fresh, playable [Board] for this level.
  Board newBoard() => Board(
        size: gridSize,
        exitRow: exitRow,
        vehicles: vehicles,
        positions: List<int>.of(initialPositions),
      );
}

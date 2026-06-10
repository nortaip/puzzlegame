import 'board.dart';
import 'vehicle.dart';

/// An immutable, fully-specified, guaranteed-clearable puzzle.
class Level {
  const Level({
    required this.number,
    required this.gridSize,
    required this.cars,
    required this.seed,
    this.trees = const [],
    this.themeIndex = 0,
  });

  final int number;
  final int gridSize;
  final List<Vehicle> cars;

  /// Static tree-obstacle cells (`row * gridSize + col`).
  final List<int> trees;

  /// Seed used to procedurally generate this level (deterministic / shareable).
  final int seed;

  final int themeIndex;

  /// The par for the level: each car must be driven off exactly once, so the
  /// optimal number of moves equals the number of cars.
  int get optimalMoves => cars.length;

  /// A fresh, playable [Board] for this level.
  Board newBoard() =>
      Board(size: gridSize, cars: List<Vehicle>.of(cars), trees: trees);
}

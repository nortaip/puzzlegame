import 'dart:math';

import '../models/board.dart';
import '../models/direction.dart';
import '../models/level.dart';
import '../models/vehicle.dart';
import 'difficulty.dart';
import 'solver.dart';

/// Procedural generator for drive-off levels that are **guaranteed clearable**.
///
/// Strategy — *reverse construction*. The solved state is an empty board. We
/// build a puzzle by driving cars *in* from the borders: each new car enters
/// from one edge and parks at some depth, and we only place it if the whole lane
/// it travelled is currently empty. Its [Vehicle.facing] is set to point back
/// toward that edge, so driving the cars off in the reverse of their placement
/// order is always a valid solution — the board is solvable by construction.
///
/// Difficulty scales with the level: more cars, and (via [DifficultyConfig.depthBias])
/// cars parked deeper, which forces longer unjamming chains. [PuzzleSolver]
/// re-verifies defensively.
class LevelGenerator {
  LevelGenerator({PuzzleSolver? solver}) : _solver = solver ?? const PuzzleSolver();

  final PuzzleSolver _solver;

  Level generate(int number, {int? seed}) {
    final cfg = DifficultyConfig.forLevel(number);
    final baseSeed = seed ?? (DateTime.now().microsecondsSinceEpoch ^ number);
    final rng = Random(baseSeed);

    final minCars = max(4, (cfg.vehicleCount * 0.8).round());

    Board? best;
    var bestCount = -1;
    for (var attempt = 0; attempt < 80; attempt++) {
      final board = _build(cfg, rng);
      if (!_solver.canClear(board)) continue; // defensive; should never fail
      if (board.cars.length >= minCars) {
        best = board;
        break;
      }
      // Keep the fullest fallback in case we never hit minCars.
      if (board.cars.length > bestCount) {
        bestCount = board.cars.length;
        best = board;
      }
    }

    best ??= _fallback(cfg);
    return Level(
      number: number,
      gridSize: best.size,
      cars: List<Vehicle>.of(best.cars),
      trees: List<int>.of(best.trees),
      seed: baseSeed,
      themeIndex: number % 5,
    );
  }

  Board _build(DifficultyConfig cfg, Random rng) {
    final size = cfg.gridSize;
    final occ = List<int>.filled(size * size, -1);

    // Trees go down first; the lane-clear check below then keeps every car's
    // exit path tree-free, so the board stays solvable.
    final trees = _placeTrees(cfg, rng, occ, size);

    final cars = <Vehicle>[];
    var nextId = 0;

    final guardLimit = cfg.vehicleCount * 30;
    var guard = 0;
    while (cars.length < cfg.vehicleCount && guard < guardLimit) {
      guard++;
      final horizontal = rng.nextBool();
      final type = cfg.typePool[rng.nextInt(cfg.typePool.length)];
      final length = type.length;
      if (length > size) continue; // too long for this board
      final line = rng.nextInt(size);
      final fromStart = rng.nextBool(); // entered from left/top vs right/bottom
      final lead = _pickLead(size, length, fromStart, cfg.depthBias, rng);

      if (!_laneClear(occ, size, horizontal, line, lead, length, fromStart)) {
        continue;
      }

      // A car that drove in from the start edge exits back toward it, etc.
      final facing = horizontal
          ? (fromStart ? SlideDirection.left : SlideDirection.right)
          : (fromStart ? SlideDirection.up : SlideDirection.down);

      final car = Vehicle(
        id: nextId,
        length: length,
        line: line,
        lead: lead,
        facing: facing,
        type: type,
        skinId: nextId,
      );
      _stampBody(occ, size, car);
      cars.add(car);
      nextId++;
    }

    return Board(size: size, cars: cars, trees: trees);
  }

  /// Places [DifficultyConfig.treeCount] tree obstacles, biased to the border
  /// (roadside) so they close off some exits while leaving plenty open.
  List<int> _placeTrees(
    DifficultyConfig cfg,
    Random rng,
    List<int> occ,
    int size,
  ) {
    if (cfg.treeCount <= 0) return const [];
    final border = <int>[];
    final interior = <int>[];
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        final isBorder = r == 0 || r == size - 1 || c == 0 || c == size - 1;
        (isBorder ? border : interior).add(r * size + c);
      }
    }
    border.shuffle(rng);
    interior.shuffle(rng);

    final trees = <int>[];
    for (final cell in [...border, ...interior]) {
      if (trees.length >= cfg.treeCount) break;
      if (occ[cell] != -1) continue;
      occ[cell] = Board.treeCell;
      trees.add(cell);
    }
    return trees;
  }

  /// Picks how deep the car parks. With higher [depthBias] we bias toward the
  /// deepest valid position (furthest from the exit edge), creating tougher
  /// interlocking jams.
  int _pickLead(int size, int length, bool fromStart, double depthBias, Random rng) {
    final maxLead = size - length;
    if (maxLead <= 0) return 0;
    // "Depth" for a start-edge car (exits left/up) increases with lead; for an
    // end-edge car (exits right/down) it increases as lead decreases.
    final r1 = rng.nextDouble();
    final r2 = rng.nextDouble();
    final biased = depthBias > 0 ? max(r1, r2) : r1; // skew toward 1.0
    final depthFraction = depthBias * biased + (1 - depthBias) * r1;
    final deep = (depthFraction * maxLead).round().clamp(0, maxLead);
    return fromStart ? deep : maxLead - deep;
  }

  /// Whether the lane a car would travel through on entry is empty. From the
  /// start edge the lane is cells 0..(lead+len-1); from the end edge it is
  /// cells lead..(size-1). The body is included, so this also rejects overlaps.
  bool _laneClear(
    List<int> occ,
    int size,
    bool horizontal,
    int line,
    int lead,
    int length,
    bool fromStart,
  ) {
    final start = fromStart ? 0 : lead;
    final end = fromStart ? lead + length - 1 : size - 1;
    for (var i = start; i <= end; i++) {
      final r = horizontal ? line : i;
      final c = horizontal ? i : line;
      if (occ[r * size + c] != -1) return false;
    }
    return true;
  }

  void _stampBody(List<int> occ, int size, Vehicle car) {
    for (var i = 0; i < car.length; i++) {
      occ[car.cellRow(i) * size + car.cellCol(i)] = car.id;
    }
  }

  /// A tiny, clearable-by-construction board, used only if random construction
  /// somehow underfills.
  Board _fallback(DifficultyConfig cfg) {
    final size = cfg.gridSize;
    return Board(
      size: size,
      cars: [
        Vehicle(id: 0, length: 2, line: 0, lead: 0, facing: SlideDirection.left),
        Vehicle(id: 1, length: 2, line: 2, lead: 1, facing: SlideDirection.left),
        Vehicle(id: 2, length: 2, line: size - 1, lead: 2, facing: SlideDirection.down),
      ],
    );
  }
}

import 'dart:math';

import '../models/board.dart';
import '../models/direction.dart';
import '../models/level.dart';
import '../models/vehicle.dart';
import 'difficulty.dart';
import 'solver.dart';

/// Procedural generator that produces **guaranteed-solvable** levels.
///
/// Strategy: construct a candidate board by randomly placing a horizontal
/// target vehicle on the exit row plus a set of non-overlapping obstacle
/// vehicles, then *prove* solvability with the BFS [PuzzleSolver]. A candidate
/// is only accepted when:
///   1. the solver finds a solution (never an impossible / soft-locked state),
///   2. the board is not already solved, and
///   3. the optimal solution length falls inside the difficulty band.
///
/// Because acceptance requires a solver-verified solution, every emitted level
/// is provably solvable — there is no path by which an unsolvable board escapes
/// the loop. If the band can't be met within the attempt budget, the band is
/// progressively relaxed (but solvability is never compromised).
class LevelGenerator {
  LevelGenerator({PuzzleSolver? solver}) : _solver = solver ?? const PuzzleSolver();

  final PuzzleSolver _solver;

  static const int _attemptsPerBand = 400;
  static const int _targetLength = 2;

  /// Generates level [number]. When [seed] is provided the result is fully
  /// deterministic (used for daily challenges and reproducible sharing).
  Level generate(int number, {int? seed}) {
    final cfg = DifficultyConfig.forLevel(number);
    final baseSeed = seed ?? (DateTime.now().microsecondsSinceEpoch ^ number);
    final rng = Random(baseSeed);

    var minMoves = cfg.minOptimalMoves;

    // Relax the minimum-move requirement in stages if needed, but keep every
    // emitted candidate strictly solver-verified.
    for (var relax = 0; relax < 6; relax++, minMoves = max(2, minMoves - 2)) {
      for (var attempt = 0; attempt < _attemptsPerBand; attempt++) {
        final candidate = _tryBuild(cfg, rng);
        if (candidate == null) continue;

        final result = _solver.solve(candidate);
        if (!result.solvable) continue; // never accept unsolvable states
        if (result.moveCount < minMoves) continue;
        if (result.moveCount > cfg.maxOptimalMoves) continue;

        return _toLevel(number, baseSeed, candidate, result.moveCount);
      }
    }

    // Guaranteed fallback: a minimal, hand-shaped board that is solvable by
    // construction. This branch is effectively unreachable for sane configs but
    // guarantees the method is total — it never returns an unsolvable level.
    return _fallback(number, baseSeed, cfg);
  }

  /// Attempts a single random board layout. Returns null on a bad layout
  /// (overlap / trivially solved) so the caller can retry.
  Board? _tryBuild(DifficultyConfig cfg, Random rng) {
    final size = cfg.gridSize;
    final exitRow = rng.nextInt(size);

    final vehicles = <Vehicle>[];
    final positions = <int>[];
    final occ = List<int>.filled(size * size, -1);

    // 1. Target vehicle: horizontal, on the exit row, not already at the exit.
    final maxStart = size - _targetLength; // exclusive of the winning column
    final targetCol = rng.nextInt(maxStart); // 0 .. maxStart-1 (never solved)
    final target = Vehicle(
      id: 0,
      axis: MoveAxis.horizontal,
      length: _targetLength,
      fixedLine: exitRow,
      isTarget: true,
    );
    _stamp(occ, size, target, targetCol);
    vehicles.add(target);
    positions.add(targetCol);

    // 2. Force at least one blocker on the exit row to the right of the target,
    //    otherwise the puzzle is trivial.
    final blockerPlaced = _placeExitRowBlocker(
      occ,
      size,
      exitRow,
      targetCol + _targetLength,
      vehicles,
      positions,
      rng,
      cfg,
    );
    if (!blockerPlaced) return null;

    // 3. Fill with obstacle vehicles up to the difficulty's vehicle count.
    var guard = 0;
    while (vehicles.length < cfg.vehicleCount && guard < 200) {
      guard++;
      _tryPlaceRandom(occ, size, exitRow, vehicles, positions, rng, cfg);
    }

    if (vehicles.length < 2) return null;

    final board = Board(
      size: size,
      exitRow: exitRow,
      vehicles: vehicles,
      positions: positions,
    );
    return board.isSolved ? null : board;
  }

  bool _placeExitRowBlocker(
    List<int> occ,
    int size,
    int exitRow,
    int fromCol,
    List<Vehicle> vehicles,
    List<int> positions,
    Random rng,
    DifficultyConfig cfg,
  ) {
    // A vertical vehicle crossing the exit row somewhere to the right of target.
    final candidateCols = <int>[
      for (var c = fromCol; c < size; c++) c,
    ]..shuffle(rng);

    for (final col in candidateCols) {
      final length = (cfg.allowTrucks && rng.nextBool()) ? 3 : 2;
      // Vertical vehicle must span exitRow.
      final minRow = max(0, exitRow - (length - 1));
      final maxRow = min(exitRow, size - length);
      if (minRow > maxRow) continue;
      final row = minRow + rng.nextInt(maxRow - minRow + 1);
      final v = Vehicle(
        id: vehicles.length,
        axis: MoveAxis.vertical,
        length: length,
        fixedLine: col,
      );
      if (_fits(occ, size, v, row)) {
        _stamp(occ, size, v, row);
        vehicles.add(v);
        positions.add(row);
        return true;
      }
    }
    return false;
  }

  void _tryPlaceRandom(
    List<int> occ,
    int size,
    int exitRow,
    List<Vehicle> vehicles,
    List<int> positions,
    Random rng,
    DifficultyConfig cfg,
  ) {
    final axis = rng.nextBool() ? MoveAxis.horizontal : MoveAxis.vertical;
    final length = (cfg.allowTrucks && rng.nextInt(3) == 0) ? 3 : 2;
    final lead = rng.nextInt(size - length + 1);
    final fixedLine = rng.nextInt(size);

    // Never drop a horizontal vehicle on the exit row (it could block illegally
    // or trivialise the lane); verticals there are fine and add challenge.
    if (axis == MoveAxis.horizontal && fixedLine == exitRow) return;

    final id = vehicles.length;
    final locked = cfg.allowLocked && rng.nextInt(8) == 0;
    final v = Vehicle(
      id: id,
      axis: axis,
      length: length,
      fixedLine: fixedLine,
      isLocked: locked,
    );
    if (_fits(occ, size, v, lead)) {
      _stamp(occ, size, v, lead);
      vehicles.add(v);
      positions.add(lead);
    }
  }

  bool _fits(List<int> occ, int size, Vehicle v, int lead) {
    for (var i = 0; i < v.length; i++) {
      final r = v.isHorizontal ? v.fixedLine : lead + i;
      final c = v.isHorizontal ? lead + i : v.fixedLine;
      if (r < 0 || r >= size || c < 0 || c >= size) return false;
      if (occ[r * size + c] != -1) return false;
    }
    return true;
  }

  void _stamp(List<int> occ, int size, Vehicle v, int lead) {
    for (var i = 0; i < v.length; i++) {
      final r = v.isHorizontal ? v.fixedLine : lead + i;
      final c = v.isHorizontal ? lead + i : v.fixedLine;
      occ[r * size + c] = v.id;
    }
  }

  Level _toLevel(int number, int seed, Board board, int optimalMoves) {
    return Level(
      number: number,
      gridSize: board.size,
      exitRow: board.exitRow,
      vehicles: List<Vehicle>.of(board.vehicles),
      initialPositions: List<int>.of(board.positions),
      optimalMoves: optimalMoves,
      seed: seed,
      themeIndex: number % 5,
    );
  }

  /// A trivially solvable, construction-proven level used only if random
  /// generation somehow fails to satisfy the band. Target + one blocker.
  Level _fallback(int number, int seed, DifficultyConfig cfg) {
    final size = cfg.gridSize;
    const exitRow = 0;
    final target = Vehicle(
      id: 0,
      axis: MoveAxis.horizontal,
      length: _targetLength,
      fixedLine: exitRow,
      isTarget: true,
    );
    final blocker = Vehicle(
      id: 1,
      axis: MoveAxis.vertical,
      length: 2,
      fixedLine: size - 1,
    );
    final board = Board(
      size: size,
      exitRow: exitRow,
      vehicles: [target, blocker],
      positions: [0, 0],
    );
    final result = _solver.solve(board);
    return _toLevel(number, seed, board, result.moveCount);
  }
}

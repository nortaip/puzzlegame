import 'dart:math';

import '../models/board.dart';
import '../models/direction.dart';
import '../models/level.dart';
import '../models/vehicle.dart';
import 'difficulty.dart';
import 'solver.dart';

/// Procedural generator for "open the road" levels that are **guaranteed
/// clearable**.
///
/// Strategy — *reverse construction*. The solved state is an empty board. We
/// build a puzzle by driving cars *in* from the borders: each new car enters
/// from one edge and parks at some depth, and we only place it if the whole lane
/// it travelled is currently empty. Driving the cars back out in the reverse of
/// their placement order is therefore always a valid solution — so the board is
/// solvable by construction. The [PuzzleSolver] re-verifies as a safety net.
class LevelGenerator {
  LevelGenerator({PuzzleSolver? solver}) : _solver = solver ?? const PuzzleSolver();

  final PuzzleSolver _solver;

  Level generate(int number, {int? seed}) {
    final cfg = DifficultyConfig.forLevel(number);
    final baseSeed = seed ?? (DateTime.now().microsecondsSinceEpoch ^ number);
    final rng = Random(baseSeed);

    final minCars = max(3, (cfg.vehicleCount * 0.7).round());

    Board? best;
    for (var attempt = 0; attempt < 60; attempt++) {
      final board = _build(cfg, rng);
      if (board.cars.length < minCars) continue;
      // Reverse construction already guarantees this; verify defensively.
      if (_solver.canClear(board)) {
        best = board;
        break;
      }
    }

    best ??= _fallback(cfg);
    return Level(
      number: number,
      gridSize: best.size,
      cars: List<Vehicle>.of(best.cars),
      seed: baseSeed,
      themeIndex: number % 5,
    );
  }

  Board _build(DifficultyConfig cfg, Random rng) {
    final size = cfg.gridSize;
    final occ = List<int>.filled(size * size, -1);
    final cars = <Vehicle>[];
    var nextId = 0;

    final guardLimit = cfg.vehicleCount * 25;
    var guard = 0;
    while (cars.length < cfg.vehicleCount && guard < guardLimit) {
      guard++;
      final axis = rng.nextBool() ? MoveAxis.horizontal : MoveAxis.vertical;
      final length = (cfg.allowTrucks && rng.nextInt(3) == 0) ? 3 : 2;
      final line = rng.nextInt(size);
      final lead = rng.nextInt(size - length + 1);
      final fromStart = rng.nextBool(); // enter from left/top vs right/bottom

      if (!_laneClear(occ, size, axis, line, lead, length, fromStart)) continue;

      final car = Vehicle(
        id: nextId,
        axis: axis,
        length: length,
        line: line,
        lead: lead,
        skinId: nextId,
      );
      _stampBody(occ, size, car);
      cars.add(car);
      nextId++;
    }

    return Board(size: size, cars: cars);
  }

  /// Whether the lane a car would travel through on entry is empty. For a car
  /// entering from the start edge (left/top) the lane is cells 0..(lead+len-1);
  /// from the end edge (right/bottom) it is cells lead..(size-1). The car's body
  /// is included, so this also guarantees no overlap.
  bool _laneClear(
    List<int> occ,
    int size,
    MoveAxis axis,
    int line,
    int lead,
    int length,
    bool fromStart,
  ) {
    final start = fromStart ? 0 : lead;
    final end = fromStart ? lead + length - 1 : size - 1;
    for (var i = start; i <= end; i++) {
      final r = axis == MoveAxis.horizontal ? line : i;
      final c = axis == MoveAxis.horizontal ? i : line;
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
  /// somehow underfills. Three non-overlapping cars on separate lines.
  Board _fallback(DifficultyConfig cfg) {
    final size = cfg.gridSize;
    return Board(
      size: size,
      cars: [
        Vehicle(id: 0, axis: MoveAxis.horizontal, length: 2, line: 0, lead: 0),
        Vehicle(id: 1, axis: MoveAxis.horizontal, length: 2, line: 2, lead: 1),
        Vehicle(id: 2, axis: MoveAxis.vertical, length: 2, line: size - 1, lead: 2),
      ],
    );
  }
}

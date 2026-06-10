import 'package:flow_park_puzzle/game/logic/level_generator.dart';
import 'package:flow_park_puzzle/game/logic/solver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final generator = LevelGenerator();
  const solver = PuzzleSolver();

  group('LevelGenerator — always solvable guarantee', () {
    test('every generated level across the progression is solvable', () {
      // Sample the difficulty curve: early (5x5), mid (6x6/7x7), late (8x8).
      for (final level in [1, 3, 5, 8, 12, 25, 40, 55, 80, 130]) {
        final lvl = generator.generate(level, seed: level * 7919);
        final board = lvl.newBoard();

        expect(board.isSolved, isFalse,
            reason: 'Level $level must not start already solved');

        final result = solver.solve(board);
        expect(result.solvable, isTrue,
            reason: 'Level $level was generated unsolvable');
        expect(result.moveCount, greaterThan(0),
            reason: 'Level $level should require at least one move');
      }
    });

    test('reported optimalMoves matches the solver', () {
      for (final level in [2, 10, 30, 60]) {
        final lvl = generator.generate(level, seed: level * 104729);
        final result = solver.solve(lvl.newBoard());
        expect(result.moveCount, equals(lvl.optimalMoves));
      }
    });

    test('deterministic for a fixed seed', () {
      final a = generator.generate(20, seed: 42);
      final b = generator.generate(20, seed: 42);
      expect(a.initialPositions, equals(b.initialPositions));
      expect(a.gridSize, equals(b.gridSize));
      expect(a.exitRow, equals(b.exitRow));
    });

    test('stress: 40 random levels are all solvable', () {
      for (var i = 0; i < 40; i++) {
        final level = 1 + (i % 30);
        final lvl = generator.generate(level, seed: i * 1_000_003);
        expect(solver.isSolvable(lvl.newBoard()), isTrue,
            reason: 'Random level (#$i, level $level) was unsolvable');
      }
    });
  });
}

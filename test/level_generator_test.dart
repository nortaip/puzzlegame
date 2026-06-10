import 'package:flow_park_puzzle/game/logic/level_generator.dart';
import 'package:flow_park_puzzle/game/logic/solver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final generator = LevelGenerator();
  const solver = PuzzleSolver();

  group('LevelGenerator — every road can be cleared', () {
    test('generated levels across the curve are all clearable', () {
      for (final level in [1, 3, 5, 8, 12, 25, 40, 55, 80, 130]) {
        final lvl = generator.generate(level, seed: level * 7919);
        final board = lvl.newBoard();

        expect(board.isCleared, isFalse,
            reason: 'Level $level must start with cars on the board');
        expect(board.cars.length, greaterThanOrEqualTo(3),
            reason: 'Level $level should have a few cars');
        expect(solver.canClear(board), isTrue,
            reason: 'Level $level produced an unclearable board');
      }
    });

    test('par (optimalMoves) equals the number of cars', () {
      for (final level in [2, 10, 30, 60]) {
        final lvl = generator.generate(level, seed: level * 104729);
        expect(lvl.optimalMoves, equals(lvl.cars.length));
      }
    });

    test('deterministic for a fixed seed', () {
      final a = generator.generate(20, seed: 42);
      final b = generator.generate(20, seed: 42);
      expect(a.cars.length, equals(b.cars.length));
      for (var i = 0; i < a.cars.length; i++) {
        expect(a.cars[i].axis, b.cars[i].axis);
        expect(a.cars[i].line, b.cars[i].line);
        expect(a.cars[i].lead, b.cars[i].lead);
        expect(a.cars[i].length, b.cars[i].length);
      }
    });

    test('stress: 40 random levels are all clearable', () {
      for (var i = 0; i < 40; i++) {
        final level = 1 + (i % 30);
        final lvl = generator.generate(level, seed: i * 1_000_003);
        expect(solver.canClear(lvl.newBoard()), isTrue,
            reason: 'Random level (#$i, level $level) was unclearable');
      }
    });
  });
}

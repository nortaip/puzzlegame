import 'package:flow_park_puzzle/game/logic/solver.dart';
import 'package:flow_park_puzzle/game/models/board.dart';
import 'package:flow_park_puzzle/game/models/direction.dart';
import 'package:flow_park_puzzle/game/models/vehicle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A 6x6 board: a horizontal car on row 2 blocked on its right by a vertical
  // truck in column 3.
  Board build() => Board(
        size: 6,
        cars: const [
          Vehicle(id: 0, axis: MoveAxis.horizontal, length: 2, line: 2, lead: 0),
          Vehicle(id: 1, axis: MoveAxis.vertical, length: 3, line: 3, lead: 0),
        ],
      );

  group('Board — drive-off mechanics', () {
    test('occupancy marks every car cell', () {
      final occ = build().occupancy();
      expect(occ[2 * 6 + 0], 0); // car A
      expect(occ[2 * 6 + 1], 0);
      expect(occ[0 * 6 + 3], 1); // truck B
      expect(occ[2 * 6 + 3], 1);
    });

    test('a car can drive off an open edge but not a jammed one', () {
      final board = build();
      final carA = board.carById(0)!;
      // Left lane is clear; right lane is blocked by the truck in column 3.
      expect(board.canExit(carA, SlideDirection.left), isTrue);
      expect(board.canExit(carA, SlideDirection.right), isFalse);
      expect(board.exitDirections(carA), [SlideDirection.left]);
    });

    test('removing the blocker opens the previously jammed lane', () {
      final board = build().removeCar(1);
      final carA = board.carById(0)!;
      expect(board.canExit(carA, SlideDirection.right), isTrue);
    });

    test('board is cleared only when all cars have left', () {
      var board = build();
      expect(board.isCleared, isFalse);
      board = board.removeCar(0).removeCar(1);
      expect(board.isCleared, isTrue);
    });

    test('vertical truck can exit either open end', () {
      final board = build();
      final truck = board.carById(1)!;
      expect(board.canExit(truck, SlideDirection.up), isTrue);
      expect(board.canExit(truck, SlideDirection.down), isTrue);
    });

    test('solver confirms the board is clearable', () {
      expect(const PuzzleSolver().canClear(build()), isTrue);
    });
  });
}

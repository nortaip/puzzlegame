import 'package:flow_park_puzzle/game/logic/solver.dart';
import 'package:flow_park_puzzle/game/models/board.dart';
import 'package:flow_park_puzzle/game/models/direction.dart';
import 'package:flow_park_puzzle/game/models/vehicle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A 6x6 board: a right-facing car on row 2 is blocked by a down-facing truck
  // in column 3.
  Board build() => Board(
        size: 6,
        cars: const [
          Vehicle(id: 0, length: 2, line: 2, lead: 0, facing: SlideDirection.right),
          Vehicle(id: 1, length: 3, line: 3, lead: 0, facing: SlideDirection.down),
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

    test('a car can only drive off if its arrow lane is clear', () {
      final board = build();
      final carA = board.carById(0)!; // faces right, blocked by the truck
      final truck = board.carById(1)!; // faces down, open lane below
      expect(board.canDriveOff(carA), isFalse);
      expect(board.canDriveOff(truck), isTrue);
    });

    test('removing the blocker opens the previously jammed lane', () {
      final board = build().removeCar(1);
      expect(board.canDriveOff(board.carById(0)!), isTrue);
    });

    test('board is cleared only when all cars have left', () {
      var board = build();
      expect(board.isCleared, isFalse);
      board = board.removeCar(0).removeCar(1);
      expect(board.isCleared, isTrue);
    });

    test('solver confirms the board is clearable (right order)', () {
      expect(const PuzzleSolver().canClear(build()), isTrue);
    });
  });
}

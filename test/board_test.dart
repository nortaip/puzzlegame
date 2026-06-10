import 'package:flow_park_puzzle/game/models/board.dart';
import 'package:flow_park_puzzle/game/models/direction.dart';
import 'package:flow_park_puzzle/game/models/vehicle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A hand-built 6x6 board: target on row 2, blocked by a vertical car.
  Board build() => Board(
        size: 6,
        exitRow: 2,
        vehicles: const [
          Vehicle(id: 0, axis: MoveAxis.horizontal, length: 2, fixedLine: 2, isTarget: true),
          Vehicle(id: 1, axis: MoveAxis.vertical, length: 3, fixedLine: 3),
        ],
        positions: [0, 0],
      );

  group('Board mechanics', () {
    test('occupancy marks all vehicle cells', () {
      final board = build();
      final occ = board.occupancy();
      // Target occupies (2,0) and (2,1).
      expect(occ[2 * 6 + 0], 0);
      expect(occ[2 * 6 + 1], 0);
      // Vertical car occupies col 3, rows 0..2.
      expect(occ[0 * 6 + 3], 1);
      expect(occ[2 * 6 + 3], 1);
    });

    test('target cannot pass through a blocking car', () {
      final board = build();
      // Target occupies cols 0–1; a vertical car sits at col 3 on the exit row,
      // so the target can only slide one cell right (to cols 1–2) before its
      // leading edge would hit the blocker at col 3.
      final maxRight = board.maxSlide(0, SlideDirection.right);
      expect(maxRight, equals(1));
      expect(board.isSolved, isFalse);
    });

    test('win condition triggers when target reaches the exit columns', () {
      final board = Board(
        size: 6,
        exitRow: 2,
        vehicles: const [
          Vehicle(id: 0, axis: MoveAxis.horizontal, length: 2, fixedLine: 2, isTarget: true),
        ],
        positions: [4], // col 4..5 == rightmost
      );
      expect(board.isSolved, isTrue);
    });

    test('legalMoves never includes a move off the grid', () {
      final board = build();
      for (final m in board.legalMoves()) {
        final v = board.vehicles[m.vehicleId];
        final newLead = board.positions[m.vehicleId] + m.steps;
        expect(newLead, greaterThanOrEqualTo(0));
        expect(newLead + v.length - 1, lessThan(board.size));
      }
    });
  });
}

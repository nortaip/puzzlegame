import '../models/board.dart';
import '../models/direction.dart';
import '../models/vehicle.dart';

/// Solver / verifier for the drive-off puzzle.
///
/// Driving a car off the board only ever **frees** cells, so it can never block
/// another car. The set of currently-drivable cars therefore only grows as cars
/// leave — so a simple greedy elimination is *complete*: if a drivable car
/// exists at every step until the board is empty, the level is solvable.
class PuzzleSolver {
  const PuzzleSolver();

  /// True if every car can be driven off the board.
  bool canClear(Board start) {
    var board = start.clone();
    while (!board.isCleared) {
      final next = _anyDrivable(board);
      if (next == null) return false; // deadlocked with cars remaining
      board = board.removeCar(next.id);
    }
    return true;
  }

  bool isSolvable(Board start) => canClear(start);

  /// The id of the most obvious car to drive off next (nearest its border), for
  /// the Hint power-up; null if none can currently move.
  int? bestNextCar(Board start) {
    Vehicle? best;
    var bestDistance = 1 << 30;
    for (final car in start.cars) {
      if (!start.canDriveOff(car)) continue;
      final distance = _distanceToBorder(start.size, car);
      if (distance < bestDistance) {
        bestDistance = distance;
        best = car;
      }
    }
    return best?.id;
  }

  Vehicle? _anyDrivable(Board board) {
    for (final car in board.cars) {
      if (board.canDriveOff(car)) return car;
    }
    return null;
  }

  int _distanceToBorder(int size, Vehicle car) {
    switch (car.facing) {
      case SlideDirection.left:
      case SlideDirection.up:
        return car.lead;
      case SlideDirection.right:
      case SlideDirection.down:
        return size - (car.lead + car.length);
    }
  }
}

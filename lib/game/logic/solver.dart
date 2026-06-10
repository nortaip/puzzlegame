import '../models/board.dart';
import '../models/direction.dart';
import '../models/vehicle.dart';

/// A single suggested exit move: drive car [carId] off toward [direction].
class ExitMove {
  const ExitMove(this.carId, this.direction);
  final int carId;
  final SlideDirection direction;
}

/// Solver / verifier for "open the road" mode.
///
/// Driving a car off the board only ever **frees** cells, so it can never make
/// another car non-exitable. That means the set of currently-exitable cars only
/// grows as cars leave — so a simple greedy elimination is *complete*: if any
/// removable car exists at every step until the board is empty, the level is
/// solvable; otherwise it is not. No exponential search is required.
class PuzzleSolver {
  const PuzzleSolver();

  /// True if every car can be driven off the board.
  bool canClear(Board start) {
    var board = start.clone();
    while (!board.isCleared) {
      final next = _anyExitable(board);
      if (next == null) return false; // deadlocked with cars remaining
      board = board.removeCar(next.id);
    }
    return true;
  }

  bool isSolvable(Board start) => canClear(start);

  /// The best next move to surface as a Hint: prefer the car nearest a border
  /// (the most obvious one), so the hint feels natural.
  ExitMove? bestNextMove(Board start) {
    Vehicle? bestCar;
    SlideDirection? bestDir;
    var bestDistance = 1 << 30;

    for (final car in start.cars) {
      for (final dir in start.exitDirections(car)) {
        final distance = _distanceToBorder(start.size, car, dir);
        if (distance < bestDistance) {
          bestDistance = distance;
          bestCar = car;
          bestDir = dir;
        }
      }
    }
    if (bestCar == null) return null;
    return ExitMove(bestCar.id, bestDir!);
  }

  Vehicle? _anyExitable(Board board) {
    for (final car in board.cars) {
      if (board.exitDirections(car).isNotEmpty) return car;
    }
    return null;
  }

  int _distanceToBorder(int size, Vehicle car, SlideDirection dir) {
    switch (dir) {
      case SlideDirection.left:
        return car.lead;
      case SlideDirection.up:
        return car.lead;
      case SlideDirection.right:
        return size - (car.lead + car.length);
      case SlideDirection.down:
        return size - (car.lead + car.length);
    }
  }
}

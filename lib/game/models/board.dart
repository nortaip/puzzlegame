import 'direction.dart';
import 'vehicle.dart';

/// The parking-grid state for "open the road" mode: a set of parked [cars]. The
/// puzzle is solved when every car has driven off the board ([isCleared]).
class Board {
  Board({required this.size, required this.cars});

  final int size;

  /// The cars still parked on the board. Driving a car off removes it.
  final List<Vehicle> cars;

  Board clone() => Board(size: size, cars: List<Vehicle>.of(cars));

  bool get isCleared => cars.isEmpty;

  Vehicle? carById(int id) {
    for (final c in cars) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Occupancy grid: each cell holds a car id, or -1 when empty.
  List<int> occupancy() {
    final grid = List<int>.filled(size * size, -1);
    for (final c in cars) {
      for (var i = 0; i < c.length; i++) {
        grid[c.cellRow(i) * size + c.cellCol(i)] = c.id;
      }
    }
    return grid;
  }

  /// Whether [car] has a clear path to the border in [direction] and can drive
  /// off that way. The direction must match the car's movement axis.
  bool canExit(Vehicle car, SlideDirection direction) {
    if (car.axis != direction.axis) return false;
    final grid = occupancy();

    bool free(int r, int c) => grid[r * size + c] == -1;

    switch (direction) {
      case SlideDirection.right:
        for (var c = car.lead + car.length; c < size; c++) {
          if (!free(car.line, c)) return false;
        }
        return true;
      case SlideDirection.left:
        for (var c = car.lead - 1; c >= 0; c--) {
          if (!free(car.line, c)) return false;
        }
        return true;
      case SlideDirection.down:
        for (var r = car.lead + car.length; r < size; r++) {
          if (!free(r, car.line)) return false;
        }
        return true;
      case SlideDirection.up:
        for (var r = car.lead - 1; r >= 0; r--) {
          if (!free(r, car.line)) return false;
        }
        return true;
    }
  }

  /// The directions (one or both ends of the car's axis) it can currently exit.
  List<SlideDirection> exitDirections(Vehicle car) {
    final dirs = car.isHorizontal
        ? const [SlideDirection.left, SlideDirection.right]
        : const [SlideDirection.up, SlideDirection.down];
    return [for (final d in dirs) if (canExit(car, d)) d];
  }

  /// A new board with car [id] removed (driven off).
  Board removeCar(int id) =>
      Board(size: size, cars: [for (final c in cars) if (c.id != id) c]);
}

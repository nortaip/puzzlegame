import 'direction.dart';
import 'vehicle.dart';

/// The parking-grid state: a set of parked [cars], each of which can only drive
/// in its own [Vehicle.facing] direction. The puzzle is solved when every car
/// has driven off the board ([isCleared]).
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

  /// Whether the lane in front of [car] (its [Vehicle.facing] direction) is
  /// clear all the way to the border, so it can drive off.
  bool canDriveOff(Vehicle car) => _laneClear(car, car.facing);

  bool _laneClear(Vehicle car, SlideDirection direction) {
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

  /// A new board with car [id] removed (driven off).
  Board removeCar(int id) =>
      Board(size: size, cars: [for (final c in cars) if (c.id != id) c]);
}

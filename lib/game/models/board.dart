import 'direction.dart';
import 'vehicle.dart';

/// The parking-grid state: a set of parked [cars], each of which can only drive
/// in its own [Vehicle.facing] direction. The puzzle is solved when every car
/// has driven off the board ([isCleared]).
class Board {
  Board({required this.size, required this.cars, this.trees = const []});

  final int size;

  /// The cars still parked on the board. Driving a car off removes it.
  final List<Vehicle> cars;

  /// Static roadside-tree obstacles, as cell indices (`row * size + col`). They
  /// never move and permanently block any lane that passes through them — used
  /// to close off some exits and make levels harder. The generator guarantees
  /// no car's exit lane ever crosses a tree, so the board stays solvable.
  final List<int> trees;

  Board clone() =>
      Board(size: size, cars: List<Vehicle>.of(cars), trees: trees);

  bool get isCleared => cars.isEmpty;

  /// Marker stored in the occupancy grid for a tree cell.
  static const int treeCell = -2;

  Vehicle? carById(int id) {
    for (final c in cars) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Occupancy grid: each cell holds a car id, [treeCell] for a tree, or -1 when
  /// empty. Only -1 counts as a clear lane cell.
  List<int> occupancy() {
    final grid = List<int>.filled(size * size, -1);
    for (final t in trees) {
      grid[t] = treeCell;
    }
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

  /// A new board with car [id] removed (driven off). Trees are preserved.
  Board removeCar(int id) => Board(
        size: size,
        cars: [for (final c in cars) if (c.id != id) c],
        trees: trees,
      );
}

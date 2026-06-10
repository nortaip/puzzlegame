import 'direction.dart';
import 'vehicle.dart';

/// A single legal slide: vehicle [vehicleId] moves [steps] cells along its axis.
/// Positive steps == right/down, negative == left/up.
class VehicleMove {
  const VehicleMove(this.vehicleId, this.steps);
  final int vehicleId;
  final int steps;
}

/// The mutable parking-grid state.
///
/// Static vehicle metadata lives in [vehicles]; the only mutable data is
/// [positions] — the variable coordinate of each vehicle (column if
/// horizontal, row if vertical). This keeps state-space search cheap: a board
/// state is fully described by the small [positions] list.
class Board {
  Board({
    required this.size,
    required this.exitRow,
    required this.vehicles,
    required this.positions,
  }) : assert(vehicles.length == positions.length);

  final int size;

  /// The row aligned with the exit gap on the right border. The target vehicle
  /// is horizontal on this row and wins by reaching the rightmost columns.
  final int exitRow;

  final List<Vehicle> vehicles;

  /// `positions[id]` is the vehicle's leading (top/left) mutable coordinate.
  final List<int> positions;

  int get targetId => vehicles.firstWhere((v) => v.isTarget).id;

  Board clone() => Board(
        size: size,
        exitRow: exitRow,
        vehicles: vehicles,
        positions: List<int>.of(positions),
      );

  /// Leading coordinate for a vehicle (column if horizontal, row if vertical).
  int leadOf(int id) => positions[id];

  /// Builds an occupancy grid: each cell holds a vehicle id or -1 when empty.
  List<int> occupancy() {
    final grid = List<int>.filled(size * size, -1);
    for (final v in vehicles) {
      final lead = positions[v.id];
      for (var i = 0; i < v.length; i++) {
        final r = v.isHorizontal ? v.fixedLine : lead + i;
        final c = v.isHorizontal ? lead + i : v.fixedLine;
        grid[r * size + c] = v.id;
      }
    }
    return grid;
  }

  bool get isSolved {
    final t = vehicles[targetId];
    return positions[targetId] == size - t.length;
  }

  /// All legal single-vehicle slides reachable from the current state. Each
  /// distinct destination cell counts as one move (classic Rush Hour metric).
  List<VehicleMove> legalMoves() {
    final grid = occupancy();
    final moves = <VehicleMove>[];
    for (final v in vehicles) {
      if (v.isLocked) continue;
      final lead = positions[v.id];

      // Slide toward the negative direction (left / up).
      for (var step = 1;; step++) {
        final newLead = lead - step;
        if (newLead < 0) break;
        final r = v.isHorizontal ? v.fixedLine : newLead;
        final c = v.isHorizontal ? newLead : v.fixedLine;
        if (grid[r * size + c] != -1) break;
        moves.add(VehicleMove(v.id, -step));
      }

      // Slide toward the positive direction (right / down).
      for (var step = 1;; step++) {
        final newLead = lead + step;
        final tail = newLead + v.length - 1;
        if (tail >= size) break;
        final r = v.isHorizontal ? v.fixedLine : tail;
        final c = v.isHorizontal ? tail : v.fixedLine;
        if (grid[r * size + c] != -1) break;
        moves.add(VehicleMove(v.id, step));
      }
    }
    return moves;
  }

  /// How far (signed) a vehicle may slide in [direction] right now. 0 = blocked.
  int maxSlide(int vehicleId, SlideDirection direction) {
    final v = vehicles[vehicleId];
    if (v.isLocked) return 0;
    if (v.axis != direction.axis) return 0;
    final grid = occupancy();
    final lead = positions[vehicleId];
    final sign = direction.delta;
    var reachable = 0;
    for (var step = 1;; step++) {
      final newLead = lead + sign * step;
      if (newLead < 0) break;
      final tail = newLead + v.length - 1;
      if (tail >= size) break;
      // The newly entered cell is the leading edge in the travel direction.
      final probe = sign > 0 ? tail : newLead;
      final r = v.isHorizontal ? v.fixedLine : probe;
      final c = v.isHorizontal ? probe : v.fixedLine;
      if (grid[r * size + c] != -1) break;
      reachable = step;
    }
    return reachable * sign;
  }

  /// Applies a slide in place (no validation — callers pre-validate).
  void applyMove(VehicleMove move) {
    positions[move.vehicleId] += move.steps;
  }

  /// Compact, comparable encoding of the mutable state for visited-set hashing.
  String encode() => positions.join(',');
}

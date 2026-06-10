import 'direction.dart';

/// The kinds of vehicle, each with the number of cells it occupies. Longer
/// vehicles (minivan / bus / truck) make jams harder and appear at higher levels.
enum VehicleType {
  car(2),
  minivan(3),
  bus(4),
  truck(4);

  const VehicleType(this.length);
  final int length;
}

/// A vehicle parked on the grid. Each one has a single fixed [facing] direction
/// (shown as an arrow): tapping it drives it forward that way until it leaves
/// the board. It never reverses or repositions, so its location
/// ([line] + [lead]) is immutable.
///
/// Coordinates:
///   • horizontal → occupies row [line], columns [lead] .. [lead]+[length]-1
///   • vertical   → occupies column [line], rows [lead] .. [lead]+[length]-1
class Vehicle {
  const Vehicle({
    required this.id,
    required this.length,
    required this.line,
    required this.lead,
    required this.facing,
    this.type = VehicleType.car,
    this.skinId = 0,
  });

  /// Stable, never-reused identifier (used as an animation key).
  final int id;

  /// Number of cells the car occupies (2 = car, 3 = truck).
  final int length;

  /// Fixed cross-axis line: the row for a horizontal car, the column for a
  /// vertical one.
  final int line;

  /// Leading (top/left) cell along the movement axis.
  final int lead;

  /// The single direction this car can drive (its arrow).
  final SlideDirection facing;

  /// Visual kind (car / minivan / bus / truck). Determines how it is drawn.
  final VehicleType type;

  /// Index into the active palette (cosmetic only).
  final int skinId;

  MoveAxis get axis => facing.axis;
  bool get isHorizontal => axis == MoveAxis.horizontal;

  /// Row of the car's i-th body cell.
  int cellRow(int i) => isHorizontal ? line : lead + i;

  /// Column of the car's i-th body cell.
  int cellCol(int i) => isHorizontal ? lead + i : line;

  Vehicle copyWith({int? id, int? skinId}) => Vehicle(
        id: id ?? this.id,
        length: length,
        line: line,
        lead: lead,
        facing: facing,
        type: type,
        skinId: skinId ?? this.skinId,
      );

  @override
  String toString() =>
      'Vehicle(id:$id, ${isHorizontal ? "H" : "V"}, len:$length, '
      'line:$line, lead:$lead, facing:$facing)';
}

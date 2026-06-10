import 'direction.dart';

/// A car parked on the grid. Each car has a single fixed [facing] direction
/// (shown as an arrow): tapping it drives it forward that way until it leaves
/// the board. It never reverses or repositions, so its location
/// ([line] + [lead]) is immutable.
///
/// Coordinates:
///   • horizontal car → occupies row [line], columns [lead] .. [lead]+[length]-1
///   • vertical car   → occupies column [line], rows [lead] .. [lead]+[length]-1
class Vehicle {
  const Vehicle({
    required this.id,
    required this.length,
    required this.line,
    required this.lead,
    required this.facing,
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
        skinId: skinId ?? this.skinId,
      );

  @override
  String toString() =>
      'Vehicle(id:$id, ${isHorizontal ? "H" : "V"}, len:$length, '
      'line:$line, lead:$lead, facing:$facing)';
}

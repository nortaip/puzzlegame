import 'direction.dart';

/// A car parked on the grid. In "open the road" mode a car never repositions —
/// it sits at a fixed location until the player drives it off an open edge — so
/// its full position ([line] + [lead]) is immutable.
///
/// Coordinates:
///   • horizontal car → occupies row [line], columns [lead] .. [lead]+[length]-1
///   • vertical car   → occupies column [line], rows [lead] .. [lead]+[length]-1
class Vehicle {
  const Vehicle({
    required this.id,
    required this.axis,
    required this.length,
    required this.line,
    required this.lead,
    this.skinId = 0,
  });

  /// Stable, never-reused identifier (used as an animation key).
  final int id;

  final MoveAxis axis;

  /// Number of cells the car occupies (2 = car, 3 = truck).
  final int length;

  /// Fixed cross-axis line: the row for a horizontal car, the column for a
  /// vertical one.
  final int line;

  /// Leading (top/left) cell along the movement axis.
  final int lead;

  /// Index into the active palette (cosmetic only).
  final int skinId;

  bool get isHorizontal => axis == MoveAxis.horizontal;

  /// Row of the car's i-th body cell.
  int cellRow(int i) => isHorizontal ? line : lead + i;

  /// Column of the car's i-th body cell.
  int cellCol(int i) => isHorizontal ? lead + i : line;

  Vehicle copyWith({int? id, int? skinId}) => Vehicle(
        id: id ?? this.id,
        axis: axis,
        length: length,
        line: line,
        lead: lead,
        skinId: skinId ?? this.skinId,
      );

  @override
  String toString() =>
      'Vehicle(id:$id, ${isHorizontal ? "H" : "V"}, len:$length, '
      'line:$line, lead:$lead)';
}

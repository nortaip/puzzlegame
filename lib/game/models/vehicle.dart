import 'direction.dart';

/// A static description of a vehicle on the board.
///
/// The board stores the *mutable* coordinate (the column for a horizontal
/// vehicle, the row for a vertical one) separately in [Board.positions], so a
/// [Vehicle] instance is immutable and cheap to share between board states.
class Vehicle {
  const Vehicle({
    required this.id,
    required this.axis,
    required this.length,
    required this.fixedLine,
    this.isTarget = false,
    this.isLocked = false,
    this.skinId = 0,
  });

  /// Stable identifier; index into the board's position list.
  final int id;

  final MoveAxis axis;

  /// Number of cells the vehicle occupies (2 = car, 3 = truck).
  final int length;

  /// For a horizontal vehicle this is its row; for a vertical one, its column.
  /// It never changes — the vehicle only slides along its [axis].
  final int fixedLine;

  /// The vehicle the player must drive to the exit.
  final bool isTarget;

  /// Locked vehicles cannot move until freed by the Police power-up.
  final bool isLocked;

  /// Index into the active skin catalogue (cosmetic only).
  final int skinId;

  bool get isHorizontal => axis == MoveAxis.horizontal;

  Vehicle copyWith({int? id, bool? isLocked, int? skinId}) => Vehicle(
        id: id ?? this.id,
        axis: axis,
        length: length,
        fixedLine: fixedLine,
        isTarget: isTarget,
        isLocked: isLocked ?? this.isLocked,
        skinId: skinId ?? this.skinId,
      );

  @override
  String toString() =>
      'Vehicle(id:$id, ${isHorizontal ? "H" : "V"}, len:$length, '
      'line:$fixedLine${isTarget ? ", TARGET" : ""})';
}

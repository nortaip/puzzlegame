/// Movement directions for vehicles on the parking grid.
enum MoveAxis { horizontal, vertical }

enum SlideDirection {
  up,
  down,
  left,
  right;

  MoveAxis get axis =>
      (this == SlideDirection.left || this == SlideDirection.right)
          ? MoveAxis.horizontal
          : MoveAxis.vertical;

  /// Signed delta applied to a vehicle's mutable coordinate.
  int get delta =>
      (this == SlideDirection.left || this == SlideDirection.up) ? -1 : 1;
}

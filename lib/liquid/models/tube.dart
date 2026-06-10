/// A single test tube in the liquid-sort puzzle. Colors are stored bottom-first
/// (index 0 is the bottom of the tube).
class Tube {
  Tube({required this.capacity, List<int>? colors})
      : colors = colors ?? <int>[];

  final int capacity;

  /// Color ids, bottom (0) to top. Length <= capacity.
  final List<int> colors;

  bool get isEmpty => colors.isEmpty;
  bool get isFull => colors.length == capacity;
  int? get top => colors.isEmpty ? null : colors.last;

  /// Number of identical colors stacked on top (the pourable run).
  int get topRun {
    if (colors.isEmpty) return 0;
    final c = colors.last;
    var n = 0;
    for (var i = colors.length - 1; i >= 0 && colors[i] == c; i--) {
      n++;
    }
    return n;
  }

  int get freeSpace => capacity - colors.length;

  /// A tube is "complete" when empty or filled with a single color.
  bool get isComplete =>
      isEmpty || (isFull && colors.every((c) => c == colors.first));

  Tube clone() => Tube(capacity: capacity, colors: List<int>.of(colors));
}

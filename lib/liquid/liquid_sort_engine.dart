import 'dart:collection';
import 'dart:math';

import 'models/tube.dart';

/// A legal pour: move the top run from tube [from] to tube [to].
class Pour {
  const Pour(this.from, this.to);
  final int from;
  final int to;
}

/// Pure logic for the liquid-sort (water sort) puzzle: pour rules, a solver, and
/// a guaranteed-solvable generator.
class LiquidSortEngine {
  const LiquidSortEngine({this.maxStates = 120000});

  /// Search cap so the solver can't hang on pathological inputs.
  final int maxStates;

  // ── Rules ──────────────────────────────────────────────────────────────────
  bool canPour(Tube from, Tube to) {
    if (from.isEmpty || to.isFull) return false;
    if (identical(from, to)) return false;
    if (to.isEmpty) return true;
    return from.top == to.top;
  }

  /// Pours the whole top run (capped by free space). Returns units moved.
  int pour(Tube from, Tube to) {
    if (!canPour(from, to)) return 0;
    final color = from.top!;
    final amount = min(from.topRun, to.freeSpace);
    for (var i = 0; i < amount; i++) {
      from.colors.removeLast();
      to.colors.add(color);
    }
    return amount;
  }

  bool isSolved(List<Tube> tubes) => tubes.every((t) => t.isComplete);

  // ── Solver ───────────────────────────────────────────────────────────────
  String _encode(List<Tube> tubes) {
    // Sort tube signatures so permutations of identical tubes hash equally —
    // this dramatically shrinks the search space.
    final sigs = [for (final t in tubes) t.colors.join('.')]..sort();
    return sigs.join('|');
  }

  List<Pour> _legalPours(List<Tube> tubes) {
    final moves = <Pour>[];
    for (var i = 0; i < tubes.length; i++) {
      for (var j = 0; j < tubes.length; j++) {
        if (i == j) continue;
        if (!canPour(tubes[i], tubes[j])) continue;
        // Pruning: never pour a single-color full-or-partial tube into empty
        // (pointless shuffle), and skip pouring into an identical empty when a
        // matching non-empty exists is handled implicitly by dedup.
        if (tubes[j].isEmpty && tubes[i].topRun == tubes[i].colors.length) {
          continue; // moving a whole tube to an empty tube is never progress
        }
        moves.add(Pour(i, j));
      }
    }
    return moves;
  }

  bool isSolvable(List<Tube> tubes) {
    if (isSolved(tubes)) return true;
    final start = [for (final t in tubes) t.clone()];
    final visited = HashSet<String>()..add(_encode(start));
    final stack = ListQueue<List<Tube>>()..add(start);
    var explored = 0;

    while (stack.isNotEmpty) {
      if (explored++ > maxStates) return false;
      final state = stack.removeLast();
      for (final m in _legalPours(state)) {
        final next = [for (final t in state) t.clone()];
        pour(next[m.from], next[m.to]);
        if (isSolved(next)) return true;
        if (visited.add(_encode(next))) stack.add(next);
      }
    }
    return false;
  }

  // ── Generator ──────────────────────────────────────────────────────────────
  /// Generates an always-solvable puzzle by randomly distributing a balanced
  /// multiset of colors and verifying solvability with [isSolvable], retrying
  /// until a non-trivial solvable layout is found.
  List<Tube> generate({
    required int colorCount,
    int capacity = 4,
    int emptyTubes = 2,
    int? seed,
  }) {
    final rng = Random(seed ?? DateTime.now().microsecondsSinceEpoch);

    for (var attempt = 0; attempt < 500; attempt++) {
      final pool = <int>[
        for (var c = 0; c < colorCount; c++)
          for (var k = 0; k < capacity; k++) c,
      ]..shuffle(rng);

      final tubes = <Tube>[];
      var idx = 0;
      for (var t = 0; t < colorCount; t++) {
        tubes.add(Tube(
          capacity: capacity,
          colors: pool.sublist(idx, idx + capacity),
        ));
        idx += capacity;
      }
      for (var e = 0; e < emptyTubes; e++) {
        tubes.add(Tube(capacity: capacity));
      }

      if (isSolved(tubes)) continue; // too easy
      if (isSolvable(tubes)) return tubes;
    }

    // Fallback: the solved state with one swapped pair is trivially solvable.
    return _trivial(colorCount, capacity, emptyTubes);
  }

  List<Tube> _trivial(int colorCount, int capacity, int emptyTubes) {
    final tubes = <Tube>[
      for (var c = 0; c < colorCount; c++)
        Tube(capacity: capacity, colors: List<int>.filled(capacity, c)),
      for (var e = 0; e < emptyTubes; e++) Tube(capacity: capacity),
    ];
    // Move one unit out so it isn't already solved but remains solvable.
    if (colorCount > 0 && emptyTubes > 0) {
      pour(tubes[0], tubes.last);
    }
    return tubes;
  }
}

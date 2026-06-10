import 'dart:collection';

import '../models/board.dart';

/// Result of a breadth-first search over board states.
class SolveResult {
  const SolveResult({required this.solvable, required this.moves});

  final bool solvable;

  /// Optimal sequence of slides from the start state to a solved state.
  /// Empty when already solved or unsolvable.
  final List<VehicleMove> moves;

  int get moveCount => moves.length;
}

/// Breadth-first solver for the parking puzzle.
///
/// BFS over the (small) position-encoded state space guarantees the *optimal*
/// (minimum-move) solution, which we use both to validate generated levels and
/// to power the Hint power-up. A node cap keeps worst-case time bounded.
class PuzzleSolver {
  const PuzzleSolver({this.maxStates = 200000});

  /// Safety valve so pathological boards can't hang the generator.
  final int maxStates;

  SolveResult solve(Board start) {
    if (start.isSolved) {
      return const SolveResult(solvable: true, moves: <VehicleMove>[]);
    }

    final visited = HashSet<String>()..add(start.encode());
    final queue = Queue<_Node>()..add(_Node(start, const []));
    var explored = 0;

    while (queue.isNotEmpty) {
      if (explored++ > maxStates) break;
      final node = queue.removeFirst();
      final board = node.board;

      for (final move in board.legalMoves()) {
        final next = board.clone()..applyMove(move);
        final key = next.encode();
        if (!visited.add(key)) continue;

        final path = List<VehicleMove>.of(node.path)..add(move);
        if (next.isSolved) {
          return SolveResult(solvable: true, moves: path);
        }
        queue.add(_Node(next, path));
      }
    }
    return const SolveResult(solvable: false, moves: <VehicleMove>[]);
  }

  /// Convenience: the single best next move, or null if none/solved.
  VehicleMove? bestNextMove(Board start) {
    final result = solve(start);
    return result.moves.isEmpty ? null : result.moves.first;
  }

  bool isSolvable(Board start) => solve(start).solvable;
}

class _Node {
  const _Node(this.board, this.path);
  final Board board;
  final List<VehicleMove> path;
}

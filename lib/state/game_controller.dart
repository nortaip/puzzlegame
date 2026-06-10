import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/haptics.dart';
import '../game/logic/solver.dart';
import '../game/models/board.dart';
import '../game/models/direction.dart';
import '../game/models/level.dart';
import '../game/models/vehicle.dart';
import '../game/themes/environment_theme.dart';
import '../services/storage/models/level_progress.dart';
import 'player_controller.dart';
import 'providers.dart';

enum GameStatus { loading, playing, won }

/// Immutable snapshot of an in-progress puzzle. The widget tree rebuilds from
/// this; vehicle widgets animate between successive [positions].
class GameState {
  const GameState({
    required this.status,
    required this.level,
    required this.board,
    required this.moveCount,
    required this.theme,
    this.selectedVehicleId,
    this.hintMove,
    this.lastMovedVehicleId,
  });

  final GameStatus status;
  final Level level;
  final Board board;
  final int moveCount;
  final EnvironmentTheme theme;
  final int? selectedVehicleId;
  final VehicleMove? hintMove;
  final int? lastMovedVehicleId;

  List<Vehicle> get vehicles => board.vehicles;
  int get optimalMoves => level.optimalMoves;

  int get stars {
    if (moveCount <= (optimalMoves * AppConstants.threeStarFactor).ceil()) {
      return 3;
    }
    if (moveCount <= (optimalMoves * AppConstants.twoStarFactor).ceil()) {
      return 2;
    }
    return 1;
  }

  GameState copyWith({
    GameStatus? status,
    Board? board,
    int? moveCount,
    int? Function()? selectedVehicleId,
    VehicleMove? Function()? hintMove,
    int? lastMovedVehicleId,
  }) {
    return GameState(
      status: status ?? this.status,
      level: level,
      board: board ?? this.board,
      moveCount: moveCount ?? this.moveCount,
      theme: theme,
      selectedVehicleId:
          selectedVehicleId != null ? selectedVehicleId() : this.selectedVehicleId,
      hintMove: hintMove != null ? hintMove() : this.hintMove,
      lastMovedVehicleId: lastMovedVehicleId ?? this.lastMovedVehicleId,
    );
  }
}

/// Drives a single puzzle session: applies player moves, runs power-ups, and
/// detects the win condition.
class GameController extends Notifier<GameState?> {
  final PuzzleSolver _solver = const PuzzleSolver();

  @override
  GameState? build() => null;

  void loadLevel(Level level) {
    final theme = EnvironmentTheme.byIndex(level.themeIndex);
    state = GameState(
      status: GameStatus.playing,
      level: level,
      board: level.newBoard(),
      moveCount: 0,
      theme: theme,
    );
    ref.read(analyticsServiceProvider).levelStarted(level.number);
  }

  /// Instant restart — re-seeds the board from the level's initial positions
  /// without any regeneration or loading.
  void restart() {
    final s = state;
    if (s == null) return;
    Haptics.light();
    state = GameState(
      status: GameStatus.playing,
      level: s.level,
      board: s.level.newBoard(),
      moveCount: 0,
      theme: s.theme,
    );
  }

  void selectVehicle(int? id) {
    final s = state;
    if (s == null) return;
    state = s.copyWith(selectedVehicleId: () => id, hintMove: () => null);
  }

  /// Slides [vehicleId] toward [direction] as far as the player dragged
  /// ([requestedSteps] cells), clamped to what is physically legal. Returns the
  /// number of cells actually moved (0 if blocked).
  int moveVehicle(int vehicleId, SlideDirection direction, int requestedSteps) {
    final s = state;
    if (s == null || s.status != GameStatus.playing) return 0;

    final maxSigned = s.board.maxSlide(vehicleId, direction); // signed
    if (maxSigned == 0) {
      Haptics.error();
      return 0;
    }
    final sign = direction.delta;
    final allowed = maxSigned.abs();
    final steps = min(requestedSteps.abs(), allowed) * sign;
    if (steps == 0) return 0;

    final next = s.board.clone()..applyMove(VehicleMove(vehicleId, steps));
    Haptics.selection();

    final won = next.isSolved;
    state = s.copyWith(
      board: next,
      moveCount: s.moveCount + 1,
      lastMovedVehicleId: vehicleId,
      hintMove: () => null,
      selectedVehicleId: () => null,
      status: won ? GameStatus.won : GameStatus.playing,
    );
    if (won) _onWin();
    return steps.abs();
  }

  void _onWin() {
    final s = state!;
    Haptics.success();
    final player = ref.read(playerControllerProvider.notifier);
    player.grantLevelReward(s.stars);
    player.advanceLevel(s.level.number);
    ref.read(analyticsServiceProvider)
        .levelCompleted(s.level.number, s.moveCount, s.stars);
    _recordResult(s);
  }

  /// Persists a per-level result (best moves / stars) to Isar for the level map
  /// and cloud sync. Fire-and-forget; never blocks the win animation.
  Future<void> _recordResult(GameState s) async {
    final isar = ref.read(isarServiceProvider);
    final existing = await isar.progressFor(s.level.number);
    final score = max(0, 1000 - s.moveCount * 5) + s.stars * 100;
    final progress = existing ?? (LevelProgress()..levelNumber = s.level.number);
    if (progress.bestMoves == 0 || s.moveCount < progress.bestMoves) {
      progress.bestMoves = s.moveCount;
    }
    progress.stars = max(progress.stars, s.stars);
    progress.bestScore = max(progress.bestScore, score);
    progress.synced = false;
    await isar.saveProgress(progress);
  }

  // ── Power-ups ──────────────────────────────────────────────────────────────

  /// Hint: highlight the optimal next move. Caller is responsible for paying
  /// (coins or rewarded ad) before invoking.
  void showHint() {
    final s = state;
    if (s == null) return;
    final best = _solver.bestNextMove(s.board);
    if (best == null) return;
    state = s.copyWith(hintMove: () => best, selectedVehicleId: () => best.vehicleId);
    ref.read(analyticsServiceProvider).powerUpUsed('hint');
  }

  /// Police: removes one blocking, non-target vehicle. Keeps the puzzle
  /// solvable (removal only frees space). Returns false if nothing to remove.
  bool usePolice({int? vehicleId}) {
    final s = state;
    if (s == null) return false;
    final removable = s.vehicles.where((v) => !v.isTarget).toList();
    if (removable.isEmpty) return false;

    final victim = vehicleId != null
        ? s.vehicles[vehicleId]
        : _bestPoliceTarget(s.board);
    if (victim == null || victim.isTarget) return false;

    final newVehicles = <Vehicle>[];
    final newPositions = <int>[];
    for (final v in s.vehicles) {
      if (v.id == victim.id) continue;
      // Re-id sequentially so vehicles stay index-aligned with positions.
      newVehicles.add(v.copyWith(id: newVehicles.length));
      newPositions.add(s.board.positions[v.id]);
    }
    final board = Board(
      size: s.board.size,
      exitRow: s.board.exitRow,
      vehicles: newVehicles,
      positions: newPositions,
    );
    state = s.copyWith(board: board, selectedVehicleId: () => null, hintMove: () => null);
    ref.read(analyticsServiceProvider).powerUpUsed('police');
    return true;
  }

  /// Picks the most impactful car to remove: prefer one on the exit row that
  /// blocks the target, otherwise any non-target car.
  Vehicle? _bestPoliceTarget(Board board) {
    final onExitRow = board.vehicles.where((v) =>
        !v.isTarget &&
        ((v.isHorizontal && v.fixedLine == board.exitRow) ||
            (!v.isHorizontal &&
                board.positions[v.id] <= board.exitRow &&
                board.positions[v.id] + v.length - 1 >= board.exitRow)));
    if (onExitRow.isNotEmpty) return onExitRow.first;
    final others = board.vehicles.where((v) => !v.isTarget);
    return others.isEmpty ? null : others.first;
  }

  /// Shuffle: re-randomises positions of non-essential cars while keeping the
  /// board solvable (re-runs the solver and retries on failure).
  bool useShuffle() {
    final s = state;
    if (s == null) return false;
    final rng = Random();
    for (var attempt = 0; attempt < 60; attempt++) {
      final candidate = _shuffleCandidate(s.board, rng);
      if (candidate == null) continue;
      if (candidate.isSolved) continue;
      if (_solver.isSolvable(candidate)) {
        state = s.copyWith(
          board: candidate,
          selectedVehicleId: () => null,
          hintMove: () => null,
        );
        ref.read(analyticsServiceProvider).powerUpUsed('shuffle');
        return true;
      }
    }
    return false;
  }

  Board? _shuffleCandidate(Board board, Random rng) {
    final size = board.size;
    final occ = List<int>.filled(size * size, -1);
    final positions = List<int>.of(board.positions);

    // Keep the target fixed, then place each other vehicle at a random legal
    // line position, one at a time, rejecting overlaps.
    final target = board.vehicles[board.targetId];
    _stamp(occ, size, target, positions[target.id]);

    final others = board.vehicles.where((v) => !v.isTarget).toList()..shuffle(rng);
    for (final v in others) {
      final maxLead = size - v.length;
      var placed = false;
      final order = [for (var i = 0; i <= maxLead; i++) i]..shuffle(rng);
      for (final lead in order) {
        if (_fits(occ, size, v, lead)) {
          _stamp(occ, size, v, lead);
          positions[v.id] = lead;
          placed = true;
          break;
        }
      }
      if (!placed) return null;
    }
    return Board(
      size: size,
      exitRow: board.exitRow,
      vehicles: board.vehicles,
      positions: positions,
    );
  }

  bool _fits(List<int> occ, int size, Vehicle v, int lead) {
    for (var i = 0; i < v.length; i++) {
      final r = v.isHorizontal ? v.fixedLine : lead + i;
      final c = v.isHorizontal ? lead + i : v.fixedLine;
      if (occ[r * size + c] != -1) return false;
    }
    return true;
  }

  void _stamp(List<int> occ, int size, Vehicle v, int lead) {
    for (var i = 0; i < v.length; i++) {
      final r = v.isHorizontal ? v.fixedLine : lead + i;
      final c = v.isHorizontal ? lead + i : v.fixedLine;
      occ[r * size + c] = v.id;
    }
  }
}

final gameControllerProvider =
    NotifierProvider<GameController, GameState?>(GameController.new);

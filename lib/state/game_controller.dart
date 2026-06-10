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

/// Immutable snapshot of an in-progress "open the road" puzzle.
class GameState {
  const GameState({
    required this.status,
    required this.level,
    required this.board,
    required this.totalCars,
    required this.moveCount,
    required this.mistakes,
    required this.theme,
    this.hint,
  });

  final GameStatus status;
  final Level level;
  final Board board;

  /// Cars the level started with (for the "cars left" display).
  final int totalCars;

  /// Number of cars successfully driven off.
  final int moveCount;

  /// Blocked exit attempts — drives the star rating.
  final int mistakes;

  final EnvironmentTheme theme;

  /// The currently highlighted hint move, if any.
  final ExitMove? hint;

  List<Vehicle> get cars => board.cars;
  int get carsLeft => board.cars.length;
  int get optimalMoves => level.optimalMoves;

  /// Stars reward clean play: a perfect clear with no blocked taps earns three.
  int get stars {
    if (mistakes == 0) return 3;
    if (mistakes <= 2) return 2;
    return 1;
  }

  GameState copyWith({
    GameStatus? status,
    Board? board,
    int? moveCount,
    int? mistakes,
    ExitMove? Function()? hint,
  }) {
    return GameState(
      status: status ?? this.status,
      level: level,
      board: board ?? this.board,
      totalCars: totalCars,
      moveCount: moveCount ?? this.moveCount,
      mistakes: mistakes ?? this.mistakes,
      theme: theme,
      hint: hint != null ? hint() : this.hint,
    );
  }
}

/// Drives a single puzzle session: validates exits, removes cleared cars, runs
/// power-ups, and detects the win (board fully cleared).
class GameController extends Notifier<GameState?> {
  final PuzzleSolver _solver = const PuzzleSolver();

  @override
  GameState? build() => null;

  void loadLevel(Level level) {
    final board = level.newBoard();
    state = GameState(
      status: GameStatus.playing,
      level: level,
      board: board,
      totalCars: board.cars.length,
      moveCount: 0,
      mistakes: 0,
      theme: EnvironmentTheme.byIndex(level.themeIndex),
    );
    ref.read(analyticsServiceProvider).levelStarted(level.number);
  }

  /// Instant restart — re-seeds the board from the level's initial layout.
  void restart() {
    final s = state;
    if (s == null) return;
    Haptics.light();
    final board = s.level.newBoard();
    state = GameState(
      status: GameStatus.playing,
      level: s.level,
      board: board,
      totalCars: board.cars.length,
      moveCount: 0,
      mistakes: 0,
      theme: s.theme,
    );
  }

  // ── Exit queries (used by the board widget) ──────────────────────────────
  bool canExit(int carId, SlideDirection direction) {
    final s = state;
    if (s == null) return false;
    final car = s.board.carById(carId);
    if (car == null) return false;
    return s.board.canExit(car, direction);
  }

  List<SlideDirection> exitDirections(int carId) {
    final s = state;
    final car = s?.board.carById(carId);
    if (s == null || car == null) return const [];
    return s.board.exitDirections(car);
  }

  /// Commits a car driving off the board (called after the ride-off animation).
  void exitCar(int carId) {
    final s = state;
    if (s == null || s.status != GameStatus.playing) return;
    if (s.board.carById(carId) == null) return;

    final board = s.board.removeCar(carId);
    final won = board.isCleared;
    state = s.copyWith(
      board: board,
      moveCount: s.moveCount + 1,
      status: won ? GameStatus.won : GameStatus.playing,
      hint: () => null,
    );
    Haptics.selection();
    if (won) _onWin();
  }

  /// Records a blocked exit attempt (a car the player tried to drive through a
  /// jammed lane). Counts against the star rating.
  void registerMistake() {
    final s = state;
    if (s == null || s.status != GameStatus.playing) return;
    Haptics.error();
    state = s.copyWith(mistakes: s.mistakes + 1);
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

  Future<void> _recordResult(GameState s) async {
    final store = ref.read(localStoreProvider);
    final existing = await store.progressFor(s.level.number);
    final score = max(0, 1000 - s.mistakes * 50) + s.stars * 100;
    final progress = existing ?? LevelProgress(levelNumber: s.level.number);
    progress.stars = max(progress.stars, s.stars);
    progress.bestScore = max(progress.bestScore, score);
    if (progress.bestMoves == 0) progress.bestMoves = s.moveCount;
    progress.synced = false;
    await store.saveProgress(progress);
  }

  // ── Power-ups ──────────────────────────────────────────────────────────────

  /// Hint: highlight the most obvious car that can drive off right now.
  void showHint() {
    final s = state;
    if (s == null) return;
    final best = _solver.bestNextMove(s.board);
    if (best == null) return;
    state = s.copyWith(hint: () => best);
    ref.read(analyticsServiceProvider).powerUpUsed('hint');
  }

  /// Police: instantly removes one car for free (always keeps the board
  /// clearable, since removal only frees space). Prefers a car that is still
  /// jammed in, to maximise impact.
  bool usePolice() {
    final s = state;
    if (s == null || s.board.cars.isEmpty) return false;
    final jammed = s.board.cars
        .where((c) => s.board.exitDirections(c).isEmpty)
        .toList();
    final victim = jammed.isNotEmpty ? jammed.first : s.board.cars.first;

    final board = s.board.removeCar(victim.id);
    final won = board.isCleared;
    state = s.copyWith(
      board: board,
      status: won ? GameStatus.won : GameStatus.playing,
      hint: () => null,
    );
    ref.read(analyticsServiceProvider).powerUpUsed('police');
    if (won) _onWin();
    return true;
  }

  /// Shuffle: re-randomises the board into a fresh, still-clearable layout with
  /// the same car count (keeps the move counter and mistakes).
  bool useShuffle() {
    final s = state;
    if (s == null) return false;
    final generator = ref.read(levelGeneratorProvider);
    final fresh = generator.generate(
      s.level.number,
      seed: Random().nextInt(1 << 31),
    );
    state = s.copyWith(board: fresh.newBoard(), hint: () => null);
    ref.read(analyticsServiceProvider).powerUpUsed('shuffle');
    return true;
  }
}

final gameControllerProvider =
    NotifierProvider<GameController, GameState?>(GameController.new);

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../game/models/direction.dart';
import '../../../game/models/vehicle.dart';
import '../../../state/game_controller.dart';
import 'board_painter.dart';
import 'vehicle_widget.dart';

/// Renders the parking grid and turns drags/taps into "drive off" actions:
/// flick a car toward an open edge and it rides off the board; flick it into a
/// jammed lane and it bumps and shakes. The level is cleared when every car has
/// left.
class BoardWidget extends ConsumerStatefulWidget {
  const BoardWidget({super.key, required this.size});

  /// Side length of the (square) board in logical pixels.
  final double size;

  @override
  ConsumerState<BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends ConsumerState<BoardWidget>
    with TickerProviderStateMixin {
  /// Cars currently playing their ride-off animation (id → exit direction).
  final Map<int, SlideDirection> _exiting = {};

  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  int? _shakeId;
  Axis _shakeAxis = Axis.horizontal;

  Offset _drag = Offset.zero;

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameControllerProvider);
    if (game == null) return const SizedBox.shrink();

    final board = game.board;
    final cell = widget.size / board.size;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            size: Size.square(widget.size),
            painter: BoardPainter(gridSize: board.size, theme: game.theme),
          ),
          for (final car in board.cars) _buildCar(game, car, cell),
        ],
      ),
    );
  }

  Widget _buildCar(GameState game, Vehicle car, double cell) {
    final width = (car.isHorizontal ? car.length : 1) * cell;
    final height = (car.isHorizontal ? 1 : car.length) * cell;

    final baseLeft = (car.isHorizontal ? car.lead : car.line) * cell;
    final baseTop = (car.isHorizontal ? car.line : car.lead) * cell;

    final exitDir = _exiting[car.id];
    var left = baseLeft;
    var top = baseTop;
    if (exitDir != null) {
      switch (exitDir) {
        case SlideDirection.right:
          left = widget.size + cell;
        case SlideDirection.left:
          left = -width - cell;
        case SlideDirection.down:
          top = widget.size + cell;
        case SlideDirection.up:
          top = -height - cell;
      }
    }

    final isHinted = game.hint?.carId == car.id;

    Widget child = GestureDetector(
      onPanStart: (_) => _drag = Offset.zero,
      onPanUpdate: (d) => _drag += d.delta,
      onPanEnd: (_) => _onFlick(car),
      onTap: () => _onTap(car),
      child: VehicleWidget(
        vehicle: car,
        color: game.theme.vehicleColor(car.skinId),
        hinted: isHinted,
      ),
    );

    // Apply a brief shake to the bumped car.
    if (_shakeId == car.id) {
      child = AnimatedBuilder(
        animation: _shake,
        builder: (context, c) {
          final dx = _shakeAxis == Axis.horizontal ? _wobble() : 0.0;
          final dy = _shakeAxis == Axis.vertical ? _wobble() : 0.0;
          return Transform.translate(offset: Offset(dx, dy), child: c);
        },
        child: child,
      );
    }

    return AnimatedPositioned(
      key: ValueKey(car.id),
      duration: exitDir != null
          ? const Duration(milliseconds: 300)
          : const Duration(milliseconds: 160),
      curve: exitDir != null ? Curves.easeIn : Curves.easeOut,
      left: left,
      top: top,
      width: width,
      height: height,
      onEnd: exitDir != null ? () => _onExitAnimationDone(car.id) : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 240),
        opacity: exitDir != null ? 0.0 : 1.0,
        child: child,
      ),
    );
  }

  double _wobble() => sin(_shake.value * pi * 6) * (1 - _shake.value) * 6;

  /// Resolves a flick into an exit attempt along the dominant drag axis.
  void _onFlick(Vehicle car) {
    if (_exiting.isNotEmpty) return; // ignore input mid-animation
    final drag = _drag;
    _drag = Offset.zero;
    if (drag.distance < 8) return; // too small — treat taps via onTap

    final SlideDirection dir;
    if (drag.dx.abs() >= drag.dy.abs()) {
      dir = drag.dx >= 0 ? SlideDirection.right : SlideDirection.left;
    } else {
      dir = drag.dy >= 0 ? SlideDirection.down : SlideDirection.up;
    }
    _attemptExit(car, dir);
  }

  /// A tap drives the car off whichever open edge is nearest.
  void _onTap(Vehicle car) {
    if (_exiting.isNotEmpty) return;
    final dirs = ref.read(gameControllerProvider.notifier).exitDirections(car.id);
    if (dirs.isEmpty) {
      _bump(car, car.isHorizontal ? Axis.horizontal : Axis.vertical);
      return;
    }
    _startExit(car, dirs.first);
  }

  void _attemptExit(Vehicle car, SlideDirection dir) {
    final controller = ref.read(gameControllerProvider.notifier);
    if (car.axis != dir.axis || !controller.canExit(car.id, dir)) {
      _bump(car, dir.axis == MoveAxis.horizontal ? Axis.horizontal : Axis.vertical);
      return;
    }
    _startExit(car, dir);
  }

  void _startExit(Vehicle car, SlideDirection dir) {
    setState(() => _exiting[car.id] = dir);
  }

  void _onExitAnimationDone(int carId) {
    if (!_exiting.containsKey(carId)) return;
    setState(() => _exiting.remove(carId));
    ref.read(gameControllerProvider.notifier).exitCar(carId);
  }

  void _bump(Vehicle car, Axis axis) {
    ref.read(gameControllerProvider.notifier).registerMistake();
    setState(() {
      _shakeId = car.id;
      _shakeAxis = axis;
    });
    _shake.forward(from: 0).whenComplete(() {
      if (mounted && _shakeId == car.id) setState(() => _shakeId = null);
    });
  }
}

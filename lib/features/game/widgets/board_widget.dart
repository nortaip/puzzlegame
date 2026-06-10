import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../game/models/direction.dart';
import '../../../game/models/vehicle.dart';
import '../../../state/game_controller.dart';
import 'board_painter.dart';
import 'vehicle_widget.dart';

/// Renders the parking grid and turns taps/flicks into "drive forward" actions:
/// tap a car and it drives off in its arrow direction if the lane is clear;
/// otherwise it lunges, bumps and shakes. The level clears when every car has
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
  /// Cars currently playing their ride-off animation.
  final Set<int> _exiting = {};

  late final AnimationController _bump = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );
  int? _bumpId;
  Offset _bumpDir = Offset.zero;

  @override
  void dispose() {
    _bump.dispose();
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

    var left = baseLeft;
    var top = baseTop;
    if (_exiting.contains(car.id)) {
      // Send the car fully off the board along its facing direction.
      switch (car.facing) {
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

    Widget child = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _drive(car),
      onPanEnd: (_) => _drive(car),
      child: VehicleWidget(
        vehicle: car,
        color: game.theme.vehicleColor(car.skinId),
        hinted: game.hintCarId == car.id,
      ),
    );

    // Directional lunge when the car is bumped against a jammed lane.
    if (_bumpId == car.id) {
      child = AnimatedBuilder(
        animation: _bump,
        builder: (context, c) {
          final k = sin(_bump.value * pi) * (1 - _bump.value) * 10;
          return Transform.translate(offset: _bumpDir * k, child: c);
        },
        child: child,
      );
    }

    final exiting = _exiting.contains(car.id);
    return AnimatedPositioned(
      key: ValueKey(car.id),
      duration: exiting
          ? const Duration(milliseconds: 360)
          : const Duration(milliseconds: 150),
      // Accelerate away (engine pulling off) on exit; gentle otherwise.
      curve: exiting ? Curves.easeInCubic : Curves.easeOut,
      left: left,
      top: top,
      width: width,
      height: height,
      onEnd: exiting ? () => _onExitDone(car.id) : null,
      child: child,
    );
  }

  /// Attempt to drive the tapped car forward (its single arrow direction).
  void _drive(Vehicle car) {
    if (_exiting.contains(car.id)) return;
    final controller = ref.read(gameControllerProvider.notifier);
    if (controller.canDriveOff(car.id)) {
      setState(() => _exiting.add(car.id));
    } else {
      _doBump(car);
    }
  }

  void _onExitDone(int carId) {
    if (!_exiting.contains(carId)) return;
    setState(() => _exiting.remove(carId));
    ref.read(gameControllerProvider.notifier).exitCar(carId);
  }

  void _doBump(Vehicle car) {
    ref.read(gameControllerProvider.notifier).registerMistake();
    setState(() {
      _bumpId = car.id;
      _bumpDir = _unit(car.facing);
    });
    _bump.forward(from: 0).whenComplete(() {
      if (mounted && _bumpId == car.id) setState(() => _bumpId = null);
    });
  }

  Offset _unit(SlideDirection d) {
    switch (d) {
      case SlideDirection.right:
        return const Offset(1, 0);
      case SlideDirection.left:
        return const Offset(-1, 0);
      case SlideDirection.down:
        return const Offset(0, 1);
      case SlideDirection.up:
        return const Offset(0, -1);
    }
  }
}

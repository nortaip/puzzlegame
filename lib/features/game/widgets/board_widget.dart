import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../game/models/direction.dart';
import '../../../game/models/vehicle.dart';
import '../../../state/game_controller.dart';
import 'board_painter.dart';
import 'car_painter.dart';
import 'vehicle_widget.dart';

/// Renders the parking grid and turns taps/flicks into "drive forward" actions:
/// tap a car and it drives off in its arrow direction if the lane is clear;
/// otherwise it lunges, bumps and shakes. The Police power-up sends a police car
/// to the centre that escorts stuck cars off one by one. The level clears when
/// every car has left.
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

  // Police escort animation.
  late final AnimationController _siren = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );
  bool _policeActive = false;
  bool _policeBusy = false;

  @override
  void dispose() {
    _bump.dispose();
    _siren.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Kick off the escort when the Police power-up bumps the token.
    ref.listen(gameControllerProvider, (prev, next) {
      if (next == null) return;
      final prevToken = prev?.policeToken ?? 0;
      if (next.policeToken != prevToken &&
          next.policeTargets.isNotEmpty &&
          !_policeBusy) {
        _runPolice(List<int>.of(next.policeTargets));
      }
    });

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
          if (_policeActive) _policeOverlay(cell),
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
    if (_policeBusy || _exiting.contains(car.id)) return;
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

  // ── Police escort ──────────────────────────────────────────────────────────
  Future<void> _runPolice(List<int> targets) async {
    _policeBusy = true;
    _siren.repeat();
    setState(() => _policeActive = true);

    // Let the police car arrive at the centre.
    await Future.delayed(const Duration(milliseconds: 650));

    final controller = ref.read(gameControllerProvider.notifier);
    for (final id in targets) {
      if (!mounted) break;
      final game = ref.read(gameControllerProvider);
      if (game == null || game.board.carById(id) == null) continue;

      setState(() => _exiting.add(id));
      await Future.delayed(const Duration(milliseconds: 360));
      if (!mounted) break;
      _exiting.remove(id);
      controller.exitCar(id); // idempotent if already gone
      await Future.delayed(const Duration(milliseconds: 130));
    }

    _siren.stop();
    if (mounted) setState(() => _policeActive = false);
    controller.clearPoliceTargets();
    _policeBusy = false;
  }

  Widget _policeOverlay(double cell) {
    final pSize = cell * 1.35;
    return Positioned(
      left: widget.size / 2 - pSize / 2,
      top: widget.size / 2 - pSize / 2,
      width: pSize,
      height: pSize,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          builder: (context, t, child) =>
              Transform.scale(scale: 0.5 + 0.5 * t, child: child),
          child: AnimatedBuilder(
            animation: _siren,
            builder: (context, _) => CustomPaint(
              painter: CarPainter(
                color: const Color(0xFFF5F5F7),
                facing: SlideDirection.down,
                police: true,
                sirenRedLeft: _siren.value < 0.5,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
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

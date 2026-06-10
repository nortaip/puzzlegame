import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../game/models/direction.dart';
import '../../../game/models/vehicle.dart';
import '../../../services/audio/sound_service.dart';
import '../../../state/game_controller.dart';
import 'board_painter.dart';
import 'car_painter.dart';
import 'trail_painter.dart';
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

  /// Fading tyre marks left behind by cars that have driven off.
  final List<_Trail> _trails = [];
  int _trailSeq = 0;
  double _cell = 0;

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
    _cell = cell;

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
          for (final t in _trails) _buildTrail(t),
          for (final car in board.cars) _buildCar(game, car, cell),
          if (_policeActive) _screenFlash(),
          if (_policeActive) _policeOverlay(cell),
        ],
      ),
    );
  }

  /// Pulsing blue/red wash over the board while the police are on scene.
  Widget _screenFlash() {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _siren,
          builder: (context, _) {
            final red = _siren.value < 0.5;
            return DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: (red ? const Color(0xFFFF1744) : const Color(0xFF2979FF))
                    .withOpacity(0.18),
              ),
            );
          },
        ),
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

    Widget inner(bool hazardOn) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _drive(car),
          onPanEnd: (_) => _drive(car),
          child: VehicleWidget(
            vehicle: car,
            color: game.theme.vehicleColor(car.skinId),
            hinted: game.hintCarId == car.id,
            hazardOn: hazardOn,
          ),
        );

    final Widget child;
    if (_bumpId == car.id) {
      // While blocked: lunge forward and blink the amber hazard lights.
      child = AnimatedBuilder(
        animation: _bump,
        builder: (context, _) {
          final k = sin(_bump.value * pi) * (1 - _bump.value) * 10;
          final hazardOn = (_bump.value * 8).floor().isOdd;
          return Transform.translate(
            offset: _bumpDir * k,
            child: inner(hazardOn),
          );
        },
      );
    } else {
      child = inner(false);
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
      SoundService.instance.drive();
      _addTrail(car);
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
    SoundService.instance.honk();
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
    SoundService.instance.startSiren();
    setState(() => _policeActive = true);

    // Let the police car arrive at the centre.
    await Future.delayed(const Duration(milliseconds: 650));

    final controller = ref.read(gameControllerProvider.notifier);
    for (final id in targets) {
      if (!mounted) break;
      final game = ref.read(gameControllerProvider);
      final car = game?.board.carById(id);
      if (car == null) continue;

      SoundService.instance.drive();
      _addTrail(car);
      setState(() => _exiting.add(id));
      await Future.delayed(const Duration(milliseconds: 360));
      if (!mounted) break;
      _exiting.remove(id);
      controller.exitCar(id); // idempotent if already gone
      await Future.delayed(const Duration(milliseconds: 130));
    }

    _siren.stop();
    SoundService.instance.stopSiren();
    if (mounted) setState(() => _policeActive = false);
    controller.clearPoliceTargets();
    _policeBusy = false;
  }

  Widget _policeOverlay(double cell) {
    final pSize = cell * 1.35;
    final boxW = pSize * 1.7;
    final boxH = pSize * 1.25;
    return Positioned(
      left: widget.size / 2 - boxW / 2,
      top: widget.size / 2 - boxH / 2,
      width: boxW,
      height: boxH,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          builder: (context, t, child) =>
              Transform.scale(scale: 0.5 + 0.5 * t, child: child),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Squad car with flashing light bar.
              Positioned(
                left: 0,
                top: (boxH - pSize) / 2,
                width: pSize,
                height: pSize,
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
              // The officer directing traffic (top-down).
              Positioned(
                right: 0,
                bottom: 0,
                width: pSize * 0.62,
                height: pSize * 0.62,
                child: CustomPaint(painter: OfficerPainter()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tyre marks ─────────────────────────────────────────────────────────────
  void _addTrail(Vehicle car) {
    final cell = _cell;
    if (cell <= 0) return;
    final width = (car.isHorizontal ? car.length : 1) * cell;
    final height = (car.isHorizontal ? 1 : car.length) * cell;
    final baseLeft = (car.isHorizontal ? car.lead : car.line) * cell;
    final baseTop = (car.isHorizontal ? car.line : car.lead) * cell;

    // The lane the car drives through: from its body to the exit border.
    final Rect rect;
    switch (car.facing) {
      case SlideDirection.right:
        rect = Rect.fromLTWH(baseLeft, baseTop, widget.size - baseLeft, height);
      case SlideDirection.left:
        rect = Rect.fromLTWH(0, baseTop, baseLeft + width, height);
      case SlideDirection.down:
        rect = Rect.fromLTWH(baseLeft, baseTop, width, widget.size - baseTop);
      case SlideDirection.up:
        rect = Rect.fromLTWH(baseLeft, 0, width, baseTop + height);
    }

    setState(() => _trails.add(_Trail(_trailSeq++, rect, car.facing)));
  }

  Widget _buildTrail(_Trail trail) {
    return Positioned.fromRect(
      key: ValueKey('trail_${trail.id}'),
      rect: trail.rect,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 1.0, end: 0.0),
          duration: const Duration(milliseconds: 750),
          onEnd: () => setState(() => _trails.removeWhere((t) => t.id == trail.id)),
          builder: (context, opacity, _) => Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: CustomPaint(
              painter: TrailPainter(facing: trail.facing, color: Colors.black54),
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

/// A fading tyre mark left in a lane after a car drove off.
class _Trail {
  const _Trail(this.id, this.rect, this.facing);
  final int id;
  final Rect rect;
  final SlideDirection facing;
}

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../game/models/direction.dart';
import '../../../game/models/vehicle.dart';
import '../../../services/audio/sound_service.dart';
import '../../../state/game_controller.dart';
import '../../../state/player_controller.dart';
import 'board_painter.dart';
import 'car_painter.dart';
import 'trail_painter.dart';
import 'vehicle_widget.dart';

/// Renders the parking grid and turns taps into "drive forward" actions.
///
/// A tapped car is removed from the board *immediately* (so a car right behind
/// it can be tapped and follow without waiting), then animated off as a drifting
/// "ghost". A follow-up car whose path just cleared launches with high beams and
/// a double honk, flashing a horn icon in the centre. A blocked car bumps,
/// blinks its hazard lights and honks. The Police power-up escorts stuck cars
/// off with a siren, blue/red screen flash and an officer on scene.
class BoardWidget extends ConsumerStatefulWidget {
  const BoardWidget({super.key, required this.size});

  /// Side length of the (square) board in logical pixels.
  final double size;

  @override
  ConsumerState<BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends ConsumerState<BoardWidget>
    with TickerProviderStateMixin {
  final Random _rng = Random();

  /// Cars currently drifting off the board (already removed from game state).
  final List<_Ghost> _ghosts = [];

  /// Cars hidden from the board while their showoff ghost plays (their removal
  /// is deferred until the animation ends, so the win screen waits for it).
  final Set<int> _hiddenCars = {};

  /// Fading tyre marks left behind.
  final List<_Trail> _trails = [];
  int _trailSeq = 0;

  /// Expanding smoke puffs left by some exits.
  final List<_Smoke> _smokes = [];
  int _smokeSeq = 0;

  double _cell = 0;

  late final AnimationController _bump = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );
  int? _bumpId;
  Offset _bumpDir = Offset.zero;

  late final AnimationController _siren = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );
  bool _policeActive = false;
  bool _policeBusy = false;

  // Centre horn-icon flash (chained / double-honk).
  late final AnimationController _horn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 760),
  );

  @override
  void dispose() {
    _bump.dispose();
    _siren.dispose();
    _horn.dispose();
    for (final g in _ghosts) {
      g.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          for (final s in _smokes) _buildSmoke(s),
          for (final tree in board.trees) _buildTree(tree, board.size, cell),
          for (final car in board.cars)
            if (!_hiddenCars.contains(car.id)) _buildCar(game, car, cell),
          for (final g in _ghosts) _buildGhost(g),
          if (_policeActive) _screenFlash(),
          if (_policeActive) _policeOverlay(cell),
          _hornOverlay(),
        ],
      ),
    );
  }

  // ── Parked cars ────────────────────────────────────────────────────────────
  Widget _buildCar(GameState game, Vehicle car, double cell) {
    final width = (car.isHorizontal ? car.length : 1) * cell;
    final height = (car.isHorizontal ? 1 : car.length) * cell;
    final left = (car.isHorizontal ? car.lead : car.line) * cell;
    final top = (car.isHorizontal ? car.line : car.lead) * cell;

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

    return Positioned(
      key: ValueKey('car_${car.id}'),
      left: left,
      top: top,
      width: width,
      height: height,
      child: child,
    );
  }

  Widget _buildTree(int cellIndex, int gridSize, double cell) {
    final r = cellIndex ~/ gridSize;
    final c = cellIndex % gridSize;
    return Positioned(
      key: ValueKey('tree_$cellIndex'),
      left: c * cell,
      top: r * cell,
      width: cell,
      height: cell,
      child: const IgnorePointer(
        child: Padding(
          padding: EdgeInsets.all(2),
          child: CustomPaint(painter: TreePainter(), child: SizedBox.expand()),
        ),
      ),
    );
  }

  void _drive(Vehicle car) {
    if (_policeBusy) return;
    final controller = ref.read(gameControllerProvider.notifier);
    if (!controller.canDriveOff(car.id)) {
      _doBump(car);
      return;
    }

    // Occasionally (every ~5th win) reward a flawless clear with a figure-8
    // drift on the very last car.
    final game = ref.read(gameControllerProvider);
    final profile = ref.read(playerControllerProvider);
    final isLastCar = (game?.board.cars.length ?? 0) == 1;
    final perfect = (game?.mistakes ?? 1) == 0;
    final milestone = (profile.levelsCompleted + 1) % 5 == 0;
    if (isLastCar && perfect && milestone) {
      _launchCar(car, showoff: true);
      return;
    }

    final chained = _isChained(car);
    _launchCar(car, highBeam: chained, chained: chained);
  }

  /// True when the lane just ahead is occupied by a car that is still driving
  /// off (a back-to-back follow).
  bool _isChained(Vehicle car) {
    for (final g in _ghosts) {
      final gc = g.car;
      if (gc.facing != car.facing || gc.line != car.line) continue;
      final ahead = switch (car.facing) {
        SlideDirection.right || SlideDirection.down => gc.lead > car.lead,
        SlideDirection.left || SlideDirection.up => gc.lead < car.lead,
      };
      if (ahead) return true;
    }
    return false;
  }

  /// Commits a car off the board immediately and animates it away as a ghost.
  void _launchCar(
    Vehicle car, {
    bool highBeam = false,
    bool chained = false,
    bool showoff = false,
  }) {
    final game = ref.read(gameControllerProvider);
    final color =
        game?.theme.vehicleColor(car.skinId) ?? const Color(0xFF3498DB);

    SoundService.instance.drive();

    // Vary the exit: sometimes a drift (fishtail), sometimes a smoke puff,
    // sometimes a plain clean getaway (never for the figure-8 showoff).
    final roll = _rng.nextDouble();
    // Only small (length-2) cars drift; bigger vehicles never do.
    final drift = !showoff && roll < 0.4 && car.length == 2;
    final smoke = !showoff && !drift && roll < 0.5;

    if (showoff) {
      SoundService.instance.honk();
      Future.delayed(const Duration(milliseconds: 900), SoundService.instance.honk);
    } else {
      _addTrail(car);
      if (chained) {
        SoundService.instance.honk();
        Future.delayed(
            const Duration(milliseconds: 190), SoundService.instance.honk);
        _flashHorn();
      }
      // A drift always kicks up tyre smoke.
      if (smoke || drift) _addSmoke(car);
    }

    final ghost = _Ghost(
      car: car,
      color: color,
      cell: _cell,
      boardSize: widget.size,
      highBeam: highBeam,
      drift: drift,
      driftSign: _rng.nextBool() ? 1 : -1,
      showoff: showoff,
    );
    ghost.controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: showoff ? 1700 : (drift ? 760 : 520)),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (showoff) {
            // Commit the win only after the figure-8 finishes.
            _hiddenCars.remove(car.id);
            ref.read(gameControllerProvider.notifier).exitCar(car.id);
          }
          if (mounted) setState(() => _ghosts.remove(ghost));
          ghost.controller.dispose();
        }
      });

    if (showoff) {
      // Keep the car in game state (hidden) until the drift ends.
      setState(() {
        _hiddenCars.add(car.id);
        _ghosts.add(ghost);
      });
    } else {
      setState(() => _ghosts.add(ghost));
      ref.read(gameControllerProvider.notifier).exitCar(car.id);
    }
    ghost.controller.forward();
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

  // ── Drifting ghosts ──────────────────────────────────────────────────────
  Widget _buildGhost(_Ghost g) {
    final rect = g.startRect;
    return Positioned.fromRect(
      key: ValueKey('ghost_${g.car.id}_${identityHashCode(g)}'),
      rect: rect,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: g.controller,
          builder: (context, _) {
            final p = g.controller.value;
            return g.showoff
                ? _showoffTransform(g, rect, p)
                : _normalGhostTransform(g, p);
          },
        ),
      ),
    );
  }

  Widget _ghostCar(_Ghost g) => Padding(
        padding: const EdgeInsets.all(2),
        child: CustomPaint(
          painter: CarPainter(
            color: g.color,
            facing: g.car.facing,
            type: g.car.type,
            highBeam: g.highBeam,
          ),
          child: const SizedBox.expand(),
        ),
      );

  Widget _normalGhostTransform(_Ghost g, double p) {
    if (!g.drift) {
      return Transform.translate(
        offset: g.travel * Curves.easeInCubic.transform(p),
        child: _ghostCar(g),
      );
    }

    // A real power-slide: the car accelerates along its lane while its tail
    // steps out sideways (lateral slip) and the body sits at a big slip angle
    // — pointing somewhere other than where it's travelling — then it hooks up
    // and straightens as it shoots off. That mismatch reads as "drifting".
    final facingU = _unit(g.car.facing);
    final perp =
        Offset(-facingU.dy, facingU.dx) * g.driftSign.toDouble();

    final forward = facingU * (g.travel.distance * Curves.easeInCubic.transform(p));
    final slide = perp * (g.cell * 1.05 * sin(p * pi)); // tail out, then back
    final off = forward + slide;

    // Big slip angle up front (~34°) that decays as the car hooks up.
    final slip = g.driftSign * 0.6 * (1 - Curves.easeInQuad.transform(p));

    return Transform.translate(
      offset: off,
      child: Transform.rotate(
        angle: slip,
        alignment: g.frontAlignment,
        child: _ghostCar(g),
      ),
    );
  }

  /// Drives a lazy figure-8 (lemniscate of Gerono) around the board centre,
  /// rotating to follow the path so the car looks like it's drifting an "8",
  /// then fades out.
  Widget _showoffTransform(_Ghost g, Rect rect, double p) {
    final centre = Offset(g.boardSize / 2, g.boardSize / 2);
    final amp = g.boardSize * 0.26;
    const loops = 1.5;

    final drivePhase = p < 0.85 ? (p / 0.85) : 1.0;
    final tt = drivePhase * 2 * pi * loops;
    final dir = g.driftSign.toDouble(); // flips the 8's direction

    final lx = amp * sin(tt) * dir;
    final ly = amp * sin(tt) * cos(tt) * 1.7;
    final pos = centre + Offset(lx, ly);

    // Tangent angle for rotation.
    final dx = cos(tt) * dir;
    final dy = (cos(tt) * cos(tt) - sin(tt) * sin(tt)) * 1.7;
    final angle = atan2(dy, dx);

    final opacity = p < 0.85 ? 1.0 : (1 - (p - 0.85) / 0.15).clamp(0.0, 1.0);

    return Transform.translate(
      offset: pos - rect.center,
      child: Transform.rotate(
        angle: angle,
        child: Opacity(opacity: opacity, child: _ghostCar(g)),
      ),
    );
  }

  // ── Police escort ──────────────────────────────────────────────────────────
  Future<void> _runPolice(List<int> targets) async {
    _policeBusy = true;
    _siren.repeat();
    SoundService.instance.startSiren();
    setState(() => _policeActive = true);

    await Future.delayed(const Duration(milliseconds: 650));

    for (final id in targets) {
      if (!mounted) break;
      final game = ref.read(gameControllerProvider);
      final car = game?.board.carById(id);
      if (car == null) continue;
      _launchCar(car);
      await Future.delayed(const Duration(milliseconds: 320));
    }

    await Future.delayed(const Duration(milliseconds: 200));
    _siren.stop();
    SoundService.instance.stopSiren();
    if (mounted) setState(() => _policeActive = false);
    ref.read(gameControllerProvider.notifier).clearPoliceTargets();
    _policeBusy = false;
  }

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

  // ── Centre horn icon flash ─────────────────────────────────────────────────
  void _flashHorn() => _horn.forward(from: 0);

  Widget _hornOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: AnimatedBuilder(
            animation: _horn,
            builder: (context, _) {
              final t = _horn.value;
              if (t == 0 || t == 1) return const SizedBox.shrink();
              final scale =
                  0.6 + 0.5 * Curves.easeOutBack.transform((t * 2).clamp(0.0, 1.0));
              final opacity =
                  t < 0.55 ? 1.0 : (1 - (t - 0.55) / 0.45).clamp(0.0, 1.0);
              final d = widget.size * 0.32;
              return Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: d,
                    height: d,
                    padding: EdgeInsets.all(d * 0.27),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4B76B9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4B76B9).withOpacity(0.5),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: CustomPaint(painter: HornIconPainter()),
                  ),
                ),
              );
            },
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

  // ── Smoke puffs ────────────────────────────────────────────────────────────
  void _addSmoke(Vehicle car) {
    final cell = _cell;
    if (cell <= 0) return;
    final w = (car.isHorizontal ? car.length : 1) * cell;
    final h = (car.isHorizontal ? 1 : car.length) * cell;
    final left = (car.isHorizontal ? car.lead : car.line) * cell;
    final top = (car.isHorizontal ? car.line : car.lead) * cell;
    final centre = Offset(left + w / 2, top + h / 2);
    // Puff out of the rear (opposite the facing direction).
    final rear = centre +
        _unit(car.facing) * (-(car.isHorizontal ? w : h) * 0.4);
    final box = cell * 1.7;
    setState(() => _smokes
        .add(_Smoke(_smokeSeq++, Rect.fromCenter(center: rear, width: box, height: box))));
  }

  Widget _buildSmoke(_Smoke smoke) {
    return Positioned.fromRect(
      key: ValueKey('smoke_${smoke.id}'),
      rect: smoke.rect,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 680),
          onEnd: () => setState(() => _smokes.removeWhere((s) => s.id == smoke.id)),
          builder: (context, t, _) => CustomPaint(
            painter: SmokePainter(t),
            child: const SizedBox.expand(),
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

/// A car animating off the board after being driven away.
class _Ghost {
  _Ghost({
    required this.car,
    required this.color,
    required this.cell,
    required this.boardSize,
    required this.highBeam,
    required this.drift,
    required this.driftSign,
    this.showoff = false,
  });

  final Vehicle car;
  final Color color;
  final double cell;
  final double boardSize;
  final bool highBeam;
  final bool drift;
  final int driftSign;

  /// Celebratory figure-8 drift in the centre before vanishing.
  final bool showoff;
  late final AnimationController controller;

  Rect get startRect {
    final w = (car.isHorizontal ? car.length : 1) * cell;
    final h = (car.isHorizontal ? 1 : car.length) * cell;
    final left = (car.isHorizontal ? car.lead : car.line) * cell;
    final top = (car.isHorizontal ? car.line : car.lead) * cell;
    return Rect.fromLTWH(left, top, w, h);
  }

  /// Total translation needed to drive fully off the board.
  Offset get travel {
    final r = startRect;
    switch (car.facing) {
      case SlideDirection.right:
        return Offset(boardSize - r.left + cell, 0);
      case SlideDirection.left:
        return Offset(-(r.right + cell), 0);
      case SlideDirection.down:
        return Offset(0, boardSize - r.top + cell);
      case SlideDirection.up:
        return Offset(0, -(r.bottom + cell));
    }
  }

  /// Rotate about the front axle so the rear swings out (fishtail).
  Alignment get frontAlignment {
    switch (car.facing) {
      case SlideDirection.right:
        return const Alignment(0.7, 0);
      case SlideDirection.left:
        return const Alignment(-0.7, 0);
      case SlideDirection.down:
        return const Alignment(0, 0.7);
      case SlideDirection.up:
        return const Alignment(0, -0.7);
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

/// An expanding smoke puff left by some exits.
class _Smoke {
  const _Smoke(this.id, this.rect);
  final int id;
  final Rect rect;
}

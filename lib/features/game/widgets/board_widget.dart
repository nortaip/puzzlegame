import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../game/models/board.dart';
import '../../../game/models/direction.dart';
import '../../../game/models/vehicle.dart';
import '../../../state/game_controller.dart';
import 'board_painter.dart';
import 'vehicle_widget.dart';

/// Renders the parking grid and translates drag gestures into legal vehicle
/// slides. Dragging is clamped live to the vehicle's free travel so cars feel
/// physical (they stop against neighbours), and releasing snaps to a cell.
class BoardWidget extends ConsumerStatefulWidget {
  const BoardWidget({super.key, required this.size});

  /// Side length of the (square) board in logical pixels.
  final double size;

  @override
  ConsumerState<BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends ConsumerState<BoardWidget> {
  int? _dragId;
  double _dragPixels = 0;
  double _minPx = 0;
  double _maxPx = 0;

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
        children: [
          CustomPaint(
            size: Size.square(widget.size),
            painter: BoardPainter(
              gridSize: board.size,
              exitRow: board.exitRow,
              theme: game.theme,
            ),
          ),
          for (final v in board.vehicles)
            _buildVehicle(context, game, board, v, cell),
        ],
      ),
    );
  }

  Widget _buildVehicle(
    BuildContext context,
    GameState game,
    Board board,
    Vehicle v,
    double cell,
  ) {
    final lead = board.positions[v.id];
    final row = v.isHorizontal ? v.fixedLine : lead;
    final col = v.isHorizontal ? lead : v.fixedLine;
    final width = (v.isHorizontal ? v.length : 1) * cell;
    final height = (v.isHorizontal ? 1 : v.length) * cell;

    var left = col * cell;
    var top = row * cell;
    final isDragging = _dragId == v.id;
    if (isDragging) {
      if (v.isHorizontal) {
        left += _dragPixels;
      } else {
        top += _dragPixels;
      }
    }

    final child = GestureDetector(
      onPanStart: v.isLocked ? null : (_) => _onPanStart(board, v, cell),
      onPanUpdate: v.isLocked ? null : (d) => _onPanUpdate(v, d),
      onPanEnd: v.isLocked ? null : (_) => _onPanEnd(v, cell),
      child: VehicleWidget(
        vehicle: v,
        color: v.isTarget
            ? game.theme.targetColor
            : game.theme.vehicleColor(v.id + 1),
        selected: game.selectedVehicleId == v.id,
        hinted: game.hintMove?.vehicleId == v.id,
      ),
    );

    // The dragged vehicle follows the finger immediately; the rest animate
    // smoothly to their new cells after a committed move.
    if (isDragging) {
      return Positioned(
        left: left,
        top: top,
        width: width,
        height: height,
        child: child,
      );
    }
    return AnimatedPositioned(
      duration: AppConstants.vehicleSlide,
      curve: Curves.easeOutCubic,
      left: left,
      top: top,
      width: width,
      height: height,
      child: child,
    );
  }

  void _onPanStart(Board board, Vehicle v, double cell) {
    ref.read(gameControllerProvider.notifier).selectVehicle(v.id);
    final negDir = v.isHorizontal ? SlideDirection.left : SlideDirection.up;
    final posDir = v.isHorizontal ? SlideDirection.right : SlideDirection.down;
    final negMax = board.maxSlide(v.id, negDir).abs();
    final posMax = board.maxSlide(v.id, posDir).abs();
    setState(() {
      _dragId = v.id;
      _dragPixels = 0;
      _minPx = -negMax * cell;
      _maxPx = posMax * cell;
    });
  }

  void _onPanUpdate(Vehicle v, DragUpdateDetails d) {
    final delta = v.isHorizontal ? d.delta.dx : d.delta.dy;
    setState(() {
      _dragPixels = (_dragPixels + delta).clamp(_minPx, _maxPx);
    });
  }

  void _onPanEnd(Vehicle v, double cell) {
    final steps = (_dragPixels / cell).round();
    final id = v.id;
    setState(() {
      _dragId = null;
      _dragPixels = 0;
    });
    if (steps == 0) return;
    final dir = v.isHorizontal
        ? (steps > 0 ? SlideDirection.right : SlideDirection.left)
        : (steps > 0 ? SlideDirection.down : SlideDirection.up);
    ref.read(gameControllerProvider.notifier).moveVehicle(id, dir, steps.abs());
  }
}

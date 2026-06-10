import 'package:flutter/material.dart';

import '../../../game/models/direction.dart';

/// Paints the tyre/skid marks a car leaves as it speeds off: two parallel
/// streaks running down the lane it drove through, strongest where the car
/// started and fading toward the edge it exited (a sense of motion). Overall
/// fade-out over time is handled by the caller (an [Opacity] wrapper).
class TrailPainter extends CustomPainter {
  TrailPainter({required this.facing, required this.color});

  final SlideDirection facing;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final horizontal = facing.axis == MoveAxis.horizontal;
    final shortSide = horizontal ? size.height : size.width;
    final thickness = shortSide * 0.13;
    final offset = shortSide * 0.22;

    // Alpha gradient along the travel axis: opaque behind, fading to the front.
    final Rect rect = Offset.zero & size;
    final Alignment begin, end;
    switch (facing) {
      case SlideDirection.right:
        begin = Alignment.centerLeft;
        end = Alignment.centerRight;
      case SlideDirection.left:
        begin = Alignment.centerRight;
        end = Alignment.centerLeft;
      case SlideDirection.down:
        begin = Alignment.topCenter;
        end = Alignment.bottomCenter;
      case SlideDirection.up:
        begin = Alignment.bottomCenter;
        end = Alignment.topCenter;
    }

    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = thickness
      ..shader = LinearGradient(
        begin: begin,
        end: end,
        colors: [color.withOpacity(0.55), color.withOpacity(0.0)],
      ).createShader(rect);

    if (horizontal) {
      final cy = size.height / 2;
      for (final dy in [-offset, offset]) {
        canvas.drawLine(
          Offset(0, cy + dy),
          Offset(size.width, cy + dy),
          paint,
        );
      }
    } else {
      final cx = size.width / 2;
      for (final dx in [-offset, offset]) {
        canvas.drawLine(
          Offset(cx + dx, 0),
          Offset(cx + dx, size.height),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant TrailPainter old) =>
      old.facing != facing || old.color != color;
}

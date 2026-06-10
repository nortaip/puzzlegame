import 'package:flutter/material.dart';

import '../../../game/themes/environment_theme.dart';

/// Paints the parking lot: a rounded asphalt surface, grid lines, and exit
/// "openings" on all four borders to signal that cars can drive off any side.
class BoardPainter extends CustomPainter {
  BoardPainter({required this.gridSize, required this.theme});

  final int gridSize;
  final EnvironmentTheme theme;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / gridSize;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(20),
    );

    canvas.drawRRect(rrect, Paint()..color = theme.boardColor);

    final line = Paint()
      ..color = theme.gridLineColor
      ..strokeWidth = 1.2;
    for (var i = 1; i < gridSize; i++) {
      canvas.drawLine(Offset(cell * i, 0), Offset(cell * i, size.height), line);
      canvas.drawLine(Offset(0, cell * i), Offset(size.width, cell * i), line);
    }

    // Subtle exit markers (outward chevrons) tucked just inside every border
    // cell, hinting that cars leave the lot from any edge.
    final marker = Paint()
      ..color = theme.exitGlow.withOpacity(0.45)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < gridSize; i++) {
      final c = i * cell + cell / 2;
      _chevron(canvas, marker, Offset(6, c), Axis.horizontal, -1); // left edge
      _chevron(canvas, marker, Offset(size.width - 6, c), Axis.horizontal, 1);
      _chevron(canvas, marker, Offset(c, 6), Axis.vertical, -1); // top edge
      _chevron(canvas, marker, Offset(c, size.height - 6), Axis.vertical, 1);
    }
  }

  void _chevron(Canvas canvas, Paint paint, Offset at, Axis axis, int sign) {
    const s = 4.0;
    if (axis == Axis.horizontal) {
      final tip = at.dx + sign * s;
      canvas.drawLine(Offset(at.dx - sign * s, at.dy - s), Offset(tip, at.dy), paint);
      canvas.drawLine(Offset(tip, at.dy), Offset(at.dx - sign * s, at.dy + s), paint);
    } else {
      final tip = at.dy + sign * s;
      canvas.drawLine(Offset(at.dx - s, at.dy - sign * s), Offset(at.dx, tip), paint);
      canvas.drawLine(Offset(at.dx, tip), Offset(at.dx + s, at.dy - sign * s), paint);
    }
  }

  @override
  bool shouldRepaint(covariant BoardPainter old) =>
      old.gridSize != gridSize || old.theme != theme;
}

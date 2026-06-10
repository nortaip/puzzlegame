import 'package:flutter/material.dart';

import '../../../game/themes/environment_theme.dart';

/// Paints the board surface: rounded backing, grid lines, and the glowing exit
/// gap on the right border aligned with the target row.
class BoardPainter extends CustomPainter {
  BoardPainter({
    required this.gridSize,
    required this.exitRow,
    required this.theme,
  });

  final int gridSize;
  final int exitRow;
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

    // Exit glow on the right edge at the target row.
    final exitRect = Rect.fromLTWH(
      size.width - 6,
      exitRow * cell + 6,
      10,
      cell - 12,
    );
    final glow = Paint()
      ..color = theme.exitGlow
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(exitRect, const Radius.circular(6)),
      glow,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(exitRect, const Radius.circular(6)),
      Paint()..color = theme.exitGlow,
    );

    // Chevrons pointing out of the exit.
    final chevron = Paint()
      ..color = theme.exitGlow.withOpacity(0.8)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final cy = exitRow * cell + cell / 2;
    for (var k = 0; k < 2; k++) {
      final x = size.width - 18 + k * 7.0;
      canvas.drawLine(Offset(x, cy - 6), Offset(x + 5, cy), chevron);
      canvas.drawLine(Offset(x + 5, cy), Offset(x, cy + 6), chevron);
    }
  }

  @override
  bool shouldRepaint(covariant BoardPainter old) =>
      old.gridSize != gridSize || old.exitRow != exitRow || old.theme != theme;
}

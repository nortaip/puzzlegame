import 'dart:math';

import 'package:flutter/material.dart';

import '../../../game/models/direction.dart';

/// Paints a clean top-down toy car oriented toward [facing]: glossy body with a
/// gradient, cabin + windshield glass, head/tail lights, four wheels, and a bold
/// white arrow showing the direction it will drive. Designed to read clearly at
/// small grid sizes.
class CarPainter extends CustomPainter {
  CarPainter({
    required this.color,
    required this.facing,
    this.police = false,
    this.sirenRedLeft = true,
  });

  final Color color;
  final SlideDirection facing;

  /// Renders a police livery (light bar instead of an arrow).
  final bool police;

  /// Which side of the siren is currently lit (animated by the caller).
  final bool sirenRedLeft;

  @override
  void paint(Canvas canvas, Size size) {
    // Work in a local frame centred on the car, with +x pointing forward, then
    // rotate so "forward" matches the facing direction.
    final isHorizontal = facing.axis == MoveAxis.horizontal;
    final longSide = (isHorizontal ? size.width : size.height);
    final shortSide = (isHorizontal ? size.height : size.width);

    final double angle;
    switch (facing) {
      case SlideDirection.right:
        angle = 0;
      case SlideDirection.left:
        angle = pi;
      case SlideDirection.down:
        angle = pi / 2;
      case SlideDirection.up:
        angle = -pi / 2;
    }

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(angle);

    final l = longSide - 6; // body length (with a little inset)
    final s = shortSide - 8; // body width
    final hl = l / 2;
    final hs = s / 2;

    // Soft drop shadow.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, 3), width: l, height: s),
        Radius.circular(s * 0.32),
      ),
      Paint()
        ..color = Colors.black.withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Body with a glossy gradient.
    final bodyRect = Rect.fromCenter(center: Offset.zero, width: l, height: s);
    final bodyRRect =
        RRect.fromRectAndRadius(bodyRect, Radius.circular(s * 0.30));
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(color, Colors.white, 0.30)!,
          color,
          Color.lerp(color, Colors.black, 0.22)!,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(bodyRect);
    canvas.drawRRect(bodyRRect, bodyPaint);

    // Wheels (peeking out along both sides).
    final wheelPaint = Paint()..color = const Color(0xFF222228);
    final wheelW = l * 0.20;
    final wheelH = s * 0.16;
    for (final sx in [-l * 0.26, l * 0.26]) {
      for (final sy in [-hs, hs]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(sx, sy), width: wheelW, height: wheelH),
            Radius.circular(wheelH * 0.45),
          ),
          wheelPaint,
        );
      }
    }
    // Redraw body so wheels sit "under" it.
    canvas.drawRRect(bodyRRect, bodyPaint);

    // Cabin / roof (slightly inset, darker shade of the body colour).
    final cabinRect = Rect.fromCenter(
      center: const Offset(-2, 0),
      width: l * 0.52,
      height: s * 0.78,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(cabinRect, Radius.circular(s * 0.22)),
      Paint()..color = Color.lerp(color, Colors.black, 0.18)!,
    );

    // Windshield (front glass) + rear window.
    final glass = Paint()..color = const Color(0xFF2A2E37);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(l * 0.18, 0), width: l * 0.16, height: s * 0.66),
        Radius.circular(s * 0.16),
      ),
      glass,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(-l * 0.22, 0), width: l * 0.13, height: s * 0.6),
        Radius.circular(s * 0.16),
      ),
      glass,
    );

    // Headlights (front, bright) and tail lights (rear, red).
    final head = Paint()..color = const Color(0xFFFFF3C4);
    final tail = Paint()..color = const Color(0xFFE53935);
    for (final sy in [-hs * 0.62, hs * 0.62]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(hl - l * 0.05, sy), width: l * 0.07, height: s * 0.2),
          Radius.circular(s * 0.08),
        ),
        head,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(-hl + l * 0.04, sy), width: l * 0.05, height: s * 0.18),
          Radius.circular(s * 0.08),
        ),
        tail,
      );
    }

    if (police) {
      _drawSiren(canvas, l, s);
    } else {
      // Direction arrow on the roof.
      _drawArrow(canvas, l, s);
    }

    canvas.restore();
  }

  /// A roof light bar split into a red and a blue half; the lit side glows.
  void _drawSiren(Canvas canvas, double l, double s) {
    final barW = l * 0.30;
    final barH = s * 0.34;
    final left = Rect.fromCenter(
        center: Offset(-barW * 0.25, 0), width: barW * 0.5, height: barH);
    final right = Rect.fromCenter(
        center: Offset(barW * 0.25, 0), width: barW * 0.5, height: barH);

    final red = sirenRedLeft ? const Color(0xFFFF1744) : const Color(0xFFB71C1C);
    final blue = sirenRedLeft ? const Color(0xFF1565C0) : const Color(0xFF2979FF);

    void light(Rect r, Color c, bool lit) {
      if (lit) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(r.inflate(2), const Radius.circular(3)),
          Paint()
            ..color = c.withOpacity(0.8)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(2)),
        Paint()..color = c,
      );
    }

    light(left, red, sirenRedLeft);
    light(right, blue, !sirenRedLeft);
  }

  void _drawArrow(Canvas canvas, double l, double s) {
    final paint = Paint()..color = Colors.white.withOpacity(0.92);
    final a = s * 0.22; // arrow half-height
    final tipX = l * 0.06 + a; // arrow head tip
    final path = Path()
      ..moveTo(tipX, 0)
      ..lineTo(tipX - a, -a)
      ..lineTo(tipX - a, -a * 0.45)
      ..lineTo(tipX - a * 2.0, -a * 0.45)
      ..lineTo(tipX - a * 2.0, a * 0.45)
      ..lineTo(tipX - a, a * 0.45)
      ..lineTo(tipX - a, a)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withOpacity(0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CarPainter old) =>
      old.color != color || old.facing != facing;
}

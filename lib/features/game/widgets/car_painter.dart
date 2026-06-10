import 'dart:math';

import 'package:flutter/material.dart';

import '../../../game/models/direction.dart';
import '../../../game/models/vehicle.dart';

/// Paints a clean top-down vehicle oriented toward [facing]. The silhouette and
/// detailing change with [type]: a sleek car, a boxier minivan, a long bus with
/// a row of windows, or a truck (a cab pulling a pale cargo box). A bold white
/// arrow shows the direction it will drive.
class CarPainter extends CustomPainter {
  CarPainter({
    required this.color,
    required this.facing,
    this.type = VehicleType.car,
    this.police = false,
    this.sirenRedLeft = true,
    this.hazardOn = false,
  });

  final Color color;
  final SlideDirection facing;
  final VehicleType type;

  /// Renders a police livery (light bar instead of an arrow).
  final bool police;

  /// Which side of the siren is currently lit (animated by the caller).
  final bool sirenRedLeft;

  /// When true, all four corner lights glow amber (hazard / blocked blink).
  final bool hazardOn;

  static const Color _glassColor = Color(0xFF2A2E37);

  @override
  void paint(Canvas canvas, Size size) {
    final isHorizontal = facing.axis == MoveAxis.horizontal;
    final longSide = isHorizontal ? size.width : size.height;
    final shortSide = isHorizontal ? size.height : size.width;

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

    final l = longSide - 6; // body length
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

    _drawWheels(canvas, l, s, hs);
    _drawMirrors(canvas, l, s, hs);
    canvas.drawRRect(bodyRRect, bodyPaint); // wheels/mirrors tuck under the body

    // Type-specific detailing.
    if (police) {
      _carGlass(canvas, l, s);
    } else {
      switch (type) {
        case VehicleType.car:
          _carGlass(canvas, l, s);
        case VehicleType.minivan:
          _minivanGlass(canvas, l, s);
        case VehicleType.bus:
          _busGlass(canvas, l, s);
        case VehicleType.truck:
          _truck(canvas, l, s, hl);
      }
    }

    _drawLights(canvas, l, s, hl, hs);

    if (police) {
      _drawSiren(canvas, l, s);
    } else {
      _drawArrow(canvas, l, s);
    }

    canvas.restore();
  }

  void _drawWheels(Canvas canvas, double l, double s, double hs) {
    final wheelPaint = Paint()..color = const Color(0xFF1C1C22);
    // Axle positions sit near the front and rear of each body type (an extra
    // rear axle for buses/trucks), so wheels read correctly on long vehicles.
    final List<double> xs;
    switch (type) {
      case VehicleType.car:
        xs = [l * 0.28, -l * 0.28];
      case VehicleType.minivan:
        xs = [l * 0.30, -l * 0.30];
      case VehicleType.bus:
        xs = [l * 0.36, -l * 0.30, -l * 0.40];
      case VehicleType.truck:
        xs = [l * 0.34, -l * 0.26, -l * 0.40];
    }
    final wheelW = l * (type == VehicleType.car ? 0.18 : 0.13);
    final wheelH = s * 0.18;
    for (final sx in xs) {
      for (final sy in [-hs, hs]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(sx, sy), width: wheelW, height: wheelH),
            Radius.circular(wheelH * 0.4),
          ),
          wheelPaint,
        );
      }
    }
  }

  /// Small wing mirrors near the front, sticking out past the sides (cars and
  /// minivans only — buses/trucks read better without them at this scale).
  void _drawMirrors(Canvas canvas, double l, double s, double hs) {
    if (type == VehicleType.bus || type == VehicleType.truck) return;
    final paint = Paint()..color = Color.lerp(color, Colors.black, 0.25)!;
    final mx = l * 0.16;
    final mw = l * 0.06;
    final mh = s * 0.16;
    for (final sy in [-hs - mh * 0.35, hs + mh * 0.35]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(mx, sy), width: mw, height: mh),
          Radius.circular(mh * 0.4),
        ),
        paint,
      );
    }
  }

  void _cabin(Canvas canvas, double l, double s, double widthFactor, double cx) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(cx, 0), width: l * widthFactor, height: s * 0.80),
        Radius.circular(s * 0.22),
      ),
      Paint()..color = Color.lerp(color, Colors.black, 0.18)!,
    );
  }

  void _glassRect(Canvas canvas, double cx, double w, double h) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, 0), width: w, height: h),
        Radius.circular(h * 0.22),
      ),
      Paint()..color = _glassColor,
    );
  }

  void _carGlass(Canvas canvas, double l, double s) {
    _cabin(canvas, l, s, 0.52, -2);
    _glassRect(canvas, l * 0.18, l * 0.16, s * 0.66); // windshield
    _glassRect(canvas, -l * 0.22, l * 0.13, s * 0.60); // rear window
  }

  void _minivanGlass(Canvas canvas, double l, double s) {
    _cabin(canvas, l, s, 0.66, -2);
    _glassRect(canvas, l * 0.26, l * 0.12, s * 0.64); // windshield
    _glassRect(canvas, l * 0.02, l * 0.12, s * 0.60); // side window
    _glassRect(canvas, -l * 0.24, l * 0.12, s * 0.60); // rear window
  }

  void _busGlass(Canvas canvas, double l, double s) {
    // Lighter long roof panel.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: l * 0.88, height: s * 0.78),
        Radius.circular(s * 0.24),
      ),
      Paint()..color = Color.lerp(color, Colors.white, 0.14)!,
    );
    // A row of windows.
    const count = 5;
    final winW = l * 0.10;
    final span = l * 0.74;
    final step = span / count;
    final startX = -span / 2 + step / 2;
    for (var i = 0; i < count; i++) {
      _glassRect(canvas, startX + i * step, winW, s * 0.5);
    }
  }

  void _truck(Canvas canvas, double l, double s, double hl) {
    // Pale cargo box covering the rear ~60%.
    final cargoRect = Rect.fromCenter(
      center: Offset(-l * 0.20, 0),
      width: l * 0.58,
      height: s * 0.94,
    );
    final cargoRRect =
        RRect.fromRectAndRadius(cargoRect, Radius.circular(s * 0.16));
    canvas.drawRRect(cargoRRect, Paint()..color = const Color(0xFFEDEDF2));
    canvas.drawRRect(
      cargoRRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Colors.black.withOpacity(0.18),
    );
    // Cab at the front.
    _cabin(canvas, l, s, 0.30, l * 0.30);
    _glassRect(canvas, l * 0.40, l * 0.10, s * 0.66); // cab windshield
  }

  void _drawLights(Canvas canvas, double l, double s, double hl, double hs) {
    if (hazardOn) {
      // All four corners glow amber (hazard / blocked blink).
      const amberColor = Color(0xFFFFB300);
      final glow = Paint()
        ..color = amberColor.withOpacity(0.85)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      final amber = Paint()..color = amberColor;
      for (final sx in [hl - l * 0.05, -hl + l * 0.05]) {
        for (final sy in [-hs * 0.62, hs * 0.62]) {
          final r = Rect.fromCenter(
              center: Offset(sx, sy), width: l * 0.06, height: s * 0.2);
          canvas.drawRRect(
              RRect.fromRectAndRadius(r.inflate(2), Radius.circular(s * 0.1)), glow);
          canvas.drawRRect(
              RRect.fromRectAndRadius(r, Radius.circular(s * 0.08)), amber);
        }
      }
      return;
    }
    final head = Paint()..color = const Color(0xFFFFF3C4);
    final tail = Paint()..color = const Color(0xFFE53935);
    for (final sy in [-hs * 0.62, hs * 0.62]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(hl - l * 0.05, sy), width: l * 0.06, height: s * 0.2),
          Radius.circular(s * 0.08),
        ),
        head,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(-hl + l * 0.04, sy), width: l * 0.045, height: s * 0.18),
          Radius.circular(s * 0.08),
        ),
        tail,
      );
    }
  }

  void _drawArrow(Canvas canvas, double l, double s) {
    final paint = Paint()..color = Colors.white.withOpacity(0.92);
    final a = s * 0.20; // arrow half-height
    final tipX = a + s * 0.05;
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
        ..color = Colors.black.withOpacity(0.20)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
    canvas.drawPath(path, paint);
  }

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

  @override
  bool shouldRepaint(covariant CarPainter old) =>
      old.color != color ||
      old.facing != facing ||
      old.type != type ||
      old.police != police ||
      old.sirenRedLeft != sirenRedLeft ||
      old.hazardOn != hazardOn;
}

/// Top-down police officer: cap, face and shoulders, with a tiny badge. Used in
/// the Police power-up overlay beside the squad car.
class OfficerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide * 0.28;

    // Shadow.
    canvas.drawCircle(
      c.translate(0, 2),
      r * 1.5,
      Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    // Shoulders (navy uniform).
    canvas.drawCircle(c, r * 1.5, Paint()..color = const Color(0xFF1A3A6B));
    // Head / face.
    canvas.drawCircle(c, r * 0.95, Paint()..color = const Color(0xFFE8B98C));
    // Cap covering the top of the head.
    canvas.drawCircle(
      c.translate(0, -r * 0.20),
      r * 0.80,
      Paint()..color = const Color(0xFF15315C),
    );
    // Cap badge.
    canvas.drawCircle(
      c.translate(0, -r * 0.52),
      r * 0.16,
      Paint()..color = const Color(0xFFFFD54F),
    );
  }

  @override
  bool shouldRepaint(covariant OfficerPainter oldDelegate) => false;
}

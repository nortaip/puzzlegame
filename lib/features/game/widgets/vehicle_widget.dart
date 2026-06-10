import 'package:flutter/material.dart';

import '../../../game/models/vehicle.dart';
import 'car_painter.dart';

/// A single car: a painted top-down vehicle that animates in on first build and
/// glows + pulses when highlighted by a Hint.
class VehicleWidget extends StatefulWidget {
  const VehicleWidget({
    super.key,
    required this.vehicle,
    required this.color,
    required this.hinted,
    this.hazardOn = false,
  });

  final Vehicle vehicle;
  final Color color;
  final bool hinted;

  /// When true the car flashes its amber hazard lights (it's blocked).
  final bool hazardOn;

  @override
  State<VehicleWidget> createState() => _VehicleWidgetState();
}

class _VehicleWidgetState extends State<VehicleWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );

  @override
  void initState() {
    super.initState();
    if (widget.hinted) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(VehicleWidget old) {
    super.didUpdateWidget(old);
    if (widget.hinted && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.hinted && _pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final car = Padding(
      padding: const EdgeInsets.all(2),
      child: CustomPaint(
        painter: CarPainter(
          color: widget.color,
          facing: widget.vehicle.facing,
          type: widget.vehicle.type,
          hazardOn: widget.hazardOn,
        ),
        child: const SizedBox.expand(),
      ),
    );

    Widget content = car;
    if (widget.hinted) {
      content = AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          final t = _pulse.value;
          return Transform.scale(
            scale: 1.0 + 0.05 * t,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.55 + 0.35 * t),
                    blurRadius: 14 + 8 * t,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: child,
            ),
          );
        },
        child: car,
      );
    }

    // Entrance: a quick parking "settle" the first time the car appears.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.7 + 0.3 * t, child: child),
      ),
      child: content,
    );
  }
}

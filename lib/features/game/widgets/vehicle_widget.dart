import 'package:flutter/material.dart';

import '../../../game/models/vehicle.dart';

/// Pure visual for a single car — a glossy rounded body with a windshield band
/// oriented along its travel axis, soft shadow, and a glow when hinted.
class VehicleWidget extends StatelessWidget {
  const VehicleWidget({
    super.key,
    required this.vehicle,
    required this.color,
    required this.hinted,
  });

  final Vehicle vehicle;
  final Color color;
  final bool hinted;

  @override
  Widget build(BuildContext context) {
    final horizontal = vehicle.isHorizontal;
    return AnimatedScale(
      duration: const Duration(milliseconds: 160),
      scale: hinted ? 1.04 : 1.0,
      child: Container(
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(color, Colors.white, 0.25)!,
              color,
              Color.lerp(color, Colors.black, 0.18)!,
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.28),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
            if (hinted)
              BoxShadow(
                color: Colors.white.withOpacity(0.9),
                blurRadius: 18,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Stack(
          children: [
            // Windshield band oriented along the body.
            Align(
              alignment:
                  horizontal ? Alignment.centerLeft : Alignment.topCenter,
              child: FractionallySizedBox(
                widthFactor: horizontal ? 0.32 : 0.66,
                heightFactor: horizontal ? 0.66 : 0.32,
                child: Container(
                  margin: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            // Glossy top highlight.
            Align(
              alignment: Alignment.topCenter,
              child: FractionallySizedBox(
                widthFactor: 0.9,
                heightFactor: 0.18,
                child: Container(
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
